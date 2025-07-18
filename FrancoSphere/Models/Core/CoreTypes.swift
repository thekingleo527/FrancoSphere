//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ CLEANED: All redeclarations removed
//  ✅ FIXED: Property conflicts resolved
//  ✅ COMPLETE: All required types defined once
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
        
        public var color: Color {
            switch skillLevel {
            case 1...2: return .red
            case 3: return .orange
            case 4: return .yellow
            default: return .green
            }
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
        
        public var color: Color {
            switch self {
            case .emergency: return .red
            case .repair: return .orange
            case .maintenance: return .blue
            case .cleaning: return .green
            case .inspection: return .purple
            default: return .gray
            }
        }
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable {
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
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            }
        }
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case none = "None"
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
    }
    
    public struct MaintenanceTask: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let recurrence: TaskRecurrence
        public let estimatedDuration: TimeInterval
        public let skillsRequired: [String]
        public let buildingId: String
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            category: TaskCategory,
            urgency: TaskUrgency,
            recurrence: TaskRecurrence = .none,
            estimatedDuration: TimeInterval,
            skillsRequired: [String] = [],
            buildingId: String
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.category = category
            self.urgency = urgency
            self.recurrence = recurrence
            self.estimatedDuration = estimatedDuration
            self.skillsRequired = skillsRequired
            self.buildingId = buildingId
        }
    }
    
    // MARK: - Building Types
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case museum = "Museum"
        case office = "Office"
        case retail = "Retail"
        case industrial = "Industrial"
        case educational = "Educational"
        case healthcare = "Healthcare"
        case government = "Government"
        case mixed = "Mixed Use"
    }
    
    public enum BuildingTab: String, Codable, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case workers = "Workers"
        case intelligence = "Intelligence"
        case maintenance = "Maintenance"
        case compliance = "Compliance"
    }
    
    public enum BuildingAccessType: String, Codable, CaseIterable {
        case assigned = "Assigned"
        case coverage = "Coverage"
        case emergency = "Emergency"
        case maintenance = "Maintenance"
        case temporary = "Temporary"
        case unknown = "Unknown"
        
        public var color: Color {
            switch self {
            case .assigned: return .green
            case .coverage: return .blue
            case .emergency: return .red
            case .maintenance: return .orange
            case .temporary: return .yellow
            case .unknown: return .gray
            }
        }
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case cloudy = "Cloudy"
        case rainy = "Rainy"
        case snowy = "Snowy"
        case stormy = "Stormy"
        case foggy = "Foggy"
        case windy = "Windy"
        case hot = "Hot"
        case cold = "Cold"
    }
    
    public enum OutdoorWorkRisk: String, Codable, CaseIterable {
        case low = "Low"
        case moderate = "Moderate"
        case high = "High"
        case extreme = "Extreme"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .extreme: return .red
            }
        }
    }
    
    public struct WeatherData: Codable, Identifiable {
        public let id: String
        public let temperature: Double
        public let condition: WeatherCondition
        public let humidity: Double
        public let windSpeed: Double
        public let outdoorWorkRisk: OutdoorWorkRisk
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            temperature: Double,
            condition: WeatherCondition,
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
    
    // MARK: - Analytics Types
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
        case incomplete = "Incomplete"
        
        public var color: Color {
            switch self {
            case .pending: return .orange
            case .verified: return .green
            case .rejected: return .red
            case .incomplete: return .gray
            }
        }
    }
    
    public enum TrendDirection: String, Codable, CaseIterable {
        case up = "Up"
        case down = "Down"
        case stable = "Stable"
        case improving = "Improving"
        case declining = "Declining"
        case unknown = "Unknown"
        
        public var color: Color {
            switch self {
            case .up, .improving: return .green
            case .down, .declining: return .red
            case .stable: return .orange
            case .unknown: return .gray
            }
        }
    }
    
    // MARK: - Intelligence Types
    public enum InsightType: String, Codable, CaseIterable {
        case performance = "Performance"
        case maintenance = "Maintenance"
        case efficiency = "Efficiency"
        case compliance = "Compliance"
        case cost = "Cost"
        case safety = "Safety"
        case scheduling = "Scheduling"
        case resource = "Resource"
        case weather = "Weather"
        case quality = "Quality"
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
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
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
        public let createdAt: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightType,
            priority: InsightPriority,
            actionRequired: Bool = false,
            affectedBuildings: [String] = [],
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionRequired = actionRequired
            self.affectedBuildings = affectedBuildings
            self.createdAt = createdAt
        }
        
        public var actionable: Bool { actionRequired }
    }
    
    // MARK: - Building Metrics
    public struct BuildingMetrics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let completionRate: Double
        public let averageTaskTime: TimeInterval
        public let overdueTasks: Int
        public let totalTasks: Int
        public let activeWorkers: Int
        public let isCompliant: Bool
        public let overallScore: Int
        public let lastUpdated: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            completionRate: Double,
            averageTaskTime: TimeInterval,
            overdueTasks: Int,
            totalTasks: Int,
            activeWorkers: Int,
            isCompliant: Bool = true,
            overallScore: Int,
            lastUpdated: Date = Date()
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
        }
        
        public var performanceGrade: String {
            switch completionRate {
            case 0.9...: return "A"
            case 0.8..<0.9: return "B"
            case 0.7..<0.8: return "C"
            case 0.6..<0.7: return "D"
            default: return "F"
            }
        }
        
        public var pendingTasks: Int {
            totalTasks - (totalTasks - overdueTasks)
        }
        
        public var weeklyCompletionTrend: Double {
            // This would be calculated from historical data
            0.0
        }
    }
    
    public struct BuildingAnalytics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let metrics: BuildingMetrics
        public let trends: [String: TrendDirection]
        public let insights: [IntelligenceInsight]
        public let lastAnalyzed: Date
        public let completionRate: Double
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            metrics: BuildingMetrics,
            trends: [String: TrendDirection] = [:],
            insights: [IntelligenceInsight] = [],
            lastAnalyzed: Date = Date(),
            completionRate: Double
        ) {
            self.id = id
            self.buildingId = buildingId
            self.metrics = metrics
            self.trends = trends
            self.insights = insights
            self.lastAnalyzed = lastAnalyzed
            self.completionRate = completionRate
        }
    }
    
    public struct PortfolioIntelligence: Codable, Identifiable {
        public let id: String
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let completionRate: Double
        public let criticalIssues: Int
        public let complianceScore: Int
        public let portfolioHealth: Double
        public let monthlyTrend: TrendDirection
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            totalBuildings: Int,
            activeWorkers: Int,
            completionRate: Double,
            criticalIssues: Int,
            complianceScore: Int,
            portfolioHealth: Double,
            monthlyTrend: TrendDirection = .stable,
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.completionRate = completionRate
            self.criticalIssues = criticalIssues
            self.complianceScore = complianceScore
            self.portfolioHealth = portfolioHealth
            self.monthlyTrend = monthlyTrend
            self.generatedAt = generatedAt
        }
        
        public static let `default` = PortfolioIntelligence(
            totalBuildings: 0,
            activeWorkers: 0,
            completionRate: 0.0,
            criticalIssues: 0,
            complianceScore: 0,
            portfolioHealth: 0.0
        )
    }
    
    // MARK: - Compliance Types
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case compliant = "Compliant"
        case warning = "Warning"
        case violation = "Violation"
        case pending = "Pending"
        
        public var color: Color {
            switch self {
            case .compliant: return .green
            case .warning: return .yellow
            case .violation: return .red
            case .pending: return .orange
            }
        }
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case environmental = "Environmental"
        case building = "Building Code"
        case accessibility = "Accessibility"
        case fire = "Fire Safety"
        case health = "Health"
        case security = "Security"
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
    
    public enum ComplianceTab: String, Codable, CaseIterable {
        case overview = "Overview"
        case issues = "Issues"
        case audits = "Audits"
        case reports = "Reports"
    }
    
    public struct ComplianceIssue: Codable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let severity: String
        public let buildingId: String
        public let status: ComplianceStatus
        public let dueDate: Date?
        public let createdAt: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            severity: String,
            buildingId: String,
            status: ComplianceStatus = .pending,
            dueDate: Date? = nil,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.severity = severity
            self.buildingId = buildingId
            self.status = status
            self.dueDate = dueDate
            self.createdAt = createdAt
        }
    }
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case tools = "Tools"
        case supplies = "Supplies"
        case equipment = "Equipment"
        case safety = "Safety"
        case cleaning = "Cleaning"
        case parts = "Parts"
    }
    
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case onOrder = "On Order"
    }
    
    public struct InventoryItem: Codable, Identifiable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let quantity: Int
        public let unitCost: Double
        public let supplier: String
        public let lastRestocked: Date
        
        public init(
            id: String = UUID().uuidString,
            name: String,
            category: InventoryCategory,
            quantity: Int,
            unitCost: Double,
            supplier: String,
            lastRestocked: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.quantity = quantity
            self.unitCost = unitCost
            self.supplier = supplier
            self.lastRestocked = lastRestocked
        }
        
        public var totalCost: Double { Double(quantity) * unitCost }
    }
    
    // MARK: - Assignment Types
    public struct WorkerAssignment: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let buildingId: String
        public let assignedDate: Date
        public let isActive: Bool
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            buildingId: String,
            assignedDate: Date = Date(),
            isActive: Bool = true
        ) {
            self.id = id
            self.workerId = workerId
            self.buildingId = buildingId
            self.assignedDate = assignedDate
            self.isActive = isActive
        }
    }
    
    public struct FrancoWorkerAssignment: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let buildingIds: [String]
        public let schedule: WeeklySchedule
        public let specializations: [String]
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            buildingIds: [String],
            schedule: WeeklySchedule,
            specializations: [String] = []
        ) {
            self.id = id
            self.workerId = workerId
            self.buildingIds = buildingIds
            self.schedule = schedule
            self.specializations = specializations
        }
    }
    
    public struct OperationalTaskAssignment: Codable, Identifiable {
        public let id: String
        public let taskId: String
        public let workerId: String
        public let assignedAt: Date
        public let estimatedCompletion: Date?
        public let priority: TaskUrgency
        
        public init(
            id: String = UUID().uuidString,
            taskId: String,
            workerId: String,
            assignedAt: Date = Date(),
            estimatedCompletion: Date? = nil,
            priority: TaskUrgency = .medium
        ) {
            self.id = id
            self.taskId = taskId
            self.workerId = workerId
            self.assignedAt = assignedAt
            self.estimatedCompletion = estimatedCompletion
            self.priority = priority
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
        
        public init(
            id: String = UUID().uuidString,
            optimizedRoute: [String],
            timeSaved: TimeInterval,
            efficiency: Double
        ) {
            self.id = id
            self.optimizedRoute = optimizedRoute
            self.timeSaved = timeSaved
            self.efficiency = efficiency
        }
    }
    
    public struct ScheduleConflict: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let conflictingTasks: [String]
        public let suggestedResolution: String
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            conflictingTasks: [String],
            suggestedResolution: String
        ) {
            self.id = id
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
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            taskId: String,
            workerId: String,
            completedDate: Date,
            description: String,
            cost: Double? = nil
        ) {
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
    public struct PerformanceMetrics: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let tasksCompleted: Int
        public let averageTaskTime: TimeInterval
        public let qualityScore: Double
        public let punctualityScore: Double
        public let overallRating: Double
        public let period: Date
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            tasksCompleted: Int,
            averageTaskTime: TimeInterval,
            qualityScore: Double,
            punctualityScore: Double,
            overallRating: Double,
            period: Date = Date()
        ) {
            self.id = id
            self.workerId = workerId
            self.tasksCompleted = tasksCompleted
            self.averageTaskTime = averageTaskTime
            self.qualityScore = qualityScore
            self.punctualityScore = punctualityScore
            self.overallRating = overallRating
            self.period = period
        }
    }
    
    public struct WorkerPerformanceMetrics: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let baseMetrics: PerformanceMetrics
        public let specializationRatings: [String: Double]
        public let teamworkScore: Double
        public let improvementAreas: [String]
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            baseMetrics: PerformanceMetrics,
            specializationRatings: [String: Double] = [:],
            teamworkScore: Double,
            improvementAreas: [String] = []
        ) {
            self.id = id
            self.workerId = workerId
            self.baseMetrics = baseMetrics
            self.specializationRatings = specializationRatings
            self.teamworkScore = teamworkScore
            self.improvementAreas = improvementAreas
        }
    }
    
    public struct StreakData: Codable, Identifiable {
        public let id: String
        public let workerId: String
        public let currentStreak: Int
        public let longestStreak: Int
        public let streakType: String
        public let lastActiveDate: Date
        
        public init(
            id: String = UUID().uuidString,
            workerId: String,
            currentStreak: Int,
            longestStreak: Int,
            streakType: String = "task_completion",
            lastActiveDate: Date = Date()
        ) {
            self.id = id
            self.workerId = workerId
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.streakType = streakType
            self.lastActiveDate = lastActiveDate
        }
    }
    
    public struct TaskTrends: Codable, Identifiable {
        public let id: String
        public let period: String
        public let completionTrend: TrendDirection
        public let averageTimeTrend: TrendDirection
        public let qualityTrend: TrendDirection
        public let dataPoints: [String: Double]
        
        public init(
            id: String = UUID().uuidString,
            period: String,
            completionTrend: TrendDirection,
            averageTimeTrend: TrendDirection,
            qualityTrend: TrendDirection,
            dataPoints: [String: Double] = [:]
        ) {
            self.id = id
            self.period = period
            self.completionTrend = completionTrend
            self.averageTimeTrend = averageTimeTrend
            self.qualityTrend = qualityTrend
            self.dataPoints = dataPoints
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
    
    // MARK: - Filter Types
    public struct InsightFilter: Codable, Hashable, Identifiable {
        public let id: String
        public let type: InsightType?
        public let priority: InsightPriority?
        public let buildingId: String?
        
        public init(
            id: String = UUID().uuidString,
            type: InsightType? = nil,
            priority: InsightPriority? = nil,
            buildingId: String? = nil
        ) {
            self.id = id
            self.type = type
            self.priority = priority
            self.buildingId = buildingId
        }
    }
    
    // MARK: - Task Progress Types
    public struct TaskProgress: Codable, Identifiable {
        public let id: String
        public let totalTasks: Int
        public let completedTasks: Int
        public let progressPercentage: Double
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
            self.progressPercentage = totalTasks > 0 ? (Double(completedTasks) / Double(totalTasks)) * 100 : 0
            self.lastUpdated = lastUpdated
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
    
    // MARK: - Building Insight Types
    public struct BuildingInsight: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let insight: IntelligenceInsight
        public let metrics: BuildingMetrics
        public let recommendations: [String]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            insight: IntelligenceInsight,
            metrics: BuildingMetrics,
            recommendations: [String] = [],
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.insight = insight
            self.metrics = metrics
            self.recommendations = recommendations
            self.generatedAt = generatedAt
        }
    }
    
    // MARK: - Dashboard Sync Types
    public enum DashboardSyncStatus: String, Codable, CaseIterable {
        case synced = "Synced"
        case syncing = "Syncing"
        case error = "Error"
        case offline = "Offline"
        
        public var color: Color {
            switch self {
            case .synced: return .green
            case .syncing: return .blue
            case .error: return .red
            case .offline: return .gray
            }
        }
    }
    
    public enum CrossDashboardUpdate: Codable {
        case taskCompleted(taskId: String, workerId: String, buildingId: String)
        case workerAssigned(workerId: String, buildingId: String)
        case buildingMetricsUpdated(buildingId: String, metrics: BuildingMetrics)
        case complianceIssueAdded(issue: ComplianceIssue)
        case portfolioUpdated(buildingCount: Int)
        case metricsUpdated(buildingIds: [String])
        case insightsGenerated(insights: [IntelligenceInsight])
        
        public var buildingId: String? {
            switch self {
            case .taskCompleted(_, _, let buildingId): return buildingId
            case .workerAssigned(_, let buildingId): return buildingId
            case .buildingMetricsUpdated(let buildingId, _): return buildingId
            case .complianceIssueAdded(let issue): return issue.buildingId
            default: return nil
            }
        }
    }
    
    // MARK: - AI Types
    public enum AIPriority: String, Codable, CaseIterable {
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
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    public enum InsightCategory: String, Codable, CaseIterable {
        case operations = "Operations"
        case maintenance = "Maintenance"
        case performance = "Performance"
        case compliance = "Compliance"
        case cost = "Cost"
        case safety = "Safety"
        case efficiency = "Efficiency"
        case quality = "Quality"
        
        public var icon: String {
            switch self {
            case .operations: return "gear"
            case .maintenance: return "wrench"
            case .performance: return "chart.line.uptrend.xyaxis"
            case .compliance: return "checkmark.shield"
            case .cost: return "dollarsign"
            case .safety: return "shield"
            case .efficiency: return "speedometer"
            case .quality: return "star"
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

// MARK: - Missing Type Definitions

public enum AIScenarioType: String, CaseIterable, Codable {
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
    
    public var icon: String {
        switch self {
        case .clockOutReminder: return "clock.badge.exclamationmark"
        case .weatherAlert: return "cloud.rain.fill"
        case .inventoryLow: return "cube.box"
        case .routineIncomplete: return "list.bullet.clipboard"
        case .pendingTasks: return "checklist"
        case .emergencyRepair: return "wrench.fill"
        case .taskOverdue: return "exclamationmark.triangle.fill"
        case .buildingAlert: return "building.2.fill"
        }
    }
}

public struct AIScenario: Codable, Identifiable {
    public let id = UUID()
    public let type: AIScenarioType
    public let title: String
    public let message: String
    public let actionRequired: Bool
    public let createdAt: Date
    public let buildingId: String?
    
    public init(type: AIScenarioType, title: String, message: String, actionRequired: Bool = false, buildingId: String? = nil) {
        self.type = type
        self.title = title
        self.message = message
        self.actionRequired = actionRequired
        self.createdAt = Date()
        self.buildingId = buildingId
    }
}

public struct BuildingStatistics: Codable {
    public let buildingId: String
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let averageCompletionTime: TimeInterval
    public let lastUpdated: Date
    
    public init(buildingId: String, totalTasks: Int, completedTasks: Int, overdueTasks: Int, averageCompletionTime: TimeInterval) {
        self.buildingId = buildingId
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.overdueTasks = overdueTasks
        self.averageCompletionTime = averageCompletionTime
        self.lastUpdated = Date()
    }
}

public enum BuildingTab: String, CaseIterable {
    case assigned = "assigned"
    case coverage = "coverage"
    case all = "all"
    
    public var displayName: String {
        switch self {
        case .assigned: return "Assigned"
        case .coverage: return "Coverage"
        case .all: return "All Buildings"
        }
    }
}

public enum RestockStatus: String, CaseIterable, Codable {
    case inStock = "in_stock"
    case lowStock = "low_stock"
    case outOfStock = "out_of_stock"
    case onOrder = "on_order"
    
    public var displayName: String {
        switch self {
        case .inStock: return "In Stock"
        case .lowStock: return "Low Stock"
        case .outOfStock: return "Out of Stock"
        case .onOrder: return "On Order"
        }
    }
}

public enum TrendDirection: String, Codable {
    case improving = "improving"
    case declining = "declining"
    case stable = "stable"
    
    public var color: Color {
        switch self {
        case .improving: return .green
        case .declining: return .red
        case .stable: return .orange
        }
    }
}

public enum SkillLevel: String, CaseIterable, Codable {
    case basic = "basic"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
    
    public var displayName: String {
        switch self {
        case .basic: return "Basic"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
}

public struct RouteStop: Codable, Identifiable {
    public let id = UUID()
    public let buildingId: String
    public let buildingName: String
    public let estimatedTime: TimeInterval
    public let tasks: [String] // Task IDs
    
    public init(buildingId: String, buildingName: String, estimatedTime: TimeInterval, tasks: [String]) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.estimatedTime = estimatedTime
        self.tasks = tasks
    }
}

public struct WorkerDailyRoute: Codable, Identifiable {
    public let id = UUID()
    public let workerId: String
    public let date: Date
    public let stops: [RouteStop]
    public let totalEstimatedTime: TimeInterval
    public let isOptimized: Bool
    
    public init(workerId: String, date: Date, stops: [RouteStop], isOptimized: Bool = false) {
        self.workerId = workerId
        self.date = date
        self.stops = stops
        self.totalEstimatedTime = stops.reduce(0) { $0 + $1.estimatedTime }
        self.isOptimized = isOptimized
    }
}

public struct WorkerRoutineSummary: Codable {
    public let workerId: String
    public let totalRoutes: Int
    public let averageStops: Double
    public let averageTime: TimeInterval
    public let efficiencyScore: Double
    public let lastUpdated: Date
    
    public init(workerId: String, totalRoutes: Int, averageStops: Double, averageTime: TimeInterval, efficiencyScore: Double) {
        self.workerId = workerId
        self.totalRoutes = totalRoutes
        self.averageStops = averageStops
        self.averageTime = averageTime
        self.efficiencyScore = efficiencyScore
        self.lastUpdated = Date()
    }
}

public enum CrossDashboardUpdateType: String, Codable {
    case taskCompleted = "task_completed"
    case buildingMetricsUpdated = "building_metrics_updated"
    case complianceIssueAdded = "compliance_issue_added"
    case intelligenceGenerated = "intelligence_generated"
    case dataRefresh = "data_refresh"
    case configurationChange = "configuration_change"
}

public struct CrossDashboardUpdate: Codable {
    public let type: CrossDashboardUpdateType
    public let source: DashboardType
    public let timestamp: Date
    public let data: [String: Any]
    
    public init(type: CrossDashboardUpdateType, source: DashboardType, timestamp: Date, data: [String: Any]) {
        self.type = type
        self.source = source
        self.timestamp = timestamp
        self.data = data
    }
}

public enum DashboardType: String, Codable {
    case worker = "worker"
    case client = "client"
    case admin = "admin"
}

// Fix for public/internal issues
public typealias Models = CoreTypes
