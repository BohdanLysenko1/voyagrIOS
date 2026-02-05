import Foundation
import CloudKit

protocol CloudKitRecordConvertible: Sendable {
    nonisolated static var recordType: String { get }
    nonisolated var recordID: CKRecord.ID { get }
    nonisolated init?(record: CKRecord)
    nonisolated func toRecord() -> CKRecord
}

// MARK: - Trip + CloudKit

extension Trip: CloudKitRecordConvertible {
    nonisolated static var recordType: String { "Trip" }

    nonisolated var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    nonisolated init?(record: CKRecord) {
        guard
            record.recordID.recordName.components(separatedBy: "-").count == 5,
            let id = UUID(uuidString: record.recordID.recordName),
            let name = record["name"] as? String,
            let destination = record["destination"] as? String,
            let startDate = record["startDate"] as? Date,
            let endDate = record["endDate"] as? Date,
            let statusRaw = record["status"] as? String,
            let status = TripStatus(rawValue: statusRaw),
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }

        self.init(
            id: id,
            name: name,
            destination: destination,
            startDate: startDate,
            endDate: endDate,
            notes: record["notes"] as? String ?? "",
            coverImageURL: (record["coverImageURL"] as? String).flatMap { URL(string: $0) },
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["name"] = name
        record["destination"] = destination
        record["startDate"] = startDate
        record["endDate"] = endDate
        record["notes"] = notes
        record["coverImageURL"] = coverImageURL?.absoluteString
        record["status"] = status.rawValue
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }
}

// MARK: - Event + CloudKit

extension Event: CloudKitRecordConvertible {
    nonisolated static var recordType: String { "Event" }

    nonisolated var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    nonisolated init?(record: CKRecord) {
        guard
            record.recordID.recordName.components(separatedBy: "-").count == 5,
            let id = UUID(uuidString: record.recordID.recordName),
            let title = record["title"] as? String,
            let date = record["date"] as? Date,
            let categoryRaw = record["category"] as? String,
            let category = EventCategory(rawValue: categoryRaw),
            let isAllDay = record["isAllDay"] as? Int,
            let createdAt = record["createdAt"] as? Date,
            let updatedAt = record["updatedAt"] as? Date
        else {
            return nil
        }

        self.init(
            id: id,
            title: title,
            date: date,
            endDate: record["endDate"] as? Date,
            location: record["location"] as? String ?? "",
            notes: record["notes"] as? String ?? "",
            category: category,
            isAllDay: isAllDay == 1,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    nonisolated func toRecord() -> CKRecord {
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["title"] = title
        record["date"] = date
        record["endDate"] = endDate
        record["location"] = location
        record["notes"] = notes
        record["category"] = category.rawValue
        record["isAllDay"] = isAllDay ? 1 : 0
        record["createdAt"] = createdAt
        record["updatedAt"] = updatedAt
        return record
    }
}
