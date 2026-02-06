import Foundation

protocol DailyTaskRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [DailyTask]
    func fetchTasks(for date: Date) async throws -> [DailyTask]
    @discardableResult func save(_ task: DailyTask) async throws -> DailyTask
    func delete(by id: UUID) async throws
    func deleteOlderThan(_ date: Date) async throws
}
