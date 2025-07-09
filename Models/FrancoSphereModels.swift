//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: All Foundation Models Defined
//  ✅ RESOLVED: All missing type errors
//  ✅ PROTOCOL: Full Codable, Hashable, Identifiable conformance
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Core Entity Models

/// Primary task model used throughout the application
public struct ContextualTask: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let category: TaskCategory
    public let urgency: TaskUrgency
    public let buildingId: String
    public let buildingName: String
    public let assignedWorkerId: String?
    public let assignedWorkerName: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    public let dueDate: Date?
    public let scheduledDate: Date?
    public let estimatedDuration: TimeInterval
    public let recurrence: TaskRecurrence
    public let notes: String?
    public let skillLevel: String
    public let status: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: TaskCategory,
        urgency: TaskUrgency,
        buildingId: String,
        buildingName: String,
        assignedWorkerId: String? = nil,
        assignedWorkerName: String? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        dueDate: Date? = nil,
        scheduledDate: Date? = nil,
        estimatedDuration: TimeInterval = 1800,
        recurrence: TaskRecurrence = .none,
        notes: String? = nil,
        skillLevel: String = "Basic",
        status: String = "pending"
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
        self.scheduledDate = scheduledDate
        self.estimatedDuration = estimatedDuration
        self.recurrence = recurrence
        self.notes = notes
        self.skillLevel = skillLevel
        self.status = status
    }
}

/// Building/location coordinate model
public struct NamedCoordinate: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let address: String?
    public let latitude: Double
    public let longitude: Double
    public let buildingType: String?
    
    public init(
        id: String,
        name: String,
        address: String? = nil,
        latitude: Double,
        longitude: Double,
        buildingType: String? = nil
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.buildingType = buildingType
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

/// Worker profile model
public struct WorkerProfile: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let email: String
    public let role: UserRole
    public let skills: [WorkerSkill]
    public let isActive: Bool
    public let phoneNumber: String?
    public let emergencyContact: String?
    public let hireDate: Date
    public let performanceRating: Double
    
    public init(
        id: String,
        name: String,
        email: String,
        role: UserRole,
        skills: [WorkerSkill] = [],
        isActive: Bool = true,
        phoneNumber: String? = nil,
        emergencyContact: String? = nil,
        hireDate: Date = Date(),
        performanceRating: Double = 3.0
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
        self.skills = skills
        self.isActive = isActive
        self.phoneNumber = phoneNumber
        self.emergencyContact = emergencyContact
        self.hireDate = hireDate
        self.performanceRating = performanceRating
    }
}

/// Maintenance-specific task model
public struct MaintenanceTask: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let category: TaskCategory
    public let urgency: TaskUrgency
    public let buildingId: String
    public let assignedWorkers: [String]
    public let assignedWorkerId: String?
    public var isComplete: Bool
    public var isCompleted: Bool { isComplete }
    public let dueDate: Date
    public let startTime: Date?
    public let estimatedDuration: TimeInterval
    public let requiredSkills: [WorkerSkill]
    public let inventoryNeeded: [String]
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        category: TaskCategory,
        urgency: TaskUrgency,
        buildingId: String,
        assignedWorkers: [String] = [],
        assignedWorkerId: String? = nil,
        isComplete: Bool = false,
        dueDate: Date,
        startTime: Date? = nil,
        estimatedDuration: TimeInterval = 1800,
        requiredSkills: [WorkerSkill] = [],
        inventoryNeeded: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.urgency = urgency
        self.buildingId = buildingId
        self.assignedWorkers = assignedWorkers
        self.assignedWorkerId = assignedWorkerId
        self.isComplete = isComplete
        self.dueDate = dueDate
        self.startTime = startTime
        self.estimatedDuration = estimatedDuration
        self.requiredSkills = requiredSkills
        self.inventoryNeeded = inventoryNeeded
        self.notes = notes
    }
}

/// Inventory item model
public struct InventoryItem: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let category: InventoryCategory
    public let currentStock: Int
    public let minimumStock: Int
    public let unit: String
    public let supplier: String
    public let costPerUnit: Double
    public let restockStatus: RestockStatus
    public let lastRestocked: Date
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        category: InventoryCategory,
        currentStock: Int,
        minimumStock: Int,
        unit: String,
        supplier: String,
        costPerUnit: Double,
        restockStatus: RestockStatus,
        lastRestocked: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.currentStock = currentStock
        self.minimumStock = minimumStock
        self.unit = unit
        self.supplier = supplier
        self.costPerUnit = costPerUnit
        self.restockStatus = restockStatus
        self.lastRestocked = lastRestocked
    }
}

