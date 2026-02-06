import SwiftUI

struct CategoryBadge: View {
    let category: EventCategory
    var style: BadgeStyle = .default

    enum BadgeStyle {
        case `default`
        case prominent
        case iconOnly
    }

    var body: some View {
        switch style {
        case .default:
            defaultBadge
        case .prominent:
            prominentBadge
        case .iconOnly:
            iconOnlyBadge
        }
    }

    private var defaultBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: 9, weight: .semibold))
            Text(category.displayName)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(category.color.opacity(0.15))
        .foregroundStyle(category.color)
        .clipShape(Capsule())
    }

    private var prominentBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(category.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(category.color.gradient)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }

    private var iconOnlyBadge: some View {
        Image(systemName: category.icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(category.color.gradient)
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack {
            CategoryBadge(category: .meeting)
            CategoryBadge(category: .social)
            CategoryBadge(category: .work)
        }
        HStack {
            CategoryBadge(category: .meeting, style: .prominent)
            CategoryBadge(category: .social, style: .prominent)
        }
        HStack {
            CategoryBadge(category: .meeting, style: .iconOnly)
            CategoryBadge(category: .social, style: .iconOnly)
            CategoryBadge(category: .travel, style: .iconOnly)
        }
    }
    .padding()
}
