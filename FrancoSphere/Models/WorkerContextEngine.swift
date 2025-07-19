//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 - FIXED: Uses OperationalDataManager as Source of Truth
//
//  ✅ FIXED: Connected to OperationalDataManager for real data
//  ✅ FIXED: All compilation errors resolved
//  ✅ UNIFIED: Single source of truth for all worker context
//  ✅ ALIGNED: With existing project structure and types
//

import Foundation
import CoreLocation

public actor WorkerContextEngine {
    public nonisolated static let shared = WorkerContextEngine()
    
    // MARK: - Private State
    private var currentWorker: WorkerProfile?
    private var assignedBuildings: [NamedCoordinate] = []
    private var portfolioBuildings: [NamedCoordinate] = []
    private var todaysTasks: [ContextualTask] = []
    private var taskProgress: TaskProgress?
    private var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    private var isLoading = false
    private var lastError: Error?
    
    // MARK: - Dependencies - OperationalDataManager as Source of Truth
    private let operationalData = OperationalDataManager.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let clockInManager = ClockInManager.shared
    
    private init() {}
    
    // MARK: - FIXED: Real Data Loading Using OperationalDataManager
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context for worker: \(workerId) using OperationalDataManager")
        
        do {
            // STEP 1: Get worker profile from service
            let allWorkers = try await workerService.getAllActiveWorkers()
            guard let worker = allWorkers.first(where: { $0.id == workerId }) else {
                throw WorkerContextError.workerNotFound(workerId)
            }
            self.currentWorker = worker
            
            // STEP 2: Get worker name for OperationalDataManager lookup
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            
            // STEP 3: Get real assignments from OperationalDataManager
            // ✅ FIXED: Use method call instead of direct property access
            let realWorldAssignments = await operationalData.getLegacyTaskAssignments().filter {
                $0.assignedWorker == workerName
            }
            
            print("📊 Found \(realWorldAssignments.count) real world assignments for \(workerName)")
            
            // STEP 4: Convert to unique buildings
            var uniqueBuildingNames = Set<String>()
            for task in realWorldAssignments {
                uniqueBuildingNames.insert(task.building)
            }
            
            // STEP 5: Get building details for assigned buildings
            let allBuildings = try await buildingService.getAllBuildings()
            var assignedBuildings: [NamedCoordinate] = []
            
            for buildingName in uniqueBuildingNames {
                // Match building names (fuzzy matching for variations)
                if let building = allBuildings.first(where: { building in
                    building.name.lowercased().contains(buildingName.lowercased()) ||
                    buildingName.lowercased().contains(building.name.lowercased())
                }) {
                    assignedBuildings.append(building)
                    print("✅ Matched building: \(buildingName) → \(building.name)")
                }
            }
            
            self.assignedBuildings = assignedBuildings
            self.portfolioBuildings = allBuildings // Full portfolio access for coverage
            
            // STEP 6: Generate contextual tasks from real operational data
            let todaysTasks = await generateContextualTasks(
                for: workerId,
                workerName: workerName,
                assignedBuildings: assignedBuildings,
                realWorldAssignments: realWorldAssignments
            )
            self.todaysTasks = todaysTasks
            
            // STEP 7: Calculate real task progress
            let completedTasks = todaysTasks.filter { $0.isCompleted }.count
            let totalTasks = todaysTasks.count
            let progressPercentage = totalTasks > 0 ?
                Double(completedTasks) / Double(totalTasks) * 100.0 : 0.0
            
            self.taskProgress = TaskProgress(
                completedTasks: completedTasks,
                totalTasks: totalTasks,
                progressPercentage: progressPercentage
            )
            
            // STEP 8: Get clock-in status
            let clockInStatus = await clockInManager.getClockInStatus(for: workerId)
            if let session = clockInStatus.session {
                let building = NamedCoordinate(
                    id: session.buildingId,
                    name: session.buildingName,
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (clockInStatus.isClockedIn, building)
            } else {
                self.clockInStatus = (clockInStatus.isClockedIn, nil)
            }
            
            print("✅ Context loaded successfully:")
            print("   Worker: \(workerName)")
            print("   Assigned Buildings: \(assignedBuildings.count)")
            print("   Portfolio Buildings: \(allBuildings.count)")
            print("   Today's Tasks: \(todaysTasks.count)")
            print("   Progress: \(completedTasks)/\(totalTasks) (\(Int(progressPercentage))%)")
            
        } catch {
            lastError = error
            print("❌ Context loading failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Real Task Generation from OperationalDataManager
    
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        assignedBuildings: [NamedCoordinate],
        realWorldAssignments: [LegacyTaskAssignment]
    ) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        for (index, operational) in realWorldAssignments.enumerated() {
            // Find matching building
            let building = assignedBuildings.first { building in
                building.name.lowercased().contains(operational.building.lowercased()) ||
                operational.building.lowercased().contains(building.name.lowercased())
            }
            
            // Map category
            let category = mapOperationalCategory(operational.category)
            
            // Map urgency based on skill level
            let urgency = mapOperationalUrgency(operational.skillLevel)
            
            // Calculate schedule
            let scheduledDate = calculateScheduledDate(operational.recurrence)
            let dueDate = Calendar.current.date(byAdding: .hour, value: 4, to: scheduledDate)
            
            // ✅ FIXED: Use correct ContextualTask initializer parameter order
            let task = ContextualTask(
                id: "op_task_\(workerId)_\(index)",
                title: operational.taskName,
                description: "Operational assignment: \(operational.taskName) at \(operational.building)",
                isCompleted: false, // ✅ FIXED: isCompleted comes before buildingId
                scheduledDate: scheduledDate,
                dueDate: dueDate,
                category: category,
                urgency: urgency,
                buildingId: building?.id,
                buildingName: operational.building
            )
            
            tasks.append(task)
        }
        
        // Sort by urgency
        return tasks.sorted { task1, task2 in
            let urgency1 = task1.urgency?.numericValue ?? 0
            let urgency2 = task2.urgency?.numericValue ?? 0
            return urgency1 > urgency2
        }
    }
    
    // MARK: - Mapping Helpers
    
    private func mapOperationalCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "inspection": return .inspection
        case "security": return .security
        case "sanitation": return .cleaning
        case "operations": return .maintenance
        default: return .maintenance
        }
    }
    
    private func mapOperationalUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency {
        switch skillLevel.lowercased() {
        case "advanced", "critical": return .critical
        case "intermediate": return .urgent
        case "basic": return .medium  // ✅ FIXED: Use .medium instead of .normal
        default: return .medium
        }
    }
    
    private func calculateScheduledDate(_ recurrence: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch recurrence.lowercased() {
        case "daily":
            return calendar.startOfDay(for: now)
        case "weekly":
            // Schedule for next occurrence
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case "monthly":
            return calendar.date(byAdding: .day, value: 7, to: now) ?? now
        default:
            return now
        }
    }
    
    // MARK: - Public API Methods
    
    public func getCurrentWorker() -> WorkerProfile? { currentWorker }
    public func getAssignedBuildings() -> [NamedCoordinate] { assignedBuildings }
    public func getPortfolioBuildings() -> [NamedCoordinate] { portfolioBuildings }
    public func getTodaysTasks() -> [ContextualTask] { todaysTasks }
    public func getTaskProgress() -> TaskProgress? { taskProgress }
    public func isWorkerClockedIn() -> Bool { clockInStatus.isClockedIn }
    public func getCurrentBuilding() -> NamedCoordinate? { clockInStatus.building }
    public func getIsLoading() -> Bool { isLoading }
    public func getLastError() -> Error? { lastError }
    
    // MARK: - Building Access Methods
    
    public func isBuildingAssigned(_ buildingId: String) -> Bool {
        return assignedBuildings.contains { $0.id == buildingId }
    }
    
    public func getBuildingType(_ buildingId: String) -> BuildingAccessType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        }
        return .unknown
    }
    
    // MARK: - Task Management
    
    public func refreshData() async throws {
        guard let worker = currentWorker else { return }
        try await loadContext(for: worker.id)
    }
    
    public func clockIn(at building: NamedCoordinate) async throws {
        guard let worker = currentWorker else {
            throw WorkerContextError.noWorkerContext
        }
        
        // ✅ FIXED: Use correct ClockInManager method signature
        try await clockInManager.clockIn(
            workerId: worker.id,
            building: building,
            location: building.coordinate
        )
        
        self.clockInStatus = (true, building)
        try await refreshData()
    }
    
    public func clockOut() async throws {
        guard let worker = currentWorker else {
            throw WorkerContextError.noWorkerContext
        }
        
        try await clockInManager.clockOut(workerId: worker.id)
        self.clockInStatus = (false, nil)
    }
    
    public func recordTaskCompletion(
        workerId: String,
        buildingId: String,
        taskId: String,
        evidence: ActionEvidence
    ) async throws {
        // Find and update task
        guard let taskIndex = todaysTasks.firstIndex(where: { $0.id == taskId }) else {
            throw WorkerContextError.taskNotFound(taskId)
        }
        
        var task = todaysTasks[taskIndex]
        task.isCompleted = true
        task.completedDate = Date()
        todaysTasks[taskIndex] = task
        
        // Recalculate progress
        let completedTasks = todaysTasks.filter { $0.isCompleted }.count
        let totalTasks = todaysTasks.count
        let progressPercentage = totalTasks > 0 ?
            Double(completedTasks) / Double(totalTasks) * 100.0 : 0.0
        
        self.taskProgress = TaskProgress(
            completedTasks: completedTasks,
            totalTasks: totalTasks,
            progressPercentage: progressPercentage
        )
        
        print("✅ Task completed: \(task.title) - Progress: \(completedTasks)/\(totalTasks)")
    }
}

// MARK: - Supporting Types

public enum BuildingAccessType {
    case assigned
    case coverage
    case unknown
}

public enum WorkerContextError: LocalizedError {
    case workerNotFound(String)
    case noWorkerContext
    case taskNotFound(String)
    case dataUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .workerNotFound(let id):
            return "Worker not found: \(id)"
        case .noWorkerContext:
            return "No worker context available"
        case .taskNotFound(let id):
            return "Task not found: \(id)"
        case .dataUnavailable:
            return "Required data is unavailable"
        }
    }
}

// MARK: - TaskUrgency Extension (if not already defined)

extension CoreTypes.TaskUrgency {
    var numericValue: Int {
        switch self {
        case .critical: return 5
        case .emergency: return 5
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}
