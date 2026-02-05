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

#Preview {
    HStack {
        CategoryBadge(category: .meeting)
        CategoryBadge(category: .social)
        CategoryBadge(category: .work)
    }
    .padding()
}
