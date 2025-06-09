//
//  TimeBasedTaskFilter.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  TimeBasedTaskFilter.swift
//  FrancoSphere
//
//  In-memory task filtering by time - no database access
//  LOCATION: Place this file in /Services/ folder
//

import Foundation

struct TimeBasedTaskFilter {
    
    // MARK: - Time Window Filtering
    
    static func tasksForCurrentWindow(
        tasks: [ContextualTask],
        currentTime: Date = Date(),
        windowHours: Int = 2
    ) -> [ContextualTask] {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        let windowEndMinutes = currentTotalMinutes + (windowHours * 60)
        
        return tasks.filter { task in
            guard let startTime = task.startTime else { return true } // No time = always visible
            
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else { return true }
            
            let taskTotalMinutes = hour * 60 + minute
            
            // Show tasks within the time window
            return taskTotalMinutes >= currentTotalMinutes && 
                   taskTotalMinutes <= windowEndMinutes
        }
    }
    
    // MARK: - Task Categorization
    
    static func categorizeByTimeStatus(
        tasks: [ContextualTask],
        currentTime: Date = Date()
    ) -> (upcoming: [ContextualTask], current: [ContextualTask], overdue: [ContextualTask]) {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: currentTime)
        let currentMinute = calendar.component(.minute, from: currentTime)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        var upcoming: [ContextualTask] = []
        var current: [ContextualTask] = []
        var overdue: [ContextualTask] = []
        
        for task in tasks {
            guard let startTime = task.startTime else {
                current.append(task) // No time = current
                continue
            }
            
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else {
                current.append(task)
                continue
            }
            
            let taskTotalMinutes = hour * 60 + minute
            
            if task.status == "completed" {
                // Completed tasks don't go in any active category
                continue
            } else if taskTotalMinutes < currentTotalMinutes - 30 {
                // More than 30 minutes past start time
                overdue.append(task)
            } else if taskTotalMinutes <= currentTotalMinutes + 30 {
                // Within 30 minutes of now
                current.append(task)
            } else {
                // Future tasks
                upcoming.append(task)
            }
        }
        
        return (upcoming, current, overdue)
    }
    
    // MARK: - Worker Schedule Filtering
    
    static func filterByWorkerSchedule(
        tasks: [ContextualTask],
        workerStartHour: Int = 6,
        workerEndHour: Int = 15
    ) -> [ContextualTask] {
        tasks.filter { task in
            guard let startTime = task.startTime else { return true }
            
            let components = startTime.split(separator: ":")
            guard components.count >= 1,
                  let hour = Int(components[0]) else { return true }
            
            return hour >= workerStartHour && hour < workerEndHour
        }
    }
    
    // MARK: - Smart Suggestions
    
    static func nextSuggestedTask(
        from tasks: [ContextualTask],
        currentTime: Date = Date()
    ) -> ContextualTask? {
        let categorized = categorizeByTimeStatus(tasks: tasks, currentTime: currentTime)
        
        // Priority order:
        // 1. Overdue urgent tasks
        // 2. Current urgent tasks
        // 3. Any overdue task
        // 4. Any current task
        // 5. Next upcoming task
        
        if let urgentOverdue = categorized.overdue.first(where: { 
            $0.urgencyLevel.lowercased() == "urgent" || $0.urgencyLevel.lowercased() == "high" 
        }) {
            return urgentOverdue
        }
        
        if let urgentCurrent = categorized.current.first(where: { 
            $0.urgencyLevel.lowercased() == "urgent" || $0.urgencyLevel.lowercased() == "high" 
        }) {
            return urgentCurrent
        }
        
        if let firstOverdue = categorized.overdue.first {
            return firstOverdue
        }
        
        if let firstCurrent = categorized.current.first {
            return firstCurrent
        }
        
        return categorized.upcoming.first
    }
    
    // MARK: - Time-Based Task Scheduler Integration
    
    static func getTasksForTimeSlot(
        tasks: [ContextualTask],
        hour: Int,
        minute: Int = 0,
        windowMinutes: Int = 60
    ) -> [ContextualTask] {
        let targetTotalMinutes = hour * 60 + minute
        let windowStart = targetTotalMinutes
        let windowEnd = targetTotalMinutes + windowMinutes
        
        return tasks.filter { task in
            guard let startTime = task.startTime else { return false }
            
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let taskHour = Int(components[0]),
                  let taskMinute = Int(components[1]) else { return false }
            
            let taskTotalMinutes = taskHour * 60 + taskMinute
            
            return taskTotalMinutes >= windowStart && taskTotalMinutes < windowEnd
        }
    }
    
    // MARK: - Edwin-Specific Schedule
    
    static func getEdwinMorningTasks(tasks: [ContextualTask]) -> [ContextualTask] {
        // Edwin works 06:00-15:00, focusing on morning routine
        let morningTasks = filterByWorkerSchedule(
            tasks: tasks,
            workerStartHour: 6,
            workerEndHour: 11  // Morning focus
        )
        
        // Sort by building priority (Stuyvesant Park first)
        return morningTasks.sorted { task1, task2 in
            // Stuyvesant Park (building 17) has priority
            if task1.buildingId == "17" && task2.buildingId != "17" {
                return true
            } else if task1.buildingId != "17" && task2.buildingId == "17" {
                return false
            }
            
            // Then sort by start time
            if let time1 = task1.startTime, let time2 = task2.startTime {
                return time1 < time2
            }
            
            return task1.buildingName < task2.buildingName
        }
    }
    
    // MARK: - Time Formatting Helpers
    
    static func formatTimeString(_ time: String?) -> String {
        guard let time = time else { return "No time set" }
        
        let components = time.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return time }
        
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }
    
    static func timeUntilTask(_ task: ContextualTask) -> String? {
        guard let startTime = task.startTime else { return nil }
        
        let components = startTime.split(separator: ":")
        guard components.count == 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let taskMinutes = hour * 60 + minute
        let currentMinutes = currentHour * 60 + currentMinute
        let difference = taskMinutes - currentMinutes
        
        if difference < 0 {
            let overdue = abs(difference)
            if overdue < 60 {
                return "\(overdue) min overdue"
            } else {
                return "\(overdue / 60) hr \(overdue % 60) min overdue"
            }
        } else if difference == 0 {
            return "Now"
        } else if difference < 60 {
            return "In \(difference) min"
        } else {
            return "In \(difference / 60) hr \(difference % 60) min"
        }
    }
}