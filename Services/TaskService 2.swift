//
//  TaskService 2.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/9/25.
//


//
//  TaskService.swift
//  FrancoSphere
//
//  ✅ V6.0: Core task management service
//  ✅ @MainActor for UI compatibility
//  ✅ Real SQLite database integration
//  ✅ Worker assignment support
//  ✅ Progress tracking and analytics
//  ✅ Real-time update capabilities
//

import Foundation
import CoreLocation
import Combine

@MainActor
public class TaskService: ObservableObject {
    public static let shared = TaskService()
    
    // MARK: - Published State
    @Published public var isLoading = false
    @Published public var lastError: Error?
    
    // MARK: - Dependencies
    private let sqliteManager = SQLiteManager.shared
    private let operationalManager = OperationalDataManager.shared
    
    // MARK: - Cache Management
    private var taskCache: [String: [ContextualTask]] = [:]
    private var progressCache: [String: TaskProgress] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    private struct CacheEntry<T> {
        let data: T
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }
    
    private init() {
        print("📋 TaskService initialized")
    }
    
    // MARK: - Core Task Operations
    
    /// Get tasks for a specific worker on a specific date
    public func getTasks(for workerId: CoreTypes.WorkerID, date: Date) async throws -> [ContextualTask] {
        print("📋 Loading tasks for worker \(workerId) on \(DateFormatter.shortDate.string(from: date))")
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let dateString = DateFormatter.sqlite.string(from: date)
        
        let query = """
            SELECT 
                t.id,
                t.title,
                t.description,
                t.category,
                t.urgency,
                t.buildingId,
                t.assignedWorkerId,
                t.isCompleted,
                t.completedDate,
                t.dueDate,
                t.scheduledDate,
                t.estimatedDuration,
                t.recurrence,
                t.notes,
                b.name as buildingName,
                w.name as workerName
            FROM tasks t
            LEFT JOIN buildings b ON CAST(b.id AS TEXT) = CAST(t.buildingId AS TEXT)
            LEFT JOIN workers w ON CAST(w.id AS TEXT) = CAST(t.assignedWorkerId AS TEXT)
            WHERE t.assignedWorkerId = ?
            AND date(t.scheduledDate) = date(?)
            ORDER BY t.urgency DESC, t.scheduledDate ASC
        """
        
        do {
            let rows = try await manager.query(query, [workerId, dateString])
            let tasks = try rows.compactMap { row in
                try parseTaskFromRow(row)
            }
            
            print("✅ Found \(tasks.count) tasks for worker \(workerId)")
            return tasks
            
        } catch {
            print("❌ Failed to load tasks: \(error)")
            throw TaskServiceError.queryFailed(error.localizedDescription)
        }
    }
    
    /// Get all tasks across the portfolio
    public func getAllTasks() async throws -> [ContextualTask] {
        print("📋 Loading all tasks across portfolio")
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let query = """
            SELECT 
                t.id,
                t.title,
                t.description,
                t.category,
                t.urgency,
                t.buildingId,
                t.assignedWorkerId,
                t.isCompleted,
                t.completedDate,
                t.dueDate,
                t.scheduledDate,
                t.estimatedDuration,
                t.recurrence,
                t.notes,
                b.name as buildingName,
                w.name as workerName
            FROM tasks t
            LEFT JOIN buildings b ON CAST(b.id AS TEXT) = CAST(t.buildingId AS TEXT)
            LEFT JOIN workers w ON CAST(w.id AS TEXT) = CAST(t.assignedWorkerId AS TEXT)
            ORDER BY t.scheduledDate DESC
        """
        
        do {
            let rows = try await manager.query(query, [])
            let tasks = try rows.compactMap { row in
                try parseTaskFromRow(row)
            }
            
            print("✅ Found \(tasks.count) total tasks")
            return tasks
            
        } catch {
            print("❌ Failed to load all tasks: \(error)")
            throw TaskServiceError.queryFailed(error.localizedDescription)
        }
    }
    
    /// Get tasks for a specific building
    public func getTasksForBuilding(_ buildingId: String, date: Date) async throws -> [ContextualTask] {
        print("📋 Loading tasks for building \(buildingId) on \(DateFormatter.shortDate.string(from: date))")
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let dateString = DateFormatter.sqlite.string(from: date)
        
        let query = """
            SELECT 
                t.id,
                t.title,
                t.description,
                t.category,
                t.urgency,
                t.buildingId,
                t.assignedWorkerId,
                t.isCompleted,
                t.completedDate,
                t.dueDate,
                t.scheduledDate,
                t.estimatedDuration,
                t.recurrence,
                t.notes,
                b.name as buildingName,
                w.name as workerName
            FROM tasks t
            LEFT JOIN buildings b ON CAST(b.id AS TEXT) = CAST(t.buildingId AS TEXT)
            LEFT JOIN workers w ON CAST(w.id AS TEXT) = CAST(t.assignedWorkerId AS TEXT)
            WHERE CAST(t.buildingId AS TEXT) = ?
            AND date(t.scheduledDate) = date(?)
            ORDER BY t.urgency DESC, t.scheduledDate ASC
        """
        
        do {
            let rows = try await manager.query(query, [buildingId, dateString])
            let tasks = try rows.compactMap { row in
                try parseTaskFromRow(row)
            }
            
            print("✅ Found \(tasks.count) tasks for building \(buildingId)")
            return tasks
            
        } catch {
            print("❌ Failed to load building tasks: \(error)")
            throw TaskServiceError.queryFailed(error.localizedDescription)
        }
    }
    
