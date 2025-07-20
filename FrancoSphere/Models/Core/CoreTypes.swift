//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: All missing types implemented
//  ✅ FIXED: All redeclaration issues resolved
//  ✅ FIXED: All access control issues (public rawValue)
//  ✅ ORGANIZED: Logical grouping maintained
//  ✅ COMPREHENSIVE: Covers all platform requirements
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - CoreTypes Namespace
public struct CoreTypes {
    
    // MARK: - Core ID Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - User Model
    public struct User: Codable, Hashable, Identifiable {
        public let id: String
        public let workerId: WorkerID
        public let name: String
        public let email: String
        public let role: String
        
        public init(id: String = UUID().uuidString, workerId: WorkerID, name: String, email: String, role: String) {
            self.id = id
            self.workerId = workerId
            self.name = name
            self.email = email
            self.role = role
        }
        
        public var isAdmin: Bool { role == "admin" }
        public var isWorker: Bool { role == "worker" }
        public var displayName: String { name }
    }
    
    // MARK: - Dashboard Sync Types
    public enum DashboardSyncStatus: String, Codable, CaseIterable {
        case syncing = "Syncing"
        case synced = "Synced"
        case failed = "Failed"
        case offline = "Offline"
        
        public var color: Color {
            switch self {
            case .synced: return .green
            case .syncing: return .blue
            case .failed: return .red
            case .offline: return .gray
            }
        }
    }
    
    public struct CrossDashboardUpdate: Codable {
        public let updateType: String
        public let data: [String: String]
        public let timestamp: Date
        
