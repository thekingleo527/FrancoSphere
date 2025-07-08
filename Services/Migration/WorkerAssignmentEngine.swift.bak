//
//  WorkerAssignmentEngine.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/6/25.
//
//
//  WorkerAssignmentEngine.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 0.1 - Eliminates "Kevin" special cases.
//  ✅ Replaces hardcoded assignment logic with a dynamic, role-based system.
//  ✅ Provides a single, authoritative source for managing worker-building relationships.
//

import Foundation
import SQLite

/// An actor responsible for managing the assignment of workers to buildings
/// based on roles, skills, and building requirements. This replaces all previous
/// hardcoded and special-case assignment logic.
actor WorkerAssignmentEngine {
    static let shared = WorkerAssignmentEngine()
    private let sqliteManager = SQLiteManager.shared

    private init() {}

    // MARK: - Core Assignment Logic

    /// Assigns a worker to a building with a specific role.
    /// This is the new, authoritative method for creating assignments.
    func assignWorkerToBuilding(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        role: String, // e.g., "Lead Maintenance", "Sanitation Specialist"
        startDate: Date = Date()
    ) async throws {
        // In a real system, we would validate this against a `WorkerRole` model.
        // For now, we directly insert into the database.
        
        print("⚙️ Assigning worker \(workerId) to building \(buildingId) with role: \(role)")

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
    }

    /// Retrieves all active assignments for a given worker.
    func getAssignments(for workerId: CoreTypes.WorkerID) async throws -> [BuildingWorkerAssignment] {
        let rows = try await sqliteManager.query("""
            SELECT * FROM worker_building_assignments
            WHERE worker_id = ? AND is_active = 1
        """, [workerId])

        return rows.compactMap { row in
            guard let buildingId = row["building_id"] as? String,
                  let role = row["assignment_type"] as? String,
                  let dateString = row["start_date"] as? String,
                  let date = ISO8601DateFormatter().date(from: dateString)
            else { return nil }

            return BuildingWorkerAssignment(
                id: row["id"] as? Int64 ?? 0,
                buildingId: Int64(buildingId) ?? 0,
                workerId: Int64(workerId) ?? 0,
                role: role,
                assignedDate: date,
                isActive: true
            )
        }
    }
    
    /// A diagnostic tool to verify that the "Kevin" special case has been successfully migrated.
    func verifyKevinMigration() async -> (isMigrated: Bool, issues: [String]) {
        var issues: [String] = []
        let kevinId: CoreTypes.WorkerID = "4"
        
        do {
            let assignments = try await getAssignments(for: kevinId)
            
            if assignments.isEmpty {
                issues.append("Kevin Dutan (ID: 4) has no assignments in the new system.")
            }
            
            // Check for the critical Rubin Museum assignment
            if !assignments.contains(where: { $0.buildingId == 14 }) {
                issues.append("Kevin is missing his critical assignment to Rubin Museum (ID: 14).")
            }
            
            // Check that he no longer has the incorrect Franklin St assignment
            if assignments.contains(where: { $0.buildingId == 13 }) {
                issues.append("Kevin still has an incorrect assignment to the old Franklin St. ID (13).")
            }
            
            if issues.isEmpty {
                print("✅ Kevin Migration Verified: Assignments are correct in the new engine.")
                return (true, [])
            } else {
                return (false, issues)
            }
            
        } catch {
            return (false, ["Database error during verification: \(error.localizedDescription)"])
        }
    }
}

// MARK: - Supporting Types

// We can define a more structured Role model here later.
// For now, a simple string is sufficient.

enum WorkerAssignmentError: LocalizedError {
    case insufficientSkills
    case buildingNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .insufficientSkills:
            return "The worker does not have the required skills for this building."
        case .buildingNotAvailable:
            return "The specified building is not available for assignment."
        }
    }
}
