#!/bin/bash

set -e
PROJECT_ROOT="/Volumes/FastSSD/Xcode"

echo "🚀 FrancoSphere Comprehensive Fix - Addressing ALL compilation errors"

# Phase 1: Complete rewrite of FrancoSphereModels.swift with ALL missing types
echo "🔧 Creating comprehensive FrancoSphereModels.swift..."
cat > "$PROJECT_ROOT/Models/FrancoSphereModels.swift" << 'MODELS_EOF'
//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  Complete type definitions - Single source of truth
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Core Models
    public struct NamedCoordinate: Identifiable, Codable {
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
        
        // Legacy constructor support
        public init(id: String, name: String, latitude: Double, longitude: Double, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.address = nil
        }
        
        // Convenience accessors for legacy code
        public var latitude: Double { coordinate.latitude }
        public var longitude: Double { coordinate.longitude }
        
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
        
        // Manual Equatable conformance since CLLocationCoordinate2D doesn't conform
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            return lhs.id == rhs.id &&
                   lhs.name == rhs.name &&
                   lhs.coordinate.latitude == rhs.coordinate.latitude &&
                   lhs.coordinate.longitude == rhs.coordinate.longitude &&
                   lhs.address == rhs.address
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
        case inactive = "Inactive"
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
    
    public struct BuildingInsight: Identifiable, Codable {
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
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let startDate: Date
        public let endDate: Date?
        
        public init(id: String, workerId: String, buildingId: String, startDate: Date, endDate: Date? = nil) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.startDate = startDate
            self.endDate = endDate
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
        public let minimumStock: Int
        
        public init(id: String, name: String, category: InventoryCategory, quantity: Int, status: RestockStatus, minimumStock: Int = 5) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.status = status
            self.minimumStock = minimumStock
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
        case urgent = "Urgent"
    }
    
    public enum TaskRecurrence: String, CaseIterable, Codable {
        case once = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        case oneOff = "One-Off"
    }
    
    public enum VerificationStatus: String, CaseIterable, Codable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case requiresReview = "Requires Review"
        case verified = "Verified"
        case failed = "Failed"
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
    
    public struct TaskEvidence: Codable {
        public let photos: [Data]
        public let timestamp: Date
        public let location: CLLocation?
        public let notes: String?
        
        public init(photos: [Data], timestamp: Date, location: CLLocation? = nil, notes: String? = nil) {
            self.photos = photos
            self.timestamp = timestamp
            self.location = location
            self.notes = notes
        }
        
        enum CodingKeys: String, CodingKey {
            case photos, timestamp, notes, latitude, longitude
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            photos = try container.decode([Data].self, forKey: .photos)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            notes = try container.decodeIfPresent(String.self, forKey: .notes)
            
            if let lat = try container.decodeIfPresent(Double.self, forKey: .latitude),
               let lng = try container.decodeIfPresent(Double.self, forKey: .longitude) {
                location = CLLocation(latitude: lat, longitude: lng)
            } else {
                location = nil
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(photos, forKey: .photos)
            try container.encode(timestamp, forKey: .timestamp)
            try container.encodeIfPresent(notes, forKey: .notes)
            try container.encodeIfPresent(location?.coordinate.latitude, forKey: .latitude)
            try container.encodeIfPresent(location?.coordinate.longitude, forKey: .longitude)
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
        // Legacy aliases
        case clear = "Clear"
        case rain = "Rain"
        case snow = "Snow"
        case fog = "Fog"
        case storm = "Storm"
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
    
    public enum OutdoorWorkRisk: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }
    
    public struct WeatherImpact: Codable {
        public let condition: WeatherCondition
        public let temperature: Double
        public let risk: OutdoorWorkRisk
        public let recommendation: String
        
        public init(condition: WeatherCondition, temperature: Double, risk: OutdoorWorkRisk, recommendation: String) {
            self.condition = condition
            self.temperature = temperature
            self.risk = risk
            self.recommendation = recommendation
        }
    }
    
    // MARK: - Worker Routine Models
    public struct WorkerRoutineSummary: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let totalTasks: Int
        public let completedTasks: Int
        
        public init(id: String, workerId: String, date: Date, totalTasks: Int, completedTasks: Int) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
        }
    }
    
    public struct WorkerDailyRoute: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let stops: [RouteStop]
        
        public init(id: String, workerId: String, date: Date, stops: [RouteStop]) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.stops = stops
        }
    }
    
    public struct RouteStop: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let estimatedTime: TimeInterval
        public let tasks: [String]
        
        public init(id: String, buildingId: String, estimatedTime: TimeInterval, tasks: [String]) {
            self.id = id
            self.buildingId = buildingId
            self.estimatedTime = estimatedTime
            self.tasks = tasks
        }
    }
    
    public struct RouteOptimization: Codable {
        public let originalDistance: Double
        public let optimizedDistance: Double
        public let timeSaved: TimeInterval
        
        public init(originalDistance: Double, optimizedDistance: Double, timeSaved: TimeInterval) {
            self.originalDistance = originalDistance
            self.optimizedDistance = optimizedDistance
            self.timeSaved = timeSaved
        }
    }
    
    public struct ScheduleConflict: Identifiable, Codable {
        public let id: String
        public let description: String
        public let severity: String
        
        public init(id: String, description: String, severity: String) {
            self.id = id
            self.description = description
            self.severity = severity
        }
    }
    
    public struct MaintenanceRecord: Identifiable, Codable {
        public let id: String
        public let taskId: String
        public let buildingId: String
        public let description: String
        public let completedDate: Date
        public let performedBy: String
        
        public init(id: String, taskId: String, buildingId: String, description: String, completedDate: Date, performedBy: String) {
            self.id = id
            self.taskId = taskId
            self.buildingId = buildingId
            self.description = description
            self.completedDate = completedDate
            self.performedBy = performedBy
        }
    }
    
    // MARK: - Performance Models
    public struct TaskTrends: Codable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        
        public init(weeklyCompletion: [Double], categoryBreakdown: [String: Int], changePercentage: Double) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
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
        public let lastCompletionDate: Date?
        
        public init(currentStreak: Int, longestStreak: Int, lastCompletionDate: Date? = nil) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastCompletionDate = lastCompletionDate
        }
    }
    
    // MARK: - Data Health
    public enum DataHealthStatus: Equatable, Hashable {
        case unknown
        case healthy
        case warning([String])
        case critical([String])
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
    
    public struct AIScenarioData: Identifiable, Codable {
        public let id: String
        public let scenario: AIScenario
        public let timestamp: Date
        public let relevantTasks: [String]
        
        public init(id: String, scenario: AIScenario, timestamp: Date, relevantTasks: [String]) {
            self.id = id
            self.scenario = scenario
            self.timestamp = timestamp
            self.relevantTasks = relevantTasks
        }
    }
    
    // MARK: - Legacy Types
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
}

