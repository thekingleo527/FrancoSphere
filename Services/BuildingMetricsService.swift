//
//  BuildingMetricsService.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/8/25.
//


//
//  BuildingMetricsService.swift
//  FrancoSphere
//
//  ✅ PHASE 1: REAL-TIME BUILDING METRICS CALCULATION
//  ✅ SQLite database integration for PropertyCard data
//  ✅ Actor-based thread-safe calculations
//  ✅ Real-time sync with WorkerEventOutbox
//  ✅ Caching for performance optimization
//  ✅ Edwin's 7-worker system integration
//

import Foundation
import SQLite
import Combine

// MARK: - BuildingMetricsService Actor

/// Thread-safe service for calculating real-time building metrics
/// Used by PropertyCard across all three dashboard types
actor BuildingMetricsService {
    static let shared = BuildingMetricsService()
    
    // MARK: - Dependencies
    private let sqliteManager = SQLiteManager.shared
    private let buildingService = BuildingService.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    
    // MARK: - Cache Management
    private var metricsCache: [String: CachedMetrics] = [:]
    private let cacheExpiration: TimeInterval = 300 // 5 minutes
    
    private struct CachedMetrics {
        let metrics: BuildingMetrics
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }
    
    private init() {
        setupRealTimeSync()
    }
    
    // MARK: - Public Interface
    
    /// Calculate comprehensive building metrics for PropertyCard
    func calculateMetrics(for buildingId: String) async throws -> BuildingMetrics {
        // Check cache first
        if let cached = metricsCache[buildingId], !cached.isExpired {
            return cached.metrics
        }
        
        // Calculate fresh metrics
        let metrics = try await performMetricsCalculation(buildingId: buildingId)
        
        // Update cache
        metricsCache[buildingId] = CachedMetrics(metrics: metrics, timestamp: Date())
        
        return metrics
    }
    
    /// Batch calculate metrics for multiple buildings
    func calculateMetrics(for buildingIds: [String]) async throws -> [String: BuildingMetrics] {
        var results: [String: BuildingMetrics] = [:]
        
        // Use TaskGroup for concurrent calculation
        await withTaskGroup(of: (String, BuildingMetrics?).self) { group in
            for buildingId in buildingIds {
                group.addTask {
                    let metrics = try? await self.calculateMetrics(for: buildingId)
                    return (buildingId, metrics)
                }
            }
            
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    results[buildingId] = metrics
                }
            }
        }
        
        return results
    }
    
    /// Invalidate cache for specific building (triggered by real-time updates)
    func invalidateCache(for buildingId: String) {
        metricsCache.removeValue(forKey: buildingId)
    }
    
    /// Clear all cached metrics
    func clearCache() {
        metricsCache.removeAll()
    }
    
    // MARK: - Private Calculation Methods
    
    /// Perform comprehensive metrics calculation from SQLite database
    private func performMetricsCalculation(buildingId: String) async throws -> BuildingMetrics {
        // Convert buildingId to Int64 for database queries
        guard let buildingIdInt = Int64(buildingId) else {
            throw MetricsError.invalidBuildingId(buildingId)
        }
        
        // Parallel data fetching
        async let taskMetrics = calculateTaskMetrics(buildingId: buildingIdInt)
        async let workerMetrics = calculateWorkerMetrics(buildingId: buildingId)
        async let complianceMetrics = calculateComplianceMetrics(buildingId: buildingIdInt)
        
        let taskData = try await taskMetrics
        let workerData = try await workerMetrics
        let complianceData = try await complianceMetrics
        
        // Combine all metrics
        return BuildingMetrics(
            completionRate: taskData.completionRate,
            pendingTasks: taskData.pendingTasks,
            overdueTasks: taskData.overdueTasks,
            activeWorkers: workerData.activeWorkers,
            isCompliant: complianceData.isCompliant,
            overallScore: calculateOverallScore(
                completionRate: taskData.completionRate,
                overdueTasks: taskData.overdueTasks,
                compliance: complianceData.isCompliant
            ),
            hasWorkerOnSite: workerData.hasWorkerOnSite
        )
    }
    
    /// Calculate task-related metrics from database
    private func calculateTaskMetrics(buildingId: Int64) async throws -> TaskMetricsData {
        let today = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: today)
        let todayEnd = calendar.date(byAdding: .day, value: 1, to: todayStart)!
        
        // Query today's tasks for the building
        let taskQuery = """
            SELECT 
                COUNT(*) as total_tasks,
                SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as completed_tasks,
                SUM(CASE WHEN isCompleted = 0 AND datetime(scheduledDate) < datetime('now') THEN 1 ELSE 0 END) as overdue_tasks
            FROM tasks 
            WHERE buildingId = ? 
            AND date(scheduledDate) = date('now')
        """
        
        let taskRows = try await sqliteManager.query(taskQuery, [buildingId])
        
        // Also check routine tasks
        let routineQuery = """
            SELECT 
                COUNT(*) as routine_count,
                SUM(CASE WHEN EXISTS(
                    SELECT 1 FROM tasks t 
                    WHERE t.name = routine_tasks.task_name 
                    AND t.buildingId = routine_tasks.building_id 
                    AND t.isCompleted = 1 
                    AND date(t.scheduledDate) = date('now')
                ) THEN 1 ELSE 0 END) as routine_completed
            FROM routine_tasks 
            WHERE building_id = ? AND is_active = 1
        """
        
        let routineRows = try await sqliteManager.query(routineQuery, [String(buildingId)])
        
        guard let taskRow = taskRows.first else {
            return TaskMetricsData(completionRate: 1.0, pendingTasks: 0, overdueTasks: 0)
        }
        
        let totalTasks = (taskRow["total_tasks"] as? Int64) ?? 0
        let completedTasks = (taskRow["completed_tasks"] as? Int64) ?? 0
        let overdueTasks = (taskRow["overdue_tasks"] as? Int64) ?? 0
        
        // Add routine tasks
        let routineCount = (routineRows.first?["routine_count"] as? Int64) ?? 0
        let routineCompleted = (routineRows.first?["routine_completed"] as? Int64) ?? 0
        
        let totalTasksAll = totalTasks + routineCount
        let completedTasksAll = completedTasks + routineCompleted
        let pendingTasks = totalTasksAll - completedTasksAll
        
        let completionRate = totalTasksAll > 0 ? 
            Double(completedTasksAll) / Double(totalTasksAll) : 1.0
        
        return TaskMetricsData(
            completionRate: completionRate,
            pendingTasks: Int(pendingTasks),
            overdueTasks: Int(overdueTasks)
        )
    }
    
    /// Calculate worker-related metrics
    private func calculateWorkerMetrics(buildingId: String) async throws -> WorkerMetricsData {
        // Get active workers assigned to building
        let assignmentQuery = """
            SELECT DISTINCT 
                wa.worker_id,
                w.name as worker_name,
                EXISTS(
                    SELECT 1 FROM worker_time_logs wtl 
                    WHERE wtl.workerId = CAST(wa.worker_id AS INTEGER)
                    AND wtl.buildingId = CAST(wa.building_id AS INTEGER)
                    AND wtl.clockInTime IS NOT NULL 
                    AND wtl.clockOutTime IS NULL
                    AND date(wtl.clockInTime) = date('now')
                ) as is_on_site
            FROM worker_assignments wa
            LEFT JOIN workers w ON CAST(w.id AS TEXT) = wa.worker_id
            WHERE wa.building_id = ? AND wa.is_active = 1
        """
        
        let assignmentRows = try await sqliteManager.query(assignmentQuery, [buildingId])
        
        let activeWorkers = assignmentRows.count
        let hasWorkerOnSite = assignmentRows.contains { row in
            (row["is_on_site"] as? Int64) == 1
        }
        
        return WorkerMetricsData(
            activeWorkers: activeWorkers,
            hasWorkerOnSite: hasWorkerOnSite
        )
    }
    
    /// Calculate compliance metrics
    private func calculateComplianceMetrics(buildingId: Int64) async throws -> ComplianceMetricsData {
        // Check for overdue tasks and recent violations
        let complianceQuery = """
            SELECT 
                COUNT(*) as total_violations,
                SUM(CASE WHEN datetime(scheduledDate) < datetime('now', '-1 day') THEN 1 ELSE 0 END) as critical_violations
            FROM tasks 
            WHERE buildingId = ? 
            AND isCompleted = 0 
            AND datetime(scheduledDate) < datetime('now')
        """
        
        let complianceRows = try await sqliteManager.query(complianceQuery, [buildingId])
        
        let totalViolations = (complianceRows.first?["total_violations"] as? Int64) ?? 0
        let criticalViolations = (complianceRows.first?["critical_violations"] as? Int64) ?? 0
        
        // Building is compliant if no overdue tasks and no critical violations
        let isCompliant = totalViolations == 0 && criticalViolations == 0
        
        return ComplianceMetricsData(isCompliant: isCompliant)
    }
    
    /// Calculate overall building score
    private func calculateOverallScore(
        completionRate: Double,
        overdueTasks: Int,
        compliance: Bool
    ) -> Int {
        var score = Int(completionRate * 100)
        
        // Penalty for overdue tasks
        score -= overdueTasks * 5
        
        // Bonus for compliance
        if compliance {
            score += 5
        }
        
        // Clamp to 0-100 range
        return max(0, min(100, score))
    }
    
    // MARK: - Real-Time Sync Integration
    
    /// Setup real-time synchronization with WorkerEventOutbox
    private func setupRealTimeSync() {
        Task {
            // Subscribe to worker events that affect building metrics
            for await event in WorkerEventOutbox.shared.eventStream {
                await handleWorkerEvent(event)
            }
        }
    }
    
    /// Handle incoming worker events and invalidate affected caches
    private func handleWorkerEvent(_ event: WorkerEventOutbox.WorkerEvent) async {
        switch event.type {
        case .taskComplete, .taskStart, .clockIn, .clockOut:
            // Invalidate cache for affected building
            invalidateCache(for: event.buildingId)
            
            // Trigger real-time update
            await broadcastMetricsUpdate(for: event.buildingId)
            
        case .routineTaskComplete:
            // Invalidate cache and update routine task metrics
            invalidateCache(for: event.buildingId)
            await broadcastMetricsUpdate(for: event.buildingId)
            
        case .emergencyReport:
            // Immediately recalculate metrics for emergency situations
            invalidateCache(for: event.buildingId)
            await broadcastMetricsUpdate(for: event.buildingId)
        }
    }
    
    /// Broadcast metrics update to UI components
    private func broadcastMetricsUpdate(for buildingId: String) async {
        do {
            let updatedMetrics = try await calculateMetrics(for: buildingId)
            
            // Notify PropertyCardDataService
            await MainActor.run {
                PropertyCardDataService.shared.updateMetrics(buildingId: buildingId, metrics: updatedMetrics)
            }
        } catch {
            print("Error broadcasting metrics update for building \(buildingId): \(error)")
        }
    }
}

