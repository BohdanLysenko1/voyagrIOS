import Foundation

enum TripStatus: String, Codable, Sendable, CaseIterable {
    case planning
    case upcoming
    case active
    case completed
    case cancelled

    var displayName: String {
        switch self {
        case .planning: "Planning"
        case .upcoming: "Upcoming"
        case .active: "Active"
        case .completed: "Completed"
        case .cancelled: "Cancelled"
        }
    }
}
