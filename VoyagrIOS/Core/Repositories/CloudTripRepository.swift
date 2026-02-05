import Foundation

actor CloudTripRepository: TripRepositoryProtocol {

    private let cloudKit: CloudKitManager

    init(cloudKit: CloudKitManager = .shared) {
        self.cloudKit = cloudKit
    }

    func fetchAll() async throws -> [Trip] {
        try await cloudKit.fetchAll(Trip.self)
            .sorted { $0.startDate < $1.startDate }
    }

    func fetch(by id: UUID) async throws -> Trip {
        try await cloudKit.fetch(Trip.self, id: id)
    }

    @discardableResult
    func save(_ trip: Trip) async throws -> Trip {
        var updatedTrip = trip
        updatedTrip.updatedAt = Date()
        return try await cloudKit.save(updatedTrip)
    }

    func delete(by id: UUID) async throws {
        try await cloudKit.delete(Trip.self, id: id)
    }
}
