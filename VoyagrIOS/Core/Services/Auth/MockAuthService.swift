import Foundation
import Observation

@Observable
final class MockAuthService: AuthServiceProtocol {

    private(set) var isAuthenticated = false

    func signIn() async throws {
        isAuthenticated = true
    }

    func signOut() async throws {
        isAuthenticated = false
    }
}
