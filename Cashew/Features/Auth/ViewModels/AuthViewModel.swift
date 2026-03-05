import Foundation
import Observation

@Observable
final class AuthViewModel {

    private let authService: AuthServiceProtocol
    private var signInTask: Task<Void, Never>?

    var isLoading = false
    var errorMessage: String?

    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }

    func signIn() {
        signInTask?.cancel()
        isLoading = true
        errorMessage = nil

        signInTask = Task {
            do {
                try await authService.signIn()
            } catch is CancellationError {
                // Task was cancelled, no action needed
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    func cancelSignIn() {
        signInTask?.cancel()
        signInTask = nil
        isLoading = false
    }
}
