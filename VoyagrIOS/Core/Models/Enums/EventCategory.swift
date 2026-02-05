import SwiftUI

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

    var displayName: String {
        switch self {
        case .general: "General"
        case .meeting: "Meeting"
        case .social: "Social"
        case .entertainment: "Entertainment"
        case .sports: "Sports"
        case .health: "Health"
        case .education: "Education"
        case .work: "Work"
        case .travel: "Travel"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .general: "star"
        case .meeting: "person.2"
        case .social: "party.popper"
        case .entertainment: "film"
        case .sports: "figure.run"
        case .health: "heart"
        case .education: "book"
        case .work: "briefcase"
        case .travel: "airplane"
        case .other: "ellipsis.circle"
        }
    }

    var color: Color {
        switch self {
        case .general: .blue
        case .meeting: .purple
        case .social: .pink
        case .entertainment: .orange
        case .sports: .green
        case .health: .red
        case .education: .indigo
        case .work: .gray
        case .travel: .cyan
        case .other: .secondary
        }
    }
}
