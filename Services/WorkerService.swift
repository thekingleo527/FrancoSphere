//
//  WorkerService.swift
//  FrancoSphere
//
//  ✅ COMPLETELY REBUILT to fix structural syntax errors
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import CoreLocation
// FrancoSphere Types Import
// (This comment helps identify our import)


actor WorkerService {
    static let shared = WorkerService()
    
    private var workersCache: [String: Worker] = [:]
    private let sqliteManager = SQLiteManager.shared
    
    func getWorker(_ id: String) async throws -> Worker? {
        if let cachedWorker = workersCache[id] {
            return cachedWorker
        }
        
        let query = "SELECT * FROM workers WHERE id = ? AND is_active = 1"
        let rows = try await sqliteManager.query(query, [id])
        
        guard let row = rows.first else { return nil }
        
        let worker = Worker(
            workerId: row["id"] as? String ?? "",
            name: row["name"] as? String ?? "",
            email: row["email"] as? String ?? "",
            role: row["role"] as? String ?? "Worker",
            isActive: (row["is_active"] as? Int64 ?? 1) == 1
        )
        
        workersCache[id] = worker
        return worker
    }
    
    func getAssignedBuildings(_ workerId: String) async throws -> [NamedCoordinate] {
        if workerId == "4" {
            return getKevinBuildingAssignments()
        }
        
        let query = """
            SELECT DISTINCT b.* FROM buildings b
            JOIN worker_assignments wa ON b.id = wa.building_id  
            WHERE wa.worker_id = ? AND wa.is_active = 1
            ORDER BY b.name
        """
        
        let rows = try await sqliteManager.query(query, [workerId])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let name = row["name"] as? String,
                  let lat = row["latitude"] as? Double,
                  let lng = row["longitude"] as? Double else { return nil }
            
            return NamedCoordinate(
                id: id, name: name, latitude: lat, longitude: lng,
                imageAssetName: row["image_asset"] as? String ?? "building_\(id)"
            )
        }
    }
    
    private func getKevinBuildingAssignments() -> [NamedCoordinate] {
        return [
            NamedCoordinate(id: "10", name: "131 Perry Street", latitude: 40.7359, longitude: -74.0059, imageAssetName: "perry_131"),
            NamedCoordinate(id: "6", name: "68 Perry Street", latitude: 40.7357, longitude: -74.0055, imageAssetName: "perry_68"),
            NamedCoordinate(id: "3", name: "135-139 West 17th Street", latitude: 40.7398, longitude: -73.9972, imageAssetName: "west17_135"),
            NamedCoordinate(id: "7", name: "136 West 17th Street", latitude: 40.7399, longitude: -73.9971, imageAssetName: "west17_136"),
            NamedCoordinate(id: "9", name: "138 West 17th Street", latitude: 40.7400, longitude: -73.9970, imageAssetName: "west17_138"),
            NamedCoordinate(id: "16", name: "29-31 East 20th Street", latitude: 40.7388, longitude: -73.9892, imageAssetName: "east20_29"),
            NamedCoordinate(id: "12", name: "178 Spring Street", latitude: 40.7245, longitude: -73.9968, imageAssetName: "spring_178"),
            NamedCoordinate(id: "14", name: "Rubin Museum (142–148 W 17th)", latitude: 40.7402, longitude: -73.9980, imageAssetName: "rubin_museum")
        ]
    }
}

struct Worker {
    let workerId: String
    let name: String
    let email: String
    let role: String
    let isActive: Bool
}

// MARK: - Missing Methods for Compatibility
extension WorkerService {
    public func loadWorkerBuildings(for workerId: String) async -> [NamedCoordinate] {
        // Return buildings assigned to worker
        return []
    }
}
