import Foundation

actor CloudEventRepository: EventRepositoryProtocol {

    private let cloudKit: CloudKitManager

    init(cloudKit: CloudKitManager = .shared) {
        self.cloudKit = cloudKit
    }

    func fetchAll() async throws -> [Event] {
        try await cloudKit.fetchAll(Event.self)
            .sorted { $0.date < $1.date }
    }

    func fetch(by id: UUID) async throws -> Event {
        try await cloudKit.fetch(Event.self, id: id)
    }

    @discardableResult
    func save(_ event: Event) async throws -> Event {
        var updatedEvent = event
        updatedEvent.updatedAt = Date()
        return try await cloudKit.save(updatedEvent)
    }

    func delete(by id: UUID) async throws {
        try await cloudKit.delete(Event.self, id: id)
    }
}
