//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  ✅ CLEAN VERSION: All core model definitions
//  ✅ No duplicate types, no shell commands, no corruption
//  ✅ Compatible with CoreTypes and GRDB
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Core Data Models

public struct NamedCoordinate: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let address: String?
    public let latitude: Double
    public let longitude: Double
    public let imageAssetName: String?
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(id: String, name: String, address: String? = nil, latitude: Double, longitude: Double, imageAssetName: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.imageAssetName = imageAssetName
    }
}

public struct WorkerProfile: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let email: String
    public let role: String
    public let phone: String?
    public let hourlyRate: Double?
    public let skills: [String]?
    public let isActive: Bool
    
    public init(id: String, name: String, email: String, role: String, phone: String? = nil, hourlyRate: Double? = nil, skills: [String]? = nil, isActive: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.phone = phone
        self.hourlyRate = hourlyRate
        self.skills = skills
        self.isActive = isActive
    }
}

public struct ContextualTask: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let category: TaskCategory
    public let urgency: TaskUrgency
    public let buildingId: String
    public let buildingName: String?
    public let assignedWorkerId: String?
    public let assignedWorkerName: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    public let dueDate: Date?
    public let estimatedDuration: TimeInterval
    public let recurrence: TaskRecurrence
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: TaskCategory,
        urgency: TaskUrgency,
        buildingId: String,
        buildingName: String? = nil,
        assignedWorkerId: String? = nil,
        assignedWorkerName: String? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        dueDate: Date? = nil,
        estimatedDuration: TimeInterval = 3600,
        recurrence: TaskRecurrence = .none,
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.urgency = urgency
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.assignedWorkerId = assignedWorkerId
        self.assignedWorkerName = assignedWorkerName
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.recurrence = recurrence
        self.notes = notes
    }
}

// MARK: - Enums

public enum TaskCategory: String, Codable, CaseIterable {
    case cleaning = "Cleaning"
    case maintenance = "Maintenance"
    case repair = "Repair"
    case sanitation = "Sanitation"
    case inspection = "Inspection"
    case security = "Security"
    case landscaping = "Landscaping"
    case hvac = "HVAC"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case other = "Other"
}

public enum TaskUrgency: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
    case emergency = "Emergency"
}

public enum TaskRecurrence: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}

public enum WorkerStatus: String, Codable, CaseIterable {
    case available = "Available"
    case busy = "Busy"
    case onBreak = "On Break"
    case offline = "Offline"
    case clockedOut = "Clocked Out"
}

public enum WeatherCondition: String, Codable, CaseIterable {
    case clear = "Clear"
    case partlyCloudy = "Partly Cloudy"
    case cloudy = "Cloudy"
    case rain = "Rain"
    case snow = "Snow"
    case thunderstorm = "Thunderstorm"
    case fog = "Fog"
    case windy = "Windy"
}

public enum TrendDirection: String, Codable, CaseIterable {
    case up = "up"
    case down = "down"
    case stable = "stable"
    
    public var icon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    public var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .blue
        }
    }
}

// MARK: - Weather Data

public struct WeatherData: Identifiable, Codable, Hashable {
    public let id: String
    public let date: Date
    public let temperature: Double
    public let feelsLike: Double
    public let humidity: Int
    public let windSpeed: Double
    public let windDirection: Int
    public let precipitation: Double
    public let snow: Double
    public let condition: WeatherCondition
    public let uvIndex: Int
    public let visibility: Double
    public let description: String
    
    public init(
        id: String = UUID().uuidString,
        date: Date,
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        windSpeed: Double,
        windDirection: Int,
        precipitation: Double,
        snow: Double,
        condition: WeatherCondition,
        uvIndex: Int,
        visibility: Double,
        description: String
    ) {
        self.id = id
        self.date = date
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.precipitation = precipitation
        self.snow = snow
        self.condition = condition
        self.uvIndex = uvIndex
        self.visibility = visibility
        self.description = description
    }
}

// MARK: - Task Progress

public struct TaskProgress: Codable, Hashable {
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

// MARK: - Building Analytics

public struct BuildingAnalytics: Codable, Hashable {
    public let buildingId: String
    public let completionRate: Double
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let activeWorkers: Int
    public let uniqueWorkers: Int
    public let averageTaskDuration: TimeInterval
    public let lastUpdated: Date
    
    public init(
        buildingId: String,
        completionRate: Double,
        totalTasks: Int,
        completedTasks: Int,
        overdueTasks: Int,
        activeWorkers: Int,
        uniqueWorkers: Int,
        averageTaskDuration: TimeInterval,
        lastUpdated: Date = Date()
    ) {
        self.buildingId = buildingId
        self.completionRate = completionRate
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.overdueTasks = overdueTasks
        self.activeWorkers = activeWorkers
        self.uniqueWorkers = uniqueWorkers
        self.averageTaskDuration = averageTaskDuration
        self.lastUpdated = lastUpdated
    }
}

// MARK: - Extensions for UI

extension TaskCategory {
    public var color: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        case .security: return .yellow
        case .landscaping: return .mint
        case .hvac: return .cyan
        case .electrical: return .indigo
        case .plumbing: return .teal
        case .other: return .gray
        }
    }
    
    public var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench"
        case .repair: return "hammer"
        case .sanitation: return "trash"
        case .inspection: return "magnifyingglass"
        case .security: return "shield"
        case .landscaping: return "leaf"
        case .hvac: return "wind"
        case .electrical: return "bolt"
        case .plumbing: return "drop"
        case .other: return "ellipsis"
        }
    }
}

extension TaskUrgency {
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        case .critical: return .red
        case .emergency: return .red
        }
    }
    
    public var priority: Int {
        switch self {
        case .emergency: return 6
        case .critical: return 5
        case .urgent: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

// MARK: - Compliance Types

public struct ComplianceIssue: Identifiable, Codable, Hashable {
    public let id: String
    public let type: ComplianceIssueType
    public let severity: ComplianceSeverity
    public let buildingId: String
    public let description: String
    public let detectedDate: Date
    public let resolvedDate: Date?
    public let isResolved: Bool
    
    public init(
        id: String = UUID().uuidString,
        type: ComplianceIssueType,
        severity: ComplianceSeverity,
        buildingId: String,
        description: String,
        detectedDate: Date = Date(),
        resolvedDate: Date? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.buildingId = buildingId
        self.description = description
        self.detectedDate = detectedDate
        self.resolvedDate = resolvedDate
        self.isResolved = isResolved
    }
}

public enum ComplianceIssueType: String, Codable, CaseIterable {
    case safety = "Safety"
    case environmental = "Environmental"
    case documentation = "Documentation"
    case maintenance = "Maintenance"
    case regulatory = "Regulatory"
    case other = "Other"
}

public enum ComplianceSeverity: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

extension ComplianceIssueType {
    public var icon: String {
        switch self {
        case .safety: return "shield.checkered"
        case .environmental: return "leaf"
        case .documentation: return "doc.text"
        case .maintenance: return "wrench"
        case .regulatory: return "checkmark.seal"
        case .other: return "ellipsis.circle"
        }
    }
}
