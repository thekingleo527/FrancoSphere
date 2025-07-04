//
//  TaskService.swift
//  FrancoSphere
//
//  🔧 COMPILATION ERRORS FIXED
//  ✅ Fixed SQLite.Binding ambiguity by using typealias
//  ✅ Maintains Kevin's Rubin Museum correction
//  ✅ All methods properly scoped within actor
//

import Foundation
import CoreLocation
import Combine
import SQLite
import SwiftUI

actor TaskService {
    static let shared = TaskService()
    
    // MARK: - Type Aliases (Fix Binding Ambiguity)
    typealias SQLiteBinding = SQLite.Binding
    
    // MARK: - Dependencies
    private var sqliteManager: SQLiteManager?
    private var operationalDataManager: OperationalDataManager?
    private var isInitialized = false
    
    // MARK: - Cache Management
    private var taskCache: [String: [ContextualTask]] = [:]
    private var completionCache: [String: TSTaskCompletion] = [:]
    private var buildingStatusCache: [String: TSBuildingStatus] = [:]
    private let cacheTimeout: TimeInterval = 300
    private var lastCacheUpdate: Date = Date.distantPast
    
    // MARK: - Initialization
    private init() {
        Task {
            await initialize()
        }
    }
    
    private func initialize() async {
        do {
            self.sqliteManager = SQLiteManager.shared
            self.operationalDataManager = await OperationalDataManager.shared
            await createTablesIfNeeded()
            await importOperationalDataIfNeeded()
            self.isInitialized = true
            print("✅ TaskService initialized successfully")
        } catch {
            print("❌ TaskService initialization failed: \(error)")
        }
    }
    
    private func ensureInitialized() async throws {
        guard isInitialized else {
            throw TaskServiceError.serviceNotInitialized
        }
    }
    
    // MARK: - Database Schema Management
    private func createTablesIfNeeded() async {
        await createTasksTable()
        await createTaskAssignmentsTable()
        await createTaskCompletionLogTable()
        await createTaskEvidenceTable()
        await createTaskVerificationTable()
        await createCompletionAuditTable()
        await createTaskPhotosTable()
        await createTaskInventoryTable()
        await createTaskTemplatesTable()
    }
    
    private func createTasksTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS master_tasks (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    category TEXT NOT NULL,
                    skill_required TEXT NOT NULL,
                    recurrence TEXT NOT NULL,
                    description TEXT,
                    urgency TEXT NOT NULL,
                    estimated_duration INTEGER DEFAULT 30,
                    requires_verification INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating master_tasks table: \(error)")
        }
    }
    
    private func createTaskAssignmentsTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_assignments (
                    id TEXT PRIMARY KEY,
                    building_id TEXT NOT NULL,
                    task_name TEXT NOT NULL,
                    worker_id TEXT NOT NULL,
                    recurrence TEXT NOT NULL,
                    day_of_week INTEGER,
                    start_time TEXT,
                    end_time TEXT,
                    category TEXT NOT NULL,
                    skill_level TEXT NOT NULL,
                    is_active INTEGER DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_assignments table: \(error)")
        }
    }
    
    private func createTaskCompletionLogTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_completion_log (
                    id TEXT PRIMARY KEY,
                    task_id TEXT NOT NULL,
                    worker_id TEXT NOT NULL,
                    building_id TEXT NOT NULL,
                    completed_at TIMESTAMP NOT NULL,
                    duration_minutes INTEGER,
                    completion_notes TEXT,
                    has_evidence INTEGER DEFAULT 0,
                    location_lat REAL,
                    location_lng REAL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_completion_log table: \(error)")
        }
    }
    
    private func createTaskEvidenceTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_evidence (
                    id TEXT PRIMARY KEY,
                    task_id TEXT NOT NULL,
                    worker_id TEXT NOT NULL,
                    evidence_type TEXT NOT NULL,
                    file_path TEXT,
                    encrypted_key_id TEXT,
                    timestamp TIMESTAMP NOT NULL,
                    location_lat REAL,
                    location_lng REAL,
                    notes TEXT,
                    photo_index INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_evidence table: \(error)")
        }
    }
    
    private func createTaskVerificationTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_verification (
                    id TEXT PRIMARY KEY,
                    task_id TEXT NOT NULL,
                    verifier_id TEXT NOT NULL,
                    verification_status TEXT NOT NULL,
                    verification_date TIMESTAMP NOT NULL,
                    verification_notes TEXT,
                    rejection_reason TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_verification table: \(error)")
        }
    }
    
    private func createCompletionAuditTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_completion_audit (
                    id TEXT PRIMARY KEY,
                    task_id TEXT NOT NULL,
                    worker_id TEXT NOT NULL,
                    building_id TEXT NOT NULL,
                    completed_at TIMESTAMP NOT NULL,
                    has_evidence INTEGER DEFAULT 0,
                    location_lat REAL,
                    location_lng REAL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_completion_audit table: \(error)")
        }
    }
    
    private func createTaskPhotosTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_photos (
                    id TEXT PRIMARY KEY,
                    task_id TEXT NOT NULL,
                    photo_path TEXT NOT NULL,
                    encrypted_key_id TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_photos table: \(error)")
        }
    }
    
    private func createTaskInventoryTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_inventory_requirements (
                    id TEXT PRIMARY KEY,
                    task_id TEXT NOT NULL,
                    item_name TEXT NOT NULL,
                    required_quantity INTEGER NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_inventory_requirements table: \(error)")
        }
    }
    
    private func createTaskTemplatesTable() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            try await sqliteManager.execute("""
                CREATE TABLE IF NOT EXISTS task_templates (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT,
                    building_id TEXT NOT NULL,
                    category TEXT NOT NULL,
                    urgency TEXT NOT NULL,
                    recurrence_pattern TEXT NOT NULL,
                    days_of_week TEXT,
                    start_time TEXT NOT NULL,
                    end_time TEXT NOT NULL,
                    assigned_worker_id TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """, emptyParams)
        } catch {
            print("❌ Error creating task_templates table: \(error)")
        }
    }
    
    // MARK: - Operational Data Import
    private func importOperationalDataIfNeeded() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let emptyParams: [SQLiteBinding] = []
            let result = try await sqliteManager.query("SELECT COUNT(*) as count FROM master_tasks", emptyParams)
            let count = result.first?["count"] as? Int64 ?? 0
            
            if count == 0 {
                await importMasterTasksFromOperationalData()
                await importTaskAssignmentsFromOperationalData()
                print("✅ Operational data imported successfully")
            }
        } catch {
            print("❌ Error checking existing data: \(error)")
        }
    }
    
    private func importMasterTasksFromOperationalData() async {
        guard let sqliteManager = sqliteManager else { return }
        
        let masterTasks: [[String: Any]] = [
            // Kevin's Rubin Museum Tasks
            ["id": "rubin_trash_sweep", "name": "Trash Area + Sidewalk & Curb Clean", "category": "Sanitation", "skillRequired": "Basic", "recurrence": "Daily", "description": "Clean trash area and sweep sidewalk at Rubin Museum", "urgency": "Medium", "estimatedDuration": 30, "requiresVerification": 0],
            ["id": "rubin_entrance_clean", "name": "Entrance Deep Clean", "category": "Cleaning", "skillRequired": "Basic", "recurrence": "Weekly", "description": "Deep clean museum entrance and glass doors", "urgency": "Medium", "estimatedDuration": 45, "requiresVerification": 1],
            
            // Perry Street Cluster Tasks
            ["id": "perry_lobby_clean", "name": "Lobby Floor Cleaning", "category": "Cleaning", "skillRequired": "Basic", "recurrence": "Daily", "description": "Clean and maintain lobby floors", "urgency": "Medium", "estimatedDuration": 20, "requiresVerification": 0],
            ["id": "perry_stair_sweep", "name": "Stairwell Cleaning", "category": "Cleaning", "skillRequired": "Basic", "recurrence": "Weekly", "description": "Sweep and mop all stairwells", "urgency": "Medium", "estimatedDuration": 30, "requiresVerification": 0],
            ["id": "perry_trash_collection", "name": "Garbage Collection", "category": "Sanitation", "skillLevel": "Basic", "recurrence": "Daily", "description": "Collect and dispose of building trash", "urgency": "High", "estimatedDuration": 15, "requiresVerification": 0],
        ]
        
        for task in masterTasks {
            do {
                let taskParams: [SQLiteBinding] = [
                    task["id"] as? String ?? "",
                    task["name"] as? String ?? "",
                    task["category"] as? String ?? "",
                    task["skillRequired"] as? String ?? "",
                    task["recurrence"] as? String ?? "",
                    task["description"] as? String ?? "",
                    task["urgency"] as? String ?? "",
                    task["estimatedDuration"] as? Int ?? 30,
                    task["requiresVerification"] as? Int ?? 0
                ]
                
                try await sqliteManager.execute("""
                    INSERT OR IGNORE INTO master_tasks 
                    (id, name, category, skill_required, recurrence, description, urgency, estimated_duration, requires_verification)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, taskParams)
            } catch {
                print("❌ Error inserting master task \(task["name"] ?? ""): \(error)")
            }
        }
    }
    
    private func importTaskAssignmentsFromOperationalData() async {
        guard let sqliteManager = sqliteManager else { return }
        
        let assignments: [[String: Any]] = [
            // Kevin's Rubin Museum (ID: 14) - CORRECTED
            ["id": "kevin_rubin_daily", "buildingId": "14", "taskName": "Trash Area + Sidewalk & Curb Clean", "workerId": "4", "recurrence": "Daily", "dayOfWeek": 0, "startTime": "10:00", "endTime": "11:00", "category": "Sanitation", "skillLevel": "Basic"],
            ["id": "kevin_rubin_weekly", "buildingId": "14", "taskName": "Entrance Deep Clean", "workerId": "4", "recurrence": "Weekly", "dayOfWeek": 1, "startTime": "10:00", "endTime": "11:30", "category": "Cleaning", "skillLevel": "Basic"],
        ]
        
        for assignment in assignments {
            do {
                let assignmentParams: [SQLiteBinding] = [
                    assignment["id"] as? String ?? "",
                    assignment["buildingId"] as? String ?? "",
                    assignment["taskName"] as? String ?? "",
                    assignment["workerId"] as? String ?? "",
                    assignment["recurrence"] as? String ?? "",
                    assignment["dayOfWeek"] as? Int ?? 0,
                    assignment["startTime"] as? String ?? "",
                    assignment["endTime"] as? String ?? "",
                    assignment["category"] as? String ?? "",
                    assignment["skillLevel"] as? String ?? ""
                ]
                
                try await sqliteManager.execute("""
                    INSERT OR IGNORE INTO task_assignments 
                    (id, building_id, task_name, worker_id, recurrence, day_of_week, start_time, end_time, category, skill_level)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, assignmentParams)
            } catch {
                print("❌ Error inserting assignment \(assignment["id"] ?? ""): \(error)")
            }
        }
    }
    
    // MARK: - Primary Task Retrieval
    func getTasks(for workerId: String, date: Date) async throws -> [ContextualTask] {
        try await ensureInitialized()
        
        // Priority 1: OperationalDataManager data
        let operationalTasks: [ContextualTask] = await getOperationalTasks(for: workerId, date: date)
        
        if !operationalTasks.isEmpty {
            print("✅ Using operational data for worker \(workerId): \(operationalTasks.count) tasks")
            let enhancedTasks: [ContextualTask] = await enhanceTasksWithIntelligence(operationalTasks, workerId: workerId)
            await updateTaskCache(workerId: workerId, tasks: enhancedTasks)
            return enhancedTasks
        }
        
        // Priority 2: Database-generated tasks
        print("⚠️ No operational data for worker \(workerId), using database generation")
        let databaseTasks: [ContextualTask] = try await generateTasksFromDatabase(for: workerId, date: date)
        
        // Priority 3: Kevin's special correction
        if workerId == "4" {
            let correctedTasks: [ContextualTask] = await applyKevinRubinCorrection(tasks: databaseTasks, date: date)
            return correctedTasks
        }
        
        return databaseTasks
    }
    
    private func getOperationalTasks(for workerId: String, date: Date) async -> [ContextualTask] {
        guard let operationalDataManager = operationalDataManager else { return [] }
        
        return await withCheckedContinuation { continuation in
            Task { @MainActor in
                let tasks = await operationalDataManager.getTasksForWorker(workerId, date: date)
                continuation.resume(returning: tasks)
            }
        }
    }
    
    private func generateTasksFromDatabase(for workerId: String, date: Date) async throws -> [ContextualTask] {
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date) - 1 // 0 = Sunday, 1 = Monday
        
        let query = """
            SELECT ta.id, ta.building_id, ta.task_name, ta.start_time, ta.end_time, ta.category, ta.skill_level,
                   mt.description, mt.urgency, mt.estimated_duration, mt.requires_verification
            FROM task_assignments ta
            JOIN master_tasks mt ON ta.task_name = mt.name
            WHERE ta.worker_id = ? AND ta.is_active = 1 
            AND (ta.day_of_week = ? OR ta.day_of_week = 0)
            ORDER BY ta.start_time ASC
        """
        
        let queryParameters: [SQLiteBinding] = [workerId, weekday]
        let rows = try await sqliteManager.query(query, queryParameters)
        
        var tasks: [ContextualTask] = []
        
        for row in rows {
            guard let assignmentId = row["id"] as? String,
                  let buildingId = row["building_id"] as? String,
                  let taskName = row["task_name"] as? String,
                  let category = row["category"] as? String,
                  let skillLevel = row["skill_level"] as? String,
                  let urgency = row["urgency"] as? String else { continue }
            
            let startTime = row["start_time"] as? String ?? "09:00"
            let endTime = row["end_time"] as? String ?? "10:00"
            let description = row["description"] as? String ?? ""
            
            // Generate unique task ID for this date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            let task = ContextualTask(
                id: "\(assignmentId)_\(dateString)",
                name: taskName,
                buildingId: buildingId,
                buildingName: await getBuildingName(buildingId),
                category: category,
                startTime: startTime,
                endTime: endTime,
                recurrence: "Daily",
                skillLevel: skillLevel,
                status: await getTaskStatus(assignmentId, date: date),
                urgencyLevel: urgency,
                assignedWorkerName: await getWorkerName(workerId),
                scheduledDate: date
            )
            
            tasks.append(task)
        }
        
        return tasks
    }
    
    private func applyKevinRubinCorrection(tasks: [ContextualTask], date: Date) async -> [ContextualTask] {
        var correctedTasks = tasks
        
        // Remove any Franklin Street tasks (ID: 13)
        correctedTasks = correctedTasks.filter { $0.buildingId != "13" }
        
        // Ensure Kevin has Rubin Museum task
        let hasRubinTask = correctedTasks.contains { $0.buildingId == "14" }
        
        if !hasRubinTask {
            print("🔧 KEVIN CORRECTION: Adding missing Rubin Museum task")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: date)
            
            let rubinTask = ContextualTask(
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
            
            correctedTasks.append(rubinTask)
        }
        
        return correctedTasks
    }
    
    // MARK: - Task Completion
    func completeTask(_ taskId: String, workerId: String, buildingId: String, evidence: TSTaskEvidence?) async throws {
        try await ensureInitialized()
        
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        // Create completion record
        let completion = TSTaskCompletion(
            taskId: taskId,
            workerId: workerId,
            buildingId: buildingId,
            completedAt: Date(),
            evidence: evidence,
            location: evidence?.location
        )
        
        // Store completion in database
        try await storeTaskCompletion(completion)
        
        // Store evidence if provided
        if let evidence = evidence {
            try await storeTaskEvidence(taskId: taskId, workerId: workerId, evidence: evidence)
        }
        
        // Update cache
        completionCache[taskId] = completion
        await invalidateTaskCache(workerId: workerId)
        
        print("✅ Task \(taskId) completed by worker \(workerId)")
    }
    
    private func storeTaskCompletion(_ completion: TSTaskCompletion) async throws {
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let insertQuery = """
            INSERT INTO task_completion_log (
                id, task_id, worker_id, building_id, completed_at,
                duration_minutes, completion_notes, has_evidence,
                location_lat, location_lng
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let durationMinutes = 30 // Default duration
        let completionNotes = completion.evidence?.notes ?? ""
        let hasEvidence = completion.evidence != nil ? 1 : 0
        let lat = completion.location?.coordinate.latitude ?? 0.0
        let lng = completion.location?.coordinate.longitude ?? 0.0
        
        let parameters: [SQLiteBinding] = [
            UUID().uuidString, completion.taskId, completion.workerId, completion.buildingId,
            ISO8601DateFormatter().string(from: completion.completedAt), durationMinutes, completionNotes, hasEvidence, lat, lng
        ]
        
        try await sqliteManager.execute(insertQuery, parameters)
    }
    
    // MARK: - Task Progress & Metrics
    func getTaskProgress(for workerId: String) async throws -> TSTaskProgress {
        let todaysTasks = try await getTasks(for: workerId, date: Date())
        
        var completedCount = 0
        var overdueCount = 0
        
        for task in todaysTasks {
            if task.status == "completed" {
                completedCount += 1
            }
            if isTaskOverdue(task) {
                overdueCount += 1
            }
        }
        
        let total = max(todaysTasks.count, 1)
        let remaining = total - completedCount
        let percentage = Double(completedCount) / Double(total) * 100.0
        
        return TSTaskProgress(
            completed: completedCount,
            total: total,
            remaining: remaining,
            percentage: percentage,
            overdueTasks: overdueCount,
            averageCompletionTime: await calculateAverageCompletionTime(workerId: workerId),
            onTimeCompletionRate: await calculateOnTimeRate(workerId: workerId)
        )
    }
    
    // MARK: - Task Creation Methods
    func createTask(
        name: String,
        description: String,
        buildingId: String,
        category: String,
        urgency: String,
        scheduledDate: Date,
        startTime: Date? = nil,
        endTime: Date? = nil,
        assignedWorkerId: String? = nil,
        requiredInventory: [String: Int] = [:],
        photo: Data? = nil
    ) async throws -> ContextualTask {
        
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let taskId = UUID().uuidString
        
        let insertQuery = """
            INSERT INTO AllTasks (
                id, name, description, building_id, category, urgency, 
                scheduled_date, start_time, end_time, assigned_worker_id,
                status, skill_level, recurrence, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'pending', 'Basic', 'one-off', ?)
        """
        
        let scheduledDateString = ISO8601DateFormatter().string(from: scheduledDate)
        let startTimeString = startTime.map { DateFormatter.timeOnly.string(from: $0) }
        let endTimeString = endTime.map { DateFormatter.timeOnly.string(from: $0) }
        let createdAt = ISO8601DateFormatter().string(from: Date())
        
        let parameters: [SQLiteBinding] = [
            taskId, name, description, buildingId, category, urgency,
            scheduledDateString, startTimeString ?? "", endTimeString ?? "", assignedWorkerId ?? "",
            createdAt
        ]
        
        try await sqliteManager.execute(insertQuery, parameters)
        
        // Store photo if provided
        if let photoData = photo {
            try await storeTaskPhoto(taskId: taskId, photoData: photoData)
        }
        
        // Store required inventory
        if !requiredInventory.isEmpty {
            try await storeRequiredInventory(taskId: taskId, inventory: requiredInventory)
        }
        
        // Get building name
        let buildingName = await getBuildingName(buildingId)
        
        // Create and return ContextualTask
        let contextualTask = ContextualTask(
            id: taskId,
            name: name,
            buildingId: buildingId,
            buildingName: buildingName,
            category: category,
            startTime: startTimeString ?? "",
            endTime: endTimeString ?? "",
            recurrence: "one-off",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: urgency,
            assignedWorkerName: assignedWorkerId ?? ""
        )
        
        print("✅ Task created successfully: \(name) for building \(buildingName)")
        
        return contextualTask
    }
    
    func createRecurringTask(
        name: String,
        description: String,
        buildingId: String,
        category: String,
        urgency: String,
        recurrencePattern: String,
        daysOfWeek: [Int] = [],
        startTime: String,
        endTime: String,
        assignedWorkerId: String? = nil
    ) async throws -> String {
        
        guard let sqliteManager = sqliteManager else {
            throw TaskServiceError.serviceNotInitialized
        }
        
        let templateId = UUID().uuidString
        
        let insertQuery = """
            INSERT INTO task_templates (
                id, name, description, building_id, category, urgency,
                recurrence_pattern, days_of_week, start_time, end_time,
                assigned_worker_id, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let daysOfWeekString = daysOfWeek.map(String.init).joined(separator: ",")
        let createdAt = ISO8601DateFormatter().string(from: Date())
        
        let parameters: [SQLiteBinding] = [
            templateId, name, description, buildingId, category, urgency,
            recurrencePattern, daysOfWeekString, startTime, endTime, assignedWorkerId ?? "", createdAt
        ]
        
        try await sqliteManager.execute(insertQuery, parameters)
        
        print("✅ Recurring task template created: \(name)")
        
        return templateId
    }
    
    // MARK: - Helper Methods
    private func getBuildingName(_ buildingId: String) async -> String {
        switch buildingId {
        case "1": return "12 West 18th Street"
        case "2": return "14 West 18th Street"
        case "3": return "135-139 West 17th Street"
        case "6": return "68 Perry Street"
        case "7": return "136 West 17th Street"
        case "9": return "138 West 17th Street"
        case "10": return "131 Perry Street"
        case "12": return "178 Spring Street"
        case "13": return "104 Franklin Street"
        case "14": return "Rubin Museum (142–148 W 17th)"
        case "16": return "29-31 East 20th Street"
        default: return "Building \(buildingId)"
        }
    }
    
    private func getWorkerName(_ workerId: String) async -> String {
        switch workerId {
        case "1": return "Greg Hutson"
        case "2": return "Edwin Vásquez"
        case "4": return "Kevin Dutan"
        case "5": return "Luis Anaya"
        case "6": return "Mercedes Romero"
        case "7": return "Angel Guirachocha"
        case "8": return "Shawn Magloire"
        default: return "Worker \(workerId)"
        }
    }
    
    private func getTaskStatus(_ assignmentId: String, date: Date) async -> String {
        if let completion = completionCache[assignmentId] {
            let calendar = Calendar.current
            if calendar.isDate(completion.completedAt, inSameDayAs: date) {
                return "completed"
            }
        }
        return "pending"
    }
    
    private func isTaskOverdue(_ task: ContextualTask) -> Bool {
        guard let endTime = parseTaskTime(task.endTime ?? ""),
              let scheduledDate = task.scheduledDate else { return false }
        
        let calendar = Calendar.current
        let taskEndDateTime = calendar.date(byAdding: .minute, value: calendar.component(.hour, from: endTime) * 60 + calendar.component(.minute, from: endTime), to: scheduledDate)
        
        return Date() > (taskEndDateTime ?? Date())
    }
    
    private func parseTaskTime(_ timeString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.date(from: timeString)
    }
    
    private func calculateAverageCompletionTime(workerId: String) async -> TimeInterval {
        return 1800.0 // 30 minutes default
    }
    
    private func calculateOnTimeRate(workerId: String) async -> Double {
        return 0.85 // 85% default
    }
    
    private func storeTaskEvidence(taskId: String, workerId: String, evidence: TSTaskEvidence) async throws {
        guard let sqliteManager = sqliteManager else { return }
        
        for (index, _) in evidence.photos.enumerated() {
            let insertQuery = """
                INSERT INTO task_evidence (
                    id, task_id, worker_id, evidence_type, 
                    timestamp, location_lat, location_lng, notes, photo_index
                ) VALUES (?, ?, ?, 'photo', ?, ?, ?, ?, ?)
            """
            
            let lat = evidence.location?.coordinate.latitude ?? 0.0
            let lng = evidence.location?.coordinate.longitude ?? 0.0
            
            let evidenceParams: [SQLiteBinding] = [
                UUID().uuidString, taskId, workerId, ISO8601DateFormatter().string(from: evidence.timestamp),
                lat, lng, evidence.notes ?? "", index
            ]
            
            try await sqliteManager.execute(insertQuery, evidenceParams)
        }
    }
    
    private func storeTaskPhoto(taskId: String, photoData: Data) async throws {
        guard let sqliteManager = sqliteManager else { return }
        
        // Encrypt and store photo
        let encryptedPhoto = try await SecurityManager.shared.encryptPhoto(photoData, taskId: taskId)
        
        let insertQuery = """
            INSERT INTO task_photos (
                id, task_id, photo_path, encrypted_key_id, created_at
            ) VALUES (?, ?, ?, ?, ?)
        """
        
        let photoPath = "task_photos/\(taskId)_\(Date().timeIntervalSince1970).enc"
        
        let parameters: [SQLiteBinding] = [
            UUID().uuidString, taskId, photoPath, encryptedPhoto.keyIdentifier,
            ISO8601DateFormatter().string(from: Date())
        ]
        
        try await sqliteManager.execute(insertQuery, parameters)
    }
    
    private func storeRequiredInventory(taskId: String, inventory: [String: Int]) async throws {
        guard let sqliteManager = sqliteManager else { return }
        
        for (itemName, quantity) in inventory {
            let insertQuery = """
                INSERT INTO task_inventory_requirements (
                    id, task_id, item_name, required_quantity, created_at
                ) VALUES (?, ?, ?, ?, ?)
            """
            
            let parameters: [SQLiteBinding] = [
                UUID().uuidString, taskId, itemName, quantity,
                ISO8601DateFormatter().string(from: Date())
            ]
            
            try await sqliteManager.execute(insertQuery, parameters)
        }
    }
    
    private func enhanceTasksWithIntelligence(_ tasks: [ContextualTask], workerId: String) async -> [ContextualTask] {
        // Apply route optimization for Kevin
        if workerId == "4" {
            let kevinBuildingOrder = ["10", "6", "3", "7", "9", "14", "16", "12"]
            
            return tasks.sorted { task1, task2 in
                let index1 = kevinBuildingOrder.firstIndex(of: task1.buildingId) ?? 999
                let index2 = kevinBuildingOrder.firstIndex(of: task2.buildingId) ?? 999
                return index1 < index2
            }
        } else {
            return tasks.sorted { task1, task2 in
                let time1 = task1.startTime ?? "09:00"
                let time2 = task2.startTime ?? "09:00"
                return time1 < time2
            }
        }
    }
    
    private func updateTaskCache(workerId: String, tasks: [ContextualTask]) async {
        taskCache[workerId] = tasks
        lastCacheUpdate = Date()
    }
    
    private func invalidateTaskCache(workerId: String) async {
        taskCache.removeValue(forKey: workerId)
    }
}

// MARK: - Supporting Types

struct TSTaskProgress {
    let completed: Int
    let total: Int
    let remaining: Int
    let percentage: Double
    let overdueTasks: Int
    let averageCompletionTime: TimeInterval
    let onTimeCompletionRate: Double
}

struct TSTaskEvidence {
    let photos: [Data]
    let timestamp: Date
    let location: CLLocation?
    let notes: String?
}

struct TSTaskCompletion {
    let taskId: String
    let workerId: String
    let buildingId: String
    let completedAt: Date
    let evidence: TSTaskEvidence?
    let location: CLLocation?
}

enum TSBuildingStatus: String, CaseIterable {
    case operational = "Operational"
    case underMaintenance = "Under Maintenance"
    case closed = "Closed"
    case routineComplete = "Routine Complete"
    case routinePartial = "Routine Partial"
    case routinePending = "Routine Pending"
    case routineOverdue = "Routine Overdue"
}

enum TaskServiceError: LocalizedError {
    case taskNotFound
    case taskAlreadyCompleted
    case unauthorized
    case completionFailed(Error)
    case noDataAvailable
    case serviceNotInitialized
    case invalidTaskData
    case databaseError(Error)
    
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
        case .invalidTaskData:
            return "Invalid task data provided"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}
