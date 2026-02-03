import Foundation
import Observation

@Observable
final class AppContainer {

    // MARK: - Repositories

    private let tripRepository: TripRepositoryProtocol
    private let eventRepository: EventRepositoryProtocol

    // MARK: - Services

    let authService: AuthServiceProtocol
    let tripService: TripServiceProtocol
    let eventService: EventServiceProtocol

    // MARK: - Init

    init(
        authService: AuthServiceProtocol? = nil,
        tripRepository: TripRepositoryProtocol? = nil,
        eventRepository: EventRepositoryProtocol? = nil
    ) {
        self.tripRepository = tripRepository ?? LocalTripRepository()
        self.eventRepository = eventRepository ?? LocalEventRepository()

        self.authService = authService ?? MockAuthService()
        self.tripService = TripService(repository: self.tripRepository)
        self.eventService = EventService(repository: self.eventRepository)
    }

    // MARK: - Factory Methods

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService)
    }
}
