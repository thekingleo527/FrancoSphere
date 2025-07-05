//
//  TaskService.swift
//  FrancoSphere
//
//  ✅ FIXED: All conflicts resolved
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)


actor TaskService {
    static let shared = TaskService()
    
    private init() {}
    
    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        // Implementation for getting tasks
        return []
    }
    
    func getTaskProgress(for workerId: String) async throws -> TaskProgress {
        return TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)
    }
    
    func completeTask(_ taskId: String, workerId: String, buildingId: String, evidence: Any?) async throws {
        // Implementation for completing task
    }
}

// MARK: - TaskProgress (Only one definition)

// MARK: - Missing Methods for Compatibility
extension TaskService {
    public func fetchTasksAsync() async throws -> [MaintenanceTask] {
        return await withCheckedContinuation { continuation in
            Task {
                let tasks = await fetchTasks()
                continuation.resume(returning: tasks)
            }
        }
    }
    
    public func createWeatherBasedTasksAsync() async throws {
        // Implementation for weather-based task creation
        print("Creating weather-based tasks...")
    }
    
    public func toggleTaskCompletionAsync(_ task: MaintenanceTask) async throws {
        await toggleTaskCompletion(task.id)
    }
    
    public func fetchMaintenanceHistory(for buildingId: String) async -> [MaintenanceRecord] {
        // Return maintenance history for building
        return []
    }
    
    public func fetchTasks() async -> [MaintenanceTask] {
        return await getAllTasks()
    }
    
    public func createTask(_ task: MaintenanceTask) async throws {
        await addTask(task)
    }
}
