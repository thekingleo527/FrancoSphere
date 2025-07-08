//
//  DailyOpsReset.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import UIKit // Added for UIApplication
// FrancoSphere Types Import
// (This comment helps identify our import)


/// Manages the daily operations reset for the Franco Sphere system
class DailyOpsReset {
    static let shared = DailyOpsReset()
    
    /// Whether the system has been initialized
    private var isInitialized = false
    
    /// The date of the last reset
    private var lastResetDate: Date?
    
    /// Private initializer to prevent multiple instances
    private init() {
        // Load last reset date from UserDefaults if available
        // Fixed: Check if the key exists first before using double value
        if UserDefaults.standard.object(forKey: "lastResetTimeStamp") != nil {
            let lastResetTimeStamp = UserDefaults.standard.double(forKey: "lastResetTimeStamp")
            if lastResetTimeStamp > 0 {
                lastResetDate = Date(timeIntervalSince1970: lastResetTimeStamp)
            }
        }
    }
    
    /// Start the daily reset scheduler
    func start() {
        if isInitialized {
            return
        }
        
        isInitialized = true
        
        // Check if we need to do an immediate reset
        Task {
            await checkIfResetNeeded()
        }
        
        // Schedule the next reset
        scheduleReset()
        
        // Also listen for app coming to foreground, as the scheduled task
        // might not run if the app is in the background
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(appWillEnterForeground),
                                              name: UIApplication.willEnterForegroundNotification,
                                              object: nil)
    }
    
    /// Check if a reset is needed (i.e., if we've passed midnight since the last reset)
    private func checkIfResetNeeded() async {
        let calendar = Calendar.current
        
        // If we've never reset or if the last reset was before today, do a reset
        if lastResetDate == nil || !calendar.isDateInToday(lastResetDate!) {
            await performReset()
        }
    }
    
    /// Schedule the next reset at 12:01 AM
    private func scheduleReset() {
        // Calculate time until next reset (12:01 AM)
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = 0
        dateComponents.minute = 1
        dateComponents.second = 0
        
        guard let tomorrowReset = calendar.nextDate(
            after: Date(),
            matching: dateComponents,
            matchingPolicy: .nextTime
        ) else { return }
        
        let timeInterval = tomorrowReset.timeIntervalSince(Date())
        
        // Schedule the reset
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            Task {
                await self?.performReset()
                self?.scheduleReset() // Schedule next reset
            }
        }
    }
    
    /// Handle app coming to foreground
    @objc private func appWillEnterForeground() {
        Task {
            await checkIfResetNeeded()
        }
    }
    
    // MARK: - Reset Operations
    
    /// Perform the actual reset operations
    private func performReset() async {
        // Update the last reset date
        lastResetDate = Date()
        UserDefaults.standard.set(lastResetDate!.timeIntervalSince1970, forKey: "lastResetTimeStamp")
        
        // Reset building statuses
        await resetBuildingStatuses()
        
        // Mark unfinished tasks as missed
        await markMissedTasks()
        
        // Generate new tasks for today
        await generateNewTasks()
        
        // Post notification that daily ops have been reset
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("DailyOpsReset"), object: nil)
        }
        
        print("Daily operations reset performed at \(Date())")
    }
    
    /// Reset all building statuses to 'pending'
    private func resetBuildingStatuses() async {
        // BuildingStatusManager handles its own reset, but we trigger it here
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("BuildingStatusesReset"), object: nil)
        }
    }
    
    /// Mark unfinished tasks from yesterday as missed/overdue
    private func markMissedTasks() async {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let taskManager = TaskService.shared
        
        // Fixed: Use async access to BuildingRepository
        let allBuildings = await BuildingService.shared.allBuildings
        for building in allBuildings {
            // Fixed: Use async retrieveTasks call
            let buildingTasks = await taskManager.fetchTasksAsync(forBuilding: building.id, includePastTasks: true)
            let yesterdayTasks = buildingTasks.filter { task in
                Calendar.current.isDate(task.dueDate, inSameDayAs: yesterday)
            }
            
            for task in yesterdayTasks where !task.isComplete {
                // In a real app, we might update task status to "missed" in database
                // For now, we just log it
                print("Missed task: \(task.name) in building \(building.name)")
                
                // If this task is recurring, we should create the next occurrence
                if task.recurrence != .none {
                    // We'd create the next occurrence here
                    // This is handled by TaskManager when marking a task complete,
                    // but for missed tasks we might need special handling
                    if let nextTask = task.createNextOccurrence() {
                        _ = await taskManager.createTaskAsync(nextTask)
                    }
                }
            }
        }
    }
    
    /// Generate new daily and weekly tasks for today
    private func generateNewTasks() async {
        // For each building, schedule recurring tasks based on the current day
        // Fixed: Use async access to BuildingRepository
        let allBuildings = await BuildingService.shared.allBuildings
        for building in allBuildings {
            // Fixed: For now, we'll just generate weather-related tasks
            await generateWeatherRelatedTasks(for: building)
        }
    }
    
    /// Generate weather-related tasks for a building
    // Fixed: Use NamedCoordinate instead of NamedCoordinate
    private func generateWeatherRelatedTasks(for building: NamedCoordinate) async {
        // Check weather conditions and generate appropriate tasks
        // Fixed: Handle main actor isolation for WeatherDataAdapter
        let weatherTasks = await MainActor.run {
            let weatherAdapter = WeatherDataAdapter.shared
            return weatherAdapter.generateWeatherTasks(for: building)
        }
        
        if !weatherTasks.isEmpty {
            // Use the existing async method from TaskManager
            await TaskService.shared.createWeatherBasedTasksAsync(for: building.id, tasks: weatherTasks)
        }
    }
    
    /// Manually trigger a reset (for admin use)
    func manualReset() {
        Task {
            await performReset()
        }
    }
    
    /// Synchronous version for legacy compatibility
    func manualResetSync() {
        Task.detached {
            await self.performReset()
        }
    }
}

// MARK: - Extension for App Initialization
extension DailyOpsReset {
    /// Initialize and configure the daily reset system
    static func configure() {
        // Start the daily reset scheduler
        shared.start()
    }
}
