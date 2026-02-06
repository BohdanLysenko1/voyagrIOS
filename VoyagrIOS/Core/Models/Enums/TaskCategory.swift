import SwiftUI

enum TaskCategory: String, Codable, Sendable, CaseIterable {
    case work
    case personal
    case health
    case errands
    case social
    case learning
    case other

    var displayName: String {
        switch self {
        case .work: "Work"
        case .personal: "Personal"
        case .health: "Health"
        case .errands: "Errands"
        case .social: "Social"
        case .learning: "Learning"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .work: "briefcase.fill"
        case .personal: "person.fill"
        case .health: "heart.fill"
        case .errands: "cart.fill"
        case .social: "person.2.fill"
        case .learning: "book.fill"
        case .other: "circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .work: .blue
        case .personal: .purple
        case .health: .red
        case .errands: .orange
        case .social: .pink
        case .learning: .green
        case .other: .gray
        }
    }
}
