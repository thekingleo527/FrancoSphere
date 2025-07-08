//
//  AdminDashboardViewModel.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  AdminDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 4.1 - ViewModel for the Real-Time Admin Dashboard.
//  ✅ Fetches and manages building intelligence data.
//  ✅ Subscribes to real-time updates from DataSynchronizationService.
//

import Foundation
import Combine

@MainActor
class AdminDashboardViewModel: ObservableObject {
    // MARK: - Published Properties for UI
    @Published var buildings: [NamedCoordinate] = []
    @Published var activeWorkers: [WorkerProfile] = []
    @Published var ongoingTasks: [ContextualTask] = []
    
    @Published var selectedBuildingIntelligence: BuildingIntelligenceDTO?
    @Published var isLoading = false
    @Published var isLoadingIntelligence = false
    
    // MARK: - Services and Subscriptions
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let dataSyncService = DataSynchronizationService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to real-time updates for building intelligence.
        dataSyncService.$buildingIntelligenceUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updates in
                // If the currently selected building is in the update, refresh the panel.
                if let selectedId = self?.selectedBuildingIntelligence?.buildingId,
                   let updatedIntelligence = updates[selectedId] {
                    self?.selectedBuildingIntelligence = updatedIntelligence
                    print("⚡️ Real-time update received for selected building: \(selectedId)")
                }
            }
            .store(in: &cancellables)
    }

    /// Loads the initial, high-level data for the dashboard.
    func loadDashboardData() async {
        isLoading = true
        
        async let buildings = buildingService.getAllBuildings()
        async let workers = workerService.getAllActiveWorkers()
        async let tasks = taskService.getAllTasks()
        
        do {
            self.buildings = try await buildings
            self.activeWorkers = try await workers
            self.ongoingTasks = (try await tasks).filter { $0.status != "completed" }
        } catch {
            print("🚨 Failed to load admin dashboard data: \(error)")
        }
        
        isLoading = false
    }

    /// Fetches the detailed intelligence DTO for a specific building.
    func fetchIntelligence(for buildingId: CoreTypes.BuildingID) async {
        isLoadingIntelligence = true
        selectedBuildingIntelligence = nil
        
        do {
            // This now calls the new intelligence aggregation method.
            selectedBuildingIntelligence = try await buildingService.getBuildingIntelligence(for: buildingId)
        } catch {
            print("🚨 Failed to fetch intelligence for building \(buildingId): \(error)")
        }
        
        isLoadingIntelligence = false
    }
    
    /// Clears the selected building's intelligence data.
    func clearIntelligence() {
        selectedBuildingIntelligence = nil
    }
}
