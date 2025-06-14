import Foundation
import Combine

// MARK: - Building Collection Schedule Helper
class BuildingCollectionScheduleHelper {
    static func garbageCollectionDays(for building: FrancoSphere.NamedCoordinate) -> [Int] {
        switch building.id {
        case "1", "2", "3":
            return [1, 4] // Monday and Thursday
        case "4", "5", "6":
            return [2, 5] // Tuesday and Friday
        case "7", "8", "9":
            return [3, 6] // Wednesday and Saturday
        default:
            return [1] // Default to Monday
        }
    }
    
    static func recyclingCollectionDays(for building: FrancoSphere.NamedCoordinate) -> [Int] {
        switch building.id {
        case "1", "2", "3":
            return [3] // Wednesday
        case "4", "5", "6":
            return [4] // Thursday
        case "7", "8", "9":
            return [5] // Friday
        default:
            return [2] // Default to Tuesday
        }
    }
}

// MARK: - Task Recurrence Helper
class TaskRecurrenceHelper {
    static func garbageCollectionRecurrence() -> FrancoSphere.TaskRecurrence {
        return .weekly // Map garbageCollection to weekly for now
    }
}

// MARK: - Extension to MaintenanceTask for immutable property handling
extension FrancoSphere.MaintenanceTask {
    // Create a new task with an updated due date
    func withUpdatedDueDate(_ newDate: Date) -> FrancoSphere.MaintenanceTask {
        return FrancoSphere.MaintenanceTask(
            id: self.id,
            name: self.name,
            buildingID: self.buildingID,
            description: self.description,
            dueDate: newDate,
            startTime: self.startTime,
            endTime: self.endTime,
            category: self.category,
            urgency: self.urgency,
            recurrence: self.recurrence,
            isComplete: self.isComplete,
            assignedWorkers: self.assignedWorkers
        )
    }
}

// MARK: - Task Scheduler Helper Methods
// These are standalone implementations that can be used by the existing TaskSchedulerService

@MainActor
class TaskSchedulerHelper {
    
    static func scheduleRecurringTasks(for buildingID: String, taskManager: TaskManager, weatherAdapter: WeatherDataAdapter) async -> [FrancoSphere.MaintenanceTask] {
        // Use async version of fetchTasks
        let existingTasks: [FrancoSphere.MaintenanceTask] = await withCheckedContinuation { continuation in
            Task {
                let tasks = await taskManager.fetchTasksAsync(forBuilding: buildingID, includePastTasks: false)
                continuation.resume(returning: tasks)
            }
        }
        
        // Check if we already have garbage collection and monthly inspection tasks
        let hasGarbageCollection = existingTasks.contains { task in
            return task.recurrence == FrancoSphere.TaskRecurrence.weekly && task.name.contains("Collection")
        }
        
        let monthlyInspectionTasks = existingTasks.filter { task in
            return task.recurrence == FrancoSphere.TaskRecurrence.monthly && task.category == FrancoSphere.TaskCategory.inspection
        }
        let hasMonthlyInspection = !monthlyInspectionTasks.isEmpty
        
        var newTasks: [FrancoSphere.MaintenanceTask] = []
        
        if !hasGarbageCollection {
            // Get all buildings from BuildingRepository
            let allBuildings = await BuildingRepository.shared.allBuildings
            if let building = allBuildings.first(where: { $0.id == buildingID }) {
                // Create garbage collection tasks
                let garbageDays = BuildingCollectionScheduleHelper.garbageCollectionDays(for: building)
                for day in garbageDays {
                    let nextDate = nextDateForWeekday(day)
                    let task = FrancoSphere.MaintenanceTask(
                        name: "Garbage Collection",
                        buildingID: buildingID,
                        description: "Take out trash bins for collection",
                        dueDate: nextDate,
                        category: .sanitation,
                        urgency: .medium,
                        recurrence: .weekly
                    )
                    newTasks.append(task)
                }
                
                // Create recycling collection tasks
                let recyclingDays = BuildingCollectionScheduleHelper.recyclingCollectionDays(for: building)
                for day in recyclingDays {
                    let nextDate = nextDateForWeekday(day)
                    let task = FrancoSphere.MaintenanceTask(
                        name: "Recycling Collection",
                        buildingID: buildingID,
                        description: "Take out recycling bins for collection",
                        dueDate: nextDate,
                        category: .sanitation,
                        urgency: .medium,
                        recurrence: .weekly
                    )
                    newTasks.append(task)
                }
            }
        }
        
        if !hasMonthlyInspection {
            let calendar = Calendar.current
            let today = Date()
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: today)!
            let components = calendar.dateComponents([.year, .month], from: nextMonth)
            let firstDayOfNextMonth = calendar.date(from: components)!
            let task = FrancoSphere.MaintenanceTask(
                name: "Monthly Building Inspection",
                buildingID: buildingID,
                description: "Comprehensive inspection of building systems and common areas",
                dueDate: firstDayOfNextMonth,
                category: .inspection,
                urgency: .medium,
                recurrence: .monthly
            )
            newTasks.append(task)
        }
        
