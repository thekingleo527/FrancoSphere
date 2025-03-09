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

// Put TaskSchedulerService inside the FrancoSphere namespace to avoid redeclaration
extension FrancoSphere {
    // Implementation of TaskSchedulerService
    class TaskSchedulerService: ObservableObject {
        @Published var scheduledTasks: [MaintenanceTask] = []
        @Published var weatherAdjustedTasks: [MaintenanceTask] = []
        
        static let shared = TaskSchedulerService()
        
        private var cancellables = Set<AnyCancellable>()
        private let taskManager = TaskManager.shared
        private let weatherService = WeatherService.shared
        
        init() {
            setupObservers()
        }
        
        // MARK: - Task Scheduling
        
        func scheduleRecurringTasks(for buildingID: String) {
            // Fixed: Added includePastTasks parameter and explicit type
            let existingTasks: [MaintenanceTask] = taskManager.fetchTasks(forBuilding: buildingID, includePastTasks: false)
            
            // Check if we already have garbage collection and monthly inspection tasks
            // Fixed: Added explicit enum reference
            let hasGarbageCollection = existingTasks.contains { task in
                return task.recurrence == TaskRecurrence.weekly && task.name.contains("Collection")
            }
            
            // Fixed: Breaking down complex expression
            let monthlyInspectionTasks = existingTasks.filter { task in
                return task.recurrence == TaskRecurrence.monthly && task.category == TaskCategory.inspection
            }
            let hasMonthlyInspection = !monthlyInspectionTasks.isEmpty
            
            var newTasks: [MaintenanceTask] = []
            
            if !hasGarbageCollection {
                if let building = NamedCoordinate.allBuildings.first(where: { $0.id == buildingID }) {
                    // Create garbage collection tasks
                    let garbageDays = BuildingCollectionScheduleHelper.garbageCollectionDays(for: building)
                    for day in garbageDays {
                        let nextDate = nextDateForWeekday(day)
                        let task = MaintenanceTask(
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
                        let task = MaintenanceTask(
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
                let task = MaintenanceTask(
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
            
            if let building = NamedCoordinate.allBuildings.first(where: { $0.id == buildingID }) {
                let weatherTasks = weatherService.generateWeatherTasks(for: building)
                newTasks.append(contentsOf: weatherTasks)
            }
            
            if !newTasks.isEmpty {
                taskManager.createWeatherBasedTasks(for: buildingID, tasks: newTasks)
                scheduledTasks.append(contentsOf: newTasks)
            }
        }
        
        private func nextDateForWeekday(_ weekday: Int) -> Date {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let todayWeekday = calendar.component(.weekday, from: today)
            let calendarWeekday = weekday == 7 ? 1 : weekday + 1
            let daysToAdd: Int = calendarWeekday > todayWeekday
                ? (calendarWeekday - todayWeekday)
                : (7 - (todayWeekday - calendarWeekday))
            return calendar.date(byAdding: .day, value: daysToAdd, to: today)!
        }
        
        func adjustTaskSchedules(for buildingID: String) {
            // Fixed: Added includePastTasks parameter and explicit type
            let tasks: [MaintenanceTask] = taskManager.fetchTasks(forBuilding: buildingID, includePastTasks: false)
            adjustForWeather(tasks: tasks, buildingID: buildingID)
        }
        
        private func adjustForWeather(tasks: [MaintenanceTask], buildingID: String) {
            guard let building = NamedCoordinate.allBuildings.first(where: { $0.id == buildingID }) else {
                return
            }
            
            // NOTE: These methods need to be implemented in the WeatherService class
            weatherService.fetchWeather(latitude: building.latitude, longitude: building.longitude)
            
            let tasksToReschedule = weatherService.tasksNeedingRescheduling(tasks)
            var adjustedTasks: [MaintenanceTask] = []
            
            for task in tasksToReschedule {
                // Fixed: Added explicit cast to handle type mismatch
                let maintenanceTask = task as MaintenanceTask
                if let newDate = weatherService.recommendedRescheduleDateForTask(maintenanceTask) {
                    // Create a new task with updated date
                    let adjustedTask = maintenanceTask.withUpdatedDueDate(newDate)
                    adjustedTasks.append(adjustedTask)
                }
            }
            
            weatherAdjustedTasks = adjustedTasks
            
            // Add an emergency task if applicable.
            // Fixed: Handle casting differently
            if let legacyEmergencyTask = weatherService.createEmergencyWeatherTask(for: building) {
                if let emergencyTask = legacyEmergencyTask as? MaintenanceTask {
                    weatherAdjustedTasks.append(emergencyTask)
                }
            }
        }
        
        private func setupObservers() {
            NotificationCenter.default.publisher(for: Notification.Name("TaskCompleted"))
                .sink { [weak self] notification in
                    guard let self = self,
                          let userInfo = notification.userInfo,
                          let buildingID = userInfo["buildingId"] as? String else { return }
                    self.scheduleRecurringTasks(for: buildingID)
                }
                .store(in: &cancellables)
            
            NotificationCenter.default.publisher(for: Notification.Name("WeatherForecastUpdated"))
                .sink { [weak self] notification in
                    guard let self = self,
                          let userInfo = notification.userInfo,
                          let buildingID = userInfo["buildingId"] as? String else { return }
                    self.adjustForWeather(tasks: self.scheduledTasks, buildingID: buildingID)
                }
                .store(in: &cancellables)
        }
        
        func suggestOptimalSchedule(for buildingID: String, category: TaskCategory, urgency: TaskUrgency) -> Date {
            // Fixed: Added includePastTasks parameter and explicit type
            let existingTasks: [MaintenanceTask] = taskManager.fetchTasks(forBuilding: buildingID, includePastTasks: false)
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
        
        func optimizeWorkerAssignments(for buildingID: String) -> [String: [MaintenanceTask]] {
            // Fixed: Added includePastTasks parameter and explicit type
            let tasks: [MaintenanceTask] = taskManager.fetchTasks(forBuilding: buildingID, includePastTasks: false)
            var workerAssignments: [String: [MaintenanceTask]] = [:]
            let workerIDs = ["1", "2", "3"]
            
            for (index, task) in tasks.enumerated() {
                let workerID = workerIDs[index % workerIDs.count]
                workerAssignments[workerID, default: []].append(task)
            }
            return workerAssignments
        }
    }
}
