//
//  DataConsolidationManager.swift
//  FrancoSphere
//
//  🚀 MIGRATED TO GRDB.swift - Data Source Consolidation
//  ✅ V6.0: Phase 0.2 - Data Source Consolidation - SYNTAX ERRORS FIXED
//  ✅ FIXED: Method name mismatch and transaction structure
//

import Foundation
import GRDB

/// An actor responsible for performing a one-time migration of hardcoded
/// operational data into the central GRDB database.
actor DataConsolidationManager {
    static let shared = DataConsolidationManager()
    private let grdbManager = GRDBManager.shared
    private let migrationKey = "v6_DataConsolidationComplete_GRDB"

    private init() {}

    /// Executes the data consolidation if it has not been run before.
    func runConsolidationIfNeeded() async throws {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else {
            print("✅ Data consolidation has already been completed with GRDB. Skipping.")
            return
        }

        print("🔧 Beginning data consolidation with GRDB...")
        
        // Ensure the necessary tables exist before we try to write to them
        try await createRequiredTables()

        // ✅ FIXED: Correct method name (without "All")
        let legacyTasks = await OperationalDataManager.shared.getLegacyTaskAssignments()
        guard !legacyTasks.isEmpty else {
            print("⚠️ No legacy tasks found in OperationalDataManager. Nothing to consolidate.")
            UserDefaults.standard.set(true, forKey: migrationKey) // Mark as complete to avoid re-running
            return
        }
        
        print("   - Found \(legacyTasks.count) legacy tasks to migrate with GRDB.")

        // ✅ FIXED: Proper transaction structure with GRDB
        do {
            try await grdbManager.execute("BEGIN TRANSACTION", [])
            
            var importedCount = 0
            for task in legacyTasks {
                // Convert these into task templates in the database
                try await createTaskTemplate(from: task)
                importedCount += 1
            }
            
            try await grdbManager.execute("COMMIT", [])
            
            // Mark consolidation as complete
            UserDefaults.standard.set(true, forKey: migrationKey)
            print("🎉 Data consolidation successful with GRDB. Migrated \(importedCount) task templates to the database.")

        } catch {
            print("🚨 CRITICAL: Data consolidation failed with GRDB. Rolling back changes.")
            try await grdbManager.execute("ROLLBACK", [])
            throw error
        }
    }

    /// Creates the required tables for data consolidation using GRDB
    private func createRequiredTables() async throws {
        // Create task_templates table
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                description TEXT,
                category TEXT NOT NULL,
                default_urgency TEXT NOT NULL,
                estimated_duration_minutes INTEGER,
                skill_level TEXT DEFAULT 'Basic',
                recurrence TEXT DEFAULT 'daily',
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(name, category)
            );
        """, [])
        
        // Create operational_data_migration table to track what's been migrated
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS operational_data_migration (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                migration_type TEXT NOT NULL,
                source_system TEXT NOT NULL,
                records_migrated INTEGER DEFAULT 0,
                migration_date TEXT DEFAULT CURRENT_TIMESTAMP,
                checksum TEXT,
                UNIQUE(migration_type, source_system)
            );
        """, [])
        
        // Create worker_task_templates for worker-specific task assignments
        try await grdbManager.execute("""
            CREATE TABLE IF NOT EXISTS worker_task_templates (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                worker_id TEXT NOT NULL,
                building_id TEXT NOT NULL,
                task_template_id INTEGER NOT NULL,
                start_time TEXT,
                end_time TEXT,
                days_of_week TEXT DEFAULT 'weekdays',
                is_active INTEGER DEFAULT 1,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (task_template_id) REFERENCES task_templates(id),
                UNIQUE(worker_id, building_id, task_template_id)
            );
        """, [])
        
        print("✅ Required tables created with GRDB")
    }

    /// Converts a legacy hardcoded task into a reusable task template in the database using GRDB
    private func createTaskTemplate(from legacyTask: LegacyTaskAssignment) async throws {
        let description = "Migrated from OperationalDataManager: \(legacyTask.taskName)"
        let urgency = determineUrgency(from: legacyTask)
        let duration = calculateDuration(from: legacyTask)
        
        // Insert task template
        let templateId = try await grdbManager.insertAndReturnID("""
            INSERT OR IGNORE INTO task_templates 
            (name, description, category, default_urgency, estimated_duration_minutes, skill_level)
            VALUES (?, ?, ?, ?, ?, ?);
        """, [
            legacyTask.taskName,
            description,
            legacyTask.category,
            urgency,
            duration,
            legacyTask.skillLevel
        ])
        
        // Create worker-specific assignment if we have worker and building info
        if templateId > 0 {
            let startTime = formatTime(hour: legacyTask.startHour)
            let endTime = formatTime(hour: legacyTask.endHour)
            
            // Use building name and worker name to look up IDs
            let buildingResults = try await grdbManager.query("""
                SELECT id FROM buildings WHERE name LIKE ?
            """, ["%\(legacyTask.building)%"])
            
            let workerResults = try await grdbManager.query("""
                SELECT id FROM workers WHERE name = ?
            """, [legacyTask.assignedWorker])
            
            if let buildingId = buildingResults.first?["id"] as? String,
               let workerId = workerResults.first?["id"] as? String {
                
                try await grdbManager.execute("""
                    INSERT OR IGNORE INTO worker_task_templates 
                    (worker_id, building_id, task_template_id, start_time, end_time)
                    VALUES (?, ?, ?, ?, ?);
                """, [workerId, buildingId, templateId, startTime, endTime])
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines task urgency based on legacy task properties
    private func determineUrgency(from task: LegacyTaskAssignment) -> String {
        switch task.skillLevel {
        case "Advanced", "Expert":
            return "high"
        case "Intermediate":
            return "medium"
        default:
            return "low"
        }
    }
    
    /// Calculates task duration in minutes
    private func calculateDuration(from task: LegacyTaskAssignment) -> Int {
        let startHour = task.startHour ?? 9
        let endHour = task.endHour ?? startHour + 1
        return max((endHour - startHour) * 60, 30) // Minimum 30 minutes
    }
    
    /// Formats hour as HH:MM string
    private func formatTime(hour: Int?) -> String {
        guard let hour = hour, hour >= 0, hour <= 23 else { return "09:00" }
        return String(format: "%02d:00", hour)
    }
    
    // MARK: - Data Analysis Methods
    
    /// Analyzes the migrated data for insights
    func analyzeConsolidatedData() async throws -> ConsolidationReport {
        let taskTemplates = try await grdbManager.query("SELECT COUNT(*) as count FROM task_templates", [])
        let workerAssignments = try await grdbManager.query("SELECT COUNT(*) as count FROM worker_task_templates", [])
        
        let categoryBreakdown = try await grdbManager.query("""
            SELECT category, COUNT(*) as count 
            FROM task_templates 
            GROUP BY category 
            ORDER BY count DESC
        """, [])
        
        let skillLevelBreakdown = try await grdbManager.query("""
            SELECT skill_level, COUNT(*) as count 
            FROM task_templates 
            GROUP BY skill_level 
            ORDER BY count DESC
        """, [])
        
        return ConsolidationReport(
            totalTaskTemplates: Int(taskTemplates.first?["count"] as? Int64 ?? 0),
            totalWorkerAssignments: Int(workerAssignments.first?["count"] as? Int64 ?? 0),
            categoryBreakdown: categoryBreakdown.compactMap { row in
                guard let category = row["category"] as? String,
                      let count = row["count"] as? Int64 else { return nil }
                return (category: category, count: Int(count))
            },
            skillLevelBreakdown: skillLevelBreakdown.compactMap { row in
                guard let skillLevel = row["skill_level"] as? String,
                      let count = row["count"] as? Int64 else { return nil }
                return (skillLevel: skillLevel, count: Int(count))
            }
        )
    }
    
    /// Records the migration in the tracking table
    func recordMigration(type: String, sourceSystem: String, recordCount: Int) async throws {
        let checksum = "\(type)_\(sourceSystem)_\(recordCount)_\(Date().timeIntervalSince1970)"
        
        try await grdbManager.execute("""
            INSERT OR REPLACE INTO operational_data_migration 
            (migration_type, source_system, records_migrated, checksum)
            VALUES (?, ?, ?, ?);
        """, [type, sourceSystem, recordCount, checksum])
        
        print("✅ Migration recorded: \(type) from \(sourceSystem) - \(recordCount) records")
    }
    
    /// Cleans up legacy data after successful migration
    func cleanupLegacyData() async {
        // Note: clearLegacyData method would need to be implemented in OperationalDataManager
        // await OperationalDataManager.shared.clearLegacyData()
        print("✅ Legacy data cleanup requested (method not implemented in OperationalDataManager)")
    }
    
    /// Exports consolidated data for verification
    func exportConsolidatedData() async throws -> ConsolidationExport {
        let taskTemplates = try await grdbManager.query("SELECT * FROM task_templates ORDER BY category, name", [])
        let workerAssignments = try await grdbManager.query("""
            SELECT wtt.*, tt.name as task_name, tt.category 
            FROM worker_task_templates wtt
            JOIN task_templates tt ON wtt.task_template_id = tt.id
            ORDER BY wtt.worker_id, wtt.building_id
        """, [])
        
        return ConsolidationExport(
            taskTemplates: taskTemplates,
            workerAssignments: workerAssignments,
            exportDate: Date(),
            totalRecords: taskTemplates.count + workerAssignments.count
        )
    }
}

// MARK: - Supporting Data Structures

/// Report structure for analyzing consolidated data
struct ConsolidationReport {
    let totalTaskTemplates: Int
    let totalWorkerAssignments: Int
    let categoryBreakdown: [(category: String, count: Int)]
    let skillLevelBreakdown: [(skillLevel: String, count: Int)]
    
    var summary: String {
        return """
        📊 Data Consolidation Report:
           Task Templates: \(totalTaskTemplates)
           Worker Assignments: \(totalWorkerAssignments)
           
           Top Categories:
        \(categoryBreakdown.prefix(3).map { "   • \($0.category): \($0.count)" }.joined(separator: "\n"))
           
           Skill Levels:
        \(skillLevelBreakdown.map { "   • \($0.skillLevel): \($0.count)" }.joined(separator: "\n"))
        """
    }
}

/// Export structure for consolidated data
struct ConsolidationExport {
    let taskTemplates: [[String: Any]]
    let workerAssignments: [[String: Any]]
    let exportDate: Date
    let totalRecords: Int
}
