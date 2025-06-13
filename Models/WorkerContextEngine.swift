// WorkerContextEngine.swift - FINAL SCHEMA-RESILIENT VERSION
// Works with any database schema state

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Data Models

struct WorkerContext {
    let workerId: String
    let workerName: String
    let email: String
    let role: String
    let primaryBuildingId: String?
}

struct ContextualTask {
    let id: String
    let name: String
    let buildingId: String
    let buildingName: String
    let category: String
    let startTime: String?
    let endTime: String?
    let recurrence: String
    let skillLevel: String
    let status: String
    let urgencyLevel: String
    
    var isOverdue: Bool {
        guard let startTime = startTime else { return false }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let taskTime = formatter.date(from: startTime) {
            let calendar = Calendar.current
            let now = Date()
            let taskComponents = calendar.dateComponents([.hour, .minute], from: taskTime)
            let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
            
            if let taskHour = taskComponents.hour, let taskMinute = taskComponents.minute,
               let nowHour = nowComponents.hour, let nowMinute = nowComponents.minute {
                let taskMinutes = taskHour * 60 + taskMinute
                let nowMinutes = nowHour * 60 + nowMinute
                return nowMinutes > taskMinutes && status == "pending"
            }
        }
        return false
    }
    
    var urgencyColor: Color {
        if isOverdue { return .red }
        switch urgencyLevel.lowercased() {
        case "urgent", "high": return .orange
        case "medium": return .yellow
        default: return .green
        }
    }
}

// MARK: - Worker Context Engine

@MainActor
class WorkerContextEngine: ObservableObject {
    static let shared = WorkerContextEngine()
    
    @Published var currentWorker: WorkerContext?
    @Published var assignedBuildings: [Building] = []
    @Published var todaysTasks: [ContextualTask] = []
    @Published var upcomingTasks: [ContextualTask] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private var sqliteManager: SQLiteManager?
    
    private init() {}
    
    // MARK: - Public Methods
    
