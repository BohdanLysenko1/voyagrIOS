import Foundation

struct DailyTask: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var date: Date
    var startTime: Date?
    var endTime: Date?
    var isCompleted: Bool
    var category: TaskCategory
    var notes: String
    var routineId: UUID?
    let createdAt: Date
    var updatedAt: Date

    nonisolated init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        isCompleted: Bool = false,
        category: TaskCategory = .personal,
        notes: String = "",
        routineId: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted
        self.category = category
        self.notes = notes
        self.routineId = routineId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Codable (backward compatible)

    enum CodingKeys: String, CodingKey {
        case id, title, date, startTime, endTime, isCompleted
        case category, notes, routineId, createdAt, updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        date = try container.decode(Date.self, forKey: .date)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        category = try container.decodeIfPresent(TaskCategory.self, forKey: .category) ?? .personal
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        routineId = try container.decodeIfPresent(UUID.self, forKey: .routineId)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }

    // MARK: - Computed Properties

    var isScheduled: Bool {
        startTime != nil
    }

    var formattedTimeRange: String? {
        guard let start = startTime else { return nil }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if let end = endTime {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
        return formatter.string(from: start)
    }

    var duration: TimeInterval? {
        guard let start = startTime, let end = endTime else { return nil }
        return end.timeIntervalSince(start)
    }
}
