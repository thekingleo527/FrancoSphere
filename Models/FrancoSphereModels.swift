//
//  FrancoSphereModels.swift
//  FrancoSphere
//
//  ✅ ALL TYPE CONFLICTS RESOLVED
//  ✅ Uses CoreTypes.swift as the foundation
//  ✅ Removed duplicate declarations
//  ✅ Backwards compatibility maintained
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - FrancoSphere Namespace
public enum FrancoSphere {
    
    // MARK: - Geographic Models
    public struct NamedCoordinate: Identifiable, Codable, Equatable {
        public let id: String
        public let name: String
        public let latitude: Double
        public let longitude: Double
        public let address: String?
        public let imageAssetName: String?
        
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public init(id: String, name: String, latitude: Double, longitude: Double, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = latitude
            self.longitude = longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public init(id: String, name: String, coordinate: CLLocationCoordinate2D, address: String? = nil, imageAssetName: String? = nil) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.address = address
            self.imageAssetName = imageAssetName
        }
        
        public static func == (lhs: NamedCoordinate, rhs: NamedCoordinate) -> Bool {
            lhs.id == rhs.id
        }
        
        // FIXED: Add computed properties here instead of in extension
        public var shortName: String {
            let components = name.components(separatedBy: " (")
            return components.first ?? name
        }
        
        public var fullAddress: String {
            return address ?? "\(latitude), \(longitude)"
        }
    }
    
    // MARK: - Weather Models
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case windy = "Windy"
        
