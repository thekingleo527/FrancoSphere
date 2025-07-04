//
//  WorkerDashboardIntegration.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved (Date unwrapping issues)
//  ✅ UPDATED: Uses existing managers (WorkerManager, TaskManagementService)
//  ✅ PRESERVED: All functionality from both versions
//  ✅ ENHANCED: Complete dashboard integration with real-world data
//

import Foundation
import SwiftUI
import Combine

// MARK: - Worker Dashboard Integration Service

@MainActor
class WorkerDashboardIntegration: ObservableObject {
    
    // MARK: - Service Dependencies (FIXED: Uses existing managers)
    private let taskManagementService = TaskManagementService.shared  // FIXED: Use existing service
    private let workerManager = WorkerManager.shared                  // FIXED: Use existing manager
    private let contextEngine = WorkerContextEngine.shared
    private let csvImporter = OperationalDataManager.shared
    
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
            
            // Ensure CSV data is loaded first
            await ensureCSVDataLoaded()
            
            // Load data using existing managers
            async let buildings = workerManager.loadWorkerBuildings(workerId)
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
    
    // MARK: - Task Loading (FIXED: Use existing services)
    
    private func loadTasksForWorker(_ workerId: String) async throws -> [ContextualTask] {
        // Use WorkerContextEngine for consistent task loading
        await contextEngine.loadWorkerContext(workerId: workerId)
        return contextEngine.getTodaysTasks()
    }
    
    private func calculateTaskProgress(for workerId: String) async -> TimeBasedTaskFilter.TaskProgress {
        // Get tasks from context engine
        let tasks = contextEngine.getTodaysTasks()
        
        // Use existing TimeBasedTaskFilter method
        return TimeBasedTaskFilter.calculateTaskProgress(tasks: tasks)
    }
    
    // MARK: - CSV Data Management (FIXED: Updated to use existing services)
    
    /// Ensure CSV data is loaded into the system
    private func ensureCSVDataLoaded() async {
        do {
            // Check if already imported
            let hasImported = await checkIfCSVImported()
            if hasImported {
                print("✅ CSV tasks already imported")
                return
            }
            
            print("🔄 Importing CSV data...")
            csvImportProgress = 0.1
            
            // Use OperationalDataManager to load real tasks
            let (imported, errors) = try await csvImporter.importRealWorldTasks()
            
            csvImportProgress = 1.0
            
            print("✅ Imported \(imported) real tasks from CSV")
            
            if !errors.isEmpty {
                print("⚠️ Import errors: \(errors)")
            }
            
        } catch {
            print("❌ Failed to import CSV tasks: \(error)")
            self.error = error
        }
    }
    
