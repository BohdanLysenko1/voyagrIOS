import Foundation

@MainActor
protocol DayPlannerServiceProtocol: AnyObject {
    var allTasks: [DailyTask] { get }
    var tasksForSelectedDate: [DailyTask] { get }
    var scheduledTasks: [DailyTask] { get }
    var unscheduledTasks: [DailyTask] { get }
    var routines: [DailyRoutine] { get }
    var selectedDate: Date { get set }

    func loadData() async throws
    func createTask(_ task: DailyTask) async throws
    func updateTask(_ task: DailyTask) async throws
    func deleteTask(by id: UUID) async throws
    func toggleTaskCompletion(_ task: DailyTask) async throws

    func createRoutine(_ routine: DailyRoutine) async throws
    func updateRoutine(_ routine: DailyRoutine) async throws
    func deleteRoutine(by id: UUID) async throws
    func toggleRoutineEnabled(_ routine: DailyRoutine) async throws

    func generateTasksFromRoutines(for date: Date) async throws
}
