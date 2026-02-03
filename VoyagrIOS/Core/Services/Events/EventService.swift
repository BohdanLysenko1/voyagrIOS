import Foundation
import Observation

@Observable
final class EventService: EventServiceProtocol {

    private let repository: EventRepositoryProtocol

    private(set) var events: [Event] = []

    init(repository: EventRepositoryProtocol) {
        self.repository = repository
    }

    func loadEvents() async throws {
        events = try await repository.fetchAll()
    }

    func createEvent(_ event: Event) async throws {
        let savedEvent = try await repository.save(event)
        events.append(savedEvent)
        sortEvents()
    }

    func updateEvent(_ event: Event) async throws {
        let savedEvent = try await repository.save(event)
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = savedEvent
            sortEvents()
        }
    }

    func deleteEvent(by id: UUID) async throws {
        try await repository.delete(by: id)
        events.removeAll { $0.id == id }
    }

    func event(by id: UUID) -> Event? {
        events.first { $0.id == id }
    }

    private func sortEvents() {
        events.sort { $0.date < $1.date }
    }
}
