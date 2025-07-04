//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  🔧 COMPLETE RESTORATION - All types preserved
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Geographic Models
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
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case windy = "Windy"
    
        case rain = "Rain"
        case snow = "Snow"
        case storm = "Storm"
        case fog = "Fog"
        
    }
    
    public struct WeatherData: Identifiable, Codable {
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
        
        public init(id: String = UUID().uuidString, date: Date = Date(), temperature: Double, feelsLike: Double? = nil, humidity: Int, windSpeed: Double, windDirection: Int = 0, precipitation: Double = 0, snow: Double = 0, condition: WeatherCondition, uvIndex: Int = 0, visibility: Double = 10, description: String = "") {
            self.id = id
            self.date = date
            self.temperature = temperature
            self.feelsLike = feelsLike ?? temperature
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
        
        // MARK: - Convenience Constructor for HeroStatusCard compatibility
        public init(condition: WeatherCondition, temperature: Double, humidity: Int, windSpeed: Double, description: String) {
            self.id = UUID().uuidString
            self.date = Date()
            self.temperature = temperature
            self.feelsLike = temperature
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.windDirection = 0
            self.precipitation = 0
            self.snow = 0
            self.condition = condition
            self.uvIndex = 0
            self.visibility = 10
            self.description = description
        }
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }
    
    // MARK: - Task Types
    public enum TaskCategory: String, Codable, CaseIterable {
        case maintenance = "Maintenance"
        case cleaning = "Cleaning"
        case inspection = "Inspection"
        case repair = "Repair"
        case security = "Security"
        case landscaping = "Landscaping"
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case annually = "Annually"
    }
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let dueDate: Date
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let requiredSkills: [String]
        public let verificationStatus: VerificationStatus
        public let assignedTo: String?
        public let assignedWorkerId: String?
        public let completedDate: Date?
        public let status: String
        public let createdDate: Date
        public let lastModified: Date
        public let notes: String?
        
        public init(id: String = UUID().uuidString, buildingId: String, title: String, description: String, category: TaskCategory, urgency: TaskUrgency, dueDate: Date, estimatedDuration: TimeInterval = 3600, recurrence: TaskRecurrence = .none, requiredSkills: [String] = [], verificationStatus: VerificationStatus = .pending, assignedTo: String? = nil, assignedWorkerId: String? = nil, completedDate: Date? = nil, status: String = "pending", createdDate: Date = Date(), lastModified: Date = Date(), notes: String? = nil) {
            self.id = id
            self.buildingId = buildingId
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.requiredSkills = requiredSkills
            self.verificationStatus = verificationStatus
            self.assignedTo = assignedTo
            self.assignedWorkerId = assignedWorkerId
            self.completedDate = completedDate
            self.status = status
            self.createdDate = createdDate
            self.lastModified = lastModified
            self.notes = notes
        }
    }
    
    // MARK: - Worker Types
    public enum WorkerSkill: String, Codable, CaseIterable {
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case carpentry = "Carpentry"
        case painting = "Painting"
        case landscaping = "Landscaping"
        case cleaning = "Cleaning"
        case security = "Security"
        case maintenance = "General Maintenance"
    
        case repair = "Repair"
        case inspection = "Inspection"
        
    }
    
    public enum UserRole: String, Codable, CaseIterable {
        case worker = "Worker"
        case supervisor = "Supervisor"
        case manager = "Manager"
        case admin = "Admin"
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let phoneNumber: String
        public let role: UserRole
        public let skills: [WorkerSkill]
        public let certifications: [String]
        public let hireDate: Date
        public let assignedBuildings: [String]
        public let contactInfo: String
        public let startDate: Date
        public let isActive: Bool
        public let profileImageUrl: String?
        
        public init(id: String = UUID().uuidString, name: String, email: String, phoneNumber: String, role: UserRole, skills: [WorkerSkill], certifications: [String] = [], hireDate: Date, assignedBuildings: [String] = [], contactInfo: String = "", startDate: Date = Date(), isActive: Bool = true, profileImageUrl: String? = nil) {
            self.id = id
            self.name = name
            self.email = email
            self.phoneNumber = phoneNumber
            self.role = role
            self.skills = skills
            self.certifications = certifications
            self.hireDate = hireDate
            self.assignedBuildings = assignedBuildings
            self.contactInfo = contactInfo
            self.startDate = startDate
            self.isActive = isActive
            self.profileImageUrl = profileImageUrl
        }
    }
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(id: String = UUID().uuidString, workerId: String, buildingId: String, assignedDate: Date, isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaningSupplies = "Cleaning Supplies"
        case tools = "Tools"
        case safety = "Safety Equipment"
        case maintenance = "Maintenance Parts"
        case office = "Office Supplies"
        case other = "Other"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let unit: String
        public let supplier: String
        public let costPerUnit: Double
        public let location: String
        public let lastRestocked: Date?
        public let status: RestockStatus
        
        public init(id: String = UUID().uuidString, name: String, description: String, category: InventoryCategory, currentStock: Int, minimumStock: Int, unit: String, supplier: String, costPerUnit: Double, location: String = "", lastRestocked: Date? = nil, status: RestockStatus = .inStock) {
            self.id = id
            self.name = name
            self.description = description
            self.category = category
            self.currentStock = currentStock
            self.minimumStock = minimumStock
            self.unit = unit
            self.supplier = supplier
            self.costPerUnit = costPerUnit
            self.location = location
            self.lastRestocked = lastRestocked
            self.status = status
        }
    }
    
    // MARK: - Task Management Types
    public struct ContextualTask: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let buildingName: String
        public let assignedTo: String
        public let dueDate: Date?
        public let estimatedDuration: TimeInterval
        public let status: String
        public let recurrence: TaskRecurrence
        public let createdDate: Date
        public let lastModified: Date
        public let weatherSensitive: Bool
        public let requiredSkills: [String]
        
        // ENHANCED: Additional properties for WorkerContextEngine compatibility
        public var name: String { return title }
        public var startTime: String? { return nil }
        public var endTime: String? { return nil }
        public var urgencyLevel: String { return urgency.rawValue }
        public var skillLevel: String { return "basic" }
        public var assignedWorkerName: String { return assignedTo }
        
        public init(id: String = UUID().uuidString, title: String, description: String, category: TaskCategory, urgency: TaskUrgency, buildingId: String, buildingName: String, assignedTo: String, dueDate: Date? = nil, estimatedDuration: TimeInterval = 3600, status: String = "pending", recurrence: TaskRecurrence = .none, createdDate: Date = Date(), lastModified: Date = Date(), weatherSensitive: Bool = false, requiredSkills: [String] = []) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.assignedTo = assignedTo
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.status = status
            self.recurrence = recurrence
            self.createdDate = createdDate
            self.lastModified = lastModified
            self.weatherSensitive = weatherSensitive
            self.requiredSkills = requiredSkills
        }
        
        // ENHANCED: Constructor with time properties
        public init(id: String, name: String, buildingId: String, buildingName: String, category: String, startTime: String?, endTime: String?, recurrence: String, skillLevel: String, status: String, urgencyLevel: String, assignedWorkerName: String) {
            self.id = id
            self.title = name
            self.description = ""
            self.category = TaskCategory(rawValue: category) ?? .maintenance
            self.urgency = TaskUrgency(rawValue: urgencyLevel) ?? .medium
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.assignedTo = assignedWorkerName
            self.dueDate = nil
            self.estimatedDuration = 3600
            self.status = status
            self.recurrence = TaskRecurrence(rawValue: recurrence) ?? .none
            self.createdDate = Date()
            self.lastModified = Date()
            self.weatherSensitive = false
            self.requiredSkills = []
        }
    }
    
    // MARK: - Missing Types (CRITICAL ADDITIONS)
    public enum DataHealthStatus: Equatable, Codable {
        case unknown
        case healthy
        case warning(String)
        case error(String)
    }
    
    public enum BuildingTab: String, Codable, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case workers = "Workers"
        case inventory = "Inventory"
        case insights = "Insights"
    }
    
    public struct WorkerPerformanceMetrics: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageCompletionTime: TimeInterval
        public let qualityScore: Double
        public let period: String
        public let lastUpdate: Date
        
        public init(id: String = UUID().uuidString, workerId: String, efficiency: Double, tasksCompleted: Int, averageCompletionTime: TimeInterval, qualityScore: Double, period: String, lastUpdate: Date = Date()) {
            self.id = id
            self.workerId = workerId
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageCompletionTime = averageCompletionTime
            self.qualityScore = qualityScore
            self.period = period
            self.lastUpdate = lastUpdate
        }
    }
    
    // MARK: - Additional Support Types
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
    
    public struct TaskEvidence: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let photos: [Data]
        public let timestamp: Date
        public let locationLatitude: Double?
        public let locationLongitude: Double?
        public let notes: String?
        
        public init(id: String = UUID().uuidString, taskId: String, workerId: String, photos: [Data], timestamp: Date, locationLatitude: Double? = nil, locationLongitude: Double? = nil, notes: String? = nil) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.photos = photos
            self.timestamp = timestamp
            self.locationLatitude = locationLatitude
            self.locationLongitude = locationLongitude
            self.notes = notes
        }
    }
    
    // Add other missing types as minimal stubs
    public struct BuildingStatus: Codable { public let operational: Bool; public init(operational: Bool = true) { self.operational = operational } }
    public struct BuildingInsight: Codable { public let title: String; public init(title: String) { self.title = title } }
    public struct BuildingStatistics: Codable { public let completionRate: Double; public init(completionRate: Double) { self.completionRate = completionRate } }
    public struct TaskTrends: Codable { public let trend: String; public init(trend: String) { self.trend = trend } }
    public struct PerformanceMetrics: Codable { public let efficiency: Double; public init(efficiency: Double) { self.efficiency = efficiency } }
    public struct StreakData: Codable { public let currentStreak: Int; public init(currentStreak: Int) { self.currentStreak = currentStreak } }
    public struct TrendDirection: Codable { public let direction: String; public init(direction: String) { self.direction = direction } }
    public struct WorkerRoutineSummary: Codable { public let totalRoutines: Int; public init(totalRoutines: Int) { self.totalRoutines = totalRoutines } }
    public struct WorkerDailyRoute: Codable { public let routeId: String; public init(routeId: String) { self.routeId = routeId } }
    public struct RouteOptimization: Codable { public let optimized: Bool; public init(optimized: Bool) { self.optimized = optimized } }
    public struct ScheduleConflict: Codable { public let conflictId: String; public init(conflictId: String) { self.conflictId = conflictId } }
    public struct RouteStop: Codable { public let stopId: String; public init(stopId: String) { self.stopId = stopId } }
    public struct AIScenario: Codable { public let scenario: String; public init(scenario: String) { self.scenario = scenario } }
    public struct AISuggestion: Codable { public let suggestion: String; public init(suggestion: String) { self.suggestion = suggestion } }
    public struct AIScenarioData: Codable { public let data: String; public init(data: String) { self.data = data } }
    public struct WeatherImpact: Codable { public let impact: String; public init(impact: String) { self.impact = impact } }
    public struct MaintenanceRecord: Codable { public let recordId: String; public init(recordId: String) { self.recordId = recordId } }
    public struct TaskCompletionRecord: Codable { public let completionId: String; public init(completionId: String) { self.completionId = completionId } }
    public struct ExportProgress: Codable { public let progress: Double; public init(progress: Double) { self.progress = progress } }
    public struct ImportError: Codable { public let error: String; public init(error: String) { self.error = error } }
}

// MARK: - Clean Type Aliases (NON-CIRCULAR)
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk = FrancoSphere.OutdoorWorkRisk
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias ContextualTask = FrancoSphere.ContextualTask
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute = FrancoSphere.WorkerDailyRoute
public typealias RouteOptimization = FrancoSphere.RouteOptimization
public typealias ScheduleConflict = FrancoSphere.ScheduleConflict
public typealias RouteStop = FrancoSphere.RouteStop
public typealias BuildingInsight = FrancoSphere.BuildingInsight
public typealias BuildingTab = FrancoSphere.BuildingTab
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias TrendDirection = FrancoSphere.TrendDirection
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias AIScenarioData = FrancoSphere.AIScenarioData
public typealias WeatherImpact = FrancoSphere.WeatherImpact
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias ExportProgress = FrancoSphere.ExportProgress
public typealias ImportError = FrancoSphere.ImportError
public typealias WorkerPerformanceMetrics = FrancoSphere.WorkerPerformanceMetrics
