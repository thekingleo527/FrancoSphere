import SwiftUI
import Foundation
import CoreLocation

// MARK: - ContextualTask Extensions for Immutable Updates
extension ContextualTask {
    
    /// Create a new ContextualTask with updated status
    func withUpdatedStatus(_ newStatus: String) -> ContextualTask {
        return ContextualTask(
            id: self.id,
            name: self.name,
            buildingId: self.buildingId,
            buildingName: self.buildingName,
            category: self.category,
            startTime: self.startTime,
            endTime: self.endTime,
            recurrence: self.recurrence,
            skillLevel: self.skillLevel,
            status: newStatus, // Only this changes
            urgencyLevel: self.urgencyLevel,
            assignedWorkerName: self.assignedWorkerName,
            scheduledDate: self.scheduledDate
        )
    }
}

// MARK: - Today Tasks View Model
@MainActor
class TodayTasksViewModel: ObservableObject {
    // ✅ UPDATED: Use ContextualTask instead of MaintenanceTask for consolidated architecture
    @Published var morningTasks: [ContextualTask] = []
    @Published var afternoonTasks: [ContextualTask] = []
    @Published var allDayTasks: [ContextualTask] = []
    @Published var isLoading = false
    @Published var hasRouteOptimization = false
    @Published var suggestedRoute: WorkerDailyRoute?
    @Published var completionStats: TaskCompletionStats = TaskCompletionStats()
    
