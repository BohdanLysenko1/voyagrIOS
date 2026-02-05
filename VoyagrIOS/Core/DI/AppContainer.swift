import Foundation
import Observation

@Observable
final class AppContainer {

    // MARK: - Repositories

    private let localTripRepository: TripRepositoryProtocol
    private let localEventRepository: EventRepositoryProtocol

    // MARK: - Services

    let authService: AuthServiceProtocol
    let tripService: TripServiceProtocol
    let eventService: EventServiceProtocol
    let syncService: SyncService

    // MARK: - Init

    init(
        authService: AuthServiceProtocol? = nil,
        tripRepository: TripRepositoryProtocol? = nil,
        eventRepository: EventRepositoryProtocol? = nil,
        syncService: SyncService? = nil
    ) {
        // Local repositories (source of truth)
        self.localTripRepository = tripRepository ?? LocalTripRepository()
        self.localEventRepository = eventRepository ?? LocalEventRepository()

        // Services
        self.authService = authService ?? MockAuthService()
        self.tripService = TripService(repository: localTripRepository)
        self.eventService = EventService(repository: localEventRepository)

        // Sync service
        self.syncService = syncService ?? SyncService(
            localTripRepository: localTripRepository,
            localEventRepository: localEventRepository
        )
    }

    // MARK: - Factory Methods

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService)
    }
}