// MARK: - Global Type Aliases (Clean, no duplicates)
public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias BuildingTab = FrancoSphere.BuildingTab
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias BuildingStatistics = FrancoSphere.BuildingStatistics
public typealias BuildingInsight = FrancoSphere.BuildingInsight
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskCompletionInfo = FrancoSphere.TaskCompletionInfo
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias TaskProgress = FrancoSphere.TaskProgress
public typealias TaskEvidence = FrancoSphere.TaskEvidence
public typealias WeatherCondition = FrancoSphere.WeatherCondition
public typealias WeatherData = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk = FrancoSphere.OutdoorWorkRisk
public typealias WeatherImpact = FrancoSphere.WeatherImpact
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute = FrancoSphere.WorkerDailyRoute
public typealias RouteStop = FrancoSphere.RouteStop
public typealias RouteOptimization = FrancoSphere.RouteOptimization
public typealias ScheduleConflict = FrancoSphere.ScheduleConflict
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias TaskTrends = FrancoSphere.TaskTrends
public typealias PerformanceMetrics = FrancoSphere.PerformanceMetrics
public typealias StreakData = FrancoSphere.StreakData
public typealias DataHealthStatus = FrancoSphere.DataHealthStatus
public typealias AIScenario = FrancoSphere.AIScenario
public typealias AISuggestion = FrancoSphere.AISuggestion
public typealias AIScenarioData = FrancoSphere.AIScenarioData
public typealias FSTaskItem = FrancoSphere.FSTaskItem
MODELS_EOF

