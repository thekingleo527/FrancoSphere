//
//  ContextualTask.swift
//  FrancoSphere
//
//  Fixed version with proper Codable conformance
//

import Foundation
import CoreLocation

// REMOVED DUPLICATE: public struct ContextualTask: Identifiable, Codable, Hashable {
// REMOVED DUPLICATE:     public let id: String
// REMOVED DUPLICATE:     public let name: String
// REMOVED DUPLICATE:     public let buildingId: String
// REMOVED DUPLICATE:     public let buildingName: String
// REMOVED DUPLICATE:     public let category: String
// REMOVED DUPLICATE:     public let startTime: String
// REMOVED DUPLICATE:     public let endTime: String
// REMOVED DUPLICATE:     public let recurrence: String
// REMOVED DUPLICATE:     public let skillLevel: String
// REMOVED DUPLICATE:     public var status: String
// REMOVED DUPLICATE:     public let urgencyLevel: String
// REMOVED DUPLICATE:     public let assignedWorkerName: String
// REMOVED DUPLICATE:     public var scheduledDate: Date?
// REMOVED DUPLICATE:     public var completedAt: Date?
// REMOVED DUPLICATE:     public var notes: String?
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // Location is not Codable, so we store coordinates separately
// REMOVED DUPLICATE:     private var locationLatitude: Double?
// REMOVED DUPLICATE:     private var locationLongitude: Double?
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // Computed property for location
// REMOVED DUPLICATE:     public var location: CLLocation? {
// REMOVED DUPLICATE:         get {
// REMOVED DUPLICATE:             guard let lat = locationLatitude, let lng = locationLongitude else { return nil }
// REMOVED DUPLICATE:             return CLLocation(latitude: lat, longitude: lng)
// REMOVED DUPLICATE:         }
// REMOVED DUPLICATE:         set {
// REMOVED DUPLICATE:             locationLatitude = newValue?.coordinate.latitude
// REMOVED DUPLICATE:             locationLongitude = newValue?.coordinate.longitude
// REMOVED DUPLICATE:         }
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // MARK: - CodingKeys
// REMOVED DUPLICATE:     private enum CodingKeys: String, CodingKey {
// REMOVED DUPLICATE:         case id, name, buildingId, buildingName, category
// REMOVED DUPLICATE:         case startTime, endTime, recurrence, skillLevel, status
// REMOVED DUPLICATE:         case urgencyLevel, assignedWorkerName, scheduledDate, completedAt, notes
// REMOVED DUPLICATE:         case locationLatitude, locationLongitude
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // MARK: - Initializers
// REMOVED DUPLICATE:     public init(
// REMOVED DUPLICATE:         id: String = UUID().uuidString,
// REMOVED DUPLICATE:         name: String,
// REMOVED DUPLICATE:         buildingId: String,
// REMOVED DUPLICATE:         buildingName: String,
// REMOVED DUPLICATE:         category: String,
// REMOVED DUPLICATE:         startTime: String,
// REMOVED DUPLICATE:         endTime: String,
// REMOVED DUPLICATE:         recurrence: String,
// REMOVED DUPLICATE:         skillLevel: String,
// REMOVED DUPLICATE:         status: String,
// REMOVED DUPLICATE:         urgencyLevel: String,
// REMOVED DUPLICATE:         assignedWorkerName: String,
// REMOVED DUPLICATE:         scheduledDate: Date? = nil,
// REMOVED DUPLICATE:         completedAt: Date? = nil,
// REMOVED DUPLICATE:         location: CLLocation? = nil,
// REMOVED DUPLICATE:         notes: String? = nil
// REMOVED DUPLICATE:     ) {
// REMOVED DUPLICATE:         self.id = id
// REMOVED DUPLICATE:         self.name = name
// REMOVED DUPLICATE:         self.buildingId = buildingId
// REMOVED DUPLICATE:         self.buildingName = buildingName
// REMOVED DUPLICATE:         self.category = category
// REMOVED DUPLICATE:         self.startTime = startTime
// REMOVED DUPLICATE:         self.endTime = endTime
// REMOVED DUPLICATE:         self.recurrence = recurrence
// REMOVED DUPLICATE:         self.skillLevel = skillLevel
// REMOVED DUPLICATE:         self.status = status
// REMOVED DUPLICATE:         self.urgencyLevel = urgencyLevel
// REMOVED DUPLICATE:         self.assignedWorkerName = assignedWorkerName
// REMOVED DUPLICATE:         self.scheduledDate = scheduledDate
// REMOVED DUPLICATE:         self.completedAt = completedAt
// REMOVED DUPLICATE:         self.notes = notes
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         // Handle location
// REMOVED DUPLICATE:         self.locationLatitude = location?.coordinate.latitude
// REMOVED DUPLICATE:         self.locationLongitude = location?.coordinate.longitude
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // MARK: - Codable Implementation
// REMOVED DUPLICATE:     public init(from decoder: Decoder) throws {
// REMOVED DUPLICATE:         let container = try decoder.container(keyedBy: CodingKeys.self)
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         id = try container.decode(String.self, forKey: .id)
// REMOVED DUPLICATE:         name = try container.decode(String.self, forKey: .name)
// REMOVED DUPLICATE:         buildingId = try container.decode(String.self, forKey: .buildingId)
// REMOVED DUPLICATE:         buildingName = try container.decode(String.self, forKey: .buildingName)
// REMOVED DUPLICATE:         category = try container.decode(String.self, forKey: .category)
// REMOVED DUPLICATE:         startTime = try container.decode(String.self, forKey: .startTime)
// REMOVED DUPLICATE:         endTime = try container.decode(String.self, forKey: .endTime)
// REMOVED DUPLICATE:         recurrence = try container.decode(String.self, forKey: .recurrence)
// REMOVED DUPLICATE:         skillLevel = try container.decode(String.self, forKey: .skillLevel)
// REMOVED DUPLICATE:         status = try container.decode(String.self, forKey: .status)
// REMOVED DUPLICATE:         urgencyLevel = try container.decode(String.self, forKey: .urgencyLevel)
// REMOVED DUPLICATE:         assignedWorkerName = try container.decode(String.self, forKey: .assignedWorkerName)
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         scheduledDate = try container.decodeIfPresent(Date.self, forKey: .scheduledDate)
// REMOVED DUPLICATE:         completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
// REMOVED DUPLICATE:         notes = try container.decodeIfPresent(String.self, forKey: .notes)
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         locationLatitude = try container.decodeIfPresent(Double.self, forKey: .locationLatitude)
// REMOVED DUPLICATE:         locationLongitude = try container.decodeIfPresent(Double.self, forKey: .locationLongitude)
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public func encode(to encoder: Encoder) throws {
// REMOVED DUPLICATE:         var container = encoder.container(keyedBy: CodingKeys.self)
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         try container.encode(id, forKey: .id)
// REMOVED DUPLICATE:         try container.encode(name, forKey: .name)
// REMOVED DUPLICATE:         try container.encode(buildingId, forKey: .buildingId)
// REMOVED DUPLICATE:         try container.encode(buildingName, forKey: .buildingName)
// REMOVED DUPLICATE:         try container.encode(category, forKey: .category)
// REMOVED DUPLICATE:         try container.encode(startTime, forKey: .startTime)
// REMOVED DUPLICATE:         try container.encode(endTime, forKey: .endTime)
// REMOVED DUPLICATE:         try container.encode(recurrence, forKey: .recurrence)
// REMOVED DUPLICATE:         try container.encode(skillLevel, forKey: .skillLevel)
// REMOVED DUPLICATE:         try container.encode(status, forKey: .status)
// REMOVED DUPLICATE:         try container.encode(urgencyLevel, forKey: .urgencyLevel)
// REMOVED DUPLICATE:         try container.encode(assignedWorkerName, forKey: .assignedWorkerName)
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         try container.encodeIfPresent(scheduledDate, forKey: .scheduledDate)
// REMOVED DUPLICATE:         try container.encodeIfPresent(completedAt, forKey: .completedAt)
// REMOVED DUPLICATE:         try container.encodeIfPresent(notes, forKey: .notes)
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         try container.encodeIfPresent(locationLatitude, forKey: .locationLatitude)
// REMOVED DUPLICATE:         try container.encodeIfPresent(locationLongitude, forKey: .locationLongitude)
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // MARK: - Computed Properties
// REMOVED DUPLICATE:     public var isCompleted: Bool {
// REMOVED DUPLICATE:         return status.lowercased() == "completed"
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public var isOverdue: Bool {
// REMOVED DUPLICATE:         guard let scheduledDate = scheduledDate else { return false }
// REMOVED DUPLICATE:         return scheduledDate < Date() && !isCompleted
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public var priorityScore: Int {
// REMOVED DUPLICATE:         switch urgencyLevel.lowercased() {
// REMOVED DUPLICATE:         case "urgent": return 4
// REMOVED DUPLICATE:         case "high": return 3
// REMOVED DUPLICATE:         case "medium": return 2
// REMOVED DUPLICATE:         case "low": return 1
// REMOVED DUPLICATE:         default: return 2
// REMOVED DUPLICATE:         }
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public var categoryColor: String {
// REMOVED DUPLICATE:         switch category.lowercased() {
// REMOVED DUPLICATE:         case "maintenance": return "orange"
// REMOVED DUPLICATE:         case "cleaning": return "blue"
// REMOVED DUPLICATE:         case "inspection": return "green"
// REMOVED DUPLICATE:         case "sanitation": return "purple"
// REMOVED DUPLICATE:         case "repair": return "red"
// REMOVED DUPLICATE:         default: return "gray"
// REMOVED DUPLICATE:         }
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public var urgencyColor: String {
// REMOVED DUPLICATE:         switch urgencyLevel.lowercased() {
// REMOVED DUPLICATE:         case "urgent": return "red"
// REMOVED DUPLICATE:         case "high": return "orange"
// REMOVED DUPLICATE:         case "medium": return "yellow"
// REMOVED DUPLICATE:         case "low": return "green"
// REMOVED DUPLICATE:         default: return "gray"
// REMOVED DUPLICATE:         }
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // MARK: - Helper Methods
// REMOVED DUPLICATE:     public func formattedStartTime() -> String {
// REMOVED DUPLICATE:         return startTime
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public func formattedEndTime() -> String {
// REMOVED DUPLICATE:         return endTime
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public func estimatedDuration() -> TimeInterval {
// REMOVED DUPLICATE:         let formatter = DateFormatter()
// REMOVED DUPLICATE:         formatter.dateFormat = "HH:mm"
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         guard let start = formatter.date(from: startTime),
// REMOVED DUPLICATE:               let end = formatter.date(from: endTime) else {
// REMOVED DUPLICATE:             return 3600 // Default 1 hour
// REMOVED DUPLICATE:         }
// REMOVED DUPLICATE:         
// REMOVED DUPLICATE:         return end.timeIntervalSince(start)
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     // MARK: - Static Factory Methods
// REMOVED DUPLICATE:     public static func createMaintenanceTask(
// REMOVED DUPLICATE:         name: String,
// REMOVED DUPLICATE:         buildingId: String,
// REMOVED DUPLICATE:         buildingName: String,
// REMOVED DUPLICATE:         assignedWorker: String
// REMOVED DUPLICATE:     ) -> ContextualTask {
// REMOVED DUPLICATE:         return ContextualTask(
// REMOVED DUPLICATE:             name: name,
// REMOVED DUPLICATE:             buildingId: buildingId,
// REMOVED DUPLICATE:             buildingName: buildingName,
// REMOVED DUPLICATE:             category: "Maintenance",
// REMOVED DUPLICATE:             startTime: "09:00",
// REMOVED DUPLICATE:             endTime: "10:00",
// REMOVED DUPLICATE:             recurrence: "Daily",
// REMOVED DUPLICATE:             skillLevel: "Basic",
// REMOVED DUPLICATE:             status: "pending",
// REMOVED DUPLICATE:             urgencyLevel: "Medium",
// REMOVED DUPLICATE:             assignedWorkerName: assignedWorker
// REMOVED DUPLICATE:         )
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE:     
// REMOVED DUPLICATE:     public static func createCleaningTask(
// REMOVED DUPLICATE:         name: String,
// REMOVED DUPLICATE:         buildingId: String,
// REMOVED DUPLICATE:         buildingName: String,
// REMOVED DUPLICATE:         assignedWorker: String
// REMOVED DUPLICATE:     ) -> ContextualTask {
// REMOVED DUPLICATE:         return ContextualTask(
// REMOVED DUPLICATE:             name: name,
// REMOVED DUPLICATE:             buildingId: buildingId,
// REMOVED DUPLICATE:             buildingName: buildingName,
// REMOVED DUPLICATE:             category: "Cleaning",
// REMOVED DUPLICATE:             startTime: "08:00",
// REMOVED DUPLICATE:             endTime: "09:00",
// REMOVED DUPLICATE:             recurrence: "Daily",
// REMOVED DUPLICATE:             skillLevel: "Basic",
// REMOVED DUPLICATE:             status: "pending",
// REMOVED DUPLICATE:             urgencyLevel: "Medium",
// REMOVED DUPLICATE:             assignedWorkerName: assignedWorker
// REMOVED DUPLICATE:         )
// REMOVED DUPLICATE:     }
// REMOVED DUPLICATE: }

// MARK: - Hash Implementation
extension ContextualTask {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: ContextualTask, rhs: ContextualTask) -> Bool {
        return lhs.id == rhs.id
    }
}
