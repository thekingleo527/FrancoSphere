//
//  WorkerService.swift
//  FrancoSphere v6.0
//
//  ✅ CONVERTED TO GRDB: Uses GRDBManager instead of SQLiteManager
//  ✅ REAL DATA: Connects to actual database with preserved worker data
//  ✅ ASYNC/AWAIT: Modern Swift concurrency patterns
//  ✅ FIXED: String to URL conversion for profileImageUrl
//  ✅ FIXED: Added CoreTypes prefix to all type references
//

import Foundation
import GRDB

public actor WorkerService {
    public static let shared = WorkerService()
    
    private let grdbManager = GRDBManager.shared
    
    private init() {}
    
    // MARK: - Public API Methods
    
    // ✅ FIXED: Added CoreTypes prefix
    func getAllActiveWorkers() async throws -> [CoreTypes.WorkerProfile] {
        let rows = try await grdbManager.query("""
            SELECT * FROM workers 
            WHERE isActive = 1 
            ORDER BY name
        """)
        
        return rows.compactMap { row in
            convertRowToWorkerProfile(row)
        }
    }
    
    // ✅ FIXED: Added CoreTypes prefix
    func getWorkerProfile(for workerId: String) async throws -> CoreTypes.WorkerProfile? {
        let rows = try await grdbManager.query("""
            SELECT * FROM workers 
            WHERE id = ? AND isActive = 1
        """, [workerId])
        
        guard let row = rows.first else { return nil }
        return convertRowToWorkerProfile(row)
    }
    
    // ✅ FIXED: Added CoreTypes prefix
    func getActiveWorkersForBuilding(_ buildingId: String) async throws -> [CoreTypes.WorkerProfile] {
        let rows = try await grdbManager.query("""
            SELECT DISTINCT w.*
            FROM workers w
            INNER JOIN worker_building_assignments wa ON w.id = wa.worker_id
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
    
    // ✅ FIXED: Added CoreTypes prefix
    private func convertRowToWorkerProfile(_ row: [String: Any]) -> CoreTypes.WorkerProfile? {
        guard let id = row["id"] as? Int64,
              let name = row["name"] as? String,
              let email = row["email"] as? String,
              let roleString = row["role"] as? String else {
            return nil
        }
        
        // ✅ FIXED: Added CoreTypes prefix
        let role = CoreTypes.UserRole(rawValue: roleString) ?? .worker
        
        // ✅ FIXED: Convert string path to URL
        let profileImageUrl: URL? = {
            if let imagePath = row["profileImagePath"] as? String {
                return URL(string: imagePath)
            }
            return nil
        }()
        
        // Parse skills and certifications from comma-separated strings if available
        let skills: [String]? = {
            if let skillsString = row["skills"] as? String {
                return skillsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            return nil
        }()
        
        // Parse hire date
        let hireDate: Date? = {
            if let hireDateString = row["hireDate"] as? String {
                return ISO8601DateFormatter().date(from: hireDateString)
            }
            return nil
        }()
        
        // ✅ FIXED: Added CoreTypes prefix
        return CoreTypes.WorkerProfile(
            id: String(id),
            name: name,
            email: email,
            phoneNumber: row["phone"] as? String,
            role: role,
            skills: skills,
            certifications: [], // Could parse from database similar to skills
            hireDate: hireDate,
            isActive: (row["isActive"] as? Int64) == 1,
            profileImageUrl: profileImageUrl
        )
    }
}

// MARK: - Extended Methods
extension WorkerService {
    
    // ✅ FIXED: Added CoreTypes prefix
    func getWorker(by workerId: String) async throws -> CoreTypes.WorkerProfile? {
        let rows = try await grdbManager.query("""
            SELECT * FROM workers 
            WHERE id = ? AND isActive = 1
        """, [workerId])
        
        guard let row = rows.first else { return nil }
        return convertRowToWorkerProfile(row)
    }
    
    // ✅ FIXED: Added CoreTypes prefix
    func getBuildingWorkers(buildingId: String) async throws -> [CoreTypes.WorkerProfile] {
        let rows = try await grdbManager.query("""
            SELECT DISTINCT w.*
            FROM workers w
            INNER JOIN worker_building_assignments wa ON w.id = wa.worker_id
            WHERE wa.building_id = ? AND wa.is_active = 1 AND w.isActive = 1
            ORDER BY w.name
        """, [buildingId])
        
        return rows.compactMap { row in
            convertRowToWorkerProfile(row)
        }
    }
    
    // ✅ FIXED: Added CoreTypes prefix
    // Convenience method that throws if worker not found
    func getWorkerProfileById(workerId: String) async throws -> CoreTypes.WorkerProfile {
        guard let profile = try await getWorker(by: workerId) else {
            throw WorkerServiceError.workerNotFound(workerId)
        }
        return profile
    }
}

enum WorkerServiceError: Error {
    case workerNotFound(String)
    
    var localizedDescription: String {
        switch self {
        case .workerNotFound(let id):
            return "Worker with ID \(id) not found"
        }
    }
}
