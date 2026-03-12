import SwiftUI

struct CompletionTrendChart: View {

    let allTasks: [DailyTask]

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -(6 - offset), to: today)
        }
    }

    private var dailyRates: [(date: Date, rate: Double, completed: Int, total: Int)] {
        let calendar = Calendar.current
        return last7Days.map { day in
            let dayTasks = allTasks.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let completed = dayTasks.filter(\.isCompleted).count
            let total = dayTasks.count
            let rate = total > 0 ? Double(completed) / Double(total) : 0
            return (day, rate, completed, total)
        }
    }

    private var weekAverage: Double {
        let rates = dailyRates.filter { $0.total > 0 }
        guard !rates.isEmpty else { return 0 }
        return rates.map(\.rate).reduce(0, +) / Double(rates.count)
    }

    private var totalCompletedThisWeek: Int {
        dailyRates.map(\.completed).reduce(0, +)
    }

    private var totalTasksThisWeek: Int {
        dailyRates.map(\.total).reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                SectionHeader(icon: "chart.bar.fill", title: "7-Day Trend", gradient: AppTheme.dayPlannerGradient)

                Spacer()

                Text("Avg \(Int(weekAverage * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }

            // Bar chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(dailyRates.enumerated()), id: \.offset) { index, data in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barGradient(for: data, isToday: index == 6))
                            .frame(height: barHeight(for: data.rate))
                            .frame(maxWidth: .infinity)

                        // Day label
                        Text(dayLabel(data.date))
                            .font(.system(size: 9, weight: index == 6 ? .bold : .medium))
                            .foregroundStyle(index == 6 ? .primary : .secondary)
                            .frame(maxWidth: .infinity)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
            .frame(height: 80)

            // Summary
            HStack(spacing: 16) {
                Label("\(totalCompletedThisWeek) done", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)

                Label("\(totalTasksThisWeek - totalCompletedThisWeek) missed", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }

    private func barHeight(for rate: Double) -> CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 56
        return max(minHeight, maxHeight * rate)
    }

    private func barGradient(for data: (date: Date, rate: Double, completed: Int, total: Int), isToday: Bool) -> LinearGradient {
        if data.total == 0 {
            return LinearGradient(colors: [Color(.systemGray5)], startPoint: .bottom, endPoint: .top)
        }
        if data.rate >= 1.0 {
            // All done — success green
            return LinearGradient(colors: [.green, .mint], startPoint: .bottom, endPoint: .top)
        }
        if isToday {
            // Today highlighted with task blue
            return AppTheme.dayPlannerGradient
        }
        // Partial completion — muted task blue
        return LinearGradient(colors: [.blue.opacity(0.4), .blue.opacity(0.7)], startPoint: .bottom, endPoint: .top)
    }

    private static let dayLabelFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        return Self.dayLabelFormatter.string(from: date)
    }
}
