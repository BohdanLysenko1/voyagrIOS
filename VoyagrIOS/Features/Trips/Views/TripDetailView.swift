import SwiftUI

struct TripDetailView: View {

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    let tripId: UUID

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var error: String?
    @State private var showError = false

    private var trip: Trip? {
        container.tripService.trip(by: tripId)
    }

    var body: some View {
        Group {
            if let trip {
                tripContent(trip)
            } else {
                ContentUnavailableView(
                    "Trip Not Found",
                    systemImage: "airplane.slash",
                    description: Text("This trip may have been deleted")
                )
            }
        }
        .navigationTitle(trip?.name ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if trip != nil {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showEditSheet = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let trip {
                TripFormView(
                    viewModel: TripFormViewModel(
                        tripService: container.tripService,
                        trip: trip
                    )
                )
            }
        }
        .confirmationDialog(
            "Delete Trip",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteTrip()
            }
        } message: {
            Text("Are you sure you want to delete this trip? This action cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                error = nil
            }
        } message: {
            if let error {
                Text(error)
            }
        }
    }

    // MARK: - Content

    private func tripContent(_ trip: Trip) -> some View {
        List {
            Section {
                DetailRow(label: "Destination", value: trip.destination)
                HStack {
                    Text("Status")
                        .foregroundStyle(.secondary)
                    Spacer()
                    StatusBadge(status: trip.status)
                }
            }

            Section("Dates") {
                DetailRow(label: "Start", value: trip.startDate.formatted(date: .long, time: .omitted))
                DetailRow(label: "End", value: trip.endDate.formatted(date: .long, time: .omitted))
                DetailRow(label: "Duration", value: durationText(from: trip.startDate, to: trip.endDate))
            }

            if !trip.notes.isEmpty {
                Section("Notes") {
                    Text(trip.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                DetailRow(label: "Created", value: trip.createdAt.formatted(date: .abbreviated, time: .shortened))
                DetailRow(label: "Updated", value: trip.updatedAt.formatted(date: .abbreviated, time: .shortened))
            } header: {
                Text("Info")
            }
        }
    }

    // MARK: - Helpers

    private func durationText(from start: Date, to end: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: start, to: end).day ?? 0
        if days == 0 {
            return "1 day"
        } else if days == 1 {
            return "2 days"
        } else {
            return "\(days + 1) days"
        }
    }

    private func deleteTrip() {
        isDeleting = true
        Task {
            do {
                try await container.tripService.deleteTrip(by: tripId)
                dismiss()
            } catch {
                self.error = error.localizedDescription
                showError = true
            }
            isDeleting = false
        }
    }
}

#Preview {
    NavigationStack {
        TripDetailView(tripId: UUID())
            .environment(AppContainer())
    }
}
