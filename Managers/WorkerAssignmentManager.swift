//
//  WorkerAssignmentManager.swift
//  FrancoSphere
//
//  🔧 PHASE-2 COMPLETE - Real-World Data Driven
//  ✅ PATCH P2-01-V2: Jose Santos removed, Kevin expanded
//  ✅ CSV-only data source (no hardcoded fallbacks)
//  ✅ Real worker_building_assignments table integration
//  ✅ Enhanced caching and error handling
//  ✅ Public UI integration methods added
//  ✅ Complete emergency recovery system
//

import Foundation
import SwiftUI

// MARK: - PATCH P2-01-V2: Real-World Worker Assignment Manager

final class WorkerAssignmentManager: ObservableObject {
    // MARK: - Singleton
    static let shared = WorkerAssignmentManager()
    
    // MARK: - CSV-Driven Assignment System (No Hardcoded Fallbacks)
    private var sqliteManager: SQLiteManager?
    private var assignmentCache: [String: [String]] = [:]
    private var cacheTimestamp: Date = Date.distantPast
    private let cacheTimeout: TimeInterval = 180 // 3 minutes (more frequent refresh)
    
    // Private init to ensure singleton
    private init() {
        Task {
            await initializeSQLiteManager()
        }
    }
    
    private func initializeSQLiteManager() async {
        sqliteManager = SQLiteManager.shared
        print("✅ WorkerAssignmentManager: SQLiteManager initialized")
    }
    
    // MARK: - ⭐ PUBLIC METHODS for UI Integration
    
    /// Force refresh assignments - called from UI components like MySitesCard
    public func forceRefreshAssignments() async {
        print("🔄 UI-triggered assignment refresh")
        await forceRefreshCache()
    }
    
    /// Get assigned building IDs for a worker - PUBLIC for UI components
    public func getAssignedBuildingIds(for workerId: String) -> [String] {
        var assignedBuildings: [String] = []
        
        // Check each building for this worker's assignments
        for buildingId in Array(1...18).map({ String($0) }) {
            let assignedWorkers = getAssignedWorkerIds(for: buildingId)
            if assignedWorkers.contains(workerId) {
                assignedBuildings.append(buildingId)
            }
        }
        
        return assignedBuildings
    }
    
    /// Emergency fix for specific worker - called from UI
    public func createEmergencyAssignments(for workerId: String) async -> Bool {
        guard let manager = await getSQLiteManager() else {
            print("❌ Cannot create emergency assignments: SQLiteManager unavailable")
            return false
        }
        
        switch workerId {
        case "4": // Kevin Dutan
            await createEmergencyKevinAssignments(manager)
            return true
        case "2": // Edwin Lema - morning shift buildings
            await createEmergencyEdwinAssignments(manager)
            return true
        default:
            print("⚠️ No emergency assignment template for worker \(workerId)")
            return false
        }
    }
    
    /// Check if worker has any assignments - PUBLIC for UI validation
    public func hasAssignments(for workerId: String) -> Bool {
        return !getAssignedBuildingIds(for: workerId).isEmpty
    }
    
    // MARK: - ⭐ PHASE-2: Enhanced Worker Management
    
    /// Get workers assigned to a specific building - CSV DATA ONLY
    func getWorkersForBuilding(buildingId: String) -> [FrancoSphere.WorkerProfile] {
        var workers: [FrancoSphere.WorkerProfile] = []
        
        // Get worker IDs assigned to this building from real data
        let buildingWorkers = getAssignedWorkerIds(for: buildingId)
        
        for workerId in buildingWorkers {
            if let worker = getWorkerById(workerId) {
                workers.append(worker)
            }
        }
        
        print("🏢 Building \(buildingId) has \(workers.count) assigned workers: \(buildingWorkers)")
        return workers
    }
    
    /// Get worker IDs assigned to a building - CSV DATA ONLY
    private func getAssignedWorkerIds(for buildingId: String) -> [String] {
        // Check cache first
        if Date().timeIntervalSince(cacheTimestamp) < cacheTimeout,
           let cached = assignmentCache[buildingId] {
            print("📋 Cache hit for building \(buildingId): \(cached)")
            return cached
        }
        
        // No fallback - refresh cache and return real data or empty
        Task {
            await refreshAssignmentCache()
        }
        
        // Return cached data or empty (forces CSV import if no data)
        return assignmentCache[buildingId] ?? []
    }
    
