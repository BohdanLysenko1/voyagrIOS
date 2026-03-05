import SwiftUI

struct RootView: View {

    @Environment(AppContainer.self) private var container
    @State private var authViewModel: AuthViewModel?

    var body: some View {
        Group {
            if container.authService.isAuthenticated {
                MainTabView()
            } else {
                authView
            }
        }
        .animation(.easeInOut, value: container.authService.isAuthenticated)
    }

    @ViewBuilder
    private var authView: some View {
        if let viewModel = authViewModel {
            AuthView(viewModel: viewModel)
        } else {
            Color.clear
                .onAppear {
                    authViewModel = container.makeAuthViewModel()
                }
        }
    }
}

#Preview {
    RootView()
        .environment(AppContainer())
}
