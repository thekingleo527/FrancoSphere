//
//  UnifiedDataService.swift
//  FrancoSphere v6.0
//
//  ✅ CRITICAL FIX: Bridges OperationalDataManager to Intelligence Services
//  ✅ FALLBACK: Provides real data when database is empty
//  ✅ VERIFICATION: Ensures data integrity across all services
//  ✅ INTELLIGENCE: Enables proper insight generation
//

import Foundation
import Combine

/// Unified service that bridges OperationalDataManager real data to GRDB services
/// Provides fallback mechanisms and ensures intelligence cards display properly
@MainActor
public class UnifiedDataService: ObservableObject {
    public static let shared = UnifiedDataService()
    
    // MARK: - Dependencies
    private let operationalData = OperationalDataManager.shared
    private let grdbManager = GRDBManager.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    
    // MARK: - Published State
    @Published public var isInitialized = false
    @Published public var dataStatus: DataStatus = .unknown
    @Published public var lastSyncTime: Date?
    @Published public var syncProgress: Double = 0.0
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var hasVerifiedData = false
    
    public enum DataStatus {
        case unknown
        case empty
        case partial
        case complete
        case syncing
        case error(String)
        
        var description: String {
            switch self {
            case .unknown: return "Unknown"
            case .empty: return "Empty Database"
            case .partial: return "Partial Data"
            case .complete: return "Complete Data"
            case .syncing: return "Syncing..."
            case .error(let msg): return "Error: \(msg)"
            }
        }
    }
    
