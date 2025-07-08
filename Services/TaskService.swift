//
//  TaskService.swift
//  FrancoSphere
//
//  ✅ CLEAN VERSION: Fixed all compilation errors
//  ✅ Uses correct ContextualTask constructor signature
//  ✅ Proper actor isolation
//  ✅ No duplicate definitions
//

import Foundation

actor TaskService {
    static let shared = TaskService()
    
    private init() {}
    
    // MARK: - Core Task Methods
    
    /// Get tasks for a specific worker on a specific date
    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        guard let manager = SQLiteManager.shared else {
            throw TaskServiceError.databaseNotAvailable
        }
        
        let query = """
            SELECT t.*, b.name as building_name, w.name as worker_name
            FROM AllTasks t
            LEFT JOIN buildings b ON t.building_id = b.id
            LEFT JOIN workers w ON t.assigned_worker_id = w.id
            WHERE t.assigned_worker_id = ? 
            AND date(t.due_date) = date(?)
            ORDER BY t.due_date ASC
        """
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let rows = try await manager.query(query, [workerId, dateString])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let title = row["title"] as? String else { return nil }
            
            let category = TaskCategory(rawValue: row["category"] as? String ?? "maintenance") ?? .maintenance
            let urgency = TaskUrgency(rawValue: row["urgency"] as? String ?? "medium") ?? .medium
            let buildingId = row["building_id"] as? String ?? ""
            let buildingName = row["building_name"] as? String ?? "Unknown Building"
            let assignedWorkerName = row["worker_name"] as? String ?? "Unknown Worker"
            let isCompleted = (row["is_completed"] as? Int64 ?? 0) == 1
            
            let dueDate: Date?
            if let dueDateString = row["due_date"] as? String {
                dueDate = ISO8601DateFormatter().date(from: dueDateString)
            } else {
                dueDate = nil
            }
            
            let completedDate: Date?
            if let completedDateString = row["completed_date"] as? String {
                completedDate = ISO8601DateFormatter().date(from: completedDateString)
            } else {
                completedDate = nil
            }
            
            return ContextualTask(
                title: title,
                description: row["description"] as? String ?? "",
                category: category,
                urgency: urgency,
                buildingId: buildingId,
                buildingName: buildingName,
                assignedWorkerId: workerId,
                assignedWorkerName: assignedWorkerName,
                isCompleted: isCompleted,
                completedDate: completedDate,
                dueDate: dueDate,
                estimatedDuration: TimeInterval(row["estimated_duration"] as? Double ?? 3600),
                recurrence: TaskRecurrence(rawValue: row["recurrence"] as? String ?? "none") ?? .none,
                notes: row["notes"] as? String
            )
        }
    }
    
    /// Get task progress summary for a worker
    func getTaskProgress(for workerId: String) async throws -> TaskProgress {
        let tasks = try await getTasks(for: workerId, date: Date())
        
        let completed = tasks.filter { $0.isCompleted }.count
        let total = tasks.count
        let remaining = total - completed
        let percentage = total > 0 ? Double(completed) / Double(total) * 100.0 : 0.0
        let overdue = tasks.filter { task in
            !task.isCompleted && (task.dueDate ?? Date.distantFuture) < Date()
        }.count
        
        return TaskProgress(
            completed: completed,
            total: total,
            remaining: remaining,
            percentage: percentage,
            overdueTasks: overdue
        )
    }
    
    /// Get tasks for a specific building
    func getTasksForBuilding(_ buildingId: String, date: Date = Date()) async throws -> [ContextualTask] {
        guard let manager = SQLiteManager.shared else {
            throw TaskServiceError.databaseNotAvailable
        }
        
        let query = """
            SELECT t.*, b.name as building_name, w.name as worker_name
            FROM AllTasks t
            LEFT JOIN buildings b ON t.building_id = b.id
            LEFT JOIN workers w ON t.assigned_worker_id = w.id
            WHERE t.building_id = ?
            AND date(t.due_date) = date(?)
            ORDER BY t.due_date ASC
        """
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let rows = try await manager.query(query, [buildingId, dateString])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let title = row["title"] as? String else { return nil }
            
            let category = TaskCategory(rawValue: row["category"] as? String ?? "maintenance") ?? .maintenance
            let urgency = TaskUrgency(rawValue: row["urgency"] as? String ?? "medium") ?? .medium
            let buildingName = row["building_name"] as? String ?? "Unknown Building"
            let assignedWorkerId = row["assigned_worker_id"] as? String
            let assignedWorkerName = row["worker_name"] as? String
            let isCompleted = (row["is_completed"] as? Int64 ?? 0) == 1
            
            let dueDate: Date?
            if let dueDateString = row["due_date"] as? String {
                dueDate = ISO8601DateFormatter().date(from: dueDateString)
            } else {
                dueDate = nil
            }
            
            let completedDate: Date?
            if let completedDateString = row["completed_date"] as? String {
                completedDate = ISO8601DateFormatter().date(from: completedDateString)
            } else {
                completedDate = nil
            }
            
            return ContextualTask(
                title: title,
                description: row["description"] as? String ?? "",
                category: category,
                urgency: urgency,
                buildingId: buildingId,
                buildingName: buildingName,
                assignedWorkerId: assignedWorkerId,
                assignedWorkerName: assignedWorkerName,
                isCompleted: isCompleted,
                completedDate: completedDate,
                dueDate: dueDate,
                estimatedDuration: TimeInterval(row["estimated_duration"] as? Double ?? 3600),
                recurrence: TaskRecurrence(rawValue: row["recurrence"] as? String ?? "none") ?? .none,
                notes: row["notes"] as? String
            )
        }
    }
    
    /// Complete a task with evidence
    func completeTask(_ taskId: String, workerId: String, buildingId: String, evidence: Any? = nil) async throws {
        guard let manager = SQLiteManager.shared else {
            throw TaskServiceError.databaseNotAvailable
        }
        
        let completedDate = Date()
        
        try await manager.execute("""
            UPDATE AllTasks 
            SET is_completed = 1, completed_date = ?, completed_by = ?
            WHERE id = ?
        """, [ISO8601DateFormatter().string(from: completedDate), workerId, taskId])
        
        print("✅ Task completed: \(taskId)")
    }
    
    /// Complete task with evidence (simplified version)
    func completeTask(_ taskId: String, evidence: ActionEvidence? = nil) async throws {
        guard let manager = SQLiteManager.shared else {
            throw TaskServiceError.databaseNotAvailable
        }
        
        let completedDate = Date()
        
        try await manager.execute("""
            UPDATE AllTasks 
            SET is_completed = 1, completed_date = ?
            WHERE id = ?
        """, [ISO8601DateFormatter().string(from: completedDate), taskId])
        
        print("✅ Task completed: \(taskId)")
    }
    
    // MARK: - Synchronous Wrapper Methods for UI Compatibility
    
    func toggleTaskCompletion(taskId: String) {
        Task {
            try? await toggleTaskCompletionAsync(taskId: taskId)
        }
    }
    
    func getAllTasks() -> [ContextualTask] {
        // Return empty array for synchronous access - UI should use async methods
        return []
    }
    
    func addTask(_ task: ContextualTask) {
        Task {
            try? await addTaskAsync(task)
        }
    }
    
    // MARK: - Private Async Methods
    
    private func toggleTaskCompletionAsync(taskId: String) async throws {
        guard let manager = SQLiteManager.shared else {
            throw TaskServiceError.databaseNotAvailable
        }
        
        // Get current completion status
        let query = "SELECT is_completed FROM AllTasks WHERE id = ?"
        let rows = try await manager.query(query, [taskId])
        
        guard let row = rows.first,
              let currentStatus = row["is_completed"] as? Int64 else {
            throw TaskServiceError.taskNotFound
        }
        
        let newStatus = currentStatus == 0 ? 1 : 0
        let updateQuery = newStatus == 1 ?
            "UPDATE AllTasks SET is_completed = 1, completed_date = ? WHERE id = ?" :
            "UPDATE AllTasks SET is_completed = 0, completed_date = NULL WHERE id = ?"
        
        if newStatus == 1 {
            try await manager.execute(updateQuery, [ISO8601DateFormatter().string(from: Date()), taskId])
        } else {
            try await manager.execute(updateQuery, [taskId])
        }
        
        print("🔄 Task completion toggled: \(taskId)")
    }
    
    private func addTaskAsync(_ task: ContextualTask) async throws {
        guard let manager = SQLiteManager.shared else {
            throw TaskServiceError.databaseNotAvailable
        }
        
        try await manager.execute("""
            INSERT INTO AllTasks 
            (id, title, description, building_id, assigned_worker_id, category, urgency, due_date, estimated_duration, recurrence, notes, is_completed, created_date)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)
        """, [
            task.id,
            task.title,
            task.description,
            task.buildingId,
            task.assignedWorkerId ?? "",
            task.category.rawValue,
            task.urgency.rawValue,
            task.dueDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            task.estimatedDuration,
            task.recurrence.rawValue,
            task.notes ?? "",
            Date().timeIntervalSince1970
        ])
        
        print("➕ Task added: \(task.title)")
    }
}

// MARK: - Error Types

enum TaskServiceError: LocalizedError {
    case databaseNotAvailable
    case taskNotFound
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .databaseNotAvailable:
            return "Database is not available"
        case .taskNotFound:
            return "Task not found"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
