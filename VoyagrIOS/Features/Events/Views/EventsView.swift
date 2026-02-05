import SwiftUI

struct EventsView: View {

    @Environment(AppContainer.self) private var container
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showAddEvent = false
    @State private var searchText = ""
    @State private var selectedCategoryFilter: EventCategory?

    private var eventService: EventServiceProtocol {
        container.eventService
    }

    private var filteredEvents: [Event] {
        var events = eventService.events

        if let category = selectedCategoryFilter {
            events = events.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            events = events.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.location.localizedCaseInsensitiveContains(searchText)
            }
        }

        return events
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
                } else if filteredEvents.isEmpty {
                    noResultsView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Events")
            .searchable(text: $searchText, prompt: "Search events")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddEvent = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showAddEvent) {
                EventFormView(
                    viewModel: EventFormViewModel(eventService: container.eventService)
                )
            }
        }
        .task {
            await loadEvents()
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Button {
                selectedCategoryFilter = nil
            } label: {
                HStack {
                    Text("All Categories")
                    if selectedCategoryFilter == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(EventCategory.allCases, id: \.self) { category in
                Button {
                    selectedCategoryFilter = category
                } label: {
                    HStack {
                        Label(category.displayName, systemImage: category.icon)
                        if selectedCategoryFilter == category {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: selectedCategoryFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }

    // MARK: - Views

    private var eventsList: some View {
        List {
            ForEach(filteredEvents) { event in
                NavigationLink(value: event.id) {
                    EventRow(event: event)
                }
            }
            .onDelete(perform: deleteEvents)
        }
        .navigationDestination(for: UUID.self) { eventId in
            EventDetailView(eventId: eventId)
        }
        .refreshable {
            await loadEvents()
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Events",
            systemImage: "star",
            description: Text("Tap + to create your first event")
        )
    }

    @ViewBuilder
    private var noResultsView: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if let category = selectedCategoryFilter {
            ContentUnavailableView(
                "No \(category.displayName) Events",
                systemImage: category.icon,
                description: Text("No events in this category")
            )
        } else {
            ContentUnavailableView.search
        }
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Events", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task { await loadEvents() }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Actions

    private func loadEvents() async {
        isLoading = eventService.events.isEmpty
        error = nil
        do {
            try await eventService.loadEvents()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func deleteEvents(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredEvents[$0].id }
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(event.title)
                    .font(.headline)
                Spacer()
                CategoryBadge(category: event.category)
            }

            if !event.location.isEmpty {
                Label(event.location, systemImage: "location")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .labelStyle(.titleOnly)
            }

            HStack {
                Image(systemName: event.isAllDay ? "calendar" : "clock")
                    .font(.caption)
                Text(formattedDate)
                    .font(.caption)
            }
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

#Preview {
    EventsView()
        .environment(AppContainer())
}
