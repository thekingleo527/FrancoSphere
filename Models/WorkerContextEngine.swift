//
//  WorkerContextEngine.swift
//  FrancoSphere v6.0 — PHASE 1 FIXED: Connected to OperationalDataManager
//
//  🔧 FIXED: Real operational data connection implemented
//  ✅ CONNECTED: WorkerContextEngine ↔ OperationalDataManager
//  ✅ PRESERVED: Kevin's Rubin Museum assignments from operational data
//  ✅ REAL DATA: Workers see actual assignments, not hardcoded data
//

import Foundation
import CoreLocation
import Combine

public actor WorkerContextEngine {
    public static let shared = WorkerContextEngine()
    
    // MARK: - Private State (Actor-Isolated)
    private var currentWorker: WorkerProfile?
    private var assignedBuildings: [NamedCoordinate] = []
    private var todaysTasks: [ContextualTask] = []
    private var taskProgress: TaskProgress?
    private var clockInStatus: (isClockedIn: Bool, building: NamedCoordinate?) = (false, nil)
    private var isLoading = false
    private var lastError: Error?
    
    // MARK: - Dependencies
    private let authManager = NewAuthManager.shared
    private let workerService = WorkerService.shared
    private let taskService = TaskService.shared
    private let buildingService = BuildingService.shared
    
    // 🔧 PHASE 1 FIX: Add OperationalDataManager dependency
    private let operationalData = OperationalDataManager.shared
    private let weatherAdapter = WeatherDataAdapter.shared
    
    private init() {}
    
    // MARK: - Public API (All methods async)
    
    public func loadContext(for workerId: CoreTypes.WorkerID) async throws {
        guard !isLoading else { return }
        isLoading = true
        lastError = nil
        
        print("🔄 Loading context for worker: \(workerId)")
        
        do {
            // Load worker profile from database
            let profile = try await workerService.getWorkerProfile(for: workerId)
            self.currentWorker = profile
            
            // 🔧 PHASE 1 FIX: Get real assignments from OperationalDataManager
            let workerName = WorkerConstants.getWorkerName(id: workerId)
            print("📋 Loading assignments for: \(workerName)")
            
            let realWorldAssignments = await operationalData.getTasksForWorker(workerId, date: Date())
            
            // Extract unique buildings from operational tasks
            var uniqueBuildingIds = Set<String>()
            for task in realWorldAssignments {
                if let buildingId = task.building?.id {
                    uniqueBuildingIds.insert(buildingId)
                }
            }
            
            // Get building details for each unique building
            var buildings: [NamedCoordinate] = []
            for buildingId in uniqueBuildingIds {
                if let building = try await buildingService.getBuilding(buildingId: buildingId) {
                    buildings.append(building)
                }
            }
            
            // 🔧 PHASE 1 FIX: Use operational data for assignments
            self.assignedBuildings = buildings
            
            // 🔧 PHASE 1 FIX: Generate contextual tasks from operational data
            let contextualTasks = await generateContextualTasks(
                for: workerId,
                workerName: workerName,
                buildings: buildings,
                operationalTasks: realWorldAssignments
            )
            self.todaysTasks = contextualTasks
            
            // Get task progress from service
            self.taskProgress = try await taskService.getTaskProgress(for: workerId)
            
            // Handle clock-in status
            let status = await ClockInManager.shared.getClockInStatus(for: workerId)
            if let session = status.session {
                // Create NamedCoordinate from session data
                let building = NamedCoordinate(
                    id: session.buildingId,
                    name: session.buildingName,
                    latitude: session.location?.latitude ?? 0,
                    longitude: session.location?.longitude ?? 0
                )
                self.clockInStatus = (status.isClockedIn, building)
            } else {
                self.clockInStatus = (status.isClockedIn, nil)
            }
            
            // 🔧 PHASE 1 SUCCESS: Log results
            print("✅ Context loaded from operational data:")
            print("   📍 Buildings: \(self.assignedBuildings.count)")
            print("   📋 Tasks: \(self.todaysTasks.count)")
            
            // Special logging for Kevin's Rubin Museum
            if workerId == "4" {
                let rubinBuildings = buildings.filter { $0.name.contains("Rubin") }
                let rubinTasks = contextualTasks.filter { task in
                    guard let building = task.building else { return false }
                    return building.name.contains("Rubin")
                }
                print("   🎯 Kevin's Rubin Museum: \(rubinBuildings.count) buildings, \(rubinTasks.count) tasks")
            }
            
        } catch {
            lastError = error
            print("❌ loadContext failed: \(error)")
            throw error
        }
        
        isLoading = false
    }
    
    // 🔧 PHASE 1 FIX: New method to generate contextual tasks from operational data
    private func generateContextualTasks(
        for workerId: String,
        workerName: String,
        buildings: [NamedCoordinate],
        operationalTasks: [ContextualTask]
    ) async -> [ContextualTask] {
        var enhancedTasks: [ContextualTask] = []
        
        // Start with operational tasks
        for task in operationalTasks {
            // Add weather context if building location available
            var enhancedTask = task
            if let building = task.building {
                // Trigger weather fetch for building
                weatherAdapter.fetchWeatherForBuilding(building)
                
                // Wait briefly for weather to load
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                
                if let weather = await weatherAdapter.currentWeather {
                    enhancedTask = addWeatherContext(to: task, weather: weather)
                }
            }
            enhancedTasks.append(enhancedTask)
        }
        
        // Add weather-based tasks if needed
        if let aggregatedWeather = await getAggregatedWeather(for: buildings) {
            let weatherTasks = await generateWeatherTasks(
                weather: aggregatedWeather,
                buildings: buildings,
                workerId: workerId
            )
            enhancedTasks.append(contentsOf: weatherTasks)
        }
        
        // Sort by urgency
        return enhancedTasks.sorted { first, second in
            let firstUrgency = first.urgency ?? .medium
            let secondUrgency = second.urgency ?? .medium
            return getUrgencyPriority(firstUrgency) > getUrgencyPriority(secondUrgency)
        }
    }
    
    // Helper method to get numeric priority for urgency
    private func getUrgencyPriority(_ urgency: TaskUrgency) -> Int {
        switch urgency {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .urgent: return 4
        case .critical: return 5
        case .emergency: return 6
        }
    }
    
    // 🔧 PHASE 1 FIX: Add weather context to tasks
    private func addWeatherContext(to task: ContextualTask, weather: WeatherData) -> ContextualTask {
        // Create new task with weather-adjusted urgency
        let weatherAdjustedUrgency: TaskUrgency
        if weather.condition == .rainy || weather.condition == .stormy {
            // Increase urgency for outdoor tasks
            if task.category == .cleaning || task.category == .maintenance {
                weatherAdjustedUrgency = .high
            } else {
                weatherAdjustedUrgency = task.urgency ?? .medium
            }
        } else {
            weatherAdjustedUrgency = task.urgency ?? .medium
        }
        
        // Add weather context to description
        let weatherNote = "Weather: \(weather.condition.rawValue), \(Int(weather.temperature))°F"
        let enhancedDescription = [task.description, weatherNote].compactMap { $0 }.joined(separator: " | ")
        
        // Create new ContextualTask with weather enhancements
        return ContextualTask(
            id: task.id,
            title: task.title,
            description: enhancedDescription,
            isCompleted: task.isCompleted,
            completedDate: task.completedDate,
            scheduledDate: task.scheduledDate,
            dueDate: task.dueDate,
            category: task.category,
            urgency: weatherAdjustedUrgency,
            building: task.building,
            worker: task.worker,
            buildingId: task.buildingId,
            buildingName: task.buildingName,
            priority: weatherAdjustedUrgency
        )
    }
    
    // 🔧 PHASE 1 FIX: Get aggregated weather for all buildings
    private func getAggregatedWeather(for buildings: [NamedCoordinate]) async -> WeatherData? {
        guard !buildings.isEmpty else { return nil }
        
        // Get weather for first building as representative
        let firstBuilding = buildings.first!
        weatherAdapter.fetchWeatherForBuilding(firstBuilding)
        
        // Wait briefly for weather to load
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return await weatherAdapter.currentWeather
    }
    
    // 🔧 PHASE 1 FIX: Generate weather-based tasks
    private func generateWeatherTasks(
        weather: WeatherData,
        buildings: [NamedCoordinate],
        workerId: String
    ) async -> [ContextualTask] {
        var weatherTasks: [ContextualTask] = []
        
        // Generate weather-specific tasks
        switch weather.condition {
        case .rainy, .stormy:
            // Add drainage check tasks
            for building in buildings {
                let drainageTask = createWeatherTask(
                    title: "Storm Drain Check",
                    description: "Check drainage systems due to storm conditions",
                    building: building,
                    workerId: workerId,
                    urgency: .high
                )
                weatherTasks.append(drainageTask)
            }
            
        case .snowy:
            // Add snow removal tasks
            for building in buildings {
                let snowTask = createWeatherTask(
                    title: "Snow Removal",
                    description: "Clear walkways and entrances of snow",
                    building: building,
                    workerId: workerId,
                    urgency: .high
                )
                weatherTasks.append(snowTask)
            }
            
        case .windy:
            // Add debris cleanup tasks
            for building in buildings {
                let debrisTask = createWeatherTask(
                    title: "Wind Debris Cleanup",
                    description: "Clear debris from walkways due to high winds",
                    building: building,
                    workerId: workerId,
                    urgency: .medium
                )
                weatherTasks.append(debrisTask)
            }
            
        default:
            break
        }
        
        return weatherTasks
    }
    
    // 🔧 PHASE 1 FIX: Create weather-specific task
    private func createWeatherTask(
        title: String,
        description: String,
        building: NamedCoordinate,
        workerId: String,
        urgency: TaskUrgency
    ) -> ContextualTask {
        // Get worker profile
        let workerProfile = WorkerProfile(
            id: workerId,
            name: WorkerConstants.getWorkerName(id: workerId),
            email: "",
            phoneNumber: "",
            role: .worker,
            skills: [],
            certifications: [],
            hireDate: Date(),
            isActive: true
        )
        
        return ContextualTask(
            id: UUID().uuidString,
            title: title,
            description: description,
            isCompleted: false,
            completedDate: nil,
            scheduledDate: Date(),
            dueDate: Date().addingTimeInterval(7200), // 2 hours
            category: .maintenance,
            urgency: urgency,
            building: building,
            worker: workerProfile
        )
    }
    
    // MARK: - Getter Methods (Replace @Published)
    
    public func getCurrentWorker() -> WorkerProfile? { currentWorker }
    public func getAssignedBuildings() -> [NamedCoordinate] { assignedBuildings }
    public func getTodaysTasks() -> [ContextualTask] { todaysTasks }
    public func getTaskProgress() -> TaskProgress? { taskProgress }
    public func isWorkerClockedIn() -> Bool { clockInStatus.isClockedIn }
    public func getCurrentBuilding() -> NamedCoordinate? { clockInStatus.building }
    public func getIsLoading() -> Bool { isLoading }
    public func getLastError() -> Error? { lastError }
    
    // MARK: - Worker Information
    
    public func getWorkerId() -> String? { currentWorker?.id }
    public func getWorkerName() -> String { currentWorker?.name ?? "Unknown" }
    public func getWorkerRole() -> String { currentWorker?.role.rawValue ?? "worker" }
    public func getWorkerStatus() -> WorkerStatus {
        clockInStatus.isClockedIn ? .clockedIn : .available
    }
    
    // MARK: - Task Management
    
    public func recordTaskCompletion(
        workerId: CoreTypes.WorkerID,
        buildingId: CoreTypes.BuildingID,
        taskId: CoreTypes.TaskID,
        evidence: ActionEvidence
    ) async throws {
        print("📝 Recording task completion: \(taskId)")
        
        // Record to database
        try await taskService.completeTask(taskId, evidence: evidence)
        
        // Update local state
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = true
            todaysTasks[index].completedDate = Date()
        }
        
        // Refresh progress
        self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        
        print("✅ Task completed and progress updated")
    }
    
    public func addTask(_ task: ContextualTask) async throws {
        print("➕ Adding new task: \(task.title)")
        
        // Add to database
        try await taskService.createTask(task)
        
        // Update local state
        todaysTasks.append(task)
        
        // Refresh progress
        if let workerId = currentWorker?.id {
            self.taskProgress = try await taskService.getTaskProgress(for: workerId)
        }
    }
    
    // MARK: - Clock In/Out Management
    
    public func clockIn(at building: NamedCoordinate) async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking in at: \(building.name)")
        
        // Update database through ClockInManager
        try await ClockInManager.shared.clockIn(workerId: workerId, building: building)
        
        // Update local state
        clockInStatus = (true, building)
        
        print("✅ Clocked in successfully")
    }
    
    public func clockOut() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        print("🕐 Clocking out...")
        
        // Update database
        try await ClockInManager.shared.clockOut(workerId: workerId)
        
        // Update local state
        clockInStatus = (false, nil)
        
        print("✅ Clocked out successfully")
    }
    
    // MARK: - Data Refresh
    
    public func refreshData() async throws {
        guard let workerId = currentWorker?.id else {
            throw WorkerContextError.noCurrentWorker
        }
        
        try await loadContext(for: workerId)
    }
    
    public func refreshContext() async {
        guard let workerId = currentWorker?.id else {
            print("⚠️ No current worker to refresh context for")
            return
        }
        
        do {
            try await loadContext(for: workerId)
        } catch {
            print("❌ Failed to refresh context: \(error)")
            lastError = error
        }
    }
    
    // MARK: - Enhanced Task Queries
    
    public func getUrgentTasks() -> [ContextualTask] {
        return todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .high || urgency == .critical
        }
    }
    
    public func getNextScheduledTask() -> ContextualTask? {
        return todaysTasks
            .filter { !$0.isCompleted }
            .sorted { first, second in
                let firstUrgency = first.urgency ?? .medium
                let secondUrgency = second.urgency ?? .medium
                
                if firstUrgency != secondUrgency {
                    return getUrgencyPriority(firstUrgency) > getUrgencyPriority(secondUrgency)
                }
                
                guard let firstDue = first.dueDate, let secondDue = second.dueDate else {
                    return first.dueDate != nil
                }
                
                return firstDue < secondDue
            }
            .first
    }
    
    public func getCompletedTasksToday() -> [ContextualTask] {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return todaysTasks.filter { task in
            guard let completedDate = task.completedDate else { return false }
            return completedDate >= today && completedDate < tomorrow
        }
    }
    
    public func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return todaysTasks.filter { $0.building?.id == buildingId }
    }
    
    // MARK: - Legacy Compatibility Methods
    
    public func todayWorkers() -> [WorkerProfile] {
        if let worker = currentWorker {
            return [worker]
        }
        return []
    }
    
    public func getUrgentTaskCount() -> Int {
        return todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .high || urgency == .critical
        }.count
    }
    
    // MARK: - Real-time Updates
    
    public func updateTaskStatus(taskId: String, isCompleted: Bool) async {
        if let index = todaysTasks.firstIndex(where: { $0.id == taskId }) {
            todaysTasks[index].isCompleted = isCompleted
            if isCompleted {
                todaysTasks[index].completedDate = Date()
            } else {
                todaysTasks[index].completedDate = nil
            }
        }
    }
    
    public func addNewTask(_ task: ContextualTask) async {
        todaysTasks.append(task)
    }
    
    public func removeTask(withId taskId: String) async {
        todaysTasks.removeAll { $0.id == taskId }
    }
}

