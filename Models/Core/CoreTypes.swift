//
//  CoreTypes.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 0.3 - Type System Unification
//  ✅ Establishes the single source of truth for all primary identifiers and core data types.
//  ✅ Resolves type confusion (e.g., String vs. Int64) and provides a unified User model.
//

import Foundation

public enum CoreTypes {
    
    // MARK: - Unified Identifiers
    // All IDs are now consistently strings for flexibility and to prevent type errors.
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String

    // MARK: - Unified User Model
    // Replaces scattered user/worker properties with a single, authoritative struct.
    // This resolves the "Value of type 'User' has no member 'workerId'" category of errors.
    public struct User: Codable, Identifiable {
        public var id: WorkerID { workerId }
        
        public let workerId: WorkerID
        public let name: String
        public let role: String
        public let email: String?
    }
}