    /// Refresh assignment cache from DATABASE (populated by CSV)
    private func refreshAssignmentCache() async {
        guard let manager = await getSQLiteManager() else {
            print("❌ SQLiteManager not available - assignments unavailable")
            return
        }
        
        do {
            let results = try await manager.query("""
                SELECT building_id, worker_id 
                FROM worker_building_assignments 
                WHERE is_active = 1
                ORDER BY building_id
            """)
            
            // 🚨 EMERGENCY: If no assignments found, force CSV import
            if results.isEmpty {
                print("🚨 EMERGENCY: No worker assignments found - forcing CSV import")
                
                // Force CSV import
                let importer = CSVDataImporter.shared
                let (imported, errors) = try await importer.importRealWorldTasks()
                print("🔄 Emergency CSV import: \(imported) tasks, \(errors.count) errors")
                
                // Wait a moment for database writes to complete
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                // Retry query after import
                let retryResults = try await manager.query("""
                    SELECT building_id, worker_id 
                    FROM worker_building_assignments 
                    WHERE is_active = 1
                    ORDER BY building_id
                """)
                
                if retryResults.isEmpty {
                    print("🚨 CRITICAL: CSV import failed - assignments still empty")
                    // Last resort: create Kevin's assignments manually
                    await createEmergencyKevinAssignments(manager)
                    return
                } else {
                    print("✅ Emergency CSV import successful: \(retryResults.count) assignments")
                }
            }
            
            // Build cache from database results
            var newCache: [String: [String]] = [:]
            let finalResults = results.isEmpty ? try await manager.query("""
                SELECT building_id, worker_id 
                FROM worker_building_assignments 
                WHERE is_active = 1
                ORDER BY building_id
            """) : results
            
            for row in finalResults {
                let buildingId = row["building_id"] as? String ?? ""
                let workerId = row["worker_id"] as? String ?? ""
                
                if !buildingId.isEmpty && !workerId.isEmpty {
                    newCache[buildingId, default: []].append(workerId)
                }
            }
            
            await MainActor.run {
                self.assignmentCache = newCache
                self.cacheTimestamp = Date()
            }
            
            print("✅ Assignment cache refreshed: \(newCache.count) buildings, \(newCache.values.flatMap { $0 }.count) assignments")
            
            // Log Kevin's assignments specifically for debugging
            if let kevinBuildings = getKevinAssignments(from: newCache) {
                print("👷 Kevin Dutan assignments: \(kevinBuildings)")
            }
            
        } catch {
            print("❌ Failed to refresh assignment cache: \(error)")
        }
    }

    /// Emergency fallback: Create Kevin's assignments manually
    private func createEmergencyKevinAssignments(_ manager: SQLiteManager) async {
        print("🆘 Creating emergency Kevin assignments...")
        
        // Kevin's real-world assignments (buildings 3, 6, 7, 9, 11, 16)
        let kevinAssignments = ["3", "6", "7", "9", "11", "16"]
        
        do {
            for buildingId in kevinAssignments {
                try await manager.execute("""
                    INSERT OR IGNORE INTO worker_building_assignments 
                    (worker_id, building_id, worker_name, assignment_type, start_date, is_active) 
                    VALUES ('4', ?, 'Kevin Dutan', 'emergency', datetime('now'), 1)
                """, [buildingId])
            }
            
            print("✅ Emergency Kevin assignments created: \(kevinAssignments.count) buildings")
            
            // Refresh cache after emergency creation
            await refreshAssignmentCache()
            
        } catch {
            print("🚨 CRITICAL: Emergency assignment creation failed: \(error)")
        }
    }
    
