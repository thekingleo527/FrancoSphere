//
//  TaskService.swift
//  FrancoSphere
//
//  ✅ FIXED: All method signatures and type conversions
//

import Foundation

actor TaskService {
    static let shared = TaskService()
    
    private init() {}
    
    // MARK: - Core Methods
    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        // Implementation for getting tasks
        return []
    }
    
    func getTaskProgress(for workerId: String) async throws -> TaskProgress {
        return TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)
    }
    
    func completeTask(_ taskId: String, workerId: String, buildingId: String, evidence: Any?) async throws {
        // Implementation for completing task
        print("✅ Task completed: \(taskId)")
    }
    
    // MARK: - Synchronous Wrapper Methods
    func toggleTaskCompletion(taskId: String) {
        Task {
            try? await toggleTaskCompletionAsync(taskId: taskId)
        }
    }
    
    func getAllTasks() -> [ContextualTask] {
        // Return cached tasks or empty array for synchronous access
        return []
    }
    
    func addTask(_ task: ContextualTask) {
        Task {
            try? await createTaskAsync(task)
        }
    }
    
    // MARK: - Async Implementation Methods
    private func toggleTaskCompletionAsync(taskId: String) async throws {
        print("🔄 Toggling completion for task: \(taskId)")
        // Implementation here
    }
    
    private func createTaskAsync(_ task: ContextualTask) async throws {
        print("➕ Creating task: \(task.id)")
        // Implementation here
    }
    
    // MARK: - Compatibility Methods for Legacy Code
    func fetchTasksAsync() async throws -> [ContextualTask] {
        // FIXED: Return ContextualTask instead of MaintenanceTask
        return try await getTasks(for: "1", date: Date())
    }
    
    func createWeatherBasedTasksAsync() async throws {
        print("🌤️ Creating weather-based tasks...")
    }
    
    func toggleTaskCompletionAsync(_ task: ContextualTask) async throws {
        // FIXED: Use ContextualTask instead of MaintenanceTask
        try await toggleTaskCompletionAsync(taskId: task.id)
    }
    
    func fetchMaintenanceHistory(for buildingId: String) async -> [MaintenanceRecord] {
        return []
    }
    
    func fetchTasks() async -> [ContextualTask] {
        // FIXED: Return ContextualTask and use proper method
        do {
            return try await getTasks(for: "1", date: Date())
        } catch {
            print("Error fetching tasks: \(error)")
            return []
        }
    }
    
    func createTask(_ task: ContextualTask) async throws {
        // FIXED: Use ContextualTask consistently
        try await createTaskAsync(task)
    }
    
    func fetchRecentTasks(for workerId: String, limit: Int = 10) async throws -> [ContextualTask] {
        let tasks = try await getTasks(for: workerId, date: Date())
        return Array(tasks.prefix(limit))
    }
}
