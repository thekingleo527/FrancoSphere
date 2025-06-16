//
//  TimeBasedTaskFilter.swift
//  FrancoSphere
//
//  🚀 PRIORITY 1 FIX: Extension Conflicts Eliminated
//  ✅ SINGLE SOURCE OF TRUTH for TaskProgress struct
//  ✅ Added CoreLocation import
//  ✅ REMOVED duplicate extensions - kept only as static methods
//  ✅ Fixed all parameter order issues
//  ⚠️  NO EXTENSIONS - only static methods to avoid conflicts with UpdatedDataLoading
//

import Foundation
import CoreLocation  // ✅ FIXED: Added missing import

struct TimeBasedTaskFilter {
    
    // ✅ MASTER TaskProgress Definition - DO NOT DUPLICATE ELSEWHERE
    struct TaskProgress {
        let hourlyDistribution: [Int: Int]
        let completedHours: Set<Int>
        let currentHour: Int
        let totalTasks: Int
        let completedTasks: Int
        
        // ✅ FIXED: Proper parameter order
        init(
            hourlyDistribution: [Int: Int],
            completedHours: Set<Int>,
            currentHour: Int,
            totalTasks: Int,
            completedTasks: Int
        ) {
            self.hourlyDistribution = hourlyDistribution
            self.completedHours = completedHours
            self.currentHour = currentHour
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
        }
    }
    
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
            guard let startTime = task.startTime else { return true }
            
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else { return true }
            
