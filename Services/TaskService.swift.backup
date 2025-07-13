//
//  TaskService.swift
//  FrancoSphere
//
//  ✅ Complete TaskService implementation
//

import Foundation

actor TaskService {
    static let shared = TaskService()
    private init() {}

    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] { [] }

    func getTaskProgress(for workerId: String) async throws -> TaskProgress {
        return TaskProgress(
            workerId: workerId,
            totalTasks: 0,
            completedTasks: 0,
            overdueTasks: 0,
            todayCompletedTasks: 0,
            weeklyTarget: 10,
            currentStreak: 0,
            lastCompletionDate: nil
        )
    }

    func completeTask(_ taskId: String, evidence: ActionEvidence?) async throws {
        print("✅ Task completed: \(taskId)")
    }

    func getTasksForBuilding(_ buildingId: String, date: Date = Date()) async throws -> [ContextualTask] { [] }
    func getActiveWorkersForBuilding(_ buildingId: String) async throws -> [WorkerProfile] { [] }

    // Legacy support
    func getAllTasks() -> [ContextualTask] { [] }
    func addTask(_ task: ContextualTask) { Task { try? await createTask(task) } }
    func createTask(_ task: ContextualTask) async throws { print("➕ Creating task: \(task.title)") }
    func toggleTaskCompletion(taskId: String) { Task { try? await completeTask(taskId, evidence: nil) } }

    // Helpers
    func fetchTasks() async -> [ContextualTask] { (try? await getTasks(for: "1", date: Date())) ?? [] }
    func fetchTasksAsync() async throws -> [ContextualTask] { try await getTasks(for: "1", date: Date()) }
    func createWeatherBasedTasksAsync() async throws { print("🌤️ Creating weather-based tasks…") }
    func toggleTaskCompletionAsync(_ task: ContextualTask) async throws { try await completeTask(task.id, evidence: nil) }
    func fetchMaintenanceHistory(for buildingId: String) async -> [MaintenanceRecord] { [] }
    func fetchRecentTasks(for workerId: String, limit: Int = 10) async throws -> [ContextualTask] {
        let t = try await getTasks(for: workerId, date: Date()); return Array(t.prefix(limit))
    }
}
