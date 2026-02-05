import SwiftUI

struct CalendarView: View {

    @Environment(AppContainer.self) private var container
    @State private var selectedDate = Date()
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showTrips = true
    @State private var showEvents = true
    @State private var selectedTripStatus: TripStatus?
    @State private var selectedEventCategory: EventCategory?

    private var tripService: TripServiceProtocol {
        container.tripService
    }

    private var eventService: EventServiceProtocol {
        container.eventService
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Divider()

                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if let error {
                    Spacer()
                    errorView(error)
                    Spacer()
                } else {
                    let (trips, events) = itemsForSelectedDate
                    if trips.isEmpty && events.isEmpty {
                        Spacer()
                        emptyStateView
                        Spacer()
                    } else {
                        itemsList(trips: trips, events: events)
                    }
                }
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .secondaryAction) {
                    filterMenu
                }
            }
            .navigationDestination(for: TripDestination.self) { destination in
                TripDetailView(tripId: destination.id)
            }
            .navigationDestination(for: EventDestination.self) { destination in
                EventDetailView(eventId: destination.id)
            }
        }
        .task {
            await loadData()
        }
    }

    // MARK: - Filter Menu

    private var hasActiveFilters: Bool {
        !showTrips || !showEvents || selectedTripStatus != nil || selectedEventCategory != nil
    }

    private var emptyStateView: some View {
        Group {
            if hasActiveFilters {
                ContentUnavailableView(
                    "No Matches",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("Try adjusting your filters")
                )
            } else {
                ContentUnavailableView(
                    "Nothing Scheduled",
                    systemImage: "calendar.badge.clock",
                    description: Text("No trips or events on this date")
                )
            }
        }
    }

    private var filterMenu: some View {
        Menu {
            Section("Show") {
                Toggle("Trips", isOn: Binding(
                    get: { showTrips },
                    set: { newValue in
                        showTrips = newValue
                        if !newValue { selectedTripStatus = nil }
                    }
                ))
                Toggle("Events", isOn: Binding(
                    get: { showEvents },
                    set: { newValue in
                        showEvents = newValue
                        if !newValue { selectedEventCategory = nil }
                    }
                ))
            }

            if showTrips {
                Section("Trip Status") {
                    Button {
                        selectedTripStatus = nil
                    } label: {
                        HStack {
                            Text("All Statuses")
                            if selectedTripStatus == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    ForEach(TripStatus.allCases, id: \.self) { status in
                        Button {
                            selectedTripStatus = status
                        } label: {
                            HStack {
                                Text(status.displayName)
                                if selectedTripStatus == status {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            if showEvents {
                Section("Event Category") {
                    Button {
                        selectedEventCategory = nil
                    } label: {
                        HStack {
                            Text("All Categories")
                            if selectedEventCategory == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }

                    ForEach(EventCategory.allCases, id: \.self) { category in
                        Button {
                            selectedEventCategory = category
                        } label: {
                            HStack {
                                Label(category.displayName, systemImage: category.icon)
                                if selectedEventCategory == category {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            Button("Reset Filters") {
                showTrips = true
                showEvents = true
                selectedTripStatus = nil
                selectedEventCategory = nil
            }
            .disabled(!hasActiveFilters)
        } label: {
            Label("Filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    private func itemsList(trips: [Trip], events: [Event]) -> some View {
        List {
            if !trips.isEmpty {
                Section("Trips") {
                    ForEach(trips) { trip in
                        NavigationLink(value: TripDestination(id: trip.id)) {
                            CalendarTripRow(trip: trip)
                        }
                    }
                }
            }

            if !events.isEmpty {
                Section("Events") {
                    ForEach(events) { event in
                        NavigationLink(value: EventDestination(id: event.id)) {
                            CalendarEventRow(event: event)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task { await loadData() }
            }
            .buttonStyle(.bordered)
        }
    }

    private var itemsForSelectedDate: (trips: [Trip], events: [Event]) {
        let calendar = Calendar.current

        var trips: [Trip] = []
        if showTrips {
            trips = tripService.trips.filter { trip in
                let startOfDay = calendar.startOfDay(for: selectedDate)
                let tripStart = calendar.startOfDay(for: trip.startDate)
                let tripEnd = calendar.startOfDay(for: trip.endDate)
                let dateMatches = startOfDay >= tripStart && startOfDay <= tripEnd

                if let statusFilter = selectedTripStatus {
                    return dateMatches && trip.status == statusFilter
                }
                return dateMatches
            }
        }

        var events: [Event] = []
        if showEvents {
            events = eventService.events.filter { event in
                let dateMatches = calendar.isDate(event.date, inSameDayAs: selectedDate)

                if let categoryFilter = selectedEventCategory {
                    return dateMatches && event.category == categoryFilter
                }
                return dateMatches
            }
        }

        return (trips, events)
    }

    private func loadData() async {
        isLoading = true
        error = nil
        do {
            async let tripsLoad: () = tripService.loadTrips()
            async let eventsLoad: () = eventService.loadEvents()
            _ = try await (tripsLoad, eventsLoad)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// MARK: - Navigation Destinations

private struct TripDestination: Hashable {
    let id: UUID
}

private struct EventDestination: Hashable {
    let id: UUID
}

// MARK: - Calendar Rows

private struct CalendarTripRow: View {
    let trip: Trip

    var body: some View {
        HStack {
            Image(systemName: "airplane")
                .foregroundStyle(.blue)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(trip.name)
                    .font(.subheadline)
                Text(trip.destination)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            StatusBadge(status: trip.status)
        }
    }
}

private struct CalendarEventRow: View {
    let event: Event

    var body: some View {
        HStack {
            Image(systemName: event.category.icon)
                .foregroundStyle(event.category.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !event.isAllDay {
                Text(event.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    CalendarView()
        .environment(AppContainer())
}
