import SwiftUI

struct StatusBadge: View {
    let status: TripStatus
    var style: BadgeStyle = .default

    enum BadgeStyle {
        case `default`
        case prominent
    }

    var body: some View {
        HStack(spacing: 4) {
            if style == .prominent {
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
            }
            Text(status.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, style == .prominent ? 10 : 8)
        .padding(.vertical, style == .prominent ? 5 : 4)
        .background(status.color.opacity(0.15))
        .foregroundStyle(status.color)
        .clipShape(Capsule())
    }
}

// MARK: - TripStatus Color Extension

extension TripStatus {
    var color: Color {
        switch self {
        case .planning: .blue
        case .upcoming: .orange
        case .active: .green
        case .completed: .gray
        case .cancelled: .red
        }
    }

    var icon: String {
        switch self {
        case .planning: "pencil.and.list.clipboard"
        case .upcoming: "calendar.badge.clock"
        case .active: "airplane.departure"
        case .completed: "checkmark.circle"
        case .cancelled: "xmark.circle"
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        HStack {
            StatusBadge(status: .planning)
            StatusBadge(status: .upcoming)
            StatusBadge(status: .active)
        }
        HStack {
            StatusBadge(status: .planning, style: .prominent)
            StatusBadge(status: .active, style: .prominent)
            StatusBadge(status: .completed, style: .prominent)
        }
    }
    .padding()
}