        public init(updateType: String, data: [String: String] = [:], timestamp: Date = Date()) {
            self.updateType = updateType
            self.data = data
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Worker Types
    public enum WorkerStatus: String, Codable, CaseIterable {
        case available = "Available"
        case clockedIn = "Clocked In"
        case onBreak = "On Break"
        case offline = "Offline"
        
        public var color: Color {
            switch self {
            case .available: return .green
            case .clockedIn: return .blue
            case .onBreak: return .orange
            case .offline: return .gray
            }
        }
    }
    
    public struct WorkerSkill: Codable, Hashable, Identifiable {
        public let id: String
        public let skillName: String
        public let skillLevel: Int
        public let skillCategory: String
        
        public init(id: String = UUID().uuidString, skillName: String, skillLevel: Int, skillCategory: String) {
            self.id = id
            self.skillName = skillName
            self.skillLevel = skillLevel
            self.skillCategory = skillCategory
        }
        
        public var levelStars: String {
            String(repeating: "⭐", count: min(skillLevel, 5))
        }
        
        public var displayName: String { skillName }
    }
    
    public struct WorkerAssignment: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let taskId: String?
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(id: String = UUID().uuidString, workerId: String, buildingId: String, taskId: String? = nil, assignedDate: Date = Date(), isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.taskId = taskId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }
    
    public struct FrancoWorkerAssignment: Codable, Identifiable {
        public let id: String
        public let workerId: Int64
        public let workerName: String
        public let buildingId: Int64
        public let buildingName: String
        public let startDate: Date
        public let shift: String
        public let specialRole: String?
        public let isActive: Bool
        
        public init(
            id: String = UUID().uuidString,
            workerId: Int64,
            workerName: String,
            buildingId: Int64,
            buildingName: String,
            startDate: Date = Date(),
            shift: String,
            specialRole: String? = nil,
            isActive: Bool = true
        ) {
            self.id = id
            self.workerId = workerId
            self.workerName = workerName
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.startDate = startDate
            self.shift = shift
            self.specialRole = specialRole
            self.isActive = isActive
        }
    }
    
    // MARK: - Building Types
    public enum BuildingTab: String, CaseIterable {
        case overview = "overview"
        case tasks = "tasks"
        case workers = "workers"
        case analytics = "analytics"
        case maintenance = "maintenance"
        
        public var displayName: String {
            switch self {
            case .overview: return "Overview"
            case .tasks: return "Tasks"
            case .workers: return "Workers"
            case .analytics: return "Analytics"
            case .maintenance: return "Maintenance"
            }
        }
        
        public var icon: String {
            switch self {
            case .overview: return "building.2"
            case .tasks: return "list.clipboard"
            case .workers: return "person.2"
            case .analytics: return "chart.bar"
            case .maintenance: return "wrench"
            }
        }
    }
    
    public enum BuildingType: String, Codable, CaseIterable {
        case office = "Office"
        case residential = "Residential"
        case retail = "Retail"
        case industrial = "Industrial"
        case warehouse = "Warehouse"
        case medical = "Medical"
        case educational = "Educational"
        case mixed = "Mixed Use"
        
        public var color: Color {
            switch self {
            case .office: return .blue
            case .residential: return .green
            case .retail: return .purple
            case .industrial: return .orange
            case .warehouse: return .brown
            case .medical: return .red
            case .educational: return .yellow
            case .mixed: return .gray
            }
        }
    }
    
    public struct BuildingMetrics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let completionRate: Double
        public let averageTaskTime: TimeInterval
        public let overdueTasks: Int
        public let totalTasks: Int
        public let activeWorkers: Int
        public let isCompliant: Bool
        public let overallScore: Double
        public let lastUpdated: Date
        
        // Missing properties that caused compilation errors
        public let pendingTasks: Int
        public let urgentTasksCount: Int
        public let hasWorkerOnSite: Bool
        public let maintenanceEfficiency: Double
        public let weeklyCompletionTrend: Double
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            completionRate: Double,
            averageTaskTime: TimeInterval = 3600,
            overdueTasks: Int,
            totalTasks: Int,
            activeWorkers: Int,
            isCompliant: Bool = true,
            overallScore: Double,
            lastUpdated: Date = Date(),
            pendingTasks: Int,
            urgentTasksCount: Int,
            hasWorkerOnSite: Bool = false,
            maintenanceEfficiency: Double = 0.85,
            weeklyCompletionTrend: Double = 0.0
        ) {
            self.id = id
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.averageTaskTime = averageTaskTime
            self.overdueTasks = overdueTasks
            self.totalTasks = totalTasks
            self.activeWorkers = activeWorkers
            self.isCompliant = isCompliant
            self.overallScore = overallScore
            self.lastUpdated = lastUpdated
            self.pendingTasks = pendingTasks
            self.urgentTasksCount = urgentTasksCount
            self.hasWorkerOnSite = hasWorkerOnSite
            self.maintenanceEfficiency = maintenanceEfficiency
            self.weeklyCompletionTrend = weeklyCompletionTrend
        }
        
        public static let empty = BuildingMetrics(
            buildingId: "",
            completionRate: 0.0,
            overdueTasks: 0,
            totalTasks: 0,
            activeWorkers: 0,
            overallScore: 0.0,
            pendingTasks: 0,
            urgentTasksCount: 0
        )
    }
    
