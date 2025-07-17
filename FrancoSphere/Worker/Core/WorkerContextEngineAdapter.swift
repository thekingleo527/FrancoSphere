//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0 - PORTFOLIO SUPPORT ADDED
//
//  ✅ ADDED: Portfolio buildings support
//  ✅ ADDED: Building type classification
//  ✅ FIXED: Real-time updates for both assigned and portfolio buildings
//  ✅ FIXED: Compilation errors in sorting and TaskUrgency handling
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []  // NEW: Portfolio access
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var isLoading = false
    @Published public var hasPendingScenario = false
    
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPeriodicUpdates()
    }
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async {
        isLoading = true
        do {
            try await contextEngine.loadContext(for: workerId)
            await refreshPublishedState()
        } catch {
            print("❌ Failed to load context:", error)
        }
        isLoading = false
    }
    
    private func refreshPublishedState() async {
        self.currentWorker = await contextEngine.getCurrentWorker()
        self.assignedBuildings = await contextEngine.getAssignedBuildings()
        self.portfolioBuildings = await contextEngine.getPortfolioBuildings()  // NEW: Portfolio access
        self.todaysTasks = await contextEngine.getTodaysTasks()
        self.taskProgress = await contextEngine.getTaskProgress()
        
        print("🔄 State refreshed: \(assignedBuildings.count) assigned, \(portfolioBuildings.count) portfolio")
    }
    
    // MARK: - Building Classification Methods
    
    public func isBuildingAssigned(_ buildingId: String) -> Bool {
        return assignedBuildings.contains { $0.id == buildingId }
    }
    
    public func getBuildingType(_ buildingId: String) -> BuildingType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        }
        return .unknown
    }
    
    public func getPrimaryBuilding() -> NamedCoordinate? {
        guard let worker = currentWorker else { return nil }
        
        // Return primary building based on worker assignments
        switch worker.id {
        case "4": return assignedBuildings.first { $0.name.contains("Rubin") }
        case "2": return assignedBuildings.first { $0.name.contains("Stuyvesant") || $0.name.contains("Park") }
        case "5": return assignedBuildings.first { $0.name.contains("112 West 18th") }
        case "6": return assignedBuildings.first { $0.name.contains("41 Elizabeth") }
        case "1": return assignedBuildings.first { $0.name.contains("12 West 18th") }
        case "7": return assignedBuildings.first { $0.name.contains("12 West 18th") }
        case "8": return assignedBuildings.first { $0.name.contains("FrancoSphere") }
        default: return assignedBuildings.first
        }
    }
    
    public enum BuildingType {
        case assigned   // Worker's regular assignments
        case coverage   // Available for coverage
        case unknown    // Not in portfolio
    }
    
    // MARK: - Existing Methods (Enhanced)
    
    public func todayWorkers() -> [WorkerProfile] {
        if let w = currentWorker { return [w] }
        return []
    }
    
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    public func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .high || urgency == .critical
        }.count
    }
    
    public func getUrgentTasks() -> [ContextualTask] {
        return todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .high || urgency == .critical
        }
    }
    
    // MARK: - ✅ FIXED: Next Scheduled Task with Proper Sorting
    public func getNextScheduledTask() -> ContextualTask? {
        return todaysTasks
            .filter { !$0.isCompleted }
            .sorted { (first: ContextualTask, second: ContextualTask) -> Bool in
                // ✅ FIXED: Explicit types and proper TaskUrgency handling
                let firstUrgency = first.urgency ?? TaskUrgency.medium
                let secondUrgency = second.urgency ?? TaskUrgency.medium
                
                // ✅ FIXED: Use proper urgency comparison
                return getUrgencyPriority(firstUrgency) > getUrgencyPriority(secondUrgency)
            }
            .first
    }
    
    // ✅ FIXED: Helper method for urgency priority comparison
    private func getUrgencyPriority(_ urgency: TaskUrgency) -> Int {
        switch urgency {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        default: return 2  // Default to medium priority for any other cases
        }
    }
    
    public func getTaskProgress() -> TaskProgress? {
        return taskProgress
    }
    
    // MARK: - Setup Methods
    
    private func setupPeriodicUpdates() {
        // Refresh every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshContextIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshContextIfNeeded() async {
        guard let workerId = currentWorker?.id else { return }
        
        do {
            try await contextEngine.refreshData()
            await refreshPublishedState()
        } catch {
            print("❌ Failed to refresh context: \(error)")
        }
    }
}
