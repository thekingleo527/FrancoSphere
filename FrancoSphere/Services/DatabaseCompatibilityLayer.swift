//
//  DatabaseCompatibilityLayer.swift
//  FrancoSphere v6.0
//
//  ✅ COMPATIBILITY: Provides transition methods for removed classes
//  ✅ NO CONFLICTS: Resolves ambiguous method calls
//  ✅ MIGRATION SAFE: Ensures no breaking changes
//

import Foundation

// MARK: - Compatibility Extensions

extension OperationalDataManager {
    
    /// Compatibility method to resolve ambiguous importRoutinesAndDSNY calls
    public func importOperationalData() async throws -> (imported: Int, errors: [String]) {
        // Delegate to the existing method to avoid ambiguity
        return try await self.importRoutinesAndDSNY()
    }
    
    /// Legacy compatibility for old initialization patterns
    public func initializeWithFallback() async throws {
        if !self.isInitialized {
            try await self.initializeOperationalData()
        }
    }
}

// MARK: - Database Status Helper

public struct DatabaseStatusChecker {
    
    public static func verifyIntegrity() async -> DatabaseIntegrityResult {
        do {
            let grdb = GRDBManager.shared
            
            let workers = try await grdb.query("SELECT COUNT(*) as count FROM workers", [])
            let buildings = try await grdb.query("SELECT COUNT(*) as count FROM buildings", [])
            let tasks = try await grdb.query("SELECT COUNT(*) as count FROM tasks", [])
            
            let workerCount = Int(workers.first?["count"] as? Int64 ?? 0)
            let buildingCount = Int(buildings.first?["count"] as? Int64 ?? 0)
            let taskCount = Int(tasks.first?["count"] as? Int64 ?? 0)
            
            return DatabaseIntegrityResult(
                workers: workerCount,
                buildings: buildingCount,
                tasks: taskCount,
                isValid: workerCount > 0 && buildingCount > 0,
                errors: []
            )
        } catch {
            return DatabaseIntegrityResult(
                workers: 0,
                buildings: 0,
                tasks: 0,
                isValid: false,
                errors: [error.localizedDescription]
            )
        }
    }
}

public struct DatabaseIntegrityResult {
    public let workers: Int
    public let buildings: Int
    public let tasks: Int
    public let isValid: Bool
    public let errors: [String]
    
    public var summary: String {
        return "Workers: \(workers), Buildings: \(buildings), Tasks: \(tasks)"
    }
}

// MARK: - Legacy Error Type Compatibility

public enum LegacyDatabaseError: LocalizedError {
    case initializationFailed(String)
    case verificationFailed(String)
    case seedingFailed(String)
    case migrationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .initializationFailed(let msg): return "Initialization failed: \(msg)"
        case .verificationFailed(let msg): return "Verification failed: \(msg)"
        case .seedingFailed(let msg): return "Seeding failed: \(msg)"
        case .migrationFailed(let msg): return "Migration failed: \(msg)"
        }
    }
}
