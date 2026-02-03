import Foundation
import Observation

@Observable
final class AppContainer {

    let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol? = nil) {
        self.authService = authService ?? MockAuthService()
    }

    func makeAuthViewModel() -> AuthViewModel {
        AuthViewModel(authService: authService)
    }
}
