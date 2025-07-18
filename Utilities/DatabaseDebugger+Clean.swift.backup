//
//  DatabaseDebugger+Clean.swift
//  FrancoSphere v6.0 - CLEANED: Removed conflicting seeding logic
//
//  ✅ DIAGNOSTIC ONLY: No seeding, only verification
//  ✅ OPERATIONAL: Uses OperationalDataManager for validation
//

import Foundation

extension DatabaseDebugger {
    
    /// CLEANED: Verify database without conflicting seeding
    static func verifyDatabaseWithOperationalData() async -> (success: Bool, message: String) {
        print("🔍 Verifying database with OperationalDataManager integration...")
        
        let grdbManager = GRDBManager.shared
        let operationalData = OperationalDataManager.shared
        
        var issues: [String] = []
        var successes: [String] = []
        
        // Step 1: Check database connectivity
        do {
            let testQuery = try await grdbManager.query("SELECT 1 as test", [])
            if testQuery.isEmpty {
                issues.append("Database query failed")
            } else {
                successes.append("Database connectivity verified")
            }
        } catch {
            issues.append("Database connection failed: \(error)")
        }
        
        // Step 2: Check core tables exist
        let requiredTables = ["workers", "buildings", "tasks"]
        for table in requiredTables {
            do {
                let count = try await grdbManager.query("SELECT COUNT(*) as count FROM \(table)", [])
                let recordCount = count.first?["count"] as? Int64 ?? 0
                
                if recordCount > 0 {
                    successes.append("\(table): \(recordCount) records")
                } else {
                    issues.append("\(table): Empty or missing")
                }
            } catch {
                issues.append("\(table): Query failed - \(error)")
            }
        }
        
        // Step 3: Check OperationalDataManager
        let realTaskCount = await operationalData.realWorldTasks.count
        if realTaskCount > 0 {
            successes.append("OperationalDataManager: \(realTaskCount) real tasks")
            
            // Check worker assignments in operational data
            let workerDistribution = await operationalData.getWorkerTaskDistribution()
            for (worker, taskCount) in workerDistribution {
                successes.append("  \(worker): \(taskCount) operational tasks")
            }
        } else {
            issues.append("OperationalDataManager: No real world tasks found")
        }
        
        // Step 4: Check specific worker data (Kevin)
        let kevinTasks = await operationalData.realWorldTasks.filter { 
            $0.assignedWorker == "Kevin Dutan" 
        }
        let kevinRubinTasks = kevinTasks.filter { 
            $0.building.contains("Rubin") 
        }
        
        if !kevinRubinTasks.isEmpty {
            successes.append("Kevin's Rubin Museum assignments: \(kevinRubinTasks.count) tasks")
        } else {
            issues.append("Kevin's Rubin Museum assignments: Not found")
        }
        
        // Step 5: Generate summary
        let totalIssues = issues.count
        let totalSuccesses = successes.count
        
        let message = """
        📊 Database Verification Results:
        
        ✅ Successes (\(totalSuccesses)):
        \(successes.map { "   • \($0)" }.joined(separator: "\n"))
        
        ⚠️ Issues (\(totalIssues)):
        \(issues.map { "   • \($0)" }.joined(separator: "\n"))
        
        📋 Recommendation:
        \(totalIssues == 0 ? "✅ Database is ready" : "🔧 Run OperationalDataManager.shared.initializeOperationalData()")
        """
        
        return (success: totalIssues == 0, message: message)
    }
    
    /// Quick diagnostic for Kevin's specific data
    static func verifyKevinData() async -> String {
        let operationalData = OperationalDataManager.shared
        
        let kevinTasks = await operationalData.realWorldTasks.filter { 
            $0.assignedWorker == "Kevin Dutan" 
        }
        
        let buildings = Set(kevinTasks.map { $0.building })
        let rubinTasks = kevinTasks.filter { $0.building.contains("Rubin") }
        
        return """
        👤 Kevin Dutan Verification:
           Total Tasks: \(kevinTasks.count)
           Buildings: \(buildings.count) (\(buildings.joined(separator: ", ")))
           Rubin Museum Tasks: \(rubinTasks.count)
           Status: \(rubinTasks.isEmpty ? "❌ Missing Rubin assignments" : "✅ Rubin assignments confirmed")
        """
    }
}
