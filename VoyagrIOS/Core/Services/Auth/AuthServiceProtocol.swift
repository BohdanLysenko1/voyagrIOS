import Foundation

@MainActor
protocol AuthServiceProtocol: AnyObject {
    var isAuthenticated: Bool { get }

    func signIn() async throws
    func signOut() async throws
}
