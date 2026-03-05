import SwiftUI

struct WeeklyReviewSection: View {

    let allTasks: [DailyTask]
    let events: [Event]
    let routines: [DailyRoutine]

    private var calendar: Calendar { Calendar.current }

    private var thisWeekRange: (start: Date, end: Date) {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let sunday = calendar.date(byAdding: .day, value: 6, to: monday) else {
            return (today, today)
        }
        return (monday, sunday)
    }

    private var lastWeekRange: (start: Date, end: Date) {
        let thisWeek = thisWeekRange
        guard let monday = calendar.date(byAdding: .day, value: -7, to: thisWeek.start),
              let sunday = calendar.date(byAdding: .day, value: -1, to: thisWeek.start) else {
            return (thisWeek.start, thisWeek.start)
        }
        return (monday, sunday)
    }

    private func tasksInRange(_ range: (start: Date, end: Date)) -> [DailyTask] {
        allTasks.filter { task in
            let day = calendar.startOfDay(for: task.date)
            return day >= range.start && day <= range.end
        }
    }

    private var thisWeekCompleted: Int {
        tasksInRange(thisWeekRange).filter(\.isCompleted).count
    }

    private var lastWeekCompleted: Int {
        tasksInRange(lastWeekRange).filter(\.isCompleted).count
    }

    private var thisWeekTotal: Int {
        tasksInRange(thisWeekRange).count
    }

    private var lastWeekTotal: Int {
        tasksInRange(lastWeekRange).count
    }

    private var thisWeekRate: Double {
        guard thisWeekTotal > 0 else { return 0 }
        return Double(thisWeekCompleted) / Double(thisWeekTotal)
    }

    private var lastWeekRate: Double {
        guard lastWeekTotal > 0 else { return 0 }
        return Double(lastWeekCompleted) / Double(lastWeekTotal)
    }

    private var completionTrend: Int {
        guard lastWeekCompleted > 0 else { return thisWeekCompleted > 0 ? 100 : 0 }
        return Int(((Double(thisWeekCompleted) - Double(lastWeekCompleted)) / Double(lastWeekCompleted)) * 100)
    }

    private var rateTrend: Int {
        guard lastWeekRate > 0 else { return thisWeekRate > 0 ? 100 : 0 }
        return Int(((thisWeekRate - lastWeekRate) / lastWeekRate) * 100)
    }

    private var thisWeekEvents: Int {
        let range = thisWeekRange
        return events.filter { event in
            let day = calendar.startOfDay(for: event.date)
            return day >= range.start && day <= range.end
        }.count
    }

    private var activeRoutineCount: Int {
        routines.filter(\.isEnabled).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.eventGradient)
                Text("This Week")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                weekStatCard(
                    value: "\(thisWeekCompleted)",
                    label: "Tasks Done",
                    trend: completionTrend,
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                weekStatCard(
                    value: "\(Int(thisWeekRate * 100))%",
                    label: "Completion",
                    trend: rateTrend,
                    icon: "target",
                    color: .blue
                )

                weekStatCard(
                    value: "\(thisWeekEvents)",
                    label: "Events",
                    trend: nil,
                    icon: "star.fill",
                    color: .purple
                )

                weekStatCard(
                    value: "\(activeRoutineCount)",
                    label: "Routines",
                    trend: nil,
                    icon: "repeat",
                    color: .orange
                )
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }

    private func weekStatCard(value: String, label: String, trend: Int?, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)

                if let trend, trend != 0 {
                    HStack(spacing: 1) {
                        Image(systemName: trend > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 8, weight: .bold))
                        Text("\(abs(trend))%")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(trend > 0 ? .green : .red)
                }
            }

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