// MARK: - Supporting Data Structures

private struct TaskMetricsData {
    let completionRate: Double
    let pendingTasks: Int
    let overdueTasks: Int
}

private struct WorkerMetricsData {
    let activeWorkers: Int
    let hasWorkerOnSite: Bool
}

private struct ComplianceMetricsData {
    let isCompliant: Bool
}

// MARK: - Error Handling

enum MetricsError: LocalizedError {
    case invalidBuildingId(String)
    case databaseError(String)
    case calculationTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidBuildingId(let id):
            return "Invalid building ID: \(id)"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .calculationTimeout:
            return "Metrics calculation timed out"
        }
    }
}

// MARK: - PropertyCardDataService Extension

extension PropertyCardDataService {
    /// Update metrics from BuildingMetricsService
    func updateMetrics(buildingId: String, metrics: BuildingMetrics) {
        buildingMetrics[buildingId] = metrics
    }
    
    /// Refresh metrics using BuildingMetricsService
    func refreshMetrics(for buildingId: String) async {
        do {
            let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
            updateMetrics(buildingId: buildingId, metrics: metrics)
        } catch {
            print("Error refreshing metrics for building \(buildingId): \(error)")
        }
    }
    
    /// Batch refresh metrics for multiple buildings
    func refreshMetrics(for buildingIds: [String]) async {
        do {
            let metricsDict = try await BuildingMetricsService.shared.calculateMetrics(for: buildingIds)
            
            await MainActor.run {
                for (buildingId, metrics) in metricsDict {
                    self.buildingMetrics[buildingId] = metrics
                }
            }
        } catch {
            print("Error batch refreshing metrics: \(error)")
        }
    }
}

