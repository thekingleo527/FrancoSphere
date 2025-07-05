//
//  DatabaseMigrations.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/27/25.
//
//  ✅ SINGLE AUTHORITATIVE DatabaseMigration PROTOCOL
//  ✅ Used by SQLiteManager, V012, and any other migration files
//  ✅ Targets: FrancoSphere + SeedDatabase
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SQLite
// FrancoSphere Types Import
// (This comment helps identify our import)


/// Database migration protocol for versioned schema changes
public protocol DatabaseMigration {
    /// Migration version number (must be unique)
    var version: Int { get }
    
    /// Human-readable migration name
    var name: String { get }
    
    /// Optional checksum for validation
    var checksum: String { get }
    
    /// Apply the migration (up direction)
    func up(_ db: Connection) throws
    
    /// Rollback the migration (down direction)
    func down(_ db: Connection) throws
}

/// Default implementations for convenience
public extension DatabaseMigration {
    var checksum: String {
        return "auto-generated-\(version)"
    }
}
