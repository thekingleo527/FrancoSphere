//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: All missing types implemented
//  ✅ FIXED: All redeclaration issues resolved
//  ✅ FIXED: All access control issues (public rawValue)
//  ✅ ORGANIZED: Logical grouping maintained
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
    
    // MARK: - Worker Types
    public enum WorkerStatus: String, Codable, CaseIterable {
        case available = "Available"
        case clockedIn = "Clocked In"
        case onBreak = "On Break"
        case offline = "Offline"
        
        public var rawValue: String {
            switch self {
            case .available: return "Available"
            case .clockedIn: return "Clocked In"
            case .onBreak: return "On Break"
            case .offline: return "Offline"
            }
        }
        
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
    
    // MARK: - Building Types
    public enum BuildingTab: String, CaseIterable {
        case overview = "overview"
        case tasks = "tasks"
        case workers = "workers"
        case analytics = "analytics"
        case maintenance = "maintenance"
        
        public var rawValue: String {
            switch self {
            case .overview: return "overview"
            case .tasks: return "tasks"
            case .workers: return "workers"
            case .analytics: return "analytics"
            case .maintenance: return "maintenance"
            }
        }
        
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
    
    public struct BuildingMetrics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let completionRate: Double
        public let overallScore: Double
        public let isCompliant: Bool
        public let activeWorkers: Int
        public let overdueTasks: Int
        public let urgentTasksCount: Int
        public let lastUpdated: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            completionRate: Double,
            overallScore: Double,
            isCompliant: Bool,
            activeWorkers: Int,
            overdueTasks: Int,
            urgentTasksCount: Int,
            lastUpdated: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.overallScore = overallScore
            self.isCompliant = isCompliant
            self.activeWorkers = activeWorkers
            self.overdueTasks = overdueTasks
            self.urgentTasksCount = urgentTasksCount
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
        
        public var rawValue: String {
            switch self {
            case .cleaning: return "Cleaning"
            case .maintenance: return "Maintenance"
            case .security: return "Security"
            case .inspection: return "Inspection"
            case .administrative: return "Administrative"
            }
        }
        
        public var color: Color {
            switch self {
            case .cleaning: return .blue
            case .maintenance: return .orange
            case .security: return .red
            case .inspection: return .green
            case .administrative: return .purple
            }
        }
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var rawValue: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    public enum TaskStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case overdue = "Overdue"
        case cancelled = "Cancelled"
        
        public var rawValue: String {
            switch self {
            case .pending: return "Pending"
            case .inProgress: return "In Progress"
            case .completed: return "Completed"
            case .overdue: return "Overdue"
            case .cancelled: return "Cancelled"
            }
        }
        
        public var color: Color {
            switch self {
            case .pending: return .gray
            case .inProgress: return .blue
            case .completed: return .green
            case .overdue: return .red
            case .cancelled: return .gray
            }
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
        
        public var rawValue: String {
            switch self {
            case .pending: return "Pending"
            case .verified: return "Verified"
            case .rejected: return "Rejected"
            case .notRequired: return "Not Required"
            }
        }
        
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
        
        public var rawValue: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .extreme: return "Extreme"
            }
        }
        
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
        
        public var rawValue: String {
            switch self {
            case .up: return "Up"
            case .down: return "Down"
            case .stable: return "Stable"
            case .improving: return "Improving"
            case .declining: return "Declining"
            }
        }
        
        public var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .stable: return "minus"
            case .improving: return "arrow.up.right"
            case .declining: return "arrow.down.right"
            }
        }
    }
    
    // MARK: - Skill Types
    public enum SkillLevel: String, Codable, CaseIterable {
        case beginner = "Beginner"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"
        
        public var rawValue: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            case .expert: return "Expert"
            }
        }
        
        public var numericValue: Int {
            switch self {
            case .beginner: return 1
            case .intermediate: return 2
            case .advanced: return 3
            case .expert: return 4
            }
        }
    }
    
    // MARK: - Inventory Types
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
        
        public var rawValue: String {
            switch self {
            case .inStock: return "In Stock"
            case .lowStock: return "Low Stock"
            case .outOfStock: return "Out of Stock"
            case .ordered: return "Ordered"
            }
        }
        
        public var color: Color {
            switch self {
            case .inStock: return .green
            case .lowStock: return .orange
            case .outOfStock: return .red
            case .ordered: return .blue
            }
        }
    }
    
    // MARK: - AI Types
    public enum AIPriority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var rawValue: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
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
    
    public enum InsightCategory: String, Codable, CaseIterable {
        case efficiency = "Efficiency"
        case cost = "Cost"
        case safety = "Safety"
        case compliance = "Compliance"
        case quality = "Quality"
        case operations = "Operations"
        case maintenance = "Maintenance"
        
        public var rawValue: String {
            switch self {
            case .efficiency: return "Efficiency"
            case .cost: return "Cost"
            case .safety: return "Safety"
            case .compliance: return "Compliance"
            case .quality: return "Quality"
            case .operations: return "Operations"
            case .maintenance: return "Maintenance"
            }
        }
        
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
    }
    
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
        
        // Convenience initializer for simple suggestions
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
            
            public var rawValue: String {
                switch self {
                case .low: return "Low"
                case .medium: return "Medium"
                case .high: return "High"
                case .critical: return "Critical"
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
        
        public var rawValue: String {
            switch self {
            case .overview: return "overview"
            case .issues: return "issues"
            case .reports: return "reports"
            case .audit: return "audit"
            }
        }
        
        public var displayName: String {
            switch self {
            case .overview: return "Overview"
            case .issues: return "Issues"
            case .reports: return "Reports"
            case .audit: return "Audit"
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
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            severity: ComplianceSeverity,
            buildingId: String? = nil,
            status: ComplianceStatus = .open,
            dueDate: Date? = nil,
            assignedTo: String? = nil,
            createdAt: Date = Date()
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
        }
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var rawValue: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case open = "Open"
        case inProgress = "In Progress"
        case resolved = "Resolved"
        case compliant = "Compliant"
        
        public var rawValue: String {
            switch self {
            case .open: return "Open"
            case .inProgress: return "In Progress"
            case .resolved: return "Resolved"
            case .compliant: return "Compliant"
            }
        }
        
        public var color: Color {
            switch self {
            case .open: return .red
            case .inProgress: return .orange
            case .resolved: return .blue
            case .compliant: return .green
            }
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
    
    // MARK: - Health Status Types
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case error = "Error"
        case unknown = "Unknown"
        
        public var rawValue: String {
            switch self {
            case .healthy: return "Healthy"
            case .warning: return "Warning"
            case .error: return "Error"
            case .unknown: return "Unknown"
            }
        }
        
        public var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .yellow
            case .error: return .red
            case .unknown: return .gray
            }
        }
    }
    
    // MARK: - Cross Dashboard Update Type
    public struct CrossDashboardUpdate: Codable {
        public let updateType: String
        public let data: [String: String] // Simplified from [String: Any] for Codable
        public let timestamp: Date
        
        public init(updateType: String, data: [String: String] = [:], timestamp: Date = Date()) {
            self.updateType = updateType
            self.data = data
            self.timestamp = timestamp
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

// MARK: - Global Type Aliases (For backward compatibility ONLY)
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID

// MARK: - Models Namespace Alias
public typealias Models = CoreTypes

// MARK: - AI Namespace for Nova Integration
public struct AI {
    public typealias Suggestion = CoreTypes.AISuggestion
    public typealias Priority = CoreTypes.AIPriority
    public typealias Insight = CoreTypes.IntelligenceInsight
}
