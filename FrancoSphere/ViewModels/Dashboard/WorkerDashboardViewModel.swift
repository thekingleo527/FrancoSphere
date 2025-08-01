//
//  WorkerDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  Comprehensive worker dashboard view model with real-time sync,
//  location tracking, and capability-based UI adaptation.
//
//  Features:
//  - Real-time cross-dashboard synchronization
//  - Location-based clock in/out
//  - Worker capability management from database
//  - Weather integration for outdoor work safety
//  - Spanish localization support
//  - Automatic data refresh
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

// MARK: - Supporting Types

public enum BuildingAccessType {
    case assigned
    case coverage
    case unknown
}

// MARK: - WorkerDashboardViewModel

@MainActor
public class WorkerDashboardViewModel: ObservableObject {
    
    // MARK: - Nested Types
    
    public struct WorkerCapabilities {
        let canUploadPhotos: Bool
        let canAddNotes: Bool
        let canViewMap: Bool
        let canAddEmergencyTasks: Bool
        let requiresPhotoForSanitation: Bool
        let simplifiedInterface: Bool
        
        static let `default` = WorkerCapabilities(
            canUploadPhotos: true,
            canAddNotes: true,
            canViewMap: true,
            canAddEmergencyTasks: false,
            requiresPhotoForSanitation: true,
            simplifiedInterface: false
        )
    }
    
    // MARK: - Published Properties
    
    // Core State
    @Published public private(set) var isLoading = false
    @Published public private(set) var errorMessage: String?
    @Published public private(set) var workerProfile: CoreTypes.WorkerProfile?
    @Published public private(set) var workerCapabilities: WorkerCapabilities?
    
    // Buildings & Tasks
    @Published public private(set) var assignedBuildings: [CoreTypes.NamedCoordinate] = []
    @Published public private(set) var todaysTasks: [CoreTypes.ContextualTask] = []
    @Published public private(set) var taskProgress: CoreTypes.TaskProgress?
    @Published public private(set) var portfolioBuildings: [CoreTypes.NamedCoordinate] = []
    
    // Clock In/Out State
    @Published public private(set) var isClockedIn = false
    @Published public private(set) var currentBuilding: CoreTypes.NamedCoordinate?
    @Published public private(set) var clockInTime: Date?
    @Published public private(set) var clockInLocation: CLLocation?
    @Published public private(set) var hoursWorkedToday: Double = 0.0
    
    // Weather & Environmental
    @Published public private(set) var weatherData: CoreTypes.WeatherData?
    @Published public private(set) var outdoorWorkRisk: CoreTypes.OutdoorWorkRisk = .low
    
    // Performance Metrics
    @Published public private(set) var completionRate: Double = 0.0
    @Published public private(set) var todaysEfficiency: Double = 0.0
    @Published public private(set) var weeklyPerformance: CoreTypes.TrendDirection = .stable
    
    // Dashboard Sync
    @Published public private(set) var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published public private(set) var recentUpdates: [CoreTypes.DashboardUpdate] = []
    @Published public private(set) var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    
    // MARK: - Private Properties
    
    private var currentWorkerId: String?
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private var weatherUpdateTimer: Timer?
    
    // Location Manager
    @ObservedObject private var locationManager = LocationManager()
    
    // Service Dependencies
    private let authManager = NewAuthManager.shared
    private let contextEngine = WorkerContextEngine.shared
    private let clockInManager = ClockInManager.shared
    private let metricsService = BuildingMetricsService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let weatherService = WeatherDataAdapter.shared
    private let grdbManager = GRDBManager.shared
    
    // MARK: - Initialization
    
