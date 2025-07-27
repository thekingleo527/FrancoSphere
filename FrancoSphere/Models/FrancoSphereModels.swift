//
//  FrancoSphereModels.swift
//  FrancoSphere v6.0
//
//  ✅ MINIMAL: Only core stored properties, no computed properties
//  ✅ NO DUPLICATES: Avoids all redeclarations with extensions
//  ✅ CODABLE: Clean protocol conformance
//  ✅ FOCUSED: Only properties used in initializers throughout codebase
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

// MARK: - ✅ MINIMAL ContextualTask - Only stored properties used in initializers

public struct ContextualTask: Identifiable, Codable, Hashable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public var isCompleted: Bool
    public var completedDate: Date?
    public let dueDate: Date?
    public let category: CoreTypes.TaskCategory?
    public let urgency: CoreTypes.TaskUrgency?
    public let building: NamedCoordinate?
    public let worker: WorkerProfile?
    public let buildingId: String?
    public let priority: CoreTypes.TaskUrgency?
    
    // ✅ STORED PROPERTIES: Used in initializers throughout codebase
    public let buildingName: String?  // Used in WorkerContextEngine, OperationalDataManager
    public let assignedWorkerId: String?  // Used in OperationalDataManager, TaskTimelineView
    public let assignedWorkerName: String?  // Referenced in GRDBManager, extensions
    public let estimatedDuration: TimeInterval  // Used in WorkerContextEngine+DataFlow
    
    // ✅ ONLY ONE COMPUTED PROPERTY: For overdue status (simple, no conflicts)
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
        dueDate: Date? = nil,
        category: CoreTypes.TaskCategory? = nil,
        urgency: CoreTypes.TaskUrgency? = nil,
        building: NamedCoordinate? = nil,
        worker: WorkerProfile? = nil,
        buildingId: String? = nil,
        priority: CoreTypes.TaskUrgency? = nil,
        buildingName: String? = nil,  // ✅ STORED: Used in initializers
        assignedWorkerId: String? = nil,  // ✅ STORED: Used in initializers
        assignedWorkerName: String? = nil,  // ✅ STORED: Used in initializers
        estimatedDuration: TimeInterval = 3600  // ✅ STORED: Used in initializers
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.dueDate = dueDate
        self.category = category
        self.urgency = urgency
        self.building = building
        self.worker = worker
        self.buildingId = buildingId ?? building?.id
        self.priority = priority ?? urgency
        self.buildingName = buildingName ?? building?.name
        self.assignedWorkerId = assignedWorkerId ?? worker?.id
        self.assignedWorkerName = assignedWorkerName ?? worker?.name
        self.estimatedDuration = estimatedDuration
    }
    
    // MARK: - Protocol Conformance
    public static func == (lhs: ContextualTask, rhs: ContextualTask) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - ✅ NO COMPUTED PROPERTIES HERE
// Extensions handle: status, name, workerId, startTime, scheduledDate
// This avoids all redeclaration conflicts while maintaining Codable conformance
