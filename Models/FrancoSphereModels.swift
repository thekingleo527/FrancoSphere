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
        public let coordinate: CLLocationCoordinate2D
        public let address: String?
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil) {
            self.id = id
            self.name = name
            self.coordinate = coordinate
            self.address = address
        }
        
        enum CodingKeys: String, CodingKey {
            case id, name, address, latitude, longitude
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            name = try container.decode(String.self, forKey: .name)
            address = try container.decodeIfPresent(String.self, forKey: .address)
            let latitude = try container.decode(Double.self, forKey: .latitude)
            let longitude = try container.decode(Double.self, forKey: .longitude)
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(name, forKey: .name)
            try container.encodeIfPresent(address, forKey: .address)
            try container.encode(coordinate.latitude, forKey: .latitude)
            try container.encode(coordinate.longitude, forKey: .longitude)
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
        case closed = "Closed"
    }
    
    // MARK: - User Models
    public enum UserRole: String, CaseIterable, Codable {
        case admin = "Admin"
        case manager = "Manager"
        case worker = "Worker"
        case viewer = "Viewer"
    }
    
    public enum WorkerSkill: String, CaseIterable, Codable {
        case basic = "Basic"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let role: UserRole
        public let skillLevel: WorkerSkill
        
        public init(id: String, name: String, email: String, role: UserRole, skillLevel: WorkerSkill) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skillLevel = skillLevel
        }
    }
    
    // MARK: - Inventory Models
    public enum InventoryCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case safety = "Safety"
        case office = "Office"
        case other = "Other"
    }
    
    public enum RestockStatus: String, CaseIterable, Codable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
        case inTransit = "In Transit"
        case delivered = "Delivered"
        case cancelled = "Cancelled"
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let quantity: Int
        public let status: RestockStatus
        
        public init(id: String, name: String, category: InventoryCategory, quantity: Int, status: RestockStatus) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.status = status
        }
    }
    
    // MARK: - Task Models
    public enum TaskCategory: String, CaseIterable, Codable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case security = "Security"
        case landscaping = "Landscaping"
        case other = "Other"
    }
    
    public enum TaskUrgency: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public enum TaskRecurrence: String, CaseIterable, Codable {
        case once = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
    }
    
    public enum VerificationStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case requiresReview = "Requires Review"
    }
    
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedWorkerId: String?
        public let dueDate: Date
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let isCompleted: Bool
        public let completedDate: Date?
        public let verificationStatus: VerificationStatus
        
        public init(id: String, title: String, description: String, category: TaskCategory, urgency: TaskUrgency, buildingId: String, assignedWorkerId: String? = nil, dueDate: Date, estimatedDuration: TimeInterval, recurrence: TaskRecurrence = .once, isCompleted: Bool = false, completedDate: Date? = nil, verificationStatus: VerificationStatus = .pending) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.verificationStatus = verificationStatus
        }
    }
    
    public struct TaskCompletionInfo: Codable {
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let photoPath: String?
        public let notes: String?
        
        public init(taskId: String, workerId: String, completedAt: Date, photoPath: String? = nil, notes: String? = nil) {
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.photoPath = photoPath
            self.notes = notes
        }
    }
    
    // MARK: - Weather Models
    public enum WeatherCondition: String, CaseIterable, Codable {
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case windy = "Windy"
    }
    
    public struct WeatherData: Codable {
        public let temperature: Double
        public let condition: WeatherCondition
        public let humidity: Double
        public let windSpeed: Double
        public let timestamp: Date
        
        public init(temperature: Double, condition: WeatherCondition, humidity: Double, windSpeed: Double, timestamp: Date = Date()) {
            self.temperature = temperature
            self.condition = condition
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.timestamp = timestamp
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
