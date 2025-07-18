//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0
//
//  ✅ COMPILATION FIXED: All missing types and errors resolved
//  ✅ PORTFOLIO ACCESS: Full support for assigned and portfolio buildings
//  ✅ TYPE SAFE: All types properly defined and consistent
//  ✅ PRODUCTION READY: Complete implementation with all required methods
//
//  📁 REPLACE: /Volumes/FastSSD/Xcode/Services/Migration/WorkerContextEngineAdapter.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    // MARK: - Published Properties (FIXES ALL "Cannot find" ERRORS)
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var hasPendingScenario = false
    @Published public var isClockedIn = false
    @Published public var currentBuilding: NamedCoordinate?
    
    // MARK: - Dependencies
    
    private let contextEngine = WorkerContextEngine.shared
    private let operationalData = OperationalDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupDataBinding()
        setupPeriodicUpdates()
    }
    
    // MARK: - Public Interface Methods (FIXES ALL COMPONENT ERRORS)
    
    /// Initialize context for a worker (both String and CoreTypes.WorkerID support)
    public func loadContext(for workerId: String) async {
        await initializeContext(workerId: workerId)
    }
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        await initializeContext(workerId: workerId)
    }
    
    private func initializeContext(workerId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            await contextEngine.initializeContext(workerId: workerId)
            await refreshPublishedState()
            print("✅ WorkerContextEngineAdapter initialized for worker \(workerId)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to initialize context: \(error)")
        }
        
        isLoading = false
    }
    
    public func refreshData() async {
        guard let workerId = currentWorker?.id else { return }
        
        do {
            await contextEngine.refreshData()
            await refreshPublishedState()
        } catch {
            print("❌ Failed to refresh data: \(error)")
        }
    }
    
    // MARK: - Building Access Methods (PORTFOLIO SUPPORT)
    
    /// Get all buildings (assigned + portfolio) for coverage access
    public func getAllAccessibleBuildings() -> [NamedCoordinate] {
        return assignedBuildings + portfolioBuildings
    }
    
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
    
    public func getPrimaryBuilding() -> NamedCoordinate? {
        guard let worker = currentWorker else { return nil }
        
        let primaryId = determinePrimaryBuildingId(for: worker.id)
        let allBuildings = assignedBuildings + portfolioBuildings
        
        return allBuildings.first { $0.id == primaryId }
    }
    
    public func canAccessBuilding(_ buildingId: String) -> Bool {
        return isBuildingAssigned(buildingId) || portfolioBuildings.contains { $0.id == buildingId }
    }
    
    // MARK: - Task Management Methods (FIXES PROGRESS CARD ERRORS)
    
    public func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { task in
            task.urgency == .urgent || task.urgency == .critical
        }.count
    }
    
    public func getCompletedTaskCount() -> Int {
        return todaysTasks.filter { $0.isCompleted }.count
    }
    
    public func getTotalTaskCount() -> Int {
        return todaysTasks.count
    }
    
    public func getProgressPercentage() -> Double {
        guard getTotalTaskCount() > 0 else { return 0.0 }
        return Double(getCompletedTaskCount()) / Double(getTotalTaskCount()) * 100.0
    }
    
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    public func getOverdueTaskCount() -> Int {
        let now = Date()
        return todaysTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < now
        }.count
    }
    
    // MARK: - Worker Information Methods (FIXES HEADER ERRORS)
    
    public func getCurrentWorkerName() -> String {
        return currentWorker?.name ?? "Unknown Worker"
    }
    
    public func getCurrentWorkerRole() -> String {
        return currentWorker?.role.rawValue ?? "worker"
    }
    
    public func getCurrentWorkerId() -> String? {
        return currentWorker?.id
    }
    
    public func isWorkerClockedIn() -> Bool {
        return isClockedIn
    }
    
    public func getCurrentClockInBuilding() -> NamedCoordinate? {
        return currentBuilding
    }
    
    // MARK: - Clock-In Methods
    
    public func clockIn(at building: NamedCoordinate) async throws {
        await contextEngine.clockIn(at: building)
        await refreshPublishedState()
    }
    
    public func clockOut() async throws {
        try await contextEngine.clockOut()
        await refreshPublishedState()
    }
    
    // MARK: - Task Completion
    
    public func completeTask(_ task: ContextualTask) async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        let evidence = ActionEvidence(
            description: "Task completed via worker dashboard",
            photoURLs: [],
            timestamp: Date()
        )
        
        try await contextEngine.recordTaskCompletion(
            workerId: workerId,
            buildingId: task.buildingId ?? "unknown",
            taskId: task.id,
            evidence: evidence
        )
        
        await refreshPublishedState()
    }
    
    // MARK: - Worker-Specific Building Logic
    
    private func determinePrimaryBuildingId(for workerId: String) -> String? {
        switch workerId {
        case "4":  // Kevin Dutan - Rubin Museum specialist
            return "rubin-museum"
        case "2":  // Edwin Lema - Park operations
            return "stuyvesant-cove"
        case "5":  // Mercedes Inamagua - Perry Street focus
            return "131-perry"
        case "6":  // Luis Lopez - Elizabeth Street area
            return "41-elizabeth"
        case "1":  // Greg Hutson - 12 West 18th
            return "12-west-18th"
        case "7":  // Angel Guirachocha - Evening operations
            return "12-west-18th"
        case "8":  // Shawn Magloire - Management overview
            return nil  // No specific primary building
        default:
            return nil
        }
    }
    
    // MARK: - Enhanced Role Descriptions
    
    public func getEnhancedWorkerRole() -> String {
        guard let worker = currentWorker else { return "Building Operations" }
        
        switch worker.id {
        case "4": return "Museum & Property Specialist"
        case "2": return "Park Operations & Maintenance"
        case "5": return "West Village Buildings"
        case "6": return "Downtown Maintenance"
        case "1": return "Building Systems Specialist"
        case "7": return "Evening Operations"
        case "8": return "Portfolio Management"
        default: return worker.role.rawValue.capitalized
        }
    }
    
    public func getAssignmentSummary() -> String {
        let assignedCount = assignedBuildings.count
        let portfolioCount = portfolioBuildings.count
        
        if assignedCount == 0 {
            return "Portfolio access (\(portfolioCount) buildings)"
        } else if portfolioCount > assignedCount {
            return "\(assignedCount) assigned + \(portfolioCount - assignedCount) coverage"
        } else {
            return "\(assignedCount) buildings assigned"
        }
    }
    
    // MARK: - Private Implementation
    
    private func setupDataBinding() {
        Timer.publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPublishedState()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshPublishedState() async {
        self.currentWorker = await contextEngine.getCurrentWorker()
        self.assignedBuildings = await contextEngine.getAssignedBuildings()
        self.portfolioBuildings = await contextEngine.getPortfolioBuildings()
        self.todaysTasks = await contextEngine.getTodaysTasks()
        self.taskProgress = await contextEngine.getTaskProgress()
        self.isClockedIn = await contextEngine.isWorkerClockedIn()
        self.currentBuilding = await contextEngine.getCurrentBuilding()
        
        print("📊 State refreshed: \(assignedBuildings.count) assigned, \(portfolioBuildings.count) portfolio, \(todaysTasks.count) tasks")
    }
}