    public init() {
        setupSubscriptions()
        setupTimers()
        setupLocationTracking()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Public Methods
    
    /// Load all initial data for the worker dashboard
    public func loadInitialData() async {
        guard let user = authManager.currentUser else {
            await showError(NSLocalizedString("Authentication required", comment: "Auth error"))
            return
        }
        
        await performLoading {
            currentWorkerId = user.workerId
            
            // Load worker profile and capabilities
            await loadWorkerProfile(workerId: user.workerId)
            await loadWorkerCapabilities(workerId: user.workerId)
            
            // Load operational context
            try await contextEngine.loadContext(for: user.workerId)
            await syncStateFromContextEngine()
            
            // Load additional data
            await loadClockInStatus(workerId: user.workerId)
            await calculateMetrics()
            await loadBuildingMetrics()
            
            // Load weather if clocked in
            if let building = currentBuilding {
                await loadWeatherData(for: building)
            }
            
            // Calculate hours worked
            await calculateHoursWorkedToday()
            
            // Broadcast activation
            broadcastWorkerActivation(user: user)
            
            print("✅ Worker dashboard loaded successfully")
        }
    }
    
    /// Refresh all dashboard data
    public func refreshData() async {
        guard let workerId = currentWorkerId else { return }
        
        await performSync {
            // Reload context
            try await contextEngine.loadContext(for: workerId)
            await syncStateFromContextEngine()
            
            // Update clock-in status
            await loadClockInStatus(workerId: workerId)
            
            // Recalculate metrics
            await calculateMetrics()
            await loadBuildingMetrics()
            await calculateHoursWorkedToday()
            
            // Update weather if needed
            if let building = currentBuilding {
                await loadWeatherData(for: building)
            }
            
            print("✅ Dashboard data refreshed")
        }
    }
    
    /// Clock in at a building
    public func clockIn(at building: CoreTypes.NamedCoordinate) async {
        guard let workerId = currentWorkerId else { return }
        
        await performSync {
            // Get current location
            let location = locationManager.location
            let coordinate = location.map {
                CLLocationCoordinate2D(
                    latitude: $0.coordinate.latitude,
                    longitude: $0.coordinate.longitude
                )
            }
            
            // Perform clock in
            try await clockInManager.clockIn(
                workerId: workerId,
                building: building,
                location: coordinate
            )
            
            // Update state
            updateClockInState(
                building: building,
                time: Date(),
                location: location
            )
            
            // Load weather and tasks
            await loadWeatherData(for: building)
            await loadBuildingTasks(workerId: workerId, buildingId: building.id)
            
            // Broadcast update
            broadcastClockIn(workerId: workerId, building: building, hasLocation: location != nil)
            
            print("✅ Clocked in at \(building.name)")
        }
    }
    
    /// Clock out with session summary
    public func clockOut() async {
        guard let workerId = currentWorkerId,
              let building = currentBuilding else { return }
        
        await performSync {
            // Calculate session summary
            let sessionSummary = calculateSessionSummary(building: building)
            
            // Perform clock out
            try await clockInManager.clockOut(workerId: workerId)
            
            // Reset state
            resetClockInState()
            
            // Broadcast summary
            broadcastClockOut(
                workerId: workerId,
                building: building,
                summary: sessionSummary
            )
            
            print("✅ Clocked out from \(building.name)")
        }
    }
    
    /// Complete a task with evidence
    public func completeTask(_ task: CoreTypes.ContextualTask, evidence: CoreTypes.ActionEvidence? = nil) async {
        guard let workerId = currentWorkerId else { return }
        
        await performSync {
            // Create evidence if needed
            let taskEvidence = evidence ?? createDefaultEvidence(for: task)
            
            // Update local state
            updateTaskCompletion(taskId: task.id)
            
            // Recalculate metrics
            await calculateMetrics()
            
            // Update building metrics
            if let buildingId = task.buildingId {
                await updateBuildingMetrics(buildingId: buildingId)
            }
            
            // Broadcast completion
            broadcastTaskCompletion(
                task: task,
                workerId: workerId,
                evidence: taskEvidence
            )
            
            print("✅ Task completed: \(task.title)")
        }
    }
    
    /// Start a task
    public func startTask(_ task: CoreTypes.ContextualTask) async {
        guard let workerId = currentWorkerId else { return }
        
        broadcastTaskStart(task: task, workerId: workerId, location: locationManager.location)
        print("✅ Task started: \(task.title)")
    }
    
    /// Force sync with server
    public func forceSyncWithServer() async {
        await performSync {
            await refreshData()
            
            // Broadcast sync request
            let syncUpdate = CoreTypes.DashboardUpdate(
                source: .worker,
                type: .buildingMetricsChanged,
                buildingId: currentBuilding?.id ?? "",
                workerId: currentWorkerId ?? "",
                data: [
                    "action": "forceSync",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )
            dashboardSyncService.broadcastWorkerUpdate(syncUpdate)
        }
    }
    
    /// Retry failed sync operations
    public func retrySyncOperations() async {
        await performSync {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            await refreshData()
        }
    }
    
    // MARK: - Public Accessors
    
    /// Get building access type
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
    public func getTasksForBuilding(_ buildingId: String) -> [CoreTypes.ContextualTask] {
        todaysTasks.filter { $0.buildingId == buildingId }
    }
    
    /// Get completion rate for a building
    public func getBuildingCompletionRate(_ buildingId: String) -> Double {
        let buildingTasks = getTasksForBuilding(buildingId)
        guard !buildingTasks.isEmpty else { return 0.0 }
        
        let completed = buildingTasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(buildingTasks.count)
    }
    
    /// Check if worker can access building
    public func canAccessBuilding(_ buildingId: String) -> Bool {
        getBuildingAccessType(for: buildingId) != .unknown
    }
    
    // MARK: - Private Methods - Data Loading
    
    private func loadWorkerProfile(workerId: String) async {
        do {
            workerProfile = try await workerService.getWorkerProfile(for: workerId)
        } catch {
            print("⚠️ Failed to load worker profile: \(error)")
        }
    }
    
    private func loadWorkerCapabilities(workerId: String) async {
        do {
            let rows = try await grdbManager.query(
                "SELECT * FROM worker_capabilities WHERE worker_id = ?",
                [workerId]
            )
            
            if let row = rows.first {
                workerCapabilities = WorkerCapabilities(
                    canUploadPhotos: (row["can_upload_photos"] as? Int64 ?? 1) == 1,
                    canAddNotes: (row["can_add_notes"] as? Int64 ?? 1) == 1,
                    canViewMap: (row["can_view_map"] as? Int64 ?? 1) == 1,
                    canAddEmergencyTasks: (row["can_add_emergency_tasks"] as? Int64 ?? 0) == 1,
                    requiresPhotoForSanitation: (row["requires_photo_for_sanitation"] as? Int64 ?? 1) == 1,
                    simplifiedInterface: (row["simplified_interface"] as? Int64 ?? 0) == 1
                )
                print("✅ Loaded capabilities for worker \(workerId)")
            } else {
                print("⚠️ No capabilities found, using defaults")
                workerCapabilities = .default
            }
        } catch {
            await showError(NSLocalizedString("Could not load worker settings.", comment: "Capabilities error"))
            print("❌ Failed to load capabilities: \(error)")
            workerCapabilities = .default
        }
    }
    
    private func loadClockInStatus(workerId: String) async {
        let status = await clockInManager.getClockInStatus(for: workerId)
        isClockedIn = status.isClockedIn
        currentBuilding = status.building
        
        if status.isClockedIn {
            clockInTime = Date() // Or retrieve actual time from ClockInManager
        }
    }
    
    private func loadWeatherData(for building: CoreTypes.NamedCoordinate) async {
        // Create sample weather data (replace with actual service call when available)
        weatherData = CoreTypes.WeatherData(
            temperature: 72,
            condition: NSLocalizedString("Partly Cloudy", comment: "Weather"),
            humidity: 0.65,
            windSpeed: 10,
            outdoorWorkRisk: .low,
            timestamp: Date()
        )
        outdoorWorkRisk = weatherData?.outdoorWorkRisk ?? .low
    }
    
    private func loadBuildingTasks(workerId: String, buildingId: String) async {
        todaysTasks = contextEngine.todaysTasks.filter { $0.buildingId == buildingId }
        print("✅ Loaded \(todaysTasks.count) tasks for building \(buildingId)")
    }
    
    private func loadBuildingMetrics() async {
        for building in assignedBuildings {
            do {
                let metrics = try await metricsService.calculateMetrics(for: building.id)
                buildingMetrics[building.id] = metrics
            } catch {
                print("⚠️ Failed to load metrics for \(building.id): \(error)")
            }
        }
    }
    
    // MARK: - Private Methods - State Management
    
    private func syncStateFromContextEngine() async {
        assignedBuildings = contextEngine.assignedBuildings
        todaysTasks = contextEngine.todaysTasks
        taskProgress = contextEngine.taskProgress
        isClockedIn = contextEngine.clockInStatus.isClockedIn
        currentBuilding = contextEngine.clockInStatus.building
        portfolioBuildings = contextEngine.portfolioBuildings
        
        if contextEngine.clockInStatus.isClockedIn {
            clockInTime = Date()
        }
    }
    
    private func updateClockInState(building: CoreTypes.NamedCoordinate, time: Date, location: CLLocation?) {
        isClockedIn = true
        currentBuilding = building
        clockInTime = time
        clockInLocation = location
    }
    
    private func resetClockInState() {
        isClockedIn = false
        currentBuilding = nil
        clockInTime = nil
        clockInLocation = nil
        weatherData = nil
    }
    
    private func updateTaskCompletion(taskId: String) {
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = true
            todaysTasks[index].completedDate = Date()
        }
    }
    
    // MARK: - Private Methods - Calculations
    
    private func calculateMetrics() async {
        let totalTasks = todaysTasks.count
        let completedTasks = todaysTasks.filter { $0.isCompleted }.count
        
        taskProgress = CoreTypes.TaskProgress(
            totalTasks: totalTasks,
            completedTasks: completedTasks
        )
        
        completionRate = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
        todaysEfficiency = calculateEfficiency()
        
        print("✅ Progress: \(completedTasks)/\(totalTasks) = \(Int(completionRate * 100))%")
    }
    
    private func calculateEfficiency() -> Double {
        let completedTasks = todaysTasks.filter { $0.isCompleted }
        guard !completedTasks.isEmpty else { return 0.0 }
        
        // Simple efficiency based on completion rate with bonus for early completion
        return min(1.0, completionRate * 1.2)
    }
    
    private func calculateHoursWorkedToday() async {
        guard let workerId = currentWorkerId else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            let summary = try await clockInManager.getPayrollSummary(
                for: workerId,
                startDate: startOfDay,
                endDate: endOfDay
            )
            hoursWorkedToday = summary.totalHours
            
            // Add current session if clocked in
            if let clockInTime = clockInTime {
                let currentSessionHours = Date().timeIntervalSince(clockInTime) / 3600.0
                hoursWorkedToday += currentSessionHours
            }
        } catch {
            print("⚠️ Failed to calculate hours: \(error)")
        }
    }
    
    private func calculateSessionSummary(building: CoreTypes.NamedCoordinate) -> (tasks: Int, hours: Double) {
        let completedTasks = todaysTasks.filter { $0.isCompleted && $0.buildingId == building.id }
        let hoursWorked = clockInTime.map { Date().timeIntervalSince($0) / 3600.0 } ?? 0
        return (completedTasks.count, hoursWorked)
    }
    
    private func updateBuildingMetrics(buildingId: String) async {
        do {
            let metrics = try await metricsService.calculateMetrics(for: buildingId)
            buildingMetrics[buildingId] = metrics
            
            // Broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: .worker,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: currentWorkerId ?? "",
                data: [
                    "completionRate": String(metrics.completionRate),
                    "overdueTasks": String(metrics.overdueTasks)
                ]
            )
            dashboardSyncService.broadcastWorkerUpdate(update)
        } catch {
            print("⚠️ Failed to update building metrics: \(error)")
        }
    }
    
    // MARK: - Private Methods - Broadcasting
    
    private func broadcastWorkerActivation(user: CoreTypes.User) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .taskStarted,
            buildingId: currentBuilding?.id ?? "",
            workerId: user.workerId,
            data: [
                "workerId": user.workerId,
                "buildingCount": String(assignedBuildings.count),
                "taskCount": String(todaysTasks.count)
            ]
        )
        dashboardSyncService.broadcastWorkerUpdate(update)
    }
    
    private func broadcastClockIn(workerId: String, building: CoreTypes.NamedCoordinate, hasLocation: Bool) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerClockedIn,
            buildingId: building.id,
            workerId: workerId,
            data: [
                "buildingName": building.name,
                "clockInTime": ISO8601DateFormatter().string(from: Date()),
                "hasLocation": String(hasLocation)
            ]
        )
        dashboardSyncService.broadcastWorkerUpdate(update)
    }
    
    private func broadcastClockOut(workerId: String, building: CoreTypes.NamedCoordinate, summary: (tasks: Int, hours: Double)) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .workerClockedOut,
            buildingId: building.id,
            workerId: workerId,
            data: [
                "buildingName": building.name,
                "completedTaskCount": String(summary.tasks),
                "hoursWorked": String(format: "%.2f", summary.hours),
                "clockOutTime": ISO8601DateFormatter().string(from: Date())
            ]
        )
        dashboardSyncService.broadcastWorkerUpdate(update)
    }
    
    private func broadcastTaskCompletion(task: CoreTypes.ContextualTask, workerId: String, evidence: CoreTypes.ActionEvidence) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .taskCompleted,
            buildingId: task.buildingId ?? "",
            workerId: workerId,
            data: [
                "taskId": task.id,
                "completionTime": ISO8601DateFormatter().string(from: Date()),
                "evidence": evidence.description,
                "photoCount": String(evidence.photoURLs.count),
                "requiresPhoto": String(workerCapabilities?.requiresPhotoForSanitation ?? false)
            ]
        )
        dashboardSyncService.broadcastWorkerUpdate(update)
    }
    
    private func broadcastTaskStart(task: CoreTypes.ContextualTask, workerId: String, location: CLLocation?) {
        let update = CoreTypes.DashboardUpdate(
            source: .worker,
            type: .taskStarted,
            buildingId: task.buildingId ?? "",
            workerId: workerId,
            data: [
                "taskId": task.id,
                "taskTitle": task.title,
                "startedAt": ISO8601DateFormatter().string(from: Date()),
                "latitude": String(location?.coordinate.latitude ?? 0),
                "longitude": String(location?.coordinate.longitude ?? 0)
            ]
        )
        dashboardSyncService.broadcastWorkerUpdate(update)
    }
    
    // MARK: - Private Methods - Setup
    
    private func setupSubscriptions() {
        // Cross-dashboard updates
        dashboardSyncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleCrossDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Admin updates
        dashboardSyncService.adminDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleAdminUpdate(update)
            }
            .store(in: &cancellables)
        
        // Client updates
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleClientUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func setupTimers() {
        // Auto-refresh every minute
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isLoading else { return }
                await self.refreshData()
            }
        }
        
        // Weather updates every 30 minutes
        weatherUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self,
                      let building = self.currentBuilding else { return }
                await self.loadWeatherData(for: building)
            }
        }
    }
    
    private func setupLocationTracking() {
        locationManager.requestLocation()
        
        locationManager.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.clockInLocation = location
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods - Update Handlers
    
    private func handleCrossDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        recentUpdates.append(update)
        if recentUpdates.count > 20 {
            recentUpdates = Array(recentUpdates.suffix(20))
        }
        
        switch update.type {
        case .taskStarted where update.workerId == currentWorkerId:
            Task { await refreshData() }
            
        case .buildingMetricsChanged:
            Task { await loadBuildingMetrics() }
            
        case .complianceStatusChanged:
            if assignedBuildings.contains(where: { $0.id == update.buildingId }) {
                Task { await refreshData() }
            }
            
        default:
            break
        }
    }
    
    private func handleAdminUpdate(_ update: CoreTypes.DashboardUpdate) {
        if update.type == .buildingMetricsChanged,
           !update.buildingId.isEmpty,
           assignedBuildings.contains(where: { $0.id == update.buildingId }) {
            Task { await updateBuildingMetrics(buildingId: update.buildingId) }
        }
    }
    
    private func handleClientUpdate(_ update: CoreTypes.DashboardUpdate) {
        if update.type == .complianceStatusChanged,
           !update.buildingId.isEmpty,
           assignedBuildings.contains(where: { $0.id == update.buildingId }) {
            Task { await refreshData() }
        }
    }
    
    // MARK: - Private Methods - Helpers
    
    private func createDefaultEvidence(for task: CoreTypes.ContextualTask) -> CoreTypes.ActionEvidence {
        CoreTypes.ActionEvidence(
            description: NSLocalizedString("Task completed via Worker Dashboard", comment: "") + ": \(task.title)",
            photoURLs: [],
            timestamp: Date()
        )
    }
    
    private func performLoading(_ operation: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await operation()
            isLoading = false
        } catch {
            let localizedError = NSLocalizedString("Failed to load dashboard data. Please check your connection and try again.", comment: "")
            await showError("\(localizedError) (\(error.localizedDescription))")
        }
    }
    
    private func performSync(_ operation: @escaping () async throws -> Void) async {
        dashboardSyncStatus = .syncing
        
        do {
            try await operation()
            dashboardSyncStatus = .synced
        } catch {
            dashboardSyncStatus = .failed
            let errorMessage = NSLocalizedString("Sync failed", comment: "")
            await showError("\(errorMessage): \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) async {
        errorMessage = message
        isLoading = false
        dashboardSyncStatus = .failed
    }
    
    private func cleanup() {
        refreshTimer?.invalidate()
        weatherUpdateTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Preview Support

#if DEBUG
extension WorkerDashboardViewModel {
    static func preview() -> WorkerDashboardViewModel {
        let viewModel = WorkerDashboardViewModel()
        
        // Configure with sample data
        viewModel.assignedBuildings = [
            CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7397,
                longitude: -73.9978
            )
        ]
        
        viewModel.todaysTasks = [
            CoreTypes.ContextualTask(
                title: "HVAC Inspection",
                description: "Check HVAC system in main gallery",
                isCompleted: false,
                scheduledDate: nil,
                dueDate: Date().addingTimeInterval(3600),
                category: .maintenance,
                urgency: .high,
                building: viewModel.assignedBuildings.first,
                worker: nil
            )
        ]
        
        viewModel.taskProgress = CoreTypes.TaskProgress(
            totalTasks: 5,
            completedTasks: 2
        )
        
        viewModel.weatherData = CoreTypes.WeatherData(
            temperature: 32,
            condition: "Snowy",
            humidity: 0.85,
            windSpeed: 15,
            outdoorWorkRisk: .high,
            timestamp: Date()
        )
        
        viewModel.workerCapabilities = WorkerCapabilities(
            canUploadPhotos: true,
            canAddNotes: true,
            canViewMap: true,
            canAddEmergencyTasks: true,
            requiresPhotoForSanitation: true,
            simplifiedInterface: false
        )
        
        return viewModel
    }
}
#endif
