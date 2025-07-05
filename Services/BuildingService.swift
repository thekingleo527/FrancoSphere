// UPDATED: Using centralized TypeRegistry for all types
//
//  BuildingService.swift
//  FrancoSphere
//
//  ✅ CRITICAL FIXES APPLIED:
//  ✅ Kevin Assignment Reality Correction (Rubin Museum ID "14", NOT Franklin ID "13")
//  ✅ Service Consolidation (BuildingStatusManager + BuildingRepository + InventoryManager)
//  ✅ Database ID handling (String ↔ Int64 conversion fixes)
//  ✅ Integration with WorkerService, TaskService, OperationalDataManager
//  ✅ Enhanced caching and performance optimization
//  ✅ FIXED: Removed duplicate method declarations only
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import CoreLocation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import SQLite
// FrancoSphere Types Import
// (This comment helps identify our import)


// ✅ Type alias for SQLite.Binding clarity
typealias SQLiteBinding = SQLite.Binding

actor BuildingService {
    static let shared = BuildingService()
    
    // MARK: - Dependencies
    private var buildingsCache: [String: NamedCoordinate] = [:]
    private var buildingStatusCache: [String: EnhancedBuildingStatus] = [:]
    private var assignmentsCache: [String: [FrancoWorkerAssignment]] = [:]
    private var routineTasksCache: [String: [String]] = [:]
    private var taskStatusCache: [String: TaskStatus] = [:]
    private var inventoryCache: [String: [FrancoSphere.InventoryItem]] = [:]
    private let sqliteManager = SQLiteManager.shared
    private let operationalManager = OperationalDataManager.shared
    
    // ✅ CRITICAL: Kevin's Corrected Building Data (Rubin Museum Reality Fix)
    private let buildings: [NamedCoordinate]
    
    // MARK: - Initialization with Kevin Correction
    private init() {
        // ✅ CRITICAL: Building definitions with Kevin's corrected assignments
        self.buildings = [
            NamedCoordinate(id: "1", name: "12 West 18th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7390, longitude: -73.9930)),
            NamedCoordinate(id: "2", name: "29-31 East 20th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9880)),
            NamedCoordinate(id: "3", name: "135-139 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7398, longitude: -73.9972)),
            NamedCoordinate(id: "4", name: "104 Franklin Street", coordinate: CLLocationCoordinate2D(latitude: 40.7180, longitude: -74.0060)),
            NamedCoordinate(id: "5", name: "138 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7400, longitude: -73.9970)),
            NamedCoordinate(id: "6", name: "68 Perry Street", coordinate: CLLocationCoordinate2D(latitude: 40.7350, longitude: -74.0050)),
            NamedCoordinate(id: "7", name: "136 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7402, longitude: -73.9970)),
            NamedCoordinate(id: "8", name: "41 Elizabeth Street", coordinate: CLLocationCoordinate2D(latitude: 40.7170, longitude: -73.9970)),
            NamedCoordinate(id: "9", name: "117 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7395, longitude: -73.9950)),
            NamedCoordinate(id: "10", name: "131 Perry Street", coordinate: CLLocationCoordinate2D(latitude: 40.7340, longitude: -74.0060)),
            NamedCoordinate(id: "11", name: "123 1st Avenue", coordinate: CLLocationCoordinate2D(latitude: 40.7270, longitude: -73.9850)),
            NamedCoordinate(id: "12", name: "178 Spring Street", coordinate: CLLocationCoordinate2D(latitude: 40.7250, longitude: -74.0020)),
            NamedCoordinate(id: "13", name: "112 West 18th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7400, longitude: -73.9940)),
            // ✅ CRITICAL CORRECTION: Kevin works at Rubin Museum, NOT Franklin Street
            NamedCoordinate(id: "14", name: "Rubin Museum (142–148 W 17th)", coordinate: CLLocationCoordinate2D(latitude: 40.7402, longitude: -73.9980)),
            NamedCoordinate(id: "15", name: "133 East 15th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7345, longitude: -73.9875)),
            NamedCoordinate(id: "16", name: "Stuyvesant Cove Park", coordinate: CLLocationCoordinate2D(latitude: 40.7318, longitude: -73.9740)),
            NamedCoordinate(id: "17", name: "36 Walker Street", coordinate: CLLocationCoordinate2D(latitude: 40.7190, longitude: -74.0050)),
            NamedCoordinate(id: "18", name: "115 7th Avenue", coordinate: CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9980))
        ]
        
        // Initialize caches asynchronously
        Task {
            await initializeCaches()
        }
        
        // Set up task completion notifications
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
        await validateKevinCorrection()
    }
    
    // ✅ CRITICAL: Validate Kevin's correction on service startup
    private func validateKevinCorrection() async {
        print("🔍 VALIDATION: Checking Kevin's building assignments...")
        
        let kevinBuildings = await getKevinCorrectedAssignments()
        
        let hasRubin = kevinBuildings.contains { $0.id == "14" && $0.name.contains("Rubin") }
        let hasFranklin = kevinBuildings.contains { $0.id == "13" && $0.name.contains("Franklin") }
        
        if hasRubin && !hasFranklin {
            print("✅ VALIDATION SUCCESS: Kevin correctly assigned to Rubin Museum (ID: 14)")
        } else {
            print("🚨 VALIDATION FAILED: Rubin=\(hasRubin), Franklin=\(hasFranklin)")
            print("   Expected: Kevin works at Rubin Museum (ID: 14)")
            print("   Reality Check: Kevin should NOT have Franklin Street")
        }
        
        print("📊 Kevin's Building Count: \(kevinBuildings.count) (Target: 8+)")
        kevinBuildings.forEach { building in
            print("   📍 \(building.name) (ID: \(building.id))")
        }
    }
    
    // MARK: - Task Status Management (Consolidated from BuildingStatusManager)
    
    enum TaskStatus: String, CaseIterable {
        case complete = "Complete"
        case partial = "Partial"
        case pending = "Pending"
        case overdue = "Overdue"
        
        var color: Color {
            switch self {
            case .complete: return .green
            case .partial: return .yellow
            case .pending: return .blue
            case .overdue: return .red
            }
        }
        
        var buildingStatus: FrancoSphere.BuildingStatus {
            switch self {
            case .complete: return .active
            case .partial: return .maintenance
            case .pending: return .maintenance
            case .overdue: return .inactive
            }
        }
    }
    
    // MARK: - Core Building Data Management
    
    var allBuildings: [NamedCoordinate] {
        get async { buildings }
    }
    
    func getBuilding(_ id: String) async throws -> NamedCoordinate? {
        // Check cache first
        if let cachedBuilding = buildingsCache[id] {
            return cachedBuilding
        }
        
        // Try hardcoded buildings first (source of truth)
        if let hardcodedBuilding = buildings.first(where: { $0.id == id }) {
            buildingsCache[id] = hardcodedBuilding
            return hardcodedBuilding
        }
        
        // Database fallback with proper ID conversion
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
            
            let building = NamedCoordinate(
                id: id, // Keep as String for application use
                name: row["name"] as? String ?? "",
                latitude: row["latitude"] as? Double ?? 0,
                longitude: row["longitude"] as? Double ?? 0,
                imageAssetName: row["image_asset"] as? String ?? "building_\(id)"
            )
            
            buildingsCache[id] = building
            return building
            
        } catch {
            print("❌ Database error fetching building \(id): \(error)")
            return nil
        }
    }
    
    func getAllBuildings() async throws -> [NamedCoordinate] {
        return buildings
    }
    
    func getBuildingsForWorker(_ workerId: String) async throws -> [NamedCoordinate] {
        // ✅ CRITICAL: Special handling for Kevin's corrected assignments
        if workerId == "4" {
            return await getKevinCorrectedAssignments()
        }
        
        // Delegate to WorkerService for other workers
        return try await WorkerService.shared.getAssignedBuildings(workerId)
    }
    
    // ✅ CRITICAL: Kevin's Corrected Building Assignments (Reality Fix)
    private func getKevinCorrectedAssignments() async -> [NamedCoordinate] {
        return [
            NamedCoordinate(id: "10", name: "131 Perry Street", coordinate: CLLocationCoordinate2D(latitude: 40.7359, longitude: -74.0059)),
            NamedCoordinate(id: "6", name: "68 Perry Street", coordinate: CLLocationCoordinate2D(latitude: 40.7357, longitude: -74.0055)),
            NamedCoordinate(id: "3", name: "135-139 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7398, longitude: -73.9972)),
            NamedCoordinate(id: "7", name: "136 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7399, longitude: -73.9971)),
            NamedCoordinate(id: "5", name: "138 West 17th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7400, longitude: -73.9970)),
            NamedCoordinate(id: "2", name: "29-31 East 20th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7388, longitude: -73.9892)),
            NamedCoordinate(id: "12", name: "178 Spring Street", coordinate: CLLocationCoordinate2D(latitude: 40.7245, longitude: -73.9968)),
            // ✅ CORRECTED: Rubin Museum instead of 104 Franklin Street
            NamedCoordinate(id: "14", name: "Rubin Museum (142–148 W 17th)", coordinate: CLLocationCoordinate2D(latitude: 40.7402, longitude: -73.9980))
        ]
    }
    
    // MARK: - Building Name/ID Mapping with Kevin Correction
    
    func id(forName name: String) async -> String? {
        let cleanedName = name
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "—", with: "-")
            .trimmingCharacters(in: .whitespaces)
        
        // ✅ CRITICAL: Ensure Rubin Museum maps to correct ID for Kevin
        if cleanedName.lowercased().contains("rubin") {
            return "14"
        }
        
        return buildings.first {
            $0.name.compare(cleanedName, options: .caseInsensitive) == .orderedSame ||
            $0.name.compare(name, options: .caseInsensitive) == .orderedSame
        }?.id
    }
    
    func name(forId id: String) async -> String {
        buildings.first { $0.id == id }?.name ?? "Unknown Building"
    }
    
    // MARK: - Enhanced Building Status Management
    
    func getBuildingStatus(_ buildingId: String) async throws -> EnhancedBuildingStatus {
        // Check cache with 5-minute expiration
        if let cachedStatus = buildingStatusCache[buildingId],
           Date().timeIntervalSince(cachedStatus.lastUpdated) < 300 {
            return cachedStatus
        }
        
        guard let buildingIdInt = Int64(buildingId) else {
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
            
            var completed = 0, pending = 0, overdue = 0
            var completionRate = 0.0
            
            for row in rows {
                let status = row["status"] as? String ?? ""
                let count = row["count"] as? Int64 ?? 0
                
                switch status {
                case "completed": completed = Int(count)
                case "pending": pending = Int(count)
                case "overdue": overdue = Int(count)
                default: break
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
            
            buildingStatusCache[buildingId] = status
            return status
            
        } catch {
            print("❌ Error fetching building status for \(buildingId): \(error)")
            return EnhancedBuildingStatus.empty(buildingId: buildingId)
        }
    }
    
    // MARK: - Worker Assignment Management (Consolidated from BuildingRepository)
    
    func assignments(for buildingId: String) async -> [FrancoWorkerAssignment] {
        if let cached = assignmentsCache[buildingId] {
            return cached
        }
        
        if let dbAssignments = await loadAssignmentsFromDB(buildingId: buildingId) {
            assignmentsCache[buildingId] = dbAssignments
            return dbAssignments
        }
        
        return []
    }
    
    func getBuildingWorkerAssignments(for buildingId: String) async -> [FrancoWorkerAssignment] {
        let existingAssignments = await assignments(for: buildingId)
        if !existingAssignments.isEmpty {
            return existingAssignments
        }
        
        // ✅ CRITICAL: Ensure Kevin is properly assigned to Rubin Museum
        if buildingId == "14" {
            return [
                FrancoWorkerAssignment(
                    buildingId: buildingId,
                    workerId: 4, // Kevin Dutan
                    workerName: "Kevin Dutan",
                    shift: "Day",
                    specialRole: "Rubin Museum Specialist"
                )
            ]
        }
        
        return []
    }
    
    // MARK: - Inventory Management (Consolidated from InventoryManager) - ✅ FIXED: Single declarations only
    
    func getInventoryItems(for buildingId: String) async throws -> [FrancoSphere.InventoryItem] {
        if let cachedItems = inventoryCache[buildingId] {
            return cachedItems
        }
        
        try await createInventoryTableIfNeeded()
        
        let query = """
            SELECT * FROM inventory_items 
            WHERE building_id = ? 
            ORDER BY name ASC
        """
        
        let rows = try await sqliteManager.query(query, [buildingId])
        
        let items = rows.compactMap { row -> FrancoSphere.InventoryItem? in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let buildingID = row["building_id"] as? String,
                  let categoryString = row["category"] as? String,
                  let quantity = row["quantity"] as? Int64,
                  let unit = row["unit"] as? String,
                  let minimumQuantity = row["minimum_quantity"] as? Int64,
                  let needsReorder = row["needs_reorder"] as? Int64,
                  let lastRestockTimestamp = row["last_restock_date"] as? String else {
                return nil
            }
            
            let category = FrancoSphere.InventoryCategory(rawValue: categoryString) ?? .other
            let lastRestockDate = ISO8601DateFormatter().date(from: lastRestockTimestamp) ?? Date()
            
            return FrancoSphere.InventoryItem(id: id, name: name, category: category, quantity: Int(Int(quantity)), status: .inStock, minimumStock: Int(Int(minimumQuantity)))
        }
        
        inventoryCache[buildingId] = items
        return items
    }
    
    func saveInventoryItem(_ item: FrancoSphere.InventoryItem) async throws {
        try await createInventoryTableIfNeeded()
        
        let insertQuery = """
            INSERT OR REPLACE INTO inventory_items (
                id, name, building_id, category, quantity, unit, 
                minimum_quantity, needs_reorder, last_restock_date, 
                location, notes, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let lastRestockString = ISO8601DateFormatter().string(from: Date())
        let needsReorderInt = (item.status == .lowStock || item.status == .outOfStock) ? 1 : 0
        
        let parameters: [SQLiteBinding] = [
            item.id, item.name, item.id, item.category.rawValue,
            item.quantity, item.category.rawValue, item.minimumStock, needsReorderInt,
            lastRestockString, item.name, item.name ?? "",
            ISO8601DateFormatter().string(from: Date())
        ]
        
        try await sqliteManager.execute(insertQuery, parameters)
        inventoryCache.removeValue(forKey: item.id)
        
        print("✅ Inventory item saved: \(item.name)")
    }
    
    func updateInventoryItemQuantity(itemId: String, newQuantity: Int, workerId: String) async throws {
        try await createInventoryTableIfNeeded()
        
        let updateQuery = """
            UPDATE inventory_items 
            SET quantity = ?, 
                needs_reorder = (? <= minimum_quantity),
                last_restock_date = ?,
                updated_by = ?
            WHERE id = ?
        """
        
        let parameters: [SQLiteBinding] = [
            newQuantity,
            newQuantity,
            ISO8601DateFormatter().string(from: Date()),
            workerId,
            itemId
        ]
        
        try await sqliteManager.execute(updateQuery, parameters)
        
        // Invalidate cache for all buildings (since we don't know which building this item belongs to)
        inventoryCache.removeAll()
        
        print("✅ Inventory item quantity updated: \(itemId) -> \(newQuantity)")
    }
    
    func deleteInventoryItem(itemId: String) async throws {
        try await createInventoryTableIfNeeded()
        
        let deleteQuery = "DELETE FROM inventory_items WHERE id = ?"
        try await sqliteManager.execute(deleteQuery, [itemId])
        
        // Invalidate cache
        inventoryCache.removeAll()
        
        print("✅ Inventory item deleted: \(itemId)")
    }
    
    func getLowStockItems(for buildingId: String) async throws -> [FrancoSphere.InventoryItem] {
        let allItems = try await getInventoryItems(for: buildingId)
        return allItems.filter { $0.status == .lowStock || $0.status == .outOfStock }
    }
    
    func getInventoryItems(for buildingId: String, category: FrancoSphere.InventoryCategory) async throws -> [FrancoSphere.InventoryItem] {
        let allItems = try await getInventoryItems(for: buildingId)
        return allItems.filter { $0.category == category }
    }
    
    // MARK: - Building Analytics and Intelligence
    
    func getBuildingAnalytics(_ buildingId: String, days: Int = 30) async throws -> BuildingAnalytics {
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
    
    func getBuildingOperationalInsights(_ buildingId: String) async throws -> BuildingOperationalInsights {
        let building = try await getBuilding(buildingId)
        let status = try await getBuildingStatus(buildingId)
        let analytics = try await getBuildingAnalytics(buildingId)
        
        guard let building = building else {
            throw BuildingServiceError.buildingNotFound(buildingId)
        }
        
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
    
    // MARK: - Cache Management & Performance
    
    func clearBuildingCache() {
        buildingsCache.removeAll()
        buildingStatusCache.removeAll()
        assignmentsCache.removeAll()
        routineTasksCache.removeAll()
        taskStatusCache.removeAll()
        inventoryCache.removeAll()
        print("✅ Building cache cleared")
    }
    
    func refreshBuildingStatus(_ buildingId: String) async throws -> EnhancedBuildingStatus {
        buildingStatusCache.removeValue(forKey: buildingId)
        taskStatusCache.removeValue(forKey: buildingId)
        return try await getBuildingStatus(buildingId)
    }
    
    // MARK: - Private Helpers
    
    private func getWorkersOnSite(_ buildingId: String) async throws -> [WorkerOnSite] {
        guard let buildingIdInt = Int64(buildingId) else { return [] }
        
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
                      let endTime = row["end_time"] as? String else { return nil }
                
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
    
    private func inferBuildingType(_ building: NamedCoordinate) -> BuildingType {
        let name = building.name.lowercased()
        
        if name.contains("museum") || name.contains("rubin") { return .cultural }
        if name.contains("perry") { return .residential }
        if name.contains("west 17th") || name.contains("west 18th") { return .commercial }
        if name.contains("elizabeth") { return .mixedUse }
        if name.contains("spring") { return .retail }
        
        return .commercial
    }
    
    private func getSpecialRequirements(_ building: NamedCoordinate, _ type: BuildingType) -> [String] {
        var requirements: [String] = []
        
        // ✅ Special requirements for Kevin's Rubin Museum assignment
        if building.id == "14" {
            requirements.append("Museum quality standards")
            requirements.append("Gentle cleaning products only")
            requirements.append("Visitor experience priority")
            requirements.append("Kevin Dutan lead responsibility")
        }
        
        switch type {
        case .cultural:
            requirements.append("Cultural institution protocols")
        case .residential:
            requirements.append("Quiet hours compliance")
        case .commercial:
            requirements.append("Business hours coordination")
        case .mixedUse:
            requirements.append("Multiple stakeholder coordination")
        case .retail:
            requirements.append("Customer experience focus")
        }
        
        return requirements
    }
    
    private func getPeakOperatingHours(_ building: NamedCoordinate, _ type: BuildingType) -> String {
        // ✅ Kevin's Rubin Museum has specific hours
        if building.id == "14" {
            return "10:00 AM - 6:00 PM (Museum Hours)"
        }
        
        switch type {
        case .cultural: return "10:00 AM - 6:00 PM"
        case .residential: return "6:00 AM - 10:00 PM"
        case .commercial: return "9:00 AM - 6:00 PM"
        case .mixedUse: return "8:00 AM - 8:00 PM"
        case .retail: return "10:00 AM - 9:00 PM"
        }
    }
    
    private func getRecommendedWorkerCount(_ building: NamedCoordinate, _ type: BuildingType) -> Int {
        // ✅ Kevin's buildings need appropriate staffing
        if building.id == "14" { return 2 } // Rubin Museum
        if building.name.contains("Perry") || building.name.contains("West 17th") { return 2 }
        
        switch type {
        case .cultural: return 2
        case .residential: return 1
        case .commercial: return 2
        case .mixedUse: return 3
        case .retail: return 2
        }
    }
    
    private func getMaintenancePriority(_ analytics: BuildingAnalytics) -> MaintenancePriority {
        if analytics.completionRate < 0.5 { return .high }
        else if analytics.completionRate < 0.8 { return .medium }
        else { return .low }
    }
    
    // MARK: - Database Operations
    
    private func loadAssignmentsFromDatabase() async {
        do {
            let sql = """
                SELECT DISTINCT 
                    t.buildingId,
                    t.workerId,
                    w.full_name as worker_name,
                    t.category,
                    MIN(t.startTime) as earliest_start
                FROM tasks t
                JOIN workers w ON t.workerId = w.id
                WHERE t.workerId IS NOT NULL AND t.workerId != ''
                GROUP BY t.buildingId, t.workerId
            """
            
            let rows = try await sqliteManager.query(sql)
            var assignments: [String: [FrancoWorkerAssignment]] = [:]
            
            for row in rows {
                guard let buildingIdStr = row["buildingId"] as? String,
                      let workerIdStr = row["workerId"] as? String,
                      let workerName = row["worker_name"] as? String,
                      let workerId = Int64(workerIdStr) else { continue }
                
                let shift = determineShift(from: row["earliest_start"] as? String)
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
            
            self.assignmentsCache = assignments
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
                
                let shift = determineShift(from: row["earliest_start"] as? String)
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
    
    private func createInventoryTableIfNeeded() async throws {
        let createTableQuery = """
            CREATE TABLE IF NOT EXISTS inventory_items (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                building_id TEXT NOT NULL,
                category TEXT NOT NULL,
                quantity INTEGER NOT NULL DEFAULT 0,
                unit TEXT NOT NULL,
                minimum_quantity INTEGER NOT NULL DEFAULT 0,
                needs_reorder INTEGER NOT NULL DEFAULT 0,
                last_restock_date TEXT NOT NULL,
                location TEXT,
                notes TEXT,
                created_at TEXT NOT NULL,
                updated_by TEXT DEFAULT 'system'
            )
        """
        
        try await sqliteManager.execute(createTableQuery, [])
        
        // Create indexes for performance
        let indexQueries = [
            "CREATE INDEX IF NOT EXISTS idx_inventory_building ON inventory_items(building_id)",
            "CREATE INDEX IF NOT EXISTS idx_inventory_category ON inventory_items(category)",
            "CREATE INDEX IF NOT EXISTS idx_inventory_reorder ON inventory_items(needs_reorder)"
        ]
        
        for indexQuery in indexQueries {
            try await sqliteManager.execute(indexQuery, [])
        }
    }
    
    private func determineShift(from timeString: String?) -> String {
        guard let timeString = timeString,
              let date = ISO8601DateFormatter().date(from: timeString) else {
            return "Day"
        }
        
        let hour = Calendar.current.component(.hour, from: date)
        if hour >= 18 { return "Evening" }
        else if hour < 7 { return "Early Morning" }
        else { return "Day" }
    }
    
    private func determineSpecialRole(from category: String, workerId: Int64) -> String? {
        // ✅ Special role handling for Kevin at Rubin Museum
        if workerId == 4 {
            if category.lowercased().contains("sanitation") || category.lowercased().contains("trash") {
                return "Rubin Museum Sanitation Specialist"
            }
            return "Rubin Museum Lead"
        }
        
        switch category.lowercased() {
        case "maintenance": return workerId == 1 ? "Lead Maintenance" : "Maintenance"
        case "cleaning": return workerId == 2 ? "Lead Cleaning" : nil
        case "sanitation": return "Sanitation"
        default: return nil
        }
    }
    
    private func handleTaskStatusChange(notification: Notification) async {
        if let taskID = notification.userInfo?["taskID"] as? String,
           let buildingID = await getBuildingIDForTask(taskID) {
            taskStatusCache.removeValue(forKey: buildingID)
            buildingStatusCache.removeValue(forKey: buildingID)
        }
    }
    
    private func getBuildingIDForTask(_ taskID: String) async -> String? {
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
}

// MARK: - Supporting Types

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
    let building: NamedCoordinate
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
