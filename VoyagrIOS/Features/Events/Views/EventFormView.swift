import SwiftUI

struct EventFormView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: EventFormViewModel
    @State private var showError = false

    init(viewModel: EventFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                dateTimeSection
                categorySection
                notesSection
            }
            .navigationTitle(viewModel.isEditing ? "Edit Event" : "New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditing ? "Save" : "Add") {
                        Task { await viewModel.save() }
                    }
                    .disabled(!viewModel.isValid || viewModel.isSaving)
                }
            }
            .overlay {
                if viewModel.isSaving {
                    savingOverlay
                }
            }
            .onChange(of: viewModel.error) { _, newError in
                showError = newError != nil
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
            .onChange(of: viewModel.didSave) { _, didSave in
                if didSave {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Sections

    private var detailsSection: some View {
        Section {
            TextField("Event Title", text: $viewModel.title)

            TextField("Location (optional)", text: $viewModel.location)
                .textContentType(.addressCity)
        } header: {
            Text("Details")
        } footer: {
            if let error = viewModel.titleError {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }

    private var dateTimeSection: some View {
        Section {
            Toggle("All Day", isOn: $viewModel.isAllDay)

            if viewModel.isAllDay {
                DatePicker(
                    "Date",
                    selection: $viewModel.date,
                    displayedComponents: .date
                )
            } else {
                DatePicker(
                    "Starts",
                    selection: $viewModel.date,
                    displayedComponents: [.date, .hourAndMinute]
                )

                Toggle("End Time", isOn: $viewModel.hasEndDate)

                if viewModel.hasEndDate {
                    DatePicker(
                        "Ends",
                        selection: Binding(
                            get: { viewModel.endDate ?? viewModel.date.addingTimeInterval(3600) },
                            set: { viewModel.endDate = $0 }
                        ),
                        in: viewModel.date...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
        } header: {
            Text("Date & Time")
        } footer: {
            if let error = viewModel.dateError {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }

    private var categorySection: some View {
        Section("Category") {
            Picker("Category", selection: $viewModel.category) {
                ForEach(EventCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.icon)
                        .tag(category)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Add notes...", text: $viewModel.notes, axis: .vertical)
                .lineLimit(4...8)
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
}

#Preview("New Event") {
    EventFormView(
        viewModel: EventFormViewModel(
            eventService: EventService(repository: LocalEventRepository())
        )
    )
}

#Preview("Edit Event") {
    EventFormView(
        viewModel: EventFormViewModel(
            eventService: EventService(repository: LocalEventRepository()),
            event: Event(
                title: "Team Meeting",
                date: Date(),
                location: "Conference Room A",
                category: .meeting
            )
        )
    )
}
