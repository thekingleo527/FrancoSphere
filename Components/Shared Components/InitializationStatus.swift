// UPDATED: Using centralized TypeRegistry for all types
//
// DataImporters.swift
// FrancoSphere Data Importers and Types
//
// ✅ CLEAN VERSION: No InitializationStatus redeclaration
// ✅ PRESERVES: All existing importer functionality
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Building Data Importer
@MainActor
class BuildingDataImporter {
    private let sqliteManager: SQLiteManager
    
    init(sqliteManager: SQLiteManager) {
        self.sqliteManager = sqliteManager
    }
    
    func importBuilding(_ building: FrancoSphereModels.NamedCoordinate) async throws {
        // Map the building data to database format
        let imageAssetName = building.imageAssetName ?? "building_default"
        
        try await sqliteManager.execute("""
            INSERT OR REPLACE INTO buildings (
                id, name, address, latitude, longitude, imageAssetName
            ) VALUES (?, ?, ?, ?, ?, ?)
            """, [
                building.id,
                building.name,
                building.address ?? "",
                building.coordinate.latitude,
                building.coordinate.longitude,
                imageAssetName
            ])
        
        print("✅ Imported building: \(building.name)")
    }
}

// MARK: - Worker Data Importer
@MainActor
class WorkerDataImporter {
    var sqliteManager: SQLiteManager?
    
    init() {}
    
    func importWorker(_ worker: FrancoSphereModels.Worker) async throws {
        guard let sqliteManager = sqliteManager else {
            throw ImportError.noSQLiteManager
        }
        
        // Generate a simple password hash (in production, use proper hashing)
        let passwordHash = "hashed_\(worker.name.lowercased().replacingOccurrences(of: " ", with: ""))_temp"
        
        try await sqliteManager.execute("""
            INSERT OR REPLACE INTO workers (
                id, name, email, role, passwordHash
            ) VALUES (?, ?, ?, ?, ?)
            """, [
                worker.id,
                worker.name,
                worker.email,
                worker.role.rawValue,
                passwordHash
            ])
        
        print("✅ Imported worker: \(worker.name)")
    }
}

// MARK: - Inventory Data Importer
@MainActor
class InventoryDataImporter {
    private let sqliteManager: SQLiteManager
    
    init(sqliteManager: SQLiteManager) {
        self.sqliteManager = sqliteManager
    }
    
    func setupInitialInventory() async throws {
        // Default inventory items for each building
        let defaultItems = [
            ("Cleaning Supplies", "Cleaning", "unit", 10, 5),
            ("Trash Bags", "Sanitation", "box", 5, 2),
            ("Light Bulbs", "Maintenance", "unit", 20, 10),
            ("Paper Towels", "Cleaning", "roll", 12, 6),
            ("Hand Soap", "Cleaning", "bottle", 8, 4),
            ("Floor Cleaner", "Cleaning", "gallon", 4, 2),
            ("Glass Cleaner", "Cleaning", "bottle", 6, 3),
            ("Toilet Paper", "Sanitation", "roll", 24, 12),
            ("Mop Heads", "Cleaning", "unit", 4, 2),
            ("Safety Cones", "Safety", "unit", 4, 2)
        ]
        
        // Get all buildings
        let buildings = try await sqliteManager.query("SELECT id FROM buildings", [])
        
        for building in buildings {
            guard let buildingId = building["id"] as? Int64 else { continue }
            
            for (name, category, unit, quantity, minimum) in defaultItems {
                try await sqliteManager.execute("""
                    INSERT OR IGNORE INTO inventory (
                        buildingId, name, category, unit, 
                        quantity, minimumQuantity, location
                    ) VALUES (?, ?, ?, ?, ?, ?, ?)
                    """, [
                        String(buildingId),
                        name,
                        category,
                        unit,
                        quantity,
                        minimum,
                        "Storage Room"
                    ])
            }
        }
        
        print("✅ Initial inventory setup complete")
    }
}

// MARK: - Error Types