// MARK: - Supporting Types (ALL MISSING TYPES DEFINED)

/// Building access classification for portfolio support
public enum BuildingAccessType: String, CaseIterable {
    case assigned = "Assigned"
    case coverage = "Coverage"
    case unknown = "Unknown"
    
    public var displayName: String { return rawValue }
    
    public var color: Color {
        switch self {
        case .assigned: return .blue
        case .coverage: return .green
        case .unknown: return .gray
        }
    }
    
    public var icon: String {
        switch self {
        case .assigned: return "building.2.crop.circle"
        case .coverage: return "building.columns"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Task progress tracking
public struct TaskProgress {
    public let totalTasks: Int
    public let completedTasks: Int
    public let urgentTasks: Int
    public let overduelTasks: Int
    
    public var completionPercentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks) * 100.0
    }
    
    public var isOnTrack: Bool {
        return overduelTasks == 0 && urgentTasks <= 2
    }
    
    public var statusMessage: String {
        if totalTasks == 0 {
            return "No tasks for today"
        } else if completedTasks == totalTasks {
            return "All tasks completed"
        } else if overduelTasks > 0 {
            return "\(overduelTasks) overdue task(s)"
        } else if urgentTasks > 0 {
            return "\(urgentTasks) urgent task(s)"
        } else {
            return "\(totalTasks - completedTasks) remaining"
        }
    }
    
    public init(totalTasks: Int, completedTasks: Int, urgentTasks: Int, overduelTasks: Int) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.urgentTasks = urgentTasks
        self.overduelTasks = overduelTasks
    }
}

/// Worker context errors
public enum WorkerContextError: Error, LocalizedError {
    case noCurrentWorker
    case noAssignedBuildings
    case buildingNotFound
    case taskNotFound
    case clockInFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .noCurrentWorker:
            return "No current worker loaded"
        case .noAssignedBuildings:
            return "No buildings assigned to worker"
        case .buildingNotFound:
            return "Building not found"
        case .taskNotFound:
            return "Task not found"
        case .clockInFailed(let message):
            return "Clock-in failed: \(message)"
        }
    }
}

/// Action evidence for task completion
public struct ActionEvidence {
    public let description: String
    public let photoURLs: [String]
    public let timestamp: Date
    
    public init(description: String, photoURLs: [String], timestamp: Date) {
        self.description = description
        self.photoURLs = photoURLs
        self.timestamp = timestamp
    }
}

// MARK: - Convenience Extensions

extension WorkerContextEngineAdapter {
    
    /// Get dashboard metrics for UI cards
    public func getDashboardMetrics() -> (
        totalTasks: Int,
        completedTasks: Int,
        urgentTasks: Int,
        overdueTasksv: Int,
        progressPercentage: Double
    ) {
        return (
            totalTasks: getTotalTaskCount(),
            completedTasks: getCompletedTaskCount(),
            urgentTasks: getUrgentTaskCount(),
            overdueTasksv: getOverdueTaskCount(),
            progressPercentage: getProgressPercentage()
        )
    }
    
    /// Get organized building data for UI
    public func getBuildingsByType() -> (
        assigned: [NamedCoordinate],
        coverage: [NamedCoordinate],
        primary: NamedCoordinate?
    ) {
        return (
            assigned: assignedBuildings,
            coverage: portfolioBuildings,
            primary: getPrimaryBuilding()
        )
    }
}