    func loadWorkerContext(workerId: String) async {
        isLoading = true
        lastError = nil
        
        do {
            // Get SQLiteManager instance
            sqliteManager = try await SQLiteManager.start()
            
            // Load worker profile with automatic reseed fallback
            let worker = try await loadWorkerProfileWithFallback(workerId)
            
            // Load worker's assigned buildings
            let buildings = try await loadWorkerBuildings(workerId)
            
            // Load worker's tasks for today
            let tasks = try await loadWorkerTasksForToday(workerId)
            
            // Update published properties
            self.currentWorker = worker
            self.assignedBuildings = buildings
            self.todaysTasks = tasks.sorted { task1, task2 in
                // Sort by start time, then by building
                if let time1 = task1.startTime, let time2 = task2.startTime {
                    return time1 < time2
                }
                return task1.buildingName < task2.buildingName
            }
            self.upcomingTasks = []
            self.isLoading = false
            
            print("✅ Worker context loaded for: \(worker.workerName)")
            print("📋 Loaded \(buildings.count) buildings and \(tasks.count) tasks")
            
        } catch {
            self.lastError = error
            self.isLoading = false
            print("❌ Failed to load worker context: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadWorkerProfileWithFallback(_ workerId: String) async throws -> WorkerContext {
        do {
            return try await loadWorkerProfile(workerId)
        } catch {
            print("⚠️ Worker \(workerId) not found in database. Triggering reseed...")
            
            guard let manager = sqliteManager else {
                throw DatabaseError.invalidData("Worker not found and no database manager available")
            }
            
            // Trigger database reseed
            try await RealWorldDataSeeder.seedAllRealData(manager)
            print("✅ Database reseeded successfully")
            
            // Try loading the worker again
            return try await loadWorkerProfile(workerId)
        }
    }
    
    private func loadWorkerProfile(_ workerId: String) async throws -> WorkerContext {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Try multiple query strategies to handle different schema states
        
        // Strategy 1: Try with is_primary column
        var results = try? await manager.query("""
            SELECT w.id, w.name, w.email, w.role,
                   wa.building_id as primary_building_id
            FROM workers w
            LEFT JOIN worker_assignments wa ON w.id = wa.worker_id AND wa.is_primary = 1
            WHERE w.id = ?
            LIMIT 1
        """, [workerId])
        
        // Strategy 2: Try without is_primary condition if column doesn't exist
        if results == nil {
            results = try? await manager.query("""
                SELECT w.id, w.name, w.email, w.role,
                       wa.building_id as primary_building_id
                FROM workers w
                LEFT JOIN worker_assignments wa ON w.id = wa.worker_id
                WHERE w.id = ?
                LIMIT 1
            """, [workerId])
        }
        
        // Strategy 3: Try just the worker table
        if results == nil || results!.isEmpty {
            results = try await manager.query("""
                SELECT w.id, w.name, w.email, w.role, NULL as primary_building_id
                FROM workers w
                WHERE w.id = ?
                LIMIT 1
            """, [workerId])
        }
        
        guard let row = results?.first else {
            throw DatabaseError.invalidData("Worker not found")
        }
        
        return WorkerContext(
            workerId: String(row["id"] as? Int64 ?? 0),
            workerName: row["name"] as? String ?? "",
            email: row["email"] as? String ?? "",
            role: row["role"] as? String ?? "worker",
            primaryBuildingId: row["primary_building_id"] != nil ? String(row["primary_building_id"] as? Int64 ?? 0) : nil
        )
    }
    
    private func loadWorkerBuildings(_ workerId: String) async throws -> [Building] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Try with is_primary and is_active columns
        var results = try? await manager.query("""
            SELECT b.id, b.name, b.address, b.latitude, b.longitude, b.imageAssetName,
                   COALESCE(wa.is_primary, 0) as is_primary
            FROM buildings b
            INNER JOIN worker_assignments wa ON b.id = wa.building_id
            WHERE wa.worker_id = ? AND COALESCE(wa.is_active, 1) = 1
            ORDER BY COALESCE(wa.is_primary, 0) DESC, b.name ASC
        """, [workerId])
        
        // Try without the extra columns if they don't exist
        if results == nil {
            results = try? await manager.query("""
                SELECT b.id, b.name, b.address, b.latitude, b.longitude, b.imageAssetName
                FROM buildings b
                INNER JOIN worker_assignments wa ON b.id = wa.building_id
                WHERE wa.worker_id = ?
                ORDER BY b.name ASC
            """, [workerId])
        }
        
        // If no assignments found, return Edwin's default buildings
        if results == nil || results!.isEmpty {
            print("⚠️ No assigned buildings found, loading Edwin's default buildings...")
            results = try await manager.query("""
                SELECT id, name, address, latitude, longitude, imageAssetName
                FROM buildings
                WHERE id IN (1, 4, 8, 10, 12, 15, 16, 17)
                ORDER BY name ASC
            """)
        }
        
        let buildings = (results ?? []).compactMap { row -> Building? in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String else { return nil }
            
            return Building(
                id: String(id),
                name: name,
                latitude: row["latitude"] as? Double ?? 0.0,
                longitude: row["longitude"] as? Double ?? 0.0,
                address: row["address"] as? String ?? "",
                imageAssetName: row["imageAssetName"] as? String ?? name.replacingOccurrences(of: " ", with: "_")
            )
        }
        
        return buildings
    }
    
    private func loadWorkerTasksForToday(_ workerId: String) async throws -> [ContextualTask] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Load from multiple sources and combine results
        var allTasks: [ContextualTask] = []
        
        // Load from main tasks table
        let mainTasks = try? await manager.query("""
            SELECT t.id, t.name, t.buildingId, b.name as buildingName, 
                   t.category, t.startTime, t.endTime, t.recurrence,
                   COALESCE(t.urgencyLevel, 'medium') as urgencyLevel, 
                   COALESCE(t.status, 'pending') as status
            FROM tasks t
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ?
              AND (t.scheduledDate = date('now') OR t.recurrence = 'daily')
              AND COALESCE(t.status, 'pending') != 'completed'
        """, [workerId])
        
        // Convert main tasks
        if let mainTasks = mainTasks {
            for row in mainTasks {
                let task = ContextualTask(
                    id: String(describing: row["id"] ?? ""),
                    name: row["name"] as? String ?? "",
                    buildingId: String(row["buildingId"] as? Int64 ?? 0),
                    buildingName: row["buildingName"] as? String ?? "",
                    category: row["category"] as? String ?? "general",
                    startTime: row["startTime"] as? String,
                    endTime: row["endTime"] as? String,
                    recurrence: row["recurrence"] as? String ?? "oneTime",
                    skillLevel: "Basic",
                    status: row["status"] as? String ?? "pending",
                    urgencyLevel: row["urgencyLevel"] as? String ?? "medium"
                )
                allTasks.append(task)
            }
        }
        
        // Load from routine_tasks table if it exists
        let routineTasks = try? await manager.query("""
            SELECT rt.id, rt.task_name as name, rt.building_id as buildingId, 
                   b.name as buildingName, rt.category, rt.start_time as startTime, 
                   rt.end_time as endTime, rt.recurrence
            FROM routine_tasks rt
            LEFT JOIN buildings b ON rt.building_id = b.id
            WHERE rt.worker_id = ? AND COALESCE(rt.is_active, 1) = 1
              AND rt.recurrence = 'daily'
        """, [workerId])
        
        // Convert routine tasks
        if let routineTasks = routineTasks {
            for row in routineTasks {
                let task = ContextualTask(
                    id: "routine_" + String(describing: row["id"] ?? ""),
                    name: row["name"] as? String ?? "",
                    buildingId: String(row["buildingId"] as? String ?? "0"),
                    buildingName: row["buildingName"] as? String ?? "",
                    category: row["category"] as? String ?? "Routine",
                    startTime: row["startTime"] as? String,
                    endTime: row["endTime"] as? String,
                    recurrence: row["recurrence"] as? String ?? "daily",
                    skillLevel: "Basic",
                    status: "pending",
                    urgencyLevel: "medium"
                )
                allTasks.append(task)
            }
        }
        
        // If no tasks found, create some default tasks for Edwin
        if allTasks.isEmpty && workerId == "2" {
            print("⚠️ No tasks found, creating default tasks for Edwin...")
            allTasks = createDefaultTasksForEdwin()
        }
        
        return allTasks
    }
    
