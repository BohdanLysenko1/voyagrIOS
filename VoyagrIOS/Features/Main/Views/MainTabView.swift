import SwiftUI

struct MainTabView: View {

    @Environment(AppContainer.self) private var container
    @State private var showSignOutError = false
    @State private var signOutErrorMessage = ""

    var body: some View {
        TabView {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ProfileTab(onSignOut: signOut)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .alert("Sign Out Failed", isPresented: $showSignOutError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(signOutErrorMessage)
        }
    }

    private func signOut() {
        Task {
            do {
                try await container.authService.signOut()
            } catch {
                signOutErrorMessage = error.localizedDescription
                showSignOutError = true
            }
        }
    }
}

// MARK: - Tab Views

private struct HomeTab: View {
    var body: some View {
        NavigationStack {
            Text("Welcome to Voyagr")
                .navigationTitle("Home")
        }
    }
}

private struct ProfileTab: View {
    let onSignOut: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                Button("Sign Out", role: .destructive) {
                    onSignOut()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppContainer())
}