        public var icon: String {
            switch self {
            case .clear, .sunny: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rainy: return "cloud.rain.fill"
            case .snowy: return "cloud.snow.fill"
            case .stormy: return "cloud.bolt.fill"
            case .foggy: return "cloud.fog.fill"
            case .windy: return "wind"
            }
        }
    }
    
    public struct WeatherData: Identifiable, Codable {
        public let id: String
        public let date: Date
        public let temperature: Double
        public let feelsLike: Double
        public let humidity: Int
        public let windSpeed: Double
        public let windDirection: Int
        public let precipitation: Double
        public let snow: Double
        public let condition: WeatherCondition
        public let uvIndex: Int
        public let visibility: Double
        public let description: String
        
        public init(id: String = UUID().uuidString, date: Date = Date(), temperature: Double, feelsLike: Double? = nil, humidity: Int, windSpeed: Double, windDirection: Int = 0, precipitation: Double = 0, snow: Double = 0, condition: WeatherCondition, uvIndex: Int = 0, visibility: Double = 10, description: String = "") {
            self.id = id
            self.date = date
            self.temperature = temperature
            self.feelsLike = feelsLike ?? temperature
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.windDirection = windDirection
            self.precipitation = precipitation
            self.snow = snow
            self.condition = condition
            self.uvIndex = uvIndex
            self.visibility = visibility
            self.description = description
        }
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case moderate = "Moderate"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }
    
    // MARK: - Task Models (Use CoreTypes for core enums)
    // Use CoreTypes.TaskCategory, CoreTypes.TaskUrgency, CoreTypes.TaskRecurrence
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case needsReview = "Needs Review"
        case failed = "Failed"
        case requiresReview = "Requires Review"
    }
    
    // MARK: - Worker Models
    public enum WorkerSkill: String, Codable, CaseIterable {
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case hvac = "HVAC"
        case carpentry = "Carpentry"
        case painting = "Painting"
        case landscaping = "Landscaping"
        case security = "Security"
        case cleaning = "Cleaning"
        case general = "General Maintenance"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case repair = "Repair"
        case installation = "Installation"
        case utilities = "Utilities"
    }
    
    public enum UserRole: String, Codable, CaseIterable {
        case worker = "Worker"
        case supervisor = "Supervisor"
        case admin = "Admin"
        case manager = "Manager"
    }
    
    public struct WorkerProfile: Identifiable, Codable {
        public let id: String
        public let name: String
        public let email: String
        public let phoneNumber: String
        public let role: UserRole
        public let skills: [WorkerSkill]
        public let certifications: [String]
        public let hireDate: Date
        public let isActive: Bool
        public let profileImageUrl: String?
        
        public init(id: String = UUID().uuidString, name: String, email: String, phoneNumber: String, role: UserRole, skills: [WorkerSkill], certifications: [String] = [], hireDate: Date, isActive: Bool = true, profileImageUrl: String? = nil) {
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
    
    public struct WorkerAssignment: Identifiable, Codable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(id: String = UUID().uuidString, workerId: String, buildingId: String, assignedDate: Date, isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }
    
    // MARK: - Inventory Models
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaningSupplies = "Cleaning Supplies"
        case tools = "Tools"
        case safety = "Safety Equipment"
        case maintenance = "Maintenance Parts"
        case office = "Office Supplies"
        case supplies = "Supplies"
        case cleaning = "Cleaning"
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case paint = "Paint"
        case other = "Other"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
    }
    
    public struct InventoryItem: Identifiable, Codable {
        public let id: String
        public let name: String
        public let description: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let unit: String
        public let supplier: String
        public let costPerUnit: Double
        public let restockStatus: RestockStatus
        public let lastRestocked: Date?
        
        public init(id: String = UUID().uuidString, name: String, description: String, category: InventoryCategory, currentStock: Int, minimumStock: Int, unit: String, supplier: String, costPerUnit: Double, restockStatus: RestockStatus, lastRestocked: Date? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.category = category
            self.currentStock = currentStock
            self.minimumStock = minimumStock
            self.unit = unit
            self.supplier = supplier
            self.costPerUnit = costPerUnit
            self.restockStatus = restockStatus
            self.lastRestocked = lastRestocked
        }
    }
    
    // MARK: - Contextual Task Model (SINGLE AUTHORITATIVE DEFINITION)
    public struct ContextualTask: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String                    // Primary property
        public let description: String
        public let category: CoreTypes.TaskCategory // Use CoreTypes
        public let urgency: CoreTypes.TaskUrgency   // Use CoreTypes
        public let buildingId: String
        public let buildingName: String             // Real building name
        public let assignedWorkerId: String?        // Real worker ID
        public let assignedWorkerName: String?      // Real worker name
        public var isCompleted: Bool                // Mutable for completion workflow
        public var completedDate: Date?             // When task was completed
        public let dueDate: Date?
        public let estimatedDuration: TimeInterval
        public let recurrence: CoreTypes.TaskRecurrence // Use CoreTypes
        public let notes: String?                   // Additional notes
        
        // Computed properties for compatibility and intelligence
        public var status: String {
            isCompleted ? "completed" : "pending"
        }
        
        public var urgencyLevel: String {
            urgency.rawValue
        }
        
        // Required for intelligence calculations
        public var skillLevel: String {
            switch category {
            case .maintenance, .repair: return "Intermediate"
            case .cleaning, .inspection, .security, .landscaping, .sanitation: return "Basic"
            case .operations: return "Advanced"
            }
        }
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: CoreTypes.TaskCategory,
            urgency: CoreTypes.TaskUrgency,
            buildingId: String,
            buildingName: String,
            assignedWorkerId: String? = nil,
            assignedWorkerName: String? = nil,
            isCompleted: Bool = false,
            completedDate: Date? = nil,
            dueDate: Date? = nil,
            estimatedDuration: TimeInterval = 3600,
            recurrence: CoreTypes.TaskRecurrence = .daily,
            notes: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.assignedWorkerId = assignedWorkerId
            self.assignedWorkerName = assignedWorkerName
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.notes = notes
        }
    }
    
    // MARK: - Legacy MaintenanceTask (for compatibility)
    public struct MaintenanceTask: Identifiable, Codable {
        public let id: String
        public let title: String
        public let description: String
        public let category: CoreTypes.TaskCategory
        public let urgency: CoreTypes.TaskUrgency
        public let recurrence: CoreTypes.TaskRecurrence
        public let estimatedDuration: TimeInterval
        public let requiredSkills: [WorkerSkill]
        public let buildingId: String
        public let assignedWorkerId: String?
        public let dueDate: Date?
        public let completedDate: Date?
        public let isCompleted: Bool
        public let notes: String?
        public let status: VerificationStatus
        
        public init(id: String = UUID().uuidString, title: String, description: String, category: CoreTypes.TaskCategory, urgency: CoreTypes.TaskUrgency, recurrence: CoreTypes.TaskRecurrence = .daily, estimatedDuration: TimeInterval = 3600, requiredSkills: [WorkerSkill] = [], buildingId: String, assignedWorkerId: String? = nil, dueDate: Date? = nil, completedDate: Date? = nil, isCompleted: Bool = false, notes: String? = nil, status: VerificationStatus = .pending) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.recurrence = recurrence
            self.estimatedDuration = estimatedDuration
            self.requiredSkills = requiredSkills
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.dueDate = dueDate
            self.completedDate = completedDate
            self.isCompleted = isCompleted
            self.notes = notes
            self.status = status
        }
    }
    
    // MARK: - Task Evidence
    public struct TaskEvidence: Codable {
        public let photos: [Data]
        public let timestamp: Date
        public let locationLatitude: Double?
        public let locationLongitude: Double?
        public let notes: String?
        
        public init(photos: [Data], timestamp: Date, locationLatitude: Double? = nil, locationLongitude: Double? = nil, notes: String?) {
            self.photos = photos
            self.timestamp = timestamp
            self.locationLatitude = locationLatitude
            self.locationLongitude = locationLongitude
            self.notes = notes
        }
    }
    
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case critical = "Critical"
        case unknown = "Unknown"
        case error = "Error"
    }
    
    public struct WeatherImpact: Codable {
        public let condition: WeatherCondition
        public let temperature: Double
        public let affectedTaskIds: [String]
        public let recommendation: String
        
        public init(condition: WeatherCondition, temperature: Double, affectedTaskIds: [String], recommendation: String) {
            self.condition = condition
            self.temperature = temperature
            self.affectedTaskIds = affectedTaskIds
            self.recommendation = recommendation
        }
    }
    
    // MARK: - Additional Supporting Models
    public enum BuildingStatus: String, Codable, CaseIterable {
        case operational = "Operational"
        case maintenance = "Under Maintenance"
        case offline = "Offline"
        case emergency = "Emergency"
    }
    
    public struct ScheduleConflict: Codable {
        public let conflictDescription: String
        
        public init(conflictDescription: String) {
            self.conflictDescription = conflictDescription
        }
    }
    
    public struct RouteStop: Codable {
        public let stopId: String
        
        public init(stopId: String) {
            self.stopId = stopId
        }
    }
    
    public struct ExportProgress: Codable {
        public let progress: Double
        
        public init(progress: Double) {
            self.progress = progress
        }
    }
    
    public enum ImportError: LocalizedError {
        case noSQLiteManager
        case invalidData(String)
        
        public var errorDescription: String? {
            switch self {
            case .noSQLiteManager:
                return "SQLiteManager not initialized"
            case .invalidData(let message):
                return "Invalid data: \(message)"
            }
        }
    }
    
    public struct WorkerPerformanceMetrics: Codable {
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageCompletionTime: TimeInterval
        
        public init(efficiency: Double, tasksCompleted: Int, averageCompletionTime: TimeInterval) {
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageCompletionTime = averageCompletionTime
        }
    }
    
    public struct MaintenanceRecord: Identifiable, Codable {
        public let id: String
        public let recordId: String
        
        public init(id: String = UUID().uuidString, recordId: String) {
            self.id = id
            self.recordId = recordId
        }
    }
    
    public struct TaskCompletionRecord: Identifiable, Codable {
        public let id: String
        public let completionId: String
        
        public init(id: String = UUID().uuidString, completionId: String) {
            self.id = id
            self.completionId = completionId
        }
    }
    
    public struct WorkerRoutineSummary: Codable {
        public let summary: String
        
        public init(summary: String) {
            self.summary = summary
        }
    }
    
    public struct WorkerDailyRoute: Codable {
        public let route: [String]
        
        public init(route: [String]) {
            self.route = route
        }
    }
    
    public struct RouteOptimization: Codable {
        public let optimizedRoute: [String]
        public let estimatedTime: TimeInterval
        public let efficiencyGain: Double
        
        public init(optimizedRoute: [String], estimatedTime: TimeInterval, efficiencyGain: Double) {
            self.optimizedRoute = optimizedRoute
            self.estimatedTime = estimatedTime
            self.efficiencyGain = efficiencyGain
        }
    }
}

