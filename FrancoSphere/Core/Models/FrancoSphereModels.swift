//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: WeatherCondition.icon property access
//  ✅ CLEANED: Removed duplicate type definitions
//  ✅ IMPORTS: All types from CoreTypes.swift
//  ✅ FOCUSED: Only unique models, no conflicts
//

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
    public let imageAssetName: String?  // ✅ ADDED: Missing property
    
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

// MARK: - Task Models

public struct ContextualTask: Identifiable, Codable, Hashable {
    public let id: String
    public let title: String
    public let description: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    public let scheduledDate: Date?
    public let dueDate: Date?
    public let category: TaskCategory?
    public let urgency: TaskUrgency?
    public let building: NamedCoordinate?
    public let worker: WorkerProfile?
    
    // ✅ ADDED: Missing properties for NotificationManager
    public let buildingId: String?
    public let buildingName: String?
    public let priority: TaskUrgency?
    
    // Computed property for backward compatibility
    public var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return !isCompleted && dueDate < Date()
    }
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, isCompleted: Bool = false, completedDate: Date? = nil, scheduledDate: Date? = nil, dueDate: Date? = nil, category: TaskCategory? = nil, urgency: TaskUrgency? = nil, building: NamedCoordinate? = nil, worker: WorkerProfile? = nil, buildingId: String? = nil, buildingName: String? = nil, priority: TaskUrgency? = nil) {
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
}

// MARK: - Weather Models

public struct WeatherData: Codable {
    public let temperature: Double
    public let humidity: Double
    public let windSpeed: Double
    public let conditions: String
    public let timestamp: Date
    
    // ✅ ADDED: Missing properties for weather components
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
    /// Formatted temperature string
    public var formattedTemperature: String {
        return "\(Int(temperature.rounded()))°F"
    }
    
    /// Icon name based on weather condition
    public var iconName: String {
        return getWeatherIcon(for: condition)
    }
}

// MARK: - WeatherCondition Extension with Icon Support

extension WeatherCondition {
    /// Icon name for each weather condition
    public var icon: String {
        return getWeatherIcon(for: self)
    }
}

// ✅ FIXED: Helper function to get weather icons (avoiding extension conflicts)
private func getWeatherIcon(for condition: WeatherCondition) -> String {
    switch condition {
    case .clear: return "sun.max"
    case .sunny: return "sun.max.fill"
    case .cloudy: return "cloud"
    case .rainy: return "cloud.rain"
    case .snowy: return "cloud.snow"
    case .stormy: return "cloud.bolt"
    case .foggy: return "cloud.fog"
    case .windy: return "wind"
    case .partlyCloudy: return "cloud.sun"
    case .overcast: return "cloud.fill"
    }
}

extension TaskCategory {
    /// Icon name for each task category
    public var icon: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver"
        case .cleaning: return "sparkles"
        case .inspection: return "magnifyingglass"
        case .repair: return "hammer"
        case .security: return "lock.shield"
        case .landscaping: return "leaf"
        case .utilities: return "bolt"
        case .emergency: return "exclamationmark.triangle.fill"
        case .renovation: return "building.2"
        case .installation: return "plus.square"
        case .sanitation: return "trash"
        }
    }
}

// MARK: - Type Aliases (Use existing CoreTypes)

// Import core enums and types from CoreTypes.swift
// Note: TaskCategory, TaskUrgency, WeatherCondition use the existing CoreTypes definitions
