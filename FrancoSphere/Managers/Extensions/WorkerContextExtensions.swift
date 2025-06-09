//
//  WorkerContextExtensions.swift
//  FrancoSphere
//
//  Extensions to WorkerContextEngine for repository pattern and refresh management
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
        static var lastRefreshTime = "lastRefreshTime"  // This was missing!
    }
    
    // MARK: - Published Properties
    
    var lastRefreshTime: Date {
        get { objc_getAssociatedObject(self, &AssociatedKeys.lastRefreshTime) as? Date ?? Date() }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastRefreshTime, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
    
    // MARK: - Repository Integration
    
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
            return todaysTasks
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
            tasks: todaysTasks,
            windowHours: windowHours
        )
    }
    
    func getCategorizedTasks() -> (upcoming: [ContextualTask], current: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(tasks: todaysTasks)
    }
    
    func getNextSuggestedTask() -> ContextualTask? {
        TimeBasedTaskFilter.nextSuggestedTask(from: todaysTasks)
    }
    
    func getEdwinMorningTasks() -> [ContextualTask] {
        guard currentWorker?.workerId == "3" else { return todaysTasks }
        return TimeBasedTaskFilter.getEdwinMorningTasks(tasks: todaysTasks)
    }
    
    // MARK: - Weather Integration
    
    func getWeatherAdaptedTasks() async -> [(task: ContextualTask, adaptation: WeatherTaskAdaptation)] {
        var adaptations: [(ContextualTask, WeatherTaskAdaptation)] = []
        
        // Get unique building IDs
        let buildingIds = Set(todaysTasks.map { $0.buildingId })
        
        // Note: WeatherService in your project doesn't have getCurrentWeather method
        // It has fetchWeather method. For now, we'll create a simple adaptation
        for task in todaysTasks {
            // Simple weather adaptation logic
            let isOutdoorTask = task.category.lowercased().contains("clean") &&
                               !task.name.lowercased().contains("indoor")
            
            let adaptation = WeatherTaskAdaptation(
                task: task,
                status: isOutdoorTask ? .weatherDependent : .normal,
                reason: isOutdoorTask ? "Check weather before starting" : nil
            )
            
            adaptations.append((task, adaptation))
        }
        
        return adaptations
    }
    
    // MARK: - Enhanced Refresh
    
    func refreshContextEnhanced() async {
        guard let workerId = currentWorker?.workerId else { return }
        
        // Update loading state
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            // Use repository if available
            if let repository = taskRepository {
                // Since loadWorkerBuildings is private, we need to use loadWorkerContext
                await loadWorkerContext(workerId: workerId)
                
                // Then use repository for additional data
                let upcoming = try await repository.upcomingTasks(for: workerId, days: 7)
                
                await MainActor.run {
                    self.upcomingTasks = upcoming
                    self.lastRefreshTime = Date()
                }
            } else {
                // Fallback to original method
                await loadWorkerContext(workerId: workerId)
            }
            
            // Notify subscribers
            contextRefreshSubject.send()
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
        }
    }
}

// MARK: - Weather Task Adaptation Model

struct WeatherTaskAdaptation {
    let task: ContextualTask
    let status: AdaptationStatus
    let reason: String?
    
    enum AdaptationStatus {
        case normal
        case weatherDependent
        case postponed
        case rescheduled
    }
}
