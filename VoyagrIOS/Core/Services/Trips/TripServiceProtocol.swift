import Foundation

@MainActor
protocol TripServiceProtocol: AnyObject {
    var trips: [Trip] { get }

    func loadTrips() async throws
    func createTrip(_ trip: Trip) async throws
    func updateTrip(_ trip: Trip) async throws
    func deleteTrip(by id: UUID) async throws
    func trip(by id: UUID) -> Trip?
}
