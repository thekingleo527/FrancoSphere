//
//  WorkerDashboardIntegration.swift
//  FrancoSphere
//
//  ✅ FIXED: Updated to use consolidated services (TaskService, WorkerService, BuildingService)
//  ✅ REMOVED: References to old TaskManagementService and WorkerManager
//  ✅ PRESERVED: All functionality with new service architecture
//

import Foundation
import SwiftUI
import Combine

// MARK: - Worker Dashboard Integration Service

@MainActor
class WorkerDashboardIntegration: ObservableObject {
    
    // MARK: - Service Dependencies (UPDATED: Use consolidated services)
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let contextEngine = WorkerContextEngine.shared
    private let operationalManager = OperationalDataManager.shared
    
    // MARK: - Published Properties
    @Published var dashboardData: DashboardData?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var csvImportProgress: Double = 0.0
    @Published var lastRefresh: Date?
    
    // MARK: - Private Properties
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Singleton
    static let shared = WorkerDashboardIntegration()
    
    private init() {
        setupAutoRefresh()
    }
    
    // MARK: - Dashboard Data Integration
    
    func loadDashboardData(for workerId: String) async {
        isLoading = true
        error = nil
        
        do {
            print("🔄 Loading dashboard data for worker \(workerId)")
            
            // Ensure operational data is loaded first
            await ensureOperationalDataLoaded()
            
            // Load data using consolidated services
            async let buildings = loadWorkerBuildings(workerId)
            async let tasks = loadTasksForWorker(workerId)
            async let progress = calculateTaskProgress(for: workerId)
            
            let (buildingList, taskList, taskProgress) = try await (buildings, tasks, progress)
            
            // Create dashboard data
            let dashboardData = DashboardData(
                workerId: workerId,
                assignedBuildings: buildingList,
                todaysTasks: taskList,
                taskProgress: taskProgress,
                lastUpdated: Date()
            )
            
            self.dashboardData = dashboardData
            self.lastRefresh = Date()
            self.isLoading = false
            
            print("✅ Dashboard data loaded for worker \(workerId): \(buildingList.count) buildings, \(taskList.count) tasks")
            
        } catch {
            self.error = error
            self.isLoading = false
            print("❌ Failed to load dashboard data: \(error)")
        }
    }
    
    // MARK: - Data Loading (UPDATED: Use consolidated services)
    
    private func loadWorkerBuildings(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        return try await workerService.getAssignedBuildings(workerId)
    }
    
    private func loadTasksForWorker(_ workerId: String) async throws -> [ContextualTask] {
        return try await taskService.getTasks(for: workerId, date: Date())
    }
    
    private func calculateTaskProgress(for workerId: String) async -> TaskProgress {
        do {
            return try await taskService.getTaskProgress(for: workerId)
        } catch {
            print("Failed to calculate task progress: \(error)")
            return TaskProgress(completed: 0, total: 0, remaining: 0, percentage: 0, overdueTasks: 0)
        }
    }
    
    // MARK: - Operational Data Management (UPDATED: Use OperationalDataManager)
    
    /// Ensure operational data is loaded into the system
    private func ensureOperationalDataLoaded() async {
        do {
            // Check if already imported
            let hasImported = await checkIfDataImported()
            if hasImported {
                print("✅ Operational data already loaded")
                return
            }
            
            print("🔄 Loading operational data...")
            csvImportProgress = 0.1
            
            // Use OperationalDataManager to load real tasks
            let (imported, errors) = try await operationalManager.importRealWorldTasks()
            
            csvImportProgress = 1.0
            
            print("✅ Loaded \(imported) real tasks from operational data")
            
            if !errors.isEmpty {
                print("⚠️ Import errors: \(errors)")
            }
            
        } catch {
            print("❌ Failed to load operational data: \(error)")
            self.error = error
        }
    }
    
    /// Check if operational data has been imported
    private func checkIfDataImported() async -> Bool {
        do {
            let workerId = NewAuthManager.shared.workerId
            guard !workerId.isEmpty else {
                return false
            }
            
            // Get all tasks and check for operational data pattern
            let allTasks = try await loadTasksForWorker(workerId)
            
            // Check for operational data tasks (should have sufficient count)
            let operationalTasks = allTasks.filter { task in
                !task.assignedWorkerName.isNilOrEmpty
            }
            
            // We expect at least 20+ tasks for active workers
            let hasMinimumTasks = allTasks.count >= 20
            let hasOperationalPattern = operationalTasks.count > 0
            
            return hasMinimumTasks || hasOperationalPattern
            
        } catch {
            print("❌ Error checking operational data status: \(error)")
            return false
        }
    }
    
