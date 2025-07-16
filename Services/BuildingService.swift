//
//  BuildingService.swift
//  FrancoSphere v6.0
//
//  ✅ CONVERTED TO GRDB: Uses GRDBManager instead of SQLiteManager
//  ✅ REAL DATA: Connects to actual database with preserved building data
//  ✅ ASYNC/AWAIT: Modern Swift concurrency patterns
//

import Foundation
import GRDB

actor BuildingService {
    static let shared = BuildingService.shared
    
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
}

    // MARK: - Inventory Management
    
    func getInventoryItems(for buildingId: String) async throws -> [CoreTypes.InventoryItem] {
        let query = """
            SELECT * FROM inventory WHERE buildingId = ? ORDER BY name
        """
        
        let rows = try await GRDBManager.shared.query(query, [buildingId])
        return rows.compactMap { row in
            guard let name = row["name"] as? String,
                  let categoryStr = row["category"] as? String,
                  let category = CoreTypes.InventoryCategory(rawValue: categoryStr),
                  let quantity = row["quantity"] as? Int,
                  let minThreshold = row["minimumQuantity"] as? Int,
                  let location = row["location"] as? String else {
                return nil
            }
            
            return CoreTypes.InventoryItem(
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
    
    func saveInventoryItem(_ item: CoreTypes.InventoryItem, buildingId: String) async throws {
        let query = """
            INSERT OR REPLACE INTO inventory 
            (id, buildingId, name, quantity, unit, minimumQuantity, category, location)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        try await GRDBManager.shared.execute(query, [
            item.id, buildingId, item.name, item.quantity, item.unit,
            item.minThreshold, item.category.rawValue, item.location
        ])
    }
    
    func deleteInventoryItem(id: String) async throws {
        let query = "DELETE FROM inventory WHERE id = ?"
        try await GRDBManager.shared.execute(query, [id])
    }
    
    func updateInventoryItemQuantity(id: String, newQuantity: Int) async throws {
        let query = "UPDATE inventory SET quantity = ? WHERE id = ?"
        try await GRDBManager.shared.execute(query, [newQuantity, id])
    }
