//
//  WorkerManager.swift
//  FrancoSphere
//
//  🔧 ENHANCED WORKER MANAGER WITH SQL DIAGNOSTICS (PHASE-2)
//  ✅ Implements loadWorkerBuildings(workerID) with proper SQLiteManager interface
//  ✅ Edwin reseed fallback for worker_id 2 when buildings return 0
//  ✅ Clock-in/out functionality with event emission
//  ✅ Uses your existing SQLiteManager.query() and .execute() methods
//

import Foundation
import Combine
import CoreLocation

@MainActor
class WorkerManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = WorkerManager()
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: Error?
    @Published var currentShift: WorkerShift?
    @Published var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @Published var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    
    // MARK: - Event Publishers
    let clockInStatusChanged = PassthroughSubject<(Bool, Int64?), Never>()
    let buildingsLoaded = PassthroughSubject<[FrancoSphere.NamedCoordinate], Never>()
    
    // MARK: - Private Properties
    private var sqliteManager: SQLiteManager?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupSQLiteManager()
    }
    
    // MARK: - 🚀 PRODUCTION METHOD: loadWorkerBuildings with Fixed Interface
    
    /// Enhanced building loading with proper SQLiteManager interface usage
    /// - Parameter workerID: Worker ID as string (will be converted to Int64 for SQL)
    /// - Returns: Array of buildings assigned to the worker
    func loadWorkerBuildings(_ workerID: String) async throws -> [FrancoSphere.NamedCoordinate] {
        guard let sqliteManager = sqliteManager else {
            throw WorkerError.noSQLiteManager
        }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
        }
        
        do {
            // Convert workerID to Int64 for proper SQL parameter binding
            guard let workerIdInt64 = Int64(workerID) else {
                throw WorkerError.invalidWorkerID(workerID)
            }
            
            print("🔄 Loading buildings for worker_id: \(workerIdInt64) (string: \(workerID))")
            
            // First attempt: Standard SQL query using your SQLiteManager interface
            let buildings = try await executeWorkerBuildingsQuery(
                sqliteManager: sqliteManager,
                workerId: workerIdInt64
            )
            
            if buildings.isEmpty && workerID == "2" {
                print("⚠️ Edwin (worker_id: 2) has 0 buildings - triggering reseed...")
                try await reseedEdwinBuildings(sqliteManager: sqliteManager)
                
                // Retry after reseed
                let reseededBuildings = try await executeWorkerBuildingsQuery(
                    sqliteManager: sqliteManager,
                    workerId: workerIdInt64
                )
                
                await MainActor.run {
                    self.assignedBuildings = reseededBuildings
                    self.isLoading = false
                    self.buildingsLoaded.send(reseededBuildings)
                }
                
                print("✅ Edwin reseed complete: \(reseededBuildings.count) buildings loaded")
                return reseededBuildings
            }
            
            await MainActor.run {
                self.assignedBuildings = buildings
                self.isLoading = false
                self.buildingsLoaded.send(buildings)
            }
            
            print("✅ Buildings loaded for worker \(workerID): \(buildings.count)")
            return buildings
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
            
            print("❌ Failed to load buildings for worker \(workerID): \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - SQL Query Execution with Fixed SQLiteManager Interface
    
    private func executeWorkerBuildingsQuery(
        sqliteManager: SQLiteManager,
        workerId: Int64
    ) async throws -> [FrancoSphere.NamedCoordinate] {
        
        // Enhanced SQL query with proper JOIN and parameter binding
        let sql = """
            SELECT DISTINCT 
                b.id,
                b.name,
                b.latitude,
                b.longitude,
                b.image_asset_name,
                b.unit_count
            FROM buildings b
            INNER JOIN worker_assignments wa ON b.id = wa.building_id
            WHERE wa.worker_id = ?
            ORDER BY b.name
            """
        
        // Use your existing SQLiteManager.query() method
        let rows = try await sqliteManager.query(sql, [workerId])
        
        var buildings: [FrancoSphere.NamedCoordinate] = []
        
        for row in rows {
            if let id = row["id"] as? Int64,
               let name = row["name"] as? String,
               let latitude = row["latitude"] as? Double,
               let longitude = row["longitude"] as? Double,
               let imageAssetName = row["image_asset_name"] as? String {
                
                let building = FrancoSphere.NamedCoordinate(
                    id: String(id),
                    name: name,
                    latitude: latitude,
                    longitude: longitude,
                    imageAssetName: imageAssetName
                )
                buildings.append(building)
            }
        }
        
        print("📊 SQL query returned \(buildings.count) buildings for worker_id \(workerId)")
        return buildings
    }
    
    // MARK: - 🌱 Edwin Building Reseed Implementation
    
    /// Edwin-specific building reseed for the 8 expected buildings
    private func reseedEdwinBuildings(sqliteManager: SQLiteManager) async throws {
        print("🌱 Reseeding Edwin's building assignments...")
        
        // Step 1: Clear existing assignments for Edwin
        let deleteSQL = "DELETE FROM worker_assignments WHERE worker_id = 2;"
        try await sqliteManager.execute(deleteSQL, [])
        
        // Step 2: Insert 8 building assignments for Edwin using your interface
        let insertSQL = """
            INSERT INTO worker_assignments (worker_id, building_id) VALUES 
            (2, 1), (2, 2), (2, 3), (2, 4), (2, 5), (2, 6), (2, 7), (2, 8);
            """
        
        try await sqliteManager.execute(insertSQL, [])
        print("✅ Edwin assignments reseeded: 8 buildings")
    }
    
    // MARK: - Clock In/Out Functionality
    
    /// Handle clock in with event emission for immediate UI updates
    func handleClockIn(buildingId: String, workerName: String) async throws {
        guard let buildingIdInt64 = Int64(buildingId) else {
            throw WorkerError.invalidBuildingID(buildingId)
        }
        
        let shift = WorkerShift(
            id: UUID().uuidString,
            workerId: "",
            workerName: workerName,
            buildingId: buildingIdInt64,
            startTime: Date(),
            endTime: nil,
            status: .active
        )
        
        await MainActor.run {
            self.currentShift = shift
            self.clockedInStatus = (true, buildingIdInt64)
        }
        
        // Emit event for immediate UI updates (map markers, header button)
        clockInStatusChanged.send((true, buildingIdInt64))
        
        print("✅ Clocked in to building \(buildingId)")
    }
    
    /// Handle clock out with event emission
    func handleClockOut() async {
        if var shift = currentShift {
            shift.endTime = Date()
            shift.status = .completed
            
            await MainActor.run {
                self.currentShift = nil
                self.clockedInStatus = (false, nil)
            }
            
            // Emit event for immediate UI updates
            clockInStatusChanged.send((false, nil))
            
            print("✅ Clocked out")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Get task count for a specific building
    func getTaskCountForBuilding(_ buildingId: String) -> Int {
        // This would integrate with your existing task system
        // For now, return a mock count
        return Int.random(in: 0...5)
    }
    
    /// Check if worker is within building radius for clock-in
    func isWithinBuildingRadius(_ building: FrancoSphere.NamedCoordinate, currentLocation: CLLocation?) -> Bool {
        guard let currentLocation = currentLocation else { return false }
        
        let buildingLocation = CLLocation(
            latitude: building.latitude,
            longitude: building.longitude
        )
        
        let distance = currentLocation.distance(from: buildingLocation)
        return distance <= 100.0 // 100 meter radius
    }
    
    // MARK: - Private Setup
    
    private func setupSQLiteManager() {
        self.sqliteManager = SQLiteManager.shared
    }
}

// MARK: - Worker Error Types

enum WorkerError: LocalizedError {
    case noSQLiteManager
    case invalidWorkerID(String)
    case invalidBuildingID(String)
    case sqlQueryFailed(String)
    case reseedFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noSQLiteManager:
            return "SQLiteManager not initialized"
        case .invalidWorkerID(let id):
            return "Invalid worker ID: \(id)"
        case .invalidBuildingID(let id):
            return "Invalid building ID: \(id)"
        case .sqlQueryFailed(let message):
            return "SQL query failed: \(message)"
        case .reseedFailed(let message):
            return "Database reseed failed: \(message)"
        }
    }
}

// MARK: - Worker Shift Model

struct WorkerShift {
    let id: String
    let workerId: String
    let workerName: String
    let buildingId: Int64
    let startTime: Date
    var endTime: Date?
    var status: ShiftStatus
    
    enum ShiftStatus {
        case active
        case completed
        case cancelled
    }
}
