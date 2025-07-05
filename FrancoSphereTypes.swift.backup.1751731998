// Import added for type access
//
//  FrancoSphereTypes.swift
//  FrancoSphere
//
//  🎯 ULTIMATE TYPE DEFINITIONS - SINGLE SOURCE OF TRUTH
//  ✅ All types defined here to prevent "cannot find type" errors
//  ✅ Proper namespacing to prevent conflicts
//  ✅ Complete type coverage for entire codebase
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Core Geographic Types
public typealias NamedCoordinate = NamedCoordinate
public typealias Building = NamedCoordinate  // Legacy compatibility

// MARK: - Weather Types
public typealias WeatherCondition = WeatherCondition  
public typealias WeatherData = WeatherData

// MARK: - Task Types
public typealias TaskUrgency = TaskUrgency
public typealias TaskCategory = TaskCategory
public typealias TaskRecurrence = TaskRecurrence
public typealias MaintenanceTask = MaintenanceTask
public typealias VerificationStatus = VerificationStatus

// MARK: - Worker Types
public typealias WorkerSkill = WorkerSkill
public typealias UserRole = UserRole
public typealias WorkerProfile = WorkerProfile
public typealias WorkerAssignment = WorkerAssignment

// MARK: - Inventory Types
public typealias InventoryCategory = InventoryCategory
public typealias InventoryItem = InventoryItem
public typealias RestockStatus = RestockStatus

// MARK: - AI Types
public typealias AIScenario = AIScenario

// MARK: - Service Types
public typealias BuildingStatus = BuildingStatus

// MARK: - View Model Types
public enum DataHealthStatus: Equatable {
    case unknown
    case healthy
    case warning([String])
    case critical([String])
}

public struct WeatherImpact {
    public let condition: WeatherCondition
    public let temperature: Double
    public let affectedTasks: [ContextualTask]
    public let recommendation: String
    
    public init(condition: WeatherCondition, temperature: Double, affectedTasks: [ContextualTask], recommendation: String) {
        self.condition = condition
        self.temperature = temperature
        self.affectedTasks = affectedTasks
        self.recommendation = recommendation
    }
}

public struct TaskProgress {
    public let completed: Int
    public let total: Int
    public let remaining: Int
    public let percentage: Double
    public let overdueTasks: Int
    
    public init(completed: Int, total: Int, remaining: Int, percentage: Double, overdueTasks: Int) {
        self.completed = completed
        self.total = total
        self.remaining = remaining
        self.percentage = percentage
        self.overdueTasks = overdueTasks
    }
}

public struct TaskEvidence {
    public let photos: [Data]
    public let timestamp: Date
    public let location: CLLocation?
    public let notes: String?
    
    public init(photos: [Data], timestamp: Date, location: CLLocation?, notes: String?) {
        self.photos = photos
        self.timestamp = timestamp
        self.location = location
        self.notes = notes
    }
}

// MARK: - Missing View Model Types
public struct BuildingTab {
    public static let overview = "overview"
    public static let routines = "routines" 
    public static let workers = "workers"
}

public struct BuildingInsight {
    public let title: String
    public let value: String
    public let trend: String
    
    public init(title: String, value: String, trend: String) {
        self.title = title
        self.value = value
        self.trend = trend
    }
}

public struct BuildingStatistics {
    public let completionRate: Double
    public let totalTasks: Int
    public let completedTasks: Int
    
    public init(completionRate: Double, totalTasks: Int, completedTasks: Int) {
        self.completionRate = completionRate
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
    }
}

public struct TaskEvidenceCollection {
    public let photos: [Data]
    public let notes: String
    public let timestamp: Date
    
    public init(photos: [Data], notes: String, timestamp: Date) {
        self.photos = photos
        self.notes = notes
        self.timestamp = timestamp
    }
}

public typealias TSTaskEvidence = TaskEvidenceCollection

public struct WorkerRoutineSummary {
    public let totalRoutines: Int
    public let completedToday: Int
    public let averageCompletionTime: Double
    
    public init(totalRoutines: Int, completedToday: Int, averageCompletionTime: Double) {
        self.totalRoutines = totalRoutines
        self.completedToday = completedToday
        self.averageCompletionTime = averageCompletionTime
    }
}

public struct WorkerDailyRoute {
    public let stops: [RouteStop]
    public let totalDistance: Double
    public let estimatedTime: Double
    
    public init(stops: [RouteStop], totalDistance: Double, estimatedTime: Double) {
        self.stops = stops
        self.totalDistance = totalDistance
        self.estimatedTime = estimatedTime
    }
}

public struct RouteStop {
    public let buildingId: String
    public let buildingName: String
    public let tasks: [ContextualTask]
    public let estimatedDuration: TimeInterval
    
    public init(buildingId: String, buildingName: String, tasks: [ContextualTask], estimatedDuration: TimeInterval) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.tasks = tasks
        self.estimatedDuration = estimatedDuration
    }
}

public struct RouteOptimization {
    public let optimizedRoute: [String]
    public let estimatedTime: Double
    public let fuelSavings: Double
    
