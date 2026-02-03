import SwiftUI

struct CalendarView: View {

    @Environment(AppContainer.self) private var container
    @State private var selectedDate = Date()
    @State private var isLoading = true
    @State private var error: Error?

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
                        ContentUnavailableView(
                            "Nothing Scheduled",
                            systemImage: "calendar.badge.clock",
                            description: Text("No trips or events on this date")
                        )
                        Spacer()
                    } else {
                        itemsList(trips: trips, events: events)
                    }
                }
            }
            .navigationTitle("Calendar")
        }
        .task {
            await loadData()
        }
    }

    private func itemsList(trips: [Trip], events: [Event]) -> some View {
        List {
            if !trips.isEmpty {
                Section("Trips") {
                    ForEach(trips) { trip in
                        CalendarTripRow(trip: trip)
                    }
                }
            }

            if !events.isEmpty {
                Section("Events") {
                    ForEach(events) { event in
                        CalendarEventRow(event: event)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            "Unable to Load",
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
    }

    private var itemsForSelectedDate: (trips: [Trip], events: [Event]) {
        let calendar = Calendar.current

        let trips = tripService.trips.filter { trip in
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let tripStart = calendar.startOfDay(for: trip.startDate)
            let tripEnd = calendar.startOfDay(for: trip.endDate)
            return startOfDay >= tripStart && startOfDay <= tripEnd
        }

        let events = eventService.events.filter { event in
            calendar.isDate(event.date, inSameDayAs: selectedDate)
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

// MARK: - Calendar Rows

private struct CalendarTripRow: View {
    let trip: Trip

    var body: some View {
        HStack {
            Image(systemName: "airplane")
                .foregroundStyle(.blue)
            VStack(alignment: .leading) {
                Text(trip.name)
                    .font(.subheadline)
                Text(trip.destination)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct CalendarEventRow: View {
    let event: Event

    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.subheadline)
                if !event.location.isEmpty {
                    Text(event.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    CalendarView()
        .environment(AppContainer())
}