    /// Check if CSV has been imported
    private func checkIfCSVImported() async -> Bool {
        do {
            // FIXED: workerId is non-optional String, just check if empty
            let workerId = NewAuthManager.shared.workerId
            guard !workerId.isEmpty else {
                return false
            }
            
            // Get all tasks and check for CSV pattern or sufficient task count
            let allTasks = try await loadTasksForWorker(workerId)
            
            // Check for CSV-imported tasks (should have external_id pattern or sufficient count)
            let csvTasks = allTasks.filter { task in
                task.id.contains("CSV") || task.id.contains("csv") ||
                (task.assignedWorkerName?.isEmpty == false)
            }
            
            // We expect at least 20+ tasks for active workers
            let hasMinimumTasks = allTasks.count >= 20
            let hasCsvPattern = csvTasks.count > 0
            
            return hasMinimumTasks || hasCsvPattern
            
        } catch {
            print("❌ Error checking CSV import status: \(error)")
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
        
        // FIXED: workerId is non-optional String, just check if empty
        guard !workerId.isEmpty else { return }
        
        // Update through TaskManagementService
        await taskManagementService.toggleTaskCompletion(
            taskID: taskId,
            workerID: workerId,
            buildingID: buildingId
        )
        
        print("✅ Task \(taskId) completed")
        
        // Refresh dashboard to reflect changes
        await refreshDashboard()
    }
    
    // MARK: - Context Engine Integration
    
    func syncWithContextEngine() async {
        // FIXED: workerId is non-optional String, just check if empty
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
        
        // 1. Ensure CSV data is loaded
        await integration.ensureCSVDataLoaded()
        
        // 2. Load worker context (this pulls from tasks table)
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
        
        if data.taskProgress.totalTasks == 0 {
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
            "lastRefresh": data.lastUpdated.timeIntervalSince1970  // FIXED: Direct access to non-optional
        ]
    }
    
    deinit {
        refreshTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - Dashboard Data Model

struct DashboardData {
    let workerId: String
    let assignedBuildings: [FrancoSphere.NamedCoordinate]
    let todaysTasks: [ContextualTask]
    let taskProgress: TimeBasedTaskFilter.TaskProgress  // FIXED: Use existing TaskProgress
    let lastUpdated: Date
    
    // Computed properties for easy access
    var buildingCount: Int { assignedBuildings.count }
    var totalTasks: Int { todaysTasks.count }
    var completedTasks: Int { taskProgress.completedTasks }  // FIXED: Use correct property
    var remainingTasks: Int { taskProgress.totalTasks - taskProgress.completedTasks }  // FIXED: Calculate from existing properties
    var completionPercentage: Double {
        let total = max(taskProgress.totalTasks, 1)
        return Double(taskProgress.completedTasks) / Double(total) * 100
    }
    
    // Task status breakdown
    var pendingTasks: [ContextualTask] {
        todaysTasks.filter { $0.status == "pending" }
    }
    
    var overdueTasks: [ContextualTask] {
        todaysTasks.filter { isTaskOverdue($0) }  // FIXED: Use helper function
    }
    
    var currentTasks: [ContextualTask] {
        todaysTasks.filter { isTaskCurrent($0) }  // FIXED: Use helper function
    }
    
    var upcomingTasks: [ContextualTask] {
        todaysTasks.filter { isTaskUpcoming($0) }  // FIXED: Use helper function
    }
    
    // MARK: - Helper methods with proper Date unwrapping
    private func isTaskOverdue(_ task: ContextualTask) -> Bool {
        guard let endTime = task.endTime,
              let endDate = parseTaskTime(endTime) else { return false }  // FIXED: Proper unwrapping
        return endDate < Date() && task.status != "completed"
    }
    
    private func isTaskCurrent(_ task: ContextualTask) -> Bool {
        guard let startTime = task.startTime,
              let endTime = task.endTime,
              let startDate = parseTaskTime(startTime),
              let endDate = parseTaskTime(endTime) else { return false }  // FIXED: Proper unwrapping
        
        let now = Date()
        return now >= startDate && now <= endDate && task.status != "completed"
    }
    
    private func isTaskUpcoming(_ task: ContextualTask) -> Bool {
        guard let startTime = task.startTime,
              let startDate = parseTaskTime(startTime) else { return false }  // FIXED: Proper unwrapping
        
        return startDate > Date() && task.status != "completed"
    }
}

// MARK: - Time Status Extension for ContextualTask (PRESERVED)

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
            // More than 30 minutes late
            return "overdue"
        } else if difference >= -30 && difference <= 30 {
            // Within 30 minute window (in progress)
            return "current"
        } else {
            // Upcoming
            return "upcoming"
        }
    }
}

// MARK: - Helper Functions for UI Compatibility (PRESERVED)

/// Helper to map ContextualTask to MaintenanceTask for UI compatibility
func mapContextualTasksToMaintenanceTasks(_ contextualTasks: [ContextualTask]) -> [MaintenanceTask] {
    contextualTasks.map { task in
        MaintenanceTask(
            id: task.id,
            name: task.name,
            buildingID: task.buildingId,
            description: "", // Not in ContextualTask
            dueDate: Date(), // Today
            startTime: parseTimeString(task.startTime),
            endTime: parseTimeString(task.endTime),
            category: TaskCategory(rawValue: task.category) ?? .maintenance,
            urgency: TaskUrgency(rawValue: task.urgencyLevel) ?? .medium,
            recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .oneTime,
            isComplete: task.status == "completed",
            assignedWorkers: [], // Initialize as empty array
            requiredSkillLevel: task.skillLevel
        )
    }
}

/// Parse time string to Date (FIXED: Proper optional handling)
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

/// Helper function to parse task time (FIXED: Proper optional handling)
private func parseTaskTime(_ timeStr: String) -> Date? {
    return parseTimeString(timeStr)
}

// MARK: - Error Types

enum DashboardIntegrationError: LocalizedError {
    case noWorkerID
    case dataLoadFailed(Error)
    case contextSyncFailed(Error)
    case csvImportFailed(Error)
    case serviceUnavailable(String)
    
    var errorDescription: String? {
        switch self {
        case .noWorkerID:
            return "Worker ID not available for dashboard integration"
        case .dataLoadFailed(let error):
            return "Failed to load dashboard data: \(error.localizedDescription)"
        case .contextSyncFailed(let error):
            return "Failed to sync with context engine: \(error.localizedDescription)"
        case .csvImportFailed(let error):
            return "Failed to import CSV data: \(error.localizedDescription)"
        case .serviceUnavailable(let service):
            return "Service unavailable: \(service)"
        }
    }
}

// MARK: - String Extension Helper

extension String {
    var isNotEmpty: Bool {
        return !isEmpty
    }
}