    private init() {
        Task {
            await initializeUnifiedData()
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize unified data service and verify data integrity
    public func initializeUnifiedData() async {
        print("🔄 Initializing UnifiedDataService...")
        dataStatus = .syncing
        
        do {
            // Step 1: Verify database integrity
            let integrity = await verifyDatabaseIntegrity()
            print("📊 Database integrity: \(integrity)")
            
            // Step 2: Sync OperationalDataManager to database if needed
            if integrity.needsSync {
                await syncOperationalDataToDatabase()
            }
            
            // Step 3: Verify data flow to services
            let serviceData = await verifyServiceDataFlow()
            print("🔗 Service data flow: \(serviceData)")
            
            // Step 4: Update status
            dataStatus = serviceData.isComplete ? .complete : .partial
            lastSyncTime = Date()
            isInitialized = true
            
            print("✅ UnifiedDataService initialized successfully")
            
        } catch {
            dataStatus = .error(error.localizedDescription)
            print("❌ UnifiedDataService initialization failed: \(error)")
        }
    }
    
    // MARK: - Data Verification
    
    /// Comprehensive database integrity check
    public func verifyDatabaseIntegrity() async -> DatabaseIntegrity {
        var integrity = DatabaseIntegrity()
        
        do {
            // Check critical tables
            integrity.hasWorkers = try await verifyWorkersTable()
            integrity.hasBuildings = try await verifyBuildingsTable()
            integrity.hasTasks = try await verifyTasksTable()
            integrity.hasAssignments = try await verifyAssignmentsTable()
            
            // Count records
            integrity.workerCount = try await getTableCount("workers")
            integrity.buildingCount = try await getTableCount("buildings")
            integrity.taskCount = try await getTableCount("routine_tasks")
            integrity.assignmentCount = try await getTableCount("worker_assignments")
            
            // Compare with OperationalDataManager
            let operationalTaskCount = operationalData.realWorldTasks.count
            let operationalWorkerCount = Set(operationalData.realWorldTasks.map { $0.assignedWorker }).count
            
            integrity.needsSync = integrity.taskCount < operationalTaskCount / 2 // If less than half
            integrity.isComplete = integrity.hasWorkers && integrity.hasBuildings &&
                                 integrity.hasTasks && integrity.hasAssignments
            
            print("📊 Database Integrity Report:")
            print("   Workers: \(integrity.workerCount) (needs: \(operationalWorkerCount))")
            print("   Buildings: \(integrity.buildingCount)")
            print("   Tasks: \(integrity.taskCount) (operational: \(operationalTaskCount))")
            print("   Assignments: \(integrity.assignmentCount)")
            print("   Needs Sync: \(integrity.needsSync)")
            
        } catch {
            print("❌ Database integrity check failed: \(error)")
            integrity.hasError = true
            integrity.errorMessage = error.localizedDescription
        }
        
        return integrity
    }
    
    /// Verify service data flow works end-to-end
    public func verifyServiceDataFlow() async -> ServiceDataFlow {
        var dataFlow = ServiceDataFlow()
        
        do {
            // Test TaskService
            let allTasks = try await taskService.getAllTasks()
            dataFlow.taskServiceWorking = true
            dataFlow.taskCount = allTasks.count
            
            // Test WorkerService
            let allWorkers = try await workerService.getAllActiveWorkers()
            dataFlow.workerServiceWorking = true
            dataFlow.workerCount = allWorkers.count
            
            // Test BuildingService
            let allBuildings = try await buildingService.getAllBuildings()
            dataFlow.buildingServiceWorking = true
            dataFlow.buildingCount = allBuildings.count
            
            // Test IntelligenceService (the final goal)
            let insights = try await IntelligenceService.shared.generatePortfolioInsights()
            dataFlow.intelligenceServiceWorking = true
            dataFlow.insightCount = insights.count
            
            dataFlow.isComplete = dataFlow.taskServiceWorking &&
                                dataFlow.workerServiceWorking &&
                                dataFlow.buildingServiceWorking &&
                                dataFlow.intelligenceServiceWorking &&
                                dataFlow.insightCount > 0
            
            print("🔗 Service Data Flow Report:")
            print("   TaskService: \(dataFlow.taskServiceWorking) (\(dataFlow.taskCount) tasks)")
            print("   WorkerService: \(dataFlow.workerServiceWorking) (\(dataFlow.workerCount) workers)")
            print("   BuildingService: \(dataFlow.buildingServiceWorking) (\(dataFlow.buildingCount) buildings)")
            print("   IntelligenceService: \(dataFlow.intelligenceServiceWorking) (\(dataFlow.insightCount) insights)")
            print("   Complete: \(dataFlow.isComplete)")
            
        } catch {
            print("❌ Service data flow verification failed: \(error)")
            dataFlow.hasError = true
            dataFlow.errorMessage = error.localizedDescription
        }
        
        return dataFlow
    }
    
    // MARK: - Data Synchronization
    
    /// Sync OperationalDataManager data to database tables
    public func syncOperationalDataToDatabase() async {
        print("🔄 Syncing OperationalDataManager to database...")
        syncProgress = 0.0
        
        do {
            // Initialize OperationalDataManager if needed
            if !operationalData.isInitialized {
                print("📦 Initializing OperationalDataManager...")
                try await operationalData.initializeOperationalData()
                syncProgress = 0.2
            }
            
            // Import routines and DSNY schedules
            print("📅 Importing routines and schedules...")
            let (routines, dsny) = try await operationalData.importRoutinesAndDSNY()
            print("✅ Imported \(routines) routines, \(dsny) DSNY schedules")
            syncProgress = 0.5
            
            // Convert OperationalDataManager tasks to routine_tasks table
            print("🔄 Converting operational tasks to database...")
            await convertOperationalTasksToDatabase()
            syncProgress = 0.8
            
            // Verify the sync worked
            let verification = await verifyDatabaseIntegrity()
            if verification.isComplete {
                print("✅ Data synchronization completed successfully")
            } else {
                print("⚠️ Data synchronization partially complete")
            }
            syncProgress = 1.0
            
        } catch {
            print("❌ Data synchronization failed: \(error)")
            dataStatus = .error(error.localizedDescription)
        }
    }
    
    /// Convert OperationalDataManager realWorldTasks to routine_tasks table
    private func convertOperationalTasksToDatabase() async {
        let tasks = operationalData.realWorldTasks
        print("🔄 Converting \(tasks.count) operational tasks to database...")
        
        var converted = 0
        var skipped = 0
        
        for (index, operationalTask) in tasks.enumerated() {
            do {
                // Map worker name to ID
                guard let workerId = getWorkerIdFromName(operationalTask.assignedWorker) else {
                    print("⚠️ Skipping task for unknown worker: \(operationalTask.assignedWorker)")
                    skipped += 1
                    continue
                }
                
                // Map building name to ID
                guard let buildingId = await getBuildingIdFromName(operationalTask.building) else {
                    print("⚠️ Skipping task for unknown building: \(operationalTask.building)")
                    skipped += 1
                    continue
                }
                
                // Generate unique external ID
                let externalId = "op_task_\(workerId)_\(buildingId)_\(operationalTask.taskName.hash)"
                
                // Check if already exists
                let existing = try await grdbManager.query(
                    "SELECT id FROM routine_tasks WHERE external_id = ?",
                    [externalId]
                )
                
                if !existing.isEmpty {
                    skipped += 1
                    continue
                }
                
                // Convert to database format
                try await grdbManager.execute("""
                    INSERT INTO routine_tasks (
                        worker_id, building_id, task_name, category, skill_level,
                        recurrence, start_time, end_time, is_active, external_id,
                        created_at
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, datetime('now'))
                """, [
                    workerId,
                    buildingId,
                    operationalTask.taskName,
                    operationalTask.category,
                    operationalTask.skillLevel,
                    operationalTask.recurrence,
                    operationalTask.startHour != nil ? String(operationalTask.startHour!) : nil,
                    operationalTask.endHour != nil ? String(operationalTask.endHour!) : nil,
                    externalId
                ])
                
                converted += 1
                
                // Log progress for important tasks
                if operationalTask.assignedWorker == "Kevin Dutan" && operationalTask.building.contains("Rubin") {
                    print("✅ Converted Kevin's Rubin Museum task: \(operationalTask.taskName)")
                }
                
            } catch {
                print("❌ Failed to convert task: \(operationalTask.taskName) - \(error)")
                skipped += 1
            }
            
            // Update progress
            if index % 10 == 0 {
                syncProgress = 0.5 + (0.3 * Double(index) / Double(tasks.count))
            }
        }
        
        print("✅ Conversion complete: \(converted) converted, \(skipped) skipped")
    }
    
    // MARK: - Fallback Data Access
    
    /// Get tasks with fallback to OperationalDataManager
    public func getTasksWithFallback(for workerId: String, date: Date) async -> [ContextualTask] {
        do {
            // Try database first
            let dbTasks = try await taskService.getTasks(for: workerId, date: date)
            if !dbTasks.isEmpty {
                return dbTasks
            }
            
            // Fallback to OperationalDataManager
            print("⚡ Using OperationalDataManager fallback for worker \(workerId)")
            return await getTasksFromOperationalData(workerId: workerId, date: date)
            
        } catch {
            print("❌ Database tasks failed, using fallback: \(error)")
            return await getTasksFromOperationalData(workerId: workerId, date: date)
        }
    }
    
    /// Get all tasks with fallback to OperationalDataManager
    public func getAllTasksWithFallback() async -> [ContextualTask] {
        do {
            // Try database first
            let dbTasks = try await taskService.getAllTasks()
            if !dbTasks.isEmpty {
                return dbTasks
            }
            
            // Fallback to OperationalDataManager
            print("⚡ Using OperationalDataManager fallback for all tasks")
            return await getAllTasksFromOperationalData()
            
        } catch {
            print("❌ Database tasks failed, using fallback: \(error)")
            return await getAllTasksFromOperationalData()
        }
    }
    
    /// Get portfolio insights with fallback data
    public func generatePortfolioInsightsWithFallback() async -> [CoreTypes.IntelligenceInsight] {
        do {
            // Try normal intelligence service first
            let insights = try await IntelligenceService.shared.generatePortfolioInsights()
            if !insights.isEmpty {
                return insights
            }
            
            // Fallback: Generate insights from OperationalDataManager directly
            print("⚡ Generating insights from OperationalDataManager fallback")
            return await generateInsightsFromOperationalData()
            
        } catch {
            print("❌ Normal insights failed, using fallback: \(error)")
            return await generateInsightsFromOperationalData()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func verifyWorkersTable() async throws -> Bool {
        let result = try await grdbManager.query("SELECT COUNT(*) as count FROM workers WHERE isActive = 1")
        return (result.first?["count"] as? Int64 ?? 0) > 0
    }
    
    private func verifyBuildingsTable() async throws -> Bool {
        let result = try await grdbManager.query("SELECT COUNT(*) as count FROM buildings")
        return (result.first?["count"] as? Int64 ?? 0) > 0
    }
    
    private func verifyTasksTable() async throws -> Bool {
        let result = try await grdbManager.query("SELECT COUNT(*) as count FROM routine_tasks")
        return (result.first?["count"] as? Int64 ?? 0) > 0
    }
    
    private func verifyAssignmentsTable() async throws -> Bool {
        let result = try await grdbManager.query("SELECT COUNT(*) as count FROM worker_assignments WHERE is_active = 1")
        return (result.first?["count"] as? Int64 ?? 0) > 0
    }
    
    private func getTableCount(_ tableName: String) async throws -> Int {
        let result = try await grdbManager.query("SELECT COUNT(*) as count FROM \(tableName)")
        return Int(result.first?["count"] as? Int64 ?? 0)
    }
    
    private func getWorkerIdFromName(_ workerName: String) -> String? {
        let workerNameMap: [String: String] = [
            "Greg Hutson": "1",
            "Edwin Lema": "2",
            "Kevin Dutan": "4",
            "Mercedes Inamagua": "5",
            "Luis Lopez": "6",
            "Angel Guirachocha": "7",
            "Shawn Magloire": "8"
        ]
        return workerNameMap[workerName]
    }
    
    private func getBuildingIdFromName(_ buildingName: String) async -> String? {
        do {
            let buildings = try await buildingService.getAllBuildings()
            return buildings.first { building in
                building.name.lowercased().contains(buildingName.lowercased()) ||
                buildingName.lowercased().contains(building.name.lowercased())
            }?.id
        } catch {
            return nil
        }
    }
    
    private func getTasksFromOperationalData(workerId: String, date: Date) async -> [ContextualTask] {
        let workerName = WorkerConstants.getWorkerName(id: workerId)
        let workerTasks = operationalData.realWorldTasks.filter { $0.assignedWorker == workerName }
        
        return workerTasks.map { operationalTask in
            convertOperationalTaskToContextualTask(operationalTask, workerId: workerId)
        }
    }
    
    private func getAllTasksFromOperationalData() async -> [ContextualTask] {
        return operationalData.realWorldTasks.compactMap { operationalTask in
            guard let workerId = getWorkerIdFromName(operationalTask.assignedWorker) else { return nil }
            return convertOperationalTaskToContextualTask(operationalTask, workerId: workerId)
        }
    }
    
    private func convertOperationalTaskToContextualTask(_ operationalTask: OperationalDataTaskAssignment, workerId: String) -> ContextualTask {
        let buildingId = getBuildingIdFromName(operationalTask.building)
        
        return ContextualTask(
            id: "op_\(operationalTask.taskName.hash)",
            title: operationalTask.taskName,
            description: "Operational task: \(operationalTask.taskName) at \(operationalTask.building)",
            isCompleted: false,
            completedDate: nil,
            scheduledDate: Date(),
            dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()),
            category: mapToTaskCategory(operationalTask.category),
            urgency: mapToTaskUrgency(operationalTask.skillLevel),
            building: nil, // Would need to fetch from BuildingService
            worker: nil,   // Would need to fetch from WorkerService
            buildingId: buildingId,
            buildingName: operationalTask.building
        )
    }
    
    private func generateInsightsFromOperationalData() async -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Get task distribution by worker
        let workerTaskCounts = operationalData.getWorkerTaskSummary()
        
        // Generate insights about task distribution
        for (workerName, taskCount) in workerTaskCounts {
            if taskCount > 20 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "High Task Load",
                    description: "\(workerName) has \(taskCount) tasks assigned",
                    type: .performance,
                    priority: .medium,
                    actionRequired: false,
                    affectedBuildings: []
                ))
            }
        }
        
