import SwiftUI

struct TripsView: View {

    @Environment(AppContainer.self) private var container
    @State private var isLoading = true
    @State private var error: Error?

    private var tripService: TripServiceProtocol {
        container.tripService
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
                } else {
                    tripsList
                }
            }
            .navigationTitle("Trips")
        }
        .task {
            await loadTrips()
        }
    }

    private var tripsList: some View {
        List {
            ForEach(tripService.trips) { trip in
                TripRow(trip: trip)
            }
            .onDelete(perform: deleteTrips)
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Trips Yet",
            systemImage: "airplane",
            description: Text("Your upcoming trips will appear here")
        )
    }

    private func errorView(_ error: Error) -> some View {
        ContentUnavailableView(
            "Unable to Load Trips",
            systemImage: "exclamationmark.triangle",
            description: Text(error.localizedDescription)
        )
    }

    private func loadTrips() async {
        isLoading = true
        error = nil
        do {
            try await tripService.loadTrips()
        } catch {
            self.error = error
        }
        isLoading = false
    }

    private func deleteTrips(at offsets: IndexSet) {
        let idsToDelete = offsets.map { tripService.trips[$0].id }
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
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.name)
                .font(.headline)
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
        return "\(start) - \(end)"
    }
}

#Preview {
    TripsView()
        .environment(AppContainer())
}
