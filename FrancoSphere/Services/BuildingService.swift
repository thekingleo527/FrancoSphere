//
//  BuildingService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Circular reference resolved
//  ✅ CONVERTED TO GRDB: Uses GRDBManager instead of GRDBManager
//  ✅ REAL DATA: Connects to actual database with preserved building data
//  ✅ ASYNC/AWAIT: Modern Swift concurrency patterns
//

import Foundation
import GRDB

actor BuildingService {
    // ✅ FIXED: Circular reference - creates new instance instead of referencing self
    static let shared = BuildingService()
    
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    // MARK: - Public API Methods
    
    func getAllBuildings() async throws -> [NamedCoordinate] {
        let rows = try await grdbManager.query("SELECT * FROM buildings ORDER BY name")
        return rows.compactMap { row in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let latitude = row["latitude"] as? Double,
                  let longitude = row["longitude"] as? Double else {
                return nil
            }
            
            return NamedCoordinate(
                id: String(id),
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude
            )
        }
    }
    
    func getBuilding(buildingId: String) async throws -> NamedCoordinate? {
        let rows = try await grdbManager.query(
            "SELECT * FROM buildings WHERE id = ?",
            [buildingId]
        )
        
        guard let row = rows.first,
              let id = row["id"] as? Int64,
              let name = row["name"] as? String,
              let address = row["address"] as? String,
              let latitude = row["latitude"] as? Double,
              let longitude = row["longitude"] as? Double else {
            return nil
        }
        
        return NamedCoordinate(
            id: String(id),
            name: name,
            address: address,
            latitude: latitude,
            longitude: longitude
        )
    }
    
    func getBuildingsForWorker(_ workerId: String) async throws -> [NamedCoordinate] {
        let rows = try await grdbManager.query("""
            SELECT DISTINCT b.id, b.name, b.address, b.latitude, b.longitude
            FROM buildings b
            INNER JOIN worker_assignments wa ON CAST(b.id AS TEXT) = wa.building_id
            WHERE wa.worker_id = ? AND wa.is_active = 1
            ORDER BY b.name
        """, [workerId])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let latitude = row["latitude"] as? Double,
                  let longitude = row["longitude"] as? Double else {
                return nil
            }
            
            return NamedCoordinate(
                id: String(id),
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude
            )
        }
    }
    
    func name(forId buildingId: CoreTypes.BuildingID) async -> String {
        do {
            let rows = try await grdbManager.query(
                "SELECT name FROM buildings WHERE id = ?",
                [buildingId]
            )
            return rows.first?["name"] as? String ?? "Unknown Building"
        } catch {
            print("❌ Error fetching building name: \(error)")
            return "Unknown Building"
        }
    }
    
    // MARK: - Building Analytics
    
    func getCoreTypes.BuildingAnalytics(_ buildingId: String) async throws -> CoreTypes.CoreTypes.BuildingAnalytics {
        // Get task statistics for this building
        let taskRows = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total_tasks,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed_tasks,
                SUM(CASE WHEN dueDate < datetime('now') AND isCompleted = 0 THEN 1 ELSE 0 END) as overdue_tasks
            FROM tasks 
            WHERE buildingId = ?
        """, [buildingId])
        
        let taskData = taskRows.first ?? [:]
        let totalTasks = taskData["total_tasks"] as? Int64 ?? 0
        let completedTasks = taskData["completed_tasks"] as? Int64 ?? 0
        let overdueTasks = taskData["overdue_tasks"] as? Int64 ?? 0
        
        // Get worker count for this building
        let workerRows = try await grdbManager.query("""
            SELECT COUNT(DISTINCT worker_id) as unique_workers
            FROM worker_assignments
            WHERE building_id = ? AND is_active = 1
        """, [buildingId])
        
        let uniqueWorkers = workerRows.first?["unique_workers"] as? Int64 ?? 0
        
        // Calculate metrics
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 1.0
        let efficiency = max(0.0, min(1.0, completionRate - (Double(overdueTasks) / max(1.0, Double(totalTasks)))))
        
        return CoreTypes.CoreTypes.BuildingAnalytics(
            buildingId: buildingId,
            totalTasks: Int(totalTasks),
            completedTasks: Int(completedTasks),
            overdueTasks: Int(overdueTasks),
            completionRate: completionRate,
            uniqueWorkers: Int(uniqueWorkers),
            averageCompletionTime: 3600, // Default 1 hour
            efficiency: efficiency,
            lastUpdated: Date()
        )
    }
    
    // MARK: - Inventory Management
    
    func getCoreTypes.InventoryItems(for buildingId: String) async throws -> [CoreTypes.CoreTypes.InventoryItem] {
        let query = """
            SELECT * FROM inventory WHERE buildingId = ? ORDER BY name
        """
        
        let rows = try await grdbManager.query(query, [buildingId])
        return rows.compactMap { row in
            guard let name = row["name"] as? String,
                  let categoryStr = row["category"] as? String,
                  let category = CoreTypes.InventoryCategory(rawValue: categoryStr),
                  let quantity = row["quantity"] as? Int,
                  let minThreshold = row["minimumQuantity"] as? Int,
                  let location = row["location"] as? String else {
                return nil
            }
            
            return CoreTypes.CoreTypes.InventoryItem(
                id: String(row["id"] as? Int64 ?? 0),
                name: name,
                category: category,
                quantity: quantity,
                minThreshold: minThreshold,
                location: location,
                currentStock: quantity,
                minimumStock: minThreshold,
                unit: row["unit"] as? String ?? "unit",
                restockStatus: quantity < minThreshold ? .lowStock : .inStock
            )
        }
    }
    
    func saveCoreTypes.InventoryItem(_ item: CoreTypes.CoreTypes.InventoryItem, buildingId: String) async throws {
        let query = """
            INSERT OR REPLACE INTO inventory 
            (id, buildingId, name, quantity, unit, minimumQuantity, category, location)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        try await grdbManager.execute(query, [
            item.id, buildingId, item.name, item.quantity, item.unit,
            item.minThreshold, item.category.rawValue, item.location
        ])
    }
    
    func deleteCoreTypes.InventoryItem(id: String) async throws {
        let query = "DELETE FROM inventory WHERE id = ?"
        try await grdbManager.execute(query, [id])
    }
    
    func updateCoreTypes.InventoryItemQuantity(id: String, newQuantity: Int) async throws {
        let query = "UPDATE inventory SET quantity = ? WHERE id = ?"
        try await grdbManager.execute(query, [newQuantity, id])
    }
    
    // MARK: - Building Search and Filtering
    
    func searchBuildings(query: String) async throws -> [NamedCoordinate] {
        let rows = try await grdbManager.query("""
            SELECT * FROM buildings 
            WHERE name LIKE ? OR address LIKE ? 
            ORDER BY name
        """, ["%\(query)%", "%\(query)%"])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let latitude = row["latitude"] as? Double,
                  let longitude = row["longitude"] as? Double else {
                return nil
            }
            
            return NamedCoordinate(
                id: String(id),
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude
            )
        }
    }
    
    func getBuildingsNearLocation(latitude: Double, longitude: Double, radiusKm: Double) async throws -> [NamedCoordinate] {
        // Simple distance calculation - for production use PostGIS or similar
        let rows = try await grdbManager.query("SELECT * FROM buildings")
        
        return rows.compactMap { row in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String,
                  let address = row["address"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lon = row["longitude"] as? Double else {
                return nil
            }
            
            // Basic distance calculation (not precise, for demo)
            let deltaLat = lat - latitude
            let deltaLon = lon - longitude
            let distance = sqrt(deltaLat * deltaLat + deltaLon * deltaLon) * 111.0 // Rough km conversion
            
            guard distance <= radiusKm else { return nil }
            
            return NamedCoordinate(
                id: String(id),
                name: name,
                address: address,
                latitude: lat,
                longitude: lon
            )
        }
    }
    
    // MARK: - Building Status and Health
    
    func getBuildingHealthScore(_ buildingId: String) async throws -> Double {
        let analytics = try await getCoreTypes.BuildingAnalytics(buildingId)
        
        // Calculate health score based on completion rate and overdue tasks
        var healthScore = analytics.completionRate * 100.0
        
        // Penalize for overdue tasks
        if analytics.totalTasks > 0 {
            let overdueRatio = Double(analytics.overdueTasks) / Double(analytics.totalTasks)
            healthScore = max(0.0, healthScore - (overdueRatio * 30.0))
        }
        
        return min(100.0, max(0.0, healthScore))
    }
    
    func getBuildingStatus(_ buildingId: String) async throws -> String {
        let healthScore = try await getBuildingHealthScore(buildingId)
        
        switch healthScore {
        case 90...100: return "Excellent"
        case 80..<90: return "Good"
        case 70..<80: return "Fair"
        case 60..<70: return "Poor"
        default: return "Critical"
        }
    }
}
