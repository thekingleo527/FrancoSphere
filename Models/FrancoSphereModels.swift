//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0 - PROTOCOL CONFORMANCE FIXED
//
//  🚨 CRITICAL FIX: Complete protocol conformance for all types
//  ✅ FIXED: All Codable, Hashable, Equatable implementations
//  ✅ ALIGNED: Uses unified type definitions from CoreTypes
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
    public let scheduledDate: Date?
    public let dueDate: Date?
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
