//
//  WorkerContextEngine.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

enum DatabaseError: LocalizedError {
    case notInitialized
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Database not initialized"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}
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
            // Use the shared singleton instead of start()
            sqliteManager = SQLiteManager.shared
            
            // Ensure database is ready
            if !SQLiteManager.shared.isDatabaseReady() {
                throw DatabaseError.notInitialized
            }
            
            // Load worker profile
            let worker = try await loadWorkerProfile(workerId)
            
            // Load worker's assigned buildings
            let buildings = try await loadWorkerBuildings(workerId)
            
            // Load worker's tasks for today
            let tasks = try await loadWorkerTasksForToday(workerId)
            
            // Load upcoming tasks (next 7 days)
            let upcoming = try await loadUpcomingTasks(workerId)
            
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
            self.upcomingTasks = upcoming
            self.isLoading = false
            
            print("✅ Worker context loaded for: \(worker.workerName)")
            
        } catch {
            self.lastError = error
            self.isLoading = false
            print("❌ Failed to load worker context: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func loadWorkerProfile(_ workerId: String) async throws -> WorkerContext {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        let results = try await manager.query("""
            SELECT w.id, w.name, w.email, w.role,
                   wa.building_id as primary_building_id
            FROM workers w
            LEFT JOIN worker_assignments wa ON w.id = wa.worker_id AND wa.is_primary = 1
            WHERE w.id = ?
            LIMIT 1
        """, [workerId])
        
        guard let row = results.first else {
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
        
        let results = try await manager.query("""
            SELECT b.id, b.name, b.address, b.latitude, b.longitude, b.imageAssetName,
                   wa.is_primary
            FROM buildings b
            INNER JOIN worker_assignments wa ON b.id = wa.building_id
            WHERE wa.worker_id = ? AND wa.is_active = 1
            ORDER BY wa.is_primary DESC, b.name ASC
        """, [workerId])
        
        let buildings = results.map { row -> Building? in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String else { return nil }
            
            // Building expects: id, name, latitude, longitude, address, imageAssetName
            return Building(
                id: String(id),
                name: name,
                latitude: row["latitude"] as? Double ?? 0.0,
                longitude: row["longitude"] as? Double ?? 0.0,
                address: row["address"] as? String ?? "",
                imageAssetName: row["imageAssetName"] as? String ?? name.replacingOccurrences(of: " ", with: "_")
            )
        }
        
        return buildings.compactMap { $0 }
    }
    
    private func loadWorkerTasksForToday(_ workerId: String) async throws -> [ContextualTask] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Load both regular tasks and routine tasks for today
        let results = try await manager.query("""
            SELECT t.id, t.name, t.buildingId, b.name as buildingName, 
                   t.category, t.startTime, t.endTime, t.recurrence,
                   t.urgencyLevel, t.status, 'Basic' as skillLevel
            FROM tasks t
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ? 
              AND (t.scheduledDate = date('now') OR t.recurrence = 'daily')
              AND t.status != 'completed'
            
            UNION ALL
            
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
            
            ORDER BY startTime ASC
        """, [workerId, workerId])
        
        return results.map { row in
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
    
    private func loadUpcomingTasks(_ workerId: String) async throws -> [ContextualTask] {
        guard let manager = sqliteManager else {
            throw DatabaseError.notInitialized
        }
        
        // Load tasks for the next 7 days
        let results = try await manager.query("""
            SELECT t.id, t.name, t.buildingId, b.name as buildingName, 
                   t.category, t.startTime, t.endTime, t.recurrence,
                   t.urgencyLevel, t.status, t.scheduledDate
            FROM tasks t
            LEFT JOIN buildings b ON t.buildingId = b.id
            WHERE t.workerId = ? 
              AND t.scheduledDate > date('now')
              AND t.scheduledDate <= date('now', '+7 days')
              AND t.status != 'completed'
            ORDER BY t.scheduledDate ASC, t.startTime ASC
            LIMIT 20
        """, [workerId])
        
        return results.map { row in
            ContextualTask(
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
        }
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
