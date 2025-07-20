//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0
//
//  ✅ MINIMAL: Only core definitions without conflicts
//  ✅ NO DUPLICATES: Avoids all redeclarations
//  ✅ CODABLE: Proper protocol conformance
//  ✅ CLEAN: No extensions that exist elsewhere
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

// MARK: - ✅ MINIMAL: ContextualTask - Core properties only

public struct ContextualTask: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    public let scheduledDate: Date?
    public let dueDate: Date?
    public let category: CoreTypes.TaskCategory?
    public let urgency: CoreTypes.TaskUrgency?
    public let building: NamedCoordinate?
    public let worker: WorkerProfile?
    public let buildingId: String?
    public let priority: CoreTypes.TaskUrgency?
    
    // ✅ COMPUTED: Only properties that don't exist elsewhere
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
        category: CoreTypes.TaskCategory? = nil,
        urgency: CoreTypes.TaskUrgency? = nil,
        building: NamedCoordinate? = nil,
        worker: WorkerProfile? = nil,
        buildingId: String? = nil,
        priority: CoreTypes.TaskUrgency? = nil
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
        self.priority = priority ?? urgency
    }
    
    // MARK: - Protocol Conformance
    public static func == (lhs: ContextualTask, rhs: ContextualTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ✅ NO EXTENSIONS: All extensions are defined in other files
// Extensions for ContextualTask (status, startTime, name, etc.) are in:
// - ContextualTaskExtensions.swift
// - ContextualTaskIntelligence.swift
// - TaskDisplayHelpers.swift

// MARK: - ✅ NO WEATHER MODELS: Use CoreTypes.WeatherData instead
