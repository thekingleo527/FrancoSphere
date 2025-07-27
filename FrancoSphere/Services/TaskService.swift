//
//  TaskService.swift
//  FrancoSphere v6.0
//
//  ✅ CONVERTED TO GRDB: Uses GRDBManager instead of GRDBManager
//  ✅ REAL DATA: Connects to actual database with preserved task data
//  ✅ ASYNC/AWAIT: Modern Swift concurrency patterns
//

import Foundation
import GRDB

actor TaskService {
    static let shared = TaskService()
    
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    // MARK: - Public API Methods
    
    func getAllTasks() async throws -> [ContextualTask] {
        let rows = try await grdbManager.query("""
            SELECT t.*, w.name as worker_name, b.name as building_name
            FROM routine_tasks t
            LEFT JOIN workers w ON t.workerId = w.id
            LEFT JOIN buildings b ON t.buildingId = b.id
            ORDER BY t.scheduledDate
        """)
        
        return rows.compactMap { row in
            convertRowToContextualTask(row)
        }
    }
    
    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        let dateString = ISO8601DateFormatter().string(from: date)
        let rows = try await grdbManager.query("""
            SELECT t.*, w.name as worker_name, b.name as building_name
            FROM routine_tasks t
            LEFT JOIN workers w ON t.workerId = w.id
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ? AND DATE(t.scheduledDate) = DATE(?)
            ORDER BY t.scheduledDate
        """, [workerId, dateString])
        
        return rows.compactMap { row in
            convertRowToContextualTask(row)
        }
    }
    
    func getCoreTypes;.TaskProgress(for workerId: String) async throws -> CoreTypes.TaskProgress? {
        let rows = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total_tasks,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed_tasks
            FROM routine_tasks 
            WHERE workerId = ? AND DATE(scheduledDate) = DATE('now')
        """, [workerId])
        
        guard let row = rows.first,
              let total = row["total_tasks"] as? Int64,
              let completed = row["completed_tasks"] as? Int64 else {
            return nil
        }
        
        return CoreTypes.TaskProgress(
            completedTasks: Int(completed),
            totalTasks: Int(total),
            progressPercentage: total > 0 ? Double(completed) / Double(total) * 100 : 0
        )
    }
    
    func completeTask(_ taskId: CoreTypes.TaskID, evidence: ActionEvidence) async throws {
        try await grdbManager.execute("""
            UPDATE routine_tasks 
            SET isCompleted = 1, completedDate = ? 
            WHERE id = ?
        """, [ISO8601DateFormatter().string(from: Date()), taskId])
    }
    
    func createTask(_ task: ContextualTask) async throws {
        try await grdbManager.execute("""
            INSERT INTO routine_tasks 
            (name, description, buildingId, workerId, scheduledDate, category, urgencyLevel)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, [
            task.title,
            task.description ?? "",
            task.building?.id ?? "",
            task.worker?.id ?? "",
            ISO8601DateFormatter().string(from: task.scheduledDate ?? Date()),
            task.category?.rawValue ?? "maintenance",
            task.urgency?.rawValue ?? "medium"
        ])
    }
    
    // MARK: - Private Helper Methods
    
    private func convertRowToContextualTask(_ row: [String: Any]) -> ContextualTask? {
        guard let id = row["id"] as? Int64,
              let name = row["name"] as? String else {
            return nil
        }
        
        // Create basic task object
        let task = ContextualTask(
            id: String(id),
            title: name,
            description: row["description"] as? String,
            isCompleted: (row["isCompleted"] as? Int64) == 1,
            completedDate: parseDate(row["completedDate"] as? String),
            scheduledDate: parseDate(row["scheduledDate"] as? String),
            dueDate: parseDate(row["dueDate"] as? String)
        )
        
        return task
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Fixed Method Signatures Extension
extension TaskService {
    func getCoreTypes() async throws -> [ContextualTask] {
        return try await getAllTasks()
    }
    
    func getWorkerTasks(workerId: String) async throws -> [ContextualTask] {
        return try await grdbManager.read { db in
            try ContextualTask
                .filter(Column("assignedWorkerId") == workerId)
                .fetchAll(db)
        }
    }
    
    func getBuildingTasks(buildingId: String) async throws -> [ContextualTask] {
        return try await grdbManager.read { db in
            try ContextualTask
                .filter(Column("buildingId") == buildingId)
                .fetchAll(db)
        }
    }
}
