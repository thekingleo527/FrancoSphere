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
public struct TaskProgress {
    public let completed: Int
    public let total: Int
    public let remaining: Int
    public let percentage: Double
    public let overdueTasks: Int
    
    public init(completed: Int, total: Int, remaining: Int, percentage: Double, overdueTasks: Int) {
        self.completed = completed
        self.total = total
        self.remaining = remaining
        self.percentage = percentage
        self.overdueTasks = overdueTasks
    }
}
