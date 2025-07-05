//
//  ContextualTask.swift
//  FrancoSphere
//
//  Fixed version with proper Codable conformance
//

import Foundation
import CoreLocation

public struct ContextualTask: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let buildingId: String
    public let buildingName: String
    public let category: String
    public let startTime: String
    public let endTime: String
    public let recurrence: String
    public let skillLevel: String
    public var status: String
    public let urgencyLevel: String
    public let assignedWorkerName: String
    public var scheduledDate: Date?
    public var completedAt: Date?
    public var notes: String?
    
    // Location is not Codable, so we store coordinates separately
    private var locationLatitude: Double?
    private var locationLongitude: Double?
    
    // Computed property for location
    public var location: CLLocation? {
        get {
            guard let lat = locationLatitude, let lng = locationLongitude else { return nil }
            return CLLocation(latitude: lat, longitude: lng)
        }
        set {
            locationLatitude = newValue?.coordinate.latitude
            locationLongitude = newValue?.coordinate.longitude
        }
    }
    
    // MARK: - CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id, name, buildingId, buildingName, category
        case startTime, endTime, recurrence, skillLevel, status
        case urgencyLevel, assignedWorkerName, scheduledDate, completedAt, notes
        case locationLatitude, locationLongitude
    }
    
    // MARK: - Initializers
    public init(
        id: String = UUID().uuidString,
        name: String,
        buildingId: String,
        buildingName: String,
        category: String,
        startTime: String,
        endTime: String,
        recurrence: String,
        skillLevel: String,
        status: String,
        urgencyLevel: String,
        assignedWorkerName: String,
        scheduledDate: Date? = nil,
        completedAt: Date? = nil,
        location: CLLocation? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.category = category
        self.startTime = startTime
        self.endTime = endTime
        self.recurrence = recurrence
        self.skillLevel = skillLevel
        self.status = status
        self.urgencyLevel = urgencyLevel
        self.assignedWorkerName = assignedWorkerName
        self.scheduledDate = scheduledDate
        self.completedAt = completedAt
        self.notes = notes
        
        // Handle location
        self.locationLatitude = location?.coordinate.latitude
        self.locationLongitude = location?.coordinate.longitude
    }
    
    // MARK: - Codable Implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        buildingId = try container.decode(String.self, forKey: .buildingId)
        buildingName = try container.decode(String.self, forKey: .buildingName)
        category = try container.decode(String.self, forKey: .category)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        recurrence = try container.decode(String.self, forKey: .recurrence)
        skillLevel = try container.decode(String.self, forKey: .skillLevel)
        status = try container.decode(String.self, forKey: .status)
        urgencyLevel = try container.decode(String.self, forKey: .urgencyLevel)
        assignedWorkerName = try container.decode(String.self, forKey: .assignedWorkerName)
        
        scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        
        locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
        locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(buildingId, forKey: .buildingId)
        try container.encode(buildingName, forKey: .buildingName)
        try container.encode(category, forKey: .category)
        try container.encode(startTime, forKey: .startTime)
        try container.encode(endTime, forKey: .endTime)
        try container.encode(recurrence, forKey: .recurrence)
        try container.encode(skillLevel, forKey: .skillLevel)
        try container.encode(status, forKey: .status)
        try container.encode(urgencyLevel, forKey: .urgencyLevel)
        try container.encode(assignedWorkerName, forKey: .assignedWorkerName)
        
        try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(notes, forKey: .notes)
        
        try container.encodeIfPresent(locationLatitude, forKey: .locationLatitude)
        try container.encodeIfPresent(locationLongitude, forKey: .locationLongitude)
    }
    
    // MARK: - Computed Properties
    public var isCompleted: Bool {
        return status.lowercased() == "completed"
    }
    
    public var isOverdue: Bool {
        guard let scheduledDate = scheduledDate else { return false }
        return scheduledDate < Date() && !isCompleted
    }
    
    public var priorityScore: Int {
        switch urgencyLevel.lowercased() {
        case "urgent": return 4
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 2
        }
    }
    
    public var categoryColor: String {
        switch category.lowercased() {
        case "maintenance": return "orange"
        case "cleaning": return "blue"
        case "inspection": return "green"
        case "sanitation": return "purple"
        case "repair": return "red"
        default: return "gray"
        }
    }
    
    public var urgencyColor: String {
        switch urgencyLevel.lowercased() {
        case "urgent": return "red"
        case "high": return "orange"
        case "medium": return "yellow"
        case "low": return "green"
        default: return "gray"
        }
    }
    
    // MARK: - Helper Methods
    public func formattedStartTime() -> String {
        return startTime
    }
    
    public func formattedEndTime() -> String {
        return endTime
    }
    
    public func estimatedDuration() -> TimeInterval {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let start = formatter.date(from: startTime),
              let end = formatter.date(from: endTime) else {
            return 3600 // Default 1 hour
        }
        
        return end.timeIntervalSince(start)
    }
    
    // MARK: - Static Factory Methods
    public static func createMaintenanceTask(
        name: String,
        buildingId: String,
        buildingName: String,
        assignedWorker: String
    ) -> ContextualTask {
        return ContextualTask(
            name: name,
            buildingId: buildingId,
            buildingName: buildingName,
            category: "Maintenance",
            startTime: "09:00",
            endTime: "10:00",
            recurrence: "Daily",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "Medium",
            assignedWorkerName: assignedWorker
        )
    }
    
    public static func createCleaningTask(
        name: String,
        buildingId: String,
        buildingName: String,
        assignedWorker: String
    ) -> ContextualTask {
        return ContextualTask(
            name: name,
            buildingId: buildingId,
            buildingName: buildingName,
            category: "Cleaning",
            startTime: "08:00",
            endTime: "09:00",
            recurrence: "Daily",
            skillLevel: "Basic",
            status: "pending",
            urgencyLevel: "Medium",
            assignedWorkerName: assignedWorker
        )
    }
}

// MARK: - Hash Implementation
extension ContextualTask {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ContextualTask, rhs: ContextualTask) -> Bool {
        return lhs.id == rhs.id
    }
}
