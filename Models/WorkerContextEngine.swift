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
    
    private init() {}
    
    // MARK: - Public API (All methods async)
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context for worker: \(workerId)")
        
        do {
            // Load worker data with enhanced error handling
            async let profile = workerService.getWorkerProfile(for: workerId)
            async let assignedBuildings = buildingService.getBuildingsForWorker(workerId)
            async let portfolioBuildings = buildingService.getAllBuildings()  // NEW: Portfolio access
            async let tasks = taskService.getTasks(for: workerId, date: Date())
            async let progress = taskService.getTaskProgress(for: workerId)
            
            // Update state atomically
            self.currentWorker = try await profile
            self.assignedBuildings = try await assignedBuildings
            self.portfolioBuildings = try await portfolioBuildings  // NEW: Portfolio access
            self.todaysTasks = try await tasks
            self.taskProgress = try await progress
            
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
            
            print("✅ Context loaded: \(self.assignedBuildings.count) assigned, \(self.portfolioBuildings.count) portfolio")
            
        } catch {
            lastError = error
            print("❌ loadContext failed: \(error)")
            throw error
        }
        
        isLoading = false
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
