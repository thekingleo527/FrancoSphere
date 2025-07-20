//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0 - FIXED VERSION
//

import Foundation

// MARK: - Type Aliases for Backward Compatibility
typealias OutdoorWorkRisk = CoreTypes.OutdoorWorkRisk

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Location & Coordinate Models

public struct NamedCoordinate: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let address: String?
    public let latitude: Double
    public let longitude: Double
    public let imageAssetName: String?
    
    public init(id: String = UUID().uuidString, name: String, address: String? = nil, latitude: Double, longitude: Double, imageAssetName: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.imageAssetName = imageAssetName
    }
    
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Equatable Conformance
    public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - User Models

public enum UserRole: String, Codable, CaseIterable {
    case admin = "admin"
    case worker = "worker"
    case supervisor = "supervisor"
    case client = "client"
}

public struct WorkerProfile: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let email: String
    public let phoneNumber: String
    public let role: UserRole
    public let skills: [String]
    public let certifications: [String]
    public let hireDate: Date
    public let isActive: Bool
    public let profileImageUrl: String?
    
    public init(id: String, name: String, email: String, phoneNumber: String, role: UserRole, skills: [String], certifications: [String], hireDate: Date, isActive: Bool = true, profileImageUrl: String? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.phoneNumber = phoneNumber
        self.role = role
        self.skills = skills
        self.certifications = certifications
        self.hireDate = hireDate
        self.isActive = isActive
        self.profileImageUrl = profileImageUrl
    }
}

// MARK: - Task Models with Complete Protocol Conformance

public struct ContextualTask: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    public let category: TaskCategory?
    public let urgency: TaskUrgency?
    public let building: NamedCoordinate?
    public let worker: WorkerProfile?
    
    // Additional properties for compatibility
    public let buildingId: String?
    public let buildingName: String?
    public let priority: TaskUrgency?
    
    // Computed property for backward compatibility
    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        isCompleted: Bool = false,
        completedDate: Date? = nil,
        scheduledDate: Date? = nil,
        dueDate: Date? = nil,
        category: TaskCategory? = nil,
        urgency: TaskUrgency? = nil,
        building: NamedCoordinate? = nil,
        worker: WorkerProfile? = nil,
        buildingId: String? = nil,
        buildingName: String? = nil,
        priority: TaskUrgency? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.scheduledDate = scheduledDate
        self.dueDate = dueDate
        self.category = category
        self.urgency = urgency
        self.building = building
        self.worker = worker
        self.buildingId = buildingId ?? building?.id
        self.buildingName = buildingName ?? building?.name
        self.priority = priority ?? urgency
    }
    
    // MARK: - Equatable Conformance
    public static func == (lhs: ContextualTask, rhs: ContextualTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Weather Models

public struct WeatherData: Codable {
    public let temperature: Double
    public let humidity: Double
    public let windSpeed: Double
    public let conditions: String
    public let timestamp: Date
    public let precipitation: Double
    public let condition: WeatherCondition
    
    public init(temperature: Double, humidity: Double, windSpeed: Double, conditions: String, timestamp: Date = Date(), precipitation: Double = 0.0, condition: WeatherCondition = .clear) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.conditions = conditions
        self.timestamp = timestamp
        self.precipitation = precipitation
        self.condition = condition
    }
}

// MARK: - WeatherData Extensions

extension WeatherData {
    public var formattedTemperature: String {
        return "\(Int(temperature.rounded()))°F"
    }
    
    public var iconName: String {
        return condition.icon
    }
}

// MARK: - WeatherData Codable Conformance (Added by Fix Script)
extension WeatherData: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        temperature = try container.decode(Double.self, forKey: .temperature)
        humidity = try container.decode(Double.self, forKey: .humidity)
        windSpeed = try container.decode(Double.self, forKey: .windSpeed)
        conditions = try container.decode(String.self, forKey: .conditions)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        precipitation = try container.decodeIfPresent(Double.self, forKey: .precipitation) ?? 0.0
        condition = try container.decodeIfPresent(CoreTypes.WeatherCondition.self, forKey: .condition) ?? .clear
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(temperature, forKey: .temperature)
        try container.encode(humidity, forKey: .humidity)
        try container.encode(windSpeed, forKey: .windSpeed)
        try container.encode(conditions, forKey: .conditions)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(precipitation, forKey: .precipitation)
        try container.encode(condition, forKey: .condition)
    }
    
    private enum CodingKeys: CodingKey {
        case temperature, humidity, windSpeed, conditions, timestamp, precipitation, condition
    }
}

// MARK: - ContextualTask Extensions
extension ContextualTask {
    var status: String {
        if isCompleted {
            return "completed"
        } else if let dueDate = dueDate, dueDate < Date() {
            return "overdue"
        } else {
            return "pending"
        }
    }
    
    var startTime: String? {
        guard let dueDate = dueDate else { return nil }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dueDate)
    }
    
    var name: String {
        return title ?? description ?? "Untitled Task"
    }
    
    var estimatedDuration: TimeInterval? {
        switch category {
        case .cleaning: return 1800.0
        case .maintenance: return 3600.0
        case .repair: return 7200.0
        case .inspection: return 900.0
        case .landscaping: return 5400.0
        case .security: return 600.0
        case .emergency: return 1800.0
        default: return 3600.0
        }
    }
}

// MARK: - TaskCategory and TaskUrgency Extensions
extension TaskCategory {
    public var rawValue: String {
        switch self {
        case .cleaning: return "cleaning"
        case .maintenance: return "maintenance"
        case .repair: return "repair"
        case .sanitation: return "sanitation"
        case .inspection: return "inspection"
        case .landscaping: return "landscaping"
        case .security: return "security"
        case .emergency: return "emergency"
        case .installation: return "installation"
        case .utilities: return "utilities"
        case .renovation: return "renovation"
        }
    }
}

extension TaskUrgency {
    public var rawValue: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "critical"
        case .emergency: return "emergency"
        case .urgent: return "urgent"
        }
    }
    
    var numericValue: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        case .critical: return 4
        case .emergency: return 5
        case .urgent: return 4
        }
    }
}
