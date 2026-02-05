import Foundation

struct Event: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var date: Date
    var endDate: Date?
    var location: String
    var notes: String
    var category: EventCategory
    var isAllDay: Bool
    let createdAt: Date
    var updatedAt: Date

    nonisolated init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        endDate: Date? = nil,
        location: String = "",
        notes: String = "",
        category: EventCategory = .general,
        isAllDay: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.category = category
        self.isAllDay = isAllDay
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
