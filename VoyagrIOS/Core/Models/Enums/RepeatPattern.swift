import Foundation

enum RepeatPattern: String, Codable, Sendable, CaseIterable {
    case daily
    case weekdays
    case weekends
    case custom

    var displayName: String {
        switch self {
        case .daily: "Every day"
        case .weekdays: "Weekdays"
        case .weekends: "Weekends"
        case .custom: "Custom"
        }
    }

    func shouldRepeat(on dayOfWeek: DayOfWeek) -> Bool {
        switch self {
        case .daily:
            return true
        case .weekdays:
            return dayOfWeek != .saturday && dayOfWeek != .sunday
        case .weekends:
            return dayOfWeek == .saturday || dayOfWeek == .sunday
        case .custom:
            return false // Custom uses selectedDays instead
        }
    }
}
