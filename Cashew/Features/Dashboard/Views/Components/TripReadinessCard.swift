import SwiftUI

struct TripReadinessCard: View {

    let trip: Trip

    private var packingPercent: Double {
        trip.packingProgress
    }

    private var checklistPercent: Double {
        trip.checklistProgress
    }

    private var overallReadiness: Double {
        let hasPackingItems = !trip.packingItems.isEmpty
        let hasChecklistItems = !trip.checklistItems.isEmpty

        if !hasPackingItems && !hasChecklistItems { return 1.0 }
        if !hasPackingItems { return checklistPercent }
        if !hasChecklistItems { return packingPercent }
        return (packingPercent + checklistPercent) / 2.0
    }

    private var readinessColor: Color {
        if overallReadiness >= 0.75 { return .green }
        if overallReadiness >= 0.4 { return .orange }
        return .red
    }

    private var daysLabel: String {
        guard let days = trip.daysUntilTrip else { return "" }
        if days == 0 { return "Today!" }
        if days == 1 { return "Tomorrow" }
        return "\(days) days"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Trip name + days
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(trip.destination)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Readiness badge
                VStack(spacing: 2) {
                    Text("\(Int(overallReadiness * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(readinessColor)
                    Text(daysLabel)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(readinessColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Progress bars
            VStack(spacing: 8) {
                if !trip.packingItems.isEmpty {
                    progressRow(
                        icon: "bag.fill",
                        label: "Packing",
                        progress: packingPercent,
                        detail: "\(trip.packingItems.filter(\.isPacked).count)/\(trip.packingItems.count)"
                    )
                }

                if !trip.checklistItems.isEmpty {
                    progressRow(
                        icon: "checklist",
                        label: "Checklist",
                        progress: checklistPercent,
                        detail: "\(trip.checklistItems.filter(\.isCompleted).count)/\(trip.checklistItems.count)"
                    )
                }

                if trip.packingItems.isEmpty && trip.checklistItems.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("No packing or checklist items yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func progressRow(icon: String, label: String, progress: Double, detail: String) -> some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(detail)
                    .font(.caption)
                    .fontWeight(.medium)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(progressBarColor(progress).gradient)
                        .frame(width: geo.size.width * progress, height: 6)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 6)
        }
    }

    private func progressBarColor(_ progress: Double) -> Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return .blue }
        return .orange
    }
}

struct TripReadinessSection: View {

    let trips: [Trip]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "airplane.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.tripGradient)
                Text("Trip Readiness")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            if trips.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No upcoming trips")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Plan your next adventure!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ForEach(trips) { trip in
                    NavigationLink(value: trip.id) {
                        TripReadinessCard(trip: trip)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }
}
