//
//  FrancoSphereModels.swift
//  FrancoSphere
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - Core FrancoSphere Models

//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  ✅ RESTRUCTURED: Clean namespace with all types properly exposed
//
import Foundation
import SwiftUI
import CoreLocation
// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    // MARK: - Core Location Types
    public struct NamedCoordinate: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let imageAssetName: String
        public init(id: String, name: String, latitude: Double, longitude: Double, imageAssetName: String) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.imageAssetName = imageAssetName
        }
    }
    // MARK: - Weather Types
    public enum WeatherCondition: String, CaseIterable, Codable {
        case clear = "clear"
        case cloudy = "cloudy"
        case rain = "rain"
        case snow = "snow"
        case fog = "fog"
        case storm = "storm"
    }
    public struct WeatherData: Codable, Hashable {
        public let temperature: Double
        public let condition: WeatherCondition
        public let humidity: Double
        public let windSpeed: Double
        public let timestamp: Date
        public init(temperature: Double, condition: WeatherCondition, humidity: Double, windSpeed: Double, timestamp: Date) {
            self.temperature = temperature
            self.condition = condition
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.timestamp = timestamp
        }
    }
    // MARK: - Task Types
    public enum TaskCategory: String, CaseIterable, Codable, Hashable {
        case maintenance = "Maintenance"
        case cleaning = "Cleaning"
        case repair = "Repair"
        case inspection = "Inspection"
        case sanitation = "Sanitation"
        public var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver"
            case .cleaning: return "spray.and.wipe"
            case .repair: return "hammer"
            case .inspection: return "checklist"
            case .sanitation: return "trash"
            }
        }
    }
    public enum TaskUrgency: String, CaseIterable, Codable, Hashable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        public var urgencyColor: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    public enum TaskRecurrence: String, CaseIterable, Codable, Hashable {
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case biweekly = "Bi-Weekly"
        case quarterly = "Quarterly"
        case semiannual = "Semi-Annual"
        case annual = "Annual"
    }
    public enum VerificationStatus: String, CaseIterable, Codable, Hashable {
        case pending = "Pending Verification"
        case verified = "Verified"
        case rejected = "Verification Failed"
        public var statusColor: Color {
            switch self {
            case .pending: return .orange
            case .verified: return .green
            case .rejected: return .red
            }
        }
    }
    public struct TaskCompletionInfo: Codable, Hashable {
        public let photoPath: String?
        public let date: Date
        public init(photoPath: String? = nil, date: Date = Date()) {
            self.photoPath = photoPath
            self.date = date
        }
    }
    public struct MaintenanceTask: Identifiable, Codable, Hashable {
        public var id: String
        public var name: String
        public var buildingID: String
        public var description: String
        public var dueDate: Date
        public var startTime: Date?
        public var endTime: Date?
        public var category: TaskCategory
        public var urgency: TaskUrgency
        public var recurrence: TaskRecurrence
        public var isComplete: Bool
        public var assignedWorkers: [String]
        public var requiredSkillLevel: String
        public var verificationStatusValue: VerificationStatus?
        public var completionInfo: TaskCompletionInfo?
        public var externalId: String?
        public init(
            id: String = UUID().uuidString,
            name: String,
            buildingID: String,
            description: String = "",
            dueDate: Date,
            startTime: Date? = nil,
            endTime: Date? = nil,
            category: TaskCategory = .maintenance,
            urgency: TaskUrgency = .medium,
            recurrence: TaskRecurrence = .oneTime,
            isComplete: Bool = false,
            assignedWorkers: [String] = [],
            requiredSkillLevel: String = "Basic",
            verificationStatus: VerificationStatus? = nil,
            completionInfo: TaskCompletionInfo? = nil,
            externalId: String? = nil
        ) {
            self.id = id
            self.name = name
            self.buildingID = buildingID
            self.description = description
            self.dueDate = dueDate
            self.startTime = startTime
            self.endTime = endTime
            self.category = category
            self.urgency = urgency
            self.recurrence = recurrence
            self.isComplete = isComplete
            self.assignedWorkers = assignedWorkers
            self.requiredSkillLevel = requiredSkillLevel
            self.verificationStatusValue = verificationStatus
            self.completionInfo = completionInfo
            self.externalId = externalId
        }
    }
    // MARK: - AI Types
    public enum AIScenario: String, CaseIterable, Codable {
        case routineIncomplete = "routine_incomplete"
        case pendingTasks = "pending_tasks"
        case taskCompletion = "task_completion"
        case missingPhoto = "missing_photo"
        case weatherAlert = "weather_alert"
        case buildingArrival = "building_arrival"
        case clockOutReminder = "clock_out_reminder"
        case inventoryLow = "inventory_low"
    }
    public struct AISuggestion: Identifiable, Codable {
        public let id: String
        public let title: String
        public let message: String
        public let actionType: String
        public let priority: Int
        public init(id: String = UUID().uuidString, title: String, message: String, actionType: String, priority: Int = 1) {
            self.id = id
            self.title = title
            self.message = message
            self.actionType = actionType
            self.priority = priority
        }
    }
    // MARK: - Worker Types
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let role: String
        public let isActive: Bool
        public init(id: String, name: String, email: String, role: String, isActive: Bool = true) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.isActive = isActive
        }
    }
    public enum UserRole: String, CaseIterable, Codable {
        case admin = "Admin"
        case manager = "Manager"
        case worker = "Worker"
        case supervisor = "Supervisor"
    }
    public struct WorkerShift: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let startTime: Date
        public let endTime: Date?
        public let status: String
        public init(id: String, workerId: String, startTime: Date, endTime: Date? = nil, status: String = "active") {
            self.id = id
            self.workerId = workerId
            self.startTime = startTime
            self.endTime = endTime
            self.status = status
        }
    }
    // MARK: - Inventory Types
    public enum InventoryCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case safety = "Safety"
        case tools = "Tools"
        case other = "other"
}
    public enum RestockStatus: String, CaseIterable, Codable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
    }
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let restockStatus: RestockStatus
        public init(id: String, name: String, category: InventoryCategory, currentStock: Int, minimumStock: Int, restockStatus: RestockStatus) {
            self.id = id
            self.name = name
            self.category = category
            self.currentStock = currentStock
            self.minimumStock = minimumStock
            self.restockStatus = restockStatus
        }
    }
    // MARK: - Worker Skill Types
    public enum WorkerSkill: String, CaseIterable, Codable {
        case basic = "Basic"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }
    // MARK: - Building Status Types
    public struct BuildingStatus: Codable {
        public let buildingId: String
        public let completedTasks: Int
        public let pendingTasks: Int
        public let overdueTasks: Int
        public let lastUpdated: Date
        public init(buildingId: String, completedTasks: Int, pendingTasks: Int, overdueTasks: Int, lastUpdated: Date) {
            self.buildingId = buildingId
            self.completedTasks = completedTasks
            self.pendingTasks = pendingTasks
            self.overdueTasks = overdueTasks
            self.lastUpdated = lastUpdated
        }
    }
    // MARK: - Task Completion Record
    public struct TaskCompletionRecord: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let photoPath: String?
        public let notes: String?
        public init(id: String = UUID().uuidString, taskId: String, workerId: String, completedAt: Date, photoPath: String? = nil, notes: String? = nil) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.photoPath = photoPath
            self.notes = notes
        }
    }
    // MARK: - Data Health Status
    public enum DataHealthStatus: Equatable, Hashable {
        case unknown
        case healthy
        case warning([String])
        case critical([String])
    }
    // MARK: - Task Evidence
    
    }