// MARK: - FrancoSphere Models Namespace
// This should match your existing models structure
enum FrancoSphereModels {
    
    // Building coordinate model
    struct NamedCoordinate {
        let id: Int
        let name: String
        let coordinate: Coordinate
        let address: String?
        let imageAssetName: String?
    }
    
    struct Coordinate {
        let latitude: Double
        let longitude: Double
    }
    
    // Worker model
    struct Worker {
        let id: Int
        let name: String
        let email: String
        let role: WorkerRole
        let skills: [String]
        let assignedBuildings: [Int]
    }
    
    enum WorkerRole: String {
        case worker = "worker"
        case supervisor = "supervisor"
        case admin = "admin"
    }
    
    // Static data collections
    struct FrancoSphere {
        // Building data
        static let namedCoordinates: [NamedCoordinate] = [
            NamedCoordinate(
                id: 1,
                name: "12 West 18th Street",
                coordinate: Coordinate(latitude: 40.7389, longitude: -73.9936),
                address: "12 West 18th Street, New York, NY 10011",
                imageAssetName: "building_12_w_18th"
            ),
            NamedCoordinate(
                id: 2,
                name: "29-31 East 20th Street",
                coordinate: Coordinate(latitude: 40.7386, longitude: -73.9883),
                address: "29-31 East 20th Street, New York, NY 10003",
                imageAssetName: "building_29_31_e_20th"
            ),
            NamedCoordinate(
                id: 3,
                name: "36 Walker Street",
                coordinate: Coordinate(latitude: 40.7171, longitude: -74.0026),
                address: "36 Walker Street, New York, NY 10013",
                imageAssetName: "building_36_walker"
            ),
            NamedCoordinate(
                id: 4,
                name: "41 Elizabeth Street",
                coordinate: Coordinate(latitude: 40.7178, longitude: -73.9965),
                address: "41 Elizabeth Street, New York, NY 10013",
                imageAssetName: "building_41_elizabeth"
            ),
            NamedCoordinate(
                id: 5,
                name: "68 Perry Street",
                coordinate: Coordinate(latitude: 40.7351, longitude: -74.0041),
                address: "68 Perry Street, New York, NY 10014",
                imageAssetName: "building_68_perry"
            ),
            NamedCoordinate(
                id: 6,
                name: "104 Franklin Street",
                coordinate: Coordinate(latitude: 40.7181, longitude: -74.0044),
                address: "104 Franklin Street, New York, NY 10013",
                imageAssetName: "building_104_franklin"
            ),
            NamedCoordinate(
                id: 7,
                name: "112 West 18th Street",
                coordinate: Coordinate(latitude: 40.7402, longitude: -73.9954),
                address: "112 West 18th Street, New York, NY 10011",
                imageAssetName: "building_112_w_18th"
            ),
            NamedCoordinate(
                id: 8,
                name: "117 West 17th Street",
                coordinate: Coordinate(latitude: 40.7396, longitude: -73.9962),
                address: "117 West 17th Street, New York, NY 10011",
                imageAssetName: "building_117_w_17th"
            ),
            NamedCoordinate(
                id: 9,
                name: "123 1st Avenue",
                coordinate: Coordinate(latitude: 40.7267, longitude: -73.9849),
                address: "123 1st Avenue, New York, NY 10009",
                imageAssetName: "building_123_1st_ave"
            ),
            NamedCoordinate(
                id: 10,
                name: "131 Perry Street",
                coordinate: Coordinate(latitude: 40.7355, longitude: -74.0073),
                address: "131 Perry Street, New York, NY 10014",
                imageAssetName: "building_131_perry"
            ),
            NamedCoordinate(
                id: 11,
                name: "133 East 15th Street",
                coordinate: Coordinate(latitude: 40.7343, longitude: -73.9877),
                address: "133 East 15th Street, New York, NY 10003",
                imageAssetName: "building_133_e_15th"
            ),
            NamedCoordinate(
                id: 12,
                name: "135-139 West 17th Street",
                coordinate: Coordinate(latitude: 40.7399, longitude: -73.9972),
                address: "135-139 West 17th Street, New York, NY 10011",
                imageAssetName: "building_135_139_w_17th"
            ),
            NamedCoordinate(
                id: 13,
                name: "136 West 17th Street",
                coordinate: Coordinate(latitude: 40.7398, longitude: -73.9970),
                address: "136 West 17th Street, New York, NY 10011",
                imageAssetName: "building_136_w_17th"
            ),
            NamedCoordinate(
                id: 14,
                name: "138 West 17th Street",
                coordinate: Coordinate(latitude: 40.7399, longitude: -73.9974),
                address: "138 West 17th Street, New York, NY 10011",
                imageAssetName: "building_138_w_17th"
            ),
            NamedCoordinate(
                id: 15,
                name: "Rubin Museum (142-148 W 17th)",
                coordinate: Coordinate(latitude: 40.7401, longitude: -73.9978),
                address: "142-148 West 17th Street, New York, NY 10011",
                imageAssetName: "building_rubin_museum"
            ),
            NamedCoordinate(
                id: 16,
                name: "Stuyvesant Cove Park",
                coordinate: Coordinate(latitude: 40.7325, longitude: -73.9741),
                address: "Stuyvesant Cove Park, New York, NY 10009",
                imageAssetName: "stuyvesant_cove_park"
            ),
            NamedCoordinate(
                id: 17,
                name: "178 Spring Street",
                coordinate: Coordinate(latitude: 40.7254, longitude: -74.0031),
                address: "178 Spring Street, New York, NY 10012",
                imageAssetName: "building_178_spring"
            ),
            NamedCoordinate(
                id: 18,
                name: "115 7th Avenue",
                coordinate: Coordinate(latitude: 40.7398, longitude: -73.9999),
                address: "115 7th Avenue, New York, NY 10011",
                imageAssetName: "building_115_7th_ave"
            )
        ]
        