// MARK: - Supporting Types

public enum WorkerContextError: Error {
    case noCurrentWorker
    case buildingNotFound
    case taskNotFound
    case clockInFailed(String)
    case operationalDataUnavailable
    
    public var localizedDescription: String {
        switch self {
        case .noCurrentWorker:
            return "No current worker logged in"
        case .buildingNotFound:
            return "Building not found"
        case .taskNotFound:
            return "Task not found"
        case .clockInFailed(let reason):
            return "Clock in failed: \(reason)"
        case .operationalDataUnavailable:
            return "Operational data not available"
        }
    }
}

// MARK: - Extension for Convenience
extension WorkerContextEngine {
    
    public func getWorkerSummary() async -> WorkerSummary {
        let urgentCount = getUrgentTasks().count
        let completedToday = getCompletedTasksToday().count
        let totalTasks = todaysTasks.count
        
        return WorkerSummary(
            workerId: getWorkerId() ?? "unknown",
            workerName: getWorkerName(),
            totalTasksToday: totalTasks,
            completedTasksToday: completedToday,
            urgentTasksPending: urgentCount,
            isClockedIn: isWorkerClockedIn(),
            currentBuilding: getCurrentBuilding()?.name
        )
    }
}

public struct WorkerSummary {
    public let workerId: String
    public let workerName: String
    public let totalTasksToday: Int
    public let completedTasksToday: Int
    public let urgentTasksPending: Int
    public let isClockedIn: Bool
    public let currentBuilding: String?
}

