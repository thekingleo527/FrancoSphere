//
//  FrancoSphereTypes.swift
//  FrancoSphere
//
//  ✅ GLOBAL TYPES - All task types in one place for easy import
//

import Foundation
import SwiftUI
import CoreLocation
import Combine

// MARK: - MaintenanceTask (Primary task type)
public struct MaintenanceTask: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let buildingId: String
    public let buildingName: String
    public let category: TaskCategory
    public let urgency: TaskUrgency
    public let recurrence: TaskRecurrence
    public let startTime: String
    public let endTime: String
    public let skillLevel: String
    public let status: String
    public let assignedWorkerName: String
    public let notes: String?
    public let estimatedDuration: TimeInterval
    public let completedAt: Date?
    
    public init(id: String = UUID().uuidString,
         name: String,
         buildingId: String,
         buildingName: String,
         category: TaskCategory,
         urgency: TaskUrgency = .medium,
         recurrence: TaskRecurrence = .daily,
         startTime: String,
         endTime: String,
         skillLevel: String = "Basic",
         status: String = "pending",
         assignedWorkerName: String,
         notes: String? = nil,
         estimatedDuration: TimeInterval = 3600,
         completedAt: Date? = nil) {
        
        self.id = id
        self.name = name
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.category = category
        self.urgency = urgency
        self.recurrence = recurrence
        self.startTime = startTime
        self.endTime = endTime
        self.skillLevel = skillLevel
        self.status = status
        self.assignedWorkerName = assignedWorkerName
        self.notes = notes
        self.estimatedDuration = estimatedDuration
        self.completedAt = completedAt
    }
}

// MARK: - TaskCategory
public enum TaskCategory: String, CaseIterable, Codable, Hashable {
    case cleaning = "Cleaning"
    case sanitation = "Sanitation"
    case maintenance = "Maintenance"
    case inspection = "Inspection"
    case delivery = "Delivery"
    case dsny = "DSNY"
    case emergency = "Emergency"
    case routine = "Routine"
    
    public var icon: String {
        switch self {
        case .cleaning: return "🧹"
        case .sanitation: return "🗑️"
        case .maintenance: return "🔧"
        case .inspection: return "🔍"
        case .delivery: return "📦"
        case .dsny: return "🚛"
        case .emergency: return "🚨"
        case .routine: return "📋"
        }
    }
    
    public var color: String {
        switch self {
        case .cleaning: return "blue"
        case .sanitation: return "green"
        case .maintenance: return "orange"
        case .inspection: return "purple"
        case .delivery: return "brown"
        case .dsny: return "yellow"
        case .emergency: return "red"
        case .routine: return "gray"
        }
    }
}

// MARK: - TaskUrgency
public enum TaskUrgency: String, CaseIterable, Codable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var priority: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        }
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

// MARK: - TaskRecurrence
public enum TaskRecurrence: String, CaseIterable, Codable, Hashable {
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
    case oneOff = "One-off"
    
    public var shortForm: String {
        switch self {
        case .daily: return "D"
        case .weekly: return "W"
        case .biweekly: return "BW"
        case .monthly: return "M"
        case .quarterly: return "Q"
        case .yearly: return "Y"
        case .oneOff: return "1x"
        }
    }
}

// MARK: - TaskEvidence (Global evidence type)
public struct TaskEvidence: Codable, Hashable {
    public let photos: [Data]
    public let timestamp: Date
    public let location: CLLocation?
    public let notes: String?
    
    public init(photos: [Data] = [], timestamp: Date = Date(), location: CLLocation? = nil, notes: String? = nil) {
        self.photos = photos
        self.timestamp = timestamp
        self.location = location
        self.notes = notes
    }
}

// MARK: - TSTaskEvidence (Alias for compatibility)
public typealias TSTaskEvidence = TaskEvidence

// MARK: - DataHealthStatus (Global type)
public enum DataHealthStatus: Equatable, Hashable {
    case unknown
    case healthy
    case warning([String])
    case critical([String])
    
    public var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .healthy: return "Healthy"
        case .warning(let issues): return "Warning: \(issues.joined(separator: ", "))"
        case .critical(let issues): return "Critical: \(issues.joined(separator: ", "))"
        }
    }
}

// MARK: - WeatherImpact (Global type)
public struct WeatherImpact: Hashable {
    public let condition: String
    public let temperature: Double
    public let affectedTasks: [ContextualTask]
    public let recommendation: String
    
