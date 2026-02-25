import SwiftUI

struct TripFormView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: TripFormViewModel
    @State private var showError = false

    init(viewModel: TripFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                detailsSection
                datesSection
                notesSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(viewModel.isEditing ? "Edit Trip" : "New Trip")
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
            TextField("Trip Name", text: $viewModel.name)
                .textContentType(.name)

            LocationSearchField(
                text: $viewModel.destination,
                latitude: $viewModel.destinationLatitude,
                longitude: $viewModel.destinationLongitude,
                label: "Destination",
                placeholder: "Search destination..."
            )
        } header: {
            Text("Details")
        } footer: {
            if let error = viewModel.nameError ?? viewModel.destinationError {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }

    private var datesSection: some View {
        Section {
            DatePicker(
                "Start Date",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )

            DatePicker(
                "End Date",
                selection: $viewModel.endDate,
                in: viewModel.startDate...,
                displayedComponents: .date
            )
        } header: {
            Text("Dates")
        } footer: {
            if let error = viewModel.dateError {
                Text(error)
                    .foregroundStyle(.red)
            }
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

#Preview("New Trip") {
    TripFormView(
        viewModel: TripFormViewModel(
            tripService: TripService(repository: LocalTripRepository())
        )
    )
}

#Preview("Edit Trip") {
    TripFormView(
        viewModel: TripFormViewModel(
            tripService: TripService(repository: LocalTripRepository()),
            trip: Trip(
                name: "Summer Vacation",
                destination: "Paris, France",
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 7)
            )
        )
    )
}
