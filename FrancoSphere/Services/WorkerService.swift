//
//  WorkerService.swift
//  FrancoSphere v6.0
//
//  ✅ CONVERTED TO GRDB: Uses GRDBManager instead of GRDBManager
//  ✅ REAL DATA: Connects to actual database with preserved worker data
//  ✅ ASYNC/AWAIT: Modern Swift concurrency patterns
//

import Foundation
import GRDB

public actor WorkerService {
    public static let shared = WorkerService()
    
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    // MARK: - Public API Methods
    
    func getAllActiveWorkers() async throws -> [WorkerProfile] {
        let rows = try await grdbManager.query("""
            SELECT * FROM workers 
            WHERE isActive = 1 
            ORDER BY name
        """)
        
        return rows.compactMap { row in
            convertRowToWorkerProfile(row)
        }
    }
    
    func getWorkerProfile(for workerId: String) async throws -> WorkerProfile? {
        let rows = try await grdbManager.query("""
            SELECT * FROM workers 
            WHERE id = ? AND isActive = 1
        """, [workerId])
        
        guard let row = rows.first else { return nil }
        return convertRowToWorkerProfile(row)
    }
    
    func getActiveWorkersForBuilding(_ buildingId: String) async throws -> [WorkerProfile] {
        let rows = try await grdbManager.query("""
            SELECT DISTINCT w.*
            FROM workers w
            INNER JOIN worker_assignments wa ON w.id = wa.worker_id
            WHERE wa.building_id = ? AND wa.is_active = 1 AND w.isActive = 1
            ORDER BY w.name
        """, [buildingId])

        return rows.compactMap { row in
            convertRowToWorkerProfile(row)
        }
    }

    /// Reassign a routine task to a new worker
    func reassignTask(taskId: String, to newWorkerId: String) async throws {
        try await grdbManager.execute("""
            UPDATE routine_tasks
            SET workerId = ?
            WHERE id = ?
        """, [newWorkerId, taskId])
    }

    // MARK: - Private Helper Methods
    
    private func convertRowToWorkerProfile(_ row: [String: Any]) -> WorkerProfile? {
        guard let id = row["id"] as? Int64,
              let name = row["name"] as? String,
              let email = row["email"] as? String,
              let roleString = row["role"] as? String else {
            return nil
        }
        
        let role = UserRole(rawValue: roleString) ?? .worker
        
        return WorkerProfile(
            id: String(id),
            name: name,
            email: email,
            phoneNumber: row["phone"] as? String ?? "",
            role: role,
            skills: [], // Parse from database if needed
            certifications: [], // Parse from database if needed
            hireDate: Date(), // Parse from database if needed
            isActive: (row["isActive"] as? Int64) == 1,
            profileImageUrl: row["profileImagePath"] as? String
        )
    }
}

// MARK: - Fixed Method Signatures Extension
extension WorkerService {
    }
    
    func getWorker(by workerId: String) async throws -> WorkerProfile? {
        return try await grdbManager.read { db in
            try WorkerProfile.fetchOne(db, id: workerId)
        }
    }
    
    func getBuildingWorkers(buildingId: String) async throws -> [WorkerProfile] {
        return try await grdbManager.read { db in
            try WorkerProfile
                .filter(Column("assignedBuildingId") == buildingId)
                .fetchAll(db)
        }
    }
    
    func getWorkerProfile(for workerId: String) async throws -> WorkerProfile {
        guard let profile = try await getWorker(by: workerId) else {
            throw WorkerServiceError.workerNotFound(workerId)
        }
        return profile
    }
}

enum WorkerServiceError: Error {
    case workerNotFound(String)
}
