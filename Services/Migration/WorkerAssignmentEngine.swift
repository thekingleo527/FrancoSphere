//
//  WorkerAssignmentEngine.swift
//  FrancoSphere
//
//  ✅ V6.0: GRDB Migration - Dynamic Worker Assignment System
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: Uses existing SQLiteManager method signatures
//  ✅ ENHANCED: Supports three-dashboard worker assignment workflows
//

import Foundation
import GRDB

// MARK: - BuildingWorkerAssignment Type Definition
public struct BuildingWorkerAssignment: Codable, Identifiable {
    public let id: Int64
    public let buildingId: Int64
    public let workerId: Int64
    public let role: String
    public let assignedDate: Date
    public let isActive: Bool
    
    public init(id: Int64, buildingId: Int64, workerId: Int64, role: String, assignedDate: Date, isActive: Bool) {
        self.id = id
        self.buildingId = buildingId
        self.workerId = workerId
        self.role = role
        self.assignedDate = assignedDate
        self.isActive = isActive
    }
}

// MARK: - WorkerAssignmentEngine Actor
actor WorkerAssignmentEngine {
    static let shared = WorkerAssignmentEngine()
    private let sqliteManager = SQLiteManager.shared

    private init() {}

    // MARK: - Core Assignment Logic (GRDB-Powered)

    /// Assigns a worker to a building with a specific role using GRDB transactions.
    /// This is the new, authoritative method for creating assignments.
    func assignWorkerToBuilding(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        role: String, // e.g., "Lead Maintenance", "Sanitation Specialist", "Museum Specialist"
        startDate: Date = Date()
    ) async throws {
        print("⚙️ Assigning worker \(workerId) to building \(buildingId) with role: \(role)")

        // Use SQLiteManager async method with correct parameter format
        try await sqliteManager.executeAsync("""
            INSERT OR REPLACE INTO worker_building_assignments
            (worker_id, building_id, assignment_type, start_date, is_active)
            VALUES (?, ?, ?, ?, 1)
        """, parameters: [
            workerId,
            buildingId,
            role,
            ISO8601DateFormatter().string(from: startDate)
        ])
        
        // Also update the worker_assignments table for compatibility
        try await sqliteManager.executeAsync("""
            INSERT OR REPLACE INTO worker_assignments
            (worker_id, building_id, worker_name, is_active)
            VALUES (?, ?, (SELECT name FROM workers WHERE id = ?), 1)
        """, parameters: [
            workerId,
            buildingId,
            workerId
        ])
        
        print("✅ Worker assignment completed and synced to both tables")
    }

    /// Retrieves all active assignments for a given worker using GRDB.
    func getAssignments(for workerId: CoreTypes.WorkerID) async throws -> [BuildingWorkerAssignment] {
        let rows = try await sqliteManager.queryAsync("""
            SELECT 
                wba.id,
                wba.worker_id,
                wba.building_id,
                wba.assignment_type,
                wba.start_date,
                wba.is_active,
                w.name as worker_name,
                b.name as building_name
            FROM worker_building_assignments wba
            LEFT JOIN workers w ON CAST(wba.worker_id AS TEXT) = CAST(w.id AS TEXT)
            LEFT JOIN buildings b ON CAST(wba.building_id AS TEXT) = CAST(b.id AS TEXT)
            WHERE wba.worker_id = ? AND wba.is_active = 1
            ORDER BY wba.start_date DESC
        """, parameters: [workerId])

        return rows.compactMap { row -> BuildingWorkerAssignment? in
            guard let assignmentId = row["id"] as? Int64,
                  let buildingIdString = row["building_id"] as? String,
                  let buildingId = Int64(buildingIdString),
                  let workerIdString = row["worker_id"] as? String,
                  let workerIdInt = Int64(workerIdString),
                  let role = row["assignment_type"] as? String,
                  let dateString = row["start_date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString)
            else {
                print("⚠️ Skipping malformed assignment row")
                return nil
            }

            return BuildingWorkerAssignment(
                id: assignmentId,
                buildingId: buildingId,
                workerId: workerIdInt,
                role: role,
                assignedDate: date,
                isActive: true
            )
        }
    }
    
    /// Gets all workers assigned to a specific building using GRDB.
    func getWorkersForBuilding(_ buildingId: CoreTypes.BuildingID) async throws -> [WorkerAssignmentInfo] {
        let rows = try await sqliteManager.queryAsync("""
            SELECT 
                wba.worker_id,
                wba.assignment_type,
                wba.start_date,
                w.name as worker_name,
                w.email as worker_email,
                w.role as worker_role
            FROM worker_building_assignments wba
            LEFT JOIN workers w ON CAST(wba.worker_id AS TEXT) = CAST(w.id AS TEXT)
            WHERE wba.building_id = ? AND wba.is_active = 1
            ORDER BY wba.start_date ASC
        """, parameters: [buildingId])
        
        return rows.compactMap { row -> WorkerAssignmentInfo? in
            guard let workerIdString = row["worker_id"] as? String,
                  let assignmentType = row["assignment_type"] as? String,
                  let workerName = row["worker_name"] as? String
            else { return nil }
            
            return WorkerAssignmentInfo(
                workerId: workerIdString,
                workerName: workerName,
                workerEmail: row["worker_email"] as? String ?? "",
                assignmentType: assignmentType,
                startDate: ISO8601DateFormatter().date(from: row["start_date"] as? String ?? "") ?? Date()
            )
        }
    }
}

// MARK: - Supporting Types (GRDB-Enhanced)

/// Information about a worker assignment
public struct WorkerAssignmentInfo {
    public let workerId: String
    public let workerName: String
    public let workerEmail: String
    public let assignmentType: String
    public let startDate: Date
    
    public init(workerId: String, workerName: String, workerEmail: String, assignmentType: String, startDate: Date) {
        self.workerId = workerId
        self.workerName = workerName
        self.workerEmail = workerEmail
        self.assignmentType = assignmentType
        self.startDate = startDate
    }
}

/// Assignment statistics for reporting
public struct AssignmentStatistics {
    public let uniqueWorkers: Int
    public let uniqueBuildings: Int
    public let totalAssignments: Int
    public let averageAssignmentAgeDays: Double
    
    public init(uniqueWorkers: Int, uniqueBuildings: Int, totalAssignments: Int, averageAssignmentAgeDays: Double) {
        self.uniqueWorkers = uniqueWorkers
        self.uniqueBuildings = uniqueBuildings
        self.totalAssignments = totalAssignments
        self.averageAssignmentAgeDays = averageAssignmentAgeDays
    }
}

/// Enhanced error handling for GRDB operations
enum WorkerAssignmentError: LocalizedError {
    case insufficientSkills
    case buildingNotAvailable
    case workerNotFound(String)
    case buildingNotFound(String)
    case databaseError(String)
    case grdbTransactionFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientSkills:
            return "The worker does not have the required skills for this building."
        case .buildingNotAvailable:
            return "The specified building is not available for assignment."
        case .workerNotFound(let id):
            return "Worker with ID \(id) not found in GRDB database."
        case .buildingNotFound(let id):
            return "Building with ID \(id) not found in GRDB database."
        case .databaseError(let message):
            return "GRDB database error: \(message)"
        case .grdbTransactionFailed:
            return "GRDB transaction failed during assignment operation."
        }
    }
}
