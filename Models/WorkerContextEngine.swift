//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 — PORTFOLIO ACCESS FIXED
//
//  ✅ FIXED: Portfolio access - workers can access ALL buildings for coverage
//  ✅ FIXED: Database query failures resolved
//  ✅ ADDED: Both assigned and portfolio building access
//

import Foundation
import CoreLocation
import Combine

public actor WorkerContextEngine {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Private State (Actor-Isolated)
    private var currentWorker: WorkerProfile?
    private var assignedBuildings: [NamedCoordinate] = []
    private var portfolioBuildings: [NamedCoordinate] = []  // NEW: Full portfolio access
    private var todaysTasks: [ContextualTask] = []
    private var taskProgress: TaskProgress?
    private var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    private var isLoading = false
    private var lastError: Error?
    
    // MARK: - Dependencies
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    
    // MARK: - Dependencies (ADD OperationalDataManager)
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    private let operationalData = OperationalDataManager.shared  // NEW: Real operational data
    
    private init() {}
    
    // MARK: - Public API (All methods async)
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context for worker: \(workerId)")
        
        do {
            // Load worker profile
            let profile = try await workerService.getWorkerProfile(for: workerId)
            self.currentWorker = profile
            
            // CRITICAL FIX: Get real assignments from OperationalDataManager
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            let realWorldAssignments = operationalData.realWorldTasks.filter { 
                $0.assignedWorker == workerName 
            }
            
            // Convert to unique buildings
            var uniqueBuildings = Set<String>()
            for task in realWorldAssignments {
                uniqueBuildings.insert(task.building)
            }
            
            // Get building details for assigned buildings
            var assignedBuildings: [NamedCoordinate] = []
            for buildingName in uniqueBuildings {
                if let buildingId = await operationalData.getRealBuildingId(from: buildingName),
                   let building = try? await buildingService.getBuilding(buildingId: buildingId) {
                    assignedBuildings.append(building)
                }
            }
            self.assignedBuildings = assignedBuildings
            
            // Get ALL buildings for portfolio access (coverage)
            let allBuildings = try await buildingService.getAllBuildings()
            self.portfolioBuildings = allBuildings
            
            // Generate contextual tasks from real operational data
            let todaysTasks = await generateContextualTasks(
                for: workerId,
                workerName: workerName,
                assignedBuildings: assignedBuildings
            )
            self.todaysTasks = todaysTasks
            
            // Calculate task progress
            let completedTasks = todaysTasks.filter { $0.isCompleted }.count
            let totalTasks = todaysTasks.count
            let progressPercentage = totalTasks > 0 ? 
                Double(completedTasks) / Double(totalTasks) * 100.0 : 0.0
            
            self.taskProgress = TaskProgress(
                completedTasks: completedTasks,
                totalTasks: totalTasks,
                progressPercentage: progressPercentage
            )
            
            // Clock-in status with enhanced error handling
            let status = await ClockInManager.shared.getClockInStatus(for: workerId)
            if let session = status.session {
                let building = NamedCoordinate(
                    id: session.buildingId,
                    name: session.buildingName,
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (status.isClockedIn, building)
            } else {
                self.clockInStatus = (status.isClockedIn, nil)
            }
            
            print("✅ Context loaded: \(self.assignedBuildings.count) assigned, \(self.portfolioBuildings.count) portfolio, \(todaysTasks.count) tasks")
            
        } catch {
            lastError = error
            print("❌ loadContext failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // NEW: Generate contextual tasks from operational data
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        assignedBuildings: [NamedCoordinate]
    ) async -> [ContextualTask] {
        var tasks: [ContextualTask] = []
        
        // Get routine tasks from OperationalDataManager
        let routineTasks = operationalData.realWorldTasks.filter {
            $0.assignedWorker == workerName
        }
        
        // Convert to ContextualTasks
        for routine in routineTasks {
            let building = assignedBuildings.first { $0.name.contains(routine.building) }
            
            let task = ContextualTask(
                id: UUID().uuidString,
                title: routine.taskName,
                description: "Routine task: \(routine.taskName) at \(routine.building)",
                buildingId: building?.id,
                buildingName: routine.building,
                category: mapToTaskCategory(routine.category),
                urgency: mapToUrgency(routine.skillLevel),
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date())
            )
            tasks.append(task)
        }
        
        return tasks.sorted { task1, task2 in
            let urgency1 = task1.urgency?.numericValue ?? 0
            let urgency2 = task2.urgency?.numericValue ?? 0
            return urgency1 > urgency2
        }
    }
    
    // Helper mapping functions
    private func mapToTaskCategory(_ category: String) -> CoreTypes.TaskCategory {
        switch category.lowercased() {
        case "cleaning": return .cleaning
        case "maintenance": return .maintenance
        case "inspection": return .inspection
        case "security": return .security
        default: return .maintenance
        }
    }
    
    private func mapToUrgency(_ skillLevel: String) -> CoreTypes.TaskUrgency {
        switch skillLevel.lowercased() {
        case "critical", "high": return .critical
        case "medium": return .urgent
        default: return .normal
        }
    }
    // MARK: - Enhanced Getter Methods
    
    public func getCurrentWorker() -> WorkerProfile? { currentWorker }
    public func getAssignedBuildings() -> [NamedCoordinate] { assignedBuildings }
    public func getPortfolioBuildings() -> [NamedCoordinate] { portfolioBuildings }  // NEW: Portfolio access
    public func getTodaysTasks() -> [ContextualTask] { todaysTasks }
    public func getTaskProgress() -> TaskProgress? { taskProgress }
    public func isWorkerClockedIn() -> Bool { clockInStatus.isClockedIn }
    public func getCurrentBuilding() -> NamedCoordinate? { clockInStatus.building }
    public func getIsLoading() -> Bool { isLoading }
    public func getLastError() -> Error? { lastError }
    
    // NEW: Building classification methods
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
    
    // Rest of existing methods remain the same...
    public func getWorkerId() -> String? { currentWorker?.id }
    public func getWorkerName() -> String { currentWorker?.name ?? "Unknown" }
    public func getWorkerRole() -> String { currentWorker?.role.rawValue ?? "worker" }
    public func getWorkerStatus() -> WorkerStatus {
        clockInStatus.isClockedIn ? .clockedIn : .available
    }
    
    // Clock In/Out Management
    public func clockIn(at building: NamedCoordinate) async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking in at: \(building.name)")
        
        try await ClockInManager.shared.clockIn(workerId: workerId, building: building)
        clockInStatus = (true, building)
        
        print("✅ Clocked in successfully")
    }
    
    public func clockOut() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking out...")
        
        try await ClockInManager.shared.clockOut(workerId: workerId)
        clockInStatus = (false, nil)
        
        print("✅ Clocked out successfully")
    }
    
    // Enhanced Task Management
    public func recordTaskCompletion(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        taskId: CoreTypes.TaskID,
        evidence: ActionEvidence
    ) async throws {
        print("📝 Recording task completion: \(taskId)")
        
        try await taskService.completeTask(taskId, evidence: evidence)
        
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = true
            todaysTasks[index].completedDate = Date()
        }
        
        self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        
        print("✅ Task completed and progress updated")
    }
    
    public func refreshData() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        try await loadContext(for: workerId)
    }
}

// NEW: Building access classification
public enum BuildingAccessType {
    case assigned   // Worker's regular assignments
    case coverage   // Available for coverage
    case unknown    // Not in portfolio
}

// Enhanced error types
public enum WorkerContextError: Error {
    case noCurrentWorker
    case noAssignedBuildings
    case buildingNotFound
    case taskNotFound
    case clockInFailed(String)
}
