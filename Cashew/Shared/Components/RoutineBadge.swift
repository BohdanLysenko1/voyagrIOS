import SwiftUI

/// A small purple pill badge indicating a task was generated from a routine.
struct RoutineBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "repeat")
                .font(.system(size: 8, weight: .bold))
            Text("Routine")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(.purple)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(.purple.opacity(0.12))
        .clipShape(Capsule())
    }
}
