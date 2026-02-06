import SwiftUI

struct EventCard: View {
    let event: Event
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

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
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
            // Header with icon and category
            HStack(alignment: .top) {
                // Category icon
                Image(systemName: event.category.icon)
                    .iconBackground(event.category.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "location.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .labelStyle(.titleAndIcon)
                            .lineLimit(1)
                    }
                }

                Spacer()

                CategoryBadge(category: event.category)
            }

            Divider()

            // Date and time info
            HStack(spacing: 16) {
                // Date
                VStack(alignment: .leading, spacing: 2) {
                    Text("Date")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(Self.dateFormatter.string(from: event.date))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }

                // Time
                if !event.isAllDay {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Time")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(timeDisplay)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .textCase(.uppercase)

                        Text("All Day")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                }

                Spacer()

                // Relative time indicator
                relativeTimeView
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        HStack(spacing: 12) {
            // Category colored bar
            RoundedRectangle(cornerRadius: 2)
                .fill(event.category.color.gradient)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if !event.location.isEmpty {
                        Label(event.location, systemImage: "location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .labelStyle(.titleOnly)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if event.isAllDay {
                    Text("All Day")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.blue)
                } else {
                    Text(Self.timeFormatter.string(from: event.date))
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                Text(Self.dateFormatter.string(from: event.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .cardStyle()
    }

    // MARK: - Helper Views

    private var timeDisplay: String {
        let start = Self.timeFormatter.string(from: event.date)
        if let end = event.endDate {
            let endTime = Self.timeFormatter.string(from: end)
            return "\(start) - \(endTime)"
        }
        return start
    }

    private var relativeTimeView: some View {
        Group {
            let calendar = Calendar.current
            if calendar.isDateInToday(event.date) {
                todayBadge
            } else if calendar.isDateInTomorrow(event.date) {
                tomorrowBadge
            } else {
                let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: event.date)).day ?? 0
                if days > 0 && days <= 7 {
                    upcomingBadge(days: days)
                }
            }
        }
    }

    private var todayBadge: some View {
        Text("Today")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.red.opacity(0.15))
            .foregroundStyle(.red)
            .clipShape(Capsule())
    }

    private var tomorrowBadge: some View {
        Text("Tomorrow")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.orange.opacity(0.15))
            .foregroundStyle(.orange)
            .clipShape(Capsule())
    }

    private func upcomingBadge(days: Int) -> some View {
        Text("In \(days)d")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.blue.opacity(0.15))
            .foregroundStyle(.blue)
            .clipShape(Capsule())
    }
}

#Preview("Full Card") {
    ScrollView {
        VStack(spacing: 16) {
            EventCard(event: Event(
                title: "Team Standup Meeting",
                date: Date(),
                endDate: Date().addingTimeInterval(3600),
                location: "Conference Room A",
                category: .meeting
            ))

            EventCard(event: Event(
                title: "Birthday Party",
                date: Date().addingTimeInterval(86400),
                location: "Central Park",
                category: .social,
                isAllDay: true
            ))

            EventCard(event: Event(
                title: "Flight to Tokyo",
                date: Date().addingTimeInterval(86400 * 5),
                location: "JFK Airport",
                category: .travel
            ))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}

#Preview("Compact Card") {
    ScrollView {
        VStack(spacing: 12) {
            EventCard(event: Event(
                title: "Team Standup Meeting",
                date: Date(),
                location: "Conference Room A",
                category: .meeting
            ), style: .compact)

            EventCard(event: Event(
                title: "Birthday Party",
                date: Date().addingTimeInterval(86400),
                location: "Central Park",
                category: .social,
                isAllDay: true
            ), style: .compact)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
