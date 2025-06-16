//
//  WorkerContextExtensions.swift
//  FrancoSphere
//
//  ✅ CLEAN VERSION - All compilation errors resolved
//  ✅ FIXED: Date/String conversion issues for ContextualTask properties
//  ✅ FIXED: Removed duplicate WeatherTaskAdaptation declaration
//  ✅ FIXED: Removed duplicate getEdwinMorningTasks declaration
//  ✅ FIXED: Removed duplicate TaskRepository declaration
//  ✅ FIXED: Added missing lastError property handling
//  ✅ FIXED: Proper String time property conversions
//

import Foundation
import Combine

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
        static var taskRepository = "taskRepository"
        static var contextRefreshSubject = "contextRefreshSubject"
        static var lastRefreshTime = "lastRefreshTime"
        static var lastError = "lastError" // ✅ ADDED: Missing key
    }
    
    // MARK: - ✅ ADDED: Missing lastError property
    
    var lastError: Error? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastError) as? Error }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastError, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Published Properties
    
    var lastRefreshTime: Date {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastRefreshTime) as? Date ?? Date() }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastRefreshTime, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Repository Integration (references external TaskRepository)
    
    private var taskRepository: TaskRepository? {
        get { objc_getAssociatedObject(self, &AssociatedKeys.taskRepository) as? TaskRepository }
        set { objc_setAssociatedObject(self, &AssociatedKeys.taskRepository, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    func configure(with repository: TaskRepository) {
        self.taskRepository = repository
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
    
    // MARK: - Enhanced Load Methods
    
    func loadWorkerTasksWithRepository(_ workerId: String) async throws -> [ContextualTask] {
        guard let repository = taskRepository else {
            // Since loadWorkerTasksForToday is private, we need to reload context
            // or make that method internal/public in WorkerContextEngine
            await loadWorkerContext(workerId: workerId)
            return getTodaysTasks() // ✅ FIXED: Use public accessor method
        }
        
        // Get both regular and routine tasks
        async let regularTasks = repository.tasks(for: workerId)
        async let routineTasks = repository.routineTasks(for: workerId)
        
        let (regular, routine) = try await (regularTasks, routineTasks)
        
        // Combine and deduplicate
        var allTasks = regular + routine
        
        // Remove duplicates based on id
        var seen = Set<String>()
        allTasks = allTasks.filter { task in
            if seen.contains(task.id) {
                return false
            }
            seen.insert(task.id)
            return true
        }
        
        return allTasks.sorted { task1, task2 in
            if let time1 = task1.startTime, let time2 = task2.startTime {
                return time1 < time2
            }
            return task1.buildingName < task2.buildingName
        }
    }
    
    // MARK: - Filtered Task Access
    
    func getTimeFilteredTasks(windowHours: Int = 2) -> [ContextualTask] {
        TimeBasedTaskFilter.tasksForCurrentWindow(
            tasks: getTodaysTasks(), // ✅ FIXED: Use public accessor
            windowHours: windowHours
        )
    }
    
    func getCategorizedTasks() -> (upcoming: [ContextualTask], current: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(tasks: getTodaysTasks()) // ✅ FIXED: Use public accessor
    }
    
    func getNextSuggestedTask() -> ContextualTask? {
        TimeBasedTaskFilter.nextSuggestedTask(from: getTodaysTasks()) // ✅ FIXED: Use public accessor
    }
    
    // MARK: - ✅ FIXED: Weather Integration with String Time Handling
    
    func getTasksAffectedByWeather(_ weatherCondition: String) -> [ContextualTask] {
        let allTasks = getTodaysTasks() // ✅ FIXED: Use public accessor
        
        return allTasks.filter { task in
            let isOutdoorTask = task.category.lowercased().contains("clean") ||
                               task.category.lowercased().contains("maintenance") ||
                               task.name.lowercased().contains("sidewalk") ||
                               task.name.lowercased().contains("trash") ||
                               task.name.lowercased().contains("roof")
            
            let isWeatherSensitive = weatherCondition.lowercased().contains("rain") ||
                                   weatherCondition.lowercased().contains("snow") ||
                                   weatherCondition.lowercased().contains("storm")
            
            return isOutdoorTask && isWeatherSensitive
        }
    }
    
    func adaptTasksForWeather(_ tasks: [ContextualTask], weatherCondition: String) -> [ContextualTask] {
        return tasks.map { task in
            var adaptedTask = task
            
            if weatherCondition.lowercased().contains("rain") {
                // ✅ FIXED: Handle String time properties properly
                adaptedTask = adaptTaskForRain(task)
            } else if weatherCondition.lowercased().contains("snow") {
                adaptedTask = adaptTaskForSnow(task)
            } else if weatherCondition.lowercased().contains("storm") {
                adaptedTask = adaptTaskForStorm(task)
            }
            
            return adaptedTask
        }
    }
    
    // ✅ FIXED: Individual weather adaptation methods with proper String time handling
    
    private func adaptTaskForRain(_ task: ContextualTask) -> ContextualTask {
        var adaptedTask = task
        
        let isOutdoor = task.name.lowercased().contains("sidewalk") ||
                       task.name.lowercased().contains("trash") ||
                       task.name.lowercased().contains("exterior")
        
        if isOutdoor {
            // Convert string time to components for manipulation
            if let startTime = task.startTime {
                let delayedTime = delayTimeString(startTime, byMinutes: 60) // ✅ FIXED: String manipulation
                adaptedTask = ContextualTask(
                    id: task.id,
                    name: task.name + " (Rain Delayed)",
                    buildingId: task.buildingId,
                    buildingName: task.buildingName,
                    category: task.category,
                    startTime: delayedTime, // ✅ FIXED: String type
                    endTime: task.endTime,
                    recurrence: task.recurrence,
                    skillLevel: task.skillLevel,
                    status: task.status,
                    urgencyLevel: "medium"
                )
            }
        }
        
        return adaptedTask
    }
    
    private func adaptTaskForSnow(_ task: ContextualTask) -> ContextualTask {
        var adaptedTask = task
        
        let requiresSnowClearance = task.name.lowercased().contains("sidewalk") ||
                                   task.name.lowercased().contains("entrance") ||
                                   task.name.lowercased().contains("walkway")
        
        if requiresSnowClearance {
            if let startTime = task.startTime {
                let earlierTime = advanceTimeString(startTime, byMinutes: -30) // ✅ FIXED: String manipulation
                adaptedTask = ContextualTask(
                    id: task.id,
                    name: "Snow Clearance + " + task.name,
                    buildingId: task.buildingId,
                    buildingName: task.buildingName,
                    category: task.category,
                    startTime: earlierTime, // ✅ FIXED: String type
                    endTime: task.endTime,
                    recurrence: task.recurrence,
                    skillLevel: task.skillLevel,
                    status: task.status,
                    urgencyLevel: "high"
                )
            }
        }
        
        return adaptedTask
    }
    
    private func adaptTaskForStorm(_ task: ContextualTask) -> ContextualTask {
        var adaptedTask = task
        
        let isOutdoor = task.name.lowercased().contains("roof") ||
                       task.name.lowercased().contains("exterior") ||
                       task.name.lowercased().contains("sidewalk")
        
        if isOutdoor {
            // Postpone outdoor tasks during storms
            if let startTime = task.startTime {
                let postponedTime = delayTimeString(startTime, byMinutes: 180) // ✅ FIXED: String manipulation
                adaptedTask = ContextualTask(
                    id: task.id,
                    name: task.name + " (Storm Postponed)",
                    buildingId: task.buildingId,
                    buildingName: task.buildingName,
                    category: task.category,
                    startTime: postponedTime, // ✅ FIXED: String type
                    endTime: task.endTime,
                    recurrence: task.recurrence,
                    skillLevel: task.skillLevel,
                    status: task.status,
                    urgencyLevel: "low"
                )
            }
        }
        
        return adaptedTask
    }
    
    // MARK: - ✅ FIXED: String Time Manipulation Helpers
    
    private func delayTimeString(_ timeString: String, byMinutes minutes: Int) -> String {
        return adjustTimeString(timeString, byMinutes: minutes)
    }
    
    private func advanceTimeString(_ timeString: String, byMinutes minutes: Int) -> String {
        return adjustTimeString(timeString, byMinutes: minutes)
    }
    
    private func adjustTimeString(_ timeString: String, byMinutes minutes: Int) -> String {
        // Parse "HH:mm" format
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else {
            return timeString // Return original if can't parse
        }
        
        // Convert to total minutes
        var totalMinutes = hour * 60 + minute
        totalMinutes += minutes
        
        // Handle day overflow/underflow
        if totalMinutes < 0 {
            totalMinutes = 1440 + (totalMinutes % 1440) // Wrap to previous day
        }
        totalMinutes = totalMinutes % 1440 // Wrap to next day if over 24 hours
        
        // Convert back to hour:minute
        let newHour = totalMinutes / 60
        let newMinute = totalMinutes % 60
        
        return String(format: "%02d:%02d", newHour, newMinute)
    }
    
    // ✅ FIXED: Get time difference between two time strings (not Date objects)
    private func getTimeDifferenceInMinutes(from startTime: String, to endTime: String) -> Int {
        let startComponents = startTime.split(separator: ":")
        let endComponents = endTime.split(separator: ":")
        
        guard startComponents.count == 2, endComponents.count == 2,
              let startHour = Int(startComponents[0]), let startMinute = Int(startComponents[1]),
              let endHour = Int(endComponents[0]), let endMinute = Int(endComponents[1]) else {
            return 0
        }
        
        let startTotalMinutes = startHour * 60 + startMinute
        let endTotalMinutes = endHour * 60 + endMinute
        
        return endTotalMinutes - startTotalMinutes
    }
}

// MARK: - ✅ REMOVED: All duplicate declarations to avoid conflicts

// NOTE: WeatherTaskAdaptation is only declared in ContextualTask.swift
// NOTE: getEdwinMorningTasks is only declared in TimeBasedTaskFilter.swift
// NOTE: TaskRepository protocol is only declared in WorkerContextEngine.swift
// NOTE: All extension methods for ContextualTask and TimeBasedTaskFilter are in their respective files

// MARK: - Error Handling Extensions

extension WorkerContextEngine {
    
    func setError(_ error: Error) {
        self.lastError = error
        self.error = error
    }
    
    func clearError() {
        self.lastError = nil
        self.error = nil
    }
    
    func hasRecentError(withinMinutes minutes: Int = 5) -> Bool {
        guard lastError != nil else { return false }
        
        let timeSinceLastRefresh = Date().timeIntervalSince(lastRefreshTime)
        return timeSinceLastRefresh < TimeInterval(minutes * 60)
    }
}

// MARK: - Context Validation Extensions

extension WorkerContextEngine {
    
    func validateContext() -> Bool {
        guard let worker = currentWorker else {
            setError(DatabaseError.invalidData("No current worker"))
            return false
        }
        
        let buildings = getAssignedBuildings()
        if buildings.isEmpty {
            setError(DatabaseError.invalidData("No assigned buildings for worker \(worker.workerId)"))
            return false
        }
        
        return true
    }
    
    func contextSummary() -> String {
        let worker = currentWorker?.workerName ?? "Unknown"
        let buildingCount = getBuildingsCount()
        let taskCount = getTasksCount()
        let pendingCount = getPendingTasksCount()
        
        return "Worker: \(worker), Buildings: \(buildingCount), Tasks: \(taskCount) (\(pendingCount) pending)"
    }
}

// MARK: - Time-Based Extensions

extension WorkerContextEngine {
    
    func getTasksForTimeWindow(startHour: Int, endHour: Int) -> [ContextualTask] {
        let allTasks = getTodaysTasks()
        
        return allTasks.filter { task in
            guard let startTime = task.startTime else { return false }
            
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
}