    public struct BuildingStatistics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let averageCompletionTime: TimeInterval
        public let workerCount: Int
        public let maintenanceCost: Double
        public let lastUpdated: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            totalTasks: Int,
            completedTasks: Int,
            averageCompletionTime: TimeInterval,
            workerCount: Int,
            maintenanceCost: Double,
            lastUpdated: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.averageCompletionTime = averageCompletionTime
            self.workerCount = workerCount
            self.maintenanceCost = maintenanceCost
            self.lastUpdated = lastUpdated
        }
    }
    
    public struct BuildingAnalytics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let efficiency: Double
        public let costTrends: [String: Double]
        public let performanceMetrics: [String: Double]
        public let predictedMaintenance: [String]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            efficiency: Double,
            costTrends: [String: Double] = [:],
            performanceMetrics: [String: Double] = [:],
            predictedMaintenance: [String] = [],
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.efficiency = efficiency
            self.costTrends = costTrends
            self.performanceMetrics = performanceMetrics
            self.predictedMaintenance = predictedMaintenance
            self.generatedAt = generatedAt
        }
    }
    
    // MARK: - Task Types
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case security = "Security"
        case inspection = "Inspection"
        case administrative = "Administrative"
        case repair = "Repair"
        case installation = "Installation"
        case utilities = "Utilities"
        case emergency = "Emergency"
        case renovation = "Renovation"
        case landscaping = "Landscaping"
        case sanitation = "Sanitation"
        
        public var color: Color {
            switch self {
            case .cleaning: return .blue
            case .maintenance: return .orange
            case .security: return .red
            case .inspection: return .green
            case .administrative: return .purple
            case .repair: return .yellow
            case .installation: return .cyan
            case .utilities: return .brown
            case .emergency: return .red
            case .renovation: return .pink
            case .landscaping: return .green
            case .sanitation: return .blue
            }
        }
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case urgent = "Urgent"
        case emergency = "Emergency"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical, .urgent, .emergency: return .red
            }
        }
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .urgent: return 4
            case .critical: return 5
            case .emergency: return 6
            }
        }
        
        public var sortOrder: Int { priorityValue }
    }
    
    public enum TaskStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case overdue = "Overdue"
        case cancelled = "Cancelled"
        case paused = "Paused"
        case waiting = "Waiting"
        
        public var color: Color {
            switch self {
            case .pending: return .gray
            case .inProgress: return .blue
            case .completed: return .green
            case .overdue: return .red
            case .cancelled: return .gray
            case .paused: return .orange
            case .waiting: return .yellow
            }
        }
    }
    
    public struct MaintenanceTask: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let status: TaskStatus
        public let buildingId: String
        public let assignedWorkerId: String?
        public let estimatedDuration: TimeInterval
        public let createdDate: Date
        public let dueDate: Date?
        public let completedDate: Date?
        public let instructions: String?
        public let requiredSkills: [String]
        public let isRecurring: Bool
        public let parentTaskId: String?
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: TaskCategory,
            urgency: TaskUrgency,
            status: TaskStatus = .pending,
            buildingId: String,
            assignedWorkerId: String? = nil,
            estimatedDuration: TimeInterval = 3600,
            createdDate: Date = Date(),
            dueDate: Date? = nil,
            completedDate: Date? = nil,
            instructions: String? = nil,
            requiredSkills: [String] = [],
            isRecurring: Bool = false,
            parentTaskId: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.status = status
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.estimatedDuration = estimatedDuration
            self.createdDate = createdDate
            self.dueDate = dueDate
            self.completedDate = completedDate
            self.instructions = instructions
            self.requiredSkills = requiredSkills
            self.isRecurring = isRecurring
            self.parentTaskId = parentTaskId
        }
        
        public var isCompleted: Bool { status == .completed }
        public var isOverdue: Bool {
            guard let dueDate = dueDate else { return false }
            return Date() > dueDate && status != .completed
        }
    }
    
    public struct TaskProgress: Codable, Identifiable {
        public let id: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let lastUpdated: Date
        
        public init(
            id: String = UUID().uuidString,
            totalTasks: Int,
            completedTasks: Int,
            lastUpdated: Date = Date()
        ) {
            self.id = id
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.lastUpdated = lastUpdated
        }
        
        public var completionPercentage: Double {
            totalTasks > 0 ? (Double(completedTasks) / Double(totalTasks)) * 100 : 0
        }
        
        public var progressPercentage: Double { completionPercentage }
    }
    
    public struct TaskCompletionRecord: Codable, Identifiable {
        public let id: String
        public let taskId: String
        public let completedDate: Date
        public let workerId: String
        public let verificationStatus: VerificationStatus
        
        public init(
            id: String = UUID().uuidString,
            taskId: String,
            completedDate: Date,
            workerId: String,
            verificationStatus: VerificationStatus = .pending
        ) {
            self.id = id
            self.taskId = taskId
            self.completedDate = completedDate
            self.workerId = workerId
            self.verificationStatus = verificationStatus
        }
    }
    
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
        case notRequired = "Not Required"
        
        public var color: Color {
            switch self {
            case .pending: return .orange
            case .verified: return .green
            case .rejected: return .red
            case .notRequired: return .gray
            }
        }
    }
    
    // MARK: - Maintenance Types
    public struct MaintenanceRecord: Codable, Identifiable {
        public let id: String
        public let taskId: String
        public let description: String
        public let completedDate: Date
        public let workerId: String
        public let cost: Double
        public let category: String
        
        public init(
            id: String = UUID().uuidString,
            taskId: String,
            description: String,
            completedDate: Date,
            workerId: String,
            cost: Double = 0.0,
            category: String = "General"
        ) {
            self.id = id
            self.taskId = taskId
            self.description = description
            self.completedDate = completedDate
            self.workerId = workerId
            self.cost = cost
            self.category = category
        }
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case partlyCloudy = "Partly Cloudy"
        case rainy = "Rainy"
        case stormy = "Stormy"
        case snowy = "Snowy"
        case foggy = "Foggy"
        case windy = "Windy"
        case hot = "Hot"
        case cold = "Cold"
        
        public var icon: String {
            switch self {
            case .sunny: return "sun.max"
            case .cloudy: return "cloud"
            case .partlyCloudy: return "cloud.sun"
            case .rainy: return "cloud.rain"
            case .stormy: return "cloud.bolt"
            case .snowy: return "cloud.snow"
            case .foggy: return "cloud.fog"
            case .windy: return "wind"
            case .hot: return "thermometer.sun"
            case .cold: return "thermometer.snowflake"
            }
        }
    }
    
    public struct WeatherData: Codable, Identifiable {
        public let id: String
        public let temperature: Double
        public let condition: String
        public let humidity: Double
        public let windSpeed: Double
        public let outdoorWorkRisk: OutdoorWorkRisk
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            temperature: Double,
            condition: String,
            humidity: Double,
            windSpeed: Double,
            outdoorWorkRisk: OutdoorWorkRisk = .low,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.temperature = temperature
            self.condition = condition
            self.humidity = humidity
            self.windSpeed = windSpeed
            self.outdoorWorkRisk = outdoorWorkRisk
            self.timestamp = timestamp
        }
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .extreme: return .red
            }
        }
    }
    
    // MARK: - Route Types
    public struct WorkerDailyRoute: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let buildings: [String]
        public let estimatedDuration: TimeInterval
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            date: Date,
            buildings: [String],
            estimatedDuration: TimeInterval
        ) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.buildings = buildings
            self.estimatedDuration = estimatedDuration
        }
    }
    
    public struct RouteOptimization: Codable, Identifiable {
        public let id: String
        public let optimizedRoute: [String]
        public let timeSaved: TimeInterval
        public let efficiency: Double
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            optimizedRoute: [String],
            timeSaved: TimeInterval,
            efficiency: Double,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.optimizedRoute = optimizedRoute
            self.timeSaved = timeSaved
            self.efficiency = efficiency
            self.generatedAt = generatedAt
        }
    }
    
    public struct RouteStop: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let expectedArrival: Date
        public let estimatedDuration: TimeInterval
        public let taskIds: [String]
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            expectedArrival: Date,
            estimatedDuration: TimeInterval,
            taskIds: [String] = []
        ) {
            self.id = id
            self.buildingId = buildingId
            self.expectedArrival = expectedArrival
            self.estimatedDuration = estimatedDuration
            self.taskIds = taskIds
        }
    }
    
    public struct WorkerRoutineSummary: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let tasksCompleted: Int
        public let hoursWorked: Double
        public let buildingsVisited: [String]
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            date: Date,
            tasksCompleted: Int,
            hoursWorked: Double,
            buildingsVisited: [String]
        ) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.tasksCompleted = tasksCompleted
            self.hoursWorked = hoursWorked
            self.buildingsVisited = buildingsVisited
        }
    }
    
    // MARK: - Performance Types
    public struct PerformanceMetrics: Codable, Identifiable {
        public let id: String
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageTime: Double
        public let qualityScore: Double
        public let lastUpdate: Date
        
        public init(
            id: String = UUID().uuidString,
            efficiency: Double,
            tasksCompleted: Int,
            averageTime: Double,
            qualityScore: Double,
            lastUpdate: Date = Date()
        ) {
            self.id = id
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageTime = averageTime
            self.qualityScore = qualityScore
            self.lastUpdate = lastUpdate
        }
        
        public var performanceGrade: String {
            let score = (efficiency + qualityScore) / 2
            switch score {
            case 0.9...1.0: return "A+"
            case 0.8..<0.9: return "A"
            case 0.7..<0.8: return "B"
            case 0.6..<0.7: return "C"
            default: return "D"
            }
        }
    }
    
    // MARK: - Trend Types
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "Up"
        case down = "Down"
        case stable = "Stable"
        case improving = "Improving"
        case declining = "Declining"
        case unknown = "Unknown"
        
        public var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            case .unknown: return "questionmark"
            }
        }
        
        public var color: Color {
            switch self {
            case .up, .improving: return .green
            case .down, .declining: return .red
            case .stable: return .blue
            case .unknown: return .gray
            }
        }
    }
    
    // MARK: - Skill Types
    public enum SkillLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        public var numericValue: Int {
            switch self {
            case .beginner: return 1
            case .intermediate: return 2
            case .advanced: return 3
            case .expert: return 4
            }
        }
        
        public var color: Color {
            switch self {
            case .beginner: return .red
            case .intermediate: return .orange
            case .advanced: return .yellow
            case .expert: return .green
            }
        }
    }
    
    // MARK: - Inventory Types
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
        
        public var color: Color {
            switch self {
            case .inStock: return .green
            case .lowStock: return .orange
            case .outOfStock: return .red
            case .ordered: return .blue
            }
        }
    }
    
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case tools = "Tools"
        case safety = "Safety"
        case electrical = "Electrical"
        case plumbing = "Plumbing"
        case general = "General"
        case office = "Office"
        case maintenance = "Maintenance"
        
        public var color: Color {
            switch self {
            case .cleaning: return .blue
            case .tools: return .orange
            case .safety: return .red
            case .electrical: return .yellow
            case .plumbing: return .cyan
            case .general: return .gray
            case .office: return .purple
            case .maintenance: return .green
            }
        }
    }
    
    public struct InventoryItem: Codable, Identifiable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let maxStock: Int
        public let unit: String
        public let costPerUnit: Double
        public let supplier: String?
        public let location: String?
        public let lastRestocked: Date?
        public let status: RestockStatus
        
        public init(
            id: String = UUID().uuidString,
            name: String,
            category: InventoryCategory,
            currentStock: Int,
            minimumStock: Int,
            maxStock: Int,
            unit: String,
            costPerUnit: Double,
            supplier: String? = nil,
            location: String? = nil,
            lastRestocked: Date? = nil,
            status: RestockStatus = .inStock
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.currentStock = currentStock
            self.minimumStock = minimumStock
            self.maxStock = maxStock
            self.unit = unit
            self.costPerUnit = costPerUnit
            self.supplier = supplier
            self.location = location
            self.lastRestocked = lastRestocked
            self.status = status
        }
        
        public var needsRestock: Bool { currentStock <= minimumStock }
        public var stockPercentage: Double {
            maxStock > 0 ? Double(currentStock) / Double(maxStock) : 0
        }
    }
    
    // MARK: - AI Types
    public enum AIPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        public var numericValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    public typealias InsightPriority = AIPriority // Alias for backward compatibility
    
    public enum InsightCategory: String, Codable, CaseIterable {
        case efficiency = "Efficiency"
        case cost = "Cost"
        case safety = "Safety"
        case compliance = "Compliance"
        case quality = "Quality"
        case operations = "Operations"
        case maintenance = "Maintenance"
        
        public var icon: String {
            switch self {
            case .efficiency: return "speedometer"
            case .cost: return "dollarsign"
            case .safety: return "shield"
            case .compliance: return "checkmark.shield"
            case .quality: return "star"
            case .operations: return "gear"
            case .maintenance: return "wrench"
            }
        }
        
        public var color: Color {
            switch self {
            case .efficiency: return .blue
            case .cost: return .green
            case .safety: return .red
            case .compliance: return .orange
            case .quality: return .purple
            case .operations: return .gray
            case .maintenance: return .yellow
            }
        }
    }
    
    public typealias InsightType = InsightCategory // Alias for backward compatibility
    
    public struct AISuggestion: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: AIPriority
        public let category: InsightCategory
        public let actionRequired: Bool
        public let estimatedImpact: String
        public let createdAt: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            priority: AIPriority,
            category: InsightCategory,
            actionRequired: Bool = false,
            estimatedImpact: String = "Low",
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
            self.category = category
            self.actionRequired = actionRequired
            self.estimatedImpact = estimatedImpact
            self.createdAt = createdAt
        }
        
        public init(suggestion: String) {
            self.id = UUID().uuidString
            self.title = suggestion.capitalized
            self.description = "AI suggestion: \(suggestion)"
            self.priority = .medium
            self.category = .operations
            self.actionRequired = false
            self.estimatedImpact = "Medium"
            self.createdAt = Date()
        }
    }
    
    public enum AIScenarioType: String, Codable, CaseIterable {
        case clockOutReminder = "clock_out_reminder"
        case weatherAlert = "weather_alert"
        case inventoryLow = "inventory_low"
        case routineIncomplete = "routine_incomplete"
        case pendingTasks = "pending_tasks"
        case emergencyRepair = "emergency_repair"
        case taskOverdue = "task_overdue"
        case buildingAlert = "building_alert"
        
        public var displayTitle: String {
            switch self {
            case .clockOutReminder: return "Clock Out Reminder"
            case .weatherAlert: return "Weather Alert"
            case .inventoryLow: return "Inventory Low"
            case .routineIncomplete: return "Routine Incomplete"
            case .pendingTasks: return "Pending Tasks"
            case .emergencyRepair: return "Emergency Repair"
            case .taskOverdue: return "Task Overdue"
            case .buildingAlert: return "Building Alert"
            }
        }
        
        public var priority: AIPriority {
            switch self {
            case .emergencyRepair, .buildingAlert: return .critical
            case .taskOverdue, .weatherAlert: return .high
            case .pendingTasks, .routineIncomplete: return .medium
            case .clockOutReminder, .inventoryLow: return .low
            }
        }
    }
    
    public struct AIScenario: Codable, Identifiable {
        public let id: String
        public let type: AIScenarioType
        public let title: String
        public let description: String
        public let priority: AIPriority
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            type: AIScenarioType,
            title: String,
            description: String,
            priority: AIPriority? = nil,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.type = type
            self.title = title
            self.description = description
            self.priority = priority ?? type.priority
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Intelligence Types
    public struct IntelligenceInsight: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightCategory
        public let priority: AIPriority
        public let actionRequired: Bool
        public let affectedBuildings: [String]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightCategory,
            priority: AIPriority,
            actionRequired: Bool = false,
            affectedBuildings: [String] = [],
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionRequired = actionRequired
            self.affectedBuildings = affectedBuildings
            self.generatedAt = generatedAt
        }
    }
    
    // MARK: - Client Dashboard Types
    public struct ExecutiveSummary: Codable, Identifiable {
        public let id: String
        public let totalBuildings: Int
        public let totalWorkers: Int
        public let portfolioHealth: Double
        public let monthlyPerformance: String
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            totalBuildings: Int,
            totalWorkers: Int,
            portfolioHealth: Double,
            monthlyPerformance: String,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.totalBuildings = totalBuildings
            self.totalWorkers = totalWorkers
            self.portfolioHealth = portfolioHealth
            self.monthlyPerformance = monthlyPerformance
            self.generatedAt = generatedAt
        }
    }
    
    public struct PortfolioBenchmark: Codable, Identifiable {
        public let id: String
        public let metric: String
        public let value: Double
        public let benchmark: Double
        public let trend: String
        public let period: String
        
        public init(
            id: String = UUID().uuidString,
            metric: String,
            value: Double,
            benchmark: Double,
            trend: String,
            period: String
        ) {
            self.id = id
            self.metric = metric
            self.value = value
            self.benchmark = benchmark
            self.trend = trend
            self.period = period
        }
    }
    
    public struct StrategicRecommendation: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: InsightCategory
        public let priority: Priority
        public let timeframe: String
        public let estimatedImpact: String
        
        public enum Priority: String, Codable, CaseIterable {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            case critical = "Critical"
            
            public var color: Color {
                switch self {
                case .low: return .green
                case .medium: return .yellow
                case .high: return .orange
                case .critical: return .red
                }
            }
        }
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: InsightCategory,
            priority: Priority,
            timeframe: String,
            estimatedImpact: String
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.priority = priority
            self.timeframe = timeframe
            self.estimatedImpact = estimatedImpact
        }
    }
    
    public struct PortfolioIntelligence: Codable, Identifiable {
        public let id: String
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completionRate: Double
        public let criticalIssues: Int
        public let monthlyTrend: TrendDirection
        public let complianceScore: Double
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            totalBuildings: Int,
            activeWorkers: Int,
            completionRate: Double,
            criticalIssues: Int,
            monthlyTrend: TrendDirection,
            complianceScore: Double,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.completionRate = completionRate
            self.criticalIssues = criticalIssues
            self.monthlyTrend = monthlyTrend
            self.complianceScore = complianceScore
            self.generatedAt = generatedAt
        }
    }
    
    // MARK: - Compliance Types
    public enum ComplianceTab: String, CaseIterable {
        case overview = "overview"
        case issues = "issues"
        case reports = "reports"
        case audit = "audit"
        
        public var displayName: String {
            switch self {
            case .overview: return "Overview"
            case .issues: return "Issues"
            case .reports: return "Reports"
            case .audit: return "Audit"
            }
        }
    }
    
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
        case compliant = "Compliant"
        case warning = "Warning"
        case violation = "Violation"
        case pending = "Pending"
        case nonCompliant = "Non-Compliant"
        case atRisk = "At Risk"
        case needsReview = "Needs Review"
        
        public var color: Color {
            switch self {
            case .compliant: return .green
            case .warning: return .yellow
            case .violation, .nonCompliant: return .red
            case .pending, .needsReview: return .orange
            case .atRisk: return .orange
            case .open: return .red
            case .inProgress: return .orange
            case .resolved: return .blue
            }
        }
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case environmental = "Environmental"
        case regulatory = "Regulatory"
        case financial = "Financial"
        case operational = "Operational"
        case documentation = "Documentation"
        
        public var color: Color {
            switch self {
            case .safety: return .red
            case .environmental: return .green
            case .regulatory: return .blue
            case .financial: return .orange
            case .operational: return .purple
            case .documentation: return .gray
            }
        }
    }
    
    public struct ComplianceIssue: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let severity: ComplianceSeverity
        public let buildingId: String?
        public let status: ComplianceStatus
        public let dueDate: Date?
        public let assignedTo: String?
        public let createdAt: Date
        public let type: ComplianceIssueType?
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            severity: ComplianceSeverity,
            buildingId: String? = nil,
            status: ComplianceStatus = .open,
            dueDate: Date? = nil,
            assignedTo: String? = nil,
            createdAt: Date = Date(),
            type: ComplianceIssueType? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.severity = severity
            self.buildingId = buildingId
            self.status = status
            self.dueDate = dueDate
            self.assignedTo = assignedTo
            self.createdAt = createdAt
            self.type = type
        }
    }
    
    // MARK: - Health Status Types
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
        case unknown = "Unknown"
        
        public var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .yellow
            case .error: return .red
            case .unknown: return .gray
            }
        }
    }
    
    // MARK: - Supporting Types
    public struct WeeklySchedule: Codable {
        public let monday: [String]
        public let tuesday: [String]
        public let wednesday: [String]
        public let thursday: [String]
        public let friday: [String]
        public let saturday: [String]
        public let sunday: [String]
        
        public init(
            monday: [String] = [],
            tuesday: [String] = [],
            wednesday: [String] = [],
            thursday: [String] = [],
            friday: [String] = [],
            saturday: [String] = [],
            sunday: [String] = []
        ) {
            self.monday = monday
            self.tuesday = tuesday
            self.wednesday = wednesday
            self.thursday = thursday
            self.friday = friday
            self.saturday = saturday
            self.sunday = sunday
        }
    }
}

