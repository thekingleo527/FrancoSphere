//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: All type definitions without duplicates
//  ✅ FIXED: All compilation errors and conflicts
//  ✅ ALIGNED: With full app architecture requirements
//  ✅ INTEGRATED: Cross-dashboard synchronization ready
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
    }
    
    public struct WorkerSkill: Codable, Hashable, Identifiable {
        public let id: String
        public let name: String
        public let category: String
        public let level: Int
        
        public init(id: String = UUID().uuidString, name: String, category: String, level: Int = 1) {
            self.id = id
            self.name = name
            self.category = category
            self.level = level
        }
        
        public var levelStars: String {
            String(repeating: "★", count: min(level, 5))
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
        
        public var rawValue: String {
            switch self {
            case .maintenance: return "Maintenance"
            case .cleaning: return "Cleaning"
            case .repair: return "Repair"
            case .inspection: return "Inspection"
            case .installation: return "Installation"
            case .utilities: return "Utilities"
            case .emergency: return "Emergency"
            case .renovation: return "Renovation"
            case .landscaping: return "Landscaping"
            case .security: return "Security"
            case .sanitation: return "Sanitation"
            }
        }
        
        public var color: Color {
            switch self {
            case .emergency: return .red
            case .repair: return .orange
            case .maintenance: return .blue
            case .cleaning: return .green
            case .inspection: return .purple
            case .security: return .red
            case .landscaping: return .green
            case .utilities: return .yellow
            case .installation: return .blue
            case .renovation: return .purple
            case .sanitation: return .green
            }
        }
        
        public var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver"
            case .cleaning: return "spray.and.wipe"
            case .repair: return "hammer"
            case .inspection: return "checklist"
            case .installation: return "gear"
            case .utilities: return "bolt"
            case .emergency: return "exclamationmark.triangle"
            case .renovation: return "building.2"
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
        case emergency = "Emergency"
        case urgent = "Urgent"
        
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
        
        public var priorityValue: Int {
            switch self {
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .critical: return 4
            case .emergency: return 5
            case .urgent: return 4
            }
        }
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical, .emergency, .urgent: return .red
            }
        }
        
        public var icon: String {
            switch self {
            case .low: return "arrow.down.circle.fill"
            case .medium: return "arrow.right.circle.fill"
            case .high: return "arrow.up.circle.fill"
            case .critical, .emergency, .urgent: return "exclamationmark.triangle.fill"
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
        
        public var rawValue: String {
            switch self {
            case .none: return "None"
            case .oneTime: return "One Time"
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .biweekly: return "Biweekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .annually: return "Annually"
            }
        }
    }
    
    // MARK: - MaintenanceTask
    public struct MaintenanceTask: Codable, Hashable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let category: TaskCategory
        public let urgency: TaskUrgency
        public let buildingId: String
        public let assignedWorkerId: String?
        public var isCompleted: Bool
        public let dueDate: Date?
        public let estimatedDuration: TimeInterval
        public let recurrence: TaskRecurrence
        public let notes: String?
        public let startTime: Date?
        public let endTime: Date?
        public let createdAt: Date
        
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
            createdAt: Date = Date()
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
            self.createdAt = createdAt
        }
        
        public var isPastDue: Bool {
            guard let dueDate = dueDate, !isCompleted else { return false }
            return dueDate < Date()
        }
        
        public var status: VerificationStatus {
            if isCompleted {
                return .verified
            } else if isPastDue {
                return .expired
            } else {
                return .pending
            }
        }
    }
    
    // MARK: - Building Types
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case industrial = "Industrial"
        case municipal = "Municipal"
        case park = "Park"
        case museum = "Museum"
        
        public var rawValue: String {
            switch self {
            case .residential: return "Residential"
            case .commercial: return "Commercial"
            case .industrial: return "Industrial"
            case .municipal: return "Municipal"
            case .park: return "Park"
            case .museum: return "Museum"
            }
        }
    }
    
    public enum BuildingTab: String, Codable, CaseIterable {
        case overview = "Overview"
        case tasks = "Tasks"
        case maintenance = "Maintenance"
        case compliance = "Compliance"
        case workers = "Workers"
        case intelligence = "Intelligence"
        case inventory = "Inventory"
        
        public var rawValue: String {
            switch self {
            case .overview: return "Overview"
            case .tasks: return "Tasks"
            case .maintenance: return "Maintenance"
            case .compliance: return "Compliance"
            case .workers: return "Workers"
            case .intelligence: return "Intelligence"
            case .inventory: return "Inventory"
            }
        }
    }
    
    // MARK: - Building Analytics & Metrics
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
        public let isCompliant: Bool
        
        public init(
            buildingId: String,
            completionRate: Double,
            overdueTasks: Int,
            urgentTasksCount: Int,
            activeWorkers: Int,
            taskCount: Int,
            complianceScore: Double = 0.85,
            lastUpdated: Date = Date(),
            weeklyCompletionTrend: Double = 0.0,
            isCompliant: Bool = true
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
            self.isCompliant = isCompliant
        }
    }
    
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
    
    // MARK: - Intelligence Types
    public enum InsightType: String, Codable, CaseIterable {
        case performance = "Performance"
        case maintenance = "Maintenance"
        case efficiency = "Efficiency"
        case compliance = "Compliance"
        case staffing = "Staffing"
        case weather = "Weather"
        case safety = "Safety"
        case cost = "Cost"
        
        public var rawValue: String {
            switch self {
            case .performance: return "Performance"
            case .maintenance: return "Maintenance"
            case .efficiency: return "Efficiency"
            case .compliance: return "Compliance"
            case .staffing: return "Staffing"
            case .weather: return "Weather"
            case .safety: return "Safety"
            case .cost: return "Cost"
            }
        }
        
        public var displayName: String { rawValue }
        
        public var icon: String {
            switch self {
            case .performance: return "chart.line.uptrend.xyaxis"
            case .maintenance: return "wrench.and.screwdriver"
            case .compliance: return "checkmark.shield"
            case .efficiency: return "speedometer"
            case .staffing: return "person.2.fill"
            case .weather: return "cloud.fill"
            case .safety: return "shield.lefthalf.filled"
            case .cost: return "dollarsign.circle"
            }
        }
    }
    
    public enum InsightPriority: String, Codable, CaseIterable {
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
        
        public var displayName: String { rawValue }
        
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
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    public struct IntelligenceInsight: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightType
        public let priority: InsightPriority
        public let actionable: Bool
        public let buildingId: String?
        public let recommendedAction: String?
        public let metadata: [String: String]
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightType,
            priority: InsightPriority,
            actionable: Bool,
            buildingId: String? = nil,
            recommendedAction: String? = nil,
            metadata: [String: String] = [:],
            timestamp: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionable = actionable
            self.buildingId = buildingId
            self.recommendedAction = recommendedAction
            self.metadata = metadata
            self.timestamp = timestamp
        }
    }
    
    // MARK: - Portfolio Intelligence
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
            case .up, .improving: return "arrow.up"
            case .down, .declining: return "arrow.down"
            case .stable: return "minus"
            }
        }
        
        public var color: Color {
            switch self {
            case .up, .improving: return .green
            case .down, .declining: return .red
            case .stable: return .gray
            }
        }
    }
    
    public struct PortfolioIntelligence: Codable, Hashable {
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
        
        // Computed properties for dashboard display
        public var overallEfficiency: Double { completionRate }
        public var averageComplianceScore: Double { Double(complianceScore) / 100.0 }
        public var trendDirection: TrendDirection { weeklyTrend > 0 ? .up : (weeklyTrend < 0 ? .down : .stable) }
        public var totalActiveWorkers: Int { activeWorkers }
        public var totalCompletedTasks: Int { completedTasks }
        
        public static let `default` = PortfolioIntelligence(
            totalBuildings: 0,
            activeWorkers: 0,
            completionRate: 0.0,
            criticalIssues: 0,
            monthlyTrend: .stable
        )
    }
    
    // MARK: - Worker Assignment Types
    public struct WorkerAssignment: Codable, Hashable, Identifiable {
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
    
    public typealias FrancoWorkerAssignment = WorkerAssignment
    public typealias OperationalTaskAssignment = WorkerAssignment
    
    // MARK: - Compliance Types
    public enum ComplianceStatus: String, Codable, CaseIterable {
        case compliant = "Compliant"
        case pending = "Pending"
        case nonCompliant = "Non-Compliant"
        case underReview = "Under Review"
        
        public var rawValue: String {
            switch self {
            case .compliant: return "Compliant"
            case .pending: return "Pending"
            case .nonCompliant: return "Non-Compliant"
            case .underReview: return "Under Review"
            }
        }
        
        public var color: Color {
            switch self {
            case .compliant: return .green
            case .pending: return .yellow
            case .nonCompliant: return .red
            case .underReview: return .blue
            }
        }
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case regulatory = "Regulatory"
        case environmental = "Environmental"
        case documentation = "Documentation"
        case inspection = "Inspection"
        case maintenanceOverdue = "Maintenance Overdue"
        case safetyViolation = "Safety Violation"
        case documentationMissing = "Documentation Missing"
        case inspectionRequired = "Inspection Required"
        case certificateExpired = "Certificate Expired"
        case permitRequired = "Permit Required"
        
        public var rawValue: String {
            switch self {
            case .safety: return "Safety"
            case .regulatory: return "Regulatory"
            case .environmental: return "Environmental"
            case .documentation: return "Documentation"
            case .inspection: return "Inspection"
            case .maintenanceOverdue: return "Maintenance Overdue"
            case .safetyViolation: return "Safety Violation"
            case .documentationMissing: return "Documentation Missing"
            case .inspectionRequired: return "Inspection Required"
            case .certificateExpired: return "Certificate Expired"
            case .permitRequired: return "Permit Required"
            }
        }
        
        public var displayName: String { rawValue }
        
        public var icon: String {
            switch self {
            case .safety, .safetyViolation: return "exclamationmark.shield"
            case .regulatory: return "doc.text"
            case .environmental: return "leaf"
            case .documentation, .documentationMissing: return "doc.badge.exclamationmark"
            case .inspection, .inspectionRequired: return "magnifyingglass"
            case .maintenanceOverdue: return "wrench.and.screwdriver"
            case .certificateExpired: return "doc.badge.clock"
            case .permitRequired: return "doc.badge.plus"
            }
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
        
        public var displayName: String { rawValue }
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    public struct ComplianceIssue: Identifiable, Codable, Hashable {
        public let id: String
        public let buildingId: String
        public let buildingName: String
        public let issueType: ComplianceIssueType
        public let severity: ComplianceSeverity
        public let description: String
        public let dueDate: Date?
        public let resolvedDate: Date?
        public let assignedTo: String?
        public let metadata: [String: String]
        public let createdAt: Date
        
        public var isResolved: Bool { resolvedDate != nil }
        public var isOverdue: Bool {
            guard let dueDate = dueDate, !isResolved else { return false }
            return dueDate < Date()
        }
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            buildingName: String,
            issueType: ComplianceIssueType,
            severity: ComplianceSeverity,
            description: String,
            dueDate: Date? = nil,
            resolvedDate: Date? = nil,
            assignedTo: String? = nil,
            metadata: [String: String] = [:],
            createdAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.buildingName = buildingName
            self.issueType = issueType
            self.severity = severity
            self.description = description
            self.dueDate = dueDate
            self.resolvedDate = resolvedDate
            self.assignedTo = assignedTo
            self.metadata = metadata
            self.createdAt = createdAt
        }
    }
    
    public enum ComplianceTab: String, Codable, CaseIterable {
        case overview = "Overview"
        case issues = "Issues"
        case documents = "Documents"
        case history = "History"
        
        public var rawValue: String {
            switch self {
            case .overview: return "Overview"
            case .issues: return "Issues"
            case .documents: return "Documents"
            case .history: return "History"
            }
        }
    }
    
    // MARK: - Weather Types
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "Clear"
        case cloudy = "Cloudy"
        case rain = "Rain"
        case snow = "Snow"
        case storm = "Storm"
        case extreme = "Extreme"
        
        public var rawValue: String {
            switch self {
            case .clear: return "Clear"
            case .cloudy: return "Cloudy"
            case .rain: return "Rain"
            case .snow: return "Snow"
            case .storm: return "Storm"
            case .extreme: return "Extreme"
            }
        }
        
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
    
    // MARK: - Inventory Types
    public enum InventoryCategory: String, Codable, CaseIterable {
        case tools = "Tools"
        case supplies = "Supplies"
        case equipment = "Equipment"
        case safety = "Safety"
        case cleaning = "Cleaning"
        case materials = "Materials"
        
        public var rawValue: String {
            switch self {
            case .tools: return "Tools"
            case .supplies: return "Supplies"
            case .equipment: return "Equipment"
            case .safety: return "Safety"
            case .cleaning: return "Cleaning"
            case .materials: return "Materials"
            }
        }
        
        public var icon: String {
            switch self {
            case .tools: return "wrench.and.screwdriver"
            case .supplies: return "box"
            case .equipment: return "gear"
            case .safety: return "shield"
            case .cleaning: return "spray.and.wipe"
            case .materials: return "cube.box"
            }
        }
    }
    
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
            case .lowStock: return .yellow
            case .outOfStock: return .red
            case .ordered: return .blue
            }
        }
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
    
    // MARK: - Performance & Analytics
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
        
        public var displayProgress: String { "\(completedTasks)/\(totalTasks)" }
    }
    
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
    
    // MARK: - Route & Schedule Types
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
    
    // MARK: - Maintenance & Records
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
    
    // MARK: - AI & Suggestion Types
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
        
        public var rawValue: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
    }
    
    public enum InsightCategory: String, Codable, CaseIterable {
        case operational = "Operational"
        case strategic = "Strategic"
        case tactical = "Tactical"
        case compliance = "Compliance"
        
        public var rawValue: String {
            switch self {
            case .operational: return "Operational"
            case .strategic: return "Strategic"
            case .tactical: return "Tactical"
            case .compliance: return "Compliance"
            }
        }
    }
    
    // MARK: - Verification & Status Types
    public enum VerificationStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case verified = "Verified"
        case rejected = "Rejected"
        case expired = "Expired"
        
        public var rawValue: String {
            switch self {
            case .pending: return "Pending"
            case .verified: return "Verified"
            case .rejected: return "Rejected"
            case .expired: return "Expired"
            }
        }
        
        public var color: Color {
            switch self {
            case .pending: return .yellow
            case .verified: return .green
            case .rejected: return .red
            case .expired: return .gray
            }
        }
    }
    
    public enum DataHealthStatus: String, Codable, CaseIterable {
        case healthy = "Healthy"
        case warning = "Warning"
        case critical = "Critical"
        case unknown = "Unknown"
        
        public var rawValue: String {
            switch self {
            case .healthy: return "Healthy"
            case .warning: return "Warning"
            case .critical: return "Critical"
            case .unknown: return "Unknown"
            }
        }
        
        public var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .yellow
            case .critical: return .red
            case .unknown: return .gray
            }
        }
    }
    
    public enum BuildingAccessType: String, Codable, CaseIterable {
        case assigned = "Assigned"
        case portfolio = "Portfolio"
        case coverage = "Coverage"
        case emergency = "Emergency"
        
        public var rawValue: String {
            switch self {
            case .assigned: return "Assigned"
            case .portfolio: return "Portfolio"
            case .coverage: return "Coverage"
            case .emergency: return "Emergency"
            }
        }
    }
    
    // MARK: - Cross-Dashboard Synchronization Types
    public enum DashboardSyncStatus: String, Codable {
        case synced = "Synced"
        case syncing = "Syncing"
        case error = "Error"
        case offline = "Offline"
        
        public var rawValue: String {
            switch self {
            case .synced: return "Synced"
            case .syncing: return "Syncing"
            case .error: return "Error"
            case .offline: return "Offline"
            }
        }
        
        public var description: String { rawValue }
        
        public var color: Color {
            switch self {
            case .synced: return .green
            case .syncing: return .blue
            case .error: return .red
            case .offline: return .gray
            }
        }
        
        public var icon: String {
            switch self {
            case .synced: return "checkmark.circle.fill"
            case .syncing: return "arrow.clockwise.circle"
            case .error: return "exclamationmark.triangle.fill"
            case .offline: return "wifi.slash"
            }
        }
    }
    
    public enum CrossDashboardUpdate: Codable, Hashable {
        case taskCompleted(buildingId: String)
        case workerClockedIn(buildingId: String)
        case metricsUpdated(buildingIds: [String])
        case insightsUpdated(count: Int)
        case buildingIntelligenceUpdated(buildingId: String)
        case complianceUpdated(buildingIds: [String])
        case portfolioUpdated(buildingCount: Int)
        
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
            case .portfolioUpdated(let buildingCount):
                return "Portfolio updated with \(buildingCount) buildings"
            }
        }
    }
    
    // MARK: - Additional Supporting Types
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