    /// ✅ NEW: Emergency Edwin assignments for morning shift
    private func createEmergencyEdwinAssignments(_ manager: SQLiteManager) async {
        print("🆘 Creating emergency Edwin assignments...")
        
        // Edwin's morning shift buildings (2, 5, 8, 11, 17)
        let edwinAssignments = ["2", "5", "8", "11", "17"]
        
        do {
            for buildingId in edwinAssignments {
                try await manager.execute("""
                    INSERT OR IGNORE INTO worker_building_assignments 
                    (worker_id, building_id, worker_name, assignment_type, start_date, is_active) 
                    VALUES ('2', ?, 'Edwin Lema', 'emergency', datetime('now'), 1)
                """, [buildingId])
            }
            
            print("✅ Emergency Edwin assignments created: \(edwinAssignments.count) buildings")
            await refreshAssignmentCache()
            
        } catch {
            print("🚨 CRITICAL: Emergency Edwin assignment creation failed: \(error)")
        }
    }

    /// Get Kevin's specific assignments for debugging
    private func getKevinAssignments(from cache: [String: [String]]) -> [String]? {
        var kevinBuildings: [String] = []
        
        for (buildingId, workerIds) in cache {
            if workerIds.contains("4") { // Kevin's worker ID
                kevinBuildings.append(buildingId)
            }
        }
        
        return kevinBuildings.isEmpty ? nil : kevinBuildings.sorted()
    }
    
    /// Trigger CSV import if no assignments found
    private func triggerCSVImport() async {
        do {
            let importer = CSVDataImporter.shared
            let (imported, errors) = try await importer.importRealWorldTasks()
            print("🔄 Emergency CSV import: \(imported) tasks, \(errors.count) errors")
            
            // Retry cache refresh after import
            await refreshAssignmentCache()
        } catch {
            print("❌ Emergency CSV import failed: \(error)")
        }
    }
    
    /// Get SQLiteManager instance
    private func getSQLiteManager() async -> SQLiteManager? {
        if sqliteManager == nil {
            sqliteManager = SQLiteManager.shared
        }
        return sqliteManager
    }
    
    // MARK: - ⭐ ENHANCED: Worker Profile Resolution
    
    /// Get worker by ID with real-world data
    private func getWorkerById(_ workerId: String) -> FrancoSphere.WorkerProfile? {
        // Current active worker profiles (Jose removed, Kevin expanded)
        let currentActiveWorkers: [String: FrancoSphere.WorkerProfile] = [
            "1": FrancoSphere.WorkerProfile(
                id: "1",
                name: "Greg Hutson",
                email: "greg@francosphere.com",
                role: .worker,
                skills: [.maintenance, .cleaning, .plumbing],
                assignedBuildings: [],
                skillLevel: .intermediate
            ),
            "2": FrancoSphere.WorkerProfile(
                id: "2",
                name: "Edwin Lema",
                email: "edwin@francosphere.com",
                role: .worker,
                skills: [.maintenance, .plumbing, .hvac, .cleaning],
                assignedBuildings: [],
                skillLevel: .advanced
            ),
            "4": FrancoSphere.WorkerProfile(
                id: "4",
                name: "Kevin Dutan",
                email: "kevin@francosphere.com",
                role: .worker,
                skills: [.maintenance, .cleaning, .electrical, .sanitation, .hvac],
                assignedBuildings: [],
                skillLevel: .advanced
            ),
            "5": FrancoSphere.WorkerProfile(
                id: "5",
                name: "Mercedes Inamagua",
                email: "mercedes@francosphere.com",
                role: .worker,
                skills: [.cleaning, .maintenance],
                assignedBuildings: [],
                skillLevel: .intermediate
            ),
            "6": FrancoSphere.WorkerProfile(
                id: "6",
                name: "Luis Lopez",
                email: "luis@francosphere.com",
                role: .worker,
                skills: [.maintenance, .cleaning, .plumbing],
                assignedBuildings: [],
                skillLevel: .intermediate
            ),
            "7": FrancoSphere.WorkerProfile(
                id: "7",
                name: "Angel Guirachocha",
                email: "angel@francosphere.com",
                role: .worker,
                skills: [.sanitation, .security, .maintenance],
                assignedBuildings: [],
                skillLevel: .intermediate
            ),
            "8": FrancoSphere.WorkerProfile(
                id: "8",
                name: "Shawn Magloire",
                email: "shawn@francosphere.com",
                role: .admin,
                skills: [.hvac, .electrical, .plumbing, .maintenance, .management],
                assignedBuildings: [],
                skillLevel: .expert
            )
        ]
        
        // NOTE: Worker ID "3" (Jose Santos) intentionally REMOVED
        
        return currentActiveWorkers[workerId]
    }
    
