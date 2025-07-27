//
//  WorkerDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Task initializer syntax corrected
//  ✅ FIXED: Timer syntax corrected
//  ✅ FIXED: ContextualTask parameter corrected
//  ✅ FIXED: DashboardUpdate creation pattern
//  ✅ FIXED: UpdateType references removed
//

import Foundation
import SwiftUI
import Combine

@MainActor
public class WorkerDashboardViewModel: ObservableObject {
    
    // MARK: - Published State Properties
    @Published public var assignedBuildings: [NamedCoordinate] = []
    @Published public var todaysTasks: [ContextualTask] = []
    @Published public var taskProgress: CoreTypes.TaskProgress?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isClockedIn = false
    @Published public var currentBuilding: NamedCoordinate?
    @Published public var workerProfile: WorkerProfile?
    
    // MARK: - Dashboard Integration State
    @Published public var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published public var recentUpdates: [DashboardUpdate] = []
    @Published public var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published public var portfolioBuildings: [NamedCoordinate] = []
    
    // MARK: - Performance Metrics
    @Published public var completionRate: Double = 0.0
    @Published public var todaysEfficiency: Double = 0.0
    @Published public var weeklyPerformance: CoreTypes.TrendDirection = .stable
    
    // MARK: - Service Dependencies
    private let authManager = NewAuthManager.shared
    private let contextEngine = WorkerContextEngine.shared
    private let clockInManager = ClockInManager.shared
    private let metricsService = BuildingMetricsService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    
    // MARK: - Private State
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Foundation.Timer?
    private var currentWorkerId: String?
    
    // MARK: - Initialization
    
