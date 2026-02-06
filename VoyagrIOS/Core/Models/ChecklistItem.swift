import Foundation

struct ChecklistItem: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: ChecklistPriority
    var notes: String

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: ChecklistPriority = .medium,
        notes: String = ""
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
        self.notes = notes
    }
}

enum ChecklistPriority: String, Codable, Sendable, CaseIterable {
    case low
    case medium
    case high
    case urgent

    var displayName: String {
        switch self {
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        case .urgent: "Urgent"
        }
    }

    var icon: String {
        switch self {
        case .low: "arrow.down.circle.fill"
        case .medium: "minus.circle.fill"
        case .high: "arrow.up.circle.fill"
        case .urgent: "exclamationmark.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .low: "green"
        case .medium: "blue"
        case .high: "orange"
        case .urgent: "red"
        }
    }
}
