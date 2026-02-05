import Foundation
import CloudKit

actor CloudKitManager {

    static let shared = CloudKitManager()

    private let container: CKContainer?
    private let database: CKDatabase?

    private let containerIdentifier = "iCloud.com.voyagr.VoyagrIOS"

    private init() {
        // Safely initialize CloudKit - won't crash if not configured
        if let _ = Bundle.main.object(forInfoDictionaryKey: "NSUbiquitousContainers") as? [String: Any] {
            self.container = CKContainer(identifier: containerIdentifier)
            self.database = container?.privateCloudDatabase
        } else {
            // CloudKit not configured in entitlements
            self.container = nil
            self.database = nil
        }
    }

    // MARK: - Availability Check

    var isAvailable: Bool {
        container != nil && database != nil
    }

    // MARK: - Account Status

    func checkAccountStatus() async throws -> Bool {
        guard let container else {
            return false
        }
        let status = try await container.accountStatus()
        return status == .available
    }

    // MARK: - CRUD Operations

    func fetchAll<T: CloudKitRecordConvertible>(_ type: T.Type) async throws -> [T] {
        guard let database else {
            throw CloudKitError.notAuthenticated
        }

        let recordType = T.recordType
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))

        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor?

        repeat {
            let result: (matchResults: [(CKRecord.ID, Result<CKRecord, Error>)], queryCursor: CKQueryOperation.Cursor?)

            if let cursor {
                result = try await database.records(continuingMatchFrom: cursor)
            } else {
                result = try await database.records(matching: query)
            }

            let records = result.matchResults.compactMap { try? $0.1.get() }
            allRecords.append(contentsOf: records)
            cursor = result.queryCursor
        } while cursor != nil

        return allRecords.compactMap { T(record: $0) }
    }

    func fetch<T: CloudKitRecordConvertible>(_ type: T.Type, id: UUID) async throws -> T {
        guard let database else {
            throw CloudKitError.notAuthenticated
        }

        let recordID = CKRecord.ID(recordName: id.uuidString)
        do {
            let record = try await database.record(for: recordID)
            guard let item = T(record: record) else {
                throw CloudKitError.conversionFailed
            }
            return item
        } catch let error as CKError where error.code == .unknownItem {
            throw CloudKitError.recordNotFound
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func save<T: CloudKitRecordConvertible>(_ item: T) async throws -> T {
        guard let database else {
            throw CloudKitError.notAuthenticated
        }

        let record = item.toRecord()
        do {
            let savedRecord = try await database.save(record)
            guard let savedItem = T(record: savedRecord) else {
                throw CloudKitError.conversionFailed
            }
            return savedItem
        } catch {
            throw CloudKitError.from(error)
        }
    }

    func delete<T: CloudKitRecordConvertible>(_ type: T.Type, id: UUID) async throws {
        guard let database else {
            throw CloudKitError.notAuthenticated
        }

        let recordID = CKRecord.ID(recordName: id.uuidString)
        do {
            try await database.deleteRecord(withID: recordID)
        } catch let error as CKError where error.code == .unknownItem {
            // Already deleted, not an error
            return
        } catch {
            throw CloudKitError.from(error)
        }
    }

    // MARK: - Batch Operations

    func saveAll<T: CloudKitRecordConvertible>(_ items: [T]) async throws {
        guard let database else {
            throw CloudKitError.notAuthenticated
        }

        guard !items.isEmpty else { return }

        let records = items.map { $0.toRecord() }
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        operation.savePolicy = .changedKeys

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: CloudKitError.from(error))
                }
            }
            database.add(operation)
        }
    }
}