// MARK: - Global Type Aliases (Make types accessible without FrancoSphere prefix)
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias WeatherData = FrancoSphere.WeatherData
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias TaskCompletionInfo = FrancoSphere.TaskCompletionInfo
public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerShift = FrancoSphere.WorkerShift
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias TaskEvidence = FrancoSphere.TaskEvidence
// MARK: - Additional Type Aliases for Compatibility
public typealias TSTaskEvidence = TaskEvidence
public typealias ExportProgress = Double
// MARK: - Missing Supporting Types
public struct WorkerAssignment: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let buildingId: String
    public let startDate: Date
    public let endDate: Date?
    public init(id: String = UUID().uuidString, workerId: String, buildingId: String, startDate: Date, endDate: Date? = nil) {
        self.id = id
        self.workerId = workerId
        self.buildingId = buildingId
        self.startDate = startDate
        self.endDate = endDate
    }
}
public struct WorkerRoutineSummary: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let totalTasks: Int
    public let completedTasks: Int
    public let efficiency: Double
    public init(id: String = UUID().uuidString, workerId: String, totalTasks: Int, completedTasks: Int, efficiency: Double) {
        self.id = id
        self.workerId = workerId
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.efficiency = efficiency
    }
}
public struct WorkerDailyRoute: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let date: Date
    public let stops: [RouteStop]
    public let optimized: Bool
    public init(id: String = UUID().uuidString, workerId: String, date: Date, stops: [RouteStop], optimized: Bool = false) {
        self.id = id
        self.workerId = workerId
        self.date = date
        self.stops = stops
        self.optimized = optimized
    }
}
public struct RouteStop: Identifiable, Codable {
    public let id: String
    public let buildingId: String
    public let estimatedArrival: Date
    public let estimatedDuration: TimeInterval
    public let taskIds: [String]
    public init(id: String = UUID().uuidString, buildingId: String, estimatedArrival: Date, estimatedDuration: TimeInterval, taskIds: [String]) {
        self.id = id
        self.buildingId = buildingId
        self.estimatedArrival = estimatedArrival
        self.estimatedDuration = estimatedDuration
        self.taskIds = taskIds
    }
}
public struct RouteOptimization: Codable {
    public let totalDistance: Double
    public let totalTime: TimeInterval
    public let fuelSavings: Double
    public let optimizationScore: Double
    public init(totalDistance: Double, totalTime: TimeInterval, fuelSavings: Double, optimizationScore: Double) {
        self.totalDistance = totalDistance
        self.totalTime = totalTime
        self.fuelSavings = fuelSavings
        self.optimizationScore = optimizationScore
    }
}
public struct ScheduleConflict: Identifiable, Codable {
    public let id: String
    public let workerId: String
    public let conflictType: String
    public let description: String
    public let severity: String
    public init(id: String = UUID().uuidString, workerId: String, conflictType: String, description: String, severity: String) {
        self.id = id
        self.workerId = workerId
        self.conflictType = conflictType
        self.description = description
        self.severity = severity
    }
}
public struct BuildingInsight: Identifiable, Codable {
    public let id: String
    public let buildingId: String
    public let insightType: String
    public let message: String
    public let priority: Int
    public init(id: String = UUID().uuidString, buildingId: String, insightType: String, message: String, priority: Int) {
        self.id = id
        self.buildingId = buildingId
        self.insightType = insightType
        self.message = message
        self.priority = priority
    }
}
public struct BuildingStatistics: Codable {
    public let totalTasks: Int
    public let completedTasks: Int
    public let efficiency: Double
    public let lastUpdated: Date
    public init(totalTasks: Int, completedTasks: Int, efficiency: Double, lastUpdated: Date) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.efficiency = efficiency
        self.lastUpdated = lastUpdated
    }
}
public enum BuildingTab: String, CaseIterable {
    case overview = "Overview"
    case tasks = "Tasks"
    case inventory = "Inventory"
    case insights = "Insights"
}
public struct MaintenanceRecord: Identifiable, Codable {
    public let id: String
    public let buildingId: String
    public let taskId: String
    public let completedBy: String
    public let completedAt: Date
    public let description: String
    public init(id: String = UUID().uuidString, buildingId: String, taskId: String, completedBy: String, completedAt: Date, description: String) {
        self.id = id
        self.buildingId = buildingId
        self.taskId = taskId
        self.completedBy = completedBy
        self.completedAt = completedAt
        self.description = description
    }
}
public struct FSTaskItem: Identifiable, Codable {
    public let id: String
    public let name: String
    public let description: String
    public let dueDate: Date
    public let isCompleted: Bool
    public init(id: String = UUID().uuidString, name: String, description: String, dueDate: Date, isCompleted: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.dueDate = dueDate
        self.isCompleted = isCompleted
    }
}
// MARK: - Performance & Analytics Types
public struct PerformanceMetrics: Codable {
    public let efficiency: Double
    public let tasksCompleted: Int
    public let averageTime: TimeInterval
    public let qualityScore: Double
    public init(efficiency: Double, tasksCompleted: Int, averageTime: TimeInterval, qualityScore: Double) {
        self.efficiency = efficiency
        self.tasksCompleted = tasksCompleted
        self.averageTime = averageTime
        self.qualityScore = qualityScore
    }
}
public struct StreakData: Codable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let lastUpdate: Date
    public init(currentStreak: Int, longestStreak: Int, lastUpdate: Date) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastUpdate = lastUpdate
    }
}
public enum ProductivityTrend: String, CaseIterable, Codable {
    case improving = "Improving"
    case stable = "Stable"
    case declining = "Declining"
}
public enum Timeframe: String, CaseIterable, Codable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case quarter = "This Quarter"
}
public struct DayProgress: Codable {
    public let completed: Int
    public let total: Int
    public let percentage: Double
    public init(completed: Int, total: Int) {
        self.completed = completed
        self.total = total
        self.percentage = total > 0 ? (Double(completed) / Double(total)) * 100 : 0
    }
}
public struct TaskTrends: Codable {
    public let trend: ProductivityTrend
    public let changePercentage: Double
    public let comparisonPeriod: String
    public init(trend: ProductivityTrend, changePercentage: Double, comparisonPeriod: String) {
        self.trend = trend
        self.changePercentage = changePercentage
        self.comparisonPeriod = comparisonPeriod
    }
}
// MARK: - TaskEvidence (Clean Implementation)
public struct TaskEvidence: Codable {
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
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case timestamp, notes
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.photos = [] // Photos handled separately for security
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.location = nil // Location handled separately
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(notes, forKey: .notes)
    }
}
