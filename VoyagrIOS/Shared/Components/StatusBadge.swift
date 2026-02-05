import SwiftUI

struct StatusBadge: View {
    let status: TripStatus

    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch status {
        case .planning: return .blue.opacity(0.15)
        case .upcoming: return .orange.opacity(0.15)
        case .active: return .green.opacity(0.15)
        case .completed: return .gray.opacity(0.15)
        case .cancelled: return .red.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .planning: return .blue
        case .upcoming: return .orange
        case .active: return .green
        case .completed: return .gray
        case .cancelled: return .red
        }
    }
}

#Preview {
    HStack {
        StatusBadge(status: .planning)
        StatusBadge(status: .active)
        StatusBadge(status: .completed)
    }
    .padding()
}
