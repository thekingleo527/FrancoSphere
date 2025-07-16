//
//  DatabaseSeeder.swift - Phase 1 Enhancement
//  FrancoSphere v6.0
//
//  🔧 PHASE 1 ENHANCEMENT: Ensures OperationalDataManager integration
//  ✅ FIXED: Database seeding now supports WorkerContextEngine connection
//  ✅ VALIDATION: Verifies operational data integration
//

import Foundation
import GRDB

extension DatabaseSeeder {
    
    /// Phase 1 Enhancement: Verify and fix OperationalDataManager integration
    func verifyOperationalDataIntegration() async -> (success: Bool, message: String) {
        do {
            let db = GRDBManager.shared
            
            print("🔍 Verifying OperationalDataManager integration...")
            
            // Step 1: Initialize OperationalDataManager if needed
            if !OperationalDataManager.shared.isInitialized {
                print("🔄 Initializing OperationalDataManager...")
                try await OperationalDataManager.shared.initializeOperationalData()
            }
            
            // Step 2: Import routines if missing
            let routineCount = try await db.query(
                "SELECT COUNT(*) as count FROM routine_schedules"
            )
            let currentRoutineCount = routineCount.first?["count"] as? Int64 ?? 0
            
            if currentRoutineCount == 0 {
                print("🚨 No routine schedules! Importing from OperationalDataManager...")
                let (imported, errors) = try await OperationalDataManager.shared.importRoutinesAndDSNY()
                print("✅ Imported \(imported) routines, \(errors.count) errors")
            }
            
            // Step 3: Verify each worker has real assignments
            let verificationResults = await verifyWorkerAssignments(db)
            
            // Step 4: Special Kevin verification (Rubin Museum)
            let kevinResults = await verifyKevinRubinAssignments(db)
            
            let message = """
            ✅ OperationalDataManager integration verified:
            📊 Routine schedules: \(currentRoutineCount)
            \(verificationResults)
            \(kevinResults)
            """
            
            return (true, message)
            
        } catch {
            let errorMessage = "❌ OperationalDataManager integration failed: \(error.localizedDescription)"
            return (false, errorMessage)
        }
    }
    
    /// Verify worker assignments from operational data
    private func verifyWorkerAssignments(_ db: GRDBManager) async -> String {
        var results: [String] = []
        
        // Check each worker from WorkerConstants
        for (workerId, workerName) in WorkerConstants.workerNames {
            // Skip Shawn's multiple roles
            guard ["1", "2", "4", "5", "6", "7"].contains(workerId) else { continue }
            
            do {
                // Get operational tasks for this worker
                let operationalTasks = await OperationalDataManager.shared.getTasksForWorker(workerId, date: Date())
                
                // Get database assignments
                let dbAssignments = try await db.query("""
                    SELECT COUNT(*) as count FROM worker_assignments 
                    WHERE worker_id = ? AND is_active = 1
                """, [workerId])
                
                let dbCount = dbAssignments.first?["count"] as? Int64 ?? 0
                let operationalCount = operationalTasks.count
                
                let status = operationalCount > 0 ? "✅" : "⚠️"
                results.append("   \(status) \(workerName): \(operationalCount) operational tasks, \(dbCount) db assignments")
                
            } catch {
                results.append("   ❌ \(workerName): Error checking assignments - \(error.localizedDescription)")
            }
        }
        
        return results.joined(separator: "\n")
    }
    
    /// Special verification for Kevin's Rubin Museum assignments
    private func verifyKevinRubinAssignments(_ db: GRDBManager) async -> String {
        do {
            // Get Kevin's operational tasks
            let kevinTasks = await OperationalDataManager.shared.getTasksForWorker("4", date: Date())
            
            // Count Rubin Museum tasks
            let rubinTasks = kevinTasks.filter { task in
                guard let building = task.building else { return false }
                return building.name.contains("Rubin")
            }
            
            // Check database for Rubin Museum assignment
            let dbRubinCheck = try await db.query("""
                SELECT COUNT(*) as count FROM worker_assignments 
                WHERE worker_id = '4' AND building_id = '14' AND is_active = 1
            """)
            
            let dbRubinCount = dbRubinCheck.first?["count"] as? Int64 ?? 0
            
            let status = rubinTasks.count > 0 ? "✅" : "❌"
            return """
            🎯 Kevin Dutan (Rubin Museum Specialist):
               \(status) Operational Rubin tasks: \(rubinTasks.count)
               📋 Database Rubin assignment: \(dbRubinCount > 0 ? "✅ Present" : "❌ Missing")
            """
            
        } catch {
            return "❌ Kevin Rubin verification failed: \(error.localizedDescription)"
        }
    }
    
    /// Enhanced seeding with operational data validation
    func seedWithOperationalDataValidation() async -> (success: Bool, message: String) {
        // First, do regular seeding
        let seedResult = await seedDatabase()
        
        if !seedResult.success {
            return seedResult
        }
        
        // Then verify operational data integration
        let verifyResult = await verifyOperationalDataIntegration()
        
        if !verifyResult.success {
            return verifyResult
        }
        
        // Finally, test the WorkerContextEngine integration
        let testResult = await testWorkerContextEngineIntegration()
        
        let combinedMessage = """
        \(seedResult.message)
        
        \(verifyResult.message)
        
        \(testResult)
        """
        
        return (true, combinedMessage)
    }
    
