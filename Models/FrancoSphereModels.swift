//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0
//
//  ✅ CLEANED: Removed all conflicting type definitions
//  ✅ IMPORTS: All types now come from CoreTypes.swift
//  ✅ FOCUSED: Only unique models that don't conflict
//

import Foundation
import CoreLocation
import SwiftUI

// Import all types from CoreTypes
// All type definitions are now in CoreTypes.swift to avoid conflicts

// MARK: - Location & Coordinate Models

public struct NamedCoordinate: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let name: String
    public let address: String?
    public let latitude: Double
    public let longitude: Double
    
    public init(id: String = UUID().uuidString, name: String, address: String? = nil, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
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
    
    public init(id: String = UUID().uuidString, title: String, description: String? = nil, isCompleted: Bool = false, completedDate: Date? = nil, scheduledDate: Date? = nil, dueDate: Date? = nil, category: TaskCategory? = nil, urgency: TaskUrgency? = nil, building: NamedCoordinate? = nil, worker: WorkerProfile? = nil) {
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
    }
}

// MARK: - Weather Models

public struct WeatherData: Codable {
    public let temperature: Double
    public let humidity: Double
    public let windSpeed: Double
    public let conditions: String
    public let timestamp: Date
    
    public init(temperature: Double, humidity: Double, windSpeed: Double, conditions: String, timestamp: Date = Date()) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.conditions = conditions
        self.timestamp = timestamp
    }
}

// MARK: - Filter Models

