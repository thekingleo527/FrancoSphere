//
//  DatabaseMigrations.swift
//  FrancoSphere
//
//  ✅ GRDB VERSION - Updated for GRDB.swift compatibility
//  ✅ Used by GRDBManager and migration files
//

import Foundation
import GRDB

/// Database migration protocol for versioned schema changes using GRDB
public protocol DatabaseMigration {
    /// Migration version number (must be unique)
    var version: Int { get }
    
    /// Human-readable migration name
    var name: String { get }
    
    /// Optional checksum for validation
    var checksum: String { get }
    
    /// Apply the migration (up direction) using GRDB Database
    func up(_ db: Database) throws
    
    /// Rollback the migration (down direction) using GRDB Database
    func down(_ db: Database) throws
}

/// Default implementations for convenience
public extension DatabaseMigration {
    var checksum: String {
        return "auto-generated-\(version)"
    }
}
