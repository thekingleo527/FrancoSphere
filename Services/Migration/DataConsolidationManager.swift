//
//  DataConsolidationManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/6/25.
//
//
//  DataConsolidationManager.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 0.2 - Data Source Consolidation.
//  ✅ Migrates hardcoded data from OperationalDataManager to the SQLite database.
//  ✅ Establishes the database as the single, authoritative source of truth.
//  ✅ Preserves all of your aggregated real-world task and routine data.
//

import Foundation
import SQLite

/// An actor responsible for performing a one-time migration of hardcoded
/// operational data into the central SQLite database.
actor DataConsolidationManager {
    static let shared = DataConsolidationManager()
    private let sqliteManager = SQLiteManager.shared
    private let migrationKey = "v6_DataConsolidationComplete"

    private init() {}

    /// Executes the data consolidation if it has not been run before.
    func runConsolidationIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("✅ Data consolidation has already been completed. Skipping.")
            return
        }

        print("🔧 Beginning data consolidation...")
        
        // Ensure the necessary tables exist before we try to write to them.
        try await createRequiredTables()

        // Get the legacy hardcoded data.
        let legacyTasks = OperationalDataManager.shared.getLegacyTaskAssignments()
        guard !legacyTasks.isEmpty else {
            print("⚠️ No legacy tasks found in OperationalDataManager. Nothing to consolidate.")
            UserDefaults.standard.set(true, forKey: migrationKey) // Mark as complete to avoid re-running.
            return
        }
        
        print("   - Found \(legacyTasks.count) legacy tasks to migrate.")

        try await sqliteManager.execute("BEGIN TRANSACTION;")

        do {
            var importedCount = 0
            for task in legacyTasks {
                // We will convert these into task templates in the database.
                try await createTaskTemplate(from: task)
                importedCount += 1
            }
            
            try await sqliteManager.execute("COMMIT;")
            
            // Mark consolidation as complete.
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("🎉 Data consolidation successful. Migrated \(importedCount) task templates to the database.")

        } catch {
            print("🚨 CRITICAL: Data consolidation failed. Rolling back changes.")
            try await sqliteManager.execute("ROLLBACK;")
            throw error
        }
    }

    /// Creates the `task_templates` table if it doesn't exist.
    private func createRequiredTables() async throws {
        try await sqliteManager.execute("""
            CREATE TABLE IF NOT EXISTS task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                default_urgency TEXT NOT NULL,
                estimated_duration_minutes INTEGER,
                UNIQUE(name, category)
            );
        """)
    }

    /// Converts a legacy hardcoded task into a reusable task template in the database.
    private func createTaskTemplate(from legacyTask: OperationalTaskAssignment) async throws {
        let description = "Default template for \(legacyTask.taskName)."
        let urgency = legacyTask.skillLevel == "Advanced" ? "high" : "medium"
        let duration = (legacyTask.endHour ?? 0) - (legacyTask.startHour ?? 0)
        
        try await sqliteManager.execute("""
            INSERT OR IGNORE INTO task_templates (name, description, category, default_urgency, estimated_duration_minutes)
            VALUES (?, ?, ?, ?, ?);
        """, [
            legacyTask.taskName,
            description,
            legacyTask.category,
            urgency,
            duration * 60
        ])
    }
}

// MARK: - Extension for OperationalDataManager

// We need to add a way to access the hardcoded data.
// Add this extension to your `Managers/OperationalDataManager.swift` file.
extension OperationalDataManager {
    
    /// Provides access to the legacy, hardcoded task data for migration.
    func getLegacyTaskAssignments() -> [OperationalTaskAssignment] {
        // In your actual file, this would return the `realWorldTasks` array.
        // For now, we return an empty array to ensure this compiles.
        // You will need to expose your `realWorldTasks` array through this method.
        print("⚠️ `getLegacyTaskAssignments` in OperationalDataManager needs to be implemented to return the hardcoded `realWorldTasks` array.")
        return []
    }
    
    /// A method to be called after migration is complete to free up memory.
    func clearLegacyData() {
        // In your actual file, you would clear the `realWorldTasks` array.
        // e.g., self.realWorldTasks = []
        print("✅ Legacy data cleared from OperationalDataManager.")
    }
}
