import SwiftUI

struct DailyTaskRow: View {
    let task: DailyTask
    var linkIcon: String? = nil
    var linkLabel: String? = nil
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3)) {
                    onToggle()
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundStyle(task.isCompleted ? .green : task.category.color)
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                HStack(spacing: 8) {
                    // Category badge
                    HStack(spacing: 4) {
                        Image(systemName: task.category.icon)
                            .font(.caption2)
                        Text(task.category.displayName)
                            .font(.caption)
                    }
                    .foregroundStyle(task.category.color)

                    if task.routineId != nil {
                        RoutineBadge()
                    }

                    // Time if scheduled
                    if let timeRange = task.formattedTimeRange {
                        Text(timeRange)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Link indicator
                    if let icon = linkIcon, let label = linkLabel {
                        HStack(spacing: 3) {
                            Image(systemName: icon)
                                .font(.caption2)
                            Text(label)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 10)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
        .contextMenu {
            Button { onEdit() } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) { onDelete() } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        DailyTaskRow(
            task: DailyTask(
                title: "Morning workout",
                date: Date(),
                startTime: Date(),
                endTime: Date().addingTimeInterval(3600),
                category: .health
            ),
            onToggle: {},
            onEdit: {},
            onDelete: {}
        )

        Divider().padding(.leading, 50)

        DailyTaskRow(
            task: DailyTask(
                title: "Buy groceries",
                date: Date(),
                category: .errands
            ),
            onToggle: {},
            onEdit: {},
            onDelete: {}
        )

        Divider().padding(.leading, 50)

        DailyTaskRow(
            task: DailyTask(
                title: "Completed task",
                date: Date(),
                isCompleted: true,
                category: .work
            ),
            onToggle: {},
            onEdit: {},
            onDelete: {}
        )
    }
    .background(AppTheme.cardBackground)
}