// MARK: - ViewModel Integration Extensions

extension WorkerDashboardViewModel {
    /// Use BuildingMetricsService instead of manual calculation
    func getBuildingMetrics(for buildingId: String) -> BuildingMetrics? {
        // Check cached metrics first
        if let cached = PropertyCardDataService.shared.getMetrics(for: buildingId) {
            return cached
        }
        
        // Trigger async refresh
        Task {
            await PropertyCardDataService.shared.refreshMetrics(for: buildingId)
        }
        
        // Return default metrics while loading
        return BuildingMetrics(
            completionRate: 0.0,
            pendingTasks: 0,
            overdueTasks: 0,
            activeWorkers: 0,
            isCompliant: true,
            overallScore: 0,
            hasWorkerOnSite: false
        )
    }
}

extension AdminDashboardViewModel {
    /// Use BuildingMetricsService for admin metrics
    func getBuildingMetrics(for buildingId: String) -> BuildingMetrics? {
        return PropertyCardDataService.shared.getMetrics(for: buildingId)
    }
    
    /// Load metrics for all buildings
    func loadBuildingMetrics() async {
        let buildingIds = buildings.map { $0.id }
        await PropertyCardDataService.shared.refreshMetrics(for: buildingIds)
    }
}

extension ClientDashboardViewModel {
    /// Use BuildingMetricsService for client metrics
    func getBuildingMetrics(for buildingId: String) -> BuildingMetrics? {
        return PropertyCardDataService.shared.getMetrics(for: buildingId)
    }
}

