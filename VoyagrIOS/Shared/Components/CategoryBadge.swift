import SwiftUI

struct CategoryBadge: View {
    let category: EventCategory

    var body: some View {
        Text(category.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(category.color.opacity(0.15))
            .foregroundStyle(category.color)
            .clipShape(Capsule())
    }
}

extension EventCategory {
    var color: Color {
        switch self {
        case .general: return .blue
        case .meeting: return .purple
        case .social: return .pink
        case .entertainment: return .orange
        case .sports: return .green
        case .health: return .red
        case .education: return .indigo
        case .work: return .gray
        case .travel: return .cyan
        case .other: return .secondary
        }
    }
}

#Preview {
    HStack {
        CategoryBadge(category: .meeting)
        CategoryBadge(category: .social)
        CategoryBadge(category: .work)
    }
    .padding()
}
