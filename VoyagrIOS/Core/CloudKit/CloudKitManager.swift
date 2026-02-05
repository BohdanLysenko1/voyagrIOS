import Foundation
import CloudKit

actor CloudKitManager {

    static let shared = CloudKitManager()

    private let container: CKContainer
    private let database: CKDatabase

    private init() {
        self.container = CKContainer(identifier: "iCloud.com.voyagr.VoyagrIOS")
        self.database = container.privateCloudDatabase
    }

    // MARK: - Account Status

    func checkAccountStatus() async throws -> Bool {
        let status = try await container.accountStatus()
        return status == .available
    }

    // MARK: - CRUD Operations

    func fetchAll<T: CloudKitRecordConvertible>(_ type: T.Type) async throws -> [T] {
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
