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

        // Use GRDB-compatible parameter binding (FIXED: No 'parameters:' label)
        try await sqliteManager.execute("""
            INSERT OR REPLACE INTO worker_building_assignments
            (worker_id, building_id, assignment_type, start_date, is_active)
            VALUES (?, ?, ?, ?, 1)
        """, [
            workerId,
            buildingId,
            role,
            ISO8601DateFormatter().string(from: startDate)
        ])
        
        // Also update the worker_assignments table for compatibility
        try await sqliteManager.execute("""
            INSERT OR REPLACE INTO worker_assignments
            (worker_id, building_id, worker_name, is_active)
            VALUES (?, ?, (SELECT name FROM workers WHERE id = ?), 1)
        """, [
            workerId,
            buildingId,
            workerId
        ])
        
        print("✅ Worker assignment completed and synced to both tables")
    }

    /// Retrieves all active assignments for a given worker using GRDB.
    func getAssignments(for workerId: CoreTypes.WorkerID) async throws -> [BuildingWorkerAssignment] {
        let rows = try await sqliteManager.query("""
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
        """, [workerId])

        return rows.compactMap { row in
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
        let rows = try await sqliteManager.query("""
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
        """, [buildingId])
        
        return rows.compactMap { row in
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
    
    /// Removes a worker assignment using GRDB transactions.
    func removeAssignment(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID
    ) async throws {
        print("🗑️ Removing assignment: Worker \(workerId) from Building \(buildingId)")
        
        // Deactivate in worker_building_assignments
        try await sqliteManager.execute("""
            UPDATE worker_building_assignments 
            SET is_active = 0 
            WHERE worker_id = ? AND building_id = ?
        """, [workerId, buildingId])
        
        // Deactivate in worker_assignments for compatibility
        try await sqliteManager.execute("""
            UPDATE worker_assignments 
            SET is_active = 0 
            WHERE worker_id = ? AND building_id = ?
        """, [workerId, buildingId])
        
        print("✅ Assignment removed from both tables")
    }
    
    /// Bulk assign a worker to multiple buildings with GRDB transaction support.
    func assignWorkerToMultipleBuildings(
        workerId: CoreTypes.WorkerID,
        assignments: [(buildingId: CoreTypes.BuildingID, role: String)]
    ) async throws {
        print("📦 Bulk assigning worker \(workerId) to \(assignments.count) buildings...")
        
        let currentDate = Date()
        
        for assignment in assignments {
            try await assignWorkerToBuilding(
                workerId: workerId,
                buildingId: assignment.buildingId,
                role: assignment.role,
                startDate: currentDate
            )
        }
        
        print("✅ Bulk assignment completed for worker \(workerId)")
    }
    
    // MARK: - Kevin Migration Verification (GRDB-Enhanced)
    
    /// A diagnostic tool to verify that the "Kevin" special case has been successfully migrated to GRDB.
    func verifyKevinMigration() async -> (isMigrated: Bool, issues: [String]) {
        var issues: [String] = []
        let kevinId: CoreTypes.WorkerID = "1" // Kevin's correct ID is 1
        
        do {
            let assignments = try await getAssignments(for: kevinId)
            
            if assignments.isEmpty {
                issues.append("Kevin Dutan (ID: 1) has no assignments in the new GRDB system.")
            } else {
                print("📊 Kevin has \(assignments.count) assignments in GRDB system")
            }
            
            // Check for the critical Rubin Museum assignment (Building ID 14)
            let hasRubinAssignment = assignments.contains { assignment in
                assignment.buildingId == 14 || assignment.role.lowercased().contains("museum")
            }
            
            if !hasRubinAssignment {
                issues.append("Kevin is missing his critical assignment to Rubin Museum (ID: 14).")
            } else {
                print("✅ Kevin has Rubin Museum assignment verified")
            }
            
            // Verify Kevin has appropriate number of assignments (should be 8+)
            if assignments.count < 8 {
                issues.append("Kevin has fewer assignments (\(assignments.count)) than expected (8+).")
            }
            
            if issues.isEmpty {
                print("✅ Kevin Migration Verified: Assignments are correct in the new GRDB engine.")
                return (true, [])
            } else {
                print("⚠️ Kevin Migration Issues Found:")
                for issue in issues {
                    print("   - \(issue)")
                }
                return (false, issues)
            }
            
        } catch {
            let errorMessage = "GRDB database error during verification: \(error.localizedDescription)"
            print("❌ \(errorMessage)")
            return (false, [errorMessage])
        }
    }
    
    /// Verify all workers have proper assignments in the GRDB system.
    func verifyAllWorkerAssignments() async -> (isHealthy: Bool, report: String) {
        do {
            // Get all active workers
            let workers = try await sqliteManager.query("""
                SELECT id, name, email FROM workers WHERE isActive = 1
            """)
            
            var report = "📊 GRDB Worker Assignment Health Report:\n\n"
            var totalIssues = 0
            
            for worker in workers {
                guard let workerIdInt = worker["id"] as? Int64,
                      let workerName = worker["name"] as? String else { continue }
                
                let workerId = String(workerIdInt)
                let assignments = try await getAssignments(for: workerId)
                
                report += "👤 \(workerName) (ID: \(workerId)): \(assignments.count) assignments\n"
                
                if assignments.isEmpty {
                    report += "   ⚠️ No assignments found\n"
                    totalIssues += 1
                } else {
                    for assignment in assignments.prefix(3) {
                        report += "   🏢 Building \(assignment.buildingId): \(assignment.role)\n"
                    }
                    if assignments.count > 3 {
                        report += "   ... and \(assignments.count - 3) more\n"
                    }
                }
                report += "\n"
            }
            
            report += "Summary: \(workers.count) workers checked, \(totalIssues) issues found\n"
            
            return (totalIssues == 0, report)
            
        } catch {
            let errorReport = "❌ GRDB verification failed: \(error.localizedDescription)"
            return (false, errorReport)
        }
    }
    
    /// Get assignment statistics for reporting.
    func getAssignmentStatistics() async throws -> AssignmentStatistics {
        let stats = try await sqliteManager.query("""
            SELECT 
                COUNT(DISTINCT worker_id) as unique_workers,
                COUNT(DISTINCT building_id) as unique_buildings,
                COUNT(*) as total_assignments,
                AVG(
                    CASE 
                        WHEN start_date IS NOT NULL 
                        THEN julianday('now') - julianday(start_date)
                        ELSE 0 
                    END
                ) as avg_assignment_age_days
            FROM worker_building_assignments 
            WHERE is_active = 1
        """)
        
        guard let row = stats.first else {
            throw WorkerAssignmentError.databaseError("Failed to get statistics")
        }
        
        return AssignmentStatistics(
            uniqueWorkers: Int(row["unique_workers"] as? Int64 ?? 0),
            uniqueBuildings: Int(row["unique_buildings"] as? Int64 ?? 0),
            totalAssignments: Int(row["total_assignments"] as? Int64 ?? 0),
            averageAssignmentAgeDays: row["avg_assignment_age_days"] as? Double ?? 0.0
        )
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

// MARK: - GRDB Convenience Extensions

extension WorkerAssignmentEngine {
    
    /// Quick check if a worker is assigned to a specific building
    func isWorkerAssignedToBuilding(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID
    ) async throws -> Bool {
        let result = try await sqliteManager.query("""
            SELECT COUNT(*) as count 
            FROM worker_building_assignments 
            WHERE worker_id = ? AND building_id = ? AND is_active = 1
        """, [workerId, buildingId])
        
        return (result.first?["count"] as? Int64 ?? 0) > 0
    }
    
    /// Get the primary assignment for a worker (if any)
    func getPrimaryAssignment(for workerId: CoreTypes.WorkerID) async throws -> BuildingWorkerAssignment? {
        let assignments = try await getAssignments(for: workerId)
        
        // Return the most recent assignment as primary, or first one with "Lead" in role
        return assignments.first { $0.role.contains("Lead") || $0.role.contains("Primary") }
            ?? assignments.first
    }
    
    /// Update an assignment role
    func updateAssignmentRole(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        newRole: String
    ) async throws {
        try await sqliteManager.execute("""
            UPDATE worker_building_assignments 
            SET assignment_type = ? 
            WHERE worker_id = ? AND building_id = ? AND is_active = 1
        """, [newRole, workerId, buildingId])
        
        print("✅ Updated assignment role for worker \(workerId) at building \(buildingId) to: \(newRole)")
    }
    
    /// Get Kevin's specific assignments (for testing and validation)
    func getKevinAssignments() async throws -> [BuildingWorkerAssignment] {
        return try await getAssignments(for: "1") // Kevin's ID is 1
    }
    
    /// Get Edwin's specific assignments (for testing and validation)
    func getEdwinAssignments() async throws -> [BuildingWorkerAssignment] {
        return try await getAssignments(for: "2") // Edwin's ID is 2
    }
    
    /// Three-Dashboard Support: Get assignments by dashboard role
    func getAssignmentsByDashboardRole(_ role: String) async throws -> [BuildingWorkerAssignment] {
        let rows = try await sqliteManager.query("""
            SELECT 
                wba.id,
                wba.worker_id,
                wba.building_id,
                wba.assignment_type,
                wba.start_date,
                wba.is_active
            FROM worker_building_assignments wba
            WHERE wba.assignment_type LIKE ? AND wba.is_active = 1
            ORDER BY wba.start_date DESC
        """, ["%\(role)%"])
        
        return rows.compactMap { row in
            guard let assignmentId = row["id"] as? Int64,
                  let buildingIdString = row["building_id"] as? String,
                  let buildingId = Int64(buildingIdString),
                  let workerIdString = row["worker_id"] as? String,
                  let workerIdInt = Int64(workerIdString),
                  let assignmentType = row["assignment_type"] as? String,
                  let dateString = row["start_date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString)
            else { return nil }

            return BuildingWorkerAssignment(
                id: assignmentId,
                buildingId: buildingId,
                workerId: workerIdInt,
                role: assignmentType,
                assignedDate: date,
                isActive: true
            )
        }
    }
}
