//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  Single source of truth - no duplicates
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Core Models
    public struct NamedCoordinate: Identifiable, Codable, Equatable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.address = address
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, address, latitude, longitude
        }
        
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            lhs.id == rhs.id
        }
    }
    
    // MARK: - Building Models
    public enum BuildingTab: String, CaseIterable, Codable {
        case overview = "Overview"
        case tasks = "Tasks"
        case inventory = "Inventory"
        case insights = "Insights"
    }
    
    public enum BuildingStatus: String, CaseIterable, Codable {
        case active = "Active"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case emergency = "Emergency"
    }
    
    // MARK: - User & Worker Models
    public enum UserRole: String, Codable {
        case admin
        case supervisor
        case worker
        case client
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let role: UserRole
        public var skills: [WorkerSkill]
        public var assignedBuildings: [String]
        public var skillLevel: WorkerSkill?
        
        public init(id: String, name: String, email: String, role: UserRole, skills: [WorkerSkill] = [], assignedBuildings: [String] = [], skillLevel: WorkerSkill? = nil) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skills = skills
            self.assignedBuildings = assignedBuildings
            self.skillLevel = skillLevel
        }
    }
    
    public enum WorkerSkill: String, CaseIterable, Codable {
        case basic = "Basic Cleaning"
        case maintenance = "General Maintenance"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case hvac = "HVAC"
        case painting = "Painting"
        case carpentry = "Carpentry"
        case landscaping = "Landscaping"
        case security = "Security"
        case specialized = "Specialized"
    }
    
    // MARK: - Inventory Models
    public enum InventoryCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning Supplies"
        case tools = "Tools & Equipment"
        case safety = "Safety Equipment"
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case paint = "Paint & Finishes"
        case hardware = "Hardware"
        case seasonal = "Seasonal"
    }
    
    public enum RestockStatus: String, Codable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let quantity: Int
        public let unit: String
        public let minimumQuantity: Int
        public let buildingId: String
        public let location: String
        public let restockStatus: RestockStatus
        public let lastRestocked: Date?
        
        public init(id: String, name: String, category: InventoryCategory, quantity: Int, unit: String, minimumQuantity: Int, buildingId: String, location: String, restockStatus: RestockStatus, lastRestocked: Date? = nil) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.unit = unit
            self.minimumQuantity = minimumQuantity
            self.buildingId = buildingId
            self.location = location
            self.restockStatus = restockStatus
            self.lastRestocked = lastRestocked
        }
    }
    
    // MARK: - Task Models
    public enum TaskCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case repair = "Repair"
        case delivery = "Delivery"
        case emergency = "Emergency"
        
        public var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .maintenance: return "wrench"
            case .inspection: return "magnifyingglass"
            case .repair: return "hammer"
            case .delivery: return "shippingbox"
            case .emergency: return "exclamationmark.triangle"
            }
        }
    }
    
    public enum TaskUrgency: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"
    }
    
    public enum TaskRecurrence: String, CaseIterable, Codable {
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case biWeekly = "Bi-Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
    }
    
    public enum VerificationStatus: String, Codable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let buildingID: String
        public let name: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let dueDate: Date
        public let recurrence: TaskRecurrence
        public var isComplete: Bool
        public var completedDate: Date?
        public var completedBy: String?
        public var verificationStatus: VerificationStatus
        public var assignedWorkers: [String]
        public var startTime: Date?
        public var endTime: Date?
        public var estimatedDuration: TimeInterval?
        public var requiredSkills: [WorkerSkill]
        public var notes: String?
        public var photoPaths: [String]
        
        public init(id: String, buildingID: String, name: String, description: String, category: TaskCategory, urgency: TaskUrgency, dueDate: Date, recurrence: TaskRecurrence, isComplete: Bool = false, completedDate: Date? = nil, completedBy: String? = nil, verificationStatus: VerificationStatus = .pending, assignedWorkers: [String] = [], startTime: Date? = nil, endTime: Date? = nil, estimatedDuration: TimeInterval? = nil, requiredSkills: [WorkerSkill] = [], notes: String? = nil, photoPaths: [String] = []) {
            self.id = id
            self.buildingID = buildingID
            self.name = name
            self.description = description
            self.category = category
            self.urgency = urgency
            self.dueDate = dueDate
            self.recurrence = recurrence
            self.isComplete = isComplete
            self.completedDate = completedDate
            self.completedBy = completedBy
            self.verificationStatus = verificationStatus
            self.assignedWorkers = assignedWorkers
            self.startTime = startTime
            self.endTime = endTime
            self.estimatedDuration = estimatedDuration
            self.requiredSkills = requiredSkills
            self.notes = notes
            self.photoPaths = photoPaths
        }
    }
    
    public struct TaskCompletionInfo: Codable {
        public let taskId: String
        public let completedBy: String
        public let completedDate: Date
        public let notes: String?
        public let photoPaths: [String]
        public let verificationStatus: VerificationStatus
        
        public init(taskId: String, completedBy: String, completedDate: Date, notes: String? = nil, photoPaths: [String] = [], verificationStatus: VerificationStatus = .pending) {
            self.taskId = taskId
            self.completedBy = completedBy
            self.completedDate = completedDate
            self.notes = notes
            self.photoPaths = photoPaths
            self.verificationStatus = verificationStatus
        }
    }
    
    // MARK: - Weather Models
    public enum WeatherCondition: String, Codable {
        case clear = "Clear"
        case cloudy = "Cloudy"
        case rain = "Rain"
        case snow = "Snow"
        case storm = "Storm"
        
        public var icon: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rain: return "cloud.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .storm: return "cloud.bolt.fill"
            }
        }
    }
    
    public struct WeatherData: Codable {
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
    
    // MARK: - Task Context
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
    }
    
    public struct TaskTrends: Codable {
        public let weeklyCompletion: [Int]
        public let categoryBreakdown: [(category: String, count: Int)]
        public let trend: Trend
        
        public enum Trend: String, Codable {
            case improving = "Improving"
            case stable = "Stable"
            case declining = "Declining"
        }
        
        public init(weeklyCompletion: [Int], categoryBreakdown: [(category: String, count: Int)], trend: Trend) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.trend = trend
        }
    }
    
    public struct PerformanceMetrics: Codable {
        public let efficiency: Double
        public let quality: Double
        public let speed: Double
        public let consistency: Double
        
        public init(efficiency: Double, quality: Double, speed: Double, consistency: Double) {
            self.efficiency = efficiency
            self.quality = quality
            self.speed = speed
            self.consistency = consistency
        }
    }
    
    public struct StreakData: Codable {
        public let currentStreak: Int
        public let longestStreak: Int
        
        public init(currentStreak: Int, longestStreak: Int) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
        }
    }
    
    // MARK: - AI Models
    public struct AIScenario: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let suggestedActions: [String]
        public let confidence: Double
        
        public init(id: String, title: String, description: String, suggestedActions: [String], confidence: Double) {
            self.id = id
            self.title = title
            self.description = description
            self.suggestedActions = suggestedActions
            self.confidence = confidence
        }
    }
    
    public struct AISuggestion: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: Int
        
        public init(id: String, title: String, description: String, priority: Int) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
        }
    }
}

// MARK: - Global Type Aliases (Clean, no duplicates)
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias BuildingTab = FrancoSphere.BuildingTab
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskCompletionInfo = FrancoSphere.TaskCompletionInfo
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