        // Get building for weather tasks
        let allBuildings = await BuildingRepository.shared.allBuildings
        if let building = allBuildings.first(where: { $0.id == buildingID }) {
            let weatherTasks = weatherAdapter.generateWeatherTasks(for: building)
            newTasks.append(contentsOf: weatherTasks)
        }
        
        if !newTasks.isEmpty {
            await taskManager.createWeatherBasedTasksAsync(for: buildingID, tasks: newTasks)
        }
        
        return newTasks
    }
    
    static func nextDateForWeekday(_ weekday: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)
        let calendarWeekday = weekday == 7 ? 1 : weekday + 1
        let daysToAdd: Int = calendarWeekday > todayWeekday
            ? (calendarWeekday - todayWeekday)
            : (7 - (todayWeekday - calendarWeekday))
        return calendar.date(byAdding: .day, value: daysToAdd, to: today)!
    }
    
    static func adjustTaskSchedulesForWeather(buildingID: String, taskManager: TaskManager, weatherAdapter: WeatherDataAdapter) async -> [FrancoSphere.MaintenanceTask] {
        let tasks: [FrancoSphere.MaintenanceTask] = await withCheckedContinuation { continuation in
            Task {
                let tasks = await taskManager.fetchTasksAsync(forBuilding: buildingID, includePastTasks: false)
                continuation.resume(returning: tasks)
            }
        }
        return await adjustForWeather(tasks: tasks, buildingID: buildingID, weatherAdapter: weatherAdapter)
    }
    
    static func adjustForWeather(tasks: [FrancoSphere.MaintenanceTask], buildingID: String, weatherAdapter: WeatherDataAdapter) async -> [FrancoSphere.MaintenanceTask] {
        // Get building from repository
        let allBuildings = await BuildingRepository.shared.allBuildings
        guard let building = allBuildings.first(where: { $0.id == buildingID }) else {
            return []
        }
        
        // Fetch weather for the building
        await weatherAdapter.fetchWeatherForBuildingAsync(building)
        
        var adjustedTasks: [FrancoSphere.MaintenanceTask] = []
        
        for task in tasks {
            if weatherAdapter.shouldRescheduleTask(task) {
                if let newDate = weatherAdapter.recommendedRescheduleDateForTask(task) {
                    // Create a new task with updated date
                    let adjustedTask = task.withUpdatedDueDate(newDate)
                    adjustedTasks.append(adjustedTask)
                }
            }
        }
        
        // Add an emergency task if applicable
        if let emergencyTask = weatherAdapter.createEmergencyWeatherTask(for: building) {
            adjustedTasks.append(emergencyTask)
        }
        
        return adjustedTasks
    }
    
    static func suggestOptimalSchedule(for buildingID: String, category: FrancoSphere.TaskCategory, urgency: FrancoSphere.TaskUrgency, taskManager: TaskManager) async -> Date {
        let existingTasks: [FrancoSphere.MaintenanceTask] = await withCheckedContinuation { continuation in
            Task {
                let tasks = await taskManager.fetchTasksAsync(forBuilding: buildingID, includePastTasks: false)
                continuation.resume(returning: tasks)
            }
        }
        let now = Date()
        let calendar = Calendar.current
        
        switch urgency {
        case .urgent:
            return now
        case .high:
            let tasksToday = existingTasks.filter { calendar.isDate($0.dueDate, inSameDayAs: now) }
            return tasksToday.count < 5 ? now : calendar.date(byAdding: .day, value: 1, to: now)!
        case .medium:
            var dayCount: [Int: Int] = [:]
            for i in 0..<7 { dayCount[i] = 0 }
            for task in existingTasks {
                let dayDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: task.dueDate)).day ?? 0
                if dayDiff >= 0 && dayDiff < 7 {
                    dayCount[dayDiff, default: 0] += 1
                }
            }
            let optimalDay = dayCount.sorted { $0.value < $1.value }.first?.key ?? 3
            return calendar.date(byAdding: .day, value: optimalDay, to: now)!
        case .low:
            return calendar.date(byAdding: .day, value: 7, to: now)!
        }
    }
    
    static func optimizeWorkerAssignments(for buildingID: String, taskManager: TaskManager) async -> [String: [FrancoSphere.MaintenanceTask]] {
        let tasks: [FrancoSphere.MaintenanceTask] = await withCheckedContinuation { continuation in
            Task {
                let tasks = await taskManager.fetchTasksAsync(forBuilding: buildingID, includePastTasks: false)
                continuation.resume(returning: tasks)
            }
        }
        var workerAssignments: [String: [FrancoSphere.MaintenanceTask]] = [:]
        let workerIDs = ["1", "2", "3"]
        
        for (index, task) in tasks.enumerated() {
            let workerID = workerIDs[index % workerIDs.count]
            workerAssignments[workerID, default: []].append(task)
        }
        return workerAssignments
    }
}

