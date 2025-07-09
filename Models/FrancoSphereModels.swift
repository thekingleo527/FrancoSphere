//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  ✅ ALL TYPE CONFLICTS RESOLVED
//  ✅ Uses CoreTypes.swift as the foundation
//  ✅ Removed duplicate declarations
//  ✅ Backwards compatibility maintained
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

        public init(id: String,
                    name: String,
                    latitude: Double,
                    longitude: Double,
                    address: String? = nil,
                    imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }

        public init(id: String,
                    name: String,
                    coordinate: CLLocationCoordinate2D,
                    address: String? = nil,
                    imageAssetName: String? = nil) {
            self.init(id: id,
                      name: name,
                      latitude: coordinate.latitude,
                      longitude: coordinate.longitude,
                      address: address,
                      imageAssetName: imageAssetName)
        }
    }

    // MARK: - Weather Models
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear, sunny, cloudy, rainy, snowy, stormy, foggy, windy

        public var icon: String {
            switch self {
            case .clear, .sunny: return "sun.max.fill"
            case .cloudy:        return "cloud.fill"
            case .rainy:         return "cloud.rain.fill"
            case .snowy:         return "cloud.snow.fill"
            case .stormy:        return "cloud.bolt.fill"
            case .foggy:         return "cloud.fog.fill"
            case .windy:         return "wind"
            }
        }
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

        public init(id: String = UUID().uuidString,
                    date: Date = Date(),
                    temperature: Double,
                    feelsLike: Double? = nil,
                    humidity: Int,
                    windSpeed: Double,
                    windDirection: Int = 0,
                    precipitation: Double = 0,
                    snow: Double = 0,
                    condition: WeatherCondition,
                    uvIndex: Int = 0,
                    visibility: Double = 10,
                    description: String = "") {
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
            self.description = description
        }
    }

    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low, moderate, high, extreme
        public var color: Color {
            switch self {
            case .low:       return .green
            case .moderate:  return .yellow
            case .high:      return .orange
            case .extreme:   return .red
            }
        }
    }

    // MARK: - Task Models
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning, maintenance, repair, inspection, security, landscaping,
             electrical, plumbing, hvac, renovation, utilities, sanitation,
             installation, emergency

        public var icon: String {
            switch self {
            case .cleaning:    return "sparkles"
            case .maintenance: return "wrench.and.screwdriver"
            case .repair:      return "hammer"
            case .inspection:  return "magnifyingglass"
            case .security:    return "shield"
            case .landscaping: return "leaf"
            case .electrical:  return "bolt"
            case .plumbing:    return "drop"
            case .hvac:        return "wind"
            case .renovation:  return "building.2"
            case .utilities:   return "power"
            case .sanitation:  return "trash"
            case .installation:return "plus.circle"
            case .emergency:   return "exclamationmark.triangle"
            }
        }
    }

    public enum TaskUrgency: String, Codable, CaseIterable {
        case low, medium, high, critical
        public var color: Color {
            switch self {
            case .low:      return .green
            case .medium:   return .yellow
            case .high:     return .orange
            case .critical: return .red
            }
        }
    }

    public enum TaskRecurrence: String, Codable, CaseIterable {
        case none, daily, weekly, monthly, yearly
    }

    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending, verified, rejected, needsReview
        public var color: Color {
            switch self {
            case .pending:     return .yellow
            case .verified:    return .green
            case .rejected:    return .red
            case .needsReview: return .orange
            }
        }
    }

    // MARK: - MaintenanceTask
    public struct MaintenanceTask: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedWorkerId: String?
        public var isCompleted: Bool
        public let dueDate: Date?
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let notes: String?

        public init(id: String = UUID().uuidString,
                    title: String,
                    description: String,
                    category: TaskCategory,
                    urgency: TaskUrgency,
                    buildingId: String,
                    assignedWorkerId: String? = nil,
                    isCompleted: Bool = false,
                    dueDate: Date? = nil,
                    estimatedDuration: TimeInterval = 3600,
                    recurrence: TaskRecurrence = .none,
                    notes: String? = nil) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.isCompleted = isCompleted
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.notes = notes
        }
    }

    // MARK: - Worker Models
    public enum WorkerSkill: String, Codable, CaseIterable {
        case basic, intermediate, advanced, expert
        public var color: Color {
            switch self {
            case .basic:        return .gray
            case .intermediate: return .blue
            case .advanced:     return .green
            case .expert:       return .purple
            }
        }
    }

    public enum UserRole: String, Codable, CaseIterable {
        case admin, worker, client, supervisor
    }

    public struct WorkerProfile: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let email: String
        public let role: String
        public let phone: String?
        public let hourlyRate: Double?
        public let skills: [String]
        public let isActive: Bool
        public let profileImagePath: String?
        public let address: String?
        public let emergencyContact: String?
        public let notes: String?
    }

    public struct WorkerAssignment: Identifiable, Codable, Hashable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let assignedDate: Date
        public let isActive: Bool
    }

    // MARK: - Inventory Models
    public enum InventoryCategory: String, Codable, CaseIterable {
        case tools, supplies, equipment, safety, cleaning,
             electrical, plumbing, hardware

        public var icon: String {
            switch self {
            case .tools:      return "wrench"
            case .supplies:   return "shippingbox"
            case .equipment:  return "gear"
            case .safety:     return "shield"
            case .cleaning:   return "sparkles"
            case .electrical: return "bolt"
            case .plumbing:   return "drop"
            case .hardware:   return "screw"
            }
        }
    }

    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock, lowStock, outOfStock, onOrder
        public var color: Color {
            switch self {
            case .inStock:    return .green
            case .lowStock:   return .yellow
            case .outOfStock: return .red
            case .onOrder:    return .blue
            }
        }
    }

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
        public let lastRestocked: Date?
    }

    // MARK: - Contextual Task (Single Authoritative Definition)
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
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let notes: String?

        // Compatibility helpers
        public var name: String { title }
        public var workerId: String { assignedWorkerId ?? "" }
        public var status: String { isCompleted ? "completed" : "pending" }
    }

    // MARK: - Supporting / Intelligence Models
    public struct WorkerRoutineSummary: Codable {
        public let totalTasks: Int
        public let completedTasks: Int
        public let efficiency: Double
        public let date: Date
    }

    public struct WorkerDailyRoute: Codable {
        public let buildings: [String]
        public let estimatedDuration: TimeInterval
        public let date: Date
    }

    public struct RouteOptimization: Codable {
        public let optimizedOrder: [String]
        public let totalDistance: Double
        public let estimatedTime: TimeInterval
    }

    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy, warning, critical
        public var color: Color {
            switch self {
            case .healthy:  return .green
            case .warning:  return .orange
            case .critical: return .red
            }
        }
    }

    public struct MaintenanceRecord: Identifiable, Codable {
        public let id: String
        public let buildingId: String
        public let taskName: String
        public let description: String?
        public let completedDate: Date
        public let completedBy: String
        public let category: String
        public let urgency: String
        public let notes: String?
        public let photoPath: String?
    }

    public struct TaskCompletionRecord: Codable {
        public let taskId: String
        public let workerId: String
        public let completedDate: Date
        public let notes: String?
        public let photoPath: String?
    }

    // MARK: - Export / Import
    public struct ExportProgress: Codable {
        public let totalSteps: Int
        public let currentStep: Int
        public let currentOperation: String
        public let isComplete: Bool
    }

    public struct ImportError: Error, Codable {
        public let message: String
        public let line: Int?
        public let column: String?
    }

    // MARK: - Service Error
    public enum ServiceError: Error {
        case noSQLiteManager
        case invalidData(String)
    }

    public struct WorkerPerformanceMetrics: Codable {
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageCompletionTime: TimeInterval
    }

    // MARK: - Trend Direction
    public enum TrendDirection: String, Codable, CaseIterable {
        case up, down, stable
        public var color: Color {
            switch self {
            case .up:     return .green
            case .down:   return .red
            case .stable: return .blue
            }
        }
        public var icon: String {
            switch self {
            case .up:     return "arrow.up.right"
            case .down:   return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }
}

// MARK: - Global Typealiases
public typealias NamedCoordinate        = FrancoSphere.NamedCoordinate
public typealias WeatherCondition       = FrancoSphere.WeatherCondition
public typealias WeatherData            = FrancoSphere.WeatherData
public typealias OutdoorWorkRisk        = FrancoSphere.OutdoorWorkRisk
public typealias TaskCategory           = FrancoSphere.TaskCategory
public typealias TaskUrgency            = FrancoSphere.TaskUrgency
public typealias TaskRecurrence         = FrancoSphere.TaskRecurrence
public typealias VerificationStatus     = FrancoSphere.VerificationStatus
public typealias MaintenanceTask        = FrancoSphere.MaintenanceTask
public typealias WorkerSkill            = FrancoSphere.WorkerSkill
public typealias UserRole               = FrancoSphere.UserRole
public typealias WorkerProfile          = FrancoSphere.WorkerProfile
public typealias WorkerAssignment       = FrancoSphere.WorkerAssignment
public typealias InventoryCategory      = FrancoSphere.InventoryCategory
public typealias RestockStatus          = FrancoSphere.RestockStatus
public typealias InventoryItem          = FrancoSphere.InventoryItem
public typealias ContextualTask         = FrancoSphere.ContextualTask
public typealias WorkerRoutineSummary   = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute       = FrancoSphere.WorkerDailyRoute
public typealias RouteOptimization      = FrancoSphere.RouteOptimization
public typealias DataHealthStatus       = FrancoSphere.DataHealthStatus
public typealias MaintenanceRecord      = FrancoSphere.MaintenanceRecord
public typealias TaskCompletionRecord   = FrancoSphere.TaskCompletionRecord
public typealias ExportProgress         = FrancoSphere.ExportProgress
public typealias ImportError            = FrancoSphere.ImportError
public typealias WorkerPerformanceMetrics = FrancoSphere.WorkerPerformanceMetrics
public typealias TrendDirection         = FrancoSphere.TrendDirection