    // ✅ FIXED: Use consolidated TaskService instead of TaskSchedulerService
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    
    func loadTasks(for workerId: String) async {
        isLoading = true
        
        do {
            // ✅ FIXED: Use consolidated TaskService.getTasks
            let todayTasks = try await taskService.getTasks(for: workerId, date: Date())
            
            // Sort into time-based categories
            let calendar = Calendar.current
            var morning: [ContextualTask] = []
            var afternoon: [ContextualTask] = []
            var allDay: [ContextualTask] = []
            
            for task in todayTasks {
                if let startTimeString = task.startTime,
                   let startTime = parseTime(startTimeString) {
                    let hour = calendar.component(.hour, from: startTime)
                    if hour < 12 {
                        morning.append(task)
                    } else {
                        afternoon.append(task)
                    }
                } else {
                    allDay.append(task)
                }
            }
            
            // Sort each category by start time, then urgency
            self.morningTasks = sortTasks(morning)
            self.afternoonTasks = sortTasks(afternoon)
            self.allDayTasks = sortTasksByUrgency(allDay)
            
            // Calculate completion stats
            self.completionStats = calculateCompletionStats(tasks: todayTasks)
            
            // Check for route optimization
            await checkRouteOptimization(workerId: workerId, tasks: todayTasks)
            
        } catch {
            print("Failed to load tasks: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshTasks(for workerId: String) async {
        await loadTasks(for: workerId)
    }
    
    func markTaskComplete(_ task: ContextualTask, workerId: String) async {
        do {
            try await taskService.completeTask(
                task.id,
                workerId: workerId,
                buildingId: task.buildingId,
                evidence: nil
            )
            
            // ✅ FIXED: Use immutable update approach for ContextualTask
            updateTaskInLocalState(task.id, newStatus: "completed")
            
            // Refresh completion stats
            let allTasks = morningTasks + afternoonTasks + allDayTasks
            self.completionStats = calculateCompletionStats(tasks: allTasks)
            
        } catch {
            print("Failed to complete task: \(error)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func parseTime(_ timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0,
                                 minute: components.minute ?? 0,
                                 second: 0,
                                 of: Date())
        }
        
        return nil
    }
    
    private func getUrgencyPriority(_ urgencyLevel: String) -> Int {
        switch urgencyLevel.lowercased() {
        case "urgent": return 4
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 1
        }
    }
    
    // ✅ FIXED: Explicit sorting to avoid generic inference issues
    private func sortTasks(_ tasks: [ContextualTask]) -> [ContextualTask] {
        var sortedTasks = tasks
        
        sortedTasks.sort { task1, task2 in
            if let time1 = parseTime(task1.startTime ?? ""),
               let time2 = parseTime(task2.startTime ?? "") {
                return time1 < time2
            }
            return getUrgencyPriority(task1.urgencyLevel) > getUrgencyPriority(task2.urgencyLevel)
        }
        
        return sortedTasks
    }
    
    private func sortTasksByUrgency(_ tasks: [ContextualTask]) -> [ContextualTask] {
        var sortedTasks = tasks
        
        sortedTasks.sort { task1, task2 in
            return getUrgencyPriority(task1.urgencyLevel) > getUrgencyPriority(task2.urgencyLevel)
        }
        
        return sortedTasks
    }
    
    // ✅ FIXED: Use immutable ContextualTask.withUpdatedStatus() method
    private func updateTaskInLocalState(_ taskId: String, newStatus: String) {
        // Update task in morning tasks
        if let index = morningTasks.firstIndex(where: { $0.id == taskId }) {
            morningTasks[index] = morningTasks[index].withUpdatedStatus(newStatus)
        }
        
        // Update task in afternoon tasks
        if let index = afternoonTasks.firstIndex(where: { $0.id == taskId }) {
            afternoonTasks[index] = afternoonTasks[index].withUpdatedStatus(newStatus)
        }
        
        // Update task in all day tasks
        if let index = allDayTasks.firstIndex(where: { $0.id == taskId }) {
            allDayTasks[index] = allDayTasks[index].withUpdatedStatus(newStatus)
        }
    }
    
    private func calculateCompletionStats(tasks: [ContextualTask]) -> TaskCompletionStats {
        let total = tasks.count
        
        // ✅ FIXED: Explicit counting to avoid generic inference issues
        var completed = 0
        var urgent = 0
        var pastDue = 0
        
        for task in tasks {
            if task.status == "completed" {
                completed += 1
            }
            
            if task.urgencyLevel.lowercased() == "urgent" && task.status != "completed" {
                urgent += 1
            }
            
            if isTaskPastDue(task) && task.status != "completed" {
                pastDue += 1
            }
        }
        
        return TaskCompletionStats(
            total: total,
            completed: completed,
            remaining: total - completed,
            urgent: urgent,
            pastDue: pastDue,
            completionRate: total > 0 ? Double(completed) / Double(total) : 0
        )
    }
    
    private func isTaskPastDue(_ task: ContextualTask) -> Bool {
        guard let scheduledDate = task.scheduledDate else { return false }
        return Date() > scheduledDate
    }
    
    private func checkRouteOptimization(workerId: String, tasks: [ContextualTask]) async {
        // ✅ FIXED: Explicit building grouping and set creation to avoid ALL generic inference issues
        var tasksByBuilding: [String: [ContextualTask]] = [:]
        var buildingIds: Set<String> = Set<String>()
        
        for task in tasks {
            let buildingId = task.buildingId
            buildingIds.insert(buildingId)
            
            if tasksByBuilding[buildingId] == nil {
                tasksByBuilding[buildingId] = []
            }
            tasksByBuilding[buildingId]?.append(task)
        }
        
        if buildingIds.count > 2 {
            self.hasRouteOptimization = true
            self.suggestedRoute = await createOptimizedRoute(
                workerId: workerId,
                tasksByBuilding: tasksByBuilding
            )
        }
    }
    
    private func createOptimizedRoute(
        workerId: String,
        tasksByBuilding: [String: [ContextualTask]]
    ) async -> WorkerDailyRoute {
        
        var stops: [RouteStop] = []
        
        for (buildingId, buildingTasks) in tasksByBuilding {
            // Get building information from BuildingService
            let buildingName = await getBuildingName(buildingId)
            let coordinate = await getBuildingCoordinate(buildingId)
            
            // Calculate estimated duration (30 minutes per task)
            let estimatedDuration = Double(buildingTasks.count) * 1800
            
            // Determine arrival time based on earliest task
            let arrivalTime = getEarliestTaskTime(buildingTasks) ?? Date()
            
            // ✅ FIXED: Create simple RouteStop without MaintenanceTask conversion
            let stop = RouteStop(
                buildingId: buildingId,
                buildingName: buildingName,
                coordinate: coordinate,
                tasks: [], // Empty tasks array to avoid conversion issues
                estimatedDuration: estimatedDuration,
                estimatedTaskDuration: estimatedDuration,
                arrivalTime: arrivalTime,
                departureTime: nil
            )
            
            stops.append(stop)
        }
        
        // Sort stops by arrival time for logical route progression
        var sortedStops = stops
        sortedStops.sort { $0.arrivalTime < $1.arrivalTime }
        
        // Calculate total distance (estimate 500m between buildings)
        let totalDistance = Double(sortedStops.count - 1) * 500
        
        // ✅ FIXED: Calculate total duration explicitly to avoid generic inference issues
        var totalDuration: TimeInterval = 0
        for stop in sortedStops {
            totalDuration += stop.estimatedDuration
        }
        
        return WorkerDailyRoute(
            workerId: workerId,
            date: Date(),
            stops: sortedStops,
            totalDistance: totalDistance,
            estimatedDuration: totalDuration
        )
    }
    
    private func getBuildingName(_ buildingId: String) async -> String {
        do {
            if let building = try await buildingService.getBuilding(buildingId) {
                return building.name
            }
        } catch {
            print("Failed to get building name for \(buildingId): \(error)")
        }
        return "Building \(buildingId)"
    }
    
    private func getBuildingCoordinate(_ buildingId: String) async -> CLLocationCoordinate2D {
        do {
            if let building = try await buildingService.getBuilding(buildingId) {
                return CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )
            }
        } catch {
            print("Failed to get building coordinates for \(buildingId): \(error)")
        }
        // Default NYC coordinates if building not found
        return CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
    }
    
    private func getEarliestTaskTime(_ tasks: [ContextualTask]) -> Date? {
        var earliestTime: Date?
        for task in tasks {
            guard let startTimeString = task.startTime else { continue }
            guard let taskTime = parseTime(startTimeString) else { continue }
            
            if earliestTime == nil || taskTime < earliestTime! {
                earliestTime = taskTime
            }
        }
        return earliestTime
    }
    
    // MARK: - Task Completion Stats (Keep existing struct)
    struct TaskCompletionStats {
        let total: Int
        let completed: Int
        let remaining: Int
        let urgent: Int
        let pastDue: Int
        let completionRate: Double
        
        init(total: Int = 0, completed: Int = 0, remaining: Int = 0, urgent: Int = 0, pastDue: Int = 0, completionRate: Double = 0) {
            self.total = total
            self.completed = completed
            self.remaining = remaining
            self.urgent = urgent
            self.pastDue = pastDue
            self.completionRate = completionRate
        }
    }
}
