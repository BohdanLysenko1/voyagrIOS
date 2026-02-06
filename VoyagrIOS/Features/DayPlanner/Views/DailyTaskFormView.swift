import SwiftUI

struct DailyTaskFormView: View {

    @Environment(\.dismiss) private var dismiss

    let service: DayPlannerServiceProtocol
    let task: DailyTask?

    @State private var title: String
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var startTime: Date
    @State private var hasEndTime: Bool
    @State private var endTime: Date
    @State private var category: TaskCategory
    @State private var notes: String

    @State private var isSaving = false
    @State private var error: String?
    @State private var showError = false

    private var isEditing: Bool { task != nil }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    init(service: DayPlannerServiceProtocol, task: DailyTask?, defaultDate: Date) {
        self.service = service
        self.task = task

        if let task {
            _title = State(initialValue: task.title)
            _date = State(initialValue: task.date)
            _hasTime = State(initialValue: task.startTime != nil)
            _startTime = State(initialValue: task.startTime ?? Date())
            _hasEndTime = State(initialValue: task.endTime != nil)
            _endTime = State(initialValue: task.endTime ?? Date().addingTimeInterval(3600))
            _category = State(initialValue: task.category)
            _notes = State(initialValue: task.notes)
        } else {
            _title = State(initialValue: "")
            _date = State(initialValue: defaultDate)
            _hasTime = State(initialValue: false)
            // Default start time to next hour
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: Date())
            let defaultStart = calendar.date(bySettingHour: hour + 1, minute: 0, second: 0, of: Date()) ?? Date()
            _startTime = State(initialValue: defaultStart)
            _hasEndTime = State(initialValue: false)
            _endTime = State(initialValue: defaultStart.addingTimeInterval(3600))
            _category = State(initialValue: .personal)
            _notes = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                scheduleSection
                categorySection
                notesSection
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        Task { await save() }
                    }
                    .disabled(!isValid || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    savingOverlay
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { error = nil }
            } message: {
                if let error {
                    Text(error)
                }
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            TextField("Task name", text: $title)
        } header: {
            Text("Task")
        }
    }

    private var scheduleSection: some View {
        Section {
            DatePicker("Date", selection: $date, displayedComponents: .date)

            Toggle("Set Time", isOn: $hasTime)

            if hasTime {
                DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)

                Toggle("End Time", isOn: $hasEndTime)

                if hasEndTime {
                    DatePicker("End Time", selection: $endTime, in: startTime..., displayedComponents: .hourAndMinute)
                }
            }
        } header: {
            Text("Schedule")
        } footer: {
            if !hasTime {
                Text("Tasks without a time will appear in your to-do list")
            }
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $category) {
                ForEach(TaskCategory.allCases, id: \.self) { cat in
                    Label(cat.displayName, systemImage: cat.icon)
                        .tag(cat)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Add notes...", text: $notes, axis: .vertical)
                .lineLimit(3...6)
        }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ProgressView("Saving...")
                .padding()
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Save

    private func save() async {
        isSaving = true

        do {
            let newTask = DailyTask(
                id: task?.id ?? UUID(),
                title: title.trimmingCharacters(in: .whitespaces),
                date: date,
                startTime: hasTime ? startTime : nil,
                endTime: hasTime && hasEndTime ? endTime : nil,
                isCompleted: task?.isCompleted ?? false,
                category: category,
                notes: notes,
                routineId: task?.routineId,
                createdAt: task?.createdAt ?? Date()
            )

            if isEditing {
                try await service.updateTask(newTask)
            } else {
                try await service.createTask(newTask)
            }

            dismiss()
        } catch {
            self.error = error.localizedDescription
            showError = true
        }

        isSaving = false
    }
}

#Preview("New Task") {
    DailyTaskFormView(
        service: DayPlannerService(
            taskRepository: LocalDailyTaskRepository(),
            routineRepository: LocalDailyRoutineRepository()
        ),
        task: nil,
        defaultDate: Date()
    )
}

#Preview("Edit Task") {
    DailyTaskFormView(
        service: DayPlannerService(
            taskRepository: LocalDailyTaskRepository(),
            routineRepository: LocalDailyRoutineRepository()
        ),
        task: DailyTask(
            title: "Team Meeting",
            date: Date(),
            startTime: Date(),
            category: .work
        ),
        defaultDate: Date()
    )
}