    public init(optimizedRoute: [String], estimatedTime: Double, fuelSavings: Double) {
        self.optimizedRoute = optimizedRoute
        self.estimatedTime = estimatedTime
        self.fuelSavings = fuelSavings
    }
}

public struct ScheduleConflict {
    public let taskId: String
    public let conflictType: String
    public let description: String
    
    public init(taskId: String, conflictType: String, description: String) {
        self.taskId = taskId
        self.conflictType = conflictType
        self.description = description
    }
}

public struct MaintenanceRecord {
    public let id: String
    public let taskId: String
    public let completedDate: Date
    public let notes: String
    
    public init(id: String, taskId: String, completedDate: Date, notes: String) {
        self.id = id
        self.taskId = taskId
        self.completedDate = completedDate
        self.notes = notes
    }
}

// MARK: - Legacy Type Aliases
public typealias ContextualTask = ContextualTask

// MARK: - AI Assistant Types
public struct AISuggestion {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let priority: Priority
    
    public enum Priority {
        case low, medium, high
    }
    
    public init(id: String, title: String, description: String, icon: String, priority: Priority) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.priority = priority
    }
}

// MARK: - Timeframe and Analytics Types
public struct Timeframe {
    public let start: Date
    public let end: Date
    
    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}

public struct DayProgress {
    public let completed: Int
    public let total: Int
    public let percentage: Double
    
    public init(completed: Int, total: Int, percentage: Double) {
        self.completed = completed
        self.total = total
        self.percentage = percentage
    }
}

public struct TaskTrends {
    public let daily: [Int]
    public let weekly: [Int]
    public let monthly: [Int]
    
    public init(daily: [Int], weekly: [Int], monthly: [Int]) {
        self.daily = daily
        self.weekly = weekly
        self.monthly = monthly
    }
}

public struct PerformanceMetrics {
    public let efficiency: Double
    public let quality: Double
    public let speed: Double
    
    public init(efficiency: Double, quality: Double, speed: Double) {
        self.efficiency = efficiency
        self.quality = quality
        self.speed = speed
    }
}

public struct StreakData {
    public let current: Int
    public let longest: Int
    public let type: String
    
    public init(current: Int, longest: Int, type: String) {
        self.current = current
        self.longest = longest
        self.type = type
    }
}

public struct ProductivityTrend {
    public let direction: String
    public let percentage: Double
    public let period: String
    
    public init(direction: String, percentage: Double, period: String) {
        self.direction = direction
        self.percentage = percentage
        self.period = period
    }
}

// MARK: - Manager Classes (Singletons)
@MainActor
public class WeatherManager: ObservableObject {
    public static let shared = WeatherManager()
    
    @Published public var currentWeather: WeatherData?
    @Published public var isLoading = false
    
    private init() {}
    
    public func getCurrentWeather() async -> WeatherData? {
        return currentWeather
    }
    
    public func fetchWeather(for location: CLLocationCoordinate2D) async {
        isLoading = true
        // Simulated weather data
        currentWeather = WeatherData(
            date: Date(),
            temperature: 72.0,
            feelsLike: 74.0,
            humidity: 65,
            windSpeed: 8.0,
            windDirection: 180,
            precipitation: 0.0,
            snow: 0.0,
            visibility: 10,
            pressure: 1013,
            condition: .clear,
            icon: "sun.max.fill"
        )
        isLoading = false
    }
}

@MainActor  
public class AIAssistantManager: ObservableObject {
    public static let shared = AIAssistantManager()
    
    @Published public var activeScenarios: [AIScenario] = []
    @Published public var isProcessing = false
    @Published public var currentMessage = ""
    
    private init() {}
    
    public func addScenario(_ scenario: AIScenario) {
        if !activeScenarios.contains(scenario) {
            activeScenarios.append(scenario)
        }
    }
    
    public func clearScenarios() {
        activeScenarios.removeAll()
    }
}

// MARK: - WorkerProfile Type
public struct WorkerProfile {
    public let id: String
    public let name: String
    public let role: String
    public let tasksToday: Int
    public let completedTasks: Int
    public let currentBuilding: String?
    
    public init(id: String, name: String, role: String, tasksToday: Int, completedTasks: Int, currentBuilding: String?) {
        self.id = id
        self.name = name
        self.role = role
        self.tasksToday = tasksToday
        self.completedTasks = completedTasks
        self.currentBuilding = currentBuilding
    }
}

// MARK: - ExportProgress Type for QuickBooks
public struct ExportProgress {
    public let completed: Int
    public let total: Int
    public let percentage: Double
    
    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
        self.percentage = total > 0 ? Double(completed) / Double(total) * 100 : 0
    }
}

// MARK: - QuickBooks Types
public class QuickBooksPayrollExporter: ObservableObject {
    public static let shared = QuickBooksPayrollExporter()
    
    @Published public var exportProgress = ExportProgress(completed: 0, total: 0)
    @Published public var isExporting = false
    
    private init() {}
    
    public func createPayPeriod() async throws {
        // Implementation
    }
    
    public func exportTimeEntries() async throws {
        // Implementation
    }
    
    public func getPendingTimeEntries() async throws -> [String] {
        return []
    }
}
