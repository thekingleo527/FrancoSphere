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
}