// MARK: - Global Type Aliases (Use CoreTypes where appropriate)

// FIXED: Use CoreTypes for these instead of redefining


// MARK: - Backwards Compatibility Extensions for ContextualTask
extension FrancoSphere.ContextualTask {
    // For compatibility with existing code that uses 'name'
    public var name: String { title }
    
    // For compatibility with existing code that uses 'workerId'
    public var workerId: String { assignedWorkerId ?? "" }
    
    // Time-based computed properties (for ContextualTaskIntelligence.swift compatibility)
    public var startTime: String {
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: dueDate)
        }
        return "9:00 AM"
    }
    
    public var endTime: String {
        if let dueDate = dueDate {
            let endDate = dueDate.addingTimeInterval(estimatedDuration)
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: endDate)
        }
        return "10:00 AM"
    }
    
    public var scheduledDate: Date? {
        return dueDate
    }
    
    public var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }
    
    public var isPastDue: Bool {
        return isOverdue
    }
}

// MARK: - Extensions for UI Compatibility
extension FrancoSphere.WeatherData {
    public var formattedTemperature: String {
        return "\(Int(temperature))°"
    }
}

extension CoreTypes.TaskUrgency {
    public func lowercased() -> String {
        return self.rawValue.lowercased()
    }
}

extension FrancoSphere.VerificationStatus {
    public func lowercased() -> String {
        return self.rawValue.lowercased()
    }
}