// MARK: - Edwin's Worker Data Integration

/// Extension to handle Edwin's specific building assignments
extension BuildingMetricsService {
    
    /// Calculate metrics for Edwin's buildings with special handling
    func calculateEdwinMetrics() async throws -> [String: BuildingMetrics] {
        // Edwin's building assignments (Worker ID: 2)
        let edwinBuildingIds = [
            "1",  // 12 West 18th Street
            "4",  // 41 Elizabeth Street  
            "5",  // 68 Perry Street
            "16", // Stuyvesant Cove Park
            "17"  // 178 Spring Street
        ]
        
        return try await calculateMetrics(for: edwinBuildingIds)
    }
    
    /// Calculate metrics for Kevin's expanded assignments
    func calculateKevinMetrics() async throws -> [String: BuildingMetrics] {
        // Kevin's expanded assignments (Worker ID: 4) - includes Rubin Museum
        let kevinBuildingIds = [
            "1",  // 12 West 18th Street
            "5",  // 131 Perry Street
            "6",  // 68 Perry Street
            "7",  // 136 West 17th Street
            "8",  // 138 West 17th Street
            "9",  // 135-139 West 17th Street
            "12", // 178 Spring Street
            "14", // Rubin Museum (CORRECTED - not Franklin)
            "16", // 29-31 East 20th Street
            "17"  // Another assignment
        ]
        
        return try await calculateMetrics(for: kevinBuildingIds)
    }
}

// MARK: - Performance Monitoring

/// Monitor BuildingMetricsService performance
struct MetricsPerformanceMonitor {
    static func logCalculationTime<T>(
        operation: String,
        buildingId: String,
        block: () async throws -> T
    ) async rethrows -> T {
        let startTime = Date()
        let result = try await block()
        let duration = Date().timeIntervalSince(startTime)
        
        print("📊 Metrics calculation [\(operation)] for building \(buildingId): \(duration * 1000, specifier: "%.1f")ms")
        
        return result
    }
}

// MARK: - Integration Testing

#if DEBUG
extension BuildingMetricsService {
    /// Test metrics calculation for sample building
    func testCalculation() async {
        do {
            let metrics = try await calculateMetrics(for: "14") // Rubin Museum
            print("🧪 Test metrics for Rubin Museum:")
            print("   - Completion Rate: \(metrics.completionRate)")
            print("   - Pending Tasks: \(metrics.pendingTasks)")
            print("   - Overdue Tasks: \(metrics.overdueTasks)")
            print("   - Active Workers: \(metrics.activeWorkers)")
            print("   - Overall Score: \(metrics.overallScore)")
            print("   - Is Compliant: \(metrics.isCompliant)")
        } catch {
            print("❌ Test failed: \(error)")
        }
    }
}
#endif