            let taskTotalMinutes = hour * 60 + minute
            
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
                current.append(task)
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
                continue
            } else if taskTotalMinutes < currentTotalMinutes - 30 {
                overdue.append(task)
            } else if taskTotalMinutes <= currentTotalMinutes + 30 {
                current.append(task)
            } else {
                upcoming.append(task)
            }
        }
        
        return (upcoming, current, overdue)
    }
    
    // MARK: - Smart Suggestions
    
    static func nextSuggestedTask(
        from tasks: [ContextualTask],
        currentTime: Date = Date()
    ) -> ContextualTask? {
        let categorized = categorizeByTimeStatus(tasks: tasks, currentTime: currentTime)
        
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
    
    // MARK: - Context-based Filtering
    
    static func tasksForContext(
        all tasks: [ContextualTask],
        clockedInBuildingId: String? = nil,
        userLocation: CLLocation? = nil,  // ✅ FIXED: CLLocation now available
        now: Date = Date()
    ) -> FilteredTaskResult {
        
        let contextBuildingId: String?
        let contextBuildingName: String?
        let isFilteredByBuilding: Bool
        
        if let clockedId = clockedInBuildingId {
            contextBuildingId = clockedId
            contextBuildingName = tasks.first { $0.buildingId == clockedId }?.buildingName
            isFilteredByBuilding = true
        } else {
            contextBuildingId = nil
            contextBuildingName = nil
            isFilteredByBuilding = false
        }
        
        var filteredTasks: [ContextualTask] = []
        
        if isFilteredByBuilding, let buildingId = contextBuildingId {
            filteredTasks = tasks.filter { $0.buildingId == buildingId }
            
            let urgentFromOthers = tasks.filter { task in
                task.buildingId != buildingId &&
                task.status != "completed" &&
                (isTaskOverdue(task, now: now) ||
                 task.urgencyLevel.lowercased() == "urgent" ||
                 task.urgencyLevel.lowercased() == "high")
            }
            
            filteredTasks.append(contentsOf: urgentFromOthers)
        } else {
            filteredTasks = tasks
        }
        
        let categorized = categorizeByTimeStatus(tasks: filteredTasks, currentTime: now)
        let allTasksCategorized = categorizeByTimeStatus(tasks: tasks, currentTime: now)
        
        let sortedTasks = sortFilteredTasks(
            overdue: categorized.overdue,
            current: categorized.current,
            upcoming: categorized.upcoming
        )
        
        let completedCount = tasks.filter { $0.status == "completed" }.count
        
        return FilteredTaskResult(
            tasks: sortedTasks,
            totalCount: tasks.count,
            overdueCount: allTasksCategorized.overdue.count,
            completedCount: completedCount,
            currentCount: categorized.current.count,
            upcomingCount: categorized.upcoming.count,
            contextBuildingName: contextBuildingName,
            contextBuildingId: contextBuildingId,
            isFilteredByBuilding: isFilteredByBuilding
        )
    }
    
    // ✅ FIXED: TaskProgress return type now unambiguous
    static func calculateTaskProgress(
        tasks: [ContextualTask],
        now: Date = Date()
    ) -> TaskProgress {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        var hourlyDistribution: [Int: Int] = [:]
        var completedHours: Set<Int> = []
        
        for task in tasks {
            guard let startTime = task.startTime else { continue }
            
            let components = startTime.split(separator: ":")
            guard components.count >= 2,
                  let hour = Int(components[0]) else { continue }
            
            hourlyDistribution[hour, default: 0] += 1
            
            if task.status == "completed" {
                completedHours.insert(hour)
            }
        }
        
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.status == "completed" }.count
        
        // ✅ FIXED: Correct parameter order
        return TaskProgress(
            hourlyDistribution: hourlyDistribution,
            completedHours: completedHours,
            currentHour: currentHour,
            totalTasks: totalTasks,
            completedTasks: completedTasks
        )
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
    
    // MARK: - 🚀 STATIC TIME FORMATTING HELPERS (NOT EXTENSIONS - AVOIDS CONFLICTS)
    
    /// Format time string to 12-hour format
    /// This is a STATIC method, not an extension, to avoid conflicts with UpdatedDataLoading
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
    
    /// Calculate time until task
    /// This is a STATIC method, not an extension, to avoid conflicts with UpdatedDataLoading
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
    
    // MARK: - Helper Methods
    
    private static func isTaskOverdue(_ task: ContextualTask, now: Date) -> Bool {
        guard task.status != "completed",
              let startTime = task.startTime else { return false }
        
        let components = startTime.split(separator: ":")
        guard components.count >= 2,
              let hour = Int(components[0]),
              let minute = Int(components[1]) else { return false }
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let taskMinutes = hour * 60 + minute
        let currentMinutes = currentHour * 60 + currentMinute
        
        return taskMinutes < currentMinutes - 30
    }
    
    private static func sortFilteredTasks(
        overdue: [ContextualTask],
        current: [ContextualTask],
        upcoming: [ContextualTask]
    ) -> [ContextualTask] {
        var result: [ContextualTask] = []
        
        let sortedOverdue = overdue.sorted { task1, task2 in
            if task1.urgencyLevel != task2.urgencyLevel {
                return urgencyPriority(task1.urgencyLevel) > urgencyPriority(task2.urgencyLevel)
            }
            return (task1.startTime ?? "") < (task2.startTime ?? "")
        }
        
        let sortedCurrent = current.sorted { task1, task2 in
            if task1.urgencyLevel != task2.urgencyLevel {
                return urgencyPriority(task1.urgencyLevel) > urgencyPriority(task2.urgencyLevel)
            }
            return (task1.startTime ?? "") < (task2.startTime ?? "")
        }
        
        let sortedUpcoming = upcoming.sorted { task1, task2 in
            return (task1.startTime ?? "") < (task2.startTime ?? "")
        }
        
        result.append(contentsOf: sortedOverdue)
        result.append(contentsOf: sortedCurrent)
        result.append(contentsOf: sortedUpcoming)
        
        return result
    }
    
    private static func urgencyPriority(_ urgency: String) -> Int {
        switch urgency.lowercased() {
        case "urgent", "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 0
        }
    }
}

// MARK: - 📝 PRIORITY 1 FIX SUMMARY
/*
 ✅ ELIMINATED EXTENSION CONFLICTS:
 
 1. formatTimeString() - Now STATIC method only (not extension)
 2. timeUntilTask() - Now STATIC method only (not extension)
 3. All helper methods are private static
 4. NO extension declarations on ContextualTask or other types
 5. Preserved all functionality as static methods
 
 🎯 THIS RESOLVES THE FOLLOWING COMPILATION ERRORS:
 - /Services/TimeBasedTaskFilter.swift:294:17 Invalid redeclaration of 'formatTimeString'
 - /Services/TimeBasedTaskFilter.swift:308:17 Invalid redeclaration of 'timeUntilTask'
 
 🔄 NEXT: Fix UpdatedDataLoading.swift to remove its duplicate extensions
 */