// MARK: - 📝 PHASE 1 IMPLEMENTATION NOTES
/*
 🔧 PHASE 1 FIXES IMPLEMENTED:
 
 ✅ CRITICAL DATA FLOW CONNECTION:
 - Added OperationalDataManager dependency
 - Connected to real operational data via getTasksForWorker()
 - Workers now see actual assignments from realWorldTasks array
 
 ✅ KEVIN'S RUBIN MUSEUM PRESERVED:
 - Kevin (ID "4") gets his Rubin Museum tasks from operational data
 - Building assignments come from actual operational assignments
 - All worker assignments preserved from OperationalDataManager
 
 ✅ WEATHER INTEGRATION:
 - Added WeatherDataAdapter for contextual task generation
 - Weather-based task urgency adjustments
 - Dynamic weather task creation (storm drains, snow removal)
 
 ✅ ENHANCED TASK GENERATION:
 - generateContextualTasks() uses operational data as foundation
 - Weather context added to existing tasks
 - Intelligent task sorting by urgency
 
 ✅ PRESERVED FUNCTIONALITY:
 - All existing methods maintained
 - Clock in/out functionality preserved
 - Task management capabilities intact
 - Real-time updates continue working
 
 🎯 RESULT: WorkerContextEngine now connects to real operational data
 while preserving all existing functionality and Kevin's Rubin Museum assignments.
 */
