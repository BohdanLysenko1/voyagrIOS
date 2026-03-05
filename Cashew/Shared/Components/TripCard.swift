import SwiftUI

struct TripCard: View {
    let trip: Trip
    var style: CardStyle = .full

    enum CardStyle {
        case full
        case compact
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        switch style {
        case .full:
            fullCard
        case .compact:
            compactCard
        }
    }

    // MARK: - Full Card

    private var fullCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and status
            HStack(alignment: .top) {
                // Trip icon
                Image(systemName: "airplane")
                    .gradientIconBackground(AppTheme.tripGradient)

                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(trip.destination)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                StatusBadge(status: trip.computedStatus, style: .prominent)
            }

            Divider()

            // Date range
            HStack(spacing: 16) {
                dateItem(label: "Start", date: trip.startDate, icon: "calendar")
                dateItem(label: "End", date: trip.endDate, icon: "calendar.badge.checkmark")
                Spacer()
                daysRemaining
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        HStack(spacing: 12) {
            // Tinted airplane icon circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: "airplane")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                // Line 1: Trip name
                Text(trip.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Line 2: Date range · Status
                Text(compactSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Line 3: Destination
                if !trip.destination.isEmpty {
                    Label(trip.destination, systemImage: "location")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .labelStyle(.titleAndIcon)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .cardStyle()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(compactAccessibilityLabel)
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Helper Views

    private func dateItem(label: String, date: Date, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)

            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(Self.dateFormatter.string(from: date))
                    .font(.caption)
                    .fontWeight(.medium)
            }
        }
    }

    private var daysRemaining: some View {
        Group {
            if trip.computedStatus == .upcoming {
                let days = Calendar.current.dateComponents([.day], from: Date(), to: trip.startDate).day ?? 0
                if days > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(days)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                        Text("days left")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var compactSubtitle: String {
        let start = Self.dateFormatter.string(from: trip.startDate)
        let end = Self.dateFormatter.string(from: trip.endDate)
        return "\(start) – \(end) · \(trip.computedStatus.displayName)"
    }

    private var compactAccessibilityLabel: String {
        let start = Self.dateFormatter.string(from: trip.startDate)
        let end = Self.dateFormatter.string(from: trip.endDate)
        var parts = [trip.name, trip.computedStatus.displayName, "\(start) to \(end)"]
        if !trip.destination.isEmpty { parts.append(trip.destination) }
        return parts.joined(separator: ", ")
    }
}

#Preview("Full Card") {
    ScrollView {
        VStack(spacing: 16) {
            TripCard(trip: Trip(
                name: "Summer Vacation",
                destination: "Paris, France",
                startDate: Date().addingTimeInterval(86400 * 30),
                endDate: Date().addingTimeInterval(86400 * 37),
                status: .upcoming
            ))

            TripCard(trip: Trip(
                name: "Business Trip",
                destination: "New York, USA",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 3),
                status: .active
            ))

            TripCard(trip: Trip(
                name: "Weekend Getaway",
                destination: "Miami Beach",
                startDate: Date().addingTimeInterval(-86400 * 7),
                endDate: Date().addingTimeInterval(-86400 * 5),
                status: .completed
            ))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Card") {
    ScrollView {
        VStack(spacing: 12) {
            TripCard(trip: Trip(
                name: "Summer Vacation",
                destination: "Paris, France",
                startDate: Date().addingTimeInterval(86400 * 30),
                endDate: Date().addingTimeInterval(86400 * 37),
                status: .upcoming
            ), style: .compact)

            TripCard(trip: Trip(
                name: "Business Trip",
                destination: "New York, USA",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 3),
                status: .active
            ), style: .compact)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