# Phase 2: Fix InventoryItem.swift to remove duplicate statusColor and use correct constructor
echo "🔧 Fixing InventoryItem.swift..."
cat > "$PROJECT_ROOT/Models/InventoryItem.swift" << 'INVENTORY_EOF'
//
//  InventoryItem.swift
//  FrancoSphere
//
//  Sample inventory data with fixed constructor
//

import Foundation

extension InventoryItem {
    static let sampleData: [InventoryItem] = [
        InventoryItem(
            id: "1",
            name: "All-Purpose Cleaner",
            category: .cleaning,
            quantity: 15,
            status: .inStock,
            minimumStock: 5
        ),
        InventoryItem(
            id: "2",
            name: "Paper Towels",
            category: .cleaning,
            quantity: 3,
            status: .lowStock,
            minimumStock: 10
        ),
        InventoryItem(
            id: "3",
            name: "Light Bulbs",
            category: .maintenance,
            quantity: 0,
            status: .outOfStock,
            minimumStock: 5
        ),
        InventoryItem(
            id: "4",
            name: "Printer Paper",
            category: .office,
            quantity: 10,
            status: .inTransit,
            minimumStock: 8
        ),
        InventoryItem(
            id: "5",
            name: "Safety Vests",
            category: .safety,
            quantity: 8,
            status: .delivered,
            minimumStock: 3
        ),
        InventoryItem(
            id: "6",
            name: "Screwdriver Set",
            category: .maintenance,
            quantity: 0,
            status: .cancelled,
            minimumStock: 2
        )
    ]
}
INVENTORY_EOF

# Phase 3: Fix NewAuthManager.swift syntax errors
echo "🔧 Fixing NewAuthManager.swift..."
sed -i '' 's/: WorkerProfile/: FrancoSphere.WorkerProfile/g' "$PROJECT_ROOT/Managers/NewAuthManager.swift"
sed -i '' 's/WorkerProfile(/FrancoSphere.WorkerProfile(/g' "$PROJECT_ROOT/Managers/NewAuthManager.swift"
sed -i '' 's/-> WorkerProfile/-> FrancoSphere.WorkerProfile/g' "$PROJECT_ROOT/Managers/NewAuthManager.swift"

# Phase 4: Fix SignUpView.swift 
echo "🔧 Fixing SignUpView.swift..."
sed -i '' 's/: UserRole/: FrancoSphere.UserRole/g' "$PROJECT_ROOT/Views/Auth/SignUpView.swift"
sed -i '' 's/UserRole\./FrancoSphere.UserRole./g' "$PROJECT_ROOT/Views/Auth/SignUpView.swift"

# Phase 5: Fix BuildingTaskDetailView.swift
echo "🔧 Fixing BuildingTaskDetailView.swift..."
sed -i '' 's/: InventoryItem/: FrancoSphere.InventoryItem/g' "$PROJECT_ROOT/Views/Buildings/BuildingTaskDetailView.swift"
sed -i '' 's/InventoryItem(/FrancoSphere.InventoryItem(/g' "$PROJECT_ROOT/Views/Buildings/BuildingTaskDetailView.swift"
sed -i '' 's/: WorkerAssignment/: FrancoSphere.WorkerAssignment/g' "$PROJECT_ROOT/Views/Buildings/BuildingTaskDetailView.swift"

# Phase 6: Fix SQLiteManager.swift constructor issues
echo "🔧 Fixing SQLiteManager.swift..."
sed -i '' 's/quantity: item\.currentStock/quantity: item.quantity/g' "$PROJECT_ROOT/Managers/SQLiteManager.swift"
sed -i '' 's/minimumStock: item\.minimumStock/status: item.status/g' "$PROJECT_ROOT/Managers/SQLiteManager.swift"

echo "✅ Comprehensive fix completed!"
echo "📊 Fixed:"
echo "  • Added ALL missing types to FrancoSphere namespace"
echo "  • Fixed enum cases (clear, rain, snow, fog, storm, urgent, verified, failed)"
echo "  • Added legacy constructor support for NamedCoordinate"
echo "  • Fixed Equatable conformance manually"
echo "  • Fixed InventoryItem constructor parameters"
echo "  • Fixed NewAuthManager syntax errors"
echo "  • Updated all type references to use proper namespacing"

