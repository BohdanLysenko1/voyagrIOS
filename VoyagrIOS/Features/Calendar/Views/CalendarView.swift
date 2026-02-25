import SwiftUI

struct CalendarView: View {

    @Environment(AppContainer.self) private var container
    @State private var selectedDate = Date()
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showTrips = true
    @State private var showEvents = true
    @State private var showTasks = true
    @State private var selectedTripStatus: TripStatus?
    @State private var selectedEventCategory: EventCategory?
    @State private var showPast = false

    private var tripService: TripServiceProtocol {
        container.tripService
    }

    private var eventService: EventServiceProtocol {
        container.eventService
    }

    private var dayPlannerService: DayPlannerServiceProtocol {
        container.dayPlannerService
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    Text("Calendar")
                        .font(.largeTitle.bold())
                    Spacer()
                    filterMenuButton
                }
                .padding(.horizontal)
                .padding(.top, 4)
                .padding(.bottom, 8)

                TripHighlightCalendar(
                    selectedDate: $selectedDate,
                    trips: tripService.trips,
                    events: eventService.events,
                    tasks: dayPlannerService.allTasks
                )
                .padding(.vertical, 8)

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
                    contentList
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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

    // MARK: - Content List

    private var contentList: some View {
        let selected = itemsForSelectedDate
        let upcoming = upcomingItems
        let past = pastItems
        let hasSelected = !selected.trips.isEmpty || !selected.events.isEmpty || !selected.tasks.isEmpty
        let hasUpcoming = !upcoming.trips.isEmpty || !upcoming.events.isEmpty
        let hasPast = !past.trips.isEmpty || !past.events.isEmpty

        return Group {
            if !hasSelected && !hasUpcoming && !hasPast {
                Spacer()
                emptyStateView
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        if hasSelected {
                            selectedDateSection(selected)
                        }
                        if hasUpcoming {
                            upcomingSection(upcoming)
                        }
                        if hasPast {
                            pastSection(past)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))
            }
        }
    }

    // MARK: - Sections

    private func selectedDateSection(_ items: (trips: [Trip], events: [Event], tasks: [DailyTask])) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.listSpacing) {
            sectionDivider(
                selectedDate.formatted(.dateTime.month(.wide).day()),
                icon: "calendar"
            )
            tripLinks(items.trips)
            eventLinks(items.events)
            if !items.tasks.isEmpty {
                VStack(spacing: AppTheme.listSpacing) {
                    ForEach(items.tasks) { task in
                        CalendarTaskRow(task: task, service: dayPlannerService)
                    }
                }
            }
        }
    }

    private func upcomingSection(_ items: (trips: [Trip], events: [Event])) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.listSpacing) {
            sectionDivider("Upcoming", icon: "arrow.right.circle")
            tripLinks(items.trips)
            eventLinks(items.events)
        }
    }

    private func pastSection(_ items: (trips: [Trip], events: [Event])) -> some View {
        let count = items.trips.count + items.events.count

        return VStack(alignment: .leading, spacing: AppTheme.listSpacing) {
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showPast.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.counterclockwise")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("Past")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showPast ? 90 : 0))
                }
                .padding(.vertical, 12)
                .padding(.horizontal)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            }
            .buttonStyle(.plain)

            if showPast {
                tripLinks(items.trips)
                eventLinks(items.events)
            }
        }
    }

    // MARK: - Reusable UI Components

    @ViewBuilder
    private func tripLinks(_ trips: [Trip]) -> some View {
        if !trips.isEmpty {
            VStack(spacing: AppTheme.listSpacing) {
                ForEach(trips) { trip in
                    NavigationLink(value: TripDestination(id: trip.id)) {
                        TripCard(trip: trip, style: .compact)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func eventLinks(_ events: [Event]) -> some View {
        if !events.isEmpty {
            VStack(spacing: AppTheme.listSpacing) {
                ForEach(events) { event in
                    NavigationLink(value: EventDestination(id: event.id)) {
                        EventCard(event: event, style: .compact)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func sectionDivider(_ title: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack { Divider() }
        }
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

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            if hasActiveFilters {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                VStack(spacing: 6) {
                    Text("No Matches")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Try adjusting your filters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button("Reset Filters", action: resetFilters)
                    .buttonStyle(.bordered)
            } else {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 50))
                    .foregroundStyle(AppTheme.calendarGradient)

                VStack(spacing: 6) {
                    Text("Nothing Scheduled")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("No trips, events, or tasks on this date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    // MARK: - Filter Menu

    private var hasActiveFilters: Bool {
        !showTrips || !showEvents || !showTasks || selectedTripStatus != nil || selectedEventCategory != nil
    }

    private func resetFilters() {
        showTrips = true
        showEvents = true
        showTasks = true
        selectedTripStatus = nil
        selectedEventCategory = nil
    }

    private var filterMenuButton: some View {
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
                Toggle("Daily Tasks", isOn: $showTasks)
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

            Button("Reset Filters", action: resetFilters)
                .disabled(!hasActiveFilters)
        } label: {
            Label("Filter", systemImage: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
    }

    // MARK: - Data

    private var itemsForSelectedDate: (trips: [Trip], events: [Event], tasks: [DailyTask]) {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: selectedDate)

        let trips = showTrips ? tripService.trips.filter { trip in
            let inRange = isTripOnDate(trip, date: selectedDay, calendar: calendar)
            return inRange && matchesTripFilter(trip)
        } : []

        let events = showEvents ? eventService.events.filter { event in
            let onDate = calendar.isDate(event.date, inSameDayAs: selectedDate)
            return onDate && matchesEventFilter(event)
        } : []

        let tasks = showTasks ? dayPlannerService.allTasks
            .filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
            .sorted { lhs, rhs in
                switch (lhs.startTime, rhs.startTime) {
                case let (l?, r?): return l < r
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return lhs.title < rhs.title
                }
            } : []

        return (trips, events, tasks)
    }

    /// Active and upcoming trips/events, excluding items already shown for the selected date.
    private var upcomingItems: (trips: [Trip], events: [Event]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: selectedDate)

        let trips = showTrips ? tripService.trips.filter { trip in
            let status = trip.computedStatus
            guard status == .active || status == .upcoming || status == .planning else { return false }
            guard !isTripOnDate(trip, date: selectedDay, calendar: calendar) else { return false }
            return matchesTripFilter(trip)
        }
        .sorted { $0.startDate < $1.startDate } : []

        let events = showEvents ? eventService.events.filter { event in
            let eventDay = calendar.startOfDay(for: event.date)
            guard eventDay >= today else { return false }
            guard !calendar.isDate(event.date, inSameDayAs: selectedDate) else { return false }
            return matchesEventFilter(event)
        }
        .sorted { $0.date < $1.date } : []

        return (trips, events)
    }

    /// Completed trips and past events, excluding items already shown for the selected date.
    private var pastItems: (trips: [Trip], events: [Event]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selectedDay = calendar.startOfDay(for: selectedDate)

        let trips = showTrips ? tripService.trips.filter { trip in
            guard trip.computedStatus == .completed else { return false }
            guard !isTripOnDate(trip, date: selectedDay, calendar: calendar) else { return false }
            return matchesTripFilter(trip)
        }
        .sorted { $0.endDate > $1.endDate } : []

        let events = showEvents ? eventService.events.filter { event in
            let eventDay = calendar.startOfDay(for: event.date)
            guard eventDay < today else { return false }
            guard !calendar.isDate(event.date, inSameDayAs: selectedDate) else { return false }
            return matchesEventFilter(event)
        }
        .sorted { $0.date > $1.date } : []

        return (trips, events)
    }

    // MARK: - Filtering Helpers

    private func isTripOnDate(_ trip: Trip, date: Date, calendar: Calendar) -> Bool {
        let tripStart = calendar.startOfDay(for: trip.startDate)
        let tripEnd = calendar.startOfDay(for: trip.endDate)
        return date >= tripStart && date <= tripEnd
    }

    private func matchesTripFilter(_ trip: Trip) -> Bool {
        guard let statusFilter = selectedTripStatus else { return true }
        return trip.status == statusFilter
    }

    private func matchesEventFilter(_ event: Event) -> Bool {
        guard let categoryFilter = selectedEventCategory else { return true }
        return event.category == categoryFilter
    }

    private func loadData() async {
        isLoading = true
        error = nil
        do {
            async let tripsLoad: () = tripService.loadTrips()
            async let eventsLoad: () = eventService.loadEvents()
            async let tasksLoad: () = dayPlannerService.loadData()
            _ = try await (tripsLoad, eventsLoad, tasksLoad)
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

#Preview {
    CalendarView()
        .environment(AppContainer())
}