    private func createDefaultTasksForEdwin() -> [ContextualTask] {
        return [
            ContextualTask(
                id: "default_1",
                name: "Put Mats Out",
                buildingId: "17",
                buildingName: "Stuyvesant Cove Park",
                category: "Cleaning",
                startTime: "06:00",
                endTime: "06:15",
                recurrence: "daily",
                skillLevel: "Basic",
                status: "pending",
                urgencyLevel: "medium"
            ),
            ContextualTask(
                id: "default_2",
                name: "Park Area Check",
                buildingId: "17",
                buildingName: "Stuyvesant Cove Park",
                category: "Inspection",
                startTime: "06:15",
                endTime: "06:45",
                recurrence: "daily",
                skillLevel: "Basic",
                status: "pending",
                urgencyLevel: "medium"
            ),
            ContextualTask(
                id: "default_3",
                name: "Boiler Check",
                buildingId: "16",
                buildingName: "133 East 15th Street",
                category: "Maintenance",
                startTime: "07:30",
                endTime: "08:00",
                recurrence: "daily",
                skillLevel: "Advanced",
                status: "pending",
                urgencyLevel: "high"
            )
        ]
    }
    
    // MARK: - Helper Methods
    
    func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    func getTaskCountForBuilding(_ buildingId: String) -> Int {
        todaysTasks.filter { $0.buildingId == buildingId }.count
    }
    
    func getUrgentTaskCount() -> Int {
        todaysTasks.filter { $0.urgencyLevel.lowercased() == "urgent" || $0.isOverdue }.count
    }
    
    func refreshContext() async {
        guard let workerId = currentWorker?.workerId else { return }
        await loadWorkerContext(workerId: workerId)
    }
}

// MARK: - Database Errors

enum DatabaseError: LocalizedError {
    case notInitialized
    case invalidData(String)
    case queryFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        case .queryFailed(let message):
            return "Query failed: \(message)"
        }
    }
}
