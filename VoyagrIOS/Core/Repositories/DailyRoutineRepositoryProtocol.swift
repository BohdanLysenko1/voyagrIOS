import Foundation

protocol DailyRoutineRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [DailyRoutine]
    @discardableResult func save(_ routine: DailyRoutine) async throws -> DailyRoutine
    func delete(by id: UUID) async throws
}
