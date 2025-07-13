//
//  InitializationStatus.swift
//  FrancoSphere
//
//  ✅ GRDB VERSION: Updated for GRDB.swift compatibility
//  ✅ CLEAN: No InitializationStatus redeclaration
//  ✅ REAL DATA: Uses actual FrancoSphere building and worker data
//

import Foundation
import GRDB

// MARK: - Import Error Types
enum ImportError: Error, LocalizedError {
    case noGRDBManager
    case invalidData
    case duplicateEntry
    case workerNotFound
    case buildingNotFound
    
    var errorDescription: String? {
        switch self {
        case .noGRDBManager:
            return "GRDB Manager not available"
        case .invalidData:
            return "Invalid data provided for import"
        case .duplicateEntry:
            return "Duplicate entry detected"
        case .workerNotFound:
            return "Worker not found in database"
        case .buildingNotFound:
            return "Building not found in database"
        }
    }
}

// MARK: - Building Data Importer
@MainActor
class BuildingDataImporter {
    private let grdbManager: GRDBManager
    
    init(grdbManager: GRDBManager = GRDBManager.shared) {
        self.grdbManager = grdbManager
    }
    
    func importBuilding(_ building: NamedCoordinate) async throws {
        let imageAssetName = building.imageAssetName ?? "building_default"
        
        try await grdbManager.dbPool.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO buildings (
                    id, name, address, latitude, longitude, imageAssetName
                ) VALUES (?, ?, ?, ?, ?, ?)
                """, arguments: [
                    building.id,
                    building.name,
                    building.address ?? "",
                    building.coordinate.latitude,
                    building.coordinate.longitude,
                    imageAssetName
                ])
        }
        
        print("✅ Imported building: \(building.name)")
    }
    
    func importAllBuildings() async throws {
        print("🏢 Importing all FrancoSphere buildings...")
        
        let buildings = FrancoSphereData.realBuildings
        for building in buildings {
            try await importBuilding(building)
        }
        
        print("✅ Imported \(buildings.count) buildings")
    }
}

// MARK: - Worker Data Importer
@MainActor
class WorkerDataImporter {
    private let grdbManager: GRDBManager
    
    init(grdbManager: GRDBManager = GRDBManager.shared) {
        self.grdbManager = grdbManager
    }
    
    func importWorker(_ worker: WorkerProfile) async throws {
        let passwordHash = "hashed_\(worker.name.lowercased().replacingOccurrences(of: " ", with: ""))_temp"
        
        try await grdbManager.dbPool.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO workers (
                    id, name, email, role, passwordHash, isActive, phone, hourlyRate, skills
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    worker.id,
                    worker.name,
                    worker.email,
                    worker.role,
                    passwordHash,
                    1, // isActive = true
                    worker.phone ?? "",
                    worker.hourlyRate ?? 25.0,
                    (worker.skills ?? []).joined(separator: ",")
                ])
        }
        
        print("✅ Imported worker: \(worker.name)")
    }
    
    func importAllWorkers() async throws {
        print("👷 Importing all FrancoSphere workers...")
        
        let workers = FrancoSphereData.realWorkers
        for worker in workers {
            try await importWorker(worker)
        }
        
        print("✅ Imported \(workers.count) workers")
    }
}

// MARK: - Assignment Data Importer
@MainActor
class AssignmentDataImporter {
    private let grdbManager: GRDBManager
    
    init(grdbManager: GRDBManager = GRDBManager.shared) {
        self.grdbManager = grdbManager
    }
    
    func importAssignment(workerId: String, buildingId: String, workerName: String, buildingName: String) async throws {
        try await grdbManager.dbPool.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO worker_assignments (
                    worker_id, building_id, worker_name, building_name, is_active, start_date
                ) VALUES (?, ?, ?, ?, ?, ?)
                """, arguments: [
                    workerId,
                    buildingId,
                    workerName,
                    buildingName,
                    1, // is_active = true
                    ISO8601DateFormatter().string(from: Date())
                ])
        }
        
        print("✅ Imported assignment: \(workerName) → \(buildingName)")
    }
    
    func importAllAssignments() async throws {
        print("📋 Importing all worker assignments...")
        
        let assignments = FrancoSphereData.realAssignments
        for assignment in assignments {
            try await importAssignment(
                workerId: assignment.workerId,
                buildingId: assignment.buildingId,
                workerName: assignment.workerName,
                buildingName: assignment.buildingName
            )
        }
        
        print("✅ Imported \(assignments.count) assignments")
    }
}

