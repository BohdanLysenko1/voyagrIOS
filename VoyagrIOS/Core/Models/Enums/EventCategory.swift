import Foundation

enum EventCategory: String, Codable, Sendable, CaseIterable {
    case general
    case meeting
    case social
    case entertainment
    case sports
    case health
    case education
    case work
    case travel
    case other
}