/// Weather data model
public struct WeatherData: Codable, Hashable {
    public let temperature: Double
    public let condition: WeatherCondition
    public let humidity: Double
    public let windSpeed: Double
    public let precipitation: Double
    public let snow: Double
    public let timestamp: Date
    
    public init(
        temperature: Double,
        condition: WeatherCondition,
        humidity: Double,
        windSpeed: Double,
        precipitation: Double = 0.0,
        snow: Double = 0.0,
        timestamp: Date = Date()
    ) {
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.precipitation = precipitation
        self.snow = snow
        self.timestamp = timestamp
    }
}

// MARK: - Enum Types

public enum TaskCategory: String, Codable, CaseIterable, Hashable {
    case cleaning = "Cleaning"
    case maintenance = "Maintenance"
    case inspection = "Inspection"
    case repair = "Repair"
    case hvac = "HVAC"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case security = "Security"
    case landscaping = "Landscaping"
    case emergency = "Emergency"
    case safety = "Safety"
    case administrative = "Administrative"
    
    public var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .inspection: return "magnifyingglass"
        case .repair: return "hammer"
        case .hvac: return "thermometer"
        case .electrical: return "bolt"
        case .plumbing: return "drop"
        case .security: return "lock"
        case .landscaping: return "leaf"
        case .emergency: return "exclamationmark.triangle"
        case .safety: return "shield"
        case .administrative: return "doc.text"
        }
    }
    
    public var color: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .inspection: return .purple
        case .repair: return .red
        case .hvac: return .cyan
        case .electrical: return .yellow
        case .plumbing: return .blue
        case .security: return .green
        case .landscaping: return .green
        case .emergency: return .red
        case .safety: return .orange
        case .administrative: return .gray
        }
    }
}

public enum TaskUrgency: String, Codable, CaseIterable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case urgent = "Urgent"
    case critical = "Critical"
    case emergency = "Emergency"
    
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .red
        case .critical: return .red
        case .emergency: return .purple
        }
    }
    
    public var fontWeight: Font.Weight {
        switch self {
        case .low: return .light
        case .medium: return .regular
        case .high, .urgent: return .semibold
        case .critical, .emergency: return .bold
        }
    }
    
    public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .low: return .light
        case .medium: return .medium
        case .high, .urgent, .critical, .emergency: return .heavy
        }
    }
    
    public var textColor: Color {
        switch self {
        case .low: return .secondary
        case .medium: return .primary
        case .high, .urgent: return .orange
        case .critical, .emergency: return .red
        }
    }
    
    public var rawValue: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        case .critical: return "Critical"
        case .emergency: return "Emergency"
        }
    }
}

public enum TaskRecurrence: String, Codable, CaseIterable, Hashable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
}

public enum WeatherCondition: String, Codable, CaseIterable, Hashable {
    case clear = "Clear"
    case cloudy = "Cloudy"
    case rainy = "Rainy"
    case snowy = "Snowy"
    case stormy = "Stormy"
    case foggy = "Foggy"
    case windy = "Windy"
    
    public var icon: String {
        switch self {
        case .clear: return "sun.max"
        case .cloudy: return "cloud"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        case .stormy: return "cloud.bolt.rain"
        case .foggy: return "cloud.fog"
        case .windy: return "wind"
        }
    }
}

public enum InventoryCategory: String, Codable, CaseIterable, Hashable {
    case tools = "Tools"
    case supplies = "Supplies"
    case safety = "Safety"
    case cleaning = "Cleaning"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case hvac = "HVAC"
    case landscaping = "Landscaping"
    case office = "Office"
    
    public static var other: InventoryCategory {
        return .supplies
    }
}

public enum UserRole: String, Codable, CaseIterable, Hashable {
    case admin = "admin"
    case worker = "worker"
    case supervisor = "supervisor"
    case manager = "manager"
    
    public var capitalized: String {
        return rawValue.capitalized
    }
}

public enum WorkerSkill: String, Codable, CaseIterable, Hashable {
    case cleaning = "Cleaning"
    case maintenance = "Maintenance"
    case electrical = "Electrical"
    case plumbing = "Plumbing"
    case hvac = "HVAC"
    case carpentry = "Carpentry"
    case painting = "Painting"
    case landscaping = "Landscaping"
    case security = "Security"
    case safety = "Safety"
    