    public init(condition: String, temperature: Double, affectedTasks: [ContextualTask], recommendation: String) {
        self.condition = condition
        self.temperature = temperature
        self.affectedTasks = affectedTasks
        self.recommendation = recommendation
    }
}

// MARK: - WeatherManager (Global weather management)
@MainActor
public class WeatherManager: ObservableObject {
    public static let shared = WeatherManager()
    
    @Published public var currentWeather: FrancoSphere.WeatherData?
    @Published public var isLoading = false
    @Published public var error: Error?
    
    private var cancellables = Set<AnyCancellable>()
    private let updateInterval: TimeInterval = 1800 // 30 minutes
    
    private init() {
        startPeriodicUpdates()
    }
    
    public func fetchCurrentWeather() async {
        isLoading = true
        error = nil
        
        do {
            // Simulate weather API call for NYC
            let weather = FrancoSphere.WeatherData(
                temperature: Double.random(in: 20...85),
                condition: FrancoSphere.WeatherCondition.allCases.randomElement() ?? .clear,
                humidity: Double.random(in: 30...90),
                windSpeed: Double.random(in: 0...25),
                timestamp: Date()
            )
            
            currentWeather = weather
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
    
    public func getWeatherImpactForTask(_ task: MaintenanceTask) -> WeatherImpact? {
        guard let weather = currentWeather else { return nil }
        
        // Determine if weather affects this task
        let isOutdoorTask = task.category == .cleaning || 
                           task.category == .sanitation ||
                           task.name.lowercased().contains("sidewalk") ||
                           task.name.lowercased().contains("hose")
        
        guard isOutdoorTask else { return nil }
        
        var recommendation = "Normal conditions for outdoor work."
        
        switch weather.condition {
        case .rain:
            recommendation = "Rain detected. Consider postponing sidewalk hosing and outdoor cleaning."
        case .snow:
            recommendation = "Snow conditions. Focus on snow removal and postpone non-essential outdoor tasks."
        default:
            if weather.temperature < 32 {
                recommendation = "Freezing temperatures. Take precautions for outdoor work."
            } else if weather.temperature > 90 {
                recommendation = "High temperature. Take frequent breaks and stay hydrated."
            } else if weather.windSpeed > 20 {
                recommendation = "High winds. Secure loose items during outdoor work."
            }
        }
        
        return WeatherImpact(
            condition: weather.condition.rawValue,
            temperature: weather.temperature,
            affectedTasks: [],
            recommendation: recommendation
        )
    }
    
    private func startPeriodicUpdates() {
        Timer.publish(every: updateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.fetchCurrentWeather()
                }
            }
            .store(in: &cancellables)
        
        // Initial fetch
        Task {
            await fetchCurrentWeather()
        }
    }
}

// MARK: - MaintenanceTask Extensions
public extension MaintenanceTask {
    
    // Convert from ContextualTask
    init(from contextualTask: ContextualTask) {
        self.init(
            id: contextualTask.id,
            name: contextualTask.name,
            buildingId: contextualTask.buildingId,
            buildingName: contextualTask.buildingName,
            category: TaskCategory(rawValue: contextualTask.category) ?? .routine,
            urgency: TaskUrgency(rawValue: contextualTask.urgencyLevel) ?? .medium,
            recurrence: TaskRecurrence(rawValue: contextualTask.recurrence) ?? .daily,
            startTime: contextualTask.startTime,
            endTime: contextualTask.endTime,
            skillLevel: contextualTask.skillLevel,
            status: contextualTask.status,
            assignedWorkerName: contextualTask.assignedWorkerName
        )
    }
    
    // Convert to ContextualTask
    func toContextualTask() -> ContextualTask {
        return ContextualTask(
            id: id,
            name: name,
            buildingId: buildingId,
            buildingName: buildingName,
            category: category.rawValue,
            startTime: startTime,
            endTime: endTime,
            recurrence: recurrence.rawValue,
            skillLevel: skillLevel,
            status: status,
            urgencyLevel: urgency.rawValue,
            assignedWorkerName: assignedWorkerName
        )
    }
}

// MARK: - Global Type Aliases for Easy Access
public typealias Task = MaintenanceTask
public typealias Evidence = TaskEvidence
public typealias Category = TaskCategory
public typealias Urgency = TaskUrgency
public typealias Recurrence = TaskRecurrence
