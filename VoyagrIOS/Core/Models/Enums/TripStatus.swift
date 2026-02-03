import Foundation

enum TripStatus: String, Codable, Sendable, CaseIterable {
    case planning
    case upcoming
    case active
    case completed
    case cancelled
}
