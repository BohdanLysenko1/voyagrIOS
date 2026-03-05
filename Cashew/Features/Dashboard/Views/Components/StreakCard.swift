import SwiftUI

struct StreakCard: View {

    let routine: DailyRoutine
    let currentStreak: Int
    let bestStreak: Int

    private var flameColor: Color {
        switch currentStreak {
        case 30...: return .yellow
        case 14...: return .purple
        case 7...: return .red
        case 3...: return .orange
        default: return .gray
        }
    }

    private var flameSize: CGFloat {
        switch currentStreak {
        case 30...: return 32
        case 14...: return 28
        case 7...: return 26
        case 3...: return 24
        default: return 20
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            // Flame + streak count
            ZStack {
                Circle()
                    .fill(flameColor.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: currentStreak >= 3 ? "flame.fill" : "flame")
                    .font(.system(size: flameSize))
                    .foregroundStyle(flameColor.gradient)
                    .symbolEffect(.bounce, value: currentStreak >= 7)
            }

            // Streak number
            Text("\(currentStreak)")
                .font(.title2)
                .fontWeight(.black)
                .monospacedDigit()

            // Routine name
            Text(routine.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)

            // Best streak
            if bestStreak > 0 {
                Text("Best: \(bestStreak)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 110)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StreakTrackerSection: View {

    let routines: [DailyRoutine]
    let allTasks: [DailyTask]

    private var streakData: [(routine: DailyRoutine, current: Int, best: Int)] {
        routines
            .filter(\.isEnabled)
            .map { routine in
                let (current, best) = computeStreak(for: routine)
                return (routine, current, best)
            }
            .sorted { $0.current > $1.current }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                Text("Streaks")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                if let topStreak = streakData.first, topStreak.current >= 3 {
                    Text("\(topStreak.current) day best!")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            if streakData.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "repeat")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("No active routines")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Create routines in My Day to track streaks")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(streakData, id: \.routine.id) { data in
                            StreakCard(
                                routine: data.routine,
                                currentStreak: data.current,
                                bestStreak: data.best
                            )
                        }
                    }
                }
            }
        }
        .padding(AppTheme.cardPadding)
        .cardStyle()
    }

    // MARK: - Streak Computation

    private func computeStreak(for routine: DailyRoutine) -> (current: Int, best: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let routineTasks = allTasks
            .filter { $0.routineId == routine.id }
            .sorted { $0.date > $1.date }

        var currentStreak = 0
        var bestStreak = 0
        var tempStreak = 0

        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            guard routine.shouldRunOn(date: date) else { continue }

            let hasCompletedTask = routineTasks.contains { task in
                calendar.isDate(task.date, inSameDayAs: date) && task.isCompleted
            }

            if hasCompletedTask {
                tempStreak += 1
                bestStreak = max(bestStreak, tempStreak)
                if dayOffset <= 1 || currentStreak == tempStreak - 1 {
                    currentStreak = tempStreak
                }
            } else {
                tempStreak = 0
                if currentStreak > 0 && dayOffset > 0 {
                    break
                }
            }
        }

        return (currentStreak, bestStreak)
    }
}
