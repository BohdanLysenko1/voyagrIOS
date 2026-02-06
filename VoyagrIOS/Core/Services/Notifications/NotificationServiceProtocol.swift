import Foundation

@MainActor
protocol NotificationServiceProtocol: AnyObject {
    var isAuthorized: Bool { get }

    func requestAuthorization() async -> Bool
    func checkAuthorizationStatus() async
    func scheduleNotifications(for event: Event) async
    func cancelNotifications(for eventId: UUID) async
    func updateNotifications(for event: Event) async
}
