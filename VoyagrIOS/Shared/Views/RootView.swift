import SwiftUI

struct RootView: View {

    @Environment(AppContainer.self) private var container
    @State private var authViewModel: AuthViewModel?

    var body: some View {
        Group {
            if container.authService.isAuthenticated {
                MainTabView()
            } else {
                AuthView(viewModel: getOrCreateAuthViewModel())
            }
        }
        .animation(.easeInOut, value: container.authService.isAuthenticated)
    }

    private func getOrCreateAuthViewModel() -> AuthViewModel {
        if let existing = authViewModel {
            return existing
        }
        let newViewModel = container.makeAuthViewModel()
        Task { @MainActor in
            authViewModel = newViewModel
        }
        return newViewModel
    }
}

#Preview {
    RootView()
        .environment(AppContainer())
}