// MARK: - Task Data Importer
@MainActor
class TaskDataImporter {
    private let grdbManager: GRDBManager
    
    init(grdbManager: GRDBManager = GRDBManager.shared) {
        self.grdbManager = grdbManager
    }
    
    func importTask(_ task: ContextualTask) async throws {
        try await grdbManager.dbPool.write { db in
            try db.execute(sql: """
                INSERT OR REPLACE INTO tasks (
                    id, name, description, buildingId, workerId, 
                    category, urgencyLevel, scheduledDate, isCompleted, estimatedDuration
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, arguments: [
                    task.id,
                    task.title,
                    task.description,
                    task.buildingId,
                    task.assignedWorkerId,
                    task.category.rawValue,
                    task.urgency.rawValue,
                    ISO8601DateFormatter().string(from: task.dueDate ?? Date()),
                    task.isCompleted ? 1 : 0,
                    Int(task.estimatedDuration / 60) // Convert seconds to minutes
                ])
        }
        
        print("✅ Imported task: \(task.title)")
    }
}

// MARK: - Inventory Data Importer
@MainActor
class InventoryDataImporter {
    private let grdbManager: GRDBManager
    
    init(grdbManager: GRDBManager = GRDBManager.shared) {
        self.grdbManager = grdbManager
    }
    
    func setupInitialInventory() async throws {
        print("📦 Setting up initial inventory...")
        
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
        
        // Get all buildings from GRDB
        let buildings = try await grdbManager.dbPool.read { db in
            try Row.fetchAll(db, sql: "SELECT id, name FROM buildings")
        }
        
        try await grdbManager.dbPool.write { db in
            // Create inventory table if it doesn't exist
            try db.execute(sql: """
                CREATE TABLE IF NOT EXISTS inventory (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    buildingId TEXT NOT NULL,
                    name TEXT NOT NULL,
                    category TEXT NOT NULL,
                    unit TEXT NOT NULL,
                    quantity INTEGER NOT NULL,
                    minimumQuantity INTEGER NOT NULL,
                    location TEXT DEFAULT 'Storage Room',
                    created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(buildingId, name)
                )
            """)
            
            // Insert default items for each building
            for building in buildings {
                guard let buildingId = building["id"] as? String,
                      let buildingName = building["name"] as? String else { continue }
                
                for (name, category, unit, quantity, minimum) in defaultItems {
                    try db.execute(sql: """
                        INSERT OR IGNORE INTO inventory (
                            buildingId, name, category, unit, 
                            quantity, minimumQuantity, location
                        ) VALUES (?, ?, ?, ?, ?, ?, ?)
                        """, arguments: [
                            buildingId,
                            name,
                            category,
                            unit,
                            quantity,
                            minimum,
                            "Storage Room - \(buildingName)"
                        ])
                }
            }
        }
        
        print("✅ Initial inventory setup complete for \(buildings.count) buildings")
    }
}

// MARK: - Real FrancoSphere Data
struct FrancoSphereData {
    
    // Real building data from your project
    static let realBuildings: [NamedCoordinate] = [
        NamedCoordinate(
            id: "1",
            name: "12 West 18th Street",
            address: "12 West 18th Street, New York, NY 10011",
            latitude: 40.7389,
            longitude: -73.9936
        ),
        NamedCoordinate(
            id: "4",
            name: "131 Perry Street",
            address: "131 Perry Street, New York, NY 10014",
            latitude: 40.7355,
            longitude: -74.0073
        ),
        NamedCoordinate(
            id: "7",
            name: "136 West 17th Street",
            address: "136 West 17th Street, New York, NY 10011",
            latitude: 40.7398,
            longitude: -73.9970
        ),
        NamedCoordinate(
            id: "13",
            name: "104 Franklin Street",
            address: "104 Franklin Street, New York, NY 10013",
            latitude: 40.7181,
            longitude: -74.0044
        ),
        NamedCoordinate(
            id: "14",
            name: "Rubin Museum (142-148 W 17th)",
            address: "142-148 West 17th Street, New York, NY 10011",
            latitude: 40.7401,
            longitude: -73.9978
        ),
        NamedCoordinate(
            id: "17",
            name: "Stuyvesant Cove Park",
            address: "Stuyvesant Cove Park, New York, NY 10009",
            latitude: 40.7325,
            longitude: -73.9741
        )
    ]
    
    // Real worker data from your project
    static let realWorkers: [WorkerProfile] = [
        WorkerProfile(
            id: "1",
            name: "Kevin Dutan",
            email: "kevin.dutan@francosphere.com",
            role: "worker",
            phone: "+1 (555) 0101",
            hourlyRate: 28.0,
            skills: ["cleaning", "sanitation", "operations"]
        ),
        WorkerProfile(
            id: "2",
            name: "Edwin Lema",
            email: "edwin.lema@francosphere.com",
            role: "worker",
            phone: "+1 (555) 0102",
            hourlyRate: 30.0,
            skills: ["maintenance", "repair", "inspection", "park_operations"]
        ),
        WorkerProfile(
            id: "3",
            name: "Mercedes Inamagua",
            email: "mercedes.inamagua@francosphere.com",
            role: "worker",
            phone: "+1 (555) 0103",
            hourlyRate: 26.0,
            skills: ["cleaning", "maintenance"]
        ),
        WorkerProfile(
            id: "4",
            name: "Luis Lopez",
            email: "luis.lopez@francosphere.com",
            role: "worker",
            phone: "+1 (555) 0104",
            hourlyRate: 25.0,
            skills: ["cleaning", "sanitation", "operations"]
        ),
        WorkerProfile(
            id: "5",
            name: "Angel Guirachocha",
            email: "angel.guirachocha@francosphere.com",
            role: "worker",
            phone: "+1 (555) 0105",
            hourlyRate: 27.0,
            skills: ["sanitation", "operations", "inspection"]
        ),
        WorkerProfile(
            id: "6",
            name: "Greg Hutson",
            email: "greg.hutson@francosphere.com",
            role: "worker",
            phone: "+1 (555) 0106",
            hourlyRate: 29.0,
            skills: ["cleaning", "sanitation", "maintenance", "operations"]
        ),
        WorkerProfile(
            id: "7",
            name: "Shawn Magloire",
            email: "shawn.magloire@francosphere.com",
            role: "admin",
            phone: "+1 (555) 0107",
            hourlyRate: 45.0,
            skills: ["maintenance", "management", "inspection", "system_admin"]
        )
    ]
    
    // Real assignment data
    static let realAssignments: [WorkerAssignment] = [
        // Kevin Dutan - Building specialist
        WorkerAssignment(workerId: "1", buildingId: "1", workerName: "Kevin Dutan", buildingName: "12 West 18th Street"),
        WorkerAssignment(workerId: "1", buildingId: "4", workerName: "Kevin Dutan", buildingName: "131 Perry Street"),
        WorkerAssignment(workerId: "1", buildingId: "7", workerName: "Kevin Dutan", buildingName: "136 West 17th Street"),
        WorkerAssignment(workerId: "1", buildingId: "14", workerName: "Kevin Dutan", buildingName: "Rubin Museum"),
        
        // Edwin Lema - Park and maintenance specialist
        WorkerAssignment(workerId: "2", buildingId: "7", workerName: "Edwin Lema", buildingName: "136 West 17th Street"),
        WorkerAssignment(workerId: "2", buildingId: "13", workerName: "Edwin Lema", buildingName: "104 Franklin Street"),
        WorkerAssignment(workerId: "2", buildingId: "17", workerName: "Edwin Lema", buildingName: "Stuyvesant Cove Park"),
        
        // Mercedes Inamagua - General assignments
        WorkerAssignment(workerId: "3", buildingId: "7", workerName: "Mercedes Inamagua", buildingName: "136 West 17th Street"),
        WorkerAssignment(workerId: "3", buildingId: "13", workerName: "Mercedes Inamagua", buildingName: "104 Franklin Street"),
        WorkerAssignment(workerId: "3", buildingId: "14", workerName: "Mercedes Inamagua", buildingName: "Rubin Museum"),
        
        // Other workers
        WorkerAssignment(workerId: "4", buildingId: "13", workerName: "Luis Lopez", buildingName: "104 Franklin Street"),
        WorkerAssignment(workerId: "5", buildingId: "1", workerName: "Angel Guirachocha", buildingName: "12 West 18th Street"),
        WorkerAssignment(workerId: "6", buildingId: "1", workerName: "Greg Hutson", buildingName: "12 West 18th Street"),
        WorkerAssignment(workerId: "7", buildingId: "1", workerName: "Shawn Magloire", buildingName: "12 West 18th Street"),
        WorkerAssignment(workerId: "7", buildingId: "7", workerName: "Shawn Magloire", buildingName: "136 West 17th Street")
    ]
}

// MARK: - Supporting Types
struct WorkerAssignment {
    let workerId: String
    let buildingId: String
    let workerName: String
    let buildingName: String
}
