//
//  TaskRepository.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  TaskRepository.swift
//  FrancoSphere
//
//  Repository pattern for task data access
//

import Foundation

// MARK: - Repository Protocol

protocol TaskRepository {
    func tasks(for workerId: String) async throws -> [ContextualTask]
    func routineTasks(for workerId: String) async throws -> [ContextualTask]
    func upcomingTasks(for workerId: String, days: Int) async throws -> [ContextualTask]
    func updateTaskStatus(taskId: String, status: String) async throws
}

// MARK: - SQL Implementation

final class SQLTaskRepository: TaskRepository {
    private let sqliteManager: SQLiteManager
    
    init(sqliteManager: SQLiteManager) {
        self.sqliteManager = sqliteManager
    }
    
    func tasks(for workerId: String) async throws -> [ContextualTask] {
        let results = try await sqliteManager.query("""
            SELECT t.id, t.name, t.buildingId, b.name as buildingName, 
                   t.category, t.startTime, t.endTime, t.recurrence,
                   t.urgencyLevel, t.status, 'Basic' as skillLevel
            FROM tasks t
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ? 
              AND (t.scheduledDate = date('now') OR t.recurrence = 'daily')
              AND t.status != 'completed'
            ORDER BY t.startTime ASC
        """, [workerId])
        
        return results.map { mapToContextualTask($0) }
    }
    
    func routineTasks(for workerId: String) async throws -> [ContextualTask] {
        let results = try await sqliteManager.query("""
            SELECT rt.id || '_routine' as id, rt.task_name as name, 
                   rt.building_id as buildingId, b.name as buildingName,
                   rt.category, rt.start_time as startTime, rt.end_time as endTime,
                   rt.recurrence, 'medium' as urgencyLevel, 'pending' as status,
                   rt.skill_level as skillLevel
            FROM routine_tasks rt
            LEFT JOIN buildings b ON rt.building_id = b.id
            WHERE rt.worker_id = ? 
              AND rt.is_active = 1
              AND (rt.recurrence = 'daily' OR 
                   (rt.recurrence = 'weekly' AND strftime('%w', 'now') = rt.days_of_week))
            ORDER BY rt.start_time ASC
        """, [workerId])
        
        return results.map { mapToContextualTask($0) }
    }
    
    func upcomingTasks(for workerId: String, days: Int = 7) async throws -> [ContextualTask] {
        let results = try await sqliteManager.query("""
            SELECT t.id, t.name, t.buildingId, b.name as buildingName, 
                   t.category, t.startTime, t.endTime, t.recurrence,
                   t.urgencyLevel, t.status, t.scheduledDate
            FROM tasks t
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ? 
              AND t.scheduledDate > date('now')
              AND t.scheduledDate <= date('now', '+\(days) days')
              AND t.status != 'completed'
            ORDER BY t.scheduledDate ASC, t.startTime ASC
            LIMIT 20
        """, [workerId])
        
        return results.map { mapToContextualTask($0) }
    }
    
    func updateTaskStatus(taskId: String, status: String) async throws {
        try await sqliteManager.execute("""
            UPDATE tasks SET status = ?, updated_at = datetime('now')
            WHERE id = ?
        """, [status, taskId])
    }
    
    // MARK: - Private Helpers
    
    private func mapToContextualTask(_ row: [String: Any]) -> ContextualTask {
        ContextualTask(
            id: String(describing: row["id"] ?? ""),
            name: row["name"] as? String ?? "",
            buildingId: String(row["buildingId"] as? Int64 ?? 0),
            buildingName: row["buildingName"] as? String ?? "",
            category: row["category"] as? String ?? "general",
            startTime: row["startTime"] as? String,
            endTime: row["endTime"] as? String,
            recurrence: row["recurrence"] as? String ?? "oneTime",
            skillLevel: row["skillLevel"] as? String ?? "Basic",
            status: row["status"] as? String ?? "pending",
            urgencyLevel: row["urgencyLevel"] as? String ?? "medium"
        )
    }
}
