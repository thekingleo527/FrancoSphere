//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: PortfolioIntelligence property mismatches
//  ✅ ALIGNED: With current three-dashboard implementation phase
//  ✅ GRDB COMPATIBLE: Works with actor-based services
//  ✅ COMPREHENSIVE: Defines all types the codebase expects
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - CoreTypes Namespace (Required by many files)
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
    
    // MARK: - Worker Types
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
        case emergency = "Emergency"
        case urgent = "Urgent"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical, .emergency, .urgent: return .red
            }
        }
        
        public var rawValue: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            case .emergency: return "Emergency"
            case .urgent: return "Urgent"
            }
        }
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case none = "None"
        case oneTime = "One Time"
        case daily = "Daily"
        case weekly = "Weekly"
        case biweekly = "Biweekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case annually = "Annually"
    }
    
    public struct MaintenanceTask: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedWorkerId: String?
        public let isCompleted: Bool
        public let dueDate: Date?
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let notes: String?
        public let startTime: Date?
        public let endTime: Date?
        public let isPastDue: Bool
        public let status: VerificationStatus
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: TaskCategory,
            urgency: TaskUrgency,
            buildingId: String,
            assignedWorkerId: String? = nil,
            isCompleted: Bool = false,
            dueDate: Date? = nil,
            estimatedDuration: TimeInterval = 3600,
            recurrence: TaskRecurrence = .none,
            notes: String? = nil,
            startTime: Date? = nil,
            endTime: Date? = nil,
            isPastDue: Bool = false,
            status: VerificationStatus = .pending
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.buildingId = buildingId
            self.assignedWorkerId = assignedWorkerId
            self.isCompleted = isCompleted
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.recurrence = recurrence
            self.notes = notes
            self.startTime = startTime
            self.endTime = endTime
            self.isPastDue = isPastDue
            self.status = status
        }
    }
    
    // MARK: - Building Types
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
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case sunny = "Sunny"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case windy = "Windy"
        case partlyCloudy = "Partly Cloudy"
        case overcast = "Overcast"
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case moderate = "Moderate"
        case medium = "Medium"
        case high = "High"
        case extreme = "Extreme"
    }
    
    // MARK: - Verification Types
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case failed = "Failed"
        case rejected = "Rejected"
        case inProgress = "In Progress"
        case needsReview = "Needs Review"
    }
    
    // MARK: - Analytics Types
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "up"
        case down = "down"
        case stable = "stable"
        case improving = "improving"
        case declining = "declining"
        case unknown = "unknown"
        
        public var color: Color {
            switch self {
            case .up, .improving: return .green
            case .down, .declining: return .red
            case .stable: return .blue
            case .unknown: return .gray
            }
        }
        
        public var icon: String {
            switch self {
            case .up, .improving: return "arrow.up.right"
            case .down, .declining: return "arrow.down.right"
            case .stable: return "arrow.right"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }
    
    public struct BuildingAnalytics: Codable {
        public let buildingId: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let overdueTasks: Int
        public let completionRate: Double
        public let uniqueWorkers: Int
        public let averageCompletionTime: TimeInterval
        public let efficiency: Double
        public let lastUpdated: Date
        
        public init(
            buildingId: String,
            totalTasks: Int,
            completedTasks: Int,
            overdueTasks: Int,
            completionRate: Double,
            uniqueWorkers: Int,
            averageCompletionTime: TimeInterval,
            efficiency: Double,
            lastUpdated: Date = Date()
        ) {
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.overdueTasks = overdueTasks
            self.completionRate = completionRate
            self.uniqueWorkers = uniqueWorkers
            self.averageCompletionTime = averageCompletionTime
            self.efficiency = efficiency
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Portfolio Types (FIXED for Three-Dashboard System)
    public struct PortfolioIntelligence: Codable {
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completionRate: Double
        public let criticalIssues: Int
        public let monthlyTrend: TrendDirection
        public let completedTasks: Int
        public let complianceScore: Int
        public let weeklyTrend: Double
        
        public init(
            totalBuildings: Int,
            activeWorkers: Int,
            completionRate: Double,
            criticalIssues: Int,
            monthlyTrend: TrendDirection,
            completedTasks: Int = 0,
            complianceScore: Int = 85,
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
        
        // MARK: - Dashboard Display Properties
        public var overallEfficiency: Double {
            return completionRate
        }
        
        public var averageComplianceScore: Double {
            return Double(complianceScore) / 100.0
        }
        
        public var trendDirection: TrendDirection {
            return weeklyTrend > 0 ? .up : (weeklyTrend < 0 ? .down : .stable)
        }
        
        public var totalActiveWorkers: Int {
            return activeWorkers
        }
        
        public var totalCompletedTasks: Int {
            return completedTasks
        }
        
        // MARK: - Default Instance
        public static let `default` = PortfolioIntelligence(
            totalBuildings: 0,
            activeWorkers: 0,
            completionRate: 0.0,
            criticalIssues: 0,
            monthlyTrend: .stable,
            completedTasks: 0,
            complianceScore: 0,
            weeklyTrend: 0.0
        )
    }
    
    // MARK: - Intelligence Types
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
    
    public struct IntelligenceInsight: Codable, Identifiable {
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
    
    // MARK: - Compliance Types
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case compliant = "Compliant"
        case needsReview = "Needs Review"
        case atRisk = "At Risk"
        case nonCompliant = "Non-Compliant"
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case maintenanceOverdue = "Maintenance Overdue"
        case safetyViolation = "Safety Violation"
        case documentationMissing = "Documentation Missing"
        case inspectionRequired = "Inspection Required"
        case certificationExpired = "Certification Expired"
        case permitRequired = "Permit Required"
        
        public var icon: String {
            switch self {
            case .maintenanceOverdue: return "wrench.and.screwdriver"
            case .safetyViolation: return "exclamationmark.shield"
            case .documentationMissing: return "doc.badge.exclamationmark"
            case .inspectionRequired: return "magnifyingglass"
            case .certificationExpired: return "doc.badge.clock"
            case .permitRequired: return "doc.badge.plus"
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
    
    public struct ComplianceIssue: Codable, Hashable, Identifiable {
        public let id: String
        public let type: ComplianceIssueType
        public let severity: ComplianceSeverity
        public let description: String
        public let buildingId: String
        public let dueDate: Date?
        public let resolvedDate: Date?
        
        public var isResolved: Bool { resolvedDate != nil }
        
        public init(id: String = UUID().uuidString, type: ComplianceIssueType, severity: ComplianceSeverity, description: String, buildingId: String, dueDate: Date? = nil, resolvedDate: Date? = nil) {
            self.id = id
            self.type = type
            self.severity = severity
            self.description = description
            self.buildingId = buildingId
            self.dueDate = dueDate
            self.resolvedDate = resolvedDate
        }
    }
    
    // MARK: - Task Progress
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
        public let currentStock: Int
        public let minimumStock: Int
        public let unit: String
        public let restockStatus: RestockStatus
        
        public init(id: String = UUID().uuidString, name: String, category: InventoryCategory, quantity: Int, minThreshold: Int, location: String, currentStock: Int? = nil, minimumStock: Int? = nil, unit: String = "unit", restockStatus: RestockStatus = .inStock) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.minThreshold = minThreshold
            self.location = location
            self.currentStock = currentStock ?? quantity
            self.minimumStock = minimumStock ?? minThreshold
            self.unit = unit
            self.restockStatus = restockStatus
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
    
    // MARK: - Route Types
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
    
    // MARK: - Maintenance Types
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
    
    // MARK: - Performance Types
    public struct PerformanceMetrics: Codable {
        public let efficiency: Double
        public let tasksCompleted: Int
        public let averageTime: Double
        public let qualityScore: Double
        public let lastUpdate: Date
        
        public init(efficiency: Double, tasksCompleted: Int, averageTime: Double, qualityScore: Double, lastUpdate: Date = Date()) {
            self.efficiency = efficiency
            self.tasksCompleted = tasksCompleted
            self.averageTime = averageTime
            self.qualityScore = qualityScore
            self.lastUpdate = lastUpdate
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
    
    public struct StreakData: Codable {
        public let currentStreak: Int
        public let longestStreak: Int
        public let lastUpdate: Date
        
        public init(currentStreak: Int, longestStreak: Int, lastUpdate: Date = Date()) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastUpdate = lastUpdate
        }
    }
    
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
    
    // MARK: - Statistics Types
    public struct BuildingStatistics: Codable {
        public let buildingId: String
        public let completionRate: Double
        public let taskCount: Int
        public let workerCount: Int
        public let efficiencyTrend: TrendDirection
        public let lastUpdate: Date
        
        public init(buildingId: String, completionRate: Double, taskCount: Int, workerCount: Int, efficiencyTrend: TrendDirection, lastUpdate: Date = Date()) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.taskCount = taskCount
            self.workerCount = workerCount
            self.efficiencyTrend = efficiencyTrend
            self.lastUpdate = lastUpdate
        }
    }
    
    public struct TaskTrends: Codable {
        public let weeklyCompletion: [Double]
        public let categoryBreakdown: [String: Int]
        public let changePercentage: Double
        public let comparisonPeriod: String
        public let trend: TrendDirection
        
        public init(weeklyCompletion: [Double], categoryBreakdown: [String: Int], changePercentage: Double, comparisonPeriod: String, trend: TrendDirection) {
            self.weeklyCompletion = weeklyCompletion
            self.categoryBreakdown = categoryBreakdown
            self.changePercentage = changePercentage
            self.comparisonPeriod = comparisonPeriod
            self.trend = trend
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
        
        // Empty metrics for fallback/default cases
        public static let empty = BuildingMetrics(
            buildingId: "",
            completionRate: 0.0,
            pendingTasks: 0,
            overdueTasks: 0,
            activeWorkers: 0,
            urgentTasksCount: 0,
            overallScore: 0,
            isCompliant: true,
            hasWorkerOnSite: false,
            maintenanceEfficiency: 0.0,
            weeklyCompletionTrend: 0.0
        )
    }
    
    // MARK: - Filter Types
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
    
    // MARK: - Task Completion
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
    
    // MARK: - Health Status
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
        case unknown = "Unknown"
    }
}

// MARK: - Global Type Aliases (For backward compatibility)
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID

public typealias WorkerStatus = CoreTypes.WorkerStatus
public typealias WorkerSkill = CoreTypes.WorkerSkill
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias TaskRecurrence = CoreTypes.TaskRecurrence
public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias WeatherCondition = CoreTypes.WeatherCondition
public typealias OutdoorWorkRisk = CoreTypes.OutdoorWorkRisk
public typealias VerificationStatus = CoreTypes.VerificationStatus
public typealias TrendDirection = CoreTypes.TrendDirection
public typealias BuildingAnalytics = CoreTypes.BuildingAnalytics
public typealias PortfolioIntelligence = CoreTypes.PortfolioIntelligence
public typealias ComplianceStatus = CoreTypes.ComplianceStatus
public typealias ComplianceIssue = CoreTypes.ComplianceIssue
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
public typealias PerformanceMetrics = CoreTypes.PerformanceMetrics
public typealias WorkerPerformanceMetrics = CoreTypes.WorkerPerformanceMetrics
public typealias StreakData = CoreTypes.StreakData
public typealias WorkerRoutineSummary = CoreTypes.WorkerRoutineSummary
public typealias BuildingStatistics = CoreTypes.BuildingStatistics
public typealias TaskTrends = CoreTypes.TaskTrends
public typealias InsightFilter = CoreTypes.InsightFilter
public typealias TaskProgress = CoreTypes.TaskProgress
public typealias TaskCompletionRecord = CoreTypes.TaskCompletionRecord
public typealias DataHealthStatus = CoreTypes.DataHealthStatus
public typealias BuildingType = CoreTypes.BuildingType
public typealias BuildingTab = CoreTypes.BuildingTab
public typealias BuildingInsight = CoreTypes.BuildingInsight
public typealias BuildingMetrics = CoreTypes.BuildingMetrics
// MARK: - Cross-Dashboard Synchronization Types

extension CoreTypes {
    
    /// Dashboard synchronization status
    public enum DashboardSyncStatus {
        case synced
        case syncing
        case error
        
        public var description: String {
            switch self {
            case .synced: return "Synced"
            case .syncing: return "Syncing..."
            case .error: return "Sync Error"
            }
        }
        
        public var color: SwiftUI.Color {
            switch self {
            case .synced: return .green
            case .syncing: return .blue
            case .error: return .red
            }
        }
    }
    
    /// Cross-dashboard update events
    public enum CrossDashboardUpdate {
        case taskCompleted(buildingId: String)
        case workerClockedIn(buildingId: String)
        case metricsUpdated(buildingIds: [String])
        case insightsUpdated(count: Int)
        case buildingIntelligenceUpdated(buildingId: String)
        case complianceUpdated(buildingIds: [String])
        
        public var description: String {
            switch self {
            case .taskCompleted(let buildingId):
                return "Task completed at building \(buildingId)"
            case .workerClockedIn(let buildingId):
                return "Worker clocked in at building \(buildingId)"
            case .metricsUpdated(let buildingIds):
                return "Metrics updated for \(buildingIds.count) buildings"
            case .insightsUpdated(let count):
                return "\(count) portfolio insights updated"
            case .buildingIntelligenceUpdated(let buildingId):
                return "Intelligence updated for building \(buildingId)"
            case .complianceUpdated(let buildingIds):
                return "Compliance updated for \(buildingIds.count) buildings"
            }
        }
    }
}