        // Generate insights about building coverage
        let buildingCoverage = operationalData.getBuildingCoverage()
        for (building, workers) in buildingCoverage {
            if workers.count == 1 {
                insights.append(CoreTypes.IntelligenceInsight(
                    title: "Single Worker Coverage",
                    description: "\(building) relies on single worker: \(workers.first ?? "Unknown")",
                    type: .maintenance,
                    priority: .medium,
                    actionRequired: true,
                    affectedBuildings: []
                ))
            }
        }
        
        return insights
    }
    
    private func mapToTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "sanitation": return .sanitation
        case "inspection": return .inspection
        default: return .maintenance
        }
    }
    
    private func mapToTaskUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency {
        switch skillLevel.lowercased() {
        case "advanced": return .high
        case "intermediate": return .medium
        case "basic": return .low
        default: return .medium
        }
    }
}

// MARK: - Supporting Types

public struct DatabaseIntegrity {
    var hasWorkers = false
    var hasBuildings = false
    var hasTasks = false
    var hasAssignments = false
    var workerCount = 0
    var buildingCount = 0
    var taskCount = 0
    var assignmentCount = 0
    var needsSync = true
    var isComplete = false
    var hasError = false
    var errorMessage: String?
}

public struct ServiceDataFlow {
    var taskServiceWorking = false
    var workerServiceWorking = false
    var buildingServiceWorking = false
    var intelligenceServiceWorking = false
    var taskCount = 0
    var workerCount = 0
    var buildingCount = 0
    var insightCount = 0
    var isComplete = false
    var hasError = false
    var errorMessage: String?
}
