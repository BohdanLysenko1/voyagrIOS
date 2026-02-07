import SwiftUI

struct TripsView: View {

    @Environment(AppContainer.self) private var container
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showAddTrip = false
    @State private var editingTrip: Trip?
    @State private var searchText = ""
    @State private var selectedStatusFilter: TripStatus?
    @State private var isSelectMode = false
    @State private var selectedTrips: Set<UUID> = []
    @State private var showDeleteConfirmation = false

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
            ZStack(alignment: .bottom) {
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

                if isSelectMode && !selectedTrips.isEmpty {
                    deleteBar
                }
            }
            .navigationTitle("Trips")
            .searchable(text: $searchText, prompt: "Search trips")
            .toolbar {
                if isSelectMode {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Done") {
                            withAnimation {
                                isSelectMode = false
                                selectedTrips.removeAll()
                            }
                        }
                    }

                    ToolbarItem(placement: .cancellationAction) {
                        Button(selectedTrips.count == filteredTrips.count ? "Deselect All" : "Select All") {
                            if selectedTrips.count == filteredTrips.count {
                                selectedTrips.removeAll()
                            } else {
                                selectedTrips = Set(filteredTrips.map(\.id))
                            }
                        }
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showAddTrip = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }

                    ToolbarItem(placement: .secondaryAction) {
                        selectButton
                    }

                    ToolbarItem(placement: .secondaryAction) {
                        filterMenu
                    }
                }
            }
            .sheet(isPresented: $showAddTrip) {
                TripFormView(
                    viewModel: TripFormViewModel(tripService: container.tripService)
                )
            }
            .sheet(item: $editingTrip) { trip in
                TripFormView(
                    viewModel: TripFormViewModel(tripService: container.tripService, trip: trip)
                )
            }
            .confirmationDialog(
                "Delete \(selectedTrips.count) Trip\(selectedTrips.count == 1 ? "" : "s")?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteSelectedTrips()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .task {
            await loadTrips()
        }
    }

    // MARK: - Select Button

    private var selectButton: some View {
        Button {
            withAnimation {
                isSelectMode = true
            }
        } label: {
            Label("Select", systemImage: "checkmark.circle")
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

    // MARK: - Delete Bar

    private var deleteBar: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            HStack {
                Image(systemName: "trash")
                Text("Delete \(selectedTrips.count) Trip\(selectedTrips.count == 1 ? "" : "s")")
            }
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Views

    private var tripsList: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.listSpacing) {
                ForEach(filteredTrips) { trip in
                    if isSelectMode {
                        selectableTripRow(trip)
                    } else {
                        NavigationLink(value: trip.id) {
                            TripCard(trip: trip)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                editingTrip = trip
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                deleteTrip(trip)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .padding(.bottom, isSelectMode && !selectedTrips.isEmpty ? 70 : 0)
        }
        .background(Color(.systemGroupedBackground))
        .navigationDestination(for: UUID.self) { tripId in
            TripDetailView(tripId: tripId)
        }
        .refreshable {
            await loadTrips()
        }
    }

    private func selectableTripRow(_ trip: Trip) -> some View {
        HStack(spacing: 12) {
            Image(systemName: selectedTrips.contains(trip.id) ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 24))
                .foregroundStyle(selectedTrips.contains(trip.id) ? .blue : .secondary)

            TripCard(trip: trip)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(response: 0.2)) {
                if selectedTrips.contains(trip.id) {
                    selectedTrips.remove(trip.id)
                } else {
                    selectedTrips.insert(trip.id)
                }
            }
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "airplane.circle")
                .font(.system(size: 70))
                .foregroundStyle(AppTheme.tripGradient)

            VStack(spacing: 8) {
                Text("No Trips Yet")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Start planning your next adventure!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                showAddTrip = true
            } label: {
                Label("Plan a Trip", systemImage: "plus")
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

    private func deleteTrip(_ trip: Trip) {
        Task {
            do {
                try await tripService.deleteTrip(by: trip.id)
            } catch {
                self.error = error
            }
        }
    }

    private func deleteSelectedTrips() {
        let idsToDelete = selectedTrips
        Task {
            for id in idsToDelete {
                do {
                    try await tripService.deleteTrip(by: id)
                } catch {
                    self.error = error
                }
            }
            withAnimation {
                selectedTrips.removeAll()
                isSelectMode = false
            }
        }
    }
}

#Preview {
    TripsView()
        .environment(AppContainer())
}