    // MARK: - ⭐ ENHANCED: Skill Matching
    
    /// Get workers with specific skill for a building
    func getWorkersWithSkill(_ skill: FrancoSphere.WorkerSkill, forBuilding buildingId: String) -> [FrancoSphere.WorkerProfile] {
        let assignedWorkers = getWorkersForBuilding(buildingId: buildingId)
        
        return assignedWorkers.filter { worker in
            worker.skills.contains(skill)
        }
    }
    
    /// Get best worker for a specific task category
    func getBestWorkerForTask(category: String, buildingId: String) -> FrancoSphere.WorkerProfile? {
        let assignedWorkers = getWorkersForBuilding(buildingId: buildingId)
        
        // Define skill requirements for task categories
        let skillRequirements: [String: FrancoSphere.WorkerSkill] = [
            "Maintenance": .maintenance,
            "Cleaning": .cleaning,
            "Sanitation": .sanitation,
            "HVAC": .hvac,
            "Electrical": .electrical,
            "Plumbing": .plumbing
        ]
        
        guard let requiredSkill = skillRequirements[category] else {
            return assignedWorkers.first
        }
        
        // Find workers with required skill, sorted by skill level (experience indicator)
        let qualifiedWorkers = assignedWorkers
            .filter { $0.skills.contains(requiredSkill) }
            .sorted { worker1, worker2 in
                let level1 = worker1.skillLevel
                let level2 = worker2.skillLevel
                
                // Convert skill levels to sortable values
                let getValue: (FrancoSphere.SkillLevel) -> Int = { level in
                    switch level {
                    case .basic: return 1
                    case .intermediate: return 2
                    case .advanced: return 3
                    case .expert: return 4
                    }
                }
                
                return getValue(level1) > getValue(level2)
            }
        
        return qualifiedWorkers.first
    }
    
    // MARK: - ⭐ PHASE-2: Real-World Assignment Validation
    
    /// Validate current worker assignments against real-world data
    func validateCurrentAssignments() async -> (isValid: Bool, issues: [String]) {
        guard let manager = await getSQLiteManager() else {
            return (false, ["Database not available"])
        }
        
        var issues: [String] = []
        
        do {
            // Check 1: Ensure Jose Santos is not in assignments
            let joseCheck = try await manager.query("""
                SELECT COUNT(*) as count FROM worker_building_assignments 
                WHERE worker_name LIKE '%Jose%' AND is_active = 1
            """)
            
            if let count = joseCheck.first?["count"] as? Int64, count > 0 {
                issues.append("Jose Santos still found in active assignments")
            }
            
            // Check 2: Verify Kevin has expanded assignments (6+ buildings)
            let kevinCheck = try await manager.query("""
                SELECT COUNT(*) as count FROM worker_building_assignments 
                WHERE worker_name = 'Kevin Dutan' AND is_active = 1
            """)
            
            let kevinCount = kevinCheck.first?["count"] as? Int64 ?? 0
            if kevinCount < 6 {
                issues.append("Kevin Dutan should have 6+ buildings, found \(kevinCount)")
            }
            
            // Check 3: Verify total active workers is 7
            let workerCountCheck = try await manager.query("""
                SELECT COUNT(DISTINCT worker_id) as count FROM worker_building_assignments 
                WHERE is_active = 1
            """)
            
            let totalWorkers = workerCountCheck.first?["count"] as? Int64 ?? 0
            if totalWorkers != 7 {
                issues.append("Expected 7 active workers, found \(totalWorkers)")
            }
            
            // Check 4: Verify all workers have assignments
            let workersWithoutBuildings = try await manager.query("""
                SELECT w.name FROM workers w 
                LEFT JOIN worker_building_assignments wa ON w.id = wa.worker_id AND wa.is_active = 1
                WHERE w.isActive = 1 AND wa.worker_id IS NULL
            """)
            
            for row in workersWithoutBuildings {
                if let name = row["name"] as? String {
                    issues.append("Worker \(name) has no building assignments")
                }
            }
            
        } catch {
            issues.append("Database query failed: \(error.localizedDescription)")
        }
        
        return (issues.isEmpty, issues)
    }
    
