//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0 - IMPORT PATH FIXED
//
//  🚨 CRITICAL FIX: Resolves "Cannot find 'WorkerContextEngineAdapter' in scope"
//  ✅ FIXED: Proper public access levels
//  ✅ FIXED: Target membership corrected
//  ✅ ENHANCED: Import statements for all dependent files
//

import Foundation
import SwiftUI
import Combine

// MARK: - Public Actor-Safe Adapter
@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    // MARK: - Public Published Properties
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []
    @Published public var allAccessibleBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var isLoading = false
    @Published public var lastError: Error?
    @Published public var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    @Published public var hasPendingScenario = false
    
    // MARK: - Dependencies
    private let contextEngine = WorkerContextEngine.shared
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPeriodicUpdates()
    }
    
    // MARK: - Public API Methods
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        await MainActor.run {
            isLoading = true
            lastError = nil
        }
        
        do {
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
        } catch {
            await MainActor.run {
                self.lastError = error
                print("❌ Failed to load context:", error)
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    public func refreshData() async {
        guard let workerId = await contextEngine.getCurrentWorker()?.id else { return }
        await loadContext(for: workerId)
    }
    
    // MARK: - Building Access Methods
    
    public func canAccessBuilding(_ buildingId: String) async -> Bool {
        do {
            let accessResult = try await contextEngine.validateBuildingAccess(buildingId)
            return accessResult.hasAccess
        } catch {
            print("❌ Access validation failed: \(error)")
            return false
        }
    }
    
    public func getBuildingAccessType(_ buildingId: String) async -> BuildingAccessType {
        return await contextEngine.getBuildingAccessType(buildingId)
    }
    
    public func getPrimaryBuilding() -> NamedCoordinate? {
        return assignedBuildings.first
    }
    
    // MARK: - Clock In/Out Methods
    
    public func clockIn(at building: NamedCoordinate) async {
        do {
            try await contextEngine.clockIn(at: building)
            await refreshClockInStatus()
        } catch {
            await MainActor.run {
                self.lastError = error
                print("❌ Clock-in failed: \(error)")
            }
        }
    }
    
    public func clockOut() async {
        do {
            try await contextEngine.clockOut()
            await refreshClockInStatus()
        } catch {
            await MainActor.run {
                self.lastError = error
                print("❌ Clock-out failed: \(error)")
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func refreshPublishedState() async {
        let worker = await contextEngine.getCurrentWorker()
        let assigned = await contextEngine.getAssignedBuildings()
        let portfolio = await contextEngine.getPortfolioBuildings()
        let allAccessible = await contextEngine.getAllAccessibleBuildings()
        let tasks = await contextEngine.getTodaysTasks()
        let progress = await contextEngine.getTaskProgress()
        let isLoading = await contextEngine.getIsLoading()
        let error = await contextEngine.getLastError()
        let isClockedIn = await contextEngine.isWorkerClockedIn()
        let currentBuilding = await contextEngine.getCurrentBuilding()
        
        await MainActor.run {
            self.currentWorker = worker
            self.assignedBuildings = assigned
            self.portfolioBuildings = portfolio
            self.allAccessibleBuildings = allAccessible
            self.todaysTasks = tasks
            self.taskProgress = progress
            self.isLoading = isLoading
            self.lastError = error
            self.clockInStatus = (isClockedIn, currentBuilding)
        }
        
        print("🔄 State refreshed - Assigned: \(assigned.count), Portfolio: \(portfolio.count), Tasks: \(tasks.count)")
    }
    
    private func refreshClockInStatus() async {
        let isClockedIn = await contextEngine.isWorkerClockedIn()
        let currentBuilding = await contextEngine.getCurrentBuilding()
        
        await MainActor.run {
            self.clockInStatus = (isClockedIn, currentBuilding)
        }
    }
    
    private func setupPeriodicUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.refreshData()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    public var hasAssignedBuildings: Bool {
        return !assignedBuildings.isEmpty
    }
    
    public var hasPortfolioAccess: Bool {
        return !portfolioBuildings.isEmpty
    }
    
    public var totalAccessibleBuildings: Int {
        return allAccessibleBuildings.count
    }
    
    public var todaysTaskCompletion: Double {
        guard let progress = taskProgress, progress.totalTasks > 0 else { return 0 }
        return progress.percentage
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}

// MARK: - Building Type Classification

public enum BuildingType {
    case assigned
    case coverage
    case unknown
    
    public var displayName: String {
        switch self {
        case .assigned: return "Assigned"
        case .coverage: return "Coverage"
        case .unknown: return "Unknown"
        }
    }
    
    public var icon: String {
        switch self {
        case .assigned: return "building.2"
        case .coverage: return "building.2.crop.circle"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Supporting Types

public struct TaskProgress {
    public let totalTasks: Int
    public let completedTasks: Int
    public let percentage: Double
    
    public init(totalTasks: Int, completedTasks: Int, percentage: Double) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.percentage = percentage
    }
}
