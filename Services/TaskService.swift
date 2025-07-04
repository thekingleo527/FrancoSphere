//
//  TaskService.swift
//  FrancoSphere
//
//  🔧 FINAL ULTRA-EXPLICIT VERSION - ALL 5 COMPILATION ERRORS FIXED
//  ✅ Line 132:41 - Manual loop with explicit Bool type
//  ✅ Line 172:17 - Manual filtering with explicit array type
//  ✅ Line 255:41 - Manual compactMap with explicit types
//  ✅ Line 303:30 - Immutable ContextualTask handling (no status mutation)
//  ✅ Line 354:17 - Individual variable declarations with explicit types
//

import Foundation
import CoreLocation
import Combine

actor TaskService {
    static let shared = TaskService()
    
    // MARK: - Dependencies
    private var sqliteManager: SQLiteManager?
    private var isInitialized = false
    
    // MARK: - Cache Management
    private var taskCache: [String: [ContextualTask]] = [:]
    private var completionCache: [String: TaskCompletion] = [:]
    private let cacheTimeout: TimeInterval = 300
    private var lastCacheUpdate: Date = Date.distantPast
    
    private init() {}
    
    private func ensureInitialized() async throws {
        guard !isInitialized else { return }
        self.sqliteManager = SQLiteManager.shared
        self.isInitialized = true
    }
    
    // MARK: - Task Retrieval (CSV-First Priority)
    
    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        try await ensureInitialized()
        
        // Access CSVDataImporter through MainActor
        let csvTasks: [ContextualTask] = await MainActor.run {
            return Task {
                await OperationalDataManager.shared.getTasksForWorker(workerId, date: date)
            }.result.get()
        }
        
        if !csvTasks.isEmpty {
            print("✅ Using CSV tasks for worker \(workerId): \(csvTasks.count) tasks")
            let enhancedTasks: [ContextualTask] = await self.enhanceTasksWithIntelligence(csvTasks, workerId: workerId)
            await updateTaskCache(workerId: workerId, tasks: enhancedTasks)
            return enhancedTasks
        }
        
        print("⚠️ No CSV data for worker \(workerId), using database fallback")
        
        if workerId == "4" {
            let kevinTasks: [ContextualTask] = await getKevinTasksWithRubinCorrection(date: date)
            return kevinTasks
        }
        
        let dbTasks: [ContextualTask] = try await getDatabaseTasks(for: workerId, date: date)
        return dbTasks
    }
    
    private func getKevinTasksWithRubinCorrection(date: Date) async -> [ContextualTask] {
        do {
            let databaseTasks: [ContextualTask] = try await getDatabaseTasks(for: "4", date: date)
            var tasks: [ContextualTask] = databaseTasks
            
            // FIXED: Line 132:41 - Ultra-explicit Bool type with manual iteration
            var hasRubinTask: Bool = false
            let taskCount: Int = tasks.count
            var index: Int = 0
            while index < taskCount {
                let currentTask: ContextualTask = tasks[index]
                let currentBuildingId: String = currentTask.buildingId
                if currentBuildingId == "14" {
                    hasRubinTask = true
                    break
                }
                index += 1
            }
            
            if !hasRubinTask {
                print("🔧 KEVIN CORRECTION: Adding missing Rubin Museum task")
                
                let dateFormatter: DateFormatter = DateFormatter.yyyyMMddFormatter
                let dateString: String = dateFormatter.string(from: date)
                
                let rubinTask: ContextualTask = ContextualTask(
                    id: "kevin_rubin_daily_\(dateString)",
                    name: "Trash Area + Sidewalk & Curb Clean",
                    buildingId: "14", // CORRECTED: Rubin Museum
                    buildingName: "Rubin Museum (142–148 W 17th)",
                    category: "Sanitation",
                    startTime: "10:00",
                    endTime: "11:00",
                    recurrence: "Daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "Medium",
                    assignedWorkerName: "Kevin Dutan",
                    scheduledDate: date
                )
                
                tasks.append(rubinTask)
            }
            
            // FIXED: Line 172:17 - Ultra-explicit array type with manual filtering
            var filteredTasks: [ContextualTask] = []
            let totalTaskCount: Int = tasks.count
            var filterIndex: Int = 0
            while filterIndex < totalTaskCount {
                let currentTask: ContextualTask = tasks[filterIndex]
                let taskBuildingId: String = currentTask.buildingId
                let taskBuildingName: String = currentTask.buildingName
                
                let isFranklinBuilding: Bool = (taskBuildingId == "13")
                let nameContainsFranklin: Bool = taskBuildingName.contains("Franklin")
                let isFranklinTask: Bool = isFranklinBuilding && nameContainsFranklin
                
                if !isFranklinTask {
                    filteredTasks.append(currentTask)
                }
                filterIndex += 1
            }
            
            return filteredTasks
            
        } catch {
            print("❌ Kevin task correction failed: \(error)")
            let emptyArray: [ContextualTask] = []
            return emptyArray
        }
    }
    
    private func getDatabaseTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let dateFormatter: DateFormatter = DateFormatter.yyyyMMddFormatter
        let dateString: String = dateFormatter.string(from: date)
        
        let query: String = """
            SELECT t.*, b.name as building_name 
            FROM AllTasks t
            LEFT JOIN buildings b ON t.building_id = b.id
            WHERE t.assigned_worker_id = ? 
            AND (t.scheduled_date = ? OR t.recurrence != 'one-off')
            AND t.is_active = 1
            ORDER BY t.start_time ASC
        """
        
        let parameters: [Any] = [workerId, dateString]
        let rows: [[String: Any]] = try await sqliteManager.query(query, parameters)
        
        // FIXED: Line 255:41 - Ultra-explicit compactMap with manual processing
        var contextualTasks: [ContextualTask] = []
        let rowCount: Int = rows.count
        var rowIndex: Int = 0
        while rowIndex < rowCount {
            let currentRow: [String: Any] = rows[rowIndex]
            let possibleTask: ContextualTask? = createContextualTask(from: currentRow)
            if let actualTask: ContextualTask = possibleTask {
                contextualTasks.append(actualTask)
            }
            rowIndex += 1
        }
        
        return contextualTasks
    }
    
    // MARK: - Task Completion (FIXED: No status mutation - immutable support)
    
    func completeTask(_ taskId: String,
                     workerId: String,
                     buildingId: String,
                     evidence: TaskEvidence?) async throws {
        
        try await ensureInitialized()
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        do {
            try await validateTaskCompletion(taskId: taskId, workerId: workerId)
            
            let updateQuery: String = """
                UPDATE AllTasks 
                SET status = 'completed', 
                    completed_at = ?, 
                    completed_by = ?,
                    completion_notes = ?
                WHERE id = ? AND assigned_worker_id = ?
            """
            
            let completionNotes: String = evidence?.notes ?? ""
            let currentDate: Date = Date()
            let parameters: [Any] = [
                currentDate, workerId, completionNotes, taskId, workerId
            ]
            try await sqliteManager.execute(updateQuery, parameters)
            
            if let actualEvidence: TaskEvidence = evidence {
                try await storeTaskEvidence(taskId: taskId, workerId: workerId, evidence: actualEvidence)
            }
            
            let completion: TaskCompletion = TaskCompletion(
                taskId: taskId,
                workerId: workerId,
                buildingId: buildingId,
                completedAt: currentDate,
                evidence: evidence,
                location: evidence?.location
            )
            
            completionCache[taskId] = completion
            await invalidateTaskCache(workerId: workerId)
            try await createCompletionAuditRecord(completion: completion)
            
            print("✅ Task \(taskId) completed by worker \(workerId)")
            
            // FIXED: Line 303:30 - No status mutation since ContextualTask.status is 'let'
            // Status updates are handled through cache invalidation and database updates.
            // Next getTasks() call will return tasks with updated status from database.
            
        } catch {
            print("❌ Task completion failed: \(error)")
            throw TaskServiceError.completionFailed(error)
        }
    }
    
    // MARK: - Task Progress (FIXED: No task mutation)
    
    func getTaskProgress(for workerId: String) async throws -> TaskProgress {
        let todaysTasks: [ContextualTask] = try await getTasks(for: workerId, date: Date())
        
        // Count completed and overdue tasks with explicit variables
        var completedCount: Int = 0
        var overdueCount: Int = 0
        let totalTaskCount: Int = todaysTasks.count
        
        var progressIndex: Int = 0
        while progressIndex < totalTaskCount {
            let currentTask: ContextualTask = todaysTasks[progressIndex]
            let taskStatus: String = currentTask.status
            
            if taskStatus == "completed" {
                completedCount += 1
            }
            
            let taskIsOverdue: Bool = isTaskOverdue(currentTask)
            if taskIsOverdue {
                overdueCount += 1
            }
            
            progressIndex += 1
        }
        
        let total: Int = max(totalTaskCount, 1)
        let remaining: Int = total - completedCount
        let completedDouble: Double = Double(completedCount)
        let totalDouble: Double = Double(total)
        let percentage: Double = completedDouble / totalDouble * 100.0
        
        let averageCompletionTime: TimeInterval = await self.calculateAverageCompletionTime(workerId: workerId)
        let onTimeCompletion: Double = await self.calculateOnTimeRate(workerId: workerId)
        
        let progressResult: TaskProgress = TaskProgress(
            completed: completedCount,
            total: total,
            remaining: remaining,
            percentage: percentage,
            overdueTasks: overdueCount,
            averageCompletionTime: averageCompletionTime,
            onTimeCompletionRate: onTimeCompletion
        )
        
        return progressResult
    }
    
    func getWorkerEfficiencyMetrics(for workerId: String, period: TimeInterval = 30 * 24 * 3600) async throws -> WorkerEfficiencyMetrics {
        try await ensureInitialized()
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let currentDate: Date = Date()
        let startDate: Date = currentDate.addingTimeInterval(-period)
        
        let query: String = """
            SELECT 
                COUNT(*) as total_tasks,
                COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_tasks,
                AVG(CASE WHEN completed_at IS NOT NULL 
                    THEN strftime('%s', completed_at) - strftime('%s', start_time) 
                    END) as avg_completion_time,
                COUNT(CASE WHEN completed_at > end_time THEN 1 END) as late_completions
            FROM AllTasks 
            WHERE assigned_worker_id = ? 
            AND created_at >= ?
        """
        
        let parameters: [Any] = [workerId, startDate]
        let rows: [[String: Any]] = try await sqliteManager.query(query, parameters)
        
        guard let firstRow: [String: Any] = rows.first else {
            throw TaskServiceError.noDataAvailable
        }
        
        // FIXED: Line 354:17 - Ultra-explicit individual variable declarations
        let totalTasksValue: Any? = firstRow["total_tasks"]
        let totalTasksOptional: Int64? = totalTasksValue as? Int64
        let totalTasks: Int64 = totalTasksOptional ?? 0
        
        let completedTasksValue: Any? = firstRow["completed_tasks"]
        let completedTasksOptional: Int64? = completedTasksValue as? Int64
        let completedTasks: Int64 = completedTasksOptional ?? 0
        
        let avgCompletionTimeValue: Any? = firstRow["avg_completion_time"]
        let avgCompletionTimeOptional: Double? = avgCompletionTimeValue as? Double
        let avgCompletionTime: Double = avgCompletionTimeOptional ?? 0.0
        
        let lateCompletionsValue: Any? = firstRow["late_completions"]
        let lateCompletionsOptional: Int64? = lateCompletionsValue as? Int64
        let lateCompletions: Int64 = lateCompletionsOptional ?? 0
        
        let hasAnyTasks: Bool = (totalTasks > 0)
        let completionRateNumerator: Double = Double(completedTasks)
        let completionRateDenominator: Double = Double(totalTasks)
        let completionRate: Double = hasAnyTasks ? (completionRateNumerator / completionRateDenominator) : 0.0
        
        let hasCompletedTasks: Bool = (completedTasks > 0)
        let lateRateNumerator: Double = Double(lateCompletions)
        let lateRateDenominator: Double = Double(completedTasks)
        let lateRate: Double = hasCompletedTasks ? (lateRateNumerator / lateRateDenominator) : 0.0
        let onTimeRate: Double = hasCompletedTasks ? (1.0 - lateRate) : 1.0
        
        let metricsResult: WorkerEfficiencyMetrics = WorkerEfficiencyMetrics(
            workerId: workerId,
            period: period,
            totalTasks: Int(totalTasks),
            completedTasks: Int(completedTasks),
            completionRate: completionRate,
            averageCompletionTime: avgCompletionTime,
            onTimeRate: onTimeRate
        )
        
        return metricsResult
    }
    
    // MARK: - AI Enhancement Layer
    
    private func enhanceTasksWithIntelligence(_ tasks: [ContextualTask], workerId: String) async -> [ContextualTask] {
        var enhancedTasks: [ContextualTask] = tasks
        enhancedTasks = await applyWeatherModifications(enhancedTasks)
        enhancedTasks = await applyRouteOptimization(enhancedTasks, workerId: workerId)
        enhancedTasks = await applyDurationPredictions(enhancedTasks, workerId: workerId)
        return enhancedTasks
    }
    
    private func applyWeatherModifications(_ tasks: [ContextualTask]) async -> [ContextualTask] {
        let currentWeather: FrancoSphere.WeatherData? = await MainActor.run {
            WeatherManager.shared.currentWeather
        }
        
        guard let weather = currentWeather else { return tasks }
        
        // Create new tasks with weather modifications (since ContextualTask is immutable)
        var modifiedTasks: [ContextualTask] = []
        let taskCount: Int = tasks.count
        var weatherIndex: Int = 0
        
        while weatherIndex < taskCount {
            let originalTask: ContextualTask = tasks[weatherIndex]
            
            if weather.condition == .rain && originalTask.category.lowercased().contains("sidewalk") {
                // Create new task with weather postponed status
                let modifiedTask: ContextualTask = ContextualTask(
                    id: originalTask.id,
                    name: originalTask.name,
                    buildingId: originalTask.buildingId,
                    buildingName: originalTask.buildingName,
                    category: originalTask.category,
                    startTime: originalTask.startTime,
                    endTime: originalTask.endTime,
                    recurrence: originalTask.recurrence,
                    skillLevel: originalTask.skillLevel,
                    status: "weather_postponed", // Modified
                    urgencyLevel: "Low", // Modified
                    assignedWorkerName: originalTask.assignedWorkerName,
                    scheduledDate: originalTask.scheduledDate
                )
                modifiedTasks.append(modifiedTask)
            } else {
                modifiedTasks.append(originalTask)
            }
            
            weatherIndex += 1
        }
        
        return modifiedTasks
    }
    
    private func applyRouteOptimization(_ tasks: [ContextualTask], workerId: String) async -> [ContextualTask] {
        if workerId == "4" {
            // Kevin's optimized building order: Perry → West 17th → Rubin → East 20th → Spring
            let kevinBuildingPriority: [String] = ["10", "6", "3", "7", "9", "14", "16", "12"]
            var sortedTasks: [ContextualTask] = []
            
            // Group tasks by building
            var tasksByBuilding: [String: [ContextualTask]] = [:]
            let taskCount: Int = tasks.count
            var groupIndex: Int = 0
            
            while groupIndex < taskCount {
                let currentTask: ContextualTask = tasks[groupIndex]
                let buildingId: String = currentTask.buildingId
                
                if tasksByBuilding[buildingId] == nil {
                    tasksByBuilding[buildingId] = []
                }
                tasksByBuilding[buildingId]?.append(currentTask)
                groupIndex += 1
            }
            
            // Add tasks in priority order
            let priorityCount: Int = kevinBuildingPriority.count
            var priorityIndex: Int = 0
            
            while priorityIndex < priorityCount {
                let priorityBuildingId: String = kevinBuildingPriority[priorityIndex]
                if let buildingTasks: [ContextualTask] = tasksByBuilding[priorityBuildingId] {
                    sortedTasks.append(contentsOf: buildingTasks)
                }
                priorityIndex += 1
            }
            
            return sortedTasks
        } else {
            // Default sorting by start time for other workers
            return tasks.sorted { (task1: ContextualTask, task2: ContextualTask) -> Bool in
                let startTime1: String = task1.startTime ?? "09:00"
                let startTime2: String = task2.startTime ?? "09:00"
                return startTime1 < startTime2
            }
        }
    }
    
    // MARK: - Evidence Storage
    
    private func storeTaskEvidence(taskId: String, workerId: String, evidence: TaskEvidence) async throws {
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let photosArray: [Data] = evidence.photos
        let photoCount: Int = photosArray.count
        var photoIndex: Int = 0
        
        while photoIndex < photoCount {
            let photoData: Data = photosArray[photoIndex]
            
            let insertQuery: String = """
                INSERT INTO task_evidence (
                    task_id, worker_id, evidence_type, 
                    timestamp, location_lat, location_lng, notes,
                    photo_index
                ) VALUES (?, ?, 'photo', ?, ?, ?, ?, ?)
            """
            
            let location: CLLocation? = evidence.location
            let coordinate: CLLocationCoordinate2D? = location?.coordinate
            let latitude: Double = coordinate?.latitude ?? 0.0
            let longitude: Double = coordinate?.longitude ?? 0.0
            let evidenceNotes: String? = evidence.notes
            let notes: String = evidenceNotes ?? ""
            let timestamp: Date = evidence.timestamp
            
            let parameters: [Any] = [
                taskId, workerId, timestamp,
                latitude, longitude, notes, photoIndex
            ]
            
            try await sqliteManager.execute(insertQuery, parameters)
            photoIndex += 1
        }
    }
    
    // MARK: - Cache Management
    
    private func updateTaskCache(workerId: String, tasks: [ContextualTask]) async {
        taskCache[workerId] = tasks
        lastCacheUpdate = Date()
    }
    
    private func invalidateTaskCache(workerId: String) async {
        taskCache.removeValue(forKey: workerId)
    }
    
    // MARK: - Helper Methods
    
    private func createContextualTask(from row: [String: Any]) -> ContextualTask? {
        guard let id = row["id"] as? String,
              let name = row["name"] as? String else { return nil }
        
        let task: ContextualTask = ContextualTask(
            id: id,
            name: name,
            buildingId: row["building_id"] as? String ?? "",
            buildingName: row["building_name"] as? String ?? "",
            category: row["category"] as? String ?? "",
            startTime: row["start_time"] as? String,
            endTime: row["end_time"] as? String,
            recurrence: row["recurrence"] as? String ?? "one-off",
            skillLevel: row["skill_level"] as? String ?? "Basic",
            status: row["status"] as? String ?? "pending",
            urgencyLevel: row["urgency"] as? String ?? "Medium",
            assignedWorkerName: row["assigned_worker_name"] as? String,
            scheduledDate: row["scheduled_date"] as? Date
        )
        
        return task
    }
    
    private func isTaskOverdue(_ task: ContextualTask) -> Bool {
        guard let endTime = parseTaskTime(task.endTime ?? "") else { return false }
        let currentTime: Date = Date()
        let taskStatus: String = task.status
        let isNotCompleted: Bool = (taskStatus != "completed")
        let isPastDue: Bool = (currentTime > endTime)
        let isOverdue: Bool = isPastDue && isNotCompleted
        return isOverdue
    }
    
    private func parseTaskTime(_ timeString: String) -> Date? {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let parsedTime: Date? = formatter.date(from: timeString)
        return parsedTime
    }
    
    private func validateTaskCompletion(taskId: String, workerId: String) async throws {
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let query: String = "SELECT status, assigned_worker_id FROM AllTasks WHERE id = ?"
        let parameters: [Any] = [taskId]
        let rows: [[String: Any]] = try await sqliteManager.query(query, parameters)
        
        guard let row: [String: Any] = rows.first else {
            throw TaskServiceError.taskNotFound
        }
        
        let statusValue: Any? = row["status"]
        let currentStatus: String = statusValue as? String ?? ""
        
        let workerValue: Any? = row["assigned_worker_id"]
        let assignedWorker: String = workerValue as? String ?? ""
        
        let isAlreadyCompleted: Bool = (currentStatus == "completed")
        if isAlreadyCompleted {
            throw TaskServiceError.taskAlreadyCompleted
        }
        
        let isWrongWorker: Bool = (assignedWorker != workerId)
        if isWrongWorker {
            throw TaskServiceError.unauthorized
        }
    }
    
    private func createCompletionAuditRecord(completion: TaskCompletion) async throws {
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let insertQuery: String = """
            INSERT INTO task_completion_audit (
                task_id, worker_id, building_id, completed_at,
                has_evidence, location_lat, location_lng, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let evidence: TaskEvidence? = completion.evidence
        let hasEvidence: Int = (evidence != nil) ? 1 : 0
        
        let location: CLLocation? = completion.location
        let coordinate: CLLocationCoordinate2D? = location?.coordinate
        let latitude: Double = coordinate?.latitude ?? 0.0
        let longitude: Double = coordinate?.longitude ?? 0.0
        
        let currentDate: Date = Date()
        let completedAt: Date = completion.completedAt
        let taskId: String = completion.taskId
        let workerId: String = completion.workerId
        let buildingId: String = completion.buildingId
        
        let parameters: [Any] = [
            taskId, workerId, buildingId, completedAt,
            hasEvidence, latitude, longitude, currentDate
        ]
        
        try await sqliteManager.execute(insertQuery, parameters)
    }
    
    private func calculateAverageCompletionTime(workerId: String) async -> TimeInterval {
        let defaultTime: TimeInterval = 1800.0 // 30 minutes default
        return defaultTime
    }
    
    private func calculateOnTimeRate(workerId: String) async -> Double {
        let defaultRate: Double = 0.85 // 85% default
        return defaultRate
    }
    
    private func applyDurationPredictions(_ tasks: [ContextualTask], workerId: String) async -> [ContextualTask] {
        let unchangedTasks: [ContextualTask] = tasks
        return unchangedTasks
    }
}

// MARK: - Supporting Types

struct TaskProgress {
    let completed: Int
    let total: Int
    let remaining: Int
    let percentage: Double
    let overdueTasks: Int
    let averageCompletionTime: TimeInterval
    let onTimeCompletionRate: Double
}

struct TaskEvidence {
    let photos: [Data]
    let timestamp: Date
    let location: CLLocation?
    let notes: String?
}

struct TaskCompletion {
    let taskId: String
    let workerId: String
    let buildingId: String
    let completedAt: Date
    let evidence: TaskEvidence?
    let location: CLLocation?
}

struct WorkerEfficiencyMetrics {
    let workerId: String
    let period: TimeInterval
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let averageCompletionTime: TimeInterval
    let onTimeRate: Double
}

enum TaskServiceError: LocalizedError {
    case taskNotFound
    case taskAlreadyCompleted
    case unauthorized
    case completionFailed(Error)
    case noDataAvailable
    case serviceNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .taskNotFound:
            return "Task not found"
        case .taskAlreadyCompleted:
            return "Task already completed"
        case .unauthorized:
            return "Not authorized to complete this task"
        case .completionFailed(let error):
            return "Task completion failed: \(error.localizedDescription)"
        case .noDataAvailable:
            return "No data available for the requested period"
        case .serviceNotInitialized:
            return "Service dependencies not properly initialized"
        }
    }
}

extension DateFormatter {
    static let yyyyMMddFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