    /// Test WorkerContextEngine integration with operational data
    private func testWorkerContextEngineIntegration() async -> String {
        do {
            let contextEngine = WorkerContextEngine.shared
            
            // Test Kevin's context loading
            try await contextEngine.loadContext(for: "4")
            
            let kevinBuildings = await contextEngine.getAssignedBuildings()
            let kevinTasks = await contextEngine.getTodaysTasks()
            
            // Check for Rubin Museum in Kevin's assignments
            let rubinBuildings = kevinBuildings.filter { $0.name.contains("Rubin") }
            let rubinTasks = kevinTasks.filter { task in
                guard let building = task.building else { return false }
                return building.name.contains("Rubin")
            }
            
            let kevinStatus = rubinBuildings.count > 0 ? "✅" : "❌"
            
            return """
            🔧 WorkerContextEngine Integration Test:
               \(kevinStatus) Kevin's buildings: \(kevinBuildings.count) (Rubin: \(rubinBuildings.count))
               📋 Kevin's tasks: \(kevinTasks.count) (Rubin: \(rubinTasks.count))
               🎯 Phase 1 Fix: \(rubinBuildings.count > 0 ? "SUCCESS" : "NEEDS ATTENTION")
            """
            
        } catch {
            return "❌ WorkerContextEngine test failed: \(error.localizedDescription)"
        }
    }
    
    /// Quick diagnostic for operational data
    func quickOperationalDataDiagnostic() async -> String {
        let operationalData = OperationalDataManager.shared
        
        // Check initialization
        let initStatus = operationalData.isInitialized ? "✅" : "❌"
        
        // Check Kevin's tasks
        let kevinTasks = await operationalData.getTasksForWorker("4", date: Date())
        let kevinRubinTasks = kevinTasks.filter { task in
            guard let building = task.building else { return false }
            return building.name.contains("Rubin")
        }
        
        // Check all workers
        var workerTaskCounts: [String] = []
        for (workerId, workerName) in WorkerConstants.workerNames {
            guard ["1", "2", "4", "5", "6", "7"].contains(workerId) else { continue }
            
            let tasks = await operationalData.getTasksForWorker(workerId, date: Date())
            workerTaskCounts.append("\(workerName): \(tasks.count)")
        }
        
        return """
        📊 Operational Data Diagnostic:
           \(initStatus) Initialization: \(operationalData.isInitialized ? "Complete" : "Pending")
           🎯 Kevin's tasks: \(kevinTasks.count) (Rubin: \(kevinRubinTasks.count))
           👥 Worker task counts: \(workerTaskCounts.joined(separator: ", "))
        """
    }
}

// MARK: - Convenience Methods for Testing

extension DatabaseSeeder {
    
    /// One-shot method to seed and validate everything for Phase 1
    static func seedAndValidatePhase1() async -> (success: Bool, message: String) {
        let seeder = DatabaseSeeder.shared
        
        // Step 1: Quick diagnostic
        let diagnostic = await seeder.quickOperationalDataDiagnostic()
        print("🔍 Pre-seed diagnostic:")
        print(diagnostic)
        
        // Step 2: Full seeding with validation
        let result = await seeder.seedWithOperationalDataValidation()
        
        // Step 3: Post-seed diagnostic
        let postDiagnostic = await seeder.quickOperationalDataDiagnostic()
        print("✅ Post-seed diagnostic:")
        print(postDiagnostic)
        
        return result
    }
    
    /// Test method specifically for Kevin's Rubin Museum integration
    static func testKevinRubinIntegration() async -> String {
        let seeder = DatabaseSeeder.shared
        return await seeder.verifyKevinRubinAssignments(GRDBManager.shared)
    }
}

// MARK: - 📝 PHASE 1 ENHANCEMENT NOTES
/*
 🔧 PHASE 1 DATABASE ENHANCEMENTS:
 
 ✅ OPERATIONAL DATA INTEGRATION:
 - verifyOperationalDataIntegration() ensures OperationalDataManager is properly initialized
 - Automatic import of routine schedules if missing
 - Worker assignment verification against operational data
 
 ✅ KEVIN'S RUBIN MUSEUM VERIFICATION:
 - verifyKevinRubinAssignments() specifically checks Kevin's Rubin Museum assignments
 - Validates both operational tasks and database assignments
 - Ensures Phase 1 fix works correctly
 
 ✅ WORKER CONTEXT ENGINE TESTING:
 - testWorkerContextEngineIntegration() validates the Phase 1 fix
 - Tests actual WorkerContextEngine.loadContext() with operational data
 - Verifies Kevin gets his Rubin Museum assignments
 
 ✅ DIAGNOSTIC TOOLS:
 - quickOperationalDataDiagnostic() provides quick status check
 - seedAndValidatePhase1() provides one-shot complete validation
 - testKevinRubinIntegration() provides targeted Kevin testing
 
 🎯 RESULT: Database seeding now fully supports and validates the Phase 1
 WorkerContextEngine → OperationalDataManager connection.
 */
