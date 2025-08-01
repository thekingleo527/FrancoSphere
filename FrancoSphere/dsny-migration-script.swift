import Foundation
import SQLite3

// MARK: - DSNY Terminology Migration Script
// This script standardizes all DSNY-related terminology in FrancoSphere v6.0

class DSNYTerminologyMigration {
    
    // MARK: - Configuration
    
    struct Config {
        static let dryRun = false // Set to true to preview changes without applying
        static let createBackup = true
        static let logFile = "dsny_migration_log_\(Date().timeIntervalSince1970).txt"
    }
    
    // MARK: - Terminology Mappings
    
    struct TermMapping {
        let oldTerm: String
        let newTerm: String
        let context: String
    }
    
    static let taskTitleMappings: [TermMapping] = [
        // Evening trash variations
        TermMapping(oldTerm: "Trash Management - Evening", newTerm: "DSNY: Set Out Trash", context: "task_title"),
        TermMapping(oldTerm: "Trash Removal", newTerm: "DSNY: Set Out Trash", context: "task_title"),
        TermMapping(oldTerm: "Trash removal", newTerm: "DSNY: Set Out Trash", context: "task_title"),
        TermMapping(oldTerm: "Put Out Trash", newTerm: "DSNY: Set Out Trash", context: "task_title"),
        TermMapping(oldTerm: "DSNY Put-Out (after 20:00)", newTerm: "DSNY: Set Out Trash", context: "task_title"),
        
        // Bring in variations
        TermMapping(oldTerm: "Bring in trash bins", newTerm: "DSNY: Bring In Trash Bins", context: "task_title"),
        TermMapping(oldTerm: "DSNY Prep / Move Bins", newTerm: "DSNY: Bring In Trash Bins", context: "task_title"),
        
        // Recycling variations
        TermMapping(oldTerm: "Recycling Management", newTerm: "DSNY: Set Out Recycling", context: "task_title"),
        TermMapping(oldTerm: "Put Out Recycling", newTerm: "DSNY: Set Out Recycling", context: "task_title"),
        
        // Compliance variations
        TermMapping(oldTerm: "DSNY Compliance", newTerm: "DSNY: Compliance Check", context: "task_title"),
        TermMapping(oldTerm: "Rubin Museum DSNY", newTerm: "DSNY: Compliance Check", context: "task_title"),
        TermMapping(oldTerm: "Rubin DSNY Operations", newTerm: "DSNY: Compliance Check", context: "task_title"),
        TermMapping(oldTerm: "DSNY Compliance Check", newTerm: "DSNY: Compliance Check", context: "task_title"),
        
        // Sanitation variations
        TermMapping(oldTerm: "Evening Sanitation", newTerm: "DSNY: Set Out Trash", context: "task_title"),
        TermMapping(oldTerm: "Sanitation - Evening", newTerm: "DSNY: Set Out Trash", context: "task_title")
    ]
    
    static let categoryMappings: [TermMapping] = [
        TermMapping(oldTerm: "maintenance", newTerm: "sanitation", context: "category_dsny"),
        TermMapping(oldTerm: "Maintenance", newTerm: "Sanitation", context: "category_dsny")
    ]
    
    // MARK: - Migration State
    
    private var log: [String] = []
    private var changesApplied: [String: Int] = [:]
    private var errors: [String] = []
    
    // MARK: - Main Migration Method
    
