// BuildingRepository.swift
// FrancoSphere v1.1 - Fixed version with proper async/await and error handling
// Converted to Actor pattern with async operations

import Foundation
import SwiftUI

// MARK: - Type Aliases

typealias FSBuilding = FrancoSphere.NamedCoordinate  // Using the correct type from FrancoSphereModels
typealias WorkerAssignmentRec = FrancoWorkerAssignment

// Import DatabaseError from SQLiteManager if it's in a separate module
// If DatabaseError is not accessible, we'll define a local error type
enum BuildingRepositoryError: LocalizedError {
    case databaseNotInitialized
    
    var errorDescription: String? {
        switch self {
        case .databaseNotInitialized:
            return "Database manager not initialized"
        }
    }
}

// MARK: - Building Repository Actor

/// Thread-safe central store for all building metadata and worker assignments
actor BuildingRepository {
    
    // MARK: - Singleton
    
    static let shared = BuildingRepository()
    
    // MARK: - Private State
    
    private let buildings: [FSBuilding]
    private var assignmentsCache: [String: [WorkerAssignmentRec]] = [:]
    private var routineTasksCache: [String: [String]] = [:]
    private var sqliteManager: SQLiteManager?
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with hardcoded data
        self.buildings = Self.createBuildings()
        
        // Initialize SQLite manager asynchronously
        Task {
            await self.initializeSQLiteManager()
        }
    }
    
    // Actor-isolated initialization method
    private func initializeSQLiteManager() async {
        do {
            self.sqliteManager = try await SQLiteManager.start()
            await self.loadAssignmentsFromDatabase()
            await self.loadRoutineTasksFromDatabase()
        } catch {
            print("❌ Failed to initialize SQLiteManager: \(error)")
        }
    }
    
    // MARK: - Public API (Async)
    
    /// Get all buildings
    public var allBuildings: [FSBuilding] {
        get async { buildings }
    }
    
    /// Get building by ID
    public func building(withId id: String) async -> FSBuilding? {
        buildings.first { $0.id == id }
    }
    
    /// Get building ID for name (case-insensitive)
    public func id(forName name: String) async -> String? {
        buildings.first {
            $0.name.compare(name, options: .caseInsensitive) == .orderedSame
        }?.id
    }
    
    /// Get building name for ID
    public func name(forId id: String) async -> String {
        buildings.first { $0.id == id }?.name ?? "Unknown Building"
    }
    
    /// Get first N buildings
    public func getFirstNBuildings(_ n: Int) async -> [FSBuilding] {
        Array(buildings.prefix(n))
    }
    
    /// Get worker assignments for building
    public func assignments(for buildingId: String) async -> [WorkerAssignmentRec] {
        // Check cache first
        if let cached = assignmentsCache[buildingId] {
            return cached
        }
        
        // Load from database if SQLiteManager is available
        if sqliteManager != nil,
           let dbAssignments = await loadAssignmentsFromDB(buildingId: buildingId) {
            assignmentsCache[buildingId] = dbAssignments
            return dbAssignments
        }
        
        // Fallback to hardcoded data
        let assignments = getHardcodedAssignments(for: buildingId)
        assignmentsCache[buildingId] = assignments
        return assignments
    }
    
    /// Get routine tasks for building
    public func routineTasks(for buildingId: String) async -> [String] {
        // Check cache first
        if let cached = routineTasksCache[buildingId] {
            return cached
        }
        
        // Load from database if SQLiteManager is available
        if sqliteManager != nil,
           let dbTasks = await loadRoutineTasksFromDB(buildingId: buildingId) {
            routineTasksCache[buildingId] = dbTasks
            return dbTasks
        }
        
        // Fallback to hardcoded data
        let tasks = getHardcodedRoutineTasks(for: buildingId)
        routineTasksCache[buildingId] = tasks
        return tasks
    }
    
    /// Search buildings by name or address
    public func searchBuildings(query: String) async -> [FSBuilding] {
        guard !query.isEmpty else { return buildings }
        
        let lowercasedQuery = query.lowercased()
        return buildings.filter { building in
            building.name.lowercased().contains(lowercasedQuery) ||
            (building.address?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    /// Get buildings within radius (in meters)
    public func buildings(within radius: Double, of coordinate: (lat: Double, lon: Double)) async -> [FSBuilding] {
        buildings.filter { building in
            let distance = haversineDistance(
                lat1: coordinate.lat, lon1: coordinate.lon,
                lat2: building.latitude, lon2: building.longitude
            )
            return distance <= radius
        }
    }
    
    /// Update worker assignment
    public func updateAssignment(
        buildingId: String,
        workerId: Int64,
        workerName: String,
        shift: String?,
        specialRole: String?
    ) async throws {
        var assignments = await self.assignments(for: buildingId)
        
        // Remove existing assignment for this worker if any
        assignments.removeAll { $0.workerId == workerId }
        
        // Add new assignment
        let newAssignment = WorkerAssignmentRec(
            buildingId: buildingId,
            workerId: workerId,
            workerName: workerName,
            shift: shift,
            specialRole: specialRole
        )
        assignments.append(newAssignment)
        
        // Update cache
        assignmentsCache[buildingId] = assignments
        
        // Persist to database if available
        if sqliteManager != nil {
            try await saveAssignmentToDB(newAssignment)
        }
    }
    
    /// Add routine task for building
    public func addRoutineTask(buildingId: String, task: String) async throws {
        var tasks = await self.routineTasks(for: buildingId)
        
        // Avoid duplicates
        guard !tasks.contains(task) else { return }
        
        tasks.append(task)
        routineTasksCache[buildingId] = tasks
        
        // Persist to database if available
        if sqliteManager != nil {
            try await saveRoutineTaskToDB(buildingId: buildingId, task: task)
        }
    }
    
    /// Legacy helper - use async version when possible
    nonisolated public func getBuildingName(forId id: String) -> String {
        // This is a temporary bridge for legacy code
        // Should migrate to async version
        let task = Task<String, Never> { @MainActor in
            await BuildingRepository.shared.name(forId: id)
        }
        return task.synchronousResult ?? "Unknown Building"
    }
    
    // MARK: - Legacy Extensions for Associated Buildings
    
    /// Get formatted string of assigned workers for a building ID
    public func getAssignedWorkersFormatted(for buildingId: String) async -> String {
        let assignments = await self.assignments(for: buildingId)
        if assignments.isEmpty {
            return "No assigned workers"
        }
        return assignments.map { $0.description }.joined(separator: ", ")
    }
    
    // MARK: - Private Methods
    
    private static func createBuildings() -> [FSBuilding] {
        [
            FSBuilding(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7390,
                longitude: -73.9930,
                address: "12 W 18th St, New York, NY",
                imageAssetName: "12_West_18th_Street"
            ),
            FSBuilding(
                id: "2",
                name: "29-31 East 20th Street",
                latitude: 40.7380,
                longitude: -73.9880,
                address: "29-31 E 20th St, New York, NY",
                imageAssetName: "29_31_East_20th_Street"
            ),
            FSBuilding(
                id: "3",
                name: "36 Walker Street",
                latitude: 40.7190,
                longitude: -74.0050,
                address: "36 Walker St, New York, NY",
                imageAssetName: "36_Walker_Street"
            ),
            FSBuilding(
                id: "4",
                name: "41 Elizabeth Street",
                latitude: 40.7170,
                longitude: -73.9970,
                address: "41 Elizabeth St, New York, NY",
                imageAssetName: "41_Elizabeth_Street"
            ),
            FSBuilding(
                id: "5",
                name: "68 Perry Street",
                latitude: 40.7350,
                longitude: -74.0050,
                address: "68 Perry St, New York, NY",
                imageAssetName: "68_Perry_Street"
            ),
            FSBuilding(
                id: "6",
                name: "104 Franklin Street",
                latitude: 40.7180,
                longitude: -74.0060,
                address: "104 Franklin St, New York, NY",
                imageAssetName: "104_Franklin_Street"
            ),
            FSBuilding(
                id: "7",
                name: "112 West 18th Street",
                latitude: 40.7400,
                longitude: -73.9940,
                address: "112 W 18th St, New York, NY",
                imageAssetName: "112_West_18th_Street"
            ),
            FSBuilding(
                id: "8",
                name: "117 West 17th Street",
                latitude: 40.7395,
                longitude: -73.9950,
                address: "117 W 17th St, New York, NY",
                imageAssetName: "117_West_17th_Street"
            ),
            FSBuilding(
                id: "9",
                name: "123 1st Avenue",
                latitude: 40.7270,
                longitude: -73.9850,
                address: "123 1st Ave, New York, NY",
                imageAssetName: "123_1st_Avenue"
            ),
            FSBuilding(
                id: "10",
                name: "131 Perry Street",
                latitude: 40.7340,
                longitude: -74.0060,
                address: "131 Perry St, New York, NY",
                imageAssetName: "131_Perry_Street"
            ),
            FSBuilding(
                id: "11",
                name: "133 East 15th Street",
                latitude: 40.7345,
                longitude: -73.9875,
                address: "133 E 15th St, New York, NY",
                imageAssetName: "133_East_15th_Street"
            ),
            FSBuilding(
                id: "12",
                name: "135-139 West 17th Street",
                latitude: 40.7400,
                longitude: -73.9960,
                address: "135-139 W 17th St, New York, NY",
                imageAssetName: "135West17thStreet"
            ),
            FSBuilding(
                id: "13",
                name: "136 West 17th Street",
                latitude: 40.7402,
                longitude: -73.9970,
                address: "136 W 17th St, New York, NY",
                imageAssetName: "136_West_17th_Street"
            ),
            FSBuilding(
                id: "14",
                name: "Rubin Museum (142-148 W 17th)",
                latitude: 40.7405,
                longitude: -73.9980,
                address: "142-148 W 17th St, New York, NY",
                imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
            ),
            FSBuilding(
                id: "15",
                name: "Stuyvesant Cove Park",
                latitude: 40.7318,
                longitude: -73.9740,
                address: "20 Waterside Plaza, New York, NY 10010",
                imageAssetName: "Stuyvesant_Cove_Park"
            ),
            FSBuilding(
                id: "16",
                name: "138 West 17th Street",
                latitude: 40.7399,
                longitude: -73.9965,
                address: "138 W 17th St, New York, NY",
                imageAssetName: "138West17thStreet"
            )
        ]
    }
    
    private func getHardcodedAssignments(for buildingId: String) -> [WorkerAssignmentRec] {
        switch buildingId {
        case "1":
            return [
                WorkerAssignmentRec(
                    buildingId: "1", workerId: 1, workerName: "Greg Hutson",
                    shift: "Day", specialRole: "Lead Maintenance"
                ),
                WorkerAssignmentRec(
                    buildingId: "1", workerId: 7, workerName: "Angel Guirachocha",
                    shift: "Day", specialRole: nil
                ),
                WorkerAssignmentRec(
                    buildingId: "1", workerId: 8, workerName: "Shawn Magloire",
                    shift: "Day", specialRole: nil
                )
            ]
        case "2":
            return [
                WorkerAssignmentRec(
                    buildingId: "2", workerId: 2, workerName: "Edwin Lema",
                    shift: "Day", specialRole: "Lead Cleaning"
                ),
                WorkerAssignmentRec(
                    buildingId: "2", workerId: 4, workerName: "Kevin Dutan",
                    shift: "Day", specialRole: nil
                )
            ]
        case "3":
            return [
                WorkerAssignmentRec(
                    buildingId: "3", workerId: 4, workerName: "Kevin Dutan",
                    shift: "Day", specialRole: nil
                ),
                WorkerAssignmentRec(
                    buildingId: "3", workerId: 7, workerName: "Angel Guirachocha",
                    shift: "Evening", specialRole: nil
                )
            ]
        case "4":
            return [
                WorkerAssignmentRec(
                    buildingId: "4", workerId: 5, workerName: "Carlos Mendez",
                    shift: "Day", specialRole: "Lead"
                )
            ]
        case "5":
            return [
                WorkerAssignmentRec(
                    buildingId: "5", workerId: 3, workerName: "Maria Rodriguez",
                    shift: "Day", specialRole: nil
                )
            ]
        case "6":
            return [
                WorkerAssignmentRec(
                    buildingId: "6", workerId: 2, workerName: "Edwin Lema",
                    shift: "Day", specialRole: nil
                )
            ]
        case "7", "8":
            return [
                WorkerAssignmentRec(
                    buildingId: buildingId, workerId: 1, workerName: "Greg Hutson",
                    shift: "Day", specialRole: nil
                )
            ]
        case "9":
            return [
                WorkerAssignmentRec(
                    buildingId: "9", workerId: 6, workerName: "James Wilson",
                    shift: "Day", specialRole: "Security"
                )
            ]
        case "10":
            return [
                WorkerAssignmentRec(
                    buildingId: "10", workerId: 3, workerName: "Maria Rodriguez",
                    shift: "Day", specialRole: nil
                ),
                WorkerAssignmentRec(
                    buildingId: "10", workerId: 7, workerName: "Angel Guirachocha",
                    shift: "Evening", specialRole: "Garbage"
                )
            ]
        case "11", "12", "13":
            return [
                WorkerAssignmentRec(
                    buildingId: buildingId, workerId: 2, workerName: "Edwin Lema",
                    shift: "Day", specialRole: nil
                )
            ]
        case "14":
            return [
                WorkerAssignmentRec(
                    buildingId: "14", workerId: 1, workerName: "Greg Hutson",
                    shift: "Day", specialRole: "Museum Specialist"
                ),
                WorkerAssignmentRec(
                    buildingId: "14", workerId: 5, workerName: "Carlos Mendez",
                    shift: "Evening", specialRole: nil
                )
            ]
        case "15":
            return [
                WorkerAssignmentRec(
                    buildingId: "15", workerId: 4, workerName: "Kevin Dutan",
                    shift: "Day", specialRole: "Park Maintenance"
                )
            ]
        case "16":
            return [
                WorkerAssignmentRec(
                    buildingId: "16", workerId: 4, workerName: "Kevin Dutan",
                    shift: "Day", specialRole: "Maintenance"
                )
            ]
        default:
            return [
                WorkerAssignmentRec(
                    buildingId: buildingId, workerId: 4, workerName: "Kevin Dutan",
                    shift: "On Call", specialRole: nil
                )
            ]
        }
    }
    
    private func getHardcodedRoutineTasks(for buildingId: String) -> [String] {
        switch buildingId {
        case "1":
            return [
                "HVAC Filter Replacement",
                "Lobby Cleaning",
                "Garbage Collection",
                "Security System Check",
                "Elevator Maintenance"
            ]
        case "2":
            return [
                "Hallway Sweeping",
                "Window Cleaning",
                "Elevator Maintenance",
                "Common Area Sanitizing",
                "Fire Alarm Testing"
            ]
        case "3":
            return [
                "HVAC Inspection",
                "Plumbing System Check",
                "Exterior Cleaning",
                "Pest Control",
                "Emergency Light Testing"
            ]
        case "4":
            return [
                "Roof Inspection",
                "Fire Safety Equipment Check",
                "Landscaping",
                "Utility Room Inspection",
                "Water Heater Maintenance"
            ]
        case "5":
            return [
                "Mailbox Area Cleaning",
                "Lighting Maintenance",
                "Front Door Maintenance",
                "Stairwell Cleaning",
                "Intercom System Check"
            ]
        case "14": // Museum special tasks
            return [
                "Climate Control Monitoring",
                "Security System Check",
                "Gallery Floor Maintenance",
                "Loading Dock Inspection",
                "Visitor Area Sanitization"
            ]
        case "15": // Park special tasks
            return [
                "Pathway Maintenance",
                "Trash Collection",
                "Landscaping",
                "Bench/Fixture Inspection",
                "Drainage System Check"
            ]
        default:
            return [
                "General Maintenance",
                "Cleaning",
                "Inspection",
                "Garbage Collection",
                "Security Check"
            ]
        }
    }
    
    // MARK: - Database Operations
    
    private func loadAssignmentsFromDatabase() async {
        guard let sqliteManager = sqliteManager else { return }
        
        // Pre-load all assignments at startup
        do {
            let sql = """
                SELECT building_id, worker_id, worker_name, shift, special_role
                FROM worker_assignments
                ORDER BY building_id, worker_id
            """
            
            let rows = try await sqliteManager.query(sql)
            
            var assignments: [String: [WorkerAssignmentRec]] = [:]
            
            for row in rows {
                guard let buildingId = row["building_id"] as? String,
                      let workerId = row["worker_id"] as? Int64,
                      let workerName = row["worker_name"] as? String else {
                    continue
                }
                
                let assignment = WorkerAssignmentRec(
                    buildingId: buildingId,
                    workerId: workerId,
                    workerName: workerName,
                    shift: row["shift"] as? String,
                    specialRole: row["special_role"] as? String
                )
                
                assignments[buildingId, default: []].append(assignment)
            }
            
            if !assignments.isEmpty {
                self.assignmentsCache = assignments
            }
        } catch {
            print("❌ Failed to load assignments from database: \(error)")
        }
    }
    
    private func loadAssignmentsFromDB(buildingId: String) async -> [WorkerAssignmentRec]? {
        guard let sqliteManager = sqliteManager else { return nil }
        
        do {
            let sql = """
                SELECT worker_id, worker_name, shift, special_role
                FROM worker_assignments
                WHERE building_id = ?
            """
            
            let rows = try await sqliteManager.query(sql, parameters: [buildingId])
            
            guard !rows.isEmpty else { return nil }
            
            return rows.compactMap { row in
                guard let workerId = row["worker_id"] as? Int64,
                      let workerName = row["worker_name"] as? String else {
                    return nil
                }
                
                return WorkerAssignmentRec(
                    buildingId: buildingId,
                    workerId: workerId,
                    workerName: workerName,
                    shift: row["shift"] as? String,
                    specialRole: row["special_role"] as? String
                )
            }
        } catch {
            print("❌ Failed to load assignments for building \(buildingId): \(error)")
            return nil
        }
    }
    
    private func loadRoutineTasksFromDatabase() async {
        guard let sqliteManager = sqliteManager else { return }
        
        do {
            let sql = """
                SELECT building_id, task_name
                FROM routine_tasks
                ORDER BY building_id, display_order
            """
            
            let rows = try await sqliteManager.query(sql)
            
            var tasks: [String: [String]] = [:]
            
            for row in rows {
                guard let buildingId = row["building_id"] as? String,
                      let taskName = row["task_name"] as? String else {
                    continue
                }
                
                tasks[buildingId, default: []].append(taskName)
            }
            
            if !tasks.isEmpty {
                self.routineTasksCache = tasks
            }
        } catch {
            print("❌ Failed to load routine tasks from database: \(error)")
        }
    }
    
    private func loadRoutineTasksFromDB(buildingId: String) async -> [String]? {
        guard let sqliteManager = sqliteManager else { return nil }
        
        do {
            let sql = """
                SELECT task_name
                FROM routine_tasks
                WHERE building_id = ?
                ORDER BY display_order
            """
            
            let rows = try await sqliteManager.query(sql, parameters: [buildingId])
            
            guard !rows.isEmpty else { return nil }
            
            return rows.compactMap { row in
                row["task_name"] as? String
            }
        } catch {
            print("❌ Failed to load routine tasks for building \(buildingId): \(error)")
            return nil
        }
    }
    
    private func saveAssignmentToDB(_ assignment: WorkerAssignmentRec) async throws {
        guard let sqliteManager = sqliteManager else {
            throw BuildingRepositoryError.databaseNotInitialized
        }
        
        let sql = """
            INSERT OR REPLACE INTO worker_assignments 
            (building_id, worker_id, worker_name, shift, special_role)
            VALUES (?, ?, ?, ?, ?)
        """
        
        try await sqliteManager.execute(sql, parameters: [
            assignment.buildingId,
            assignment.workerId,
            assignment.workerName,
            assignment.shift ?? NSNull(),
            assignment.specialRole ?? NSNull()
        ])
    }
    
    private func saveRoutineTaskToDB(buildingId: String, task: String) async throws {
        guard let sqliteManager = sqliteManager else {
            throw BuildingRepositoryError.databaseNotInitialized
        }
        
        // Get current max display order
        let orderSql = """
            SELECT COALESCE(MAX(display_order), 0) + 1 as next_order
            FROM routine_tasks
            WHERE building_id = ?
        """
        
        let rows = try await sqliteManager.query(orderSql, parameters: [buildingId])
        let nextOrder = rows.first?["next_order"] as? Int64 ?? 1
        
        // Insert new task
        let sql = """
            INSERT INTO routine_tasks (building_id, task_name, display_order)
            VALUES (?, ?, ?)
        """
        
        try await sqliteManager.execute(sql, parameters: [buildingId, task, nextOrder])
    }
    
    // MARK: - Utility Functions
    
    private func haversineDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let dLat = (lat2 - lat1) * .pi / 180
        let dLon = (lon2 - lon1) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return R * c
    }
}

// MARK: - Worker Assignment Record

struct FrancoWorkerAssignment: Identifiable {
    let id: String
    let buildingId: String
    let workerId: Int64
    let workerName: String
    let shift: String?
    let specialRole: String?
    
    init(buildingId: String, workerId: Int64, workerName: String, shift: String? = nil, specialRole: String? = nil) {
        self.id = UUID().uuidString
        self.buildingId = buildingId
        self.workerId = workerId
        self.workerName = workerName
        self.shift = shift
        self.specialRole = specialRole
    }
    
    var description: String {
        var out = workerName
        if let s = shift { out += " (\(s))" }
        if let r = specialRole { out += " – \(r)" }
        return out
    }
}

// MARK: - Task Extension for Sync Result

extension Task where Success: Sendable, Failure == Never {
    /// WARNING: This blocks the thread - use only for legacy compatibility
    var synchronousResult: Success? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: Success?
        
        let task = Task<Void, Never> {
            result = await self.value
            semaphore.signal()
        }
        
        semaphore.wait()
        _ = task // Prevent compiler warning
        return result
    }
}