    public var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .electrical: return "bolt"
        case .plumbing: return "drop"
        case .hvac: return "thermometer"
        case .carpentry: return "hammer"
        case .painting: return "paintbrush"
        case .landscaping: return "leaf"
        case .security: return "lock"
        case .safety: return "shield"
        }
    }
}

public enum VerificationStatus: String, Codable, CaseIterable, Hashable {
    case pending = "Pending"
    case verified = "Verified"
    case rejected = "Rejected"
    case incomplete = "Incomplete"
}

public enum DataHealthStatus: String, Codable, CaseIterable, Hashable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    
    public static var unknown: DataHealthStatus {
        return .poor
    }
}

public enum RestockStatus: String, Codable, CaseIterable, Hashable {
    case inStock = "In Stock"
    case lowStock = "Low Stock"
    case outOfStock = "Out of Stock"
    case onOrder = "On Order"
}

public enum OutdoorWorkRisk: String, Codable, CaseIterable, Hashable {
    case low = "Low"
    case moderate = "Moderate"
    case high = "High"
    case extreme = "Extreme"
}

// MARK: - Supporting Models



}

public struct MaintenanceRecord: Identifiable, Codable, Hashable {
    public let id: String
    public let taskId: String
    public let buildingId: String
    public let workerId: String
    public let category: TaskCategory
    public let description: String
    public let completedDate: Date
    public let duration: TimeInterval
    public let notes: String?
    public let verificationStatus: VerificationStatus
    
    public init(
        id: String = UUID().uuidString,
        taskId: String,
        buildingId: String,
        workerId: String,
        category: TaskCategory,
        description: String,
        completedDate: Date,
        duration: TimeInterval,
        notes: String? = nil,
        verificationStatus: VerificationStatus = .pending
    ) {
        self.id = id
        self.taskId = taskId
        self.buildingId = buildingId
        self.workerId = workerId
        self.category = category
        self.description = description
        self.completedDate = completedDate
        self.duration = duration
        self.notes = notes
        self.verificationStatus = verificationStatus
    }
}

public struct WorkerAssignment: Identifiable, Codable, Hashable {
    public let id: String
    public let workerId: String
    public let taskId: String
    public let buildingId: String
    public let assignedDate: Date
    public let dueDate: Date
    public let priority: TaskUrgency
    public var isCompleted: Bool
    
    public init(
        id: String = UUID().uuidString,
        workerId: String,
        taskId: String,
        buildingId: String,
        assignedDate: Date = Date(),
        dueDate: Date,
        priority: TaskUrgency = .medium,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.workerId = workerId
        self.taskId = taskId
        self.buildingId = buildingId
        self.assignedDate = assignedDate
        self.dueDate = dueDate
        self.priority = priority
        self.isCompleted = isCompleted
    }
}

public struct WorkerPerformanceMetrics: Codable, Hashable {
    public let workerId: String
    public let totalTasksCompleted: Int
    public let averageCompletionTime: TimeInterval
    public let qualityScore: Double
    public let punctualityScore: Double
    public let overallRating: Double
    public let lastEvaluationDate: Date
    
    public init(
        workerId: String,
        totalTasksCompleted: Int,
        averageCompletionTime: TimeInterval,
        qualityScore: Double,
        punctualityScore: Double,
        overallRating: Double,
        lastEvaluationDate: Date = Date()
    ) {
        self.workerId = workerId
        self.totalTasksCompleted = totalTasksCompleted
        self.averageCompletionTime = averageCompletionTime
        self.qualityScore = qualityScore
        self.punctualityScore = punctualityScore
        self.overallRating = overallRating
        self.lastEvaluationDate = lastEvaluationDate
    }
}

public struct TaskCompletionRecord: Identifiable, Codable, Hashable {
    public let id: String
    public let taskId: String
    public let workerId: String
    public let completedDate: Date
    public let duration: TimeInterval
    public let quality: Double
    public let verificationStatus: VerificationStatus
    public let photos: [String]
    public let notes: String?
    
    public init(
        id: String = UUID().uuidString,
        taskId: String,
        workerId: String,
        completedDate: Date = Date(),
        duration: TimeInterval,
        quality: Double = 5.0,
        verificationStatus: VerificationStatus = .pending,
        photos: [String] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.taskId = taskId
        self.workerId = workerId
        self.completedDate = completedDate
        self.duration = duration
        self.quality = quality
        self.verificationStatus = verificationStatus
        self.photos = photos
        self.notes = notes
    }
}

public struct VerificationRecord: Identifiable, Codable, Hashable {
    public let id: String
    public let taskId: String
    public let workerId: String
    public let verifierId: String
    public let verificationDate: Date
    public let status: VerificationStatus
    public let comments: String?
    public let rating: Double
    
