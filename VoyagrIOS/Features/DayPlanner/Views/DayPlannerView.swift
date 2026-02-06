import SwiftUI

struct DayPlannerView: View {

    @Environment(AppContainer.self) private var container
    @State private var showAddTask = false
    @State private var showRoutines = false
    @State private var editingTask: DailyTask?
    @State private var isLoading = true
    @State private var error: String?

    private var service: DayPlannerServiceProtocol {
        container.dayPlannerService
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selector
                dateSelector

                Divider()

                // Content
                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("My Day")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showAddTask = true
                        } label: {
                            Label("Add Task", systemImage: "plus")
                        }

                        Button {
                            showRoutines = true
                        } label: {
                            Label("Manage Routines", systemImage: "repeat")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                DailyTaskFormView(
                    service: service,
                    task: nil,
                    defaultDate: service.selectedDate
                )
            }
            .sheet(item: $editingTask) { task in
                DailyTaskFormView(
                    service: service,
                    task: task,
                    defaultDate: service.selectedDate
                )
            }
            .sheet(isPresented: $showRoutines) {
                RoutinesListView(service: service)
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - Date Selector

    private var dateSelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(dateRange, id: \.self) { date in
                        DateTab(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: service.selectedDate),
                            taskCount: tasksCount(for: date)
                        )
                        .id(date)
                        .onTapGesture {
                            withAnimation {
                                service.selectedDate = date
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
            }
            .background(Color(.systemBackground))
            .onAppear {
                proxy.scrollTo(service.selectedDate, anchor: .center)
            }
            .onChange(of: service.selectedDate) { _, newDate in
                withAnimation {
                    proxy.scrollTo(newDate, anchor: .center)
                }
            }
        }
    }

    private var dateRange: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dates: [Date] = []

        // 7 days before and 14 days after
        for offset in -7...14 {
            if let date = calendar.date(byAdding: .day, value: offset, to: today) {
                dates.append(date)
            }
        }

        return dates
    }

    private func tasksCount(for date: Date) -> Int {
        let calendar = Calendar.current
        return service.allTasks.filter { calendar.isDate($0.date, inSameDayAs: date) }.count
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Today's summary
                summaryCard

                // Scheduled tasks (timeline)
                if !service.scheduledTasks.isEmpty {
                    scheduledSection
                }

                // Unscheduled tasks (to-do list)
                if !service.unscheduledTasks.isEmpty {
                    todoSection
                }

                // Empty state
                if service.tasksForSelectedDate.isEmpty {
                    emptyStateView
                }
            }
            .padding()
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateTitle)
                        .font(.title2)
                        .fontWeight(.bold)

                    let completed = service.tasksForSelectedDate.filter { $0.isCompleted }.count
                    let total = service.tasksForSelectedDate.count

                    if total > 0 {
                        Text("\(completed) of \(total) tasks completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No tasks planned")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if !service.tasksForSelectedDate.isEmpty {
                    progressRing
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var dateTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(service.selectedDate) {
            return "Today"
        } else if calendar.isDateInTomorrow(service.selectedDate) {
            return "Tomorrow"
        } else if calendar.isDateInYesterday(service.selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: service.selectedDate)
        }
    }

    private var progressRing: some View {
        let completed = service.tasksForSelectedDate.filter { $0.isCompleted }.count
        let total = service.tasksForSelectedDate.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0

        return ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 6)
                .frame(width: 50, height: 50)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(progressColor(progress).gradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .fontWeight(.bold)
        }
    }

    private func progressColor(_ progress: Double) -> Color {
        if progress == 1.0 { return .green }
        if progress > 0.5 { return .blue }
        return .orange
    }

    // MARK: - Scheduled Section

    private var scheduledSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Schedule", icon: "clock.fill")

            ScheduleTimelineView(
                tasks: service.scheduledTasks,
                onToggle: { task in toggleTask(task) },
                onEdit: { task in editingTask = task },
                onDelete: { task in deleteTask(task) }
            )
        }
    }

    // MARK: - To-Do Section

    private var todoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("To-Do", icon: "checklist")
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                ForEach(service.unscheduledTasks) { task in
                    DailyTaskRow(
                        task: task,
                        onToggle: { toggleTask(task) },
                        onEdit: { editingTask = task },
                        onDelete: { deleteTask(task) }
                    )

                    if task.id != service.unscheduledTasks.last?.id {
                        Divider().padding(.leading, 50)
                    }
                }
            }
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        }
    }

    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sun.max")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)

            VStack(spacing: 6) {
                Text("No Tasks Planned")
                    .font(.headline)

                Text("Add tasks to plan your day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                showAddTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading...")
            Spacer()
        }
    }

    // MARK: - Actions

    private func loadData() async {
        isLoading = true
        do {
            try await service.loadData()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func toggleTask(_ task: DailyTask) {
        Task {
            try? await service.toggleTaskCompletion(task)
        }
    }

    private func deleteTask(_ task: DailyTask) {
        Task {
            try? await service.deleteTask(by: task.id)
        }
    }
}

// MARK: - Date Tab

private struct DateTab: View {
    let date: Date
    let isSelected: Bool
    let taskCount: Int

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(Self.dayFormatter.string(from: date))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : .secondary)

            Text(Self.dateFormatter.string(from: date))
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))

            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .blue)
            }
        }
        .frame(width: 50, height: 70)
        .background(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DayPlannerView()
        .environment(AppContainer())
}
