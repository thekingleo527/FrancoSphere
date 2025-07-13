//
import CoreLocation
//  WorkerDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ ACTOR-COMPATIBLE: Updated for WorkerContextEngine Actor
//  ✅ Async/await patterns for all actor interactions
//  ✅ Real-time metrics integration
//

import Foundation
import Combine
import SwiftUI

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
    
    // MARK: - Actor Dependencies
    private let authManager = NewAuthManager.shared
    private let contextEngine = WorkerContextEngine.shared
    private let metricsService = BuildingMetricsService.shared
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupAutoRefresh()
    }

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
            try await contextEngine.loadContext(for: user.workerId)
            
            // Update UI state from Actor
            self.assignedBuildings = await contextEngine.getAssignedBuildings()
            self.todaysTasks = await contextEngine.getTodaysTasks()
            self.taskProgress = await contextEngine.getTaskProgress()
            self.isClockedIn = await contextEngine.isWorkerClockedIn()
            self.currentBuilding = await contextEngine.getCurrentBuilding()
            
            print("✅ Worker dashboard data loaded: \(assignedBuildings.count) buildings")
            
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load worker dashboard: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshData() async {
        do {
            try await contextEngine.refreshData()
            
            // Update UI state
            self.assignedBuildings = await contextEngine.getAssignedBuildings()
            self.todaysTasks = await contextEngine.getTodaysTasks()
            self.taskProgress = await contextEngine.getTaskProgress()
            self.isClockedIn = await contextEngine.isWorkerClockedIn()
            self.currentBuilding = await contextEngine.getCurrentBuilding()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func completeTask(_ task: ContextualTask) async {
        guard let user = await authManager.getCurrentUser() else { return }
        
        do {
            let evidence = ActionEvidence(
                taskId: task.id,
                timestamp: Date(),
                location: CLLocation(latitude: 0, longitude: 0),
                photos: [],
                notes: "Task completed via dashboard"
            )
            
            try await contextEngine.recordTaskCompletion(
                workerId: user.workerId,
                buildingId: task.id,
                taskId: task.id,
                evidence: evidence
            )
            
            // Invalidate metrics cache for this building
            await metricsService.invalidateCache(for: task.id)
            
            // Refresh local data
            await refreshData()
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clockIn(at building: NamedCoordinate) async {
        do {
            try await contextEngine.clockIn(at: building)
            self.isClockedIn = true
            self.currentBuilding = building
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clockOut() async {
        do {
            try await contextEngine.clockOut()
            self.isClockedIn = false
            self.currentBuilding = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func setupAutoRefresh() {
        // Refresh every 30 seconds
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.refreshData()
                }
            }
            .store(in: &cancellables)
    }
}