    public init() {
        setupDashboardSyncSubscriptions()
        setupAutoRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Primary Data Loading
    
    /// Load all initial data for worker dashboard
    public func loadInitialData() async {
        await setLoadingState(true)
        
        guard let user = await authManager.getCurrentUser() else {
            await setError("Authentication required")
            return
        }
        
        currentWorkerId = user.workerId
        
        do {
            // Load worker profile first
            await loadWorkerProfile(workerId: user.workerId)
            
            // Use specific method to avoid ambiguity
            try await contextEngine.loadContextWithOperationalData(for: user.workerId as CoreTypes.WorkerID)
            
            // Update UI state from WorkerContextEngine
            assignedBuildings = contextEngine.assignedBuildings
            todaysTasks = contextEngine.todaysTasks
            taskProgress = contextEngine.taskProgress
            isClockedIn = contextEngine.clockInStatus.isClockedIn
            currentBuilding = contextEngine.clockInStatus.building
            portfolioBuildings = contextEngine.portfolioBuildings
            
            // Calculate derived metrics
            await calculateDerivedMetrics()
            await loadBuildingMetricsData()
            
            // Broadcast dashboard activation with DashboardUpdate
            let update = DashboardUpdate(
                source: .worker,
                type: .taskStarted,
                buildingId: nil,
                workerId: user.workerId,
                data: [
                    "workerId": user.workerId,
                    "buildingCount": String(assignedBuildings.count),
                    "taskCount": String(todaysTasks.count)
                ]
            )
            await broadcastWorkerDashboardUpdate(update)
            
            await setLoadingState(false)
            print("✅ Worker dashboard loaded: \(assignedBuildings.count) buildings, \(todaysTasks.count) tasks")
            
        } catch {
            await setError("Failed to load dashboard: \(error.localizedDescription)")
            print("❌ Worker dashboard load failed: \(error)")
        }
    }
    
    // MARK: - Task Management
    
    /// Complete a task with evidence and cross-dashboard sync
    public func completeTask(_ task: ContextualTask, evidence: ActionEvidence? = nil) async {
        guard let workerId = currentWorkerId else { return }
        
        // Create evidence if not provided
        let taskEvidence = evidence ?? ActionEvidence(
            description: "Task completed via Worker Dashboard: \(task.title)",
            photoURLs: [],
            timestamp: Date()
        )
        
        // Update local state first
        if let taskIndex = todaysTasks.firstIndex(where: { $0.id == task.id }) {
            todaysTasks[taskIndex].isCompleted = true
        }
        
        // Recalculate progress
        await calculateDerivedMetrics()
        
        // Update building metrics
        if let buildingId = task.buildingId {
            await updateBuildingMetrics(buildingId: buildingId)
        }
        
        // Broadcast to other dashboards using DashboardUpdate directly
        let completionUpdate = DashboardUpdate(
            source: .worker,
            type: .taskCompleted,
            buildingId: task.buildingId,
            workerId: workerId,
            data: [
                "taskId": task.id,
                "completionTime": Date(),
                "evidence": taskEvidence.description,
                "photoCount": taskEvidence.photoURLs.count
            ]
        )
        dashboardSyncService.broadcastWorkerUpdate(completionUpdate)
        
        print("✅ Task completed: \(task.title)")
    }
    
    /// Start a task with location tracking
    public func startTask(_ task: ContextualTask) async {
        guard let workerId = currentWorkerId else { return }
        
        // Update local state
        if let taskIndex = todaysTasks.firstIndex(where: { $0.id == task.id }) {
            print("✅ Task started: \(task.title)")
        }
        
        // Create and broadcast update
        let update = DashboardUpdate(
            source: .worker,
            type: .taskStarted,
            buildingId: task.buildingId,
            workerId: workerId,
            data: [
                "taskId": task.id,
                "taskTitle": task.title,
                "startedAt": ISO8601DateFormatter().string(from: Date()),
                "workerId": workerId
            ]
        )
        await broadcastWorkerDashboardUpdate(update)
    }
    
    // MARK: - Clock In/Out Management
    
    /// Clock in at a building with cross-dashboard notification
    public func clockIn(at building: NamedCoordinate) async {
        guard let workerId = currentWorkerId else { return }
        
        do {
            // Use ClockInManager with correct method signature
            try await clockInManager.clockIn(
                workerId: workerId,
                building: building,
                location: nil
            )
            
            // Update local state
            isClockedIn = true
            currentBuilding = building
            
            // Refresh tasks for this building
            await loadTodaysTasks(workerId: workerId, buildingId: building.id)
            
            // Broadcast using DashboardUpdate directly
            let clockInUpdate = DashboardUpdate(
                source: .worker,
                type: .workerClockedIn,
                buildingId: building.id,
                workerId: workerId,
                data: [
                    "buildingName": building.name,
                    "clockInTime": Date()
                ]
            )
            dashboardSyncService.broadcastWorkerUpdate(clockInUpdate)
            
            print("✅ Clocked in at \(building.name)")
            
        } catch {
            await setError("Failed to clock in: \(error.localizedDescription)")
            print("❌ Clock-in failed: \(error)")
        }
    }
    
    /// Clock out with automatic task summary
    public func clockOut() async {
        guard let workerId = currentWorkerId,
              let building = currentBuilding else { return }
        
        do {
            // Calculate session summary
            let completedTasks = todaysTasks.filter { $0.isCompleted && $0.buildingId == building.id }
            
            // Use ClockInManager for clock-out
            try await clockInManager.clockOut(workerId: workerId)
            
            // Update local state
            isClockedIn = false
            currentBuilding = nil
            
            // Broadcast session summary using DashboardUpdate directly
            let clockOutUpdate = DashboardUpdate(
                source: .worker,
                type: .workerClockedOut,
                buildingId: building.id,
                workerId: workerId,
                data: [
                    "buildingName": building.name,
                    "completedTaskCount": completedTasks.count,
                    "clockOutTime": Date()
                ]
            )
            dashboardSyncService.broadcastWorkerUpdate(clockOutUpdate)
            
            print("✅ Clocked out from \(building.name) - \(completedTasks.count) tasks completed")
            
        } catch {
            await setError("Failed to clock out: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Refresh
    
    /// Refresh all dashboard data
    public func refreshData() async {
        guard let workerId = currentWorkerId else { return }
        
        do {
            // Use specific method to avoid ambiguity
            try await contextEngine.loadContextWithOperationalData(for: workerId as CoreTypes.WorkerID)
            
            // Update UI state from WorkerContextEngine
            assignedBuildings = contextEngine.assignedBuildings
            todaysTasks = contextEngine.todaysTasks
            taskProgress = contextEngine.taskProgress
            isClockedIn = contextEngine.clockInStatus.isClockedIn
            currentBuilding = contextEngine.clockInStatus.building
            
            // Recalculate derived metrics
            await calculateDerivedMetrics()
            await loadBuildingMetricsData()
            
            dashboardSyncStatus = .synced
            print("✅ Worker dashboard data refreshed")
            
        } catch {
            dashboardSyncStatus = .failed
            await setError("Failed to refresh data: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadWorkerProfile(workerId: String) async {
        do {
            workerProfile = try await workerService.getWorkerProfile(for: workerId)
        } catch {
            print("⚠️ Failed to load worker profile: \(error)")
        }
    }
    
    private func loadTodaysTasks(workerId: String, buildingId: String? = nil) async {
        // Use actual available method from contextEngine
        todaysTasks = contextEngine.todaysTasks
        
        if let buildingId = buildingId {
            // Filter tasks for specific building if needed
            todaysTasks = contextEngine.todaysTasks.filter { $0.buildingId == buildingId }
        }
        
        print("✅ Loaded \(todaysTasks.count) tasks for today")
    }
    
    // Renamed method to avoid duplicate declaration
    private func loadBuildingMetricsData() async {
        await refreshBuildingMetricsForAllBuildings()
    }
    
    private func refreshBuildingMetricsForAllBuildings() async {
        for building in assignedBuildings {
            do {
                let metrics = try await metricsService.calculateMetrics(for: building.id)
                buildingMetrics[building.id] = metrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
    }
    
    private func refreshSingleBuildingMetrics(buildingId: String) async {
        do {
            let metrics = try await metricsService.calculateMetrics(for: buildingId)
            buildingMetrics[buildingId] = metrics
        } catch {
            print("⚠️ Failed to refresh metrics for building \(buildingId): \(error)")
        }
    }
    
    private func calculateDerivedMetrics() async {
        let totalTasks = todaysTasks.count
        let completedTasks = todaysTasks.filter { $0.isCompleted }.count
        
        // Use correct TaskProgress constructor
        taskProgress = CoreTypes.TaskProgress(
            totalTasks: totalTasks,
            completedTasks: completedTasks
        )
        
        completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        
        // Calculate efficiency based on time vs. standard
        todaysEfficiency = calculateDailyEfficiency()
        
        print("✅ Progress calculated: \(completedTasks)/\(totalTasks) = \(Int(completionRate * 100))%")
    }
    
    private func calculateDailyEfficiency() -> Double {
        let completedTasks = todaysTasks.filter { $0.isCompleted }
        guard !completedTasks.isEmpty else { return 0.0 }
        
        // Simple efficiency calculation based on completion ratio
        return min(1.0, completionRate * 1.2) // Boost for early completion
    }
    
    private func updateBuildingMetrics(buildingId: String) async {
        do {
            let metrics = try await metricsService.calculateMetrics(for: buildingId)
            buildingMetrics[buildingId] = metrics
            
            // Broadcast metrics update using DashboardUpdate directly
            let metricsUpdate = DashboardUpdate(
                source: .worker,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: currentWorkerId,
                data: [
                    "buildingId": buildingId,
                    "completionRate": metrics.completionRate,
                    "overdueTasks": metrics.overdueTasks
                ]
            )
            dashboardSyncService.broadcastWorkerUpdate(metricsUpdate)
        } catch {
            print("⚠️ Failed to update building metrics: \(error)")
        }
    }
    
    private func setLoadingState(_ loading: Bool) async {
        isLoading = loading
        if !loading {
            errorMessage = nil
        }
    }
    
    private func setError(_ message: String) async {
        errorMessage = message
        isLoading = false
        dashboardSyncStatus = .failed
    }
    
    // MARK: - Dashboard Sync Integration
    
    private func setupDashboardSyncSubscriptions() {
        // Subscribe to cross-dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleCrossDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to admin dashboard updates
        dashboardSyncService.adminDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleAdminDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to client dashboard updates
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleClientDashboardUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func handleCrossDashboardUpdate(_ update: DashboardUpdate) {
        recentUpdates.append(update)
        
        // Keep only recent updates (last 20)
        if recentUpdates.count > 20 {
            recentUpdates = Array(recentUpdates.suffix(20))
        }
        
        // Handle specific update types
        switch update.type {
        case .performanceChanged:
            if update.workerId == currentWorkerId {
                Task { @MainActor in
                    await refreshData()
                }
            }
        case .portfolioUpdated:
            Task { @MainActor in
                await refreshBuildingMetricsForAllBuildings()
            }
        default:
            break
        }
    }
    
    private func handleAdminDashboardUpdate(_ update: DashboardUpdate) {
        switch update.type {
        case .buildingMetricsChanged:
            if let buildingId = update.buildingId,
               assignedBuildings.contains(where: { $0.id == buildingId }) {
                Task { @MainActor in
                    await refreshSingleBuildingMetrics(buildingId: buildingId)
                }
            }
        default:
            break
        }
    }
    
    private func handleClientDashboardUpdate(_ update: DashboardUpdate) {
        switch update.type {
        case .complianceChanged:
            // Refresh all data to get updated compliance requirements
            if let buildingId = update.buildingId,
               assignedBuildings.contains(where: { $0.id == buildingId }) {
                Task { @MainActor in
                    await refreshData()
                }
            }
        default:
            break
        }
    }
    
    /// Broadcast a worker dashboard update using DashboardUpdate directly
    private func broadcastWorkerDashboardUpdate(_ update: DashboardUpdate) async {
        dashboardSyncService.broadcastWorkerUpdate(update)
    }
    
    // MARK: - Auto-refresh Setup
    
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isLoading else { return }
            
            Task { @MainActor in
                await self.refreshData()
            }
        }
    }
}

// MARK: - Supporting Types

public enum BuildingAccessType {
    case assigned
    case coverage
    case unknown
}

// MARK: - Supporting Extensions

extension WorkerDashboardViewModel {
    
    /// Get building access type for UI display
    public func getBuildingAccessType(for buildingId: String) -> BuildingAccessType {
        if assignedBuildings.contains(where: { $0.id == buildingId }) {
            return .assigned
        } else if portfolioBuildings.contains(where: { $0.id == buildingId }) {
            return .coverage
        } else {
            return .unknown
        }
    }
    
    /// Get tasks for a specific building
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    /// Get completion rate for a specific building
    public func getBuildingCompletionRate(_ buildingId: String) -> Double {
        let buildingTasks = getTasksForBuilding(buildingId)
        guard !buildingTasks.isEmpty else { return 0.0 }
        
        let completed = buildingTasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(buildingTasks.count)
    }
    
    /// Check if worker can access building
    public func canAccessBuilding(_ buildingId: String) -> Bool {
        return getBuildingAccessType(for: buildingId) != .unknown
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension WorkerDashboardViewModel {
    static func preview() -> WorkerDashboardViewModel {
        let viewModel = WorkerDashboardViewModel()
        
        // Mock data for previews
        viewModel.assignedBuildings = [
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7397,
                longitude: -73.9978,
                imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
            )
        ]
        
        // Create building for task
        let rubinMuseum = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St, New York, NY 10011",
            latitude: 40.7397,
            longitude: -73.9978,
            imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
        )
        
        // Use correct ContextualTask constructor
        viewModel.todaysTasks = [
            ContextualTask(
                id: "task1",
                title: "HVAC Inspection",
                description: "Check HVAC system in main gallery",
                isCompleted: false,
                completedDate: nil,
                dueDate: Date().addingTimeInterval(3600),
                category: .maintenance,
                urgency: .high,
                building: rubinMuseum,
                worker: nil,
                buildingId: "14",
                priority: .high
            )
        ]
        
        viewModel.taskProgress = CoreTypes.TaskProgress(
            totalTasks: 5,
            completedTasks: 2
        )
        
        return viewModel
    }
}
#endif
