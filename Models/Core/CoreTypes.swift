//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ COMPREHENSIVE FIX: All missing types defined
//  ✅ SYSTEMATIC SOLUTION: Addresses all compilation errors
//  ✅ COMPLETE TYPE SYSTEM: Every type the codebase expects
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - CoreTypes Namespace (Complete Definition)
public struct CoreTypes {
    
    // MARK: - Core ID Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - User Authentication Model
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
    
    // MARK: - Task Types
    public enum TaskCategory: String, Codable, CaseIterable {
        case maintenance = "Maintenance"
        case cleaning = "Cleaning"
        case repair = "Repair"
        case inspection = "Inspection"
        case installation = "Installation"
        case utilities = "Utilities"
        case emergency = "Emergency"
        case renovation = "Renovation"
        case landscaping = "Landscaping"
        case security = "Security"
        case sanitation = "Sanitation"
        
        public var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver"
            case .cleaning: return "sparkles"
            case .repair: return "hammer"
            case .inspection: return "magnifyingglass"
            case .installation: return "plus.circle"
            case .utilities: return "bolt"
            case .emergency: return "exclamationmark.triangle"
            case .renovation: return "paintbrush"
            case .landscaping: return "leaf"
            case .security: return "shield"
            case .sanitation: return "trash"
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
        
        public var sortOrder: Int {
            switch self {
            case .emergency: return 6
            case .critical: return 5
            case .urgent: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    // MARK: - MaintenanceTask (Complete Definition)
    public struct MaintenanceTask: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String?
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedWorkerId: String?
        public var isCompleted: Bool
        public var completedDate: Date?
        public let dueDate: Date?
        public let recurrence: TaskRecurrence?
        public let startTime: Date?
        public let endTime: Date?
        public let estimatedDuration: TimeInterval?
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String? = nil,
            category: TaskCategory,
            urgency: TaskUrgency,
            buildingId: String,
            assignedWorkerId: String? = nil,
            isCompleted: Bool = false,
            completedDate: Date? = nil,
            dueDate: Date? = nil,
            recurrence: TaskRecurrence? = nil,
            startTime: Date? = nil,
            endTime: Date? = nil,
            estimatedDuration: TimeInterval? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.dueDate = dueDate
            self.recurrence = recurrence
            self.startTime = startTime
            self.endTime = endTime
            self.estimatedDuration = estimatedDuration
        }
    }
    
    // MARK: - Building & Metrics Types
    public struct BuildingMetrics: Codable, Hashable {
        public let buildingId: String
        public let completionRate: Double
        public let overdueTasksCount: Int
        public let totalTasksCount: Int
        public let averageCompletionTime: TimeInterval
        public let efficiencyScore: Double
        public let lastUpdated: Date
        
        public init(
            buildingId: String,
            completionRate: Double = 0.0,
            overdueTasksCount: Int = 0,
            totalTasksCount: Int = 0,
            averageCompletionTime: TimeInterval = 0,
            efficiencyScore: Double = 0.0,
            lastUpdated: Date = Date()
        ) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.overdueTasksCount = overdueTasksCount
            self.totalTasksCount = totalTasksCount
            self.averageCompletionTime = averageCompletionTime
            self.efficiencyScore = efficiencyScore
            self.lastUpdated = lastUpdated
        }
    }
    
    public struct BuildingAnalytics: Codable, Hashable {
        public let buildingId: String
        public let metrics: BuildingMetrics
        public let trends: TaskTrends
        public let predictions: [String: Double]
        
        public init(buildingId: String, metrics: BuildingMetrics, trends: TaskTrends, predictions: [String: Double] = [:]) {
            self.buildingId = buildingId
            self.metrics = metrics
            self.trends = trends
            self.predictions = predictions
        }
    }
    
