// UPDATED: Using centralized TypeRegistry for all types
// FrancoSphereModels.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// "Source of truth" for all FrancoSphere-wide models.
// All other files should reference exactly these definitions,
// via either the namespace `FrancoSphere.<Type>` or the
// top-level typealiases at the bottom.
//
// Fixed compilation errors: duplicate color properties and WeatherAlert redeclaration
// ✅ UPDATED: References to OperationalDataManager (renamed from OperationalDataManager)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import CoreLocation
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: — FrancoSphere Namespace
public enum FrancoSphere {

    // ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
    // MARK: — 1) Core Models
    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, address, imageAssetName
    }
    /// Represents a geographic coordinate with a name (legacy building).
    public struct NamedCoordinate: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let imageAssetName: String

        public init(
            id: String = UUID().uuidString,
            name: String,
            latitude: Double,
            longitude: Double,
            address: String? = nil,
            imageAssetName: String
        ) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.imageAssetName = imageAssetName
        }

        /// Full list of buildings (18 entries including missing ones)
        public static var allBuildings: [NamedCoordinate] {
            return [
                NamedCoordinate(
                    id: "1",
                    name: "12 West 18th Street",
                    latitude: 40.739750,
                    longitude: -73.994424,
                    address: "12 West 18th Street, New York, NY",
                    imageAssetName: "12_West_18th_Street"
                ),
                NamedCoordinate(
                    id: "2",
                    name: "29-31 East 20th Street",
                    latitude: 40.738957,
                    longitude: -73.986362,
                    address: "29-31 East 20th Street, New York, NY",
                    imageAssetName: "29_31_East_20th_Street"
                ),
                NamedCoordinate(
                    id: "3",
                    name: "36 Walker Street",
                    latitude: 40.7190,
                    longitude: -74.0050,
                    address: "36 Walker St, New York, NY",
                    imageAssetName: "36_Walker_Street"
                ),
                NamedCoordinate(
                    id: "4",
                    name: "41 Elizabeth Street",
                    latitude: 40.7170,
                    longitude: -73.9970,
                    address: "41 Elizabeth St, New York, NY",
                    imageAssetName: "41_Elizabeth_Street"
                ),
                NamedCoordinate(
                    id: "5",
                    name: "68 Perry Street",
                    latitude: 40.7350,
                    longitude: -74.0050,
                    address: "68 Perry St, New York, NY",
                    imageAssetName: "68_Perry_Street"
                ),
                NamedCoordinate(
                    id: "6",
                    name: "104 Franklin Street",
                    latitude: 40.7180,
                    longitude: -74.0060,
                    address: "104 Franklin St, New York, NY",
                    imageAssetName: "104_Franklin_Street"
                ),
                NamedCoordinate(
                    id: "7",
                    name: "112 West 18th Street",
                    latitude: 40.7400,
                    longitude: -73.9940,
                    address: "112 W 18th St, New York, NY",
                    imageAssetName: "112_West_18th_Street"
                ),
                NamedCoordinate(
                    id: "8",
                    name: "117 West 17th Street",
                    latitude: 40.7395,
                    longitude: -73.9950,
                    address: "117 W 17th St, New York, NY",
                    imageAssetName: "117_West_17th_Street"
                ),
                NamedCoordinate(
                    id: "9",
                    name: "123 1st Avenue",
                    latitude: 40.7270,
                    longitude: -73.9850,
                    address: "123 1st Ave, New York, NY",
                    imageAssetName: "123_1st_Avenue"
                ),
                NamedCoordinate(
                    id: "10",
                    name: "131 Perry Street",
                    latitude: 40.7340,
                    longitude: -74.0060,
                    address: "131 Perry St, New York, NY",
                    imageAssetName: "131_Perry_Street"
                ),
                NamedCoordinate(
                    id: "11",
                    name: "133 East 15th Street",
                    latitude: 40.7345,
                    longitude: -73.9875,
                    address: "133 E 15th St, New York, NY",
                    imageAssetName: "133_East_15th_Street"
                ),
                NamedCoordinate(
                    id: "12",
                    name: "135-139 West 17th Street",
                    latitude: 40.7400,
                    longitude: -73.9960,
                    address: "135-139 W 17th St, New York, NY",
                    imageAssetName: "135West17thStreet"
                ),
                NamedCoordinate(
                    id: "13",
                    name: "136 West 17th Street",
                    latitude: 40.7402,
                    longitude: -73.9970,
                    address: "136 W 17th St, New York, NY",
                    imageAssetName: "136_West_17th_Street"
                ),
                NamedCoordinate(
                    id: "15",
                    name: "138 West 17th Street",
                    latitude: 40.7399,
                    longitude: -73.9965,
                    address: "138 W 17th St, New York, NY",
                    imageAssetName: "138West17thStreet"
                ),
                NamedCoordinate(
                    id: "14",
                    name: "Rubin Museum (142-148 W 17th)",
                    latitude: 40.7405,
                    longitude: -73.9980,
                    address: "142-148 W 17th St, New York, NY",
                    imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
                ),
                NamedCoordinate(
                    id: "16",
                    name: "Stuyvesant Cove Park",
                    latitude: 40.7318,
                    longitude: -73.9740,
                    address: "20 Waterside Plaza, New York, NY 10010",
                    imageAssetName: "Stuyvesant_Cove_Park"
                ),
                NamedCoordinate(
                    id: "17",
                    name: "178 Spring Street",
                    latitude: 40.7250,
                    longitude: -74.0020,
                    address: "178 Spring St, New York, NY",
                    imageAssetName: "178_Spring_Street"
                ),
                NamedCoordinate(
                    id: "18",
                    name: "115 7th Avenue",
                    latitude: 40.7390,
                    longitude: -73.9990,
                    address: "115 7th Ave, New York, NY",
                    imageAssetName: "115_7th_Avenue"
                )
            ]
        }
        
        // Explicit Hashable conformance
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        // Explicit Equatable conformance
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            lhs.id == rhs.id
        }
        
        public static func getBuilding(byId id: String) -> NamedCoordinate? {
            return allBuildings.first { $0.id == id }
        }
        
        public static func getBuildingId(byName name: String) -> String? {
            // Handle various name formats from operational data
            let normalizedName = name.lowercased()
                .replacingOccurrences(of: "–", with: "-")
                .replacingOccurrences(of: "_", with: "-")
            
            // Direct matches
            if let building = allBuildings.first(where: { $0.name.lowercased() == normalizedName }) {
                return building.id
            }
            
            // Handle special cases
            switch name {
            case "135–139 West 17th", "135_139 West 17th":
                return "12"
            case "29–31 East 20th", "29_31 East 20th":
                return "2"
            case "36 Walker":
                return "3"
            case "104 Franklin":
                return "6"
            case "123 1st Ave":
                return "9"
            case "Stuyvesant Cove", "Stuyvesant Cove Park":
                return "16"
            case "Rubin Museum", "Rubin Museum (142–148 W 17th)", "Rubin Museum (142-148 W 17th)":
                return "14"
            case "117 W 17th", "117 West 17th Street":
                return "8"
            case "112 W 18th", "112 West 18th Street":
                return "7"
            case "117 W 17th + 112 W 18th":
                return "8" // Return first building for combined
            case "138 W 17th", "138 West 17th Street":
                return "15"
            case "12 W 18th", "12 West 18th Street":
                return "1"
            case "68 Perry", "68 Perry Street":
                return "5"
            case "131 Perry", "131 Perry Street":
                return "10"
            case "41 Elizabeth", "41 Elizabeth Street":
                return "4"
            case "133 E 15th", "133 East 15th Street":
                return "11"
            case "136 W 17th", "136 West 17th", "136 West 17th Street":
                return "13"
            case "178 Spring":
                return "17"
            case "115 7th Ave":
                return "18"
            default:
                return nil
            }
        }
    }
    
    // MARK: — 2) Weather Models

    public enum WeatherCondition: String, Codable, CaseIterable, Hashable {
        case clear        = "Clear"
        case cloudy       = "Cloudy"
        case rain         = "Rain"
        case snow         = "Snow"
        case thunderstorm = "Thunderstorm"
        case fog          = "Fog"
        case other        = "Other"

        public var icon: String {
            switch self {
            case .clear:        return "sun.max.fill"
            case .cloudy:       return "cloud.fill"
            case .rain:         return "cloud.rain.fill"
            case .snow:         return "cloud.snow.fill"
            case .thunderstorm: return "cloud.bolt.fill"
            case .fog:          return "cloud.fog.fill"
            case .other:        return "questionmark.circle"
            }
        }

        public var conditionColor: Color {
            switch self {
            case .clear:        return .yellow
            case .cloudy:       return .gray
            case .rain:         return .blue
            case .snow:         return .cyan
            case .thunderstorm: return .purple
            case .fog:          return .gray
            case .other:        return .gray
            }
        }
    }

    public struct WeatherData: Codable, Hashable {
        public let date: Date
        public let temperature: Double
        public let feelsLike: Double
        public let humidity: Int
        public let windSpeed: Double
        public let windDirection: Int
        public let precipitation: Double
        public let snow: Double
        public let visibility: Int
        public let pressure: Int
        public let condition: WeatherCondition
        public let icon: String

        public init(
            date: Date,
            temperature: Double,
            feelsLike: Double,
            humidity: Int,
            windSpeed: Double,
            windDirection: Int,
            precipitation: Double,
            snow: Double,
            visibility: Int,
            pressure: Int,
            condition: WeatherCondition,
            icon: String
        ) {
            self.date = date
            self.temperature = temperature
            self.feelsLike = feelsLike
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.windDirection = windDirection
            self.precipitation = precipitation
            self.snow = snow
            self.visibility = visibility
            self.pressure = pressure
            self.condition = condition
            self.icon = icon
        }

        public var formattedTemperature: String {
            "\(Int(temperature))°"
        }
        public var formattedHighLow: String {
            "H: \(Int(temperature + 5))°  L: \(Int(temperature - 5))°"
        }

        public enum OutdoorWorkRisk: String {
            case low      = "Low Risk"
            case moderate = "Moderate Risk"
            case high     = "High Risk"
            case extreme  = "Extreme Risk"

            public var riskColor: Color {
                switch self {
                case .low:      return .green
                case .moderate: return .yellow
                case .high:     return .orange
                case .extreme:  return .red
                }
            }
        }

        public var outdoorWorkRisk: OutdoorWorkRisk {
            if temperature < 20 || temperature > 100 || windSpeed > 40 || condition == .thunderstorm {
                return .extreme
            } else if temperature < 32 || temperature > 90 || windSpeed > 25 || precipitation > 0.5 {
                return .high
            } else if temperature < 40 || temperature > 85 || windSpeed > 15 || precipitation > 0.2 {
                return .moderate
            } else {
                return .low
            }
        }
    }

    public struct WeatherAlertModel: Identifiable, Codable, Hashable {
        public let id: String
        public let buildingId: String
        public let buildingName: String
        public let title: String
        public let message: String
        public let icon: String
        public let colorName: String  // Stored as a String
        public let timestamp: Date

        public var alertColor: Color {
            switch colorName {
            case "red":    return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green":  return .green
            case "blue":   return .blue
            case "purple": return .purple
            case "gray":   return .gray
            default:       return .blue
            }
        }

        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            buildingName: String,
            title: String,
            message: String,
            icon: String,
            color: Color,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.title = title
            self.message = message
            self.icon = icon
            switch color {
            case .red:    self.colorName = "red"
            case .orange: self.colorName = "orange"
            case .yellow: self.colorName = "yellow"
            case .green:  self.colorName = "green"
            case .blue:   self.colorName = "blue"
            case .purple: self.colorName = "purple"
            case .gray:   self.colorName = "gray"
            default:      self.colorName = "blue"
            }
            self.timestamp = timestamp
        }
    }

    // ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
    // MARK: — 3) Task Models

    public enum TaskUrgency: String, Codable, CaseIterable, Hashable {
        case low    = "Low"
        case medium = "Medium"
        case high   = "High"
        case urgent = "Urgent"

        public var urgencyColor: Color {
            switch self {
            case .low:    return .green
            case .medium: return .yellow
            case .high:   return .red
            case .urgent: return .purple
            }
        }
    }

    public enum TaskCategory: String, Codable, CaseIterable, Hashable {
        case maintenance = "Maintenance"
        case cleaning     = "Cleaning"
        case repair       = "Repair"
        case inspection   = "Inspection"
        case sanitation   = "Sanitation"

        public var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver"
            case .cleaning:     return "spray.and.wipe"
            case .repair:       return "hammer"
            case .inspection:   return "checklist"
            case .sanitation:   return "trash"
            }
        }
        
        public var categoryColor: Color {
            switch self {
            case .maintenance: return .orange
            case .cleaning:    return .blue
            case .repair:      return .red
            case .inspection:  return .purple
            case .sanitation:  return .green
            }
        }
    }

    public enum TaskRecurrence: String, Codable, CaseIterable, Hashable {
        case oneTime    = "One Time"
        case daily      = "Daily"
        case weekly     = "Weekly"
        case monthly    = "Monthly"
        case biweekly   = "Bi-Weekly"
        case quarterly  = "Quarterly"
        case semiannual = "Semi-Annual"
        case annual     = "Annual"
    }

    public enum VerificationStatus: String, Codable, CaseIterable, Hashable {
        case pending  = "Pending Verification"
        case verified = "Verified"
        case rejected = "Verification Failed"

        public var statusColor: Color {
            switch self {
            case .pending:  return .orange
            case .verified: return .green
            case .rejected: return .red
            }
        }

        public var icon: String {
            switch self {
            case .pending:  return "clock.fill"
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
        public var externalId: String?

        public init(
            id: String = UUID().uuidString,
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
            completionInfo: TaskCompletionInfo? = nil,
            externalId: String? = nil
        ) {
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
            self.externalId = externalId
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
                return status.statusColor
            }
            return isComplete ? .gray : urgency.urgencyColor
        }

        public var isPastDue: Bool {
            !isComplete && dueDate < Date()
        }

        public func nextOccurrence() -> Date? {
            guard !isComplete else { return nil }
            let cal = Calendar.current
            switch recurrence {
            case .daily:
                return cal.date(byAdding: .day, value: 1, to: dueDate)
            case .weekly:
                return cal.date(byAdding: .day, value: 7, to: dueDate)
            case .monthly:
                return cal.date(byAdding: .month, value: 1, to: dueDate)
            case .oneTime:
                return nil
            case .biweekly:
                return cal.date(byAdding: .day, value: 14, to: dueDate)
            case .quarterly:
                return cal.date(byAdding: .month, value: 3, to: dueDate)
            case .semiannual:
                return cal.date(byAdding: .month, value: 6, to: dueDate)
            case .annual:
                return cal.date(byAdding: .year, value: 1, to: dueDate)
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

        public init(
            id: String = UUID().uuidString,
            taskId: String,
            buildingID: String,
            workerId: String,
            completionDate: Date = Date(),
            notes: String? = nil,
            photoPath: String? = nil,
            verificationStatus: VerificationStatus = .pending,
            verifierID: String? = nil,
            verificationDate: Date? = nil
        ) {
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
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            return fmt.string(from: completionDate)
        }

        public var formattedVerificationDate: String? {
            guard let date = verificationDate else { return nil }
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            return fmt.string(from: date)
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

        public init(
            id: String = UUID().uuidString,
            taskId: String,
            buildingID: String,
            workerId: String,
            completionDate: Date = Date(),
            notes: String? = nil,
            taskName: String,
            completedBy: String
        ) {
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
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            return fmt.string(from: completionDate)
        }
    }

    // ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
    // MARK: — 4) Worker Models

    public enum WorkerSkill: String, Codable, CaseIterable, Hashable {
        case technical      = "Technical"
        case manual         = "Manual"
        case administrative = "Administrative"
        case cleaning       = "Cleaning"
        case repair         = "Repair"
        case inspection     = "Inspection"
        case sanitation     = "Sanitation"
        case maintenance    = "Maintenance"
        case electrical     = "Electrical"
        case plumbing       = "Plumbing"
        case hvac           = "HVAC"
        case security       = "Security"
        case management     = "Management"
        case boiler         = "Boiler Operations"
        case landscaping    = "Landscaping"

        public var icon: String {
            switch self {
            case .technical:      return "cpu"
            case .manual:         return "hand.raised"
            case .administrative: return "folder"
            case .cleaning:       return "spray.and.wipe"
            case .repair:         return "hammer"
            case .inspection:     return "checklist"
            case .sanitation:     return "trash"
            case .maintenance:    return "wrench.and.screwdriver"
            case .electrical:     return "bolt"
            case .plumbing:       return "drop"
            case .hvac:           return "fan"
            case .security:       return "lock.shield"
            case .management:     return "person.2"
            case .boiler:         return "flame"
            case .landscaping:    return "leaf"
            }
        }

        public var skillColor: Color {
            switch self {
            case .technical:      return .blue
            case .manual:         return .orange
            case .administrative: return .purple
            case .cleaning:       return .teal
            case .repair:         return .red
            case .inspection:     return .yellow
            case .sanitation:     return .green
            case .maintenance:    return .blue
            case .electrical:     return .yellow
            case .plumbing:       return .cyan
            case .hvac:           return .mint
            case .security:       return .red
            case .management:     return .purple
            case .boiler:         return .orange
            case .landscaping:    return .green
            }
        }
    }

    public enum SkillLevel: String, Codable, CaseIterable, Hashable {
        case basic        = "Basic"
        case intermediate = "Intermediate"
        case advanced     = "Advanced"
        case expert       = "Expert"
    }

    public enum UserRole: String, Codable, CaseIterable, Hashable {
        case admin   = "Admin"
        case worker  = "Worker"
        case manager = "Manager"
        case client  = "Client"

        public var displayName: String {
            switch self {
            case .worker:  return "Maintenance Worker"
            case .admin:   return "System Administrator"
            case .manager: return "Manager"
            case .client:  return "Client"
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

        public init(
            id: String = UUID().uuidString,
            name: String,
            email: String,
            role: UserRole = .worker,
            skills: [WorkerSkill] = [],
            assignedBuildings: [String] = [],
            skillLevel: SkillLevel = .basic
        ) {
            self.id = id
            self.name = name
            self.email = email
            self.role = role
            self.skills = skills
            self.assignedBuildings = assignedBuildings
            self.skillLevel = skillLevel
        }

        /// Complete list of all workers from operational data (active workers only)
        public static var allWorkers: [WorkerProfile] {
            return [
                WorkerProfile(
                    id: "1",
                    name: "Greg Hutson",
                    email: "g.hutson1989@gmail.com",
                    role: .worker,
                    skills: [.maintenance, .repair, .plumbing, .electrical, .inspection],
                    assignedBuildings: ["5", "7", "8", "10", "11", "15"],
                    skillLevel: .advanced
                ),
                WorkerProfile(
                    id: "2",
                    name: "Edwin Lema",
                    email: "edwinlema911@gmail.com",
                    role: .worker,
                    skills: [.maintenance, .cleaning, .repair, .inspection],
                    assignedBuildings: ["1", "2", "4", "7", "8", "10", "12", "13", "14", "16", "18"],
                    skillLevel: .intermediate
                ),
                WorkerProfile(
                    id: "4",
                    name: "Kevin Dutan",
                    email: "dutankevin1@gmail.com",
                    role: .worker,
                    skills: [.maintenance, .cleaning, .sanitation],
                    assignedBuildings: ["2", "3", "4", "5", "6", "9", "10", "12", "15", "17"],
                    skillLevel: .intermediate
                ),
                WorkerProfile(
                    id: "5",
                    name: "Mercedes Inamagua",
                    email: "Jneola@gmail.com",
                    role: .worker,
                    skills: [.cleaning, .sanitation, .maintenance],
                    assignedBuildings: ["1", "6", "7", "8", "12", "13", "14", "15"],
                    skillLevel: .basic
                ),
                WorkerProfile(
                    id: "6",
                    name: "Luis Lopez",
                    email: "luislopez030@yahoo.com",
                    role: .worker,
                    skills: [.maintenance, .cleaning, .inspection],
                    assignedBuildings: ["1", "14"],
                    skillLevel: .intermediate
                ),
                WorkerProfile(
                    id: "7",
                    name: "Angel Guirachocha",
                    email: "lio.angel71@gmail.com",
                    role: .worker,
                    skills: [.maintenance, .cleaning, .sanitation],
                    assignedBuildings: ["1", "7", "8", "12", "13", "16", "18"],
                    skillLevel: .intermediate
                ),
                WorkerProfile(
                    id: "8",
                    name: "Shawn Magloire",
                    email: "shawn@francomanagementgroup.com",
                    role: .worker,
                    skills: [.maintenance, .boiler, .hvac],
                    assignedBuildings: ["7", "8", "11", "13", "14", "18"],
                    skillLevel: .advanced
                ),
                // Shawn's additional accounts for testing
                WorkerProfile(
                    id: "9",
                    name: "Shawn Magloire",
                    email: "FrancoSphere@francomanagementgroup.com",
                    role: .client,
                    skills: [],
                    assignedBuildings: [],
                    skillLevel: .basic
                ),
                WorkerProfile(
                    id: "10",
                    name: "Shawn Magloire",
                    email: "Shawn@fme-llc.com",
                    role: .admin,
                    skills: [.management],
                    assignedBuildings: [], // Admin can access all buildings
                    skillLevel: .expert
                )
            ]
        }

        public static func getWorker(byId id: String) -> WorkerProfile? {
            return allWorkers.first { $0.id == id }
        }
        
        public static func getWorkerId(byName name: String) -> String? {
            // Handle first name only cases
            let searchName = name.lowercased()
            
            // Try exact match first
            if let worker = allWorkers.first(where: { $0.name.lowercased() == searchName }) {
                return worker.id
            }
            
            // Handle first name only cases
            if searchName == "angel" {
                return "7"
            }
            
            return nil
        }
    }


// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// MARK: — Top-Level Type Aliases
//
// Expose every FrancoSphere.<Type> at the top level so
// that all other files can refer to "MaintenanceTask"
// instead of "FrancoSphere.MaintenanceTask."

// Core Models
public typealias NamedCoordinate      = FrancoSphere.NamedCoordinate

// Weather Models
public typealias WeatherCondition     = FrancoSphere.WeatherCondition
public typealias WeatherData          = FrancoSphere.WeatherData
public typealias WeatherAlert         = FrancoSphere.WeatherAlertModel

// Task Models
public typealias VerificationStatus   = FrancoSphere.VerificationStatus
public typealias TaskCompletionInfo   = FrancoSphere.TaskCompletionInfo
public typealias TaskCompletionRecord = FrancoSphere.TaskCompletionRecord
public typealias MaintenanceRecord    = FrancoSphere.MaintenanceRecord

// Worker Models
public typealias WorkerSkill          = FrancoSphere.WorkerSkill
public typealias SkillLevel           = FrancoSphere.SkillLevel
public typealias UserRole             = FrancoSphere.UserRole
public typealias WorkerProfile        = FrancoSphere.WorkerProfile
public typealias WorkerAssignment     = FrancoSphere.WorkerAssignment
public typealias WorkerRoutineSummary = FrancoSphere.WorkerRoutineSummary
public typealias WorkerDailyRoute     = FrancoSphere.WorkerDailyRoute
public typealias RouteStop            = FrancoSphere.RouteStop
public typealias RouteOptimization    = FrancoSphere.RouteOptimization
public typealias ScheduleConflict     = FrancoSphere.ScheduleConflict

// Other Models
public typealias TaskTemplate         = FrancoSphere.TaskTemplate
public typealias OperationalDataMapper = FrancoSphere.OperationalDataMapper  // ✅ UPDATED: Changed from CSVDataMapper
public typealias BuildingStatus       = FrancoSphere.BuildingStatus

// Inventory Models
public typealias InventoryCategory    = FrancoSphere.InventoryCategory
public typealias InventoryItem        = FrancoSphere.InventoryItem
public typealias InventoryUsageRecord = FrancoSphere.InventoryUsageRecord
public typealias RestockStatus        = FrancoSphere.RestockStatus
public typealias InventoryRestockRequest = FrancoSphere.InventoryRestockRequest

// View Components
public typealias StatusChipView       = FrancoSphere.StatusChipView

// Legacy Models
public typealias FSTaskItem           = FrancoSphere.FSTaskItem

// AI Models
public typealias AIScenario           = FrancoSphere.AIScenario

// MARK: - Phase 2 Extensions for Missing Properties
extension FrancoSphere.NamedCoordinate {
    // Add missing address property
    public var address: String? {
        // Use real addresses from production
        switch id {
        case "1": return "12 West 18th Street, New York, NY"
        case "2": return "29-31 East 20th Street, New York, NY"
        case "3": return "36 Walker Street, New York, NY"
        case "4": return "41 Elizabeth Street, New York, NY"
        case "5": return "68 Perry Street, New York, NY"
        case "6": return "104 Franklin Street, New York, NY"
        case "7": return "112 West 18th Street, New York, NY"
        case "8": return "117 West 17th Street, New York, NY"
        case "9": return "123 1st Avenue, New York, NY"
        case "10": return "131 Perry Street, New York, NY"
        case "11": return "133 East 15th Street, New York, NY"
        case "12": return "135-139 West 17th Street, New York, NY"
        case "13": return "136 West 17th Street, New York, NY"
        case "14": return "142-148 West 17th Street, New York, NY"
        case "15": return "138 West 17th Street, New York, NY"
        case "16": return "20 Waterside Plaza, New York, NY 10010"
        case "17": return "178 Spring Street, New York, NY"
        case "18": return "115 7th Avenue, New York, NY"
        default: return nil
        }
    }
}
// MARK: - Missing Type Definitions (Compilation Fix)

extension FrancoSphere {
    
    // Worker Management Types
