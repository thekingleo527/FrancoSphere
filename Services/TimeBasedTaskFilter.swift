// UPDATED: Using centralized TypeRegistry for all types
//
//  TimeBasedTaskFilter.swift - PHASE-2 WORKER-SPECIFIC FILTERING
//  FrancoSphere
//
//  ✅ PATCH P2-08-V2: Worker-specific filtering based on real CSV schedules
//  ✅ Single source of truth for TaskProgress struct
//  ✅ Real-world worker schedules and responsibilities
//  ✅ Enhanced worker-specific filtering logic
//  ✅ Static methods to avoid extension conflicts
//

import Foundation
import CoreLocation

struct TimeBasedTaskFilter {
    
    // ✅ MASTER TaskProgress Definition - Single source of truth
    struct TaskProgress {
        let hourlyDistribution: [Int: Int]
        let completedHours: Set<Int>
        let currentHour: Int
        let totalTasks: Int
        let completedTasks: Int
        
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
    
    // MARK: - ✅ PHASE-2: Worker-Specific Task Filtering
    
    /// Get worker-specific tasks based on real CSV schedule data
    static func getWorkerSpecificTasks(tasks: [ContextualTask], workerId: String) -> [ContextualTask] {
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Worker-specific schedule logic based on real data
        switch workerId {
        case "1": // Greg Hutson - Day shift (reduced hours)
            return filterTasksByTimeWindow(tasks: tasks, startHour: 7, endHour: 15, currentHour: currentHour)
            
        case "2": // Edwin Lema - Early morning shift
            return filterTasksByTimeWindow(tasks: tasks, startHour: 6, endHour: 15, currentHour: currentHour)
            
        case "4": // Kevin Dutan - Extended day + garbage (Jose's duties)
            return filterTasksByTimeWindow(tasks: tasks, startHour: 6, endHour: 17, currentHour: currentHour)
            
        case "5": // Mercedes Inamagua - Split shift
            return filterMercedesSplitShift(tasks: tasks, currentHour: currentHour)
            
        case "6": // Luis Lopez - Standard day
            return filterTasksByTimeWindow(tasks: tasks, startHour: 7, endHour: 16, currentHour: currentHour)
            
        case "7": // Angel Guirachocha - Day + evening garbage
            return filterAngelExtendedShift(tasks: tasks, currentHour: currentHour)
            
        case "8": // Shawn Magloire - Flexible (Rubin Museum focus)
            return filterShawnFlexibleSchedule(tasks: tasks, currentHour: currentHour)
            
        default:
            return getStandardDayTasks(tasks: tasks, currentHour: currentHour)
        }
    }
    
    /// Filter tasks by time window with current time awareness
    private static func filterTasksByTimeWindow(tasks: [ContextualTask], startHour: Int, endHour: Int, currentHour: Int) -> [ContextualTask] {
        return tasks.filter { task in
            // Include all tasks within worker's shift hours
            guard let taskStartTime = task.startTime,
                  let taskHour = parseHourFromTimeString(taskStartTime) else {
                return true // Include tasks without specific times
            }
            
            // Task is within worker's shift window
            return taskHour >= startHour && taskHour < endHour
        }.sorted { task1, task2 in
            // Prioritize tasks based on current time proximity
            guard let time1 = task1.startTime, let hour1 = parseHourFromTimeString(time1),
                  let time2 = task2.startTime, let hour2 = parseHourFromTimeString(time2) else {
                return task1.name < task2.name
            }
            
            let diff1 = abs(hour1 - currentHour)
            let diff2 = abs(hour2 - currentHour)
            return diff1 < diff2
        }
    }
    
    /// Mercedes split shift filter (6:30-10:30 AM)
    private static func filterMercedesSplitShift(tasks: [ContextualTask], currentHour: Int) -> [ContextualTask] {
        return tasks.filter { task in
            guard let taskStartTime = task.startTime,
                  let taskHour = parseHourFromTimeString(taskStartTime) else {
                return currentHour <= 10 // Default to morning window
            }
            
            // Mercedes works 6:30-10:30 AM
            return taskHour >= 6 && taskHour < 11
        }
    }
    
    /// Angel extended shift (day + evening garbage)
    private static func filterAngelExtendedShift(tasks: [ContextualTask], currentHour: Int) -> [ContextualTask] {
        return tasks.filter { task in
            guard let taskStartTime = task.startTime,
                  let taskHour = parseHourFromTimeString(taskStartTime) else {
                return true
            }
            
            // Angel: 6 AM - 5 PM with garbage duties
            return (taskHour >= 6 && taskHour < 17) ||
                   task.category.lowercased().contains("garbage") ||
                   task.category.lowercased().contains("waste")
        }
    }
    
