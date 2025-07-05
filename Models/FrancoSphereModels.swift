//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  Complete working model definitions
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Core Geographic Types
    public struct NamedCoordinate: Identifiable, Codable, Equatable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        public let imageAssetName: String?
        
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public init(id: String, name: String, latitude: Double, longitude: Double, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rain = "Rain"
        case rainy = "Rainy"
        case snow = "Snow"
        case snowy = "Snowy"
        case storm = "Storm"
        case stormy = "Stormy"
        case fog = "Fog"
        case foggy = "Foggy"
        case windy = "Windy"
        
        public var icon: String {
            switch self {
            case .clear, .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rain, .rainy: return "cloud.rain.fill"
            case .snow, .snowy: return "cloud.snow.fill"
            case .storm, .stormy: return "cloud.bolt.fill"
            case .fog, .foggy: return "cloud.fog.fill"
            case .windy: return "wind"
            }
        }
    }
    
    public struct WeatherData: Codable {
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
        
        // Compatibility property for existing code
        public var timestamp: Date { date }
        
        public init(date: Date = Date(), temperature: Double, feelsLike: Double = 0, humidity: Int, 
                   windSpeed: Double, windDirection: Int = 180, precipitation: Double = 0, snow: Double = 0,
                   condition: WeatherCondition, uvIndex: Int = 5, visibility: Double = 10, description: String = "") {
            self.date = date
            self.temperature = temperature
            self.feelsLike = feelsLike == 0 ? temperature : feelsLike
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.windDirection = windDirection
            self.precipitation = precipitation
            self.snow = snow
            self.condition = condition
            self.uvIndex = uvIndex
            self.visibility = visibility
            self.description = description.isEmpty ? condition.rawValue : description
        }
        
        // Legacy constructor for existing code
        public init(temperature: Double, condition: WeatherCondition, humidity: Int, windSpeed: Double, timestamp: Date) {
            self.init(date: timestamp, temperature: temperature, humidity: humidity, windSpeed: windSpeed, condition: condition)
        }
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .extreme: return .red
            }
        }
    }
    
    // MARK: - Task Types
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case repair = "Repair"
        case installation = "Installation"
        case landscaping = "Landscaping"
        case security = "Security"
        case utilities = "Utilities"
        case emergency = "Emergency"
        case renovation = "Renovation"
        case sanitation = "Sanitation"
        
        public var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .maintenance: return "wrench.and.screwdriver"
            case .inspection: return "magnifyingglass"
            case .repair: return "hammer"
            case .installation: return "plus.square"
            case .landscaping: return "leaf"
            case .security: return "lock.shield"
            case .utilities: return "bolt"
            case .emergency: return "exclamationmark.triangle"
            case .renovation: return "house"
            case .sanitation: return "trash"
            }
        }
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case emergency = "Emergency"
        case urgent = "Urgent"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .blue
            case .high: return .orange
            case .critical, .urgent: return .red
            case .emergency: return .purple
            }
        }
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case once = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Bi-weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case annually = "Annually"
        case none = "None"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let name: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let dueDate: Date
        public let startTime: Date?
        public let endTime: Date?
        public let recurrence: TaskRecurrence
        public let isCompleted: Bool
        
        // Legacy compatibility
        public var buildingID: String { buildingId }
        public var isComplete: Bool { isCompleted }
        public var isPastDue: Bool { !isCompleted && dueDate < Date() }
        
        public init(id: String = UUID().uuidString, buildingId: String, name: String, description: String,
                   category: TaskCategory, urgency: TaskUrgency, dueDate: Date, startTime: Date? = nil,
                   endTime: Date? = nil, recurrence: TaskRecurrence = .once, isCompleted: Bool = false) {
            self.id = id
            self.buildingId = buildingId
            self.name = name
            self.description = description
            self.category = category
            self.urgency = urgency
            self.dueDate = dueDate
            self.startTime = startTime
            self.endTime = endTime
            self.recurrence = recurrence
            self.isCompleted = isCompleted
        }
    }
    
    // MARK: - Progress and Analytics
    public struct TaskProgress: Codable {
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
        
        public var calculatedPercentage: Double {
            total > 0 ? Double(completed) / Double(total) * 100 : 0
        }
    }
    
    public enum TrendDirection: String, Codable {
        case up = "up"
        case down = "down"
        case stable = "stable"
    }
    
    public struct TaskTrends: Codable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        public let comparisonPeriod: String
        public let trend: TrendDirection
        
        public init(weeklyCompletion: [Double], categoryBreakdown: [String: Int], changePercentage: Double, comparisonPeriod: String, trend: TrendDirection) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
            self.comparisonPeriod = comparisonPeriod
            self.trend = trend
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageTime: TimeInterval
        public let qualityScore: Double
        public let lastUpdate: Date
        
        public init(efficiency: Double, tasksCompleted: Int, averageTime: TimeInterval, qualityScore: Double, lastUpdate: Date) {
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageTime = averageTime
            self.qualityScore = qualityScore
            self.lastUpdate = lastUpdate
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
    
    public struct BuildingStatistics: Codable {
        public let buildingId: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let completionRate: Double
        public let averageTaskTime: TimeInterval
        public let lastUpdated: Date
        
        public init(buildingId: String = "", totalTasks: Int, completedTasks: Int, completionRate: Double, averageTaskTime: TimeInterval = 3600, lastUpdated: Date = Date()) {
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.completionRate = completionRate
            self.averageTaskTime = averageTaskTime
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Worker Types
    public enum UserRole: String, Codable, CaseIterable {
        case admin = "Admin"
        case supervisor = "Supervisor"
        case worker = "Worker"
        case client = "Client"
    }
    
    public struct WorkerSkill: Codable, Equatable {
        public let name: String
        public let level: Int
        public let certified: Bool
        public let lastUsed: Date?
        
        public init(name: String, level: Int, certified: Bool, lastUsed: Date?) {
            self.name = name
            self.level = level
            self.certified = certified
            self.lastUsed = lastUsed
        }
        
        public static func == (lhs: WorkerSkill, rhs: WorkerSkill) -> Bool {
            lhs.name == rhs.name && lhs.level == rhs.level
        }
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let phone: String?
        public let role: UserRole
        public let skills: [WorkerSkill]
        public let hourlyRate: Double?
        public let isActive: Bool
        public let profileImagePath: String?
        public let address: String?
        public let emergencyContact: String?
        public let notes: String?
        
        public init(id: String, name: String, email: String, phone: String?, role: UserRole,
                   skills: [WorkerSkill], hourlyRate: Double?, isActive: Bool, 
                   profileImagePath: String?, address: String?, emergencyContact: String?, notes: String?) {
            self.id = id
            self.name = name
            self.email = email
            self.phone = phone
            self.role = role
            self.skills = skills
            self.hourlyRate = hourlyRate
            self.isActive = isActive
            self.profileImagePath = profileImagePath
            self.address = address
            self.emergencyContact = emergencyContact
            self.notes = notes
        }
    }
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case tools = "Tools"
        case hardware = "Hardware"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case safety = "Safety"
        case office = "Office"
        case supplies = "Supplies"
        case other = "Other"
        
        public var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .tools: return "wrench"
            case .hardware: return "bolt"
            case .electrical: return "bolt.circle"
            case .plumbing: return "drop"
            case .safety: return "shield"
            case .office: return "folder"
            case .supplies: return "box"
            case .other: return "square.grid.2x2"
            }
        }
        
        public var systemImage: String { icon }
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
        case discontinued = "Discontinued"
        
        public var color: Color {
            switch self {
            case .inStock: return .green
            case .lowStock: return .orange
            case .outOfStock: return .red
            case .onOrder: return .blue
            case .discontinued: return .gray
            }
        }
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String?
        public let category: InventoryCategory
        public let quantity: Int
        public let minimumQuantity: Int
        public let unit: String
        public let costPerUnit: Double?
        public let supplier: String?
        public let lastRestockDate: Date
        public let status: RestockStatus
        
        // Legacy compatibility
        public var minimumStock: Int { minimumQuantity }
        public var needsReorder: Bool { quantity <= minimumQuantity }
        public var lastRestocked: Date? { lastRestockDate }
        
        public init(id: String = UUID().uuidString, name: String, description: String? = nil, 
                   category: InventoryCategory, quantity: Int, minimumQuantity: Int, unit: String,
                   costPerUnit: Double? = nil, supplier: String? = nil, lastRestocked: Date? = nil,
                   status: RestockStatus) {
            self.id = id
            self.name = name
            self.description = description
            self.category = category
            self.quantity = quantity
            self.minimumQuantity = minimumQuantity
            self.unit = unit
            self.costPerUnit = costPerUnit
            self.supplier = supplier
            self.lastRestockDate = lastRestocked ?? Date()
            self.status = status
        }
    }
    
    // MARK: - Contextual Task
    public struct ContextualTask: Identifiable, Codable {
        public let id: String
        public let task: MaintenanceTask
        public let location: NamedCoordinate
        public let weather: WeatherData?
        public let estimatedTravelTime: TimeInterval?
        public let priority: Int
        
        // Compatibility properties
        public var name: String { task.name }
        public var description: String { task.description }
        public var buildingId: String { task.buildingId }
        public var workerId: String { "" }
        public var isCompleted: Bool { task.isCompleted }
        public var category: TaskCategory { task.category }
        
        public init(id: String = UUID().uuidString, task: MaintenanceTask, location: NamedCoordinate,
                   weather: WeatherData? = nil, estimatedTravelTime: TimeInterval? = nil, priority: Int = 0) {
            self.id = id
            self.task = task
            self.location = location
            self.weather = weather
            self.estimatedTravelTime = estimatedTravelTime
            self.priority = priority
        }
        
        // Legacy constructor
        public init(id: String, name: String, description: String, buildingId: String, workerId: String, isCompleted: Bool) {
            let task = MaintenanceTask(buildingId: buildingId, name: name, description: description, category: .maintenance, urgency: .medium, dueDate: Date(), isCompleted: isCompleted)
            let location = NamedCoordinate(id: buildingId, name: "Building \(buildingId)", latitude: 40.7589, longitude: -73.9851)
            self.init(id: id, task: task, location: location, priority: 0)
        }
    }
    
    // MARK: - Other Types
    public enum DataHealthStatus: Codable {
        case healthy
        case warning(String)
        case error(String)
        case unknown
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "healthy": self = .healthy
            case "warning": 
                let message = try container.decode(String.self, forKey: .message)
                self = .warning(message)
            case "error":
                let message = try container.decode(String.self, forKey: .message)
                self = .error(message)
            case "unknown": self = .unknown
            default: self = .unknown
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .healthy: try container.encode("healthy", forKey: .type)
            case .warning(let message):
                try container.encode("warning", forKey: .type)
                try container.encode(message, forKey: .message)
            case .error(let message):
                try container.encode("error", forKey: .type)
                try container.encode(message, forKey: .message)
            case .unknown: try container.encode("unknown", forKey: .type)
            }
        }
        
        private enum CodingKeys: String, CodingKey {
            case type, message
        }
    }
}

// MARK: - Type Aliases
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk = FrancoSphere.OutdoorWorkRisk
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias TrendDirection = FrancoSphere.TrendDirection
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias ContextualTask = FrancoSphere.ContextualTask
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
