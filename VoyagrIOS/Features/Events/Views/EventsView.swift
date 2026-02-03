import SwiftUI

struct EventsView: View {

    @Environment(AppContainer.self) private var container
    @State private var isLoading = true
    @State private var error: Error?

    private var eventService: EventServiceProtocol {
        container.eventService
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error {
                    errorView(error)
                } else if eventService.events.isEmpty {
                    emptyView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Events")
        }
        .task {
            await loadEvents()
        }
    }

    private var eventsList: some View {
        List {
            ForEach(eventService.events) { event in
                EventRow(event: event)
            }
            .onDelete(perform: deleteEvents)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Events",
            systemImage: "star",
            description: Text("Your scheduled events will appear here")
        )
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            "Unable to Load Events",
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
    }

    private func loadEvents() async {
        isLoading = true
        error = nil
        do {
            try await eventService.loadEvents()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func deleteEvents(at offsets: IndexSet) {
        let idsToDelete = offsets.map { eventService.events[$0].id }
        Task {
            for id in idsToDelete {
                do {
                    try await eventService.deleteEvent(by: id)
                } catch {
                    self.error = error
                }
            }
        }
    }
}

// MARK: - Event Row

private struct EventRow: View {
    let event: Event

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(event.title)
                    .font(.headline)
                Spacer()
                CategoryBadge(category: event.category)
            }
            if !event.location.isEmpty {
                Text(event.location)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        if event.isAllDay {
            return Self.dateOnlyFormatter.string(from: event.date)
        } else {
            return Self.dateTimeFormatter.string(from: event.date)
        }
    }
}

// MARK: - Category Badge

private struct CategoryBadge: View {
    let category: EventCategory

    var body: some View {
        Text(category.rawValue.capitalized)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.2))
            .clipShape(Capsule())
    }
}

#Preview {
    EventsView()
        .environment(AppContainer())
}
