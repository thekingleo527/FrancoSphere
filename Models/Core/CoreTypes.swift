//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All structural issues and duplicate declarations resolved
//  ✅ DASHBOARD SUPPORT: Types for Worker/Admin/Client dashboard refactor
//  ✅ PROPERTYCARD READY: Supports multi-mode display with BuildingMetrics
//  ✅ GRDB COMPATIBLE: Works with actor-based services and real data
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - Core Types Namespace
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
    
    // MARK: - Worker Types (Dashboard Support)
    public enum WorkerStatus: String, Codable, CaseIterable {
        case available = "Available"
        case clockedIn = "Clocked In"
        case onBreak = "On Break"
        case offline = "Offline"
    }
    
    public enum WorkerSkill: String, Codable, CaseIterable {
        case plumbing = "Plumbing"
        case electrical = "Electrical"
        case hvac = "HVAC"
        case carpentry = "Carpentry"
        case painting = "Painting"
        case cleaning = "Cleaning"
        case landscaping = "Landscaping"
        case security = "Security"
        case museumSpecialist = "Museum Specialist"
        case parkMaintenance = "Park Maintenance"
    }
    
    public struct PerformanceMetrics: Codable {
        public let completionRate: Double
        public let avgTaskTime: Double
        public let qualityScore: Double
        
        public init(completionRate: Double, avgTaskTime: Double, qualityScore: Double) {
            self.completionRate = completionRate
            self.avgTaskTime = avgTaskTime
            self.qualityScore = qualityScore
        }
    }
    
    public struct WorkerPerformanceMetrics: Codable {
        public let workerId: String
        public let metrics: PerformanceMetrics
        
        public init(workerId: String, metrics: PerformanceMetrics) {
            self.workerId = workerId
            self.metrics = metrics
        }
    }
    
    public struct StreakData: Codable {
        public let currentStreak: Int
        public let longestStreak: Int
        
        public init(currentStreak: Int, longestStreak: Int) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
        }
    }
    
    // MARK: - Task Types (Multi-Dashboard)
    public struct MaintenanceTask: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String?
        public let buildingId: String
        public let workerId: String?
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let isCompleted: Bool
        public let scheduledDate: Date?
        public let completedDate: Date?
        
        public init(id: String = UUID().uuidString, title: String, description: String? = nil, buildingId: String, workerId: String? = nil, category: TaskCategory = .maintenance, urgency: TaskUrgency = .medium, isCompleted: Bool = false, scheduledDate: Date? = nil, completedDate: Date? = nil) {
            self.id = id
            self.title = title
            self.description = description
            self.buildingId = buildingId
            self.workerId = workerId
            self.category = category
            self.urgency = urgency
            self.isCompleted = isCompleted
            self.scheduledDate = scheduledDate
            self.completedDate = completedDate
        }
    }
    
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
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public struct TaskProgress: Codable {
        public let completedTasks: Int
        public let totalTasks: Int
        public let progressPercentage: Double
        
        public init(completedTasks: Int, totalTasks: Int, progressPercentage: Double) {
            self.completedTasks = completedTasks
            self.totalTasks = totalTasks
            self.progressPercentage = progressPercentage
        }
    }
    
    public struct TaskCompletionRecord: Codable {
        public let taskId: String
        public let completedDate: Date
        public let workerId: String
        
        public init(taskId: String, completedDate: Date, workerId: String) {
            self.taskId = taskId
            self.completedDate = completedDate
            self.workerId = workerId
        }
    }
    
    // MARK: - Building Types (PropertyCard Support)
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case museum = "Museum"
        case cultural = "Cultural"
        case mixedUse = "Mixed Use"
        case retail = "Retail"
        case park = "Park"
    }
    
    public enum BuildingTab: String, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case workers = "Workers"
        case maintenance = "Maintenance"
        case compliance = "Compliance"
    }
    
    public struct BuildingInsight: Codable {
        public let title: String
        public let description: String
        public let priority: String
        
        public init(title: String, description: String, priority: String) {
            self.title = title
            self.description = description
            self.priority = priority
        }
    }
    
    // MARK: - Building Metrics (PropertyCard Integration)
    public struct BuildingMetrics: Codable {
        public let buildingId: String
        public let completionRate: Double
        public let pendingTasks: Int
        public let overdueTasks: Int
        public let activeWorkers: Int
        public let urgentTasksCount: Int
        public let overallScore: Int
        public let isCompliant: Bool
        public let hasWorkerOnSite: Bool
        public let maintenanceEfficiency: Double
        public let weeklyCompletionTrend: Double
        public let lastActivityDate: Date?
        
        public init(buildingId: String, completionRate: Double, pendingTasks: Int, overdueTasks: Int, activeWorkers: Int, urgentTasksCount: Int, overallScore: Int, isCompliant: Bool, hasWorkerOnSite: Bool, maintenanceEfficiency: Double, weeklyCompletionTrend: Double, lastActivityDate: Date? = nil) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.pendingTasks = pendingTasks
            self.overdueTasks = overdueTasks
            self.activeWorkers = activeWorkers
            self.urgentTasksCount = urgentTasksCount
            self.overallScore = overallScore
            self.isCompliant = isCompliant
            self.hasWorkerOnSite = hasWorkerOnSite
            self.maintenanceEfficiency = maintenanceEfficiency
            self.weeklyCompletionTrend = weeklyCompletionTrend
            self.lastActivityDate = lastActivityDate
        }
        
        // Dashboard display helpers
        public var displayStatus: String {
            if overdueTasks > 0 { return "⚠️ Overdue" }
            if urgentTasksCount > 0 { return "🔥 Urgent" }
            if completionRate >= 0.9 { return "✅ Excellent" }
            if completionRate >= 0.7 { return "👍 Good" }
            return "📋 In Progress"
        }
        
        public var statusColor: String {
            if overdueTasks > 0 { return "red" }
            if urgentTasksCount > 0 { return "orange" }
            if completionRate >= 0.8 { return "green" }
            return "blue"
        }
    }
    
    // MARK: - Intelligence & Analytics Types
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "up"
        case down = "down"
        case stable = "stable"
        
        public var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .blue
            }
        }
        
        public var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
    }
    
    public struct BuildingAnalytics: Codable {
        public let buildingId: String
        public let completionRate: Double
        public let avgResponseTime: Double
        public let issueCount: Int
        public let trend: TrendDirection
        
        public init(buildingId: String, completionRate: Double, avgResponseTime: Double, issueCount: Int, trend: TrendDirection) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.avgResponseTime = avgResponseTime
            self.issueCount = issueCount
            self.trend = trend
        }
    }
    
    // MARK: - Portfolio Intelligence (Admin/Client Dashboards)
    public struct PortfolioIntelligence: Codable {
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completionRate: Double
        public let criticalIssues: Int
        public let monthlyTrend: TrendDirection
        
        public init(totalBuildings: Int, activeWorkers: Int, completionRate: Double, criticalIssues: Int, monthlyTrend: TrendDirection) {
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.completionRate = completionRate
            self.criticalIssues = criticalIssues
            self.monthlyTrend = monthlyTrend
        }
    }
    
    public enum InsightType: String, Codable, CaseIterable {
        case performance = "Performance"
        case maintenance = "Maintenance"
        case efficiency = "Efficiency"
        case compliance = "Compliance"
        case cost = "Cost"
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
    
    public struct IntelligenceInsight: Codable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightType
        public let priority: InsightPriority
        public let actionRequired: Bool
        public let affectedBuildings: [String]
        
        public init(id: String = UUID().uuidString, title: String, description: String, type: InsightType, priority: InsightPriority, actionRequired: Bool, affectedBuildings: [String]) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionRequired = actionRequired
            self.affectedBuildings = affectedBuildings
        }
    }
    
    // MARK: - Compliance Types (Client Dashboard)
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case compliant = "Compliant"
        case needsReview = "Needs Review"
        case atRisk = "At Risk"
        case nonCompliant = "Non-Compliant"
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case environmental = "Environmental"
        case regulatory = "Regulatory"
        case maintenance = "Maintenance"
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public struct ComplianceIssue: Codable, Hashable {
        public let id: String
        public let type: ComplianceIssueType
        public let severity: ComplianceSeverity
        public let description: String
        public let buildingId: String
        
        public init(id: String = UUID().uuidString, type: ComplianceIssueType, severity: ComplianceSeverity, description: String, buildingId: String) {
            self.id = id
            self.type = type
            self.severity = severity
            self.description = description
            self.buildingId = buildingId
        }
    }
    
    // MARK: - Verification & Status Types
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case failed = "Failed"
        case inProgress = "In Progress"
    }
    
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
        case unknown = "Unknown"
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case extreme = "Extreme"
    }
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case tools = "Tools"
        case supplies = "Supplies"
        case equipment = "Equipment"
        case materials = "Materials"
        case safety = "Safety"
        case other = "Other"
    }
    
    public struct InventoryItem: Codable, Identifiable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let quantity: Int
        public let minThreshold: Int
        public let location: String
        
        public init(id: String = UUID().uuidString, name: String, category: InventoryCategory, quantity: Int, minThreshold: Int, location: String) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.minThreshold = minThreshold
            self.location = location
        }
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
    }
    
    // MARK: - Assignment Types
    public struct WorkerAssignment: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let role: String
        public let startDate: Date
        public let isActive: Bool
        
        public init(id: String = UUID().uuidString, workerId: String, buildingId: String, role: String, startDate: Date, isActive: Bool = true) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.role = role
            self.startDate = startDate
            self.isActive = isActive
        }
    }
    
    public struct FrancoWorkerAssignment: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let workerId: Int64
        public let workerName: String
        public let shift: String
        public let specialRole: String?
        
        public init(id: String = UUID().uuidString, buildingId: String, workerId: Int64, workerName: String, shift: String, specialRole: String? = nil) {
            self.id = id
            self.buildingId = buildingId
            self.workerId = workerId
            self.workerName = workerName
            self.shift = shift
            self.specialRole = specialRole
        }
    }
    
    public struct OperationalTaskAssignment: Codable {
        public let workerId: String?
        public let buildingId: String?
        public let taskName: String
        public let category: String
        public let skillLevel: String
        public let startHour: Int?
        public let endHour: Int?
        
        public init(workerId: String? = nil, buildingId: String? = nil, taskName: String, category: String, skillLevel: String = "Basic", startHour: Int? = nil, endHour: Int? = nil) {
            self.workerId = workerId
            self.buildingId = buildingId
            self.taskName = taskName
            self.category = category
            self.skillLevel = skillLevel
            self.startHour = startHour
            self.endHour = endHour
        }
    }
    
    // MARK: - Route & Schedule Types
    public struct WorkerDailyRoute: Codable {
        public let workerId: String
        public let date: Date
        public let buildings: [String]
        public let estimatedDuration: TimeInterval
        
        public init(workerId: String, date: Date, buildings: [String], estimatedDuration: TimeInterval) {
            self.workerId = workerId
            self.date = date
            self.buildings = buildings
            self.estimatedDuration = estimatedDuration
        }
    }
    
    public struct RouteOptimization: Codable {
        public let optimizedRoute: [String]
        public let timeSaved: TimeInterval
        public let efficiency: Double
        
        public init(optimizedRoute: [String], timeSaved: TimeInterval, efficiency: Double) {
            self.optimizedRoute = optimizedRoute
            self.timeSaved = timeSaved
            self.efficiency = efficiency
        }
    }
    
    public struct ScheduleConflict: Codable {
        public let workerId: String
        public let conflictingTasks: [String]
        public let suggestedResolution: String
        
        public init(workerId: String, conflictingTasks: [String], suggestedResolution: String) {
            self.workerId = workerId
            self.conflictingTasks = conflictingTasks
            self.suggestedResolution = suggestedResolution
        }
    }
    
    // MARK: - Maintenance History Types
    public struct MaintenanceRecord: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let taskId: String
        public let workerId: String
        public let completedDate: Date
        public let description: String
        public let cost: Double?
        
        public init(id: String = UUID().uuidString, buildingId: String, taskId: String, workerId: String, completedDate: Date, description: String, cost: Double? = nil) {
            self.id = id
            self.buildingId = buildingId
            self.taskId = taskId
            self.workerId = workerId
            self.completedDate = completedDate
            self.description = description
            self.cost = cost
        }
    }
    
    // MARK: - Worker Summary Types
    public struct WorkerRoutineSummary: Codable {
        public let workerId: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let efficiency: Double
        
        public init(workerId: String, totalTasks: Int, completedTasks: Int, efficiency: Double) {
            self.workerId = workerId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.efficiency = efficiency
        }
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case clear = "Clear"
        case partlyCloudy = "Partly Cloudy"
        case overcast = "Overcast"
    }
    
    // MARK: - Task Recurrence
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Biweekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case annually = "Annually"
    }
    
    // MARK: - Building Statistics
    public struct BuildingStatistics: Codable {
        public let buildingId: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let pendingTasks: Int
        public let overdueTasks: Int
        public let completionRate: Double
        public let avgCompletionTime: Double
        
        public init(buildingId: String, totalTasks: Int, completedTasks: Int, pendingTasks: Int, overdueTasks: Int, completionRate: Double, avgCompletionTime: Double) {
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.pendingTasks = pendingTasks
            self.overdueTasks = overdueTasks
            self.completionRate = completionRate
            self.avgCompletionTime = avgCompletionTime
        }
    }
    
    // MARK: - Task Trends
    public struct TaskTrends: Codable {
        public let weeklyCompletion: Double
        public let monthlyCompletion: Double
        public let trend: TrendDirection
        public let categoryBreakdown: [String: Int]
        
        public init(weeklyCompletion: Double, monthlyCompletion: Double, trend: TrendDirection, categoryBreakdown: [String: Int]) {
            self.weeklyCompletion = weeklyCompletion
            self.monthlyCompletion = monthlyCompletion
            self.trend = trend
            self.categoryBreakdown = categoryBreakdown
        }
    }
    
    // MARK: - AI Types (Generic)
    public struct AIScenarioData<T: Codable>: Codable {
        public let data: T
        public let timestamp: Date
        
        public init(data: T, timestamp: Date = Date()) {
            self.data = data
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Filter Types (Dashboard Support)
    public struct InsightFilter: Codable, Hashable {
        public let type: InsightType?
        public let priority: InsightPriority?
        public let buildingId: String?
        
        public init(type: InsightType? = nil, priority: InsightPriority? = nil, buildingId: String? = nil) {
            self.type = type
            self.priority = priority
            self.buildingId = buildingId
        }
    }
}

// MARK: - Global Type Aliases (For Compatibility)
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID

public typealias WorkerStatus = CoreTypes.WorkerStatus
public typealias WorkerSkill = CoreTypes.WorkerSkill
public typealias PerformanceMetrics = CoreTypes.PerformanceMetrics
public typealias WorkerPerformanceMetrics = CoreTypes.WorkerPerformanceMetrics
public typealias StreakData = CoreTypes.StreakData

public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias TaskProgress = CoreTypes.TaskProgress
public typealias TaskCompletionRecord = CoreTypes.TaskCompletionRecord

public typealias BuildingType = CoreTypes.BuildingType
public typealias BuildingTab = CoreTypes.BuildingTab
public typealias BuildingInsight = CoreTypes.BuildingInsight

public typealias TrendDirection = CoreTypes.TrendDirection
public typealias BuildingAnalytics = CoreTypes.BuildingAnalytics
public typealias PortfolioIntelligence = CoreTypes.PortfolioIntelligence
public typealias InsightType = CoreTypes.InsightType
public typealias InsightPriority = CoreTypes.InsightPriority
public typealias IntelligenceInsight = CoreTypes.IntelligenceInsight

public typealias ComplianceStatus = CoreTypes.ComplianceStatus
public typealias ComplianceIssue = CoreTypes.ComplianceIssue

public typealias VerificationStatus = CoreTypes.VerificationStatus
public typealias DataHealthStatus = CoreTypes.DataHealthStatus
public typealias OutdoorWorkRisk = CoreTypes.OutdoorWorkRisk

public typealias InventoryCategory = CoreTypes.InventoryCategory
public typealias InventoryItem = CoreTypes.InventoryItem
public typealias RestockStatus = CoreTypes.RestockStatus

public typealias WorkerAssignment = CoreTypes.WorkerAssignment
public typealias FrancoWorkerAssignment = CoreTypes.FrancoWorkerAssignment
public typealias OperationalTaskAssignment = CoreTypes.OperationalTaskAssignment

public typealias WorkerDailyRoute = CoreTypes.WorkerDailyRoute
public typealias RouteOptimization = CoreTypes.RouteOptimization
public typealias ScheduleConflict = CoreTypes.ScheduleConflict

public typealias MaintenanceRecord = CoreTypes.MaintenanceRecord
public typealias WorkerRoutineSummary = CoreTypes.WorkerRoutineSummary

public typealias WeatherCondition = CoreTypes.WeatherCondition
public typealias TaskRecurrence = CoreTypes.TaskRecurrence
public typealias BuildingStatistics = CoreTypes.BuildingStatistics
public typealias TaskTrends = CoreTypes.TaskTrends