// MARK: - Global Type Aliases (For backward compatibility and convenience)
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID

public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias TaskRecurrence = CoreTypes.TaskRecurrence
public typealias MaintenanceTask = CoreTypes.MaintenanceTask
public typealias BuildingType = CoreTypes.BuildingType
public typealias WeatherCondition = CoreTypes.WeatherCondition
public typealias OutdoorWorkRisk = CoreTypes.OutdoorWorkRisk
public typealias VerificationStatus = CoreTypes.VerificationStatus
public typealias TrendDirection = CoreTypes.TrendDirection
public typealias InsightType = CoreTypes.InsightType
public typealias InsightPriority = CoreTypes.InsightPriority
public typealias BuildingMetrics = CoreTypes.BuildingMetrics
public typealias BuildingAnalytics = CoreTypes.BuildingAnalytics
public typealias PortfolioIntelligence = CoreTypes.PortfolioIntelligence
public typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
public typealias ComplianceStatus = CoreTypes.ComplianceStatus
public typealias ComplianceIssue = CoreTypes.ComplianceIssue
public typealias ComplianceIssueType = CoreTypes.ComplianceIssueType
public typealias ComplianceSeverity = CoreTypes.ComplianceSeverity
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
public typealias BuildingTab = CoreTypes.BuildingTab
public typealias BuildingInsight = CoreTypes.BuildingInsight
public typealias DashboardSyncStatus = CoreTypes.DashboardSyncStatus
public typealias CrossDashboardUpdate = CoreTypes.CrossDashboardUpdate
public typealias BuildingAccessType = CoreTypes.BuildingAccessType
public typealias WorkerSkill = CoreTypes.WorkerSkill
public typealias WorkerStatus = CoreTypes.WorkerStatus
public typealias AISuggestion = CoreTypes.AISuggestion
public typealias AIPriority = CoreTypes.AIPriority
public typealias InsightCategory = CoreTypes.InsightCategory
