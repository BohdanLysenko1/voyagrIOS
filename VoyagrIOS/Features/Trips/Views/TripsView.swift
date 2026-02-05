import SwiftUI

struct TripsView: View {

    @Environment(AppContainer.self) private var container
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showAddTrip = false
    @State private var searchText = ""
    @State private var selectedStatusFilter: TripStatus?

    private var tripService: TripServiceProtocol {
        container.tripService
    }

    private var filteredTrips: [Trip] {
        var trips = tripService.trips

        if let status = selectedStatusFilter {
            trips = trips.filter { $0.status == status }
        }

        if !searchText.isEmpty {
            trips = trips.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.destination.localizedCaseInsensitiveContains(searchText)
            }
        }

        return trips
    }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView()
                } else if let error {
                    errorView(error)
                } else if tripService.trips.isEmpty {
                    emptyView
                } else if filteredTrips.isEmpty {
                    noResultsView
                } else {
                    tripsList
                }
            }
            .navigationTitle("Trips")
            .searchable(text: $searchText, prompt: "Search trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .secondaryAction) {
                    filterMenu
                }
            }
            .sheet(isPresented: $showAddTrip) {
                TripFormView(
                    viewModel: TripFormViewModel(tripService: container.tripService)
                )
            }
        }
        .task {
            await loadTrips()
        }
    }

    // MARK: - Filter Menu

    private var filterMenu: some View {
        Menu {
            Button {
                selectedStatusFilter = nil
            } label: {
                HStack {
                    Text("All Statuses")
                    if selectedStatusFilter == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }

            Divider()

            ForEach(TripStatus.allCases, id: \.self) { status in
                Button {
                    selectedStatusFilter = status
                } label: {
                    HStack {
                        Text(status.displayName)
                        if selectedStatusFilter == status {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Filter", systemImage: selectedStatusFilter == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
        }
    }

    // MARK: - Views

    private var tripsList: some View {
        List {
            ForEach(filteredTrips) { trip in
                NavigationLink(value: trip.id) {
                    TripRow(trip: trip)
                }
            }
            .onDelete(perform: deleteTrips)
        }
        .navigationDestination(for: UUID.self) { tripId in
            TripDetailView(tripId: tripId)
        }
        .refreshable {
            await loadTrips()
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Trips Yet",
            systemImage: "airplane",
            description: Text("Tap + to plan your first trip")
        )
    }

    @ViewBuilder
    private var noResultsView: some View {
        if !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else if let status = selectedStatusFilter {
            ContentUnavailableView(
                "No \(status.displayName) Trips",
                systemImage: "airplane",
                description: Text("No trips with this status")
            )
        } else {
            ContentUnavailableView.search
        }
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Trips", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Retry") {
                Task { await loadTrips() }
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Actions

    private func loadTrips() async {
        isLoading = tripService.trips.isEmpty
        error = nil
        do {
            try await tripService.loadTrips()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func deleteTrips(at offsets: IndexSet) {
        let idsToDelete = offsets.map { filteredTrips[$0].id }
        Task {
            for id in idsToDelete {
                do {
                    try await tripService.deleteTrip(by: id)
                } catch {
                    self.error = error
                }
            }
        }
    }
}

// MARK: - Trip Row

private struct TripRow: View {
    let trip: Trip

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trip.name)
                    .font(.headline)
                Spacer()
                StatusBadge(status: trip.status)
            }

            Text(trip.destination)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(dateRange)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var dateRange: String {
        let start = Self.dateFormatter.string(from: trip.startDate)
        let end = Self.dateFormatter.string(from: trip.endDate)
        return "\(start) – \(end)"
    }
}

#Preview {
    TripsView()
        .environment(AppContainer())
}
