//
//  WorkerContextExtensions.swift
//  FrancoSphere
//
//  ✅ SIMPLE FIX - Uses existing managers only
//  ✅ FIXED: All compilation errors resolved
//  ✅ REMOVED: Non-existent service references
//  ✅ USES: WorkerManager, SQLiteManager, WeatherManager (existing)
//

import Foundation
import Combine
import UserNotifications

// MARK: - WorkerContextEngine Extensions

extension WorkerContextEngine {
    
    // MARK: - Refresh Management
    
    private static let refreshInterval: TimeInterval = 900 // 15 minutes
    
    private var refreshTimer: Timer? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.refreshTimer) as? Timer }
        set { objc_setAssociatedObject(self, &AssociatedKeys.refreshTimer, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Associated Keys
    
    private struct AssociatedKeys {
        static var refreshTimer = "refreshTimer"
        static var contextRefreshSubject = "contextRefreshSubject"
        static var lastRefreshTime = "lastRefreshTime"
        static var lastError = "lastError"
    }
    
    // MARK: - Error Handling
    
    var lastError: Error? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastError) as? Error }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastError, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Published Properties
    
    var lastRefreshTime: Date {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastRefreshTime) as? Date ?? Date() }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastRefreshTime, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Refresh Stream
    
    private var contextRefreshSubject: PassthroughSubject<Void, Never> {
        if let existing = objc_getAssociatedObject(self, &AssociatedKeys.contextRefreshSubject) as? PassthroughSubject<Void, Never> {
            return existing
        }
        let new = PassthroughSubject<Void, Never>()
        objc_setAssociatedObject(self, &AssociatedKeys.contextRefreshSubject, new, .OBJC_ASSOCIATION_RETAIN)
        return new
    }
    
    var contextDidChange: AnyPublisher<Void, Never> {
        contextRefreshSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Automatic Refresh
    
    func startAutoRefresh() {
        stopAutoRefresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.refreshContext()
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Safe Internal Data Access Methods
    
    internal func getTodaysTasksInternal() -> [ContextualTask] {
        return todaysTasks
    }
    
    internal func getAssignedBuildingsInternal() -> [FrancoSphere.NamedCoordinate] {
        return assignedBuildings
    }
    
    // MARK: - Enhanced Load Methods (Using Existing Managers)
    
    func loadWorkerTasksWithManager(_ workerId: String) async -> [ContextualTask] {
        // Use existing WorkerContextEngine methods
        await loadWorkerContext(workerId: workerId)
        
        // Notify observers
        contextRefreshSubject.send()
        
        return getTodaysTasksInternal()
    }
    
    func loadWorkerBuildingsWithManager(_ workerId: String) async throws -> [FrancoSphere.NamedCoordinate] {
        // Use existing WorkerManager
        let buildings = try await WorkerManager.shared.loadWorkerBuildings(workerId)
        
        // Update internal state
        await MainActor.run {
            self.assignedBuildings = buildings
        }
        
        // Notify observers
        contextRefreshSubject.send()
        
        return buildings
    }
    
    // MARK: - Context Refresh with Existing Managers
    
    private func refreshContextWithManagers() async {
        guard let workerId = currentWorker?.workerId else {
            print("⚠️ No worker ID available for refresh")
            return
        }
        
        // Parallel loading using existing managers
        async let buildings = loadWorkerBuildingsWithManager(workerId)
        async let tasks = loadWorkerTasksWithManager(workerId)
        
        do {
            let (buildingList, taskList) = try await (buildings, tasks)
            
            await MainActor.run {
                self.assignedBuildings = buildingList
                self.todaysTasks = taskList
                self.lastRefreshTime = Date()
            }
            
            print("✅ Context refreshed: \(buildingList.count) buildings, \(taskList.count) tasks")
            
        } catch {
            lastError = error
            print("❌ Context refresh failed: \(error)")
        }
    }
    
    // MARK: - Background Operations
    
    func scheduleBackgroundRefresh() {
        let identifier = "com.francosphere.background-refresh"
        
        let content = UNMutableNotificationContent()
        content.title = "FrancoSphere"
        content.body = "Refreshing your schedule..."
        content.sound = nil
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: Self.refreshInterval, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule background refresh: \(error)")
            } else {
                print("✅ Background refresh scheduled")
            }
        }
    }
    
    // MARK: - Data Validation (Simplified)
    
    func validateDataIntegrity() async -> Bool {
        guard let workerId = currentWorker?.workerId else {
            return false
        }
        
        // Simple validation using existing data
        if assignedBuildings.isEmpty {
            print("⚠️ No assigned buildings found")
            return false
        }
        
        if todaysTasks.isEmpty {
            print("⚠️ No tasks found for today")
            return false
        }
        
        return true
    }
    
    // MARK: - Logging and Summary
    
    func logContextSummary() -> String {
        let worker = currentWorker?.workerName ?? "Unknown"
        let buildingCount = assignedBuildings.count
        let taskCount = todaysTasks.count
        let pendingCount = todaysTasks.filter { $0.status.lowercased() == "pending" }.count
        let routineCount = dailyRoutines.count
        
        return """
        📊 WorkerContextEngine Summary:
        Worker: \(worker) (ID: \(getWorkerId()))
        Buildings: \(buildingCount)
        Tasks: \(taskCount) (\(pendingCount) pending)
        Routines: \(routineCount)
        Last Refresh: \(lastRefreshTime)
        Data Health: \(lastError == nil ? "✅ Healthy" : "⚠️ Issues")
        """
    }
    
    // MARK: - Time-Based Task Filtering
    
    func getTasksForTimeWindow(startHour: Int, endHour: Int) -> [ContextualTask] {
        let allTasks = getTodaysTasksInternal()
        
        return allTasks.filter { task in
            guard let startTime = task.startTime, !startTime.isEmpty else { return false }
            
            let components = startTime.split(separator: ":")
            guard components.count >= 1,
                  let hour = Int(components[0]) else { return false }
            
            return hour >= startHour && hour < endHour
        }
    }
    
    func getMorningTasks() -> [ContextualTask] {
        return getTasksForTimeWindow(startHour: 6, endHour: 12)
    }
    
    func getAfternoonTasks() -> [ContextualTask] {
        return getTasksForTimeWindow(startHour: 12, endHour: 18)
    }
    
    func getEveningTasks() -> [ContextualTask] {
        return getTasksForTimeWindow(startHour: 18, endHour: 22)
    }
    
    // MARK: - Enhanced Internal Access Methods
    
    /// Get merged tasks including routines (internal access only)
    internal func getMergedTasksInternal() -> [ContextualTask] {
        return getTodaysTasksInternal() + dailyRoutines
    }
    
    /// Get tasks for specific building (internal access only)
    internal func getTasksForBuildingInternal(_ buildingId: String) -> [ContextualTask] {
        return getTodaysTasksInternal().filter { $0.buildingId == buildingId }
    }
    
    /// Get routine tasks for specific building (internal access only)
    internal func getRoutinesForBuildingInternal(_ buildingId: String) -> [ContextualTask] {
        return dailyRoutines.filter { $0.buildingId == buildingId }
    }
    
    // MARK: - Refresh Methods
    
    func forceRefresh() async {
        await refreshContextWithManagers()
        contextRefreshSubject.send()
    }
    
    func refreshWithWeather() async {
        // Refresh context first
        await refreshContextWithManagers()
        
        // Load weather data using existing WeatherManager
        if !assignedBuildings.isEmpty {
            await WeatherManager.shared.loadWeatherForBuildings(assignedBuildings)
        }
        
        contextRefreshSubject.send()
    }
    
    // MARK: - Emergency Recovery (Simplified)
    
    func triggerEmergencyRefresh() async {
        print("🚨 Emergency refresh triggered")
        
        // Clear cached data
        await MainActor.run {
            self.assignedBuildings = []
            self.todaysTasks = []
            self.dailyRoutines = []
            self.lastError = nil
        }
        
        // Force reload using existing managers
        await refreshContextWithManagers()
        
        contextRefreshSubject.send()
        print("✅ Emergency refresh completed")
    }
}
