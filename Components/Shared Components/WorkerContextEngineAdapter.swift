//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0 - FIXED VERSION
//
//  ✅ ADDED: Missing currentBuilding property
//  ✅ FIXED: All dynamic member access issues
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var currentBuilding: NamedCoordinate? // ✅ ADDED: Missing property
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var portfolioBuildings: [NamedCoordinate] = []
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
        self.currentBuilding = await contextEngine.getCurrentBuilding() // ✅ ADDED
        self.assignedBuildings = await contextEngine.getAssignedBuildings()
        self.portfolioBuildings = await contextEngine.getPortfolioBuildings()
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
        return assignedBuildings.first
    }
    
    // MARK: - Periodic Updates
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshFromTimer()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshFromTimer() async {
        guard !isLoading else { return }
        await refreshPublishedState()
    }
    
    // MARK: - Cross-Dashboard Sync Support
    
    public func refreshFromSync() async {
        await refreshPublishedState()
    }
}
