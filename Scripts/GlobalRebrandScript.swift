//
//  GlobalRebrandScript.swift
//  CyntientOps Phase 12
//
//  Automated script to rebrand CyntientOps to CyntientOps across entire codebase
//  Handles file contents, comments, strings, database names, and project references
//

import Foundation

@MainActor
class GlobalRebrandManager {
    
    private let projectRoot = "/Volumes/FastSSD/Xcode/CyntientOps"
    
    // Rebrand mapping
    private let rebrandMappings: [String: String] = [
        "CyntientOps": "CyntientOps",
        "francosphere": "cyntientops",  
        "FRANCOSPHERE": "CYNTIENTOPS",
        "franco_sphere": "cyntient_ops",
        "FRANCO_SPHERE": "CYNTIENT_OPS"
    ]
    
    // File extensions to process
    private let processableExtensions = [
        ".swift", ".h", ".m", ".mm", ".cpp", ".hpp", 
        ".plist", ".strings", ".md", ".txt", ".json", 
        ".yml", ".yaml", ".pbxproj", ".xcconfig"
    ]
    
    // Files to exclude from processing
    private let excludedPaths = [
        "/.git/",
        "/build/", 
        "/Pods/",
        "/DerivedData/",
        "/.build/",
        "/Scripts/GlobalRebrandScript.swift" // Don't rebrand this script
    ]
    
    func performGlobalRebrand() async {
        print("🚀 STARTING GLOBAL FRANCOSPHERE → CYNTIENTOPS REBRAND")
        print("=" * 80)
        
        let startTime = Date()
        var processedFiles = 0
        var modifiedFiles = 0
        var errors: [String] = []
        
        do {
            // Get all files to process
            let allFiles = try await getAllProcessableFiles()
            print("📁 Found \(allFiles.count) files to process")
            
            // Process each file
            for filePath in allFiles {
                do {
                    let wasModified = try await processFile(filePath)
                    processedFiles += 1
                    
                    if wasModified {
                        modifiedFiles += 1
                        print("✏️  Modified: \(filePath.replacingOccurrences(of: projectRoot, with: ""))")
                    }
                    
                    if processedFiles % 50 == 0 {
                        print("📊 Progress: \(processedFiles)/\(allFiles.count) files processed")
                    }
                    
                } catch {
                    let errorMsg = "Failed to process \(filePath): \(error)"
                    errors.append(errorMsg)
                    print("❌ \(errorMsg)")
                }
            }
            
        } catch {
            print("❌ FATAL ERROR: Failed to get file list: \(error)")
            return
        }
        
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n" + "=" * 80)
        print("🎯 GLOBAL REBRAND RESULTS")
        print("=" * 80)
        print("📁 Files Processed: \(processedFiles)")
        print("✏️  Files Modified: \(modifiedFiles)")
        print("⚠️  Errors: \(errors.count)")
        print("⏱️  Duration: \(String(format: "%.2f", duration)) seconds")
        
        if !errors.isEmpty {
            print("\n🚨 ERRORS ENCOUNTERED:")
            for error in errors.prefix(10) {
                print("   • \(error)")
            }
            if errors.count > 10 {
                print("   ... and \(errors.count - 10) more errors")
            }
        }
        
        if errors.isEmpty {
            print("\n🎉 GLOBAL REBRAND COMPLETED SUCCESSFULLY!")
            print("✨ CyntientOps rebrand is complete")
            
            await generateRebrandReport(
                processedFiles: processedFiles,
                modifiedFiles: modifiedFiles,
                duration: duration
            )
            
        } else {
            print("\n⚠️  REBRAND COMPLETED WITH ERRORS")
            print("Please review and manually fix the errors listed above")
        }
        
        print("=" * 80)
    }
    
    private func getAllProcessableFiles() async throws -> [String] {
        let fileManager = FileManager.default
        var processableFiles: [String] = []
        
        let enumerator = fileManager.enumerator(atPath: projectRoot)
        
        while let relativePath = enumerator?.nextObject() as? String {
            let fullPath = "\(projectRoot)/\(relativePath)"
            
            // Skip excluded paths
            if excludedPaths.contains(where: { fullPath.contains($0) }) {
                continue
            }
            
            // Check if it's a processable file
            let pathExtension = "." + (fullPath as NSString).pathExtension
            if processableExtensions.contains(pathExtension) {
                
                var isDirectory: ObjCBool = false
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) && 
                   !isDirectory.boolValue {
                    processableFiles.append(fullPath)
                }
            }
        }
        
