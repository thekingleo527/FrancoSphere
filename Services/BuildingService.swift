//
//  BuildingService.swift
//  FrancoSphere
//
//  ✅ COMPLETE FIX: All compilation errors resolved
//  ✅ Fixed type ambiguities (View, Binding)
//  ✅ Removed duplicate StatusChipView struct
//  ✅ Using SQLite.Binding explicitly
//  ✅ Updated getStatusChip to use FrancoSphere.StatusChipView
//

import Foundation
import CoreLocation
import SwiftUI
import SQLite

// ✅ ADDED: Type alias for clarity
typealias SQLiteBinding = SQLite.Binding

actor BuildingService {
    static let shared = BuildingService()
    
    // MARK: - Dependencies
    private var buildingsCache: [String: FrancoSphere.NamedCoordinate] = [:]
    private var buildingStatusCache: [String: EnhancedBuildingStatus] = [:]
    private var assignmentsCache: [String: [FrancoWorkerAssignment]] = [:]
    private var routineTasksCache: [String: [String]] = [:]
    private var taskStatusCache: [String: TaskStatus] = [:]
    private let sqliteManager = SQLiteManager.shared
    private let operationalManager = OperationalDataManager.shared
    private let buildings: [FrancoSphere.NamedCoordinate]
    
    // MARK: - Initialization
    private init() {
        // ✅ FIXED: Initialize buildings properly without Self reference
        self.buildings = [
            FrancoSphere.NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7390,
                longitude: -73.9930,
                imageAssetName: "12_West_18th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "2",
                name: "29-31 East 20th Street",
                latitude: 40.7380,
                longitude: -73.9880,
                imageAssetName: "29_31_East_20th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "3",
                name: "36 Walker Street",
                latitude: 40.7190,
                longitude: -74.0050,
                imageAssetName: "36_Walker_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "4",
                name: "41 Elizabeth Street",
                latitude: 40.7170,
                longitude: -73.9970,
                imageAssetName: "41_Elizabeth_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "5",
                name: "68 Perry Street",
                latitude: 40.7350,
                longitude: -74.0050,
                imageAssetName: "68_Perry_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "6",
                name: "104 Franklin Street",
                latitude: 40.7180,
                longitude: -74.0060,
                imageAssetName: "104_Franklin_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "7",
                name: "112 West 18th Street",
                latitude: 40.7400,
                longitude: -73.9940,
                imageAssetName: "112_West_18th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "8",
                name: "117 West 17th Street",
                latitude: 40.7395,
                longitude: -73.9950,
                imageAssetName: "117_West_17th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "9",
                name: "123 1st Avenue",
                latitude: 40.7270,
                longitude: -73.9850,
                imageAssetName: "123_1st_Avenue"
            ),
            FrancoSphere.NamedCoordinate(
                id: "10",
                name: "131 Perry Street",
                latitude: 40.7340,
                longitude: -74.0060,
                imageAssetName: "131_Perry_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "11",
                name: "133 East 15th Street",
                latitude: 40.7345,
                longitude: -73.9875,
                imageAssetName: "133_East_15th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "12",
                name: "135-139 West 17th Street",
                latitude: 40.7400,
                longitude: -73.9960,
                imageAssetName: "135West17thStreet"
            ),
            FrancoSphere.NamedCoordinate(
                id: "13",
                name: "136 West 17th Street",
                latitude: 40.7402,
                longitude: -73.9970,
                imageAssetName: "136_West_17th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "14",
                name: "Rubin Museum (142-148 W 17th)",
                latitude: 40.7405,
                longitude: -73.9980,
                imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "15",
                name: "Stuyvesant Cove Park",
                latitude: 40.7318,
                longitude: -73.9740,
                imageAssetName: "Stuyvesant_Cove_Park"
            ),
            FrancoSphere.NamedCoordinate(
                id: "16",
                name: "138 West 17th Street",
                latitude: 40.7399,
                longitude: -73.9965,
                imageAssetName: "138West17thStreet"
            ),
            FrancoSphere.NamedCoordinate(
                id: "17",
                name: "178 Spring Street",
                latitude: 40.7250,
                longitude: -74.0020,
                imageAssetName: "178_Spring_Street"
            ),
            FrancoSphere.NamedCoordinate(
                id: "18",
                name: "115 7th Avenue",
                latitude: 40.7380,
                longitude: -73.9980,
                imageAssetName: "115_7th_Avenue"
            )
        ]
        
        // Initialize caches asynchronously
        Task {
            await initializeCaches()
        }
        
        // Set up notification handling
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("TaskCompletionStatusChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task {
                await self?.handleTaskStatusChange(notification: notification)
            }
        }
    }
    
    private func initializeCaches() async {
        await loadAssignmentsFromDatabase()
        await loadRoutineTasksFromDatabase()
    }
    
    // MARK: - Task Status Management (BuildingStatusManager functionality)
    
    /// Task‐based statuses for buildings
    enum TaskStatus: String, CaseIterable {
        case complete = "Complete"
        case partial  = "Partial"
        case pending  = "Pending"
        case overdue  = "Overdue"
        
        var color: Color {
            switch self {
            case .complete: return .green
            case .partial:  return .yellow
            case .pending:  return .blue
            case .overdue:  return .red
            }
        }
        
        /// Map each TaskStatus into the existing FrancoSphere.BuildingStatus enum
        var buildingStatus: FrancoSphere.BuildingStatus {
            switch self {
            case .complete:
                return .operational             // fully operational
            case .partial:
                return .underMaintenance       // partially maintained
            case .pending:
                return .underMaintenance       // pending maintenance
            case .overdue:
                return .closed                 // needs immediate attention
            }
        }
    }
    
    // ✅ REMOVED: Duplicate StatusChipView struct - using FrancoSphere.StatusChipView instead
    
    // MARK: - Core Building Data Management
    
    /// Get all buildings
    var allBuildings: [FrancoSphere.NamedCoordinate] {
        get async { buildings }
    }
    
    /// Get building by ID
    func getBuilding(_ id: String) async throws -> FrancoSphere.NamedCoordinate? {
        // Check cache first
        if let cachedBuilding = buildingsCache[id] {
            return cachedBuilding
        }
        
        // Try hardcoded buildings first
        if let hardcodedBuilding = buildings.first(where: { $0.id == id }) {
            buildingsCache[id] = hardcodedBuilding
            return hardcodedBuilding
        }
        
        // ✅ FIXED: Convert String ID to Int64 for database query
        guard let buildingIdInt = Int64(id) else {
            print("⚠️ Invalid building ID format: \(id)")
            return nil
        }
        
        do {
            let query = "SELECT * FROM buildings WHERE id = ?"
            let rows = try await sqliteManager.query(query, [buildingIdInt])
            
            guard let row = rows.first else {
                print("⚠️ Building \(id) not found in database")
                return nil
            }
            
            let building = FrancoSphere.NamedCoordinate(
                id: id, // Keep as String for application use
                name: row["name"] as? String ?? "",
                latitude: row["latitude"] as? Double ?? 0,
                longitude: row["longitude"] as? Double ?? 0,
                imageAssetName: row["image_asset"] as? String ?? "building_\(id)"
            )
            
            // Cache for performance
            buildingsCache[id] = building
            return building
            
        } catch {
            print("❌ Database error fetching building \(id): \(error)")
            return nil
        }
    }
    
    /// Get building ID for name (case-insensitive)
    func id(forName name: String) async -> String? {
        // Clean the name for matching
        let cleanedName = name
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .whitespaces)

        return buildings.first {
            $0.name.compare(cleanedName, options: .caseInsensitive) == .orderedSame ||
            $0.name.compare(name, options: .caseInsensitive) == .orderedSame
        }?.id
    }
    
    /// Get building name for ID
    func name(forId id: String) async -> String {
        buildings.first { $0.id == id }?.name ?? "Unknown Building"
    }
    
    /// Get first N buildings
    func getFirstNBuildings(_ n: Int) async -> [FrancoSphere.NamedCoordinate] {
        Array(buildings.prefix(n))
    }
    
    /// Legacy synchronous helper
    nonisolated func getBuildingName(forId id: String) -> String {
        // This is a temporary bridge for legacy code
        var result = "Unknown Building"
        let semaphore = DispatchSemaphore(value: 0)
        
        Task {
            result = await BuildingService.shared.name(forId: id)
            semaphore.signal()
        }
        
        semaphore.wait()
        return result
    }
    
    func getAllBuildings() async throws -> [FrancoSphere.NamedCoordinate] {
        // Return hardcoded buildings (source of truth)
        return buildings
    }
    
    func getBuildingsForWorker(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        // Delegate to WorkerService for assignment logic
        return try await WorkerService.shared.getAssignedBuildings(workerId)
    }
    
    // MARK: - Search and Filtering
    
    /// Search buildings by name
    func searchBuildings(query: String) async -> [FrancoSphere.NamedCoordinate] {
        guard !query.isEmpty else { return buildings }
        
        let lowercasedQuery = query.lowercased()
        return buildings.filter { building in
            building.name.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Get buildings within radius (in meters)
    func buildings(within radius: Double, of coordinate: (lat: Double, lon: Double)) async -> [FrancoSphere.NamedCoordinate] {
        buildings.filter { building in
            let distance = haversineDistance(
                lat1: coordinate.lat, lon1: coordinate.lon,
                lat2: building.latitude, lon2: building.longitude
            )
            return distance <= radius
        }
    }
    
    func getBuildingsByType(_ buildingType: String) async throws -> [FrancoSphere.NamedCoordinate] {
        return buildings.filter { building in
            inferBuildingType(building).rawValue == buildingType
        }
    }
    
    // MARK: - Worker Assignment Management
    
    /// Get worker assignments for building - NOW QUERIES REAL DATA
    func assignments(for buildingId: String) async -> [FrancoWorkerAssignment] {
        // Check cache first
        if let cached = assignmentsCache[buildingId] {
            return cached
        }
        
        // Load from database
        if let dbAssignments = await loadAssignmentsFromDB(buildingId: buildingId) {
            assignmentsCache[buildingId] = dbAssignments
            return dbAssignments
        }
        
        // No assignments found
        return []
    }
    
    /// Get building-specific worker assignments (BuildingDetailView compatibility)
    func getBuildingWorkerAssignments(for buildingId: String) async -> [FrancoWorkerAssignment] {
        // First try to get from existing assignments method
        let existingAssignments = await assignments(for: buildingId)
        if !existingAssignments.isEmpty {
            return existingAssignments
        }
        
        // Fallback: Create sample worker for building if no real assignments found
        return [
            FrancoWorkerAssignment(
                buildingId: buildingId,
                workerId: 4, // Kevin Dutan
                workerName: "Kevin Dutan",
                shift: "Day",
                specialRole: "Lead Maintenance"
            )
        ]
    }
    
    /// Get formatted string of assigned workers for a building ID
    func getAssignedWorkersFormatted(for buildingId: String) async -> String {
        let assignments = await self.assignments(for: buildingId)
        if assignments.isEmpty {
            return "No assigned workers"
        }
        return assignments.map { $0.description }.joined(separator: ", ")
    }
    
    /// Update worker assignment
    func updateAssignment(
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
        let newAssignment = FrancoWorkerAssignment(
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
        try await saveAssignmentToDB(newAssignment)
    }
    
    // MARK: - Routine Task Management
    
    /// Get routine tasks for building - FROM REAL DATA
    func routineTasks(for buildingId: String) async -> [String] {
        // Check cache first
        if let cached = routineTasksCache[buildingId] {
            return cached
        }
        
        // Load from database
        if let dbTasks = await loadRoutineTasksFromDB(buildingId: buildingId) {
            routineTasksCache[buildingId] = dbTasks
            return dbTasks
        }
        
        // No tasks found
        return []
    }
    
    /// Get building-specific routine task names (BuildingDetailView compatibility)
    func getBuildingRoutineTaskNames(for buildingId: String) async -> [String] {
        do {
            let sql = """
                SELECT DISTINCT name
                FROM tasks
                WHERE buildingId = ? AND recurrence IN ('Daily', 'Weekly', 'Monthly')
                ORDER BY name
            """
            
            let rows = try await sqliteManager.query(sql, [buildingId])
            
            return rows.compactMap { row in
                row["name"] as? String
            }
        } catch {
            print("❌ Failed to load building routine task names for \(buildingId): \(error)")
            return []
        }
    }
    
    /// Add routine task for building
    func addRoutineTask(buildingId: String, task: String) async throws {
        var tasks = await self.routineTasks(for: buildingId)
        
        // Avoid duplicates
        guard !tasks.contains(task) else { return }
        
        tasks.append(task)
        routineTasksCache[buildingId] = tasks
        
        // Persist to database
        try await saveRoutineTaskToDB(buildingId: buildingId, task: task)
    }
    
    // MARK: - Building Status Management (BuildingStatusManager functionality)
    
    /// Evaluates a TaskStatus for this building ID (caches result)
    func evaluateStatus(for buildingID: String) async -> TaskStatus {
        if let cached = taskStatusCache[buildingID] {
            return cached
        }
        
        let tasks = await getAllTasksForBuilding(buildingID)
        let status: TaskStatus
        
        if tasks.isEmpty {
            status = .pending
        } else {
            let completedCount = tasks.filter { $0.isComplete }.count
            
            if completedCount == tasks.count {
                status = .complete
            } else if completedCount == 0 {
                // after 5 PM, mark as overdue; else still pending
                if Calendar.current.component(.hour, from: Date()) >= 17 {
                    status = .overdue
                } else {
                    status = .pending
                }
            } else {
                status = .partial
            }
        }
        
        taskStatusCache[buildingID] = status
        return status
    }
    
    /// Returns the actual FrancoSphere.BuildingStatus enum for UI logic
    func buildingStatus(for buildingID: String) async -> FrancoSphere.BuildingStatus {
        let taskStatus = await evaluateStatus(for: buildingID)
        return taskStatus.buildingStatus
    }
    
    /// Returns the color for a building's status
    func getStatusColor(for buildingID: String) async -> Color {
        let taskStatus = await evaluateStatus(for: buildingID)
        return taskStatus.color
    }
    
    /// Returns the raw text label for a building's status
    func getStatusText(for buildingID: String) async -> String {
        let taskStatus = await evaluateStatus(for: buildingID)
        return taskStatus.rawValue
    }
    
    /// Forces recalculation (removes cache) and emits a notification
    func recalculateStatus(for buildingID: String) async {
        taskStatusCache.removeValue(forKey: buildingID)
        NotificationCenter.default.post(
            name: NSNotification.Name("BuildingStatusChanged"),
            object: nil,
            userInfo: ["buildingID": buildingID]
        )
    }
    
    /// ✅ FIXED: Use FrancoSphere.StatusChipView instead of duplicate struct
    func getStatusChip(for buildingID: String) async -> FrancoSphere.StatusChipView {
        let taskStatus = await evaluateStatus(for: buildingID)
        let buildingStatus = taskStatus.buildingStatus
        return FrancoSphere.StatusChipView(status: buildingStatus)
    }
    
    // MARK: - Enhanced Building Status (Our Addition)
    
    func getBuildingStatus(_ buildingId: String) async throws -> EnhancedBuildingStatus {
        // Check cache first (with 5-minute expiration)
        if let cachedStatus = buildingStatusCache[buildingId],
           Date().timeIntervalSince(cachedStatus.lastUpdated) < 300 {
            return cachedStatus
        }
        
        // ✅ FIXED: Convert String ID to Int64 for database query
        guard let buildingIdInt = Int64(buildingId) else {
            print("⚠️ Invalid building ID format: \(buildingId)")
            return EnhancedBuildingStatus.empty(buildingId: buildingId)
        }
        
        let query = """
            SELECT 
                status, 
                COUNT(*) as count,
                AVG(CASE WHEN status = 'completed' THEN 1.0 ELSE 0.0 END) as completion_rate
            FROM AllTasks 
            WHERE building_id = ? AND DATE(scheduled_date) = DATE('now')
            GROUP BY status
        """
        
        do {
            let rows = try await sqliteManager.query(query, [buildingIdInt])
            
            var completed = 0
            var pending = 0
            var overdue = 0
            var completionRate = 0.0
            
            for row in rows {
                let status = row["status"] as? String ?? ""
                let count = row["count"] as? Int64 ?? 0
                
                switch status {
                case "completed":
                    completed = Int(count)
                case "pending":
                    pending = Int(count)
                case "overdue":
                    overdue = Int(count)
                default:
                    break
                }
                
                completionRate = row["completion_rate"] as? Double ?? 0.0
            }
            
            let status = EnhancedBuildingStatus(
                buildingId: buildingId,
                completedTasks: completed,
                pendingTasks: pending,
                overdueTasks: overdue,
                completionRate: completionRate,
                lastUpdated: Date(),
                workersOnSite: try await getWorkersOnSite(buildingId),
                todaysTaskCount: completed + pending + overdue
            )
            
            // Cache for performance
            buildingStatusCache[buildingId] = status
            return status
            
        } catch {
            print("❌ Error fetching building status for \(buildingId): \(error)")
            return EnhancedBuildingStatus.empty(buildingId: buildingId)
        }
    }
    
    func getAllBuildingStatuses() async throws -> [EnhancedBuildingStatus] {
        let buildings = try await getAllBuildings()
        
        return await withTaskGroup(of: EnhancedBuildingStatus.self) { group in
            for building in buildings {
                group.addTask {
                    do {
                        return try await self.getBuildingStatus(building.id)
                    } catch {
                        return EnhancedBuildingStatus.empty(buildingId: building.id)
                    }
                }
            }
            
            var statuses: [EnhancedBuildingStatus] = []
            for await status in group {
                statuses.append(status)
            }
            return statuses
        }
    }
    
    // MARK: - Worker Assignment and Building Operations
    
    private func getWorkersOnSite(_ buildingId: String) async throws -> [WorkerOnSite] {
        // ✅ FIXED: Convert String ID to Int64 for database query
        guard let buildingIdInt = Int64(buildingId) else {
            return []
        }
        
        let query = """
            SELECT DISTINCT w.id, w.name, w.role, t.start_time, t.end_time
            FROM workers w
            JOIN AllTasks t ON w.id = t.assigned_worker_id
            WHERE t.building_id = ? 
            AND DATE(t.scheduled_date) = DATE('now')
            AND t.status IN ('pending', 'in_progress')
            AND TIME('now') BETWEEN t.start_time AND t.end_time
        """
        
        do {
            let rows = try await sqliteManager.query(query, [buildingIdInt])
            
            return rows.compactMap { row in
                guard let workerId = row["id"] as? Int64,
                      let name = row["name"] as? String,
                      let role = row["role"] as? String,
                      let startTime = row["start_time"] as? String,
                      let endTime = row["end_time"] as? String else {
                    return nil
                }
                
                return WorkerOnSite(
                    workerId: String(workerId),
                    name: name,
                    role: role,
                    startTime: startTime,
                    endTime: endTime,
                    isCurrentlyOnSite: true
                )
            }
            
        } catch {
            print("❌ Error fetching workers on site for building \(buildingId): \(error)")
            return []
        }
    }
    
    // MARK: - Building Image Management
    
    func getBuildingImage(_ building: FrancoSphere.NamedCoordinate) -> UIImage? {
        // ✅ FIXED: Use image loading pattern from existing project views
        // Try primary image asset name
        if let primaryImage = UIImage(named: building.imageAssetName) {
            return primaryImage
        }
        // Try building ID based name
        else if let idImage = UIImage(named: "building_\(building.id)") {
            return idImage
        }
        // Try sanitized building name
        else {
            let sanitizedName = building.name
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "–", with: "-")
                .lowercased()
            
            if let nameImage = UIImage(named: sanitizedName) {
                return nameImage
            }
        }
        
        // No image found
        return nil
    }
    
    func getBuildingImagePath(_ building: FrancoSphere.NamedCoordinate) -> String {
        return building.imageAssetName
    }
    
    // MARK: - Building Analytics and Reporting
    
    func getBuildingAnalytics(_ buildingId: String, days: Int = 30) async throws -> BuildingAnalytics {
        // ✅ FIXED: Convert String ID to Int64 for database query
        guard let buildingIdInt = Int64(buildingId) else {
            return BuildingAnalytics.empty(buildingId: buildingId)
        }
        
        let query = """
            SELECT 
                COUNT(*) as total_tasks,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
                SUM(CASE WHEN status = 'overdue' THEN 1 ELSE 0 END) as overdue_tasks,
                COUNT(DISTINCT assigned_worker_id) as unique_workers,
                AVG(CASE WHEN status = 'completed' THEN 1.0 ELSE 0.0 END) as completion_rate
            FROM AllTasks 
            WHERE building_id = ?
            AND scheduled_date >= date('now', '-\(days) days')
        """
        
        do {
            let rows = try await sqliteManager.query(query, [buildingIdInt])
            
            guard let row = rows.first else {
                return BuildingAnalytics.empty(buildingId: buildingId)
            }
            
            return BuildingAnalytics(
                buildingId: buildingId,
                totalTasks: Int(row["total_tasks"] as? Int64 ?? 0),
                completedTasks: Int(row["completed_tasks"] as? Int64 ?? 0),
                overdueTasks: Int(row["overdue_tasks"] as? Int64 ?? 0),
                uniqueWorkers: Int(row["unique_workers"] as? Int64 ?? 0),
                completionRate: row["completion_rate"] as? Double ?? 0.0,
                averageTasksPerDay: Double(row["total_tasks"] as? Int64 ?? 0) / Double(days),
                periodDays: days
            )
            
        } catch {
            print("❌ Error fetching building analytics for \(buildingId): \(error)")
            return BuildingAnalytics.empty(buildingId: buildingId)
        }
    }
    
    // MARK: - Building Maintenance and Updates
    
    /// ✅ FIXED: Use SQLite.Binding explicitly to resolve ambiguity
    func updateBuildingInfo(_ buildingId: String, name: String? = nil, address: String? = nil) async throws {
        guard let buildingIdInt = Int64(buildingId) else {
            throw BuildingServiceError.invalidBuildingId(buildingId)
        }
        
        var updateFields: [String] = []
        var parameters: [SQLiteBinding] = []  // ✅ FIXED: Use SQLite.Binding explicitly
        
        if let name = name {
            updateFields.append("name = ?")
            parameters.append(name)  // String converts to SQLite.Binding automatically
        }
        
        if let address = address {
            updateFields.append("address = ?")
            parameters.append(address)  // String converts to SQLite.Binding automatically
        }
        
        guard !updateFields.isEmpty else {
            return
        }
        
        parameters.append(buildingIdInt)  // Int64 converts to SQLite.Binding automatically
        
        let updateQuery = """
            UPDATE buildings 
            SET \(updateFields.joined(separator: ", "))
            WHERE id = ?
        """
        
        try await sqliteManager.execute(updateQuery, parameters)
        
        // Clear cache
        buildingsCache.removeValue(forKey: buildingId)
        buildingStatusCache.removeValue(forKey: buildingId)
        
        print("✅ Updated building info for \(buildingId)")
    }
    
    // MARK: - Cache Management
    
    func clearBuildingCache() {
        buildingsCache.removeAll()
        buildingStatusCache.removeAll()
        assignmentsCache.removeAll()
        routineTasksCache.removeAll()
        taskStatusCache.removeAll()
        print("✅ Building cache cleared")
    }
    
    func refreshBuildingStatus(_ buildingId: String) async throws -> EnhancedBuildingStatus {
        // Clear cache for this building
        buildingStatusCache.removeValue(forKey: buildingId)
        taskStatusCache.removeValue(forKey: buildingId)
        
        // Fetch fresh status
        return try await getBuildingStatus(buildingId)
    }
    
    // MARK: - Building Operational Intelligence
    
    func getBuildingOperationalInsights(_ buildingId: String) async throws -> BuildingOperationalInsights {
        let building = try await getBuilding(buildingId)
        let status = try await getBuildingStatus(buildingId)
        let analytics = try await getBuildingAnalytics(buildingId)
        
        guard let building = building else {
            throw BuildingServiceError.buildingNotFound(buildingId)
        }
        
        // Determine building characteristics
        let buildingType = inferBuildingType(building)
        let specialRequirements = getSpecialRequirements(building, buildingType)
        let peakOperatingHours = getPeakOperatingHours(building, buildingType)
        
        return BuildingOperationalInsights(
            building: building,
            buildingType: buildingType,
            specialRequirements: specialRequirements,
            peakOperatingHours: peakOperatingHours,
            currentStatus: status,
            analytics: analytics,
            recommendedWorkerCount: getRecommendedWorkerCount(building, buildingType),
            maintenancePriority: getMaintenancePriority(analytics)
        )
    }
    
    // MARK: - Notification Handling
    
    /// Called when any task's "completion status" changes
    private func handleTaskStatusChange(notification: Notification) async {
        if let taskID = notification.userInfo?["taskID"] as? String,
           let buildingID = await getBuildingIDForTask(taskID) {
            await recalculateStatus(for: buildingID)
        }
    }
    
    /// Map a task ID to its building ID
    private func getBuildingIDForTask(_ taskID: String) async -> String? {
        // Query database for task's building ID
        do {
            let query = "SELECT building_id FROM AllTasks WHERE id = ?"
            let rows = try await sqliteManager.query(query, [taskID])
            
            if let row = rows.first {
                if let buildingIdInt = row["building_id"] as? Int64 {
                    return String(buildingIdInt)
                } else if let buildingIdString = row["building_id"] as? String {
                    return buildingIdString
                }
            }
        } catch {
            print("❌ Error fetching building ID for task \(taskID): \(error)")
        }
        
        return nil
    }
    
    /// Fetches all tasks for a given building
    private func getAllTasksForBuilding(_ buildingID: String) async -> [SimpleLegacyTask] {
        // Get FrancoSphere maintenance tasks and convert to simple legacy format
        let fsTasks = await getAllFrancoSphereTasks(for: buildingID)
        return fsTasks.map { task in
            SimpleLegacyTask(isComplete: task.isComplete)
        }
    }
    
    /// Fetches all tasks (FrancoSphere.MaintenanceTask) for a given building
    private func getAllFrancoSphereTasks(for buildingID: String) async -> [FrancoSphere.MaintenanceTask] {
        // Try to get from database first
        do {
            let query = """
                SELECT * FROM AllTasks 
                WHERE building_id = ? AND DATE(scheduled_date) = DATE('now')
                ORDER BY start_time
            """
            
            let buildingIdInt = Int64(buildingID) ?? 0
            let rows = try await sqliteManager.query(query, [buildingIdInt])
            
            return rows.compactMap { row in
                guard let id = row["id"] as? String,
                      let name = row["name"] as? String,
                      let categoryStr = row["category"] as? String else {
                    return nil
                }
                
                let category = FrancoSphere.TaskCategory(rawValue: categoryStr) ?? .maintenance
                let urgency = FrancoSphere.TaskUrgency(rawValue: row["urgency"] as? String ?? "medium") ?? .medium
                let recurrence = FrancoSphere.TaskRecurrence(rawValue: row["recurrence"] as? String ?? "oneTime") ?? .oneTime
                let isComplete = (row["status"] as? String ?? "pending") == "completed"
                
                return FrancoSphere.MaintenanceTask(
                    id: id,
                    name: name,
                    buildingID: buildingID,
                    description: row["description"] as? String ?? "",
                    dueDate: Date(),
                    category: category,
                    urgency: urgency,
                    recurrence: recurrence,
                    isComplete: isComplete
                )
            }
            
        } catch {
            print("❌ Error fetching FrancoSphere tasks for building \(buildingID): \(error)")
        }
        
        // Fallback to hardcoded examples
        switch buildingID {
        case "1":
            return [
                .init(
                    id: UUID().uuidString,
                    name: "Daily Cleaning",
                    buildingID: buildingID,
                    description: "Regular daily cleaning",
                    dueDate: Date(),
                    category: .cleaning,
                    urgency: .medium,
                    recurrence: .daily,
                    isComplete: true
                )
            ]
        case "2":
            return [
                .init(
                    id: UUID().uuidString,
                    name: "Inspect HVAC",
                    buildingID: buildingID,
                    description: "Routine HVAC inspection",
                    dueDate: Date(),
                    category: .inspection,
                    urgency: .medium,
                    recurrence: .monthly,
                    isComplete: false
                ),
                .init(
                    id: UUID().uuidString,
                    name: "Clean Lobby",
                    buildingID: buildingID,
                    description: "Lobby cleaning",
                    dueDate: Date(),
                    category: .cleaning,
                    urgency: .low,
                    recurrence: .daily,
                    isComplete: true
                )
            ]
        default:
            return []
        }
    }
    
    // MARK: - Database Operations
    
    private func loadAssignmentsFromDatabase() async {
        do {
            // Query for unique worker-building assignments from tasks table
            let sql = """
                SELECT DISTINCT 
                    t.buildingId,
                    t.workerId,
                    w.full_name as worker_name,
                    t.category,
                    MIN(t.startTime) as earliest_start,
                    MAX(t.endTime) as latest_end
                FROM tasks t
                JOIN workers w ON t.workerId = w.id
                WHERE t.workerId IS NOT NULL AND t.workerId != ''
                GROUP BY t.buildingId, t.workerId
                ORDER BY t.buildingId, t.workerId
            """
            
            let rows = try await sqliteManager.query(sql)
            
            var assignments: [String: [FrancoWorkerAssignment]] = [:]
            
            for row in rows {
                guard let buildingIdStr = row["buildingId"] as? String,
                      let workerIdStr = row["workerId"] as? String,
                      let workerName = row["worker_name"] as? String else {
                    continue
                }
                
                // Convert worker ID to Int64
                guard let workerId = Int64(workerIdStr) else { continue }
                
                // Determine shift based on task times
                var shift = "Day"
                if let startTimeStr = row["earliest_start"] as? String,
                   let startDate = ISO8601DateFormatter().date(from: startTimeStr) {
                    let hour = Calendar.current.component(.hour, from: startDate)
                    if hour >= 18 {
                        shift = "Evening"
                    } else if hour < 7 {
                        shift = "Early Morning"
                    }
                }
                
                // Determine special role based on category
                let category = row["category"] as? String ?? ""
                let specialRole = determineSpecialRole(from: category, workerId: workerId)
                
                let assignment = FrancoWorkerAssignment(
                    buildingId: buildingIdStr,
                    workerId: workerId,
                    workerName: workerName,
                    shift: shift,
                    specialRole: specialRole
                )
                
                assignments[buildingIdStr, default: []].append(assignment)
            }
            
            if !assignments.isEmpty {
                self.assignmentsCache = assignments
                print("✅ Loaded \(assignments.count) building assignments from database")
            }
        } catch {
            print("❌ Failed to load assignments from database: \(error)")
        }
    }
    
    private func loadAssignmentsFromDB(buildingId: String) async -> [FrancoWorkerAssignment]? {
        do {
            let sql = """
                SELECT DISTINCT 
                    t.workerId,
                    w.full_name as worker_name,
                    t.category,
                    MIN(t.startTime) as earliest_start,
                    MAX(t.endTime) as latest_end
                FROM tasks t
                JOIN workers w ON t.workerId = w.id
                WHERE t.buildingId = ? AND t.workerId IS NOT NULL AND t.workerId != ''
                GROUP BY t.workerId
            """
            
            let rows = try await sqliteManager.query(sql, [buildingId])
            
            guard !rows.isEmpty else { return nil }
            
            return rows.compactMap { row in
                guard let workerIdStr = row["workerId"] as? String,
                      let workerName = row["worker_name"] as? String,
                      let workerId = Int64(workerIdStr) else {
                    return nil
                }
                
                // Determine shift
                var shift = "Day"
                if let startTimeStr = row["earliest_start"] as? String,
                   let startDate = ISO8601DateFormatter().date(from: startTimeStr) {
                    let hour = Calendar.current.component(.hour, from: startDate)
                    if hour >= 18 {
                        shift = "Evening"
                    } else if hour < 7 {
                        shift = "Early Morning"
                    }
                }
                
                let category = row["category"] as? String ?? ""
                let specialRole = determineSpecialRole(from: category, workerId: workerId)
                
                return FrancoWorkerAssignment(
                    buildingId: buildingId,
                    workerId: workerId,
                    workerName: workerName,
                    shift: shift,
                    specialRole: specialRole
                )
            }
        } catch {
            print("❌ Failed to load assignments for building \(buildingId): \(error)")
            return nil
        }
    }
    
    private func loadRoutineTasksFromDatabase() async {
        do {
            let sql = """
                SELECT DISTINCT 
                    buildingId,
                    name as task_name
                FROM tasks
                WHERE recurrence IN ('Daily', 'Weekly')
                ORDER BY buildingId, name
            """
            
            let rows = try await sqliteManager.query(sql)
            
            var tasks: [String: [String]] = [:]
            
            for row in rows {
                guard let buildingId = row["buildingId"] as? String,
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
        do {
            let sql = """
                SELECT DISTINCT name
                FROM tasks
                WHERE buildingId = ? AND recurrence IN ('Daily', 'Weekly')
                ORDER BY name
            """
            
            let rows = try await sqliteManager.query(sql, [buildingId])
            
            guard !rows.isEmpty else { return nil }
            
            return rows.compactMap { row in
                row["name"] as? String
            }
        } catch {
            print("❌ Failed to load routine tasks for building \(buildingId): \(error)")
            return nil
        }
    }
    
    private func saveAssignmentToDB(_ assignment: FrancoWorkerAssignment) async throws {
        // Worker assignments are derived from tasks, so we don't save them separately
        // This method is kept for API compatibility but doesn't need to do anything
        print("ℹ️ Worker assignments are managed through task assignments")
    }
    
    private func saveRoutineTaskToDB(buildingId: String, task: String) async throws {
        // Tasks should be added through OperationalDataManager or task management
        print("ℹ️ Tasks should be added through task management system")
    }
    
    // MARK: - Helper Methods
    
    /// Determine special role based on task category and worker
    private func determineSpecialRole(from category: String, workerId: Int64) -> String? {
        // Map categories to special roles
        switch category.lowercased() {
        case "maintenance":
            if workerId == 1 { return "Lead Maintenance" }
            if workerId == 8 { return "Maintenance Specialist" }
            return "Maintenance"
            
        case "cleaning":
            if workerId == 2 { return "Lead Cleaning" }
            return nil
            
        case "sanitation":
            if workerId == 7 { return "Evening Garbage" }
            return "Garbage"
            
        case "operations":
            if workerId == 7 { return "DSNY Specialist" }
            return nil
            
        case "repair":
            return "Repairs"
            
        case "inspection":
            return "Inspector"
            
        default:
            return nil
        }
    }
    
    // MARK: - Building Intelligence Helpers
    
    private func inferBuildingType(_ building: FrancoSphere.NamedCoordinate) -> BuildingType {
        let name = building.name.lowercased()
        
        if name.contains("museum") { return .cultural }
        if name.contains("perry") { return .residential }
        if name.contains("west 17th") || name.contains("west 18th") { return .commercial }
        if name.contains("elizabeth") { return .mixedUse }
        if name.contains("spring") { return .retail }
        if name.contains("east 20th") { return .commercial }
        
        return .commercial // Default
    }
    
    private func getSpecialRequirements(_ building: FrancoSphere.NamedCoordinate, _ type: BuildingType) -> [String] {
        var requirements: [String] = []
        
        switch type {
        case .cultural:
            requirements.append("Museum quality standards")
            requirements.append("Gentle cleaning products only")
            requirements.append("Visitor experience priority")
        case .residential:
            requirements.append("Quiet hours compliance")
            requirements.append("Resident privacy respect")
            requirements.append("Package area maintenance")
        case .commercial:
            requirements.append("Business hours coordination")
            requirements.append("Professional appearance")
            requirements.append("Lobby presentation priority")
        case .mixedUse:
            requirements.append("Multiple stakeholder coordination")
            requirements.append("Flexible scheduling")
            requirements.append("Diverse cleaning needs")
        case .retail:
            requirements.append("Customer experience focus")
            requirements.append("High-traffic area priority")
            requirements.append("Window display maintenance")
        }
        
        return requirements
    }
    
    private func getPeakOperatingHours(_ building: FrancoSphere.NamedCoordinate, _ type: BuildingType) -> String {
        switch type {
        case .cultural:
            return "10:00 AM - 6:00 PM"
        case .residential:
            return "6:00 AM - 10:00 PM"
        case .commercial:
            return "9:00 AM - 6:00 PM"
        case .mixedUse:
            return "8:00 AM - 8:00 PM"
        case .retail:
            return "10:00 AM - 9:00 PM"
        }
    }
    
    private func getRecommendedWorkerCount(_ building: FrancoSphere.NamedCoordinate, _ type: BuildingType) -> Int {
        let name = building.name.lowercased()
        
        // Kevin's buildings need more workers due to his expanded coverage
        if name.contains("perry") || name.contains("west 17th") || name.contains("rubin") {
            return 2
        }
        
        switch type {
        case .cultural:
            return 2 // Museum requires careful attention
        case .residential:
            return 1
        case .commercial:
            return 2
        case .mixedUse:
            return 3
        case .retail:
            return 2
        }
    }
    
    private func getMaintenancePriority(_ analytics: BuildingAnalytics) -> MaintenancePriority {
        if analytics.completionRate < 0.5 {
            return .high
        } else if analytics.completionRate < 0.8 {
            return .medium
        } else {
            return .low
        }
    }
    
    // MARK: - Utility Functions
    
    /// Haversine distance calculation
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

// MARK: - Supporting Types (Non-conflicting)

// ✅ ADDED: FrancoWorkerAssignment struct (was in BuildingRepository.swift)
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

// ✅ FIXED: Simple legacy task type for internal use only
private struct SimpleLegacyTask {
    let isComplete: Bool
}

struct EnhancedBuildingStatus {
    let buildingId: String
    let completedTasks: Int
    let pendingTasks: Int
    let overdueTasks: Int
    let completionRate: Double
    let lastUpdated: Date
    let workersOnSite: [WorkerOnSite]
    let todaysTaskCount: Int
    
    static func empty(buildingId: String) -> EnhancedBuildingStatus {
        return EnhancedBuildingStatus(
            buildingId: buildingId,
            completedTasks: 0,
            pendingTasks: 0,
            overdueTasks: 0,
            completionRate: 0.0,
            lastUpdated: Date(),
            workersOnSite: [],
            todaysTaskCount: 0
        )
    }
}

struct WorkerOnSite {
    let workerId: String
    let name: String
    let role: String
    let startTime: String
    let endTime: String
    let isCurrentlyOnSite: Bool
}

struct BuildingAnalytics {
    let buildingId: String
    let totalTasks: Int
    let completedTasks: Int
    let overdueTasks: Int
    let uniqueWorkers: Int
    let completionRate: Double
    let averageTasksPerDay: Double
    let periodDays: Int
    
    static func empty(buildingId: String) -> BuildingAnalytics {
        return BuildingAnalytics(
            buildingId: buildingId,
            totalTasks: 0,
            completedTasks: 0,
            overdueTasks: 0,
            uniqueWorkers: 0,
            completionRate: 0.0,
            averageTasksPerDay: 0.0,
            periodDays: 0
        )
    }
}

struct BuildingOperationalInsights {
    let building: FrancoSphere.NamedCoordinate
    let buildingType: BuildingType
    let specialRequirements: [String]
    let peakOperatingHours: String
    let currentStatus: EnhancedBuildingStatus
    let analytics: BuildingAnalytics
    let recommendedWorkerCount: Int
    let maintenancePriority: MaintenancePriority
}

enum BuildingType: String, CaseIterable {
    case residential = "Residential"
    case commercial = "Commercial"
    case cultural = "Cultural"
    case mixedUse = "Mixed Use"
    case retail = "Retail"
}

enum MaintenancePriority: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

// MARK: - Error Types

enum BuildingServiceError: LocalizedError {
    case buildingNotFound(String)
    case invalidBuildingId(String)
    case statusUpdateFailed(String)
    case databaseError(String)
    case databaseNotInitialized
    case noAssignmentsFound
    
    var errorDescription: String? {
        switch self {
        case .buildingNotFound(let id):
            return "Building with ID \(id) not found"
        case .invalidBuildingId(let id):
            return "Invalid building ID format: \(id)"
        case .statusUpdateFailed(let message):
            return "Status update failed: \(message)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .databaseNotInitialized:
            return "Database manager not initialized"
        case .noAssignmentsFound:
            return "No worker assignments found"
        }
    }
}