// MARK: - Convenience Extensions for non-async contexts

extension TaskSchedulerHelper {
    // Wrapper methods for use in synchronous contexts
    static func scheduleRecurringTasksSync(for buildingID: String, taskManager: TaskManager, weatherAdapter: WeatherDataAdapter) -> [FrancoSphere.MaintenanceTask] {
        let task = Task { @MainActor in
            await scheduleRecurringTasks(for: buildingID, taskManager: taskManager, weatherAdapter: weatherAdapter)
        }
        
        // For synchronous context, we need to block and wait
        // In production, consider using completion handlers instead
        return []  // Return empty array for now, as we can't easily block
    }
    
    static func adjustTaskSchedulesForWeatherSync(buildingID: String, taskManager: TaskManager, weatherAdapter: WeatherDataAdapter) -> [FrancoSphere.MaintenanceTask] {
        let task = Task { @MainActor in
            await adjustTaskSchedulesForWeather(buildingID: buildingID, taskManager: taskManager, weatherAdapter: weatherAdapter)
        }
        
        return []  // Return empty array for now
    }
    
    static func suggestOptimalScheduleSync(for buildingID: String, category: FrancoSphere.TaskCategory, urgency: FrancoSphere.TaskUrgency, taskManager: TaskManager) -> Date {
        // For synchronous context, return a default date
        let calendar = Calendar.current
        return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }
    
    static func optimizeWorkerAssignmentsSync(for buildingID: String, taskManager: TaskManager) -> [String: [FrancoSphere.MaintenanceTask]] {
        let task = Task { @MainActor in
            await optimizeWorkerAssignments(for: buildingID, taskManager: taskManager)
        }
        
        return [:]  // Return empty dictionary for now
    }
}