        return processableFiles
    }
    
    private func processFile(_ filePath: String) async throws -> Bool {
        let originalContent = try String(contentsOfFile: filePath, encoding: .utf8)
        var modifiedContent = originalContent
        var wasModified = false
        
        // Apply all rebrand mappings
        for (from, to) in rebrandMappings {
            let newContent = modifiedContent.replacingOccurrences(of: from, with: to)
            if newContent != modifiedContent {
                modifiedContent = newContent
                wasModified = true
            }
        }
        
        // Handle special cases
        modifiedContent = try await applySpecialCases(modifiedContent, filePath: filePath)
        if modifiedContent != originalContent && !wasModified {
            wasModified = true
        }
        
        // Write back if modified
        if wasModified {
            try modifiedContent.write(to: URL(fileURLWithPath: filePath), atomically: true, encoding: .utf8)
        }
        
        return wasModified
    }
    
    private func applySpecialCases(_ content: String, filePath: String) async throws -> String {
        var modifiedContent = content
        
        // Handle database file names
        modifiedContent = modifiedContent.replacingOccurrences(
            of: "CyntientOps.sqlite", 
            with: "CyntientOps.sqlite"
        )
        
        // Handle bundle identifiers
        modifiedContent = modifiedContent.replacingOccurrences(
            of: "com.francosphere", 
            with: "com.cyntientops"
        )
        
        // Handle URL schemes
        modifiedContent = modifiedContent.replacingOccurrences(
            of: "francosphere://", 
            with: "cyntientops://"
        )
        
        // Handle keychain identifiers
        modifiedContent = modifiedContent.replacingOccurrences(
            of: "CyntientOpsKeychain", 
            with: "CyntientOpsKeychain"
        )
        
        // Handle UserDefaults keys
        modifiedContent = modifiedContent.replacingOccurrences(
            of: "CyntientOps_", 
            with: "CyntientOps_"
        )
        
        // Handle file-specific cases
        let fileName = (filePath as NSString).lastPathComponent
        
        switch fileName {
        case "project.pbxproj":
            // Handle Xcode project-specific rebranding
            modifiedContent = modifiedContent.replacingOccurrences(
                of: "PRODUCT_NAME = CyntientOps",
                with: "PRODUCT_NAME = CyntientOps"
            )
            modifiedContent = modifiedContent.replacingOccurrences(
                of: "PRODUCT_BUNDLE_IDENTIFIER = com.francosphere",
                with: "PRODUCT_BUNDLE_IDENTIFIER = com.cyntientops"
            )
            
        case _ where fileName.hasSuffix(".plist"):
            // Handle plist-specific rebranding
            modifiedContent = modifiedContent.replacingOccurrences(
                of: "<string>CyntientOps</string>",
                with: "<string>CyntientOps</string>"
            )
            
        case "Info.plist", "CyntientOps-Info.plist":
            // Handle app info plist
            modifiedContent = modifiedContent.replacingOccurrences(
                of: "<key>CFBundleName</key>\n\t<string>CyntientOps</string>",
                with: "<key>CFBundleName</key>\n\t<string>CyntientOps</string>"
            )
            modifiedContent = modifiedContent.replacingOccurrences(
                of: "<key>CFBundleDisplayName</key>\n\t<string>CyntientOps</string>",
                with: "<key>CFBundleDisplayName</key>\n\t<string>CyntientOps</string>"
            )
            
        case _ where fileName.hasSuffix(".strings"):
            // Handle localization strings
            modifiedContent = modifiedContent.replacingOccurrences(
                of: "\"CyntientOps\"",
                with: "\"CyntientOps\""
            )
            
        default:
            break
        }
        
        return modifiedContent
    }
    
    private func generateRebrandReport(
        processedFiles: Int, 
        modifiedFiles: Int, 
        duration: TimeInterval
    ) async {
        
        let report = """
        # CyntientOps Global Rebrand Report
        Generated: \(Date().formatted())
        
        ## Summary
        - **Files Processed**: \(processedFiles)
        - **Files Modified**: \(modifiedFiles)
        - **Success Rate**: \(String(format: "%.1f%%", Double(modifiedFiles) / Double(processedFiles) * 100))
        - **Duration**: \(String(format: "%.2f", duration)) seconds
        
        ## Rebrand Mappings Applied
        - `CyntientOps` → `CyntientOps`
        - `francosphere` → `cyntientops`
        - `FRANCOSPHERE` → `CYNTIENTOPS`
        - `franco_sphere` → `cyntient_ops`
        - `FRANCO_SPHERE` → `CYNTIENT_OPS`
        
        ## Special Cases Handled
        - Database file names: `CyntientOps.sqlite` → `CyntientOps.sqlite`
        - Bundle identifiers: `com.francosphere` → `com.cyntientops`
        - URL schemes: `francosphere://` → `cyntientops://`
        - Keychain identifiers: Updated to CyntientOps
        - UserDefaults keys: Updated prefixes
        - Xcode project settings
        - Localization strings
        
        ## File Types Processed
        - Swift source files (.swift)
        - Objective-C files (.h, .m, .mm)
        - Property lists (.plist)
        - Localization files (.strings)
        - Documentation (.md)
        - Configuration files (.json, .yml)
        - Xcode project files (.pbxproj)
        
        ## Post-Rebrand Checklist
        
        ### Required Manual Steps:
        - [ ] Rename project folder from "CyntientOps" to "CyntientOps"
        - [ ] Rename Xcode project file if needed
        - [ ] Update scheme names in Xcode
        - [ ] Verify app icon and display name
        - [ ] Update App Store metadata
        - [ ] Check and update any hardcoded strings
        - [ ] Test all dashboard functionality
        - [ ] Verify Nova AI integration still works
        - [ ] Run production readiness tests
        
        ### Testing Required:
        - [ ] Kevin has 38 tasks (critical data test)
        - [ ] Rubin Museum assignment (critical data test)
        - [ ] Client data filtering works correctly
        - [ ] Database connections functional
        - [ ] Nova AI singleton persistence
        - [ ] All three dashboards load correctly
        - [ ] Authentication flow works
        - [ ] NYC API integration functional
        
        ## Status
        ✅ **GLOBAL REBRAND COMPLETED SUCCESSFULLY**
        
        The CyntientOps → CyntientOps rebrand has been completed across:
        - All source code files
        - Configuration files
        - Documentation
        - Database references
        - UI strings and labels
        
        **Next Steps**: Complete manual checklist above and run comprehensive testing.
        
        ---
        Report generated by CyntientOps Automated Rebrand System
        """
        
        // Save report
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let reportURL = documentsPath.appendingPathComponent("CyntientOps_Rebrand_Report.md")
        
        do {
            try report.write(to: reportURL, atomically: true, encoding: .utf8)
            print("📄 Rebrand report saved to: \(reportURL.path)")
        } catch {
            print("❌ Failed to save rebrand report: \(error)")
        }
    }
}

// MARK: - Execution

func performGlobalRebrand() async {
    let rebrander = GlobalRebrandManager()
    await rebrander.performGlobalRebrand()
}

// Execute if run as script
if CommandLine.arguments.contains("--execute-rebrand") {
    print("⚠️  WARNING: This will rebrand ALL files from CyntientOps to CyntientOps")
    print("⚠️  This operation cannot be easily undone!")
    print("Press ENTER to continue or Ctrl+C to cancel...")
    _ = readLine()
    
    Task {
        await performGlobalRebrand()
        exit(0)
    }
    RunLoop.main.run()
} else {
    print("📋 Global Rebrand Script Ready")
    print("Usage: swift GlobalRebrandScript.swift --execute-rebrand")
    print("")
    print("⚠️  WARNING: This will rebrand the entire codebase!")
    print("Ensure you have a backup before running.")
}

// MARK: - Helper Extensions

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}

extension Date {
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}