    // MARK: - Real-time Updates
    
    func refreshDashboard() async {
        guard let currentData = dashboardData else { return }
        await loadDashboardData(for: currentData.workerId)
    }
    
    func updateTaskCompletion(_ taskId: String, buildingId: String) async {
        guard let workerId = dashboardData?.workerId else { return }
        guard !workerId.isEmpty else { return }
        
        do {
            // Update through consolidated TaskService
            try await taskService.completeTask(
                taskId,
                workerId: workerId,
                buildingId: buildingId,
                evidence: nil
            )
            
            print("✅ Task \(taskId) completed")
            
            // Refresh dashboard to reflect changes
            await refreshDashboard()
            
        } catch {
            print("❌ Failed to complete task: \(error)")
            self.error = error
        }
    }
    
    // MARK: - Context Engine Integration
    
    func syncWithContextEngine() async {
        let workerId = NewAuthManager.shared.workerId
        guard !workerId.isEmpty else { return }
        
        print("🔄 Syncing with context engine...")
        
        // Ensure context engine has latest data
        await contextEngine.refreshContext()
        
        // Load dashboard with refreshed context
        await loadDashboardData(for: workerId)
        
        print("✅ Context engine sync complete")
    }
    
    // MARK: - Background Updates & Auto-refresh
    
    private func setupAutoRefresh() {
        // Refresh every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { @MainActor in
                await self.refreshDashboard()
            }
        }
    }
    
    func startBackgroundUpdates() {
        print("🔄 Starting background updates...")
        setupAutoRefresh()
    }
    
    func stopBackgroundUpdates() {
        print("⏹️ Stopping background updates...")
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Worker-Specific Setup
    
    /// Complete setup for WorkerDashboardView
    static func setupDashboard(for workerId: String) async {
        let integration = WorkerDashboardIntegration.shared
        
        // 1. Ensure operational data is loaded
        await integration.ensureOperationalDataLoaded()
        
        // 2. Load worker context
        await WorkerContextEngine.shared.loadWorkerContext(workerId: workerId)
        
        // 3. Load dashboard data
        await integration.loadDashboardData(for: workerId)
        
        // 4. Start auto-refresh
        integration.startBackgroundUpdates()
        
        print("✅ Dashboard setup complete for worker \(workerId)")
    }
    
    // MARK: - Data Health & Validation
    
    func validateDashboardData() -> [String] {
        var issues: [String] = []
        
        guard let data = dashboardData else {
            issues.append("No dashboard data loaded")
            return issues
        }
        
        if data.assignedBuildings.isEmpty {
            issues.append("No buildings assigned to worker")
        }
        
        if data.todaysTasks.isEmpty {
            issues.append("No tasks scheduled for today")
        }
        
        if data.taskProgress.total == 0 {
            issues.append("Task progress calculation failed")
        }
        
        // Worker-specific validation
        if data.workerId == "4" && data.assignedBuildings.count < 6 {
            issues.append("Kevin should have 8+ buildings (expanded duties)")
        }
        
        return issues
    }
    
    func getDataHealthReport() -> [String: Any] {
        guard let data = dashboardData else {
            return ["status": "no_data", "lastRefresh": "never"]
        }
        
        let issues = validateDashboardData()
        
        return [
            "status": issues.isEmpty ? "healthy" : "issues",
            "issues": issues,
            "buildingCount": data.buildingCount,
            "taskCount": data.totalTasks,
            "completionRate": data.completionPercentage,
            "lastRefresh": data.lastUpdated.timeIntervalSince1970
        ]
    }
    
    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Dashboard Data Model (UPDATED: Use TaskProgress from TaskService)

struct DashboardData {
    let workerId: String
    let assignedBuildings: [FrancoSphere.NamedCoordinate]
    let todaysTasks: [ContextualTask]
    let taskProgress: TaskProgress  // Use TaskProgress from TaskService
    let lastUpdated: Date
    
    // Computed properties for easy access
    var buildingCount: Int { assignedBuildings.count }
    var totalTasks: Int { todaysTasks.count }
    var completedTasks: Int { taskProgress.completed }
    var remainingTasks: Int { taskProgress.remaining }
    var completionPercentage: Double { taskProgress.percentage }
    
    // Task status breakdown
    var pendingTasks: [ContextualTask] {
        todaysTasks.filter { $0.status == "pending" }
    }
    
    var overdueTasks: [ContextualTask] {
        todaysTasks.filter { isTaskOverdue($0) }
    }
    
    var currentTasks: [ContextualTask] {
        todaysTasks.filter { isTaskCurrent($0) }
    }
    
    var upcomingTasks: [ContextualTask] {
        todaysTasks.filter { isTaskUpcoming($0) }
    }
    
    // MARK: - Helper methods with proper Date handling
    private func isTaskOverdue(_ task: ContextualTask) -> Bool {
        guard let endTime = task.endTime,
              let endDate = parseTaskTime(endTime) else { return false }
        return endDate < Date() && task.status != "completed"
    }
    
    private func isTaskCurrent(_ task: ContextualTask) -> Bool {
        guard let startTime = task.startTime,
              let endTime = task.endTime,
              let startDate = parseTaskTime(startTime),
              let endDate = parseTaskTime(endTime) else { return false }
        
        let now = Date()
        return now >= startDate && now <= endDate && task.status != "completed"
    }
    
    private func isTaskUpcoming(_ task: ContextualTask) -> Bool {
        guard let startTime = task.startTime,
              let startDate = parseTaskTime(startTime) else { return false }
        
        return startDate > Date() && task.status != "completed"
    }
}

// MARK: - Time Status Extension for ContextualTask

extension ContextualTask {
    
    var timeStatus: String {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // Parse task start time
        guard let startTime = startTime else {
            return "upcoming"
        }
        
        let components = startTime.split(separator: ":")
        guard components.count == 2,
              let taskHour = Int(components[0]),
              let taskMinute = Int(components[1]) else {
            return "upcoming"
        }
        
        let taskTotalMinutes = taskHour * 60 + taskMinute
        
        // Check status
        if status == "completed" {
            return "completed"
        }
        
        let difference = taskTotalMinutes - currentTotalMinutes
        
        if difference < -30 {
            return "overdue"
        } else if difference >= -30 && difference <= 30 {
            return "current"
        } else {
            return "upcoming"
        }
    }
}

// MARK: - Helper Functions

/// Parse time string to Date
private func parseTimeString(_ timeStr: String?) -> Date? {
    guard let timeStr = timeStr else { return nil }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    
    if let time = formatter.date(from: timeStr) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: components.hour ?? 0,
                           minute: components.minute ?? 0,
                           second: 0,
                           of: Date())
    }
    
    return nil
}

/// Helper function to parse task time
private func parseTaskTime(_ timeStr: String) -> Date? {
    return parseTimeString(timeStr)
}

// MARK: - Error Types

enum DashboardIntegrationError: LocalizedError {
    case noWorkerID
    case dataLoadFailed(Error)
    case contextSyncFailed(Error)
    case operationalDataFailed(Error)
    case serviceUnavailable(String)
    
    var errorDescription: String? {
        switch self {
        case .noWorkerID:
            return "Worker ID not available for dashboard integration"
        case .dataLoadFailed(let error):
            return "Failed to load dashboard data: \(error.localizedDescription)"
        case .contextSyncFailed(let error):
            return "Failed to sync with context engine: \(error.localizedDescription)"
        case .operationalDataFailed(let error):
            return "Failed to load operational data: \(error.localizedDescription)"
        case .serviceUnavailable(let service):
            return "Service unavailable: \(service)"
        }
    }
}

// MARK: - String Extension Helper

extension String? {
    var isNilOrEmpty: Bool {
        return self?.isEmpty ?? true
    }
}

// MARK: - Legacy Support (if needed by other files)

/// Helper to map ContextualTask to MaintenanceTask for UI compatibility
func mapContextualTasksToMaintenanceTasks(_ contextualTasks: [ContextualTask]) -> [MaintenanceTask] {
    return contextualTasks.map { task in
        MaintenanceTask(
            id: task.id,
            name: task.name,
            buildingID: task.buildingId,
            description: "",
            dueDate: Date(),
            startTime: parseTimeString(task.startTime),
            endTime: parseTimeString(task.endTime),
            category: TaskCategory(rawValue: task.category) ?? .maintenance,
            urgency: TaskUrgency(rawValue: task.urgencyLevel) ?? .medium,
            recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .oneTime,
            isComplete: task.status == "completed",
            assignedWorkers: [],
            requiredSkillLevel: task.skillLevel
        )
    }
}
