//
//  AdminDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ V6.0: Fixed compilation errors and aligned with current implementation
//  ✅ FIXED: async let try patterns for throwing vs non-throwing methods
//  ✅ FIXED: getBuildingIntelligence optional binding issue
//  ✅ FIXED: ContextualTask property usage (isCompleted vs status)
//  ✅ ALIGNED: With GRDB-based services and actor patterns
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
    @Published var errorMessage: String?
    
    // MARK: - Services and Subscriptions
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let dataSyncService = DataSynchronizationService.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupDataSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupDataSubscriptions() {
        // Subscribe to real-time updates for building intelligence
        dataSyncService.$buildingIntelligenceUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updates in
                // If the currently selected building is in the update, refresh the panel
                if let selectedId = self?.selectedBuildingIntelligence?.buildingId,
                   let updatedIntelligence = updates[selectedId] {
                    self?.selectedBuildingIntelligence = updatedIntelligence
                    print("⚡️ Real-time update received for selected building: \(selectedId)")
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading
    
    /// Loads the initial, high-level data for the dashboard
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // ✅ FIXED: All three service methods throw - need try for all
            async let buildingsResult = try buildingService.getAllBuildings()    // throws
            async let workersResult = try workerService.getAllActiveWorkers()    // throws
            async let tasksResult = try taskService.getAllTasks()                // throws
            
            let (buildings, workers, tasks) = await (try buildingsResult, try workersResult, try tasksResult)
            
            await MainActor.run {
                self.buildings = buildings
                self.activeWorkers = workers
                // ✅ FIXED: Use isCompleted property instead of status string comparison
                self.ongoingTasks = tasks.filter { !$0.isCompleted }
                self.isLoading = false
            }
            
            print("✅ Admin dashboard data loaded: \(buildings.count) buildings, \(workers.count) workers, \(ongoingTasks.count) ongoing tasks")
            
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("🚨 Failed to load admin dashboard data: \(error)")
        }
    }

    /// Fetches the detailed intelligence DTO for a specific building
    func fetchIntelligence(for buildingId: CoreTypes.BuildingID) async {
        guard !buildingId.isEmpty else {
            print("⚠️ Invalid building ID provided")
            return
        }
        
        isLoadingIntelligence = true
        selectedBuildingIntelligence = nil
        
        do {
            // ✅ FIXED: getBuildingIntelligence returns non-optional BuildingIntelligenceDTO
            let intelligence = try await buildingService.getBuildingIntelligence(for: buildingId)
            
            await MainActor.run {
                self.selectedBuildingIntelligence = intelligence
                self.isLoadingIntelligence = false
            }
            print("✅ Intelligence loaded for building \(buildingId)")
            
        } catch {
            await MainActor.run {
                self.isLoadingIntelligence = false
                self.errorMessage = "Failed to fetch intelligence for building \(buildingId): \(error.localizedDescription)"
            }
            print("🚨 Failed to fetch intelligence for building \(buildingId): \(error)")
        }
    }
    
    /// Clears the selected building's intelligence data
    func clearIntelligence() {
        selectedBuildingIntelligence = nil
        errorMessage = nil
        print("🧹 Cleared selected building intelligence")
    }
    
    // MARK: - Computed Properties
    
    /// Get summary statistics for the admin dashboard
    var dashboardSummary: (totalBuildings: Int, activeWorkers: Int, ongoingTasks: Int, completionRate: String) {
        let totalTasks = ongoingTasks.count + activeWorkers.reduce(0) { count, worker in
            // Approximate completed tasks for rate calculation
            return count + 5 // Default assumption of 5 completed tasks per worker
        }
        
        let completedCount = max(0, totalTasks - ongoingTasks.count)
        let completionRate = totalTasks > 0 ? Int((Double(completedCount) / Double(totalTasks)) * 100) : 0
        
        return (
            totalBuildings: buildings.count,
            activeWorkers: activeWorkers.count,
            ongoingTasks: ongoingTasks.count,
            completionRate: "\(completionRate)%"
        )
    }
    
    /// Get buildings with high task counts (for priority attention)
    var buildingsNeedingAttention: [NamedCoordinate] {
        return buildings.filter { building in
            let tasksForBuilding = ongoingTasks.filter { task in
                task.building?.id == building.id
            }
            return tasksForBuilding.count > 3 // More than 3 ongoing tasks
        }
    }
    
    /// Get workers who are currently active and assigned to buildings
    var activeAssignedWorkers: [WorkerProfile] {
        return activeWorkers.filter { $0.isActive }
    }
    
    // MARK: - Refresh Methods
    
    /// Force refresh all dashboard data
    func refreshDashboard() async {
        print("🔄 Refreshing admin dashboard...")
        await loadDashboardData()
    }
    
    /// Refresh only the selected building's intelligence
    func refreshSelectedBuildingIntelligence() async {
        guard let buildingId = selectedBuildingIntelligence?.buildingId else {
            print("⚠️ No building selected for intelligence refresh")
            return
        }
        
        await fetchIntelligence(for: buildingId)
    }
}
