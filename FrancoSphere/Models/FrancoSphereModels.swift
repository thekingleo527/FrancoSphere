// FrancoSphereModels.swift
// Core data models for the FrancoSphere application

import Foundation
import SwiftUI
import CoreLocation

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {

    // MARK: - Core Models

    /// Represents a geographic coordinate with a name.
    public struct NamedCoordinate: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        public let imageAssetName: String

        public init(id: String = UUID().uuidString,
                    name: String,
                    latitude: Double,
                    longitude: Double,
                    address: String? = nil,
                    imageAssetName: String) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }

        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        /// Full list of buildings (16 locations)
        public static var allBuildings: [NamedCoordinate] {
            return [
                NamedCoordinate(id: "1", name: "12 West 18th Street", latitude: 40.739750, longitude: -73.994424, address: "12 West 18th Street, New York, NY", imageAssetName: "12_West_18th_Street"),
                NamedCoordinate(id: "2", name: "29-31 East 20th Street", latitude: 40.738957, longitude: -73.986362, address: "29-31 East 20th Street, New York, NY", imageAssetName: "29_31_East_20th_Street"),
                NamedCoordinate(id: "3", name: "36 Walker Street", latitude: 40.718922, longitude: -74.002657, address: "36 Walker Street, New York, NY", imageAssetName: "36_Walker_Street"),
                NamedCoordinate(id: "4", name: "41 Elizabeth Street", latitude: 40.717773, longitude: -73.995608, address: "41 Elizabeth Street, New York, NY", imageAssetName: "41_Elizabeth_Street"),
                NamedCoordinate(id: "5", name: "68 Perry Street", latitude: 40.736258, longitude: -74.003901, address: "68 Perry Street, New York, NY", imageAssetName: "68_Perry_Street"),
                NamedCoordinate(id: "6", name: "104 Franklin Street", latitude: 40.719474, longitude: -74.006746, address: "104 Franklin Street, New York, NY", imageAssetName: "104_Franklin_Street"),
                NamedCoordinate(id: "7", name: "112 West 18th Street", latitude: 40.740160, longitude: -73.998230, address: "112 West 18th Street, New York, NY", imageAssetName: "112_West_18th_Street"),
                NamedCoordinate(id: "8", name: "117 West 17th Street", latitude: 40.740196, longitude: -73.997602, address: "117 West 17th Street, New York, NY", imageAssetName: "117_West_17th_Street"),
                NamedCoordinate(id: "9", name: "123 1st Avenue", latitude: 40.729009, longitude: -73.985394, address: "123 1st Avenue, New York, NY", imageAssetName: "123_1st_Avenue"),
                NamedCoordinate(id: "10", name: "131 Perry Street", latitude: 40.736164, longitude: -74.006250, address: "131 Perry Street, New York, NY", imageAssetName: "131_Perry_Street"),
                NamedCoordinate(id: "11", name: "133 East 15th Street", latitude: 40.734420, longitude: -73.987720, address: "133 East 15th Street, New York, NY", imageAssetName: "133_East_15th_Street"),
                NamedCoordinate(id: "12", name: "135-139 West 17th Street", latitude: 40.739750, longitude: -73.997720, address: "135-139 West 17th Street, New York, NY", imageAssetName: "135West17thStreet"),
                NamedCoordinate(id: "13", name: "136 West 17th Street", latitude: 40.740280, longitude: -73.997790, address: "136 West 17th Street, New York, NY", imageAssetName: "136_West_17th_Street"),
                NamedCoordinate(id: "14", name: "138 West 17th Street", latitude: 40.740280, longitude: -73.997910, address: "138 West 17th Street, New York, NY", imageAssetName: "138_West_17th_Street"),
                NamedCoordinate(id: "15", name: "Rubin Museum (142-148 W 17th)", latitude: 40.740370, longitude: -73.998120, address: "142-148 West 17th Street, New York, NY", imageAssetName: "building15"),
                NamedCoordinate(id: "16", name: "Stuyvesant Cove Park", latitude: 40.731780, longitude: -73.974400, address: "Stuyvesant Cove Park, New York, NY", imageAssetName: "building16")
            ]
        }

        public static func getBuilding(byId id: String) -> NamedCoordinate? {
            return allBuildings.first { $0.id == id }
        }

        public static func getBuildingId(byName name: String) -> String? {
            return allBuildings.first { $0.name == name }?.id
        }
    }

    // MARK: - Task Models

    public enum TaskUrgency: String, Codable, CaseIterable, Hashable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case urgent = "Urgent"

        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .red
            case .urgent: return .purple
            }
        }
    }

    public enum TaskCategory: String, Codable, CaseIterable, Hashable {
        case maintenance = "Maintenance"
        case cleaning = "Cleaning"
        case repair = "Repair"
        case inspection = "Inspection"
        case sanitation = "Sanitation"

        public var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver"
            case .cleaning: return "spray.and.wipe"
            case .repair: return "hammer"
            case .inspection: return "checklist"
            case .sanitation: return "trash"
            }
        }
    }

    public enum TaskRecurrence: String, Codable, CaseIterable, Hashable {
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case biweekly = "Bi-Weekly"
        case quarterly = "Quarterly"
        case semiannual = "Semi-Annual"
        case annual = "Annual"
    }

    public enum VerificationStatus: String, Codable, CaseIterable, Hashable {
        case pending = "Pending Verification"
        case verified = "Verified"
        case rejected = "Verification Failed"

        public var color: Color {
            switch self {
            case .pending: return .orange
            case .verified: return .green
            case .rejected: return .red
            }
        }

        public var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .verified: return "checkmark.seal.fill"
            case .rejected: return "xmark.seal.fill"
            }
        }
    }

    public struct TaskCompletionInfo: Codable, Hashable {
        public let photoPath: String?
        public let date: Date

        public init(photoPath: String? = nil, date: Date = Date()) {
            self.photoPath = photoPath
            self.date = date
        }
    }

    public struct MaintenanceTask: Identifiable, Codable, Hashable {
        public var id: String
        public var name: String
        public var buildingID: String
        public var description: String
        public var dueDate: Date
        public var startTime: Date?
        public var endTime: Date?
        public var category: TaskCategory
        public var urgency: TaskUrgency
        public var recurrence: TaskRecurrence
        public var isComplete: Bool
        public var assignedWorkers: [String]
        public var requiredSkillLevel: String
        public var verificationStatusValue: VerificationStatus?
        public var completionInfo: TaskCompletionInfo?

        public init(id: String = UUID().uuidString,
                    name: String,
                    buildingID: String,
                    description: String = "",
                    dueDate: Date,
                    startTime: Date? = nil,
                    endTime: Date? = nil,
                    category: TaskCategory = .maintenance,
                    urgency: TaskUrgency = .medium,
                    recurrence: TaskRecurrence = .oneTime,
                    isComplete: Bool = false,
                    assignedWorkers: [String] = [],
                    requiredSkillLevel: String = "Basic",
                    verificationStatus: VerificationStatus? = nil,
                    completionInfo: TaskCompletionInfo? = nil) {
            self.id = id
            self.name = name
            self.buildingID = buildingID
            self.description = description
            self.dueDate = dueDate
            self.startTime = startTime
            self.endTime = endTime
            self.category = category
            self.urgency = urgency
            self.recurrence = recurrence
            self.isComplete = isComplete
            self.assignedWorkers = assignedWorkers
            self.requiredSkillLevel = requiredSkillLevel
            self.verificationStatusValue = verificationStatus
            self.completionInfo = completionInfo
        }

        public var verificationStatus: VerificationStatus? {
            get { verificationStatusValue }
            set { verificationStatusValue = newValue }
        }

        public var statusText: String {
            if let status = verificationStatusValue {
                return status.rawValue
            }
            return isComplete ? "Completed" : "Pending"
        }

        public var statusColor: Color {
            if let status = verificationStatusValue {
                return status.color
            }
            return isComplete ? .gray : urgency.color
        }

        public var isPastDue: Bool {
            return !isComplete && dueDate < Date()
        }

        public func nextOccurrence() -> Date? {
            guard !isComplete else { return nil }
            let calendar = Calendar.current
            switch recurrence {
            case .daily:
                return calendar.date(byAdding: .day, value: 1, to: dueDate)
            case .weekly:
                return calendar.date(byAdding: .day, value: 7, to: dueDate)
            case .monthly:
                return calendar.date(byAdding: .month, value: 1, to: dueDate)
            case .oneTime:
                return nil
            case .biweekly:
                return calendar.date(byAdding: .day, value: 14, to: dueDate)
            case .quarterly:
                return calendar.date(byAdding: .month, value: 3, to: dueDate)
            case .semiannual:
                return calendar.date(byAdding: .month, value: 6, to: dueDate)
            case .annual:
                return calendar.date(byAdding: .year, value: 1, to: dueDate)
            }
        }

        public func createNextOccurrence() -> MaintenanceTask? {
            guard let nextDate = nextOccurrence() else { return nil }
            return MaintenanceTask(
                id: UUID().uuidString,
                name: name,
                buildingID: buildingID,
                description: description,
                dueDate: nextDate,
                startTime: startTime,
                endTime: endTime,
                category: category,
                urgency: urgency,
                recurrence: recurrence,
                isComplete: false,
                assignedWorkers: assignedWorkers,
                requiredSkillLevel: requiredSkillLevel
            )
        }

        public func convertToLegacyTaskItem() -> FSTaskItem {
            let intId = Int64(self.id) ?? 0
            let buildingIntId = Int64(self.buildingID) ?? 0
            let workerIntId = self.assignedWorkers.first.flatMap { Int64($0) } ?? 0
            return FSTaskItem(
                id: intId,
                name: self.name,
                description: self.description,
                buildingId: buildingIntId,
                workerId: workerIntId,
                isCompleted: self.isComplete,
                scheduledDate: self.dueDate
            )
        }
    }

    public struct TaskCompletionRecord: Identifiable, Codable, Hashable {
        public let id: String
        public let taskId: String
        public let buildingID: String
        public let workerId: String
        public let completionDate: Date
        public let notes: String?
        public let photoPath: String?
        public var verificationStatusValue: VerificationStatus
        public var verifierID: String?
        public var verificationDate: Date?

        public init(id: String = UUID().uuidString,
                    taskId: String,
                    buildingID: String,
                    workerId: String,
                    completionDate: Date = Date(),
                    notes: String? = nil,
                    photoPath: String? = nil,
                    verificationStatus: VerificationStatus = .pending,
                    verifierID: String? = nil,
                    verificationDate: Date? = nil) {
            self.id = id
            self.taskId = taskId
            self.buildingID = buildingID
            self.workerId = workerId
            self.completionDate = completionDate
            self.notes = notes
            self.photoPath = photoPath
            self.verificationStatusValue = verificationStatus
            self.verifierID = verifierID
            self.verificationDate = verificationDate
        }

        public var verificationStatus: VerificationStatus {
            get { verificationStatusValue }
            set { verificationStatusValue = newValue }
        }

        public var formattedCompletionDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: completionDate)
        }

        public var formattedVerificationDate: String? {
            if let date = verificationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            return nil
        }
    }

    public struct MaintenanceRecord: Identifiable, Codable, Hashable {
        public let id: String
        public let taskId: String
        public let buildingID: String
        public let workerId: String
        public let completionDate: Date
        public let notes: String?
        public let taskName: String
        public let completedBy: String

        public init(id: String = UUID().uuidString,
                    taskId: String,
                    buildingID: String,
                    workerId: String,
                    completionDate: Date = Date(),
                    notes: String? = nil,
                    taskName: String,
                    completedBy: String) {
            self.id = id
            self.taskId = taskId
            self.buildingID = buildingID
            self.workerId = workerId
            self.completionDate = completionDate
            self.notes = notes
            self.taskName = taskName
            self.completedBy = completedBy
        }

        public var formattedCompletionDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: completionDate)
        }
    }

    // MARK: - Worker Models

    public enum WorkerSkill: String, Codable, CaseIterable, Hashable {
        case technical = "Technical"
        case manual = "Manual"
        case administrative = "Administrative"
        case cleaning = "Cleaning"
        case repair = "Repair"
        case inspection = "Inspection"
        case sanitation = "Sanitation"
        case maintenance = "Maintenance"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case hvac = "HVAC"
        case security = "Security"
        case management = "Management"

        public var icon: String {
            switch self {
            case .technical: return "cpu"
            case .manual: return "hand.raised"
            case .administrative: return "folder"
            case .cleaning: return "spray.and.wipe"
            case .repair: return "hammer"
            case .inspection: return "checklist"
            case .sanitation: return "trash"
            case .maintenance: return "wrench.and.screwdriver"
            case .electrical: return "bolt"
            case .plumbing: return "drop"
            case .hvac: return "fan"
            case .security: return "lock.shield"
            case .management: return "person.2"
            }
        }

        public var color: Color {
            switch self {
            case .technical: return .blue
            case .manual: return .orange
            case .administrative: return .purple
            case .cleaning: return .teal
            case .repair: return .red
            case .inspection: return .yellow
            case .sanitation: return .green
            case .maintenance: return .blue
            case .electrical: return .yellow
            case .plumbing: return .cyan
            case .hvac: return .mint
            case .security: return .red
            case .management: return .purple
            }
        }
    }

    public enum SkillLevel: String, Codable, CaseIterable, Hashable {
        case basic = "Basic"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
    }

    public enum UserRole: String, Codable, CaseIterable, Hashable {
        case admin = "Admin"
        case worker = "Worker"
        case manager = "Manager"

        public var displayName: String {
            switch self {
            case .worker: return "Maintenance Worker"
            case .admin: return "System Administrator"
            case .manager: return "Manager"
            }
        }
    }

    public struct WorkerProfile: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let email: String
        public let role: UserRole
        public let skills: [WorkerSkill]
        public let assignedBuildings: [String]
        public let skillLevel: SkillLevel

        public init(id: String = UUID().uuidString,
                    name: String,
                    email: String,
                    role: UserRole = .worker,
                    skills: [WorkerSkill] = [],
                    assignedBuildings: [String] = [],
                    skillLevel: SkillLevel = .basic) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skills = skills
            self.assignedBuildings = assignedBuildings
            self.skillLevel = skillLevel
        }

        public static var allWorkers: [WorkerProfile] {
            return [
                WorkerProfile(id: "1", name: "Edwin Lema", email: "edwin@francosphere.com", role: .worker,
                              skills: [.maintenance, .cleaning, .repair],
                              assignedBuildings: ["1", "2", "7", "8", "12", "13", "14"],
                              skillLevel: .intermediate),
                WorkerProfile(id: "2", name: "Jose Rodriguez", email: "jose@francosphere.com", role: .worker,
                              skills: [.maintenance, .cleaning, .sanitation],
                              assignedBuildings: ["3", "4", "6", "9"],
                              skillLevel: .intermediate),
                WorkerProfile(id: "3", name: "Greg", email: "greg@francosphere.com", role: .worker,
                              skills: [.maintenance, .repair, .plumbing, .electrical],
                              assignedBuildings: ["5", "10", "11"],
                              skillLevel: .advanced),
                WorkerProfile(id: "4", name: "Angel", email: "angel@francosphere.com", role: .worker,
                              skills: [.maintenance, .cleaning, .sanitation],
                              assignedBuildings: ["15", "16"],
                              skillLevel: .intermediate)
            ]
        }

        public static func getWorker(byId id: String) -> WorkerProfile? {
            return allWorkers.first { $0.id == id }
        }

        public static func getWorkerId(byName name: String) -> String? {
            return allWorkers.first { $0.name == name }?.id
        }
    }

    public struct WorkerAssignment: Identifiable, Codable, Hashable {
        public let id: String
        public let workerId: String
        public let taskId: String
        public let assignmentDate: Date
        public let workerName: String
        public let shift: String?
        public let specialRole: String?

        public init(id: String = UUID().uuidString,
                    workerId: String,
                    taskId: String,
                    assignmentDate: Date = Date(),
                    workerName: String = "",
                    shift: String? = nil,
                    specialRole: String? = nil) {
            self.id = id
            self.workerId = workerId
            self.taskId = taskId
            self.assignmentDate = assignmentDate
            self.workerName = workerName
            self.shift = shift
            self.specialRole = specialRole
        }
    }

    // MARK: - Task Templates

    public struct TaskTemplate: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let category: TaskCategory
        public let description: String
        public let requiredSkillLevel: String
        public let recurrence: TaskRecurrence
        public let urgency: TaskUrgency

        public init(id: String = UUID().uuidString,
                    name: String,
                    category: TaskCategory,
                    description: String,
                    requiredSkillLevel: String,
                    recurrence: TaskRecurrence,
                    urgency: TaskUrgency) {
            self.id = id
            self.name = name
            self.category = category
            self.description = description
            self.requiredSkillLevel = requiredSkillLevel
            self.recurrence = recurrence
            self.urgency = urgency
        }

        public static var allTaskTemplates: [TaskTemplate] {
            return [
                TaskTemplate(
                    id: "1",
                    name: "HVAC Filter Replacement",
                    category: .maintenance,
                    description: "Replace all air filters in the HVAC system",
                    requiredSkillLevel: "Intermediate",
                    recurrence: .monthly,
                    urgency: .medium
                ),
                TaskTemplate(
                    id: "2",
                    name: "Lobby Floor Cleaning",
                    category: .cleaning,
                    description: "Deep clean the lobby floor and entrance mats",
                    requiredSkillLevel: "Basic",
                    recurrence: .weekly,
                    urgency: .low
                ),
                TaskTemplate(
                    id: "3",
                    name: "Check Rain Gutters & Drainage",
                    category: .maintenance,
                    description: "Inspect and clear all gutters, downspouts, and drainage areas",
                    requiredSkillLevel: "Intermediate",
                    recurrence: .monthly,
                    urgency: .medium
                )
            ]
        }

        public func createTask(buildingID: String, dueDate: Date) -> MaintenanceTask {
            return MaintenanceTask(
                id: UUID().uuidString,
                name: name,
                buildingID: buildingID,
                description: description,
                dueDate: dueDate,
                category: category,
                urgency: urgency,
                recurrence: recurrence,
                isComplete: false,
                assignedWorkers: [],
                requiredSkillLevel: requiredSkillLevel
            )
        }
    }

    // MARK: - CSV Data Mapping Helper

    public class CSVDataMapper {
        public static func getBuildingID(fromName name: String) -> String? {
            return NamedCoordinate.getBuildingId(byName: name)
        }

        public static func getWorkerID(fromName name: String) -> String? {
            return WorkerProfile.getWorkerId(byName: name)
        }

        public static func createTaskFromCSVData(
            taskName: String,
            buildingName: String,
            workerName: String,
            category: String,
            skillLevel: String,
            recurrence: String,
            dueDate: Date = Date().addingTimeInterval(86400 * 7)
        ) -> MaintenanceTask? {
            guard let buildingID = getBuildingID(fromName: buildingName),
                  let workerID = getWorkerID(fromName: workerName),
                  let taskCategory = TaskCategory(rawValue: category),
                  let taskRecurrence = TaskRecurrence(rawValue: recurrence) else {
                return nil
            }

            let taskTemplate = TaskTemplate.allTaskTemplates.first(where: { $0.name == taskName })

            let task = MaintenanceTask(
                id: UUID().uuidString,
                name: taskName,
                buildingID: buildingID,
                description: taskTemplate?.description ?? "",
                dueDate: dueDate,
                category: taskCategory,
                urgency: taskTemplate?.urgency ?? .medium,
                recurrence: taskRecurrence,
                isComplete: false,
                assignedWorkers: [workerID],
                requiredSkillLevel: skillLevel
            )

            return task
        }

        public static func validateCSVData(
            category: String,
            urgency: String,
            recurrence: String,
            skillLevel: String
        ) -> [String] {
            var errors: [String] = []
            if TaskCategory(rawValue: category) == nil {
                errors.append("Invalid category: \(category)")
            }
            if TaskUrgency(rawValue: urgency) == nil {
                errors.append("Invalid urgency level: \(urgency)")
            }
            if TaskRecurrence(rawValue: recurrence) == nil {
                errors.append("Invalid recurrence pattern: \(recurrence)")
            }
            if SkillLevel(rawValue: skillLevel) == nil {
                errors.append("Invalid skill level: \(skillLevel)")
            }
            return errors
        }
    }

    // MARK: - Building Status

    public enum BuildingStatus: String, Codable, Hashable {
        case operational = "Operational"
        case underMaintenance = "Under Maintenance"
        case closed = "Closed"
        case routineComplete = "Complete"
        case routinePartial = "Partial"
        case routinePending = "Pending"
        case routineOverdue = "Overdue"

        public var color: Color {
            switch self {
            case .operational: return .green
            case .underMaintenance: return .orange
            case .closed: return .red
            case .routineComplete: return .green
            case .routinePartial: return .yellow
            case .routinePending: return .blue
            case .routineOverdue: return .red
            }
        }
    }

    // MARK: - Inventory Models

    public enum InventoryCategory: String, Codable, CaseIterable, Hashable {
        case cleaning = "cleaning"
        case tools = "tools"
        case safety = "safety"
        case electrical = "electrical"
        case plumbing = "plumbing"
        case hvac = "hvac"
        case painting = "painting"
        case flooring = "flooring"
        case hardware = "hardware"
        case office = "office"
        case maintenance = "maintenance"
        case other = "other"

        public var icon: String {
            switch self {
            case .cleaning: return "spray.and.wipe"
            case .tools: return "wrench.and.screwdriver"
            case .safety: return "exclamationmark.shield"
            case .electrical: return "bolt"
            case .plumbing: return "drop"
            case .hvac: return "fan"
            case .painting: return "paintbrush"
            case .flooring: return "square.grid.3x3"
            case .hardware: return "hammer"
            case .office: return "printer"
            case .maintenance: return "gear"
            case .other: return "cube.box"
            }
        }

        public var systemImage: String { icon }

        public var categoryColor: Color {
            switch self {
            case .cleaning: return .blue
            case .tools: return .orange
            case .safety: return .red
            case .electrical: return .yellow
            case .plumbing: return .cyan
            case .hvac: return .mint
            case .painting: return .purple
            case .flooring: return .brown
            case .hardware: return .gray
            case .office: return .indigo
            case .maintenance: return .teal
            case .other: return .gray
            }
        }
    }

    public struct InventoryItem: Identifiable, Codable, Hashable {
        public let id: String
        public var name: String
        public var buildingID: String
        public var category: InventoryCategory
        public var quantity: Int
        public var unit: String
        public var minimumQuantity: Int
        public var needsReorder: Bool
        public var lastRestockDate: Date
        public var location: String
        public var notes: String?

        public init(id: String = UUID().uuidString,
                    name: String,
                    buildingID: String,
                    category: InventoryCategory = .other,
                    quantity: Int = 0,
                    unit: String = "",
                    minimumQuantity: Int = 0,
                    needsReorder: Bool = false,
                    lastRestockDate: Date = Date(),
                    location: String = "",
                    notes: String? = nil) {
            self.id = id
            self.name = name
            self.buildingID = buildingID
            self.category = category
            self.quantity = quantity
            self.unit = unit
            self.minimumQuantity = minimumQuantity
            self.needsReorder = needsReorder
            self.lastRestockDate = lastRestockDate
            self.location = location
            self.notes = notes
        }

        public var shouldReorder: Bool {
            quantity <= minimumQuantity
        }

        public var stockPercentage: Double {
            guard minimumQuantity > 0 else { return 1.0 }
            let targetQuantity = minimumQuantity * 2
            return min(1.0, Double(quantity) / Double(targetQuantity))
        }

        public var statusText: String {
            if quantity <= 0 { return "Out of Stock" }
            else if quantity <= minimumQuantity { return "Low Stock" }
            else { return "In Stock" }
        }

        public var statusColor: Color {
            if quantity <= 0 { return .red }
            else if quantity <= minimumQuantity { return .orange }
            else { return .green }
        }
    }

    public struct InventoryUsageRecord: Identifiable, Codable, Hashable {
        public let id: String
        public let itemID: String
        public let buildingID: String
        public let itemName: String
        public let quantityUsed: Int
        public let usedBy: String
        public let usageDate: Date
        public let notes: String?

        public init(id: String = UUID().uuidString,
                    itemID: String,
                    buildingID: String,
                    itemName: String,
                    quantityUsed: Int,
                    usedBy: String,
                    usageDate: Date = Date(),
                    notes: String? = nil) {
            self.id = id
            self.itemID = itemID
            self.buildingID = buildingID
            self.itemName = itemName
            self.quantityUsed = quantityUsed
            self.usedBy = usedBy
            self.usageDate = usageDate
            self.notes = notes
        }

        public var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: usageDate)
        }
    }

    // MARK: - Inventory Restock Request Models

    public enum RestockStatus: String, Codable, CaseIterable, Hashable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case fulfilled = "Fulfilled"

        public var statusColor: Color {
            switch self {
            case .pending: return .orange
            case .approved: return .blue
            case .fulfilled: return .green
            case .rejected: return .red
            }
        }
    }

    public struct InventoryRestockRequest: Identifiable, Codable, Hashable {
        public let id: String
        public let itemID: String
        public let buildingID: String
        public let itemName: String
        public let currentQuantity: Int
        public let requestedQuantity: Int
        public let requestedBy: String
        public let requestDate: Date
        public var status: RestockStatus
        public var notes: String?
        public var approvedBy: String?
        public var approvalDate: Date?

        public init(id: String = UUID().uuidString,
                    itemID: String,
                    buildingID: String,
                    itemName: String,
                    currentQuantity: Int,
                    requestedQuantity: Int,
                    requestedBy: String,
                    requestDate: Date = Date(),
                    status: RestockStatus = .pending,
                    notes: String? = nil,
                    approvedBy: String? = nil,
                    approvalDate: Date? = nil) {
            self.id = id
            self.itemID = itemID
            self.buildingID = buildingID
            self.itemName = itemName
            self.currentQuantity = currentQuantity
            self.requestedQuantity = requestedQuantity
            self.requestedBy = requestedBy
            self.requestDate = requestDate
            self.status = status
            self.notes = notes
            self.approvedBy = approvedBy
            self.approvalDate = approvalDate
        }

        public var formattedRequestDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: requestDate)
        }

        public var formattedApprovalDate: String? {
            guard let date = approvalDate else { return nil }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }

    // MARK: - Status Chip View

    public struct StatusChipView: View {
        public let status: BuildingStatus

        public init(status: BuildingStatus) {
            self.status = status
        }

        public var body: some View {
            Text(status.rawValue)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(status.color)
                .foregroundColor(.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Legacy Task Item

    public struct FSTaskItem: Identifiable, Codable, Hashable {
        public let id: Int64
        public let name: String
        public let description: String
        public let buildingId: Int64
        public let workerId: Int64
        public let isCompleted: Bool
        public let scheduledDate: Date

        public init(id: Int64,
                    name: String,
                    description: String,
                    buildingId: Int64,
                    workerId: Int64,
                    isCompleted: Bool,
                    scheduledDate: Date) {
            self.id = id
            self.name = name
            self.description = description
            self.buildingId = buildingId
            self.workerId = workerId
            self.isCompleted = isCompleted
            self.scheduledDate = scheduledDate
        }
    }
}

// MARK: - Top-Level Type Aliases

public typealias NamedCoordinate = FrancoSphere.NamedCoordinate
public typealias TaskUrgency = FrancoSphere.TaskUrgency
public typealias TaskCategory = FrancoSphere.TaskCategory
public typealias MaintenanceTask = FrancoSphere.MaintenanceTask
public typealias TaskRecurrence = FrancoSphere.TaskRecurrence
public typealias VerificationStatus = FrancoSphere.VerificationStatus
public typealias TaskCompletionInfo = FrancoSphere.TaskCompletionInfo
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias MaintenanceRecord = FrancoSphere.MaintenanceRecord
public typealias WorkerSkill = FrancoSphere.WorkerSkill
public typealias SkillLevel = FrancoSphere.SkillLevel
public typealias UserRole = FrancoSphere.UserRole
public typealias WorkerProfile = FrancoSphere.WorkerProfile
public typealias WorkerAssignment = FrancoSphere.WorkerAssignment
public typealias TaskTemplate = FrancoSphere.TaskTemplate
public typealias CSVDataMapper = FrancoSphere.CSVDataMapper
public typealias BuildingStatus = FrancoSphere.BuildingStatus
public typealias InventoryCategory = FrancoSphere.InventoryCategory
public typealias InventoryItem = FrancoSphere.InventoryItem
public typealias InventoryUsageRecord = FrancoSphere.InventoryUsageRecord
public typealias RestockStatus = FrancoSphere.RestockStatus
public typealias InventoryRestockRequest = FrancoSphere.InventoryRestockRequest
public typealias StatusChipView = FrancoSphere.StatusChipView
public typealias FSTaskItem = FrancoSphere.FSTaskItem