extension CoreTypes.TaskCategory {
    public func lowercased() -> String {
        return self.rawValue.lowercased()
    }
    
    public var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench.and.screwdriver"
        case .inspection: return "magnifyingglass"
        case .repair: return "hammer"
        case .landscaping: return "leaf"
        case .security: return "shield"
        case .sanitation: return "drop"
        case .operations: return "gear"
        }
    }
    
    public static var safety: CoreTypes.TaskCategory {
        return .security // Map safety to security
    }
    
    public static var emergency: CoreTypes.TaskCategory {
        return .operations // Map emergency to operations
    }
}

extension FrancoSphere.InventoryCategory {
    public var icon: String {
        switch self {
        case .cleaningSupplies: return "sparkles"
        case .tools: return "wrench.and.screwdriver"
        case .safety: return "shield"
        case .maintenance: return "gear"
        case .office: return "doc"
        case .supplies: return "box"
        case .cleaning: return "sparkles"
        case .plumbing: return "drop"
        case .electrical: return "bolt"
        case .paint: return "paintbrush"
        case .other: return "questionmark.circle"
        }
    }
    
    public var systemImage: String {
        return icon
    }
}

extension FrancoSphere.InventoryItem {
    public var quantity: Int {
        return currentStock
    }
    
    public var minimumQuantity: Int {
        return minimumStock
    }
    
    public var needsReorder: Bool {
        return currentStock <= minimumStock
    }
    
    public var statusColor: Color {
        if currentStock <= 0 {
            return .red
        } else if needsReorder {
            return .orange
        } else {
            return .green
        }
    }
    
    public var lastRestockDate: Date? {
        return lastRestocked
    }
}

extension FrancoSphere.MaintenanceTask {
    public var isComplete: Bool {
        return isCompleted
    }
    
    public var assignedWorkers: [String] {
        return assignedWorkerId != nil ? [assignedWorkerId!] : []
    }
    
    public var buildingID: String {
        return buildingId
    }
    
    public var name: String {
        return title  // Map name to title property
    }
    
    public var startTime: Date? {
        return dueDate
    }
    
    public var endTime: Date? {
        guard let start = dueDate else { return nil }
        return Calendar.current.date(byAdding: .second, value: Int(estimatedDuration), to: start)
    }
    
    public var isPastDue: Bool {
        guard let due = dueDate else { return false }
        return due < Date() && !isCompleted
    }
}

extension FrancoSphere.WorkerProfile {
    public var contactInfo: String {
        var info: [String] = []
        if !phoneNumber.isEmpty {
            info.append(phoneNumber)
        }
        if !email.isEmpty {
            info.append(email)
        }
        return info.joined(separator: " • ")
    }
    
    public var currentBuildingId: String? {
        return nil // Would be populated from assignment data
    }
}

extension PerformanceMetrics {
    public var tasksCompleted: Int {
        return self.tasksCompleted // Use the actual property
    }
}

extension FrancoSphere.NamedCoordinate {
    public func getBuilding() async -> NamedCoordinate? {
        return self  // Return self as the building
    }
}

// MARK: - Legacy Compatibility Type Aliases
}
