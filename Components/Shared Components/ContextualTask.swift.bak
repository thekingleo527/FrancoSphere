//
//  ContextualTask.swift
//  FrancoSphere
//
//  Single source of truth for ContextualTask
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
    public var location: CLLocation?
    public var notes: String?
    
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
        self.location = location
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    public var isCompleted: Bool {
        return status == "completed"
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
    
    // MARK: - Helper Methods
    public func formattedStartTime() -> String {
        return startTime
    }
    
    public func formattedEndTime() -> String {
        return endTime
    }
    
    public func estimatedDuration() -> TimeInterval {
        // Simple duration calculation
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
    
    public static func createInspectionTask(
        name: String,
        buildingId: String,
        buildingName: String,
        assignedWorker: String
    ) -> ContextualTask {
        return ContextualTask(
            name: name,
            buildingId: buildingId,
            buildingName: buildingName,
            category: "Inspection",
            startTime: "10:00",
            endTime: "11:00",
            recurrence: "Weekly",
            skillLevel: "Intermediate",
            status: "pending",
            urgencyLevel: "High",
            assignedWorkerName: assignedWorker
        )
    }
}

// MARK: - Extensions
extension ContextualTask {
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
}
