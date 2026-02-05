import SwiftUI

struct EventDetailView: View {

    @Environment(AppContainer.self) private var container
    @Environment(\.dismiss) private var dismiss

    let eventId: UUID

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var error: String?
    @State private var showError = false

    private var event: Event? {
        container.eventService.event(by: eventId)
    }

    var body: some View {
        Group {
            if let event {
                eventContent(event)
            } else {
                ContentUnavailableView(
                    "Event Not Found",
                    systemImage: "star.slash",
                    description: Text("This event may have been deleted")
                )
            }
        }
        .navigationTitle(event?.title ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if event != nil {
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
            if let event {
                EventFormView(
                    viewModel: EventFormViewModel(
                        eventService: container.eventService,
                        event: event
                    )
                )
            }
        }
        .confirmationDialog(
            "Delete Event",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
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

    private func eventContent(_ event: Event) -> some View {
        List {
            Section {
                HStack {
                    Label(event.category.displayName, systemImage: event.category.icon)
                    Spacer()
                    CategoryBadge(category: event.category)
                }

                if !event.location.isEmpty {
                    Label(event.location, systemImage: "location")
                }
            }

            Section("Date & Time") {
                if event.isAllDay {
                    DetailRow(label: "Date", value: event.date.formatted(date: .long, time: .omitted))
                    DetailRow(label: "All Day", value: "Yes")
                } else {
                    DetailRow(label: "Starts", value: event.date.formatted(date: .long, time: .shortened))
                    if let endDate = event.endDate {
                        DetailRow(label: "Ends", value: endDate.formatted(date: .long, time: .shortened))
                        DetailRow(label: "Duration", value: durationText(from: event.date, to: endDate))
                    }
                }
            }

            if !event.notes.isEmpty {
                Section("Notes") {
                    Text(event.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                DetailRow(label: "Created", value: event.createdAt.formatted(date: .abbreviated, time: .shortened))
                DetailRow(label: "Updated", value: event.updatedAt.formatted(date: .abbreviated, time: .shortened))
            } header: {
                Text("Info")
            }
        }
    }

    // MARK: - Helpers

    private func durationText(from start: Date, to end: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: start, to: end)
        let hours = components.hour ?? 0
        let minutes = components.minute ?? 0

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }

    private func deleteEvent() {
        isDeleting = true
        Task {
            do {
                try await container.eventService.deleteEvent(by: eventId)
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
        EventDetailView(eventId: UUID())
            .environment(AppContainer())
    }
}
