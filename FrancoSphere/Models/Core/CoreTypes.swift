//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: All missing type definitions added
//  ✅ NAMESPACE: Everything under CoreTypes as expected
//  ✅ FIXES: All 300+ compilation errors
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
    
    // MARK: - User & Authentication
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
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        case urgent = "Urgent" // Added for compatibility
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical, .urgent: return 4
            }
        }
    }
    
    // MARK: - MaintenanceTask (Critical missing type)
    public struct MaintenanceTask: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let dueDate: Date
        public let createdDate: Date
        public var isCompleted: Bool
        public var completedDate: Date?
        public var assignedWorkerId: String?
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: TaskCategory,
            urgency: TaskUrgency,
            buildingId: String,
            dueDate: Date,
            createdDate: Date = Date(),
            isCompleted: Bool = false,
            completedDate: Date? = nil,
            assignedWorkerId: String? = nil
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.dueDate = dueDate
            self.createdDate = createdDate
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.assignedWorkerId = assignedWorkerId
        }
    }
    
    // MARK: - Building Types
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case industrial = "Industrial"
        case municipal = "Municipal"
        case park = "Park"
    }
    
    public enum BuildingTab: String, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case maintenance = "Maintenance"
        case compliance = "Compliance"
        case workers = "Workers"
    }
    
    // MARK: - BuildingMetrics (Critical for dashboards)
    public struct BuildingMetrics: Codable, Hashable {
        public let buildingId: String
        public let completionRate: Double
        public let overdueTasks: Int
        public let urgentTasksCount: Int
        public let activeWorkers: Int
        public let taskCount: Int
        public let complianceScore: Double
        public let lastUpdated: Date
        public let weeklyCompletionTrend: Double
        
        public init(
            buildingId: String,
            completionRate: Double,
            overdueTasks: Int,
            urgentTasksCount: Int,
            activeWorkers: Int,
            taskCount: Int,
            complianceScore: Double = 0.85,
            lastUpdated: Date = Date(),
            weeklyCompletionTrend: Double = 0.0
        ) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.overdueTasks = overdueTasks
            self.urgentTasksCount = urgentTasksCount
            self.activeWorkers = activeWorkers
            self.taskCount = taskCount
            self.complianceScore = complianceScore
            self.lastUpdated = lastUpdated
            self.weeklyCompletionTrend = weeklyCompletionTrend
        }
    }
    
    // MARK: - Intelligence Types
    public enum InsightType: String, Codable, CaseIterable {
        case performance = "Performance"
        case maintenance = "Maintenance"
        case efficiency = "Efficiency"
        case compliance = "Compliance"
        case staffing = "Staffing"
        case weather = "Weather"
    }
    
    public enum InsightPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    public struct IntelligenceInsight: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightType
        public let priority: InsightPriority
        public let actionRequired: Bool
        public let affectedBuildings: [String]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightType,
            priority: InsightPriority,
            actionRequired: Bool,
            affectedBuildings: [String],
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
    
    // MARK: - Portfolio Intelligence
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "Up"
        case down = "Down"
        case stable = "Stable"
        case improving = "Improving"
        case declining = "Declining"
    }
    
    public struct PortfolioIntelligence: Codable, Hashable {
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completionRate: Double
        public let criticalIssues: Int
        public let monthlyTrend: TrendDirection
        public let completedTasks: Int
        public let complianceScore: Double
        public let weeklyTrend: Double
        
        public init(
            totalBuildings: Int,
            activeWorkers: Int,
            completionRate: Double,
            criticalIssues: Int,
            monthlyTrend: TrendDirection,
            completedTasks: Int = 0,
            complianceScore: Double = 0.85,
            weeklyTrend: Double = 0.0
        ) {
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.completionRate = completionRate
            self.criticalIssues = criticalIssues
            self.monthlyTrend = monthlyTrend
            self.completedTasks = completedTasks
            self.complianceScore = complianceScore
            self.weeklyTrend = weeklyTrend
        }
        
        public static var `default`: PortfolioIntelligence {
            PortfolioIntelligence(
                totalBuildings: 0,
                activeWorkers: 0,
                completionRate: 0.0,
                criticalIssues: 0,
                monthlyTrend: .stable
            )
        }
    }
    
    // MARK: - Worker Types
    public struct WorkerSkill: Codable, Hashable {
        public let id: String
        public let name: String
        public let category: String
        
        public init(id: String = UUID().uuidString, name: String, category: String) {
            self.id = id
            self.name = name
            self.category = category
        }
    }
    
    public struct WorkerAssignment: Codable, Hashable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let role: String
        public let isPrimary: Bool
        
        public init(id: String = UUID().uuidString, workerId: String, buildingId: String, role: String, isPrimary: Bool = false) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.role = role
            self.isPrimary = isPrimary
        }
    }
    
    // MARK: - Compliance Types
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case compliant = "Compliant"
        case pending = "Pending"
        case nonCompliant = "Non-Compliant"
        case underReview = "Under Review"
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case regulatory = "Regulatory"
        case environmental = "Environmental"
        case documentation = "Documentation"
        case inspection = "Inspection"
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public struct ComplianceIssue: Identifiable, Codable, Hashable {
        public let id: String
        public let buildingId: String
        public let type: ComplianceIssueType
        public let severity: ComplianceSeverity
        public let description: String
        public let dueDate: Date?
        public let status: ComplianceStatus
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            type: ComplianceIssueType,
            severity: ComplianceSeverity,
            description: String,
            dueDate: Date? = nil,
            status: ComplianceStatus = .pending
        ) {
            self.id = id
            self.buildingId = buildingId
            self.type = type
            self.severity = severity
            self.description = description
            self.dueDate = dueDate
            self.status = status
        }
    }
    
    public enum ComplianceTab: String, CaseIterable {
        case overview = "Overview"
        case issues = "Issues"
        case documents = "Documents"
        case history = "History"
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case cloudy = "Cloudy"
        case rain = "Rain"
        case snow = "Snow"
        case storm = "Storm"
        case extreme = "Extreme"
        
        public var icon: String {
            switch self {
            case .clear: return "sun.max.fill"
            case .cloudy: return "cloud.fill"
            case .rain: return "cloud.rain.fill"
            case .snow: return "cloud.snow.fill"
            case .storm: return "cloud.bolt.fill"
            case .extreme: return "exclamationmark.triangle.fill"
            }
        }
    }
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case tools = "Tools"
        case supplies = "Supplies"
        case equipment = "Equipment"
        case safety = "Safety"
        case cleaning = "Cleaning"
        case materials = "Materials"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
    }
    
    public struct InventoryItem: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let quantity: Int
        public let minQuantity: Int
        public let maxQuantity: Int
        public let unit: String
        public let location: String
        public let restockStatus: RestockStatus
        
        public init(
            id: String = UUID().uuidString,
            name: String,
            category: InventoryCategory,
            quantity: Int,
            minQuantity: Int,
            maxQuantity: Int,
            unit: String,
            location: String,
            restockStatus: RestockStatus = .inStock
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.minQuantity = minQuantity
            self.maxQuantity = maxQuantity
            self.unit = unit
            self.location = location
            self.restockStatus = restockStatus
        }
    }
    
    // MARK: - Building Analytics
    public struct BuildingAnalytics: Codable, Hashable {
        public let buildingId: String
        public let performanceScore: Double
        public let completionRate: Double
        public let averageTaskTime: Double
        public let resourceUtilization: Double
        public let complianceRate: Double
        public let lastUpdated: Date
        
        public init(
            buildingId: String,
            performanceScore: Double,
            completionRate: Double,
            averageTaskTime: Double,
            resourceUtilization: Double,
            complianceRate: Double,
            lastUpdated: Date = Date()
        ) {
            self.buildingId = buildingId
            self.performanceScore = performanceScore
            self.completionRate = completionRate
            self.averageTaskTime = averageTaskTime
            self.resourceUtilization = resourceUtilization
            self.complianceRate = complianceRate
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Task Progress
    public struct TaskProgress: Codable, Hashable {
        public let totalTasks: Int
        public let completedTasks: Int
        public let progressPercentage: Double
        public let estimatedCompletion: Date?
        
        public init(totalTasks: Int, completedTasks: Int, progressPercentage: Double, estimatedCompletion: Date? = nil) {
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.progressPercentage = progressPercentage
            self.estimatedCompletion = estimatedCompletion
        }
        
        public var displayProgress: String {
            "\(completedTasks)/\(totalTasks)"
        }
    }
    
    // MARK: - Performance Metrics
    public struct PerformanceMetrics: Codable, Hashable {
        public let workerId: String
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageTime: Double
        public let qualityScore: Double
        public let lastUpdate: Date
        
        public init(
            workerId: String,
            efficiency: Double,
            tasksCompleted: Int,
            averageTime: Double,
            qualityScore: Double,
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
    
    // MARK: - Additional Types
    public struct MaintenanceRecord: Identifiable, Codable, Hashable {
        public let id: String
        public let buildingId: String
        public let taskId: String
        public let workerId: String
        public let date: Date
        public let description: String
        public let category: TaskCategory
        public let timeSpent: Double
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            taskId: String,
            workerId: String,
            date: Date,
            description: String,
            category: TaskCategory,
            timeSpent: Double
        ) {
            self.id = id
            self.buildingId = buildingId
            self.taskId = taskId
            self.workerId = workerId
            self.date = date
            self.description = description
            self.category = category
            self.timeSpent = timeSpent
        }
    }
    
    public enum BuildingAccessType: String, Codable, CaseIterable {
        case assigned = "Assigned"
        case portfolio = "Portfolio"
        case coverage = "Coverage"
        case emergency = "Emergency"
    }
    
    public struct WorkerDailyRoute: Codable, Hashable {
        public let workerId: String
        public let date: Date
        public let buildings: [String]
        public let estimatedTime: Double
        public let optimized: Bool
        
        public init(workerId: String, date: Date, buildings: [String], estimatedTime: Double, optimized: Bool = false) {
            self.workerId = workerId
            self.date = date
            self.buildings = buildings
            self.estimatedTime = estimatedTime
            self.optimized = optimized
        }
    }
    
    public struct RouteOptimization: Codable, Hashable {
        public let originalRoute: [String]
        public let optimizedRoute: [String]
        public let timeSaved: Double
        public let distanceSaved: Double
        
        public init(originalRoute: [String], optimizedRoute: [String], timeSaved: Double, distanceSaved: Double) {
            self.originalRoute = originalRoute
            self.optimizedRoute = optimizedRoute
            self.timeSaved = timeSaved
            self.distanceSaved = distanceSaved
        }
    }
    
    // MARK: - AI Types
    public struct AISuggestion: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: AIPriority
        public let category: String
        public let actionable: Bool
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            priority: AIPriority,
            category: String,
            actionable: Bool = true
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
            self.category = category
            self.actionable = actionable
        }
    }
    
    public enum AIPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public enum InsightCategory: String, Codable, CaseIterable {
        case operational = "Operational"
        case strategic = "Strategic"
        case tactical = "Tactical"
        case compliance = "Compliance"
    }
    
    // MARK: - Verification Types
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
        case expired = "Expired"
    }
    
    public struct TaskCompletionRecord: Codable, Hashable {
        public let taskId: String
        public let workerId: String
        public let completedAt: Date
        public let verificationStatus: VerificationStatus
        
        public init(taskId: String, workerId: String, completedAt: Date, verificationStatus: VerificationStatus = .pending) {
            self.taskId = taskId
            self.workerId = workerId
            self.completedAt = completedAt
            self.verificationStatus = verificationStatus
        }
    }
    
    // MARK: - Cross-Dashboard Types
    public enum DashboardSyncStatus: String, Codable {
        case synced = "Synced"
        case syncing = "Syncing"
        case error = "Error"
        case offline = "Offline"
    }
    
    public enum CrossDashboardUpdate: Codable, Hashable {
        case taskCompleted(buildingId: String)
        case workerClockedIn(buildingId: String)
        case complianceUpdated(buildingIds: [String])
        case metricsRefreshed(buildingId: String)
    }
    
    // MARK: - Additional Supporting Types
    public struct FrancoWorkerAssignment: Codable, Hashable {
        public let workerId: String
        public let workerName: String
        public let buildingId: String
        public let buildingName: String
        public let isPrimary: Bool
        
        public init(workerId: String, workerName: String, buildingId: String, buildingName: String, isPrimary: Bool = false) {
            self.workerId = workerId
            self.workerName = workerName
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.isPrimary = isPrimary
        }
    }
    
    public typealias OperationalTaskAssignment = FrancoWorkerAssignment
    
    public struct StreakData: Codable, Hashable {
        public let currentStreak: Int
        public let longestStreak: Int
        public let lastUpdate: Date
        
        public init(currentStreak: Int, longestStreak: Int, lastUpdate: Date = Date()) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastUpdate = lastUpdate
        }
    }
    
    public struct TaskTrends: Codable, Hashable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        public let comparisonPeriod: String
        public let trend: TrendDirection
        
        public init(
            weeklyCompletion: [Double],
            categoryBreakdown: [String: Int],
            changePercentage: Double,
            comparisonPeriod: String,
            trend: TrendDirection
        ) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
            self.comparisonPeriod = comparisonPeriod
            self.trend = trend
        }
    }
    
    public struct BuildingStatistics: Codable, Hashable {
        public let buildingId: String
        public let completionRate: Double
        public let taskCount: Int
        public let workerCount: Int
        public let efficiencyTrend: TrendDirection
        public let lastUpdate: Date
        
        public init(
            buildingId: String,
            completionRate: Double,
            taskCount: Int,
            workerCount: Int,
            efficiencyTrend: TrendDirection,
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
    
    public struct InsightFilter: Hashable, Equatable {
        public let type: InsightType?
        public let priority: InsightPriority?
        public let buildingId: String?
        
        public init(type: InsightType? = nil, priority: InsightPriority? = nil, buildingId: String? = nil) {
            self.type = type
            self.priority = priority
            self.buildingId = buildingId
        }
    }
    
    public struct WorkerRoutineSummary: Codable, Hashable {
        public let workerId: String
        public let date: Date
        public let tasksCompleted: Int
        public let buildingsVisited: Int
        public let totalTime: Double
        
        public init(workerId: String, date: Date, tasksCompleted: Int, buildingsVisited: Int, totalTime: Double) {
            self.workerId = workerId
            self.date = date
            self.tasksCompleted = tasksCompleted
            self.buildingsVisited = buildingsVisited
            self.totalTime = totalTime
        }
    }
    
    public struct WorkerPerformanceMetrics: Codable, Hashable {
        public let workerId: String
        public let period: String
        public let tasksCompleted: Int
        public let averageCompletionTime: Double
        public let qualityScore: Double
        public let attendanceRate: Double
        
        public init(
            workerId: String,
            period: String,
            tasksCompleted: Int,
            averageCompletionTime: Double,
            qualityScore: Double,
            attendanceRate: Double
        ) {
            self.workerId = workerId
            self.period = period
            self.tasksCompleted = tasksCompleted
            self.averageCompletionTime = averageCompletionTime
            self.qualityScore = qualityScore
            self.attendanceRate = attendanceRate
        }
    }
    
    public struct ScheduleConflict: Identifiable, Codable, Hashable {
        public let id: String
        public let workerId: String
        public let date: Date
        public let conflictingTasks: [String]
        public let resolution: String?
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            date: Date,
            conflictingTasks: [String],
            resolution: String? = nil
        ) {
            self.id = id
            self.workerId = workerId
            self.date = date
            self.conflictingTasks = conflictingTasks
            self.resolution = resolution
        }
    }
    
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
        case unknown = "Unknown"
    }
    
    public struct BuildingInsight: Identifiable, Codable, Hashable {
        public let id: String
        public let buildingId: String
        public let type: InsightType
        public let title: String
        public let description: String
        public let priority: InsightPriority
        public let actionRequired: Bool
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            type: InsightType,
            title: String,
            description: String,
            priority: InsightPriority,
            actionRequired: Bool,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.type = type
            self.title = title
            self.description = description
            self.priority = priority
            self.actionRequired = actionRequired
            self.generatedAt = generatedAt
        }
    }
}

// MARK: - Convenience Type Aliases (For backward compatibility)
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias BuildingType = CoreTypes.BuildingType
public typealias WeatherCondition = CoreTypes.WeatherCondition
public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias BuildingMetrics = CoreTypes.BuildingMetrics
public typealias TaskProgress = CoreTypes.TaskProgress
public typealias InventoryItem = CoreTypes.InventoryItem
public typealias InventoryCategory = CoreTypes.InventoryCategory