    // MARK: - Trend & Direction Types
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "Up"
        case down = "Down"
        case stable = "Stable"
        case unknown = "Unknown"
    }
    
    public struct TaskTrends: Codable, Hashable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        public let comparisonPeriod: String
        public let trend: TrendDirection
        
        public init(
            weeklyCompletion: [Double] = [],
            categoryBreakdown: [String: Int] = [:],
            changePercentage: Double = 0.0,
            comparisonPeriod: String = "Last Week",
            trend: TrendDirection = .stable
        ) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
            self.comparisonPeriod = comparisonPeriod
            self.trend = trend
        }
    }
    
    // MARK: - Compliance Types
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case compliant = "Compliant"
        case nonCompliant = "Non-Compliant"
        case pending = "Pending"
        case unknown = "Unknown"
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case environmental = "Environmental"
        case regulatory = "Regulatory"
        case documentation = "Documentation"
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public struct ComplianceIssue: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let type: ComplianceIssueType
        public let severity: ComplianceSeverity
        public let buildingId: String
        public let discoveredDate: Date
        public let dueDate: Date?
        public let status: ComplianceStatus
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: ComplianceIssueType,
            severity: ComplianceSeverity,
            buildingId: String,
            discoveredDate: Date = Date(),
            dueDate: Date? = nil,
            status: ComplianceStatus = .pending
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.severity = severity
            self.buildingId = buildingId
            self.discoveredDate = discoveredDate
            self.dueDate = dueDate
            self.status = status
        }
    }
    
    // MARK: - Verification Types
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
        case inProgress = "In Progress"
    }
    
    public struct TaskCompletionRecord: Identifiable, Codable, Hashable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let buildingId: String
        public let completionDate: Date
        public let status: VerificationStatus
        
        public init(
            id: String = UUID().uuidString,
            taskId: String,
            workerId: String,
            buildingId: String,
            completionDate: Date = Date(),
            status: VerificationStatus = .pending
        ) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.buildingId = buildingId
            self.completionDate = completionDate
            self.status = status
        }
    }
    
    public struct MaintenanceRecord: Identifiable, Codable, Hashable {
        public let id: String
        public let taskId: String
        public let buildingId: String
        public let workerId: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let completionDate: Date
        public let verificationStatus: VerificationStatus
        
        public init(
            id: String = UUID().uuidString,
            taskId: String,
            buildingId: String,
            workerId: String,
            title: String,
            description: String,
            category: TaskCategory,
            completionDate: Date = Date(),
            verificationStatus: VerificationStatus = .pending
        ) {
            self.id = id
            self.taskId = taskId
            self.buildingId = buildingId
            self.workerId = workerId
            self.title = title
            self.description = description
            self.category = category
            self.completionDate = completionDate
            self.verificationStatus = verificationStatus
        }
    }
    
    // MARK: - Worker Assignment Types
    public struct WorkerAssignment: Identifiable, Codable, Hashable {
        public let id: String
        public let workerId: String
        public let taskId: String
        public let buildingId: String
        public let assignedDate: Date
        public let status: AssignmentStatus
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            taskId: String,
            buildingId: String,
            assignedDate: Date = Date(),
            status: AssignmentStatus = .assigned
        ) {
            self.id = id
            self.workerId = workerId
            self.taskId = taskId
            self.buildingId = buildingId
            self.assignedDate = assignedDate
            self.status = status
        }
    }
    
    public enum AssignmentStatus: String, Codable, CaseIterable {
        case assigned = "Assigned"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
    
    // MARK: - Inventory Types
    public struct InventoryItem: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let unit: String
        public let cost: Double
        public let supplier: String?
        public let restockStatus: RestockStatus
        
        public init(
            id: String = UUID().uuidString,
            name: String,
            category: InventoryCategory,
            currentStock: Int,
            minimumStock: Int,
            unit: String,
            cost: Double = 0.0,
            supplier: String? = nil,
            restockStatus: RestockStatus = .inStock
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.currentStock = currentStock
            self.minimumStock = minimumStock
            self.unit = unit
            self.cost = cost
            self.supplier = supplier
            self.restockStatus = restockStatus
        }
    }
    
    public enum InventoryCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case maintenance = "Maintenance"
        case safety = "Safety"
        case tools = "Tools"
        case supplies = "Supplies"
        case equipment = "Equipment"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
    }
    
    // MARK: - Performance & Route Types
    public struct PerformanceMetrics: Codable, Hashable {
        public let workerId: String
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageTime: Double
        public let qualityScore: Double
        public let lastUpdate: Date
        
        public init(
            workerId: String,
            efficiency: Double = 0.0,
            tasksCompleted: Int = 0,
            averageTime: Double = 0.0,
            qualityScore: Double = 0.0,
            lastUpdate: Date = Date()
        ) {
            self.workerId = workerId
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageTime = averageTime
            self.qualityScore = qualityScore
            self.lastUpdate = lastUpdate
        }
    }
    
    public struct WorkerDailyRoute: Identifiable, Codable, Hashable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let buildings: [String]
        public let estimatedDuration: TimeInterval
        public let status: RouteStatus
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            date: Date = Date(),
            buildings: [String] = [],
            estimatedDuration: TimeInterval = 0,
            status: RouteStatus = .planned
        ) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.buildings = buildings
            self.estimatedDuration = estimatedDuration
            self.status = status
        }
    }
    
    public struct RouteOptimization: Codable, Hashable {
        public let originalRoute: [String]
        public let optimizedRoute: [String]
        public let timeSaved: TimeInterval
        public let distanceSaved: Double
        
        public init(
            originalRoute: [String] = [],
            optimizedRoute: [String] = [],
            timeSaved: TimeInterval = 0,
            distanceSaved: Double = 0
        ) {
            self.originalRoute = originalRoute
            self.optimizedRoute = optimizedRoute
            self.timeSaved = timeSaved
            self.distanceSaved = distanceSaved
        }
    }
    
    public enum RouteStatus: String, Codable, CaseIterable {
        case planned = "Planned"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
    
    // MARK: - Streak Data
    public struct StreakData: Codable, Hashable {
        public let workerId: String
        public let currentStreak: Int
        public let longestStreak: Int
        public let streakType: StreakType
        public let lastActivityDate: Date
        public let nextMilestone: Int
        public let streakStartDate: Date
        
        public enum StreakType: String, Codable {
            case taskCompletion = "task_completion"
            case punctuality = "punctuality"
            case qualityRating = "quality_rating"
            case consistency = "consistency"
        }
        
        public init(
            workerId: String,
            currentStreak: Int = 0,
            longestStreak: Int = 0,
            streakType: StreakType = .taskCompletion,
            lastActivityDate: Date = Date(),
            nextMilestone: Int = 5,
            streakStartDate: Date = Date()
        ) {
            self.workerId = workerId
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.streakType = streakType
            self.lastActivityDate = lastActivityDate
            self.nextMilestone = nextMilestone
            self.streakStartDate = streakStartDate
        }
    }
    
    // MARK: - Intelligence Insight Types
    public enum InsightPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var priorityValue: Int {
            switch self {
            case .critical: return 4
            case .high: return 3
            case .medium: return 2
            case .low: return 1
            }
        }
    }
    
    public enum InsightType: String, Codable, CaseIterable {
        case performance = "Performance"
        case maintenance = "Maintenance"
        case compliance = "Compliance"
        case efficiency = "Efficiency"
        case safety = "Safety"
        case cost = "Cost"
    }
    
    public struct IntelligenceInsight: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightType
        public let priority: InsightPriority
        public let actionRequired: Bool
        public let affectedBuildings: [String]
        public let createdDate: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightType,
            priority: InsightPriority = .medium,
            actionRequired: Bool = false,
            affectedBuildings: [String] = [],
            createdDate: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionRequired = actionRequired
            self.affectedBuildings = affectedBuildings
            self.createdDate = createdDate
        }
    }
}

