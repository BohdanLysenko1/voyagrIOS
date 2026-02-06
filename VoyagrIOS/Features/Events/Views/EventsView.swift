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
        ScrollView {
            LazyVStack(spacing: AppTheme.listSpacing) {
                ForEach(filteredEvents) { event in
                    NavigationLink(value: event.id) {
                        EventCard(event: event)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            deleteEvent(event)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: UUID.self) { eventId in
            EventDetailView(eventId: eventId)
        }
        .refreshable {
            await loadEvents()
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle")
                .font(.system(size: 70))
                .foregroundStyle(AppTheme.eventGradient)

            VStack(spacing: 8) {
                Text("No Events")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Create events to track your activities!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddEvent = true
            } label: {
                Label("Create Event", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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

    private func deleteEvent(_ event: Event) {
        Task {
            do {
                try await eventService.deleteEvent(by: event.id)
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    EventsView()
        .environment(AppContainer())
}
