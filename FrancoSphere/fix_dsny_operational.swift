#!/usr/bin/env swift

import Foundation

// MARK: - OperationalDataManager DSNY Fix Script
// This script updates the OperationalDataManager.swift file to use standardized DSNY terminology

struct DSNYOperationalFix {
    
    // Mapping of old task names to new standardized names
    static let taskNameMappings: [(old: String, new: String)] = [
        ("Trash Management - Evening", "DSNY: Set Out Trash"),
        ("Trash Removal", "DSNY: Set Out Trash"),
        ("Trash removal", "DSNY: Set Out Trash"),
        ("Put Out Trash", "DSNY: Set Out Trash"),
        ("DSNY Put-Out (after 20:00)", "DSNY: Set Out Trash"),
        ("Bring in trash bins", "DSNY: Bring In Trash Bins"),
        ("DSNY Prep / Move Bins", "DSNY: Bring In Trash Bins"),
        ("Recycling Management", "DSNY: Set Out Recycling"),
        ("DSNY Compliance", "DSNY: Compliance Check"),
        ("Rubin Museum DSNY", "DSNY: Compliance Check"),
        ("Rubin DSNY Operations", "DSNY: Compliance Check"),
        ("DSNY Compliance Check", "DSNY: Compliance Check")
    ]
    
    static func fixOperationalDataManager(at filePath: String) throws {
        print("📄 Reading OperationalDataManager.swift...")
        
        var content = try String(contentsOfFile: filePath, encoding: .utf8)
        let originalContent = content
        var changesCount = 0
        
        // Fix task names
        print("\n🔧 Fixing task names...")
        for mapping in taskNameMappings {
            let oldPattern = "taskName: \"\(mapping.old)\""
            let newPattern = "taskName: \"\(mapping.new)\""
            
            let occurrences = content.components(separatedBy: oldPattern).count - 1
            if occurrences > 0 {
                content = content.replacingOccurrences(of: oldPattern, with: newPattern)
                changesCount += occurrences
                print("  ✓ Replaced '\(mapping.old)' → '\(mapping.new)' (\(occurrences) occurrences)")
            }
        }
        
        // Fix categories for DSNY tasks
        print("\n🔧 Fixing categories for DSNY tasks...")
        
        // Pattern to find DSNY tasks with maintenance category
        let lines = content.components(separatedBy: .newlines)
        var updatedLines: [String] = []
        var inDSNYTask = false
        var categoryFixed = 0
        
        for i in 0..<lines.count {
            var line = lines[i]
            
            // Check if we're starting a DSNY task
            if line.contains("taskName:") && line.contains("DSNY:") {
                inDSNYTask = true
            }
            
            // If we're in a DSNY task and find a maintenance category, fix it
            if inDSNYTask && line.contains("category: \"maintenance\"") {
                line = line.replacingOccurrences(of: "category: \"maintenance\"", with: "category: \"sanitation\"")
                categoryFixed += 1
                inDSNYTask = false // Reset for next task
            }
            
            // Reset if we hit a new task or closing bracket
            if line.contains("),") || (line.contains("OperationalDataTaskAssignment(") && !line.contains("taskName:")) {
                inDSNYTask = false
            }
            
            updatedLines.append(line)
        }
        
        if categoryFixed > 0 {
            content = updatedLines.joined(separator: "\n")
            changesCount += categoryFixed
            print("  ✓ Fixed \(categoryFixed) category assignments from 'maintenance' to 'sanitation'")
        }
        
        // Remove hardcoded schedule logic
        print("\n🔧 Looking for hardcoded schedule logic...")
        
        // Pattern: if building.name.contains("Rubin") && taskType == "DSNY Compliance"
        let schedulePattern = #"if\s+building\.name\.contains\("Rubin"\)\s*&&\s*taskType\s*==\s*"DSNY Compliance"#
        if content.contains(schedulePattern) {
            print("  ⚠️ Found hardcoded Rubin Museum DSNY schedule logic - consider removing")
            // Add comment above the code
            content = content.replacingOccurrences(
                of: schedulePattern,
                with: "// TODO: Remove hardcoded schedule - use DSNYAPIService instead\n        " + schedulePattern
            )
            changesCount += 1
        }
        
        // Check if any changes were made
        if content == originalContent {
            print("\n✅ No changes needed - file is already up to date!")
        } else {
            // Create backup
            let backupPath = filePath + ".backup_\(Int(Date().timeIntervalSince1970))"
            try originalContent.write(toFile: backupPath, atomically: true, encoding: .utf8)
            print("\n💾 Created backup at: \(backupPath)")
            
            // Write updated content
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            print("✅ Updated OperationalDataManager.swift with \(changesCount) changes")
        }
        
        // Generate summary
        print("\n📊 Summary of standardized DSNY task names:")
        print("  • DSNY: Set Out Trash")
        print("  • DSNY: Bring In Trash Bins")
        print("  • DSNY: Set Out Recycling")
        print("  • DSNY: Compliance Check")
        
        print("\n💡 Next steps:")
        print("  1. Review the changes with: git diff OperationalDataManager.swift")
        print("  2. Run the database migration script to update existing records")
        print("  3. Test with Kevin's account to verify Rubin Museum tasks")
    }
    
    // Helper to find the file
    static func findOperationalDataManager(in directory: String = FileManager.default.currentDirectoryPath) -> String? {
        let fileManager = FileManager.default
        
        if let enumerator = fileManager.enumerator(atPath: directory) {
            while let file = enumerator.nextObject() as? String {
                if file.hasSuffix("OperationalDataManager.swift") {
                    return "\(directory)/\(file)"
                }
            }
        }
        
        return nil
    }
}

// MARK: - Main Execution

print("🚀 DSNY OperationalDataManager Fix Script")
print("=====================================")

// Try to find the file
if let filePath = DSNYOperationalFix.findOperationalDataManager() {
    print("✅ Found OperationalDataManager.swift at:")
    print("   \(filePath)")
    
    do {
        try DSNYOperationalFix.fixOperationalDataManager(at: filePath)
    } catch {
        print("\n❌ Error: \(error)")
        exit(1)
    }
} else {
    print("\n❌ Could not find OperationalDataManager.swift")
    print("💡 Please run this script from your Xcode project directory")
    print("   or specify the path manually")
    exit(1)
}

// MARK: - Manual Usage Instructions

/*
To run this script:

1. Save it as fix_dsny_operational.swift
2. Make it executable: chmod +x fix_dsny_operational.swift
3. Run from your project directory: ./fix_dsny_operational.swift

Or run directly in Terminal:
swift fix_dsny_operational.swift

Or integrate into your project:
try DSNYOperationalFix.fixOperationalDataManager(at: "path/to/OperationalDataManager.swift")
*/