// MARK: - Additional Types (Outside CoreTypes for compatibility)

public struct BuildingStatistics: Codable, Hashable {
    public let buildingId: String
    public let completionRate: Double
    public let taskCount: Int
    public let workerCount: Int
    public let efficiencyTrend: CoreTypes.TrendDirection
    public let lastUpdate: Date
    
    public init(
        buildingId: String,
        completionRate: Double = 0.0,
        taskCount: Int = 0,
        workerCount: Int = 0,
        efficiencyTrend: CoreTypes.TrendDirection = .stable,
        lastUpdate: Date = Date()
    ) {
        self.buildingId = buildingId
        self.completionRate = completionRate
        self.taskCount = taskCount
        self.workerCount = workerCount
        self.efficiencyTrend = efficiencyTrend
        self.lastUpdate = lastUpdate
    }
}

public struct FrancoWorkerAssignment: Identifiable, Codable, Hashable {
    public let id: String
    public let workerId: String
    public let buildingId: String
    public let role: String
    public let startDate: Date
    public let endDate: Date?
    public let isActive: Bool
    
    public init(
        id: String = UUID().uuidString,
        workerId: String,
        buildingId: String,
        role: String = "worker",
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.workerId = workerId
        self.buildingId = buildingId
        self.role = role
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
}

public enum BuildingTab: String, CaseIterable {
    case overview = "Overview"
    case tasks = "Tasks"
    case workers = "Workers"
    case intelligence = "Intelligence"
}

public enum ComplianceTab: String, CaseIterable {
    case overview = "Overview"
    case issues = "Issues"
    case reports = "Reports"
    case history = "History"
}

// MARK: - Type Aliases for Backward Compatibility
public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias TaskRecurrence = CoreTypes.TaskRecurrence
public typealias BuildingMetrics = CoreTypes.BuildingMetrics
public typealias TrendDirection = CoreTypes.TrendDirection
public typealias ComplianceStatus = CoreTypes.ComplianceStatus
public typealias VerificationStatus = CoreTypes.VerificationStatus
public typealias InventoryItem = CoreTypes.InventoryItem
public typealias InventoryCategory = CoreTypes.InventoryCategory
public typealias RestockStatus = CoreTypes.RestockStatus
public typealias PerformanceMetrics = CoreTypes.PerformanceMetrics