    func performMigration() async throws {
        log("=== DSNY Terminology Migration Started ===")
        log("Timestamp: \(Date())")
        log("Dry Run: \(Config.dryRun)")
        log("")
        
        do {
            // Step 1: Create backup if enabled
            if Config.createBackup && !Config.dryRun {
                try await createDatabaseBackup()
            }
            
            // Step 2: Update OperationalDataManager tasks
            try await updateOperationalDataTasks()
            
            // Step 3: Update database records
            try await updateDatabaseRecords()
            
            // Step 4: Update code files
            try updateCodeFiles()
            
            // Step 5: Generate report
            generateReport()
            
            // Step 6: Save log
            try saveLog()
            
            log("\n=== Migration Completed Successfully ===")
            
        } catch {
            log("ERROR: Migration failed - \(error)")
            errors.append(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Database Operations
    
    private func createDatabaseBackup() async throws {
        log("\n--- Creating Database Backup ---")
        
        let backupPath = "francosphere_backup_\(Date().timeIntervalSince1970).db"
        
        // Using GRDBManager's database path
        let sourcePath = getDatabasePath()
        
        if FileManager.default.fileExists(atPath: sourcePath) {
            try FileManager.default.copyItem(atPath: sourcePath, toPath: backupPath)
            log("✅ Database backed up to: \(backupPath)")
        } else {
            log("⚠️ Database file not found at expected path")
        }
    }
    
    private func updateDatabaseRecords() async throws {
        log("\n--- Updating Database Records ---")
        
        let updateQueries = [
            // Update routine_tasks table
            """
            UPDATE routine_tasks 
            SET title = CASE 
                WHEN title LIKE '%Trash Management - Evening%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Trash Removal%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Put Out Trash%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%DSNY Put-Out%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Bring in trash bins%' THEN 'DSNY: Bring In Trash Bins'
                WHEN title LIKE '%DSNY Prep / Move Bins%' THEN 'DSNY: Bring In Trash Bins'
                WHEN title LIKE '%Recycling Management%' THEN 'DSNY: Set Out Recycling'
                WHEN title = 'DSNY Compliance' THEN 'DSNY: Compliance Check'
                WHEN title LIKE '%Rubin%DSNY%' THEN 'DSNY: Compliance Check'
                ELSE title
            END,
            category = CASE
                WHEN (title LIKE '%Trash%' OR title LIKE '%DSNY%' OR title LIKE '%Recycling%') 
                     AND category = 'maintenance' 
                THEN 'sanitation'
                ELSE category
            END
            WHERE title LIKE '%Trash%' 
               OR title LIKE '%DSNY%' 
               OR title LIKE '%Recycling%'
               OR title LIKE '%Sanitation%'
            """,
            
            // Update routine_templates table if it exists
            """
            UPDATE routine_templates 
            SET title = CASE 
                WHEN title LIKE '%Trash Management - Evening%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Trash Removal%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Put Out Trash%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Recycling Management%' THEN 'DSNY: Set Out Recycling'
                WHEN title = 'DSNY Compliance' THEN 'DSNY: Compliance Check'
                ELSE title
            END,
            category = 'sanitation'
            WHERE title LIKE '%Trash%' 
               OR title LIKE '%DSNY%' 
               OR title LIKE '%Recycling%'
            """
        ]
        
        if Config.dryRun {
            log("🔍 DRY RUN: Would execute \(updateQueries.count) update queries")
            for (index, query) in updateQueries.enumerated() {
                log("Query \(index + 1): \(query.prefix(100))...")
            }
        } else {
            for query in updateQueries {
                do {
                    let changes = try await executeSQL(query)
                    log("✅ Updated \(changes) records")
                    changesApplied["database_records", default: 0] += changes
                } catch {
                    log("⚠️ Query failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Code File Operations
    
    private func updateOperationalDataTasks() async throws {
        log("\n--- Updating OperationalDataManager Tasks ---")
        
        let filePath = findFile(named: "OperationalDataManager.swift")
        guard let path = filePath else {
            log("⚠️ OperationalDataManager.swift not found")
            return
        }
        
        do {
            var content = try String(contentsOfFile: path, encoding: .utf8)
            var changeCount = 0
            
            // Apply task title mappings
            for mapping in Self.taskTitleMappings {
                let oldCount = content.count
                content = content.replacingOccurrences(
                    of: "taskName: \"\(mapping.oldTerm)\"",
                    with: "taskName: \"\(mapping.newTerm)\""
                )
                if content.count != oldCount {
                    changeCount += 1
                    log("  ✏️ Replaced '\(mapping.oldTerm)' → '\(mapping.newTerm)'")
                }
            }
            
            // Fix category assignments for DSNY tasks
            let categoryPattern = #"(taskName:\s*"DSNY[^"]+",[\s\S]*?)category:\s*"maintenance""#
            let regex = try NSRegularExpression(pattern: categoryPattern, options: [])
            let nsContent = content as NSString
            let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsContent.length))
            
            for match in matches.reversed() {
                if let range = Range(match.range, in: content) {
                    let substring = String(content[range])
                    let updated = substring.replacingOccurrences(of: "category: \"maintenance\"", with: "category: \"sanitation\"")
                    content.replaceSubrange(range, with: updated)
                    changeCount += 1
                }
            }
            
            if Config.dryRun {
                log("🔍 DRY RUN: Would make \(changeCount) changes to OperationalDataManager.swift")
            } else if changeCount > 0 {
                try content.write(toFile: path, atomically: true, encoding: .utf8)
                log("✅ Updated OperationalDataManager.swift with \(changeCount) changes")
                changesApplied["operational_data_tasks", default: 0] += changeCount
            }
            
        } catch {
            log("❌ Failed to update OperationalDataManager: \(error)")
            errors.append("OperationalDataManager update failed: \(error)")
        }
    }
    
    private func updateCodeFiles() throws {
        log("\n--- Updating Code Files ---")
        
        let targetFiles = [
            "TaskService.swift",
            "WorkerDashboardViewModel.swift",
            "BuildingService.swift",
            "TaskDetailView.swift",
            "AdminDashboardView.swift"
        ]
        
        for fileName in targetFiles {
            if let filePath = findFile(named: fileName) {
                try updateFile(at: filePath)
            } else {
                log("⚠️ File not found: \(fileName)")
            }
        }
    }
    
    private func updateFile(at path: String) throws {
        var content = try String(contentsOfFile: path, encoding: .utf8)
        let fileName = URL(fileURLWithPath: path).lastPathComponent
        var changeCount = 0
        
        // Apply terminology mappings
        for mapping in Self.taskTitleMappings {
            let patterns = [
                "\"\(mapping.oldTerm)\"",
                "'\(mapping.oldTerm)'",
                "task.title == \"\(mapping.oldTerm)\"",
                "title.contains(\"\(mapping.oldTerm)\")"
            ]
            
            for pattern in patterns {
                let oldCount = content.count
                content = content.replacingOccurrences(
                    of: pattern,
                    with: pattern.replacingOccurrences(of: mapping.oldTerm, with: mapping.newTerm)
                )
                if content.count != oldCount {
                    changeCount += 1
                }
            }
        }
        
        if Config.dryRun {
            if changeCount > 0 {
                log("🔍 DRY RUN: Would make \(changeCount) changes to \(fileName)")
            }
        } else if changeCount > 0 {
            try content.write(toFile: path, atomically: true, encoding: .utf8)
            log("✅ Updated \(fileName) with \(changeCount) changes")
            changesApplied[fileName, default: 0] += changeCount
        }
    }
    
    // MARK: - Helper Methods
    
    private func findFile(named fileName: String, in directory: String = FileManager.default.currentDirectoryPath) -> String? {
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix(fileName) {
                    return "\(directory)/\(file)"
                }
            }
        }
        
        return nil
    }
    
    private func getDatabasePath() -> String {
        // Adjust this path based on your actual database location
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return "\(documentsPath)/francosphere.db"
    }
    
    private func executeSQL(_ query: String) async throws -> Int {
        // This would use your actual GRDBManager
        // For now, returning a placeholder
        return 0
    }
    
    private func log(_ message: String) {
        print(message)
        log.append(message)
    }
    
    private func generateReport() {
        log("\n=== Migration Report ===")
        log("Total Changes Applied:")
        
        var totalChanges = 0
        for (area, count) in changesApplied.sorted(by: { $0.key < $1.key }) {
            log("  - \(area): \(count) changes")
            totalChanges += count
        }
        
        log("\nTotal: \(totalChanges) changes")
        
        if !errors.isEmpty {
            log("\nErrors Encountered:")
            for error in errors {
                log("  ❌ \(error)")
            }
        }
        
        log("\nRecommended Next Steps:")
        log("1. Review the changes in git diff")
        log("2. Run the app and test DSNY task generation")
        log("3. Verify database records are updated correctly")
        log("4. Test with Kevin's account (ID: 4) at Rubin Museum")
    }
    
    private func saveLog() throws {
        let logContent = log.joined(separator: "\n")
        try logContent.write(toFile: Config.logFile, atomically: true, encoding: .utf8)
        print("\n📄 Log saved to: \(Config.logFile)")
    }
}

// MARK: - Script Execution

@main
struct DSNYMigrationScript {
    static func main() async {
        print("🚀 FrancoSphere DSNY Terminology Migration Script")
        print("=" * 50)
        
        let migration = DSNYTerminologyMigration()
        
        do {
            try await migration.performMigration()
            print("\n✅ Migration completed successfully!")
        } catch {
            print("\n❌ Migration failed: \(error)")
            exit(1)
        }
    }
}

// MARK: - Utilities

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// MARK: - SQL Generation for Manual Review

extension DSNYTerminologyMigration {
    
    static func generateSQLScript() -> String {
        var sql = """
        -- DSNY Terminology Migration SQL Script
        -- Generated: \(Date())
        -- Purpose: Standardize all DSNY-related terminology
        
        -- Create backup tables
        CREATE TABLE IF NOT EXISTS routine_tasks_backup AS SELECT * FROM routine_tasks;
        CREATE TABLE IF NOT EXISTS routine_templates_backup AS SELECT * FROM routine_templates;
        
        -- Update routine_tasks
        UPDATE routine_tasks 
        SET title = 
            CASE 
                WHEN title LIKE '%Trash Management - Evening%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Trash Removal%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Put Out Trash%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%DSNY Put-Out%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Bring in trash bins%' THEN 'DSNY: Bring In Trash Bins'
                WHEN title LIKE '%DSNY Prep%' THEN 'DSNY: Bring In Trash Bins'
                WHEN title LIKE '%Recycling Management%' THEN 'DSNY: Set Out Recycling'
                WHEN title = 'DSNY Compliance' THEN 'DSNY: Compliance Check'
                WHEN title LIKE '%Rubin%DSNY%' THEN 'DSNY: Compliance Check'
                ELSE title
            END,
        category = 'sanitation'
        WHERE title LIKE '%Trash%' 
           OR title LIKE '%DSNY%' 
           OR title LIKE '%Recycling%'
           OR title LIKE '%Garbage%';
        
        -- Update routine_templates
        UPDATE routine_templates 
        SET title = 
            CASE 
                WHEN title LIKE '%Trash Management - Evening%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Trash Removal%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Put Out Trash%' THEN 'DSNY: Set Out Trash'
                WHEN title LIKE '%Recycling Management%' THEN 'DSNY: Set Out Recycling'
                WHEN title = 'DSNY Compliance' THEN 'DSNY: Compliance Check'
                ELSE title
            END,
        category = 'sanitation'
        WHERE title LIKE '%Trash%' 
           OR title LIKE '%DSNY%' 
           OR title LIKE '%Recycling%';
        
        -- Verification queries
        SELECT 'Updated Tasks' as report_type, COUNT(*) as count 
        FROM routine_tasks 
        WHERE title LIKE 'DSNY:%';
        
        SELECT 'Category Updates' as report_type, COUNT(*) as count 
        FROM routine_tasks 
        WHERE category = 'sanitation' AND title LIKE 'DSNY:%';
        
        -- Rollback script (if needed)
        -- DROP TABLE routine_tasks;
        -- ALTER TABLE routine_tasks_backup RENAME TO routine_tasks;
        -- DROP TABLE routine_templates;
        -- ALTER TABLE routine_templates_backup RENAME TO routine_templates;
        """
        
        return sql
    }
}
