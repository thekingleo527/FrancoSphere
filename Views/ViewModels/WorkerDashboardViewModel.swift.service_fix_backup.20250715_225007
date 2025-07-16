//
//  WorkerDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ PHASE 2: Actor-Compatible ViewModel with CORRECT Type Usage
//  ✅ Fixed all optional unwrapping issues
//  ✅ Uses correct ActionEvidence signature from DTOs
//  ✅ Integrates with existing CoreTypes and Services
//  ✅ Maintains all operational data continuity
//

import Foundation
import Combine
import SwiftUI
import CoreLocation

@MainActor
class WorkerDashboardViewModel: ObservableObject {
    // MARK: - Published State for UI
    @Published var assignedBuildings: [NamedCoordinate] = []
    @Published var todaysTasks: [ContextualTask] = []
    @Published var taskProgress: TaskProgress?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isClockedIn = false
    @Published var currentBuilding: NamedCoordinate?
    
    // MARK: - Actor Dependencies (Phase 2 Integration)
    private let authManager = NewAuthManager.shared
    private let contextEngine = WorkerContextEngine.shared
    private let metricsService = BuildingMetricsService.shared
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAutoRefresh()
    }

    // MARK: - Data Loading (Actor-Compatible Async Patterns)
    
    func loadInitialData() async {
        guard let user = await authManager.getCurrentUser() else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load context using Actor pattern (await calls)
            // ✅ FIXED: user.workerId is non-optional String from CoreTypes.User
            try await contextEngine.loadContext(for: user.workerId)
            
            // Update UI state from Actor
            self.assignedBuildings = await contextEngine.getAssignedBuildings()
            self.todaysTasks = await contextEngine.getTodaysTasks()
            self.taskProgress = await contextEngine.getTaskProgress()
            self.isClockedIn = await contextEngine.isWorkerClockedIn()
            self.currentBuilding = await contextEngine.getCurrentBuilding()
            
            print("✅ Worker dashboard data loaded: \(assignedBuildings.count) buildings, \(todaysTasks.count) tasks")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load worker dashboard: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        do {
            try await contextEngine.refreshData()
            
            // Update UI state from Actor
            self.assignedBuildings = await contextEngine.getAssignedBuildings()
            self.todaysTasks = await contextEngine.getTodaysTasks()
            self.taskProgress = await contextEngine.getTaskProgress()
            self.isClockedIn = await contextEngine.isWorkerClockedIn()
            self.currentBuilding = await contextEngine.getCurrentBuilding()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Task Management (FIXED Method Signatures)
    
    func completeTask(_ task: ContextualTask) async {
        guard let user = await authManager.getCurrentUser() else { return }
        
        do {
            // ✅ FIXED: Correct ActionEvidence initializer from DTOs/ActionEvidence.swift
            let evidence = ActionEvidence(
                description: "Task completed via dashboard: \(task.title)",
                photoURLs: [], // Correct parameter name
                timestamp: Date()
            )
            
            // ✅ FIXED: Safe unwrapping of optional buildingId
            let buildingId = task.buildingId ?? "unknown"
            
            // ✅ FIXED: user.workerId is non-optional String from CoreTypes.User
            try await contextEngine.recordTaskCompletion(
                workerId: user.workerId,
                buildingId: buildingId,
                taskId: task.id,
                evidence: evidence
            )
            
            // Invalidate metrics cache for this building to trigger real-time updates
            await metricsService.invalidateCache(for: buildingId)
            
            // Refresh local data to reflect completion
            await refreshData()
            
            print("✅ Task completed: \(task.title)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to complete task: \(error)")
        }
    }
    
    // MARK: - Clock In/Out Management
    
    func clockIn(at building: NamedCoordinate) async {
        do {
            try await contextEngine.clockIn(at: building)
            self.isClockedIn = true
            self.currentBuilding = building
            
            // Invalidate metrics for the building to reflect worker presence
            await metricsService.invalidateCache(for: building.id)
            
            print("✅ Clocked in at: \(building.name)")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to clock in: \(error)")
        }
    }
    
    func clockOut() async {
        guard let building = currentBuilding else { return }
        
        do {
            try await contextEngine.clockOut()
            self.isClockedIn = false
            self.currentBuilding = nil
            
            // Invalidate metrics for the building to reflect worker departure
            await metricsService.invalidateCache(for: building.id)
            
            print("✅ Clocked out")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to clock out: \(error)")
        }
    }
    
    // MARK: - Real-Time Metrics Integration
    
    func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { ($0.buildingId ?? "") == buildingId }
    }
    
    func getCompletionRateForBuilding(_ buildingId: String) -> Double {
        let buildingTasks = getTasksForBuilding(buildingId)
        guard !buildingTasks.isEmpty else { return 0.0 }
        
        let completedTasks = buildingTasks.filter { $0.isCompleted }
        return Double(completedTasks.count) / Double(buildingTasks.count)
    }
    
    func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { $0.urgency == .high || $0.urgency == .critical }.count
    }
    
    func getTotalTasksToday() -> Int {
        return todaysTasks.count
    }
    
    func getCompletedTasksToday() -> Int {
        return todaysTasks.filter { $0.isCompleted }.count
    }
    
    // MARK: - Auto-Refresh for Real-Time Updates
    
    private func setupAutoRefresh() {
        // Refresh every 30 seconds to maintain real-time data
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.refreshData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Worker Profile Information
    
    func getCurrentWorkerName() async -> String {
        let worker = await contextEngine.getCurrentWorker()
        return worker?.name ?? "Unknown Worker"
    }
    
    func getCurrentWorkerRole() async -> String {
        let worker = await contextEngine.getCurrentWorker()
        return worker?.role.rawValue ?? "worker"
    }
    
    // MARK: - Building-Specific Operations
    
    func requestTask(for buildingId: String, taskType: String) async {
        // Implementation for requesting new tasks
        print("📝 Task requested for building \(buildingId): \(taskType)")
        // This would integrate with TaskService to create new tasks
    }
    
    func reportIssue(for buildingId: String, description: String) async {
        do {
            let evidence = ActionEvidence(
                description: "Issue reported: \(description)",
                photoURLs: [],
                timestamp: Date()
            )
            
            // Log the issue - could be expanded to create maintenance tasks
            print("⚠️ Issue reported for building \(buildingId): \(description)")
            
            // Invalidate metrics to reflect potential building status change
            await metricsService.invalidateCache(for: buildingId)
            
        } catch {
            errorMessage = "Failed to report issue: \(error.localizedDescription)"
        }
    }
}

// MARK: - Phase 2 Enhancements

extension WorkerDashboardViewModel {
    
    /// Get building-specific metrics for real-time dashboard updates
    func getBuildingMetrics(for buildingId: String) async -> CoreTypes.BuildingMetrics? {
        do {
            return try await metricsService.calculateMetrics(for: buildingId)
        } catch {
            print("❌ Failed to get building metrics: \(error)")
            return nil
        }
    }
    
    /// Check if worker has permissions for specific building operations
    func canPerformOperation(_ operation: String, on buildingId: String) async -> Bool {
        let worker = await contextEngine.getCurrentWorker()
        let building = assignedBuildings.first { $0.id == buildingId }
        
        // Basic permission check - could be expanded with role-based permissions
        return worker != nil && building != nil
    }
    
    /// Get next scheduled task for worker planning
    func getNextScheduledTask() async -> ContextualTask? {
        return await contextEngine.getNextScheduledTask()
    }
}