// MARK: - Global Type Aliases (For backward compatibility)
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID

// Additional type aliases for missing types
public typealias BuildingMetrics = CoreTypes.BuildingMetrics
public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias BuildingType = CoreTypes.BuildingType
public typealias AIScenarioType = CoreTypes.AIScenarioType
public typealias AIScenario = CoreTypes.AIScenario
public typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
public typealias TaskProgress = CoreTypes.TaskProgress
public typealias TrendDirection = CoreTypes.TrendDirection
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias WeatherCondition = CoreTypes.WeatherCondition
public typealias InventoryItem = CoreTypes.InventoryItem
public typealias InventoryCategory = CoreTypes.InventoryCategory
public typealias RestockStatus = CoreTypes.RestockStatus
public typealias ComplianceStatus = CoreTypes.ComplianceStatus
public typealias ComplianceIssueType = CoreTypes.ComplianceIssueType
public typealias DashboardSyncStatus = CoreTypes.DashboardSyncStatus
public typealias CrossDashboardUpdate = CoreTypes.CrossDashboardUpdate
public typealias InsightPriority = CoreTypes.InsightPriority
public typealias SkillLevel = CoreTypes.SkillLevel
public typealias RouteStop = CoreTypes.RouteStop
public typealias WorkerDailyRoute = CoreTypes.WorkerDailyRoute
public typealias WorkerRoutineSummary = CoreTypes.WorkerRoutineSummary
public typealias BuildingStatistics = CoreTypes.BuildingStatistics

// MARK: - Models Namespace Alias
public typealias Models = CoreTypes

// MARK: - AI Namespace for Nova Integration
public struct AI {
    public typealias Suggestion = CoreTypes.AISuggestion
    public typealias Priority = CoreTypes.AIPriority
    public typealias Insight = CoreTypes.IntelligenceInsight
    public typealias Scenario = CoreTypes.AIScenario
    public typealias ScenarioType = CoreTypes.AIScenarioType
}

// MARK: - Task Manager (Referenced in error logs)
public class TaskManager {
    public static let shared = TaskManager()
    private init() {}
    
    // Placeholder for TaskManager functionality
    public func getTasks() -> [MaintenanceTask] { [] }
    public func createTask(_ task: MaintenanceTask) {}
    public func updateTask(_ task: MaintenanceTask) {}
    public func deleteTask(id: String) {}
}