    /// Shawn flexible schedule (Rubin Museum + admin)
    private static func filterShawnFlexibleSchedule(tasks: [ContextualTask], currentHour: Int) -> [ContextualTask] {
        return tasks.filter { task in
            // Shawn handles Rubin Museum (building 14) and admin tasks
            return task.buildingId == "14" ||
                   task.category.lowercased().contains("admin") ||
                   task.category.lowercased().contains("inspection")
        }
    }
    
    /// Standard day tasks for generic workers
    private static func getStandardDayTasks(tasks: [ContextualTask], currentHour: Int) -> [ContextualTask] {
        return filterTasksByTimeWindow(tasks: tasks, startHour: 8, endHour: 16, currentHour: currentHour)
    }
    
    /// Enhanced task categorization by worker and current time
    static func categorizeTasksByWorkerAndTime(
        tasks: [ContextualTask],
        workerId: String
    ) -> (immediate: [ContextualTask], upcoming: [ContextualTask], later: [ContextualTask]) {
        
        let workerTasks = getWorkerSpecificTasks(tasks: tasks, workerId: workerId)
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        var immediate: [ContextualTask] = []
        var upcoming: [ContextualTask] = []
        var later: [ContextualTask] = []
        
        for task in workerTasks {
            guard let startTime = task.startTime,
                  let taskHour = parseHourFromTimeString(startTime) else {
                immediate.append(task) // Tasks without time are immediate
                continue
            }
            
            let hourDiff = taskHour - currentHour
            
            switch hourDiff {
            case -2...1:        // Within 2 hours past to 1 hour future
                immediate.append(task)
            case 2...4:         // 2-4 hours future
                upcoming.append(task)
            default:            // More than 4 hours away
                later.append(task)
            }
        }
        
        return (immediate, upcoming, later)
    }
    
    /// Parse hour from time string helper
    private static func parseHourFromTimeString(_ timeString: String) -> Int? {
        let components = timeString.split(separator: ":")
        guard let hourString = components.first,
              let hour = Int(hourString) else {
            return nil
        }
        return hour
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
        userLocation: CLLocation? = nil,
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
    
    // MARK: - Task Progress Calculation
    
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
        
        return TaskProgress(
            hourlyDistribution: hourlyDistribution,
            completedHours: completedHours,
            currentHour: currentHour,
            totalTasks: totalTasks,
            completedTasks: completedTasks
        )
    }
    
    // MARK: - Edwin-Specific Schedule (Legacy support)
    
    static func getEdwinMorningTasks(tasks: [ContextualTask]) -> [ContextualTask] {
        return getWorkerSpecificTasks(tasks: tasks, workerId: "2")
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
    
    // MARK: - Static Time Formatting Helpers
    
    /// Format time string to 12-hour format
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
        case "urgent", "high":
            return 3
        case "medium":
            return 2
        case "low":
            return 1
        default:
            return 0
        }
    }
}

// MARK: - ✅ PHASE-2: Deprecated Methods (Legacy Support)

extension TimeBasedTaskFilter {
    
    @available(*, deprecated, message: "Use getWorkerSpecificTasks for worker-aware filtering")
    static func getEdwinMorningTasks_Legacy(tasks: [ContextualTask]) -> [ContextualTask] {
        return getWorkerSpecificTasks(tasks: tasks, workerId: "2")
    }
    
    @available(*, deprecated, message: "Use categorizeTasksByWorkerAndTime for worker-specific categorization")
    static func categorizeByTimeStatus_Legacy(
        tasks: [ContextualTask],
        currentTime: Date = Date()
    ) -> (upcoming: [ContextualTask], current: [ContextualTask], overdue: [ContextualTask]) {
        return categorizeByTimeStatus(tasks: tasks, currentTime: currentTime)
    }
}

// MARK: - 📝 PRIORITY 1 FIX SUMMARY
/*
 ✅ SYNTAX ERROR FIXED:
 
 1. Removed orphaned case statements at end of file that were outside any function
 2. Maintained complete functionality with proper urgencyPriority function
 3. All static methods preserved
 4. No extension conflicts
 5. Ready for Phase 2 implementation
 
 🎯 FILE IS NOW COMPILATION READY
 */