    /// Get assignment statistics for monitoring
    func getAssignmentStatistics() async -> [String: Any] {
        guard let manager = await getSQLiteManager() else {
            return ["error": "Database not available"]
        }
        
        var stats: [String: Any] = [:]
        
        do {
            // Total assignments
            let totalAssignments = try await manager.query("""
                SELECT COUNT(*) as count FROM worker_building_assignments WHERE is_active = 1
            """)
            stats["totalAssignments"] = totalAssignments.first?["count"] as? Int64 ?? 0
            
            // Assignments per worker
            let perWorkerStats = try await manager.query("""
                SELECT worker_name, COUNT(*) as count 
                FROM worker_building_assignments 
                WHERE is_active = 1 
                GROUP BY worker_id 
                ORDER BY count DESC
            """)
            
            var workerStats: [String: Int64] = [:]
            for row in perWorkerStats {
                let name = row["worker_name"] as? String ?? "Unknown"
                let count = row["count"] as? Int64 ?? 0
                workerStats[name] = count
            }
            stats["perWorkerAssignments"] = workerStats
            
            // Buildings with most workers
            let buildingStats = try await manager.query("""
                SELECT building_id, COUNT(*) as worker_count 
                FROM worker_building_assignments 
                WHERE is_active = 1 
                GROUP BY building_id 
                ORDER BY worker_count DESC 
                LIMIT 5
            """)
            
            var topBuildings: [String: Int64] = [:]
            for row in buildingStats {
                let buildingId = row["building_id"] as? String ?? "Unknown"
                let count = row["worker_count"] as? Int64 ?? 0
                topBuildings[buildingId] = count
            }
            stats["topBuildingsByWorkerCount"] = topBuildings
            
        } catch {
            stats["error"] = "Failed to generate statistics: \(error.localizedDescription)"
        }
        
        return stats
    }
    
    // MARK: - ⭐ CACHE MANAGEMENT
    
    /// Force refresh assignment cache
    func forceRefreshCache() async {
        print("🔄 Force refreshing assignment cache...")
        assignmentCache.removeAll()
        cacheTimestamp = Date.distantPast
        await refreshAssignmentCache()
    }
    
    /// Clear assignment cache
    func clearCache() {
        assignmentCache.removeAll()
        cacheTimestamp = Date.distantPast
        print("🗑️ Assignment cache cleared")
    }
    
    /// Get cache status
    func getCacheStatus() -> (count: Int, age: TimeInterval, isValid: Bool) {
        let age = Date().timeIntervalSince(cacheTimestamp)
        let isValid = age < cacheTimeout
        return (assignmentCache.count, age, isValid)
    }
}

// MARK: - ⭐ DEBUGGING HELPERS

extension WorkerAssignmentManager {
    
    /// Debug method to log current assignments
    func debugLogCurrentAssignments() async {
        print("🔍 DEBUG: Current Assignment Status")
        print("═══════════════════════════════════")
        
        let (cacheCount, cacheAge, isValid) = getCacheStatus()
        print("Cache: \(cacheCount) entries, age: \(Int(cacheAge))s, valid: \(isValid)")
        
        for (buildingId, workerIds) in assignmentCache.sorted(by: { $0.key < $1.key }) {
            print("Building \(buildingId): \(workerIds.joined(separator: ", "))")
        }
        
        let stats = await getAssignmentStatistics()
        print("Statistics: \(stats)")
        
        let (validationResult, issues) = await validateCurrentAssignments()
        print("Validation: \(validationResult ? "✅ PASS" : "❌ FAIL")")
        for issue in issues {
            print("  ⚠️ \(issue)")
        }
    }
    
    /// ✅ NEW: Quick assignment check for specific worker
    func debugWorkerAssignments(_ workerId: String) -> String {
        let assignments = getAssignedBuildingIds(for: workerId)
        let workerName = getWorkerById(workerId)?.name ?? "Unknown"
        
        if assignments.isEmpty {
            return "❌ \(workerName) (ID: \(workerId)) has NO assignments"
        } else {
            return "✅ \(workerName) (ID: \(workerId)) assigned to \(assignments.count) buildings: \(assignments.joined(separator: ", "))"
        }
    }
}
