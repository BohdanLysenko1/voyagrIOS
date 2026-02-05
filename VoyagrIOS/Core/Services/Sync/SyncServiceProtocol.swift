import Foundation

enum SyncStatus: Equatable, Sendable {
    case idle
    case syncing
    case success
    case failed(String)
}

@MainActor
protocol SyncServiceProtocol: AnyObject {
    var isSyncEnabled: Bool { get set }
    var syncStatus: SyncStatus { get }
    var lastSyncDate: Date? { get }

    func sync() async
    func checkCloudAvailability() async -> Bool
}
