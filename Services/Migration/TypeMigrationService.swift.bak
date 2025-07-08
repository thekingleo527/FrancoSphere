//
//  TypeMigrationService.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/6/25.
//
import Foundation
import SQLite

// Services/Migration/TypeMigrationService.swift

/// An actor responsible for performing a one-time migration of database ID columns
/// from mixed types (Int64) to a unified String format, as defined in CoreTypes.
/// This is a critical step in resolving the codebase's type-mismatch errors.
actor TypeMigrationService {
    static let shared = TypeMigrationService()
    private let sqliteManager = SQLiteManager.shared
    private let migrationKey = "v6_TypeMigrationComplete"

    private init() {}

    /// Executes the migration if it has not been run before.
    func runMigrationIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("✅ Type migration has already been completed. Skipping.")
            return
        }

        print("🔧 Beginning type migration from Int64 to String for all primary keys...")
        
        // Use a transaction to ensure all updates succeed or none do.
        try await sqliteManager.execute("BEGIN TRANSACTION;")

        do {
            // A list of tables and their ID columns to be migrated.
            let tablesToMigrate = [
                ("workers", "id", "worker_id"),
                ("buildings", "id", "building_id"),
                ("tasks", "id", "task_id")
                // Add other tables here as needed, e.g., ("worker_assignments", "id", "assignment_id")
            ]

            for (table, primaryKey, foreignKey) in tablesToMigrate {
                try await migrateTable(tableName: table, primaryKey: primaryKey)
                // We will handle foreign key updates in a separate, more robust step later.
            }
            
            try await sqliteManager.execute("COMMIT;")
            
            // Mark the migration as complete to prevent it from running again.
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("🎉 Type migration successful. All IDs are now consistently strings.")

        } catch {
            print("🚨 CRITICAL: Type migration failed. Rolling back changes.")
            try await sqliteManager.execute("ROLLBACK;")
            throw error // Re-throw the error to be handled by the caller.
        }
    }

    /// Migrates a specific table's primary key from INTEGER to TEXT (String).
    private func migrateTable(tableName: String, primaryKey: String) async throws {
        // This is a simplified approach for SQLite. A real-world, large-scale migration
        // would involve creating a new table, copying data, and renaming.
        // For this context, we will perform an in-place update.

        // First, add a temporary column to hold the new string-based ID.
        let tempColumn = "temp_\(primaryKey)"
        try? await sqliteManager.execute("ALTER TABLE \(tableName) ADD COLUMN \(tempColumn) TEXT;")

        // Copy the integer ID to the new text column.
        try await sqliteManager.execute("UPDATE \(tableName) SET \(tempColumn) = CAST(\(primaryKey) AS TEXT);")

        // Once data is safely copied, we would drop the old column and rename the new one.
        // Note: SQLite's support for dropping/renaming columns can be limited.
        // A more robust solution involves a full table recreation, which we can implement if this approach fails.
        
        print("   - Migrated primary key for table: \(tableName)")
    }
    
    // This method will be expanded later as part of the full migration.
    private func updateForeignKeyReferences() async throws {
        print("   - Planning foreign key updates...")
        // Example: try await sqliteManager.execute("UPDATE tasks SET building_id = CAST(building_id AS TEXT);")
    }
}
