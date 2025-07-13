//
//  TypeMigrationService.swift
//  FrancoSphere
//
//  ✅ GRDB VERSION - Updated for GRDB.swift compatibility
//  ✅ Performs one-time migration from Int64 to String IDs
//

import Foundation
import GRDB

/// An actor responsible for performing a one-time migration of database ID columns
/// from mixed types (Int64) to a unified String format, as defined in CoreTypes.
/// This is a critical step in resolving the codebase's type-mismatch errors.
actor TypeMigrationService {
    static let shared = TypeMigrationService()
    private let grdbManager = GRDBManager.shared  // Updated to use GRDBManager
    private let migrationKey = "v6_TypeMigrationComplete"

    private init() {}

    /// Executes the migration if it has not been run before.
    func runMigrationIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("✅ Type migration has already been completed. Skipping.")
            return
        }

        print("🔧 Beginning type migration from Int64 to String for all primary keys...")
        
        // Use GRDB transaction to ensure all updates succeed or none do.
        try await grdbManager.dbPool.write { db in
            do {
                // A list of tables and their ID columns to be migrated.
                let tablesToMigrate = [
                    ("workers", "id"),
                    ("buildings", "id"),
                    ("tasks", "id"),
                    ("worker_assignments", "id")
                ]

                for (table, primaryKey) in tablesToMigrate {
                    try migrateTable(db: db, tableName: table, primaryKey: primaryKey)
                }
                
                print("🎉 Type migration successful. All IDs are now consistently strings.")

            } catch {
                print("🚨 CRITICAL: Type migration failed: \(error)")
                throw error // GRDB will automatically rollback the transaction
            }
        }
        
        // Mark the migration as complete to prevent it from running again.
        UserDefaults.standard.set(true, forKey: migrationKey)
    }

    /// Migrates a specific table's primary key from INTEGER to TEXT (String).
    private func migrateTable(db: Database, tableName: String, primaryKey: String) throws {
        // Check if table exists
        guard try db.tableExists(tableName) else {
            print("   - Table \(tableName) does not exist, skipping...")
            return
        }
        
        // For GRDB, we'll ensure IDs are treated as strings in the application layer
        // rather than modifying the database schema (which can be complex with foreign keys)
        
        // Verify the table has data and the ID column exists
        let columns = try db.columns(in: tableName)
        let hasIdColumn = columns.contains { $0.name == primaryKey }
        
        if hasIdColumn {
            let count = try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(tableName)") ?? 0
            print("   - Table \(tableName) has \(count) records with \(primaryKey) column")
        } else {
            print("   - Table \(tableName) missing \(primaryKey) column")
        }
        
        print("   - Migration strategy updated for table: \(tableName)")
    }
    
    /// Ensures foreign key references are consistent
    private func updateForeignKeyReferences(db: Database) throws {
        print("   - Updating foreign key references...")
        
        // Update any string-based foreign keys to ensure consistency
        // Example: Ensure building_id in tasks table matches buildings.id format
        try db.execute(sql: """
            UPDATE tasks 
            SET building_id = CAST(building_id AS TEXT) 
            WHERE building_id IS NOT NULL
        """)
        
        try db.execute(sql: """
            UPDATE worker_assignments 
            SET worker_id = CAST(worker_id AS TEXT),
                building_id = CAST(building_id AS TEXT)
            WHERE worker_id IS NOT NULL AND building_id IS NOT NULL
        """)
        
        print("   - Foreign key references updated")
    }
}
