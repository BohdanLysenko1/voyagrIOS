import SwiftUI

@main
struct VoyagrIOSApp: App {

    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .task {
                    await requestNotificationPermissionIfNeeded()
                }
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        let hasRequestedKey = "hasRequestedNotificationPermission"

        if !UserDefaults.standard.bool(forKey: hasRequestedKey) {
            await container.requestNotificationPermission()
            UserDefaults.standard.set(true, forKey: hasRequestedKey)
        } else {
            // Check current status on subsequent launches
            await container.notificationService.checkAuthorizationStatus()
        }
    }
}