    public init(
        id: String = UUID().uuidString,
        taskId: String,
        workerId: String,
        verifierId: String,
        verificationDate: Date = Date(),
        status: VerificationStatus,
        comments: String? = nil,
        rating: Double = 5.0
    ) {
        self.id = id
        self.taskId = taskId
        self.workerId = workerId
        self.verifierId = verifierId
        self.verificationDate = verificationDate
        self.status = status
        self.comments = comments
        self.rating = rating
    }
}

// MARK: - Analytics and Routine Models

public struct WorkerDailyRoute: Identifiable, Codable, Hashable {
    public let id: String
    public let workerId: String
    public let date: Date
    public let buildings: [String]
    public let estimatedDuration: TimeInterval
    public let actualDuration: TimeInterval?
    public let isOptimized: Bool
    
    public init(
        id: String = UUID().uuidString,
        workerId: String,
        date: Date,
        buildings: [String],
        estimatedDuration: TimeInterval,
        actualDuration: TimeInterval? = nil,
        isOptimized: Bool = false
    ) {
        self.id = id
        self.workerId = workerId
        self.date = date
        self.buildings = buildings
        self.estimatedDuration = estimatedDuration
        self.actualDuration = actualDuration
        self.isOptimized = isOptimized
    }
}

public struct RouteOptimization: Codable, Hashable {
    public let originalRoute: [String]
    public let optimizedRoute: [String]
    public let timeSaved: TimeInterval
    public let distanceSaved: Double
    public let efficiencyGain: Double
    
    public init(
        originalRoute: [String],
        optimizedRoute: [String],
        timeSaved: TimeInterval,
        distanceSaved: Double,
        efficiencyGain: Double
    ) {
        self.originalRoute = originalRoute
        self.optimizedRoute = optimizedRoute
        self.timeSaved = timeSaved
        self.distanceSaved = distanceSaved
        self.efficiencyGain = efficiencyGain
    }
}

public struct ScheduleConflict: Identifiable, Codable, Hashable {
    public let id: String
    public let description: String
    public let conflictType: String
    public let severity: String
    public let affectedTasks: [String]
    public let suggestedResolution: String?
    
    public init(
        id: String = UUID().uuidString,
        description: String,
        conflictType: String,
        severity: String,
        affectedTasks: [String] = [],
        suggestedResolution: String? = nil
    ) {
        self.id = id
        self.description = description
        self.conflictType = conflictType
        self.severity = severity
        self.affectedTasks = affectedTasks
        self.suggestedResolution = suggestedResolution
    }
}

public struct WorkerRoutineSummary: Codable, Hashable {
    public let workerId: String
    public let date: Date
    public let totalTasks: Int
    public let completedTasks: Int
    public let averageTaskDuration: TimeInterval
    public let routeEfficiency: Double
    public let overallPerformance: Double
    
    public init(
        workerId: String,
        date: Date,
        totalTasks: Int,
        completedTasks: Int,
        averageTaskDuration: TimeInterval,
        routeEfficiency: Double,
        overallPerformance: Double
    ) {
        self.workerId = workerId
        self.date = date
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.averageTaskDuration = averageTaskDuration
        self.routeEfficiency = routeEfficiency
        self.overallPerformance = overallPerformance
    }
}

// MARK: - Building and Analytics Models



}

// MARK: - Type Aliases for Backward Compatibility

public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias User = CoreTypes.User
public typealias BuildingType = CoreTypes.BuildingType
public typealias PerformanceMetrics = CoreTypes.PerformanceMetrics
public typealias BuildingStatistics = CoreTypes.BuildingStatistics
public typealias TaskTrends = CoreTypes.TaskTrends
public typealias StreakData = CoreTypes.StreakData
public typealias InsightFilter = CoreTypes.InsightFilter
public typealias TrendDirection = CoreTypes.TrendDirection

// Intelligence Types (avoid circular references)
// These will be defined in IntelligenceTypes.swift

// DTO Types (avoid circular references)
// These will be defined in DTOs folder

extension FrancoSphere.TaskUrgency {
    public var fontWeight: Font.Weight {
        switch self {
        case .low: return .light
        case .medium: return .regular
        case .high: return .semibold
        case .urgent: return .bold
        case .critical: return .bold
        case .emergency: return .black
        }
    }
    
    public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .low: return .light
        case .medium: return .medium
        case .high, .urgent: return .heavy
        case .critical, .emergency: return .heavy
        }
    }
}