        // Worker data
        static let workers: [Worker] = [
            Worker(
                id: 1,
                name: "Kevin Dutan",
                email: "kevin.dutan@francosphere.com",
                role: .worker,
                skills: ["cleaning", "sanitation", "operations"],
                assignedBuildings: [1, 5, 8, 10, 12, 13, 14, 17]
            ),
            Worker(
                id: 2,
                name: "Mercedes Inamagua",
                email: "mercedes.inamagua@francosphere.com",
                role: .worker,
                skills: ["cleaning", "maintenance"],
                assignedBuildings: [6, 7, 8, 12, 13, 14, 15]
            ),
            Worker(
                id: 3,
                name: "Edwin Lema",
                email: "edwin.lema@francosphere.com",
                role: .worker,
                skills: ["maintenance", "repair", "inspection"],
                assignedBuildings: [7, 8, 10, 11, 12, 14, 16]
            ),
            Worker(
                id: 4,
                name: "Luis Lopez",
                email: "luis.lopez@francosphere.com",
                role: .worker,
                skills: ["cleaning", "sanitation", "operations"],
                assignedBuildings: [3, 4, 6]
            ),
            Worker(
                id: 5,
                name: "Angel Guirachocha",
                email: "angel.guirachocha@francosphere.com",
                role: .worker,
                skills: ["sanitation", "operations", "inspection"],
                assignedBuildings: [1, 5, 6, 9, 12]
            ),
            Worker(
                id: 6,
                name: "Greg Hutson",
                email: "greg.hutson@francosphere.com",
                role: .worker,
                skills: ["cleaning", "sanitation", "maintenance", "operations"],
                assignedBuildings: [1]
            ),
            Worker(
                id: 7,
                name: "Shawn Magloire",
                email: "shawn.magloire@francosphere.com",
                role: .admin,
                skills: ["maintenance", "management", "inspection"],
                assignedBuildings: [1, 7, 8, 11, 13, 14, 18]
            )
        ]
    }
}
