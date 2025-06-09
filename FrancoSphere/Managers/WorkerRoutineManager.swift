//
//  WorkerRoutineManager.swift
//  FrancoSphere
//
//  Manager for worker daily routes and schedule optimization

import Foundation
import CoreLocation
import SwiftUI

// MARK: - WorkerRoutineManager

actor WorkerRoutineManager {
    static let shared = WorkerRoutineManager()
    
    private let taskManager = TaskManager.shared
    private var cachedRoutes: [String: WorkerDailyRoute] = [:]
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get worker routine summary
    func getWorkerRoutineSummary(workerId: String) async -> WorkerRoutineSummary? {
        // Get all tasks for worker across multiple days
        let allTasks = await taskManager.getUpcomingTasks(forWorker: workerId, days: 30)
        
        // Group by recurrence
        let tasksByRecurrence = Dictionary(grouping: allTasks) { $0.recurrence }
        
        let dailyTaskCount = tasksByRecurrence[.daily]?.count ?? 0
        let weeklyTaskCount = tasksByRecurrence[.weekly]?.count ?? 0
        let monthlyTaskCount = tasksByRecurrence[.monthly]?.count ?? 0
        
        // Get unique buildings
        let uniqueBuildings = Set(allTasks.map { $0.buildingID })
        
        // Calculate estimated hours
        let dailyHours = Double(dailyTaskCount) * 0.5 // 30 min per daily task
        let weeklyHours = Double(weeklyTaskCount) * 1.0 + dailyHours * 5 // 1 hour per weekly task
        
        // Calculate total distance (simplified)
        let totalDistance = Double(uniqueBuildings.count) * 1000.0 // 1km average between buildings
        
        // Calculate estimated duration
        let estimatedDuration = TimeInterval(allTasks.count * 1800) // 30 min per task average
        
        return WorkerRoutineSummary(
            id: UUID().uuidString,
            workerId: workerId,
            date: Date(),
            totalTasks: allTasks.count,
            completedTasks: allTasks.filter { $0.isComplete }.count,
            totalDistance: totalDistance,
            estimatedDuration: estimatedDuration,
            dailyTasks: dailyTaskCount,
            weeklyTasks: weeklyTaskCount,
            monthlyTasks: monthlyTaskCount,
            buildingCount: uniqueBuildings.count,
            estimatedDailyHours: dailyHours,
            estimatedWeeklyHours: weeklyHours
        )
    }
    
    /// Generate daily route for worker
    func generateDailyRoute(workerId: String, date: Date) async throws -> WorkerDailyRoute {
        // Check cache first
        let cacheKey = "\(workerId)-\(date.timeIntervalSince1970)"
        if let cached = cachedRoutes[cacheKey] {
            return cached
        }
        
        // Get tasks for the day
        let tasks = await taskManager.fetchTasksAsync(forWorker: workerId, date: date)
        
        // Group tasks by building
        let tasksByBuilding = Dictionary(grouping: tasks) { $0.buildingID }
        
        // Create route stops
        var stops: [RouteStop] = []
        var currentTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: date)!
        
        for (buildingId, buildingTasks) in tasksByBuilding.sorted(by: { $0.key < $1.key }) {
            guard let building = NamedCoordinate.getBuilding(byId: buildingId) else {
                continue
            }
            
            let estimatedDuration = TimeInterval(buildingTasks.count * 1800) // 30 min per task
            
            let stop = RouteStop(
                id: UUID().uuidString,
                buildingId: buildingId,
                buildingName: building.name,
                coordinate: building.coordinate,
                tasks: buildingTasks,
                estimatedDuration: estimatedDuration,
                estimatedTaskDuration: estimatedDuration,
                arrivalTime: currentTime,
                departureTime: currentTime.addingTimeInterval(estimatedDuration)
            )
            
            stops.append(stop)
            currentTime = currentTime.addingTimeInterval(estimatedDuration + 900) // +15 min travel
        }
        
        // Optimize stop order
        stops = optimizeStopOrder(stops)
        
        // Calculate total distance
        let totalDistance = calculateTotalDistance(stops: stops)
        
        // Create route
        let route = WorkerDailyRoute(
            id: UUID().uuidString,
            workerId: workerId,
            date: date,
            stops: stops,
            totalDistance: totalDistance,
            estimatedDuration: TimeInterval(stops.count * 2700) // 45 min per stop average
        )
        
        // Cache it
        cachedRoutes[cacheKey] = route
        
        return route
    }
    
    /// Get daily route (convenience method)
    func getDailyRoute(workerId: String, date: Date) async throws -> WorkerDailyRoute {
        return try await generateDailyRoute(workerId: workerId, date: date)
    }
    
    /// Suggest route optimizations
    func suggestOptimizations(for route: WorkerDailyRoute) async -> [RouteOptimization] {
        var optimizations: [RouteOptimization] = []
        
        // Check for nearby buildings that could be combined
        if route.stops.count > 3 {
            optimizations.append(
                RouteOptimization(
                    id: UUID().uuidString,
                    type: .reorder,
                    description: "Reorder stops by geographic proximity",
                    timeSaved: 900, // 15 minutes
                    estimatedTimeSaving: 900
                )
            )
        }
        
        // Check for low priority tasks
        let lowPriorityTasks = route.stops.flatMap { $0.tasks }.filter { $0.urgency == .low }
        if lowPriorityTasks.count > 2 {
            let timeSaved = TimeInterval(lowPriorityTasks.count * 600)
            optimizations.append(
                RouteOptimization(
                    id: UUID().uuidString,
                    type: .skip,
                    description: "Defer \(lowPriorityTasks.count) low priority tasks",
                    timeSaved: timeSaved,
                    estimatedTimeSaving: timeSaved
                )
            )
        }
        
        // Check for similar tasks that could be batched
        let cleaningStops = route.stops.filter { stop in
            stop.tasks.contains { $0.category == .cleaning }
        }
        if cleaningStops.count > 2 {
            optimizations.append(
                RouteOptimization(
                    id: UUID().uuidString,
                    type: .combine,
                    description: "Batch all cleaning tasks together",
                    timeSaved: 1200, // 20 minutes
                    estimatedTimeSaving: 1200
                )
            )
        }
        
        return optimizations
    }
    
    /// Detect schedule conflicts
    func detectScheduleConflicts(stops: [RouteStop], date: Date) async -> [ScheduleConflict] {
        var conflicts: [ScheduleConflict] = []
        
        // Check for time overlaps
        for i in 0..<stops.count - 1 {
            let currentStop = stops[i]
            let nextStop = stops[i + 1]
            
            if let currentDeparture = currentStop.departureTime {
                if currentDeparture > nextStop.arrivalTime {
                    conflicts.append(
                        ScheduleConflict(
                            id: UUID().uuidString,
                            type: .overlap,
                            description: "Tasks at \(currentStop.buildingName) overlap with \(nextStop.buildingName)",
                            severity: .high,
                            suggestedResolution: "Reschedule one task or assign to another worker"
                        )
                    )
                }
            }
        }
        
        // Check for unrealistic travel times
        for i in 0..<stops.count - 1 {
            let distance = calculateDistance(
                from: stops[i].coordinate,
                to: stops[i + 1].coordinate
            )
            
            let travelTimeNeeded = distance / 5.0 // 5 m/s walking speed
            if travelTimeNeeded > 900 { // More than 15 minutes
                conflicts.append(
                    ScheduleConflict(
                        id: UUID().uuidString,
                        type: .travel,
                        description: "Insufficient travel time between \(stops[i].buildingName) and \(stops[i + 1].buildingName)",
                        severity: .medium,
                        suggestedResolution: "Allow more time between locations or reorder stops"
                    )
                )
            }
        }
        
        return conflicts
    }
    
    /// Optimize route by reordering stops
    func optimizeRoute(_ route: WorkerDailyRoute) async -> WorkerDailyRoute {
        let optimizedStops = optimizeStopOrder(route.stops)
        
        // Recalculate times
        var currentTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: route.date)!
        var updatedStops: [RouteStop] = []
        
        for stop in optimizedStops {
            let updatedStop = RouteStop(
                id: stop.id,
                buildingId: stop.buildingId,
                buildingName: stop.buildingName,
                coordinate: stop.coordinate,
                tasks: stop.tasks,
                estimatedDuration: stop.estimatedDuration,
                estimatedTaskDuration: stop.estimatedTaskDuration,
                arrivalTime: currentTime,
                departureTime: currentTime.addingTimeInterval(stop.estimatedDuration)
            )
            updatedStops.append(updatedStop)
            currentTime = currentTime.addingTimeInterval(stop.estimatedDuration + 900) // +15 min travel
        }
        
        let totalDistance = calculateTotalDistance(stops: updatedStops)
        
        return WorkerDailyRoute(
            id: route.id,
            workerId: route.workerId,
            date: route.date,
            stops: updatedStops,
            totalDistance: totalDistance,
            estimatedDuration: route.estimatedDuration
        )
    }
    
    // MARK: - Helper Methods
    
    private func optimizeStopOrder(_ stops: [RouteStop]) -> [RouteStop] {
        // Simple nearest neighbor optimization
        guard !stops.isEmpty else { return stops }
        
        var optimizedStops: [RouteStop] = []
        var remainingStops = stops
        
        // Start with the first stop
        optimizedStops.append(remainingStops.removeFirst())
        
        // Find nearest neighbor for each subsequent stop
        while !remainingStops.isEmpty {
            let currentStop = optimizedStops.last!
            
            // Find closest stop
            let closestIndex = remainingStops.enumerated().min { a, b in
                let distA = calculateDistance(
                    from: currentStop.coordinate,
                    to: a.element.coordinate
                )
                let distB = calculateDistance(
                    from: currentStop.coordinate,
                    to: b.element.coordinate
                )
                return distA < distB
            }?.offset ?? 0
            
            optimizedStops.append(remainingStops[closestIndex])
            remainingStops.remove(at: closestIndex)
        }
        
        return optimizedStops
    }
    
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc1.distance(from: loc2)
    }
    
    private func calculateTotalDistance(stops: [RouteStop]) -> Double {
        var totalDistance = 0.0
        
        for i in 0..<stops.count - 1 {
            totalDistance += calculateDistance(
                from: stops[i].coordinate,
                to: stops[i + 1].coordinate
            )
        }
        
        return totalDistance
    }
}

// MARK: - TaskManager Extension

extension TaskManager {
    /// Get worker routine tasks grouped by building
    func getWorkerRoutineTasks(workerId: String) async -> [String: [MaintenanceTask]] {
        let tasks = await getUpcomingTasks(forWorker: workerId, days: 30)
        return Dictionary(grouping: tasks) { $0.buildingID }
    }
    
    /// Get upcoming tasks for a worker (async version)
    func getUpcomingTasks(forWorker workerId: String, days: Int = 7) async -> [MaintenanceTask] {
        var allTasks: [MaintenanceTask] = []
        
        for day in 0..<days {
            guard let date = Calendar.current.date(byAdding: .day, value: day, to: Date()) else {
                continue
            }
            let tasks = await fetchTasksAsync(forWorker: workerId, date: date)
            allTasks.append(contentsOf: tasks)
        }
        
        return allTasks.sorted { $0.dueDate < $1.dueDate }
    }
}
