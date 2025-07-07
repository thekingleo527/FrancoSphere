//
//  WorkerDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: View model for the main worker dashboard.
//  ✅ Handles all logic for fetching data and interacting with services/actors.
//  ✅ Decouples the view from the business logic.
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
    
    // Clock-In State
    @Published var isClockedIn = false
    @Published var currentSession: ClockInManager.ClockInSession?
    
    // Services (Actors)
    private let authManager = NewAuthManager.shared
    private let clockInManager = ClockInManager.shared
    private let contextEngine = WorkerContextEngine.shared
    
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Listen for notifications from our actors
        setupNotificationListeners()
    }

    func loadInitialData() async {
        guard let workerId = await authManager.currentUser?.workerId else {
            errorMessage = "Critical error: Could not identify current worker."
            isLoading = false
            return
        }
        
        isLoading = true
        
        // Fetch initial clock-in status
        let status = await clockInManager.getClockInStatus(for: workerId)
        self.isClockedIn = status.isClockedIn
        self.currentSession = status.session
        
        // Load the rest of the context
        await contextEngine.loadContext(for: workerId)
        
        // Update published properties from the context engine
        self.assignedBuildings = contextEngine.assignedBuildings
        self.todaysTasks = contextEngine.todaysTasks
        self.taskProgress = contextEngine.taskProgress
        
        if let error = contextEngine.error {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func handleClockInToggle() async {
        guard let workerId = await authManager.currentUser?.workerId else { return }

        if isClockedIn {
            await handleClockOut(workerId: workerId)
        } else {
            // In a real app, this would trigger a sheet to select a building.
            // We will add this logic back into the view.
            print("Clock-in action initiated, view should present building selection.")
        }
    }
    
    func handleClockIn(for building: NamedCoordinate) async {
        guard let workerId = await authManager.currentUser?.workerId else { return }
        do {
            try await clockInManager.clockIn(workerId: workerId, building: building)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleClockOut(workerId: CoreTypes.WorkerID) async {
        do {
            try await clockInManager.clockOut(workerId: workerId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func setupNotificationListeners() {
        NotificationCenter.default.publisher(for: .workerClockInChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                Task { [weak self] in
                    await self?.updateClockInState(from: notification)
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateClockInState(from notification: Notification) async {
        guard let userInfo = notification.userInfo,
              let workerId = userInfo["workerId"] as? CoreTypes.WorkerID,
              let authWorkerId = await authManager.currentUser?.workerId,
              authWorkerId == workerId else { return }

        self.isClockedIn = userInfo["isClockedIn"] as? Bool ?? false
        if self.isClockedIn {
             self.currentSession = .init(
                workerId: workerId,
                buildingId: userInfo["buildingId"] as? String ?? "",
                buildingName: userInfo["buildingName"] as? String ?? "Unknown",
                startTime: Date(),
                location: nil)
        } else {
            self.currentSession = nil
        }
    }
}
