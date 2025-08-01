//
//  BuildingService.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Uses correct InventoryItem properties
//  ✅ WORKING: BuildingMetrics integration
//

import Foundation
import GRDB

actor BuildingService {
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
    
    // MARK: - Building Metrics
    
    func buildingMetrics(buildingId: String) async throws -> CoreTypes.BuildingMetrics? {
        return try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
    }
    
    func getBuildingMetrics(_ buildingId: String) async throws -> CoreTypes.BuildingMetrics {
        return try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
    }
    
    // MARK: - Inventory Management
    
    func getInventoryItems(for buildingId: String) async throws -> [CoreTypes.InventoryItem] {
        let query = """
            SELECT * FROM inventory WHERE buildingId = ? ORDER BY name
        """
        
        let rows = try await grdbManager.query(query, [buildingId])
        return rows.compactMap { row in
            guard let id = row["id"] as? Int64,
                  let name = row["name"] as? String,
                  let categoryStr = row["category"] as? String,
                  let category = CoreTypes.InventoryCategory(rawValue: categoryStr),
                  let quantity = row["quantity"] as? Int,
                  let minimumQuantity = row["minimumQuantity"] as? Int else {
                return nil
            }
            
            // Get optional values with defaults
            let maxQuantity = row["maxQuantity"] as? Int ?? (minimumQuantity * 3)
            let unit = row["unit"] as? String ?? "unit"
            let cost = row["cost"] as? Double ?? 0.0
            let supplier = row["supplier"] as? String
            let location = row["location"] as? String
            let lastRestockedTimestamp = row["lastRestocked"] as? Double
            let lastRestocked = lastRestockedTimestamp.map { Date(timeIntervalSince1970: $0) }
            
            // Determine status based on quantities
            let status: CoreTypes.RestockStatus
            if quantity <= 0 {
                status = .outOfStock
            } else if quantity <= minimumQuantity {
                status = .lowStock
            } else {
                status = .inStock
            }
            
            return CoreTypes.InventoryItem(
                id: String(id),
                name: name,
                category: category,
                currentStock: quantity,
                minimumStock: minimumQuantity,
                maxStock: maxQuantity,
                unit: unit,
                cost: cost,
                supplier: supplier,
                location: location,
                lastRestocked: lastRestocked,
                status: status
            )
        }
    }
    
    func saveInventoryItem(_ item: CoreTypes.InventoryItem, buildingId: String) async throws {
        let query = """
            INSERT OR REPLACE INTO inventory 
            (id, buildingId, name, quantity, unit, minimumQuantity, maxQuantity, 
             category, location, cost, supplier, lastRestocked)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        let lastRestockedTimestamp = item.lastRestocked?.timeIntervalSince1970
        
        try await grdbManager.execute(query, [
            item.id,
            buildingId,
            item.name,
            item.currentStock,
            item.unit,
            item.minimumStock,
            item.maxStock,
            item.category.rawValue,
            item.location ?? NSNull(),
            item.cost,
            item.supplier ?? NSNull(),
            lastRestockedTimestamp ?? NSNull()
        ])
    }
    
    func deleteInventoryItem(id: String) async throws {
        let query = "DELETE FROM inventory WHERE id = ?"
        try await grdbManager.execute(query, [id])
    }
    
    func updateInventoryItemQuantity(id: String, newQuantity: Int) async throws {
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
        let metrics = try await getBuildingMetrics(buildingId)
        
        // Calculate health score based on completion rate and overdue tasks
        var healthScore = metrics.completionRate * 100.0
        
        // Penalize for overdue tasks
        if metrics.totalTasks > 0 {
            let overdueRatio = Double(metrics.overdueTasks) / Double(metrics.totalTasks)
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
    
    // MARK: - Database Operations
    
    func updateBuildingData(_ building: NamedCoordinate) async throws {
        let query = """
            UPDATE buildings 
            SET name = ?, address = ?, latitude = ?, longitude = ?
            WHERE id = ?
        """
        
        try await grdbManager.execute(query, [
            building.name,
            building.address,
            building.latitude,
            building.longitude,
            building.id
        ])
    }
    
    func deleteBuildingData(buildingId: String) async throws {
        // Delete building and related data
        try await grdbManager.execute("DELETE FROM buildings WHERE id = ?", [buildingId])
        try await grdbManager.execute("DELETE FROM worker_assignments WHERE building_id = ?", [buildingId])
        try await grdbManager.execute("DELETE FROM routine_tasks WHERE buildingId = ?", [buildingId])
    }
    
    // MARK: - Building Analytics Integration
    
    func getBuildingAnalytics(for buildingId: String) async throws -> [String: Any] {
        let metrics = try await getBuildingMetrics(buildingId)
        
        return [
            "buildingId": buildingId,
            "completionRate": metrics.completionRate,
            "overdueTasks": metrics.overdueTasks,
            "totalTasks": metrics.totalTasks,
            "activeWorkers": metrics.activeWorkers,
            "overallScore": metrics.overallScore,
            "isCompliant": metrics.isCompliant,
            "lastUpdated": metrics.lastUpdated
        ]
    }
    
    // MARK: - Legacy Method Support
    
    func getCoreTypes() async throws -> [NamedCoordinate] {
        return try await getAllBuildings()
    }
    
    func getBuildings(building: String) async throws -> [NamedCoordinate] {
        return try await searchBuildings(query: building)
    }
    
    func getBuildingData(data: String) async throws -> NamedCoordinate? {
        return try await getBuilding(buildingId: data)
    }
    
    func updateBuilding(building: String) async throws {
        // Implementation for building update by name/query
        print("Building update requested for: \(building)")
    }
}
