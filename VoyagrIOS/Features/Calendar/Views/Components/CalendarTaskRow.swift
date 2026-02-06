import SwiftUI

struct CalendarTaskRow: View {
    let task: DailyTask
    let service: DayPlannerServiceProtocol

    @State private var isToggling = false

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                toggleTask()
            } label: {
                Group {
                    if isToggling {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    }
                }
                .font(.system(size: 22))
                .foregroundStyle(task.isCompleted ? .green : task.category.color)
                .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(isToggling)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Category
                    Label(task.category.displayName, systemImage: task.category.icon)
                        .font(.caption)
                        .foregroundStyle(task.category.color)

                    // Time if scheduled
                    if let timeRange = task.formattedTimeRange {
                        Text(timeRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Routine indicator
                    if task.routineId != nil {
                        Label("Routine", systemImage: "repeat")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func toggleTask() {
        guard !isToggling else { return }
        isToggling = true

        Task {
            do {
                try await service.toggleTaskCompletion(task)
            } catch {
                // Error handling is managed by the service's @Observable state
                // The UI will reflect the unchanged state if toggle fails
            }
            isToggling = false
        }
    }
}

#Preview {
    VStack(spacing: 10) {
        CalendarTaskRow(
            task: DailyTask(
                title: "Morning workout",
                date: Date(),
                startTime: Date(),
                category: .health
            ),
            service: DayPlannerService(
                taskRepository: LocalDailyTaskRepository(),
                routineRepository: LocalDailyRoutineRepository()
            )
        )

        CalendarTaskRow(
            task: DailyTask(
                title: "Completed task",
                date: Date(),
                isCompleted: true,
                category: .work
            ),
            service: DayPlannerService(
                taskRepository: LocalDailyTaskRepository(),
                routineRepository: LocalDailyRoutineRepository()
            )
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
