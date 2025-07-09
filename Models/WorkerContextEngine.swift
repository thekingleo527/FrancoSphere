////
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 — COMPLETE ACTOR IMPLEMENTATION
//
//  ✅ COMPLETE: All methods from backup restored
//  ✅ ENHANCED: Proper actor isolation patterns
//  ✅ COMPATIBLE: Works with WorkerContextEngineAdapter
//

import Foundation
import CoreLocation
import Combine

public actor WorkerContextEngine {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Private State (Actor-Isolated)
    private var currentWorker: WorkerProfile?
    private var assignedBuildings: [NamedCoordinate] = []
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
    
    private init() {}
    
    // MARK: - Public API (All methods async)
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context for worker: \(workerId)")
        
        do {
            // Load REAL worker data from database
            async let profile = workerService.getWorkerProfile(for: workerId)
            async let buildings = buildingService.getBuildingsForWorker(workerId)
            async let tasks = taskService.getTasks(for: workerId, date: Date())
            async let progress = taskService.getTaskProgress(for: workerId)
            
            // Update state atomically
            self.currentWorker = try await profile
            self.assignedBuildings = try await buildings
            self.todaysTasks = try await tasks
            self.taskProgress = try await progress
            
            // Update clock-in status
            let status = await ClockInManager.shared.getClockInStatus(for: workerId)
            self.clockInStatus = (status.isClockedIn, status.session?.building)
            
            print("✅ Context loaded: \(self.assignedBuildings.count) buildings, \(self.todaysTasks.count) tasks")
            
        } catch {
            lastError = error
            print("❌ loadContext failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Getter Methods (Replace @Published)
    
    public func getCurrentWorker() -> WorkerProfile? { currentWorker }
    public func getAssignedBuildings() -> [NamedCoordinate] { assignedBuildings }
    public func getTodaysTasks() -> [ContextualTask] { todaysTasks }
    public func getTaskProgress() -> TaskProgress? { taskProgress }
    public func isWorkerClockedIn() -> Bool { clockInStatus.isClockedIn }
    public func getCurrentBuilding() -> NamedCoordinate? { clockInStatus.building }
    public func getIsLoading() -> Bool { isLoading }
    public func getLastError() -> Error? { lastError }
    
    // MARK: - Worker Information
    
    public func getWorkerId() -> String? { currentWorker?.id }
    public func getWorkerName() -> String { currentWorker?.name ?? "Unknown" }
    public func getWorkerRole() -> String { currentWorker?.role.rawValue ?? "worker" }
    public func getWorkerStatus() -> WorkerStatus {
        clockInStatus.isClockedIn ? .clockedIn : .available
    }
    
    // MARK: - Task Management
    
    public func recordTaskCompletion(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        taskId: CoreTypes.TaskID,
        evidence: ActionEvidence
    ) async throws {
        print("📝 Recording task completion: \(taskId)")
        
        // Record to database
        try await taskService.completeTask(taskId, evidence: evidence)
        
        // Update local state
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = true
            todaysTasks[index].completedDate = Date()
        }
        
        // Refresh progress
        self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        
        print("✅ Task completed and progress updated")
    }
    
    public func addTask(_ task: ContextualTask) async throws {
        print("➕ Adding new task: \(task.title)")
        
        // Add to database
        try await taskService.createTask(task)
        
        // Update local state
        todaysTasks.append(task)
        
        // Refresh progress
        if let workerId = currentWorker?.id {
            self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        }
    }
    
    // MARK: - Clock In/Out Management
    
    public func clockIn(at building: NamedCoordinate) async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking in at: \(building.name)")
        
        // Update database through ClockInManager
        try await ClockInManager.shared.clockIn(workerId: workerId, building: building)
        
        // Update local state
        clockInStatus = (true, building)
        
        print("✅ Clocked in successfully")
    }
    
    public func clockOut() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking out...")
        
        // Update database
        try await ClockInManager.shared.clockOut(workerId: workerId)
        
        // Update local state
        clockInStatus = (false, nil)
        
        print("✅ Clocked out successfully")
    }
    
    // MARK: - Data Refresh
    
    public func refreshData() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        try await loadContext(for: workerId)
    }
    
    public func refreshContext() async {
        guard let workerId = currentWorker?.id else {
            print("⚠️ No current worker to refresh context for")
            return
        }
        
        do {
            try await loadContext(for: workerId)
        } catch {
            print("❌ Failed to refresh context: \(error)")
            lastError = error
        }
    }
    
    // MARK: - Enhanced Task Queries
    
    public func getUrgentTasks() -> [ContextualTask] {
        return todaysTasks.filter { task in
            task.urgency == .high || task.urgency == .critical
        }
    }
    
    public func getNextScheduledTask() -> ContextualTask? {
        return todaysTasks
            .filter { !$0.isCompleted }
            .sorted { first, second in
                // Sort by urgency first, then by due date
                if first.urgency != second.urgency {
                    return first.urgency.rawValue > second.urgency.rawValue
                }
                
                guard let firstDue = first.dueDate, let secondDue = second.dueDate else {
                    return first.dueDate != nil
                }
                
                return firstDue < secondDue
            }
            .first
    }
    
    public func getCompletedTasksToday() -> [ContextualTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return todaysTasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return completedDate >= today && completedDate < tomorrow
        }
    }
    
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    // MARK: - Legacy Compatibility Methods
    
    public func todayWorkers() -> [WorkerProfile] {
        // Return current worker as array for compatibility
        if let worker = currentWorker {
            return [worker]
        }
        return []
    }
    
    public func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { $0.urgency == .high || $0.urgency == .critical }.count
    }
    
    // MARK: - Real-time Updates
    
    public func updateTaskStatus(taskId: String, isCompleted: Bool) async {
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = isCompleted
            if isCompleted {
                todaysTasks[index].completedDate = Date()
            } else {
                todaysTasks[index].completedDate = nil
            }
        }
    }
    
    public func addNewTask(_ task: ContextualTask) async {
        todaysTasks.append(task)
    }
    
    public func removeTask(withId taskId: String) async {
        todaysTasks.removeAll { $0.id == taskId }
    }
}

// MARK: - Supporting Types

public enum WorkerStatus {
    case available, clockedIn, onBreak, offDuty
}

public enum WorkerContextError: Error {
    case noCurrentWorker
    case buildingNotFound
    case taskNotFound
    case clockInFailed(String)
    
    public var localizedDescription: String {
        switch self {
        case .noCurrentWorker:
            return "No current worker logged in"
        case .buildingNotFound:
            return "Building not found"
        case .taskNotFound:
            return "Task not found"
        case .clockInFailed(let reason):
            return "Clock in failed: \(reason)"
        }
    }
}

// MARK: - Extension for Convenience
extension WorkerContextEngine {
    
    public func getWorkerSummary() async -> WorkerSummary {
        let urgentCount = getUrgentTasks().count
        let completedToday = getCompletedTasksToday().count
        let totalTasks = todaysTasks.count
        
        return WorkerSummary(
            workerId: getWorkerId() ?? "unknown",
            workerName: getWorkerName(),
            totalTasksToday: totalTasks,
            completedTasksToday: completedToday,
            urgentTasksPending: urgentCount,
            isClockedIn: isWorkerClockedIn(),
            currentBuilding: getCurrentBuilding()?.name
        )
    }
}

public struct WorkerSummary {
    public let workerId: String
    public let workerName: String
    public let totalTasksToday: Int
    public let completedTasksToday: Int
    public let urgentTasksPending: Int
    public let isClockedIn: Bool
    public let currentBuilding: String?
}