    /// Complete a task with evidence
    public func completeTask(_ taskId: CoreTypes.TaskID, evidence: ActionEvidence) async throws {
        print("✅ Completing task \(taskId)")
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let completedDate = Date()
        let completedDateString = DateFormatter.sqlite.string(from: completedDate)
        
        let updateQuery = """
            UPDATE tasks 
            SET isCompleted = 1,
                completedDate = ?,
                notes = COALESCE(notes, '') || ?
            WHERE id = ?
        """
        
        let evidenceNote = "\n[Completed: \(DateFormatter.readable.string(from: completedDate))] \(evidence.description)"
        
        do {
            try await manager.execute(updateQuery, [completedDateString, evidenceNote, taskId])
            
            // Record evidence if photos provided
            if !evidence.photoURLs.isEmpty {
                try await recordTaskEvidence(taskId: taskId, evidence: evidence)
            }
            
            // Invalidate cache
            invalidateCache()
            
            // Trigger real-time update
            await broadcastTaskUpdate(taskId: taskId, completed: true)
            
            print("✅ Task \(taskId) completed successfully")
            
        } catch {
            print("❌ Failed to complete task: \(error)")
            throw TaskServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Create a new task
    public func createTask(_ task: ContextualTask) async throws {
        print("➕ Creating new task: \(task.title)")
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let insertQuery = """
            INSERT INTO tasks (
                id, title, description, category, urgency, buildingId,
                assignedWorkerId, isCompleted, dueDate, scheduledDate,
                estimatedDuration, recurrence, notes
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let values: [Any?] = [
            task.id,
            task.title,
            task.description,
            task.category.rawValue,
            task.urgency.rawValue,
            task.buildingId,
            task.assignedWorkerId,
            task.isCompleted ? 1 : 0,
            task.dueDate.map { DateFormatter.sqlite.string(from: $0) },
            DateFormatter.sqlite.string(from: Date()), // scheduledDate
            task.estimatedDuration,
            task.recurrence.rawValue,
            task.notes
        ]
        
        do {
            try await manager.execute(insertQuery, values)
            
            // Invalidate cache
            invalidateCache()
            
            print("✅ Task created successfully: \(task.id)")
            
        } catch {
            print("❌ Failed to create task: \(error)")
            throw TaskServiceError.createFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Progress Tracking
    
    /// Get task progress for a worker
    public func getTaskProgress(for workerId: CoreTypes.WorkerID) async throws -> TaskProgress {
        print("📊 Calculating progress for worker \(workerId)")
        
        // Check cache first
        if let cached = progressCache[workerId],
           Date().timeIntervalSince(cached.timestamp) < cacheExpiration {
            return cached.data
        }
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let query = """
            SELECT 
                COUNT(*) as totalTasks,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completedTasks,
                SUM(CASE WHEN isCompleted = 0 AND datetime(scheduledDate) < datetime('now') THEN 1 ELSE 0 END) as overdueTasks,
                AVG(CASE WHEN isCompleted = 1 AND completedDate IS NOT NULL THEN
                    (julianday(completedDate) - julianday(scheduledDate)) * 24 * 60
                    ELSE NULL END) as avgCompletionTimeMinutes
            FROM tasks
            WHERE assignedWorkerId = ?
            AND date(scheduledDate) = date('now')
        """
        
        do {
            let rows = try await manager.query(query, [workerId])
            guard let row = rows.first else {
                throw TaskServiceError.noDataFound
            }
            
            let totalTasks = row["totalTasks"] as? Int64 ?? 0
            let completedTasks = row["completedTasks"] as? Int64 ?? 0
            let overdueTasks = row["overdueTasks"] as? Int64 ?? 0
            let avgTime = row["avgCompletionTimeMinutes"] as? Double ?? 0
            
            let progress = TaskProgress(
                totalTasks: Int(totalTasks),
                completedTasks: Int(completedTasks),
                pendingTasks: Int(totalTasks - completedTasks),
                overdueTasks: Int(overdueTasks),
                completionRate: totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0,
                averageCompletionTime: avgTime,
                lastUpdated: Date()
            )
            
            // Cache the result
            progressCache[workerId] = CacheEntry(data: progress, timestamp: Date())
            
            print("✅ Progress calculated: \(completedTasks)/\(totalTasks) tasks completed")
            return progress
            
        } catch {
            print("❌ Failed to calculate progress: \(error)")
            throw TaskServiceError.queryFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Task Analytics
    
    /// Get building analytics for intelligence service
    public func getBuildingTaskAnalytics(_ buildingId: String) async throws -> BuildingTaskAnalytics {
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let query = """
            SELECT 
                COUNT(*) as totalTasks,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completedTasks,
                SUM(CASE WHEN isCompleted = 0 AND datetime(scheduledDate) < datetime('now') THEN 1 ELSE 0 END) as overdueTasks,
                AVG(estimatedDuration) as avgDuration,
                COUNT(DISTINCT assignedWorkerId) as assignedWorkers
            FROM tasks
            WHERE CAST(buildingId AS TEXT) = ?
            AND date(scheduledDate) >= date('now', '-30 days')
        """
        
        do {
            let rows = try await manager.query(query, [buildingId])
            guard let row = rows.first else {
                return BuildingTaskAnalytics.empty
            }
            
            let totalTasks = row["totalTasks"] as? Int64 ?? 0
            let completedTasks = row["completedTasks"] as? Int64 ?? 0
            let overdueTasks = row["overdueTasks"] as? Int64 ?? 0
            let avgDuration = row["avgDuration"] as? Double ?? 0
            let assignedWorkers = row["assignedWorkers"] as? Int64 ?? 0
            
            return BuildingTaskAnalytics(
                totalTasks: Int(totalTasks),
                completedTasks: Int(completedTasks),
                overdueTasks: Int(overdueTasks),
                completionRate: totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0,
                averageDuration: avgDuration,
                assignedWorkers: Int(assignedWorkers)
            )
            
        } catch {
            print("❌ Failed to get building analytics: \(error)")
            throw TaskServiceError.queryFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Worker Assignment
    
    /// Assign a task to a worker
    public func assignTask(_ taskId: CoreTypes.TaskID, to workerId: CoreTypes.WorkerID) async throws {
        print("👷 Assigning task \(taskId) to worker \(workerId)")
        
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let updateQuery = """
            UPDATE tasks 
            SET assignedWorkerId = ?
            WHERE id = ?
        """
        
        do {
            try await manager.execute(updateQuery, [workerId, taskId])
            invalidateCache()
            
            print("✅ Task assigned successfully")
            
        } catch {
            print("❌ Failed to assign task: \(error)")
            throw TaskServiceError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Get tasks assigned to a worker (any date)
    public func getWorkerTasks(_ workerId: CoreTypes.WorkerID) async throws -> [ContextualTask] {
        guard let manager = await getManager() else {
            throw TaskServiceError.databaseUnavailable
        }
        
        let query = """
            SELECT 
                t.id,
                t.title,
                t.description,
                t.category,
                t.urgency,
                t.buildingId,
                t.assignedWorkerId,
                t.isCompleted,
                t.completedDate,
                t.dueDate,
                t.scheduledDate,
                t.estimatedDuration,
                t.recurrence,
                t.notes,
                b.name as buildingName,
                w.name as workerName
            FROM tasks t
            LEFT JOIN buildings b ON CAST(b.id AS TEXT) = CAST(t.buildingId AS TEXT)
            LEFT JOIN workers w ON CAST(w.id AS TEXT) = CAST(t.assignedWorkerId AS TEXT)
            WHERE t.assignedWorkerId = ?
            ORDER BY t.scheduledDate DESC
            LIMIT 100
        """
        
        do {
            let rows = try await manager.query(query, [workerId])
            return try rows.compactMap { row in
                try parseTaskFromRow(row)
            }
            
        } catch {
            print("❌ Failed to get worker tasks: \(error)")
            throw TaskServiceError.queryFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Real-time Updates
    
    private func broadcastTaskUpdate(taskId: CoreTypes.TaskID, completed: Bool) async {
        // Post notification for real-time updates
        let userInfo: [String: Any] = [
            "taskId": taskId,
            "isCompleted": completed,
            "timestamp": Date()
        ]
        
        NotificationCenter.default.post(
            name: .taskStatusChanged,
            object: nil,
            userInfo: userInfo
        )
    }
    
    // MARK: - Helper Methods
    
    private func getManager() async -> SQLiteManager? {
        return sqliteManager
    }
    
    private func parseTaskFromRow(_ row: [String: Any]) throws -> ContextualTask {
        guard let id = row["id"] as? String,
              let title = row["title"] as? String,
              let description = row["description"] as? String,
              let categoryString = row["category"] as? String,
              let urgencyString = row["urgency"] as? String,
              let buildingId = row["buildingId"] else {
            throw TaskServiceError.parseError("Missing required task fields")
        }
        
        // Parse enums
        let category = TaskCategory(rawValue: categoryString) ?? .maintenance
        let urgency = TaskUrgency(rawValue: urgencyString) ?? .medium
        let recurrence = TaskRecurrence(rawValue: row["recurrence"] as? String ?? "none") ?? .none
        
        // Parse dates
        let dueDate = (row["dueDate"] as? String).flatMap { DateFormatter.sqlite.date(from: $0) }
        let completedDate = (row["completedDate"] as? String).flatMap { DateFormatter.sqlite.date(from: $0) }
        
        return ContextualTask(
            id: id,
            title: title,
            description: description,
            category: category,
            urgency: urgency,
            buildingId: String(describing: buildingId),
            buildingName: row["buildingName"] as? String ?? "Unknown Building",
            assignedWorkerId: row["assignedWorkerId"] as? String,
            assignedWorkerName: row["workerName"] as? String,
            isCompleted: (row["isCompleted"] as? Int64) == 1,
            completedDate: completedDate,
            dueDate: dueDate,
            estimatedDuration: (row["estimatedDuration"] as? Double) ?? 3600.0,
            recurrence: recurrence,
            notes: row["notes"] as? String
        )
    }
    
    private func recordTaskEvidence(taskId: CoreTypes.TaskID, evidence: ActionEvidence) async throws {
        // Record task evidence in database
        guard let manager = await getManager() else { return }
        
        for photoURL in evidence.photoURLs {
            let insertQuery = """
                INSERT INTO task_evidence (taskId, photoURL, description, recordedAt)
                VALUES (?, ?, ?, ?)
            """
            
            try await manager.execute(insertQuery, [
                taskId,
                photoURL.absoluteString,
                evidence.description,
                DateFormatter.sqlite.string(from: Date())
            ])
        }
    }
    
    private func invalidateCache() {
        taskCache.removeAll()
        progressCache.removeAll()
    }
}

// MARK: - Supporting Types

public struct TaskProgress: Codable, Hashable {
    public let totalTasks: Int
    public let completedTasks: Int
    public let pendingTasks: Int
    public let overdueTasks: Int
    public let completionRate: Double
    public let averageCompletionTime: Double // in minutes
    public let lastUpdated: Date
    
    public init(totalTasks: Int, completedTasks: Int, pendingTasks: Int, overdueTasks: Int, completionRate: Double, averageCompletionTime: Double, lastUpdated: Date) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.pendingTasks = pendingTasks
        self.overdueTasks = overdueTasks
        self.completionRate = completionRate
        self.averageCompletionTime = averageCompletionTime
        self.lastUpdated = lastUpdated
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalTasks = try container.decode(Int.self, forKey: .totalTasks)
        completedTasks = try container.decode(Int.self, forKey: .completedTasks)
        pendingTasks = try container.decode(Int.self, forKey: .pendingTasks)
        overdueTasks = try container.decode(Int.self, forKey: .overdueTasks)
        completionRate = try container.decode(Double.self, forKey: .completionRate)
        averageCompletionTime = try container.decode(Double.self, forKey: .averageCompletionTime)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
    }
    
    private enum CodingKeys: String, CodingKey {
        case totalTasks, completedTasks, pendingTasks, overdueTasks
        case completionRate, averageCompletionTime, lastUpdated
    }
}

public struct BuildingTaskAnalytics: Codable {
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let completionRate: Double
    public let averageDuration: Double
    public let assignedWorkers: Int
    
    public static let empty = BuildingTaskAnalytics(
        totalTasks: 0,
        completedTasks: 0,
        overdueTasks: 0,
        completionRate: 0.0,
        averageDuration: 0.0,
        assignedWorkers: 0
    )
    
    public init(totalTasks: Int, completedTasks: Int, overdueTasks: Int, completionRate: Double, averageDuration: Double, assignedWorkers: Int) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.overdueTasks = overdueTasks
        self.completionRate = completionRate
        self.averageDuration = averageDuration
        self.assignedWorkers = assignedWorkers
    }
}

public enum TaskServiceError: Error, LocalizedError {
    case databaseUnavailable
    case queryFailed(String)
    case updateFailed(String)
    case createFailed(String)
    case parseError(String)
    case noDataFound
    
    public var errorDescription: String? {
        switch self {
        case .databaseUnavailable:
            return "Database is not available"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        case .updateFailed(let message):
            return "Update failed: \(message)"
        case .createFailed(let message):
            return "Create failed: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .noDataFound:
            return "No data found"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    public static let taskStatusChanged = Notification.Name("taskStatusChanged")
    public static let taskAssigned = Notification.Name("taskAssigned")
    public static let taskCreated = Notification.Name("taskCreated")
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    static let sqlite: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let readable: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}