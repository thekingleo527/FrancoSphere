//
//  UnifiedDataService.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/16/25.
//


//
//  UnifiedDataService.swift
//  FrancoSphere v6.0
//
//  ✅ SINGLE SOURCE OF TRUTH: All data flows through OperationalDataManager
//  ✅ NO CONFLICTS: Replaces all other data sources
//  ✅ REAL DATA: Uses actual operational tasks
//

import Foundation
import GRDB

@MainActor
public class UnifiedDataService: ObservableObject {
    public static let shared = UnifiedDataService()
    
    private let operationalData = OperationalDataManager.shared
    private let grdbManager = GRDBManager.shared
    
    // Cache for converted data
    private var contextualTaskCache: [String: [ContextualTask]] = [:]
    private var buildingCache: [String: NamedCoordinate] = [:]
    
    private init() {
        Task {
            await initializeData()
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize all data from OperationalDataManager
    public func initializeData() async {
        print("🚀 Initializing UnifiedDataService from OperationalDataManager...")
        
        // 1. Ensure database tables exist
        await createRequiredTables()
        
        // 2. Import operational data to database
        await importOperationalData()
        
        // 3. Build caches
        await buildCaches()
        
        print("✅ UnifiedDataService initialized with \(operationalData.realWorldTasks.count) tasks")
    }
    
    // MARK: - Database Setup
    
    private func createRequiredTables() async {
        do {
            // Create unified tasks table
            try await grdbManager.execute("""
                CREATE TABLE IF NOT EXISTS unified_tasks (
                    id TEXT PRIMARY KEY,
                    worker_id TEXT NOT NULL,
                    worker_name TEXT NOT NULL,
                    building_id TEXT NOT NULL,
                    building_name TEXT NOT NULL,
                    task_name TEXT NOT NULL,
                    description TEXT,
                    category TEXT NOT NULL,
                    skill_level TEXT NOT NULL,
                    start_time TEXT,
                    duration_minutes INTEGER DEFAULT 60,
                    is_completed INTEGER DEFAULT 0,
                    completed_date TEXT,
                    scheduled_date TEXT NOT NULL,
                    urgency TEXT DEFAULT 'medium',
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            // Create indexes for performance
            try await grdbManager.execute("""
                CREATE INDEX IF NOT EXISTS idx_unified_tasks_worker 
                ON unified_tasks(worker_id, scheduled_date)
            """)
            
            try await grdbManager.execute("""
                CREATE INDEX IF NOT EXISTS idx_unified_tasks_building 
                ON unified_tasks(building_id, scheduled_date)
            """)
            
            print("✅ Database tables created/verified")
            
        } catch {
            print("❌ Failed to create tables: \(error)")
        }
    }
    
    // MARK: - Import from OperationalDataManager
    
    private func importOperationalData() async {
        do {
            // Clear existing data
            try await grdbManager.execute("DELETE FROM unified_tasks")
            
            // Import each operational task
            for (index, opTask) in operationalData.realWorldTasks.enumerated() {
                let taskId = "op_task_\(index)"
                let workerId = getWorkerId(for: opTask.assignedWorker)
                let buildingId = getBuildingId(for: opTask.building)
                
                try await grdbManager.execute("""
                    INSERT INTO unified_tasks (
                        id, worker_id, worker_name, building_id, building_name,
                        task_name, description, category, skill_level, start_time,
                        duration_minutes, scheduled_date, urgency
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, date('now'), ?)
                """, [
                    taskId,
                    workerId,
                    opTask.assignedWorker,
                    buildingId,
                    opTask.building,
                    opTask.taskName,
                    opTask.taskDescription ?? "",
                    opTask.category,
                    opTask.skillLevel,
                    opTask.startTime ?? "09:00",
                    opTask.estimatedDuration,
                    mapUrgency(opTask.urgencyLevel)
                ])
            }
            
            print("✅ Imported \(operationalData.realWorldTasks.count) tasks from OperationalDataManager")
            
        } catch {
            print("❌ Failed to import operational data: \(error)")
        }
    }
    
    // MARK: - Public API (Replaces TaskService)
    
    /// Get all tasks from unified source
    public func getAllTasks() async -> [ContextualTask] {
        do {
            let rows = try await grdbManager.query("""
                SELECT * FROM unified_tasks
                ORDER BY scheduled_date, start_time
            """)
            
            return rows.compactMap { convertToContextualTask($0) }
            
        } catch {
            print("❌ Failed to get all tasks: \(error)")
            // Fallback to operational data
            return convertOperationalTasks(operationalData.realWorldTasks)
        }
    }
    
    /// Get tasks for specific worker
    public func getTasks(for workerId: String, date: Date = Date()) async -> [ContextualTask] {
        // Check cache first
        let cacheKey = "\(workerId)-\(date.timeIntervalSince1970)"
        if let cached = contextualTaskCache[cacheKey] {
            return cached
        }
        
        do {
            let dateString = ISO8601DateFormatter().string(from: date)
            let rows = try await grdbManager.query("""
                SELECT * FROM unified_tasks
                WHERE worker_id = ? AND DATE(scheduled_date) = DATE(?)
                ORDER BY start_time
            """, [workerId, dateString])
            
            let tasks = rows.compactMap { convertToContextualTask($0) }
            
            // Cache result
            contextualTaskCache[cacheKey] = tasks
            
            return tasks
            
        } catch {
            print("❌ Failed to get worker tasks: \(error)")
            // Fallback to operational data
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            let workerTasks = operationalData.realWorldTasks.filter { 
                $0.assignedWorker == workerName 
            }
            return convertOperationalTasks(workerTasks)
        }
    }
    
    /// Get tasks for specific building
    public func getTasksForBuilding(_ buildingId: String) async -> [ContextualTask] {
        do {
            let rows = try await grdbManager.query("""
                SELECT * FROM unified_tasks
                WHERE building_id = ? AND DATE(scheduled_date) = DATE('now')
                ORDER BY start_time
            """, [buildingId])
            
            return rows.compactMap { convertToContextualTask($0) }
            
        } catch {
            print("❌ Failed to get building tasks: \(error)")
            // Fallback
            let buildingName = getBuildingName(for: buildingId)
            let buildingTasks = operationalData.realWorldTasks.filter {
                $0.building == buildingName
            }
            return convertOperationalTasks(buildingTasks)
        }
    }
    
    /// Get task progress for worker
    public func getTaskProgress(for workerId: String) async -> TaskProgress {
        let tasks = await getTasks(for: workerId)
        let completedCount = tasks.filter { $0.isCompleted }.count
        let totalCount = tasks.count
        
        let progressPercentage = totalCount > 0 ? 
            Double(completedCount) / Double(totalCount) * 100 : 0
        
        // Count urgent tasks
        let urgentCount = tasks.filter { task in
            task.urgency == .high || task.urgency == .critical
        }.count
        
        return TaskProgress(
            totalTasks: totalCount,
            completedTasks: completedCount,
            remainingTasks: totalCount - completedCount,
            urgentTasks: urgentCount,
            progressPercentage: progressPercentage
        )
    }
    
    /// Get buildings for worker (from their tasks)
    public func getBuildingsForWorker(_ workerId: String) async -> [NamedCoordinate] {
        do {
            let rows = try await grdbManager.query("""
                SELECT DISTINCT building_id, building_name 
                FROM unified_tasks
                WHERE worker_id = ?
            """, [workerId])
            
            var buildings: [NamedCoordinate] = []
            
            for row in rows {
                if let buildingId = row["building_id"] as? String,
                   let buildingName = row["building_name"] as? String {
                    
                    if let building = await getBuilding(id: buildingId, name: buildingName) {
                        buildings.append(building)
                    }
                }
            }
            
            return buildings
            
        } catch {
            print("❌ Failed to get worker buildings: \(error)")
            return []
        }
    }
    
    // MARK: - Intelligence Support Methods
    
    /// Get metrics for intelligence generation
    public func getPortfolioMetrics() async -> PortfolioMetrics {
        do {
            // Overall completion rate
            let completionRows = try await grdbManager.query("""
                SELECT 
                    COUNT(*) as total,
                    SUM(CASE WHEN is_completed = 1 THEN 1 ELSE 0 END) as completed
                FROM unified_tasks
                WHERE DATE(scheduled_date) = DATE('now')
            """)
            
            let total = completionRows.first?["total"] as? Int64 ?? 0
            let completed = completionRows.first?["completed"] as? Int64 ?? 0
            let completionRate = total > 0 ? Double(completed) / Double(total) : 0
            
            // Overdue tasks
            let overdueRows = try await grdbManager.query("""
                SELECT COUNT(*) as count
                FROM unified_tasks
                WHERE is_completed = 0 
                AND datetime(scheduled_date || ' ' || start_time) < datetime('now')
            """)
            
            let overdueCount = overdueRows.first?["count"] as? Int64 ?? 0
            
            // Active workers
            let workerRows = try await grdbManager.query("""
                SELECT COUNT(DISTINCT worker_id) as count
                FROM unified_tasks
                WHERE DATE(scheduled_date) = DATE('now')
            """)
            
            let activeWorkers = workerRows.first?["count"] as? Int64 ?? 0
            
            return PortfolioMetrics(
                totalTasks: Int(total),
                completedTasks: Int(completed),
                completionRate: completionRate,
                overdueTasksCount: Int(overdueCount),
                activeWorkersCount: Int(activeWorkers)
            )
            
        } catch {
            print("❌ Failed to get portfolio metrics: \(error)")
            return PortfolioMetrics(
                totalTasks: 0,
                completedTasks: 0,
                completionRate: 0,
                overdueTasksCount: 0,
                activeWorkersCount: 0
            )
        }
    }
    
    // MARK: - Private Helpers
    
    private func convertToContextualTask(_ row: [String: Any]) -> ContextualTask? {
        guard let id = row["id"] as? String,
              let title = row["task_name"] as? String,
              let buildingId = row["building_id"] as? String,
              let buildingName = row["building_name"] as? String,
              let workerId = row["worker_id"] as? String,
              let workerName = row["worker_name"] as? String else {
            return nil
        }
        
        // Create building and worker objects
        let building = NamedCoordinate(
            id: buildingId,
            name: buildingName,
            latitude: 40.7589,  // Default NYC coords
            longitude: -73.9851
        )
        
        let worker = WorkerProfile(
            id: workerId,
            name: workerName,
            role: .worker,
            email: "\(workerId)@francosphere.com",
            phone: "",
            certifications: [],
            specializations: [],
            assignedBuildings: []
        )
        
        return ContextualTask(
            id: id,
            title: title,
            description: row["description"] as? String,
            buildingId: buildingId,
            buildingName: buildingName,
            category: TaskCategory(rawValue: row["category"] as? String ?? "") ?? .maintenance,
            urgency: TaskUrgency(rawValue: row["urgency"] as? String ?? "") ?? .medium,
            skillLevel: SkillLevel(rawValue: row["skill_level"] as? String ?? "") ?? .intermediate,
            estimatedDuration: 3600,  // 1 hour default
            isCompleted: (row["is_completed"] as? Int64 ?? 0) == 1,
            completedAt: nil,
            completedBy: nil,
            notes: nil,
            building: building,
            worker: worker
        )
    }
    
    private func convertOperationalTasks(_ tasks: [OperationalTask]) -> [ContextualTask] {
        return tasks.enumerated().map { index, opTask in
            let workerId = getWorkerId(for: opTask.assignedWorker)
            let buildingId = getBuildingId(for: opTask.building)
            
            let building = NamedCoordinate(
                id: buildingId,
                name: opTask.building,
                latitude: 40.7589,
                longitude: -73.9851
            )
            
            let worker = WorkerProfile(
                id: workerId,
                name: opTask.assignedWorker,
                role: .worker,
                email: "\(workerId)@francosphere.com",
                phone: "",
                certifications: [],
                specializations: [],
                assignedBuildings: []
            )
            
            return ContextualTask(
                id: "op_\(index)",
                title: opTask.taskName,
                description: opTask.taskDescription,
                buildingId: buildingId,
                buildingName: opTask.building,
                category: mapCategory(opTask.category),
                urgency: mapTaskUrgency(opTask.urgencyLevel),
                skillLevel: mapSkillLevel(opTask.skillLevel),
                estimatedDuration: TimeInterval(opTask.estimatedDuration * 60),
                isCompleted: false,
                completedAt: nil,
                completedBy: nil,
                notes: nil,
                building: building,
                worker: worker
            )
        }
    }
    
    private func buildCaches() async {
        // Pre-build building cache
        let buildingMappings: [(name: String, id: String)] = [
            ("Rubin Museum", "14"),
            ("12 West 18th Street", "1"),
            ("135-139 West 17th Street", "3"),
            ("131 Perry Street", "10"),
            ("41 Elizabeth Street", "7"),
            ("178 Spring Street", "17"),
            ("Stuyvesant Park", "16")
        ]
        
        for mapping in buildingMappings {
            buildingCache[mapping.name] = NamedCoordinate(
                id: mapping.id,
                name: mapping.name,
                latitude: 40.7589,
                longitude: -73.9851
            )
        }
    }
    
    private func getWorkerId(for name: String) -> String {
        return WorkerConstants.getWorkerId(name: name) ?? "unknown"
    }
    
    private func getBuildingId(for name: String) -> String {
        // Map building names to IDs
        let mappings: [String: String] = [
            "Rubin Museum": "14",
            "12 West 18th Street": "1",
            "135-139 West 17th Street": "3",
            "131 Perry Street": "10",
            "41 Elizabeth Street": "7",
            "178 Spring Street": "17",
            "Stuyvesant Park": "16",
            "136 West 17th Street": "13",
            "138 West 17th Street": "5",
            "117 West 17th Street": "9",
            "36 Walker Street": "11",
            "68 Perry Street": "6"
        ]
        
        return mappings[name] ?? "unknown"
    }
    
    private func getBuildingName(for id: String) -> String {
        // Reverse mapping
        let mappings: [String: String] = [
            "14": "Rubin Museum",
            "1": "12 West 18th Street",
            "3": "135-139 West 17th Street",
            "10": "131 Perry Street",
            "7": "41 Elizabeth Street",
            "17": "178 Spring Street",
            "16": "Stuyvesant Park"
        ]
        
        return mappings[id] ?? "Unknown Building"
    }
    
    private func getBuilding(id: String, name: String) async -> NamedCoordinate? {
        if let cached = buildingCache[name] {
            return cached
        }
        
        // Create new building
        let building = NamedCoordinate(
            id: id,
            name: name,
            latitude: 40.7589,
            longitude: -73.9851
        )
        
        buildingCache[name] = building
        return building
    }
    
    // MARK: - Mapping Functions
    
    private func mapCategory(_ category: String) -> TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "inspection": return .inspection
        case "security": return .security
        case "emergency": return .emergency
        case "sanitation": return .sanitation
        default: return .maintenance
        }
    }
    
    private func mapTaskUrgency(_ urgency: String) -> TaskUrgency {
        switch urgency.lowercased() {
        case "low": return .low
        case "medium": return .medium
        case "high": return .high
        case "critical", "emergency": return .critical
        default: return .medium
        }
    }
    
    private func mapSkillLevel(_ level: String) -> SkillLevel {
        switch level.lowercased() {
        case "basic": return .basic
        case "intermediate": return .intermediate
        case "advanced": return .advanced
        case "expert": return .expert
        default: return .intermediate
        }
    }
    
    private func mapUrgency(_ level: String) -> String {
        switch level.lowercased() {
        case "emergency": return "critical"
        default: return level.lowercased()
        }
    }
}

// MARK: - Supporting Types

public struct PortfolioMetrics {
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let overdueTasksCount: Int
    let activeWorkersCount: Int
}

// MARK: - WorkerConstants Extension

extension WorkerConstants {
    static func getWorkerId(name: String) -> String? {
        let nameToId: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Enrique Balam": "3",
            "Kevin Dutan": "4",
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn": "8"
        ]
        return nameToId[name]
    }
}