//
//  WorkerDashboardViewModel.swift
//  FrancoSphere v6.0 - PROGRESS CALCULATION FIXED
//
//  ✅ FIXED: Progress calculation to show real numbers
//  ✅ ADDED: Explicit task progress calculation
//  ✅ ENHANCED: Real-time progress updates
//

import SwiftUI
import Combine

@MainActor
class WorkerDashboardViewModel: ObservableObject {
    @Published var assignedBuildings: [NamedCoordinate] = []
    @Published var todaysTasks: [ContextualTask] = []
    @Published var taskProgress: TaskProgress?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isClockedIn = false
    @Published var currentBuilding: NamedCoordinate?
    
    private let authManager = NewAuthManager.shared
    private let contextEngine = WorkerContextEngine.shared
    private let metricsService = BuildingMetricsService.shared
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAutoRefresh()
    }

    // MARK: - Data Loading with Progress Fix
    
    func loadInitialData() async {
        guard let user = await authManager.getCurrentUser() else {
            errorMessage = "Not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load context using Actor pattern
            try await contextEngine.loadContext(for: user.workerId)
            
            // Update UI state from Actor
            self.assignedBuildings = await contextEngine.getAssignedBuildings()
            self.todaysTasks = await contextEngine.getTodaysTasks()
            self.isClockedIn = await contextEngine.isWorkerClockedIn()
            self.currentBuilding = await contextEngine.getCurrentBuilding()
            
            // FIXED: Explicit task progress calculation
            await calculateTaskProgress()
            
            print("✅ Worker dashboard data loaded: \(assignedBuildings.count) buildings, \(todaysTasks.count) tasks")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load worker dashboard: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Progress Calculation Fix
    
    private func calculateTaskProgress() async {
        let totalTasks = todaysTasks.count
        let completedTasks = todaysTasks.filter { $0.isCompleted }.count
        
        let completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        self.taskProgress = TaskProgress(
            totalTasks: totalTasks,
            completedTasks: completedTasks,
            completionRate: completionRate
        )
        
        print("✅ Progress calculated: \(completedTasks)/\(totalTasks) tasks (\(Int(completionRate * 100))%)")
    }
    
    func refreshData() async {
        do {
            try await contextEngine.refreshData()
            
            // Update UI state from Actor
            self.assignedBuildings = await contextEngine.getAssignedBuildings()
            self.todaysTasks = await contextEngine.getTodaysTasks()
            self.isClockedIn = await contextEngine.isWorkerClockedIn()
            self.currentBuilding = await contextEngine.getCurrentBuilding()
            
            // Recalculate progress
            await calculateTaskProgress()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Task Management
    
    func completeTask(_ task: ContextualTask) async {
        guard let user = await authManager.getCurrentUser() else { return }
        
        do {
            let evidence = ActionEvidence(
                description: "Task completed via dashboard: \(task.title ?? "Unknown")",
                photoURLs: [],
                timestamp: Date()
            )
            
            let buildingId = task.buildingId ?? "unknown"
            
            try await contextEngine.recordTaskCompletion(
                workerId: user.workerId,
                buildingId: buildingId,
                taskId: task.id,
                evidence: evidence
            )
            
            // Refresh data to get updated progress
            await refreshData()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clockIn(at building: NamedCoordinate) async {
        do {
            try await contextEngine.clockIn(at: building)
            
            // Update state
            self.isClockedIn = true
            self.currentBuilding = building
            
            print("✅ Clocked in at \(building.name)")
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clockOut() async {
        do {
            try await contextEngine.clockOut()
            
            // Update state
            self.isClockedIn = false
            self.currentBuilding = nil
            
            print("✅ Clocked out")
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Auto-refresh Setup
    
    private func setupAutoRefresh() {
        // Refresh every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - TaskProgress Model Enhancement

extension TaskProgress {
    init(totalTasks: Int, completedTasks: Int, completionRate: Double) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.completionRate = completionRate
    }
}
