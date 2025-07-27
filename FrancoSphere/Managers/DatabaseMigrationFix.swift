//
//  DatabaseMigrationFix.swift
//  FrancoSphere v6.0
//
//  Temporary migration helper to ensure smooth transition
//

import Foundation

extension GRDBManager {
    /// Compatibility layer for any remaining SQLiteManager references
    static func start() async throws -> GRDBManager {
        return GRDBManager.shared
    }
}
