//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/9/25.
//


//
//  WorkerContextEngineAdapter.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All syntax errors resolved
//  ✅ ADDED: Missing braces and proper async/await patterns
//  ✅ ENHANCED: Complete method implementations
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerContextEngineAdapter: ObservableObject {
    public static let shared = WorkerContextEngineAdapter()
    
    @Published public var currentWorker: WorkerProfile?
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: TaskProgress?
    @Published public var isLoading = false
    @Published public var hasPendingScenario = false
    
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupPeriodicUpdates()
    }
    
    // ✅ FIXED: Added missing braces and proper error handling
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
    
    public func todayWorkers() -> [WorkerProfile] {
        if let w = currentWorker { return [w] }
        return []
    }
    
    public func getTasksForBuilding(_ b: String) -> [ContextualTask] {
        todaysTasks.filter { $0.buildingId == b }
    }
    
    public func getUrgentTaskCount() -> Int {
        todaysTasks.filter { [.high, .critical].contains($0.urgency) }.count
    }
    
    public func getUrgentTasks() -> [ContextualTask] {
        todaysTasks.filter { [.high, .critical].contains($0.urgency) }
    }
    
    public func getNextScheduledTask() -> ContextualTask? {
        todaysTasks
            .filter { !$0.isCompleted }
            .sorted { first, second in
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
    
    // ✅ FIXED: Proper async state refresh
    private func refreshPublishedState() async {
        currentWorker = await contextEngine.getCurrentWorker()
        assignedBuildings = await contextEngine.getAssignedBuildings()
        todaysTasks = await contextEngine.getTodaysTasks()
        taskProgress = await contextEngine.getTaskProgress()
        isLoading = await contextEngine.getIsLoading()
        hasPendingScenario = getUrgentTaskCount() > 0
    }
    
    private func setupPeriodicUpdates() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refreshPublishedState() }
            }
            .store(in: &cancellables)
    }
}