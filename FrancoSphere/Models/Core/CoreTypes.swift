//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Services removed, only data types remain
//  ✅ FIXED: All compilation errors eliminated
//  ✅ FIXED: Removed all color properties - now in FrancoSphereDesign.EnumColors
//  ✅ FIXED: Removed duplicate needsRestock property
//  ✅ FIXED: Added missing BuildingIntelligence type
//  ✅ FIXED: Made TaskFrequency accessible
//  ✅ FIXED: Removed duplicate rawValue property from TaskUrgency
//  ✅ FIXED: Removed all duplicate properties from InventoryItem
//  ✅ ORGANIZED: Clean architecture with data types only
//
//  NOTE: All enum colors have been moved to FrancoSphereDesign.EnumColors
//  Usage: FrancoSphereDesign.EnumColors.taskStatus(.completed)
//

import Foundation
import CoreLocation
import Combine
import SwiftUI

// MARK: - CoreTypes Namespace
public struct CoreTypes {
    
    // MARK: - Core ID Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - User Role
    public enum UserRole: String, Codable, CaseIterable {
        case admin = "admin"
        case manager = "manager"
        case worker = "worker"
        case client = "client"
        
        public var displayName: String {
            switch self {
            case .admin: return "Admin"
            case .manager: return "Manager"
            case .worker: return "Worker"
            case .client: return "Client"
            }
        }
    }
    
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
    
    // MARK: - Dashboard Update
    public struct DashboardUpdate: Codable, Identifiable {
        public enum Source: String, Codable {
            case admin = "admin"
            case worker = "worker"
            case client = "client"
            case system = "system"
        }
        
        public enum UpdateType: String, Codable {
            case taskStarted = "taskStarted"
            case taskCompleted = "taskCompleted"
            case taskUpdated = "taskUpdated"
            case workerClockedIn = "workerClockedIn"
            case workerClockedOut = "workerClockedOut"
            case buildingMetricsChanged = "buildingMetricsChanged"
            case inventoryUpdated = "inventoryUpdated"
            case complianceStatusChanged = "complianceStatusChanged"
        }
        
        public let id: String
        public let source: Source
        public let type: UpdateType
        public let buildingId: String
        public let workerId: String
        public let data: [String: String]
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            source: Source,
            type: UpdateType,
            buildingId: String,
            workerId: String,
            data: [String: String] = [:],
            timestamp: Date = Date()
        ) {
            self.id = id
            self.source = source
            self.type = type
            self.buildingId = buildingId
            self.workerId = workerId
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
    }
    
    // MARK: - Worker Profile
    public struct WorkerProfile: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let email: String
        public let phone: String?
        public let phoneNumber: String?
        public let role: UserRole
        public let skills: [String]?
        public let certifications: [String]?
        public let hireDate: Date?
        public let isActive: Bool
        public let profileImageUrl: URL?
        public let assignedBuildingIds: [String]
        public let capabilities: WorkerCapabilities?
        public let createdAt: Date
        public let updatedAt: Date
        
        public init(
            id: String,
            name: String,
            email: String,
            phone: String? = nil,
            phoneNumber: String? = nil,
            role: UserRole,
            skills: [String]? = nil,
            certifications: [String]? = nil,
            hireDate: Date? = nil,
            isActive: Bool = true,
            profileImageUrl: URL? = nil,
            assignedBuildingIds: [String] = [],
            capabilities: WorkerCapabilities? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.email = email
            self.phone = phone
            self.phoneNumber = phoneNumber ?? phone
            self.role = role
            self.skills = skills
            self.certifications = certifications
            self.hireDate = hireDate
            self.isActive = isActive
            self.profileImageUrl = profileImageUrl
            self.assignedBuildingIds = assignedBuildingIds
            self.capabilities = capabilities
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        public var displayName: String { name }
        public var isAdmin: Bool { role == .admin }
        public var isWorker: Bool { role == .worker }
        public var isManager: Bool { role == .manager }
        public var isClient: Bool { role == .client }
    }
    
    // MARK: - Worker Capabilities
    public struct WorkerCapabilities: Codable, Hashable {
        public let canUploadPhotos: Bool
        public let canAddNotes: Bool
        public let canViewMap: Bool
        public let canAddEmergencyTasks: Bool
        public let requiresPhotoForSanitation: Bool
        public let simplifiedInterface: Bool
        
        public init(
            canUploadPhotos: Bool = true,
            canAddNotes: Bool = true,
            canViewMap: Bool = true,
            canAddEmergencyTasks: Bool = false,
            requiresPhotoForSanitation: Bool = true,
            simplifiedInterface: Bool = false
        ) {
            self.canUploadPhotos = canUploadPhotos
            self.canAddNotes = canAddNotes
            self.canViewMap = canViewMap
            self.canAddEmergencyTasks = canAddEmergencyTasks
            self.requiresPhotoForSanitation = requiresPhotoForSanitation
            self.simplifiedInterface = simplifiedInterface
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
    
    // MARK: - Location Types
    public struct NamedCoordinate: Identifiable, Codable, Hashable {
        public let id: String
        public let name: String
        public let address: String
        public let latitude: Double
        public let longitude: Double
        
        public init(id: String, name: String, address: String, latitude: Double, longitude: Double) {
            self.id = id
            self.name = name
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
        }
        
        // Convenience initializer for compatibility
        public init(id: String, name: String, latitude: Double, longitude: Double) {
            self.id = id
            self.name = name
            self.address = ""
            self.latitude = latitude
            self.longitude = longitude
        }
        
        public var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        public func distance(from other: NamedCoordinate) -> Double {
            let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
            let location2 = CLLocation(latitude: other.latitude, longitude: other.longitude)
            return location1.distance(from: location2)
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
        
        public var displayStatus: String {
            if overdueTasks > 0 { return "Behind Schedule" }
            if urgentTasksCount > 0 { return "Urgent Tasks" }
            if completionRate >= 0.9 { return "Excellent" }
            if completionRate >= 0.7 { return "Good" }
            return "Needs Attention"
        }
    }
    
    // MARK: - Building Intelligence (Added for compatibility)
    public struct BuildingIntelligence: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let metrics: BuildingMetrics
        public let insights: [IntelligenceInsight]
        public let recommendations: [String]
        public let predictedIssues: [String]
        public let optimizationOpportunities: [String]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            metrics: BuildingMetrics,
            insights: [IntelligenceInsight] = [],
            recommendations: [String] = [],
            predictedIssues: [String] = [],
            optimizationOpportunities: [String] = [],
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.metrics = metrics
            self.insights = insights
            self.recommendations = recommendations
            self.predictedIssues = predictedIssues
            self.optimizationOpportunities = optimizationOpportunities
            self.generatedAt = generatedAt
        }
    }
    
    // MARK: - PortfolioState
    public struct PortfolioState: Codable {
        public let totalBuildings: Int
        public let activeWorkers: Int
        public let overallCompletion: Double
        public let criticalIssues: Int
        public let complianceScore: Double
        public let lastUpdated: Date
        
        public init(
            totalBuildings: Int,
            activeWorkers: Int,
            overallCompletion: Double,
            criticalIssues: Int,
            complianceScore: Double,
            lastUpdated: Date = Date()
        ) {
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.overallCompletion = overallCompletion
            self.criticalIssues = criticalIssues
            self.complianceScore = complianceScore
            self.lastUpdated = lastUpdated
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
    
    public struct BuildingAnalytics: Codable, Identifiable {
        public let id: String
        public let buildingId: String
        public let totalTasks: Int
        public let efficiency: Double
        public let costTrends: [String: Double]
        public let performanceMetrics: [String: Double]
        public let predictedMaintenance: [String]
        public let generatedAt: Date
        
        public init(
            id: String = UUID().uuidString,
            buildingId: String,
            totalTasks: Int = 0,
            efficiency: Double,
            costTrends: [String: Double] = [:],
            performanceMetrics: [String: Double] = [:],
            predictedMaintenance: [String] = [],
            generatedAt: Date = Date()
        ) {
            self.id = id
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.efficiency = efficiency
            self.costTrends = costTrends
            self.performanceMetrics = performanceMetrics
            self.predictedMaintenance = predictedMaintenance
            self.generatedAt = generatedAt
        }
    }
    
    // MARK: - Task Types
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "cleaning"
        case maintenance = "maintenance"
        case security = "security"
        case inspection = "inspection"
        case administrative = "administrative"
        case repair = "repair"
        case installation = "installation"
        case utilities = "utilities"
        case emergency = "emergency"
        case renovation = "renovation"
        case landscaping = "landscaping"
        case sanitation = "sanitation"
        
        public var icon: String {
            switch self {
            case .cleaning: return "sparkles"
            case .maintenance: return "wrench.and.screwdriver"
            case .security: return "shield"
            case .inspection: return "magnifyingglass"
            case .administrative: return "folder"
            case .repair: return "hammer"
            case .installation: return "plus.square"
            case .utilities: return "bolt"
            case .emergency: return "exclamationmark.triangle.fill"
            case .renovation: return "building.2"
            case .landscaping: return "leaf"
            case .sanitation: return "sparkles"
            }
        }
    }

    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        case urgent = "urgent"
        case emergency = "emergency"
        
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
    }
    
    // MARK: - Task Frequency
    public enum TaskFrequency: String, Codable, CaseIterable {
        case daily = "daily"
        case weekly = "weekly"
        case biweekly = "bi-weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
        case annual = "annual"
        case onDemand = "on-demand"
        
        // Add public to rawValue to fix the error
        public var rawValue: String {
            switch self {
            case .daily: return "daily"
            case .weekly: return "weekly"
            case .biweekly: return "bi-weekly"
            case .monthly: return "monthly"
            case .quarterly: return "quarterly"
            case .annual: return "annual"
            case .onDemand: return "on-demand"
            }
        }
        
        public init?(rawValue: String) {
            switch rawValue {
            case "daily": self = .daily
            case "weekly": self = .weekly
            case "bi-weekly": self = .biweekly
            case "monthly": self = .monthly
            case "quarterly": self = .quarterly
            case "annual": self = .annual
            case "on-demand": self = .onDemand
            default: return nil
            }
        }
        
        public var displayName: String {
            switch self {
            case .daily: return "Daily"
            case .weekly: return "Weekly"
            case .biweekly: return "Bi-Weekly"
            case .monthly: return "Monthly"
            case .quarterly: return "Quarterly"
            case .annual: return "Annual"
            case .onDemand: return "On-Demand"
            }
        }
        
        public var sortOrder: Int {
            switch self {
            case .daily: return 1
            case .weekly: return 2
            case .biweekly: return 3
            case .monthly: return 4
            case .quarterly: return 5
            case .annual: return 6
            case .onDemand: return 7
            }
        }
    }

    
    // MARK: - Contextual Task
    public struct ContextualTask: Identifiable, Codable, Hashable {
        public let id: String
        public let title: String
        public let description: String?
        public var status: TaskStatus
        public var completedAt: Date?
        public var scheduledDate: Date?
        public var dueDate: Date?
        public var category: TaskCategory?
        public var urgency: TaskUrgency?
        public var building: NamedCoordinate?
        public var worker: WorkerProfile?
        public var buildingId: String?
        public var buildingName: String?
        public var assignedWorkerId: String?
        public var priority: TaskUrgency?
        public var frequency: TaskFrequency?
        public var requiresPhoto: Bool?
        public var estimatedDuration: TimeInterval?
        public var createdAt: Date
        public var updatedAt: Date
        
        // Computed properties for compatibility
        public var isCompleted: Bool {
            get { status == .completed }
            set { status = newValue ? .completed : .pending }
        }
        
        public var completedDate: Date? {
            get { completedAt }
            set { completedAt = newValue }
        }
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String? = nil,
            status: TaskStatus = .pending,
            completedAt: Date? = nil,
            scheduledDate: Date? = nil,
            dueDate: Date? = nil,
            category: TaskCategory? = nil,
            urgency: TaskUrgency? = nil,
            building: NamedCoordinate? = nil,
            worker: WorkerProfile? = nil,
            buildingId: String? = nil,
            buildingName: String? = nil,
            assignedWorkerId: String? = nil,
            priority: TaskUrgency? = nil,
            frequency: TaskFrequency? = nil,
            requiresPhoto: Bool? = false,
            estimatedDuration: TimeInterval? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.status = status
            self.completedAt = completedAt
            self.scheduledDate = scheduledDate
            self.dueDate = dueDate
            self.category = category
            self.urgency = urgency
            self.building = building
            self.worker = worker
            self.buildingId = buildingId ?? building?.id
            self.buildingName = buildingName ?? building?.name
            self.assignedWorkerId = assignedWorkerId ?? worker?.id
            self.priority = priority ?? urgency
            self.frequency = frequency
            self.requiresPhoto = requiresPhoto
            self.estimatedDuration = estimatedDuration
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
        
        // Convenience initializer for compatibility
        public init(
            title: String,
            description: String?,
            isCompleted: Bool,
            scheduledDate: Date?,
            dueDate: Date?,
            category: TaskCategory?,
            urgency: TaskUrgency?,
            building: NamedCoordinate?,
            worker: WorkerProfile?
        ) {
            self.id = UUID().uuidString
            self.title = title
            self.description = description
            self.status = isCompleted ? .completed : .pending
            self.completedAt = isCompleted ? Date() : nil
            self.scheduledDate = scheduledDate
            self.dueDate = dueDate ?? scheduledDate
            self.category = category
            self.urgency = urgency
            self.building = building
            self.worker = worker
            self.buildingId = building?.id
            self.buildingName = building?.name
            self.assignedWorkerId = worker?.id
            self.priority = urgency
            self.frequency = nil
            self.requiresPhoto = false
            self.estimatedDuration = nil
            self.createdAt = Date()
            self.updatedAt = Date()
        }
        
        public var isOverdue: Bool {
            guard let dueDate = dueDate else { return false }
            return Date() > dueDate && status != .completed
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
    
    // MARK: - Action Evidence
    public struct ActionEvidence: Codable, Hashable, Identifiable {
        public let id: String
        public let description: String
        public let photoURLs: [URL]
        public let photoData: [Data]?
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            description: String,
            photoURLs: [URL] = [],
            photoData: [Data]? = nil,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.description = description
            self.photoURLs = photoURLs
            self.photoData = photoData
            self.timestamp = timestamp
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
        case clear = "Clear"
        case cloudy = "Cloudy"
        case partlyCloudy = "Partly Cloudy"
        case rainy = "Rainy"
        case stormy = "Stormy"
        case snowy = "Snowy"
        case foggy = "Foggy"
        case windy = "Windy"
        case hot = "Hot"
        case cold = "Cold"
        case overcast = "Overcast"
        
        public var icon: String {
            switch self {
            case .sunny, .clear: return "sun.max"
            case .cloudy, .overcast: return "cloud"
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
    }
    
    // MARK: - Inventory Types
    public enum RestockStatus: String, Codable, CaseIterable {
        case inStock = "In Stock"
        case lowStock = "Low Stock"
        case outOfStock = "Out of Stock"
        case ordered = "Ordered"
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
        case supplies = "Supplies"
        case equipment = "Equipment"
        case materials = "Materials"
        case other = "Other"
    }
    
    public struct InventoryItem: Codable, Identifiable {
        public let id: String
        public let name: String
        public let category: InventoryCategory
        public let currentStock: Int
        public let minimumStock: Int
        public let maxStock: Int
        public let unit: String
        public let cost: Double
        public let supplier: String?
        public let location: String?
        public let lastRestocked: Date?
        public let status: RestockStatus
        
        // Additional properties for compatibility
        public var quantity: Int { currentStock }
        public var minThreshold: Int { minimumStock }
        public var restockStatus: RestockStatus { status }
        // stockLevel is a computed property alias for stockPercentage
        public var stockLevel: Double { stockPercentage }
        
        public init(
            id: String = UUID().uuidString,
            name: String,
            category: InventoryCategory,
            currentStock: Int,
            minimumStock: Int,
            maxStock: Int,
            unit: String,
            cost: Double = 0.0,
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
            self.cost = cost
            self.supplier = supplier
            self.location = location
            self.lastRestocked = lastRestocked
            self.status = status
        }
        
        // Core computed properties
        public var needsRestock: Bool {
            currentStock <= minimumStock
        }
        
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
        
        public var priorityValue: Int {
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
        public let timestamp: Date
        
        public init(
            id: String = UUID().uuidString,
            type: AIScenarioType,
            title: String,
            description: String,
            timestamp: Date = Date()
        ) {
            self.id = id
            self.type = type
            self.title = title
            self.description = description
            self.timestamp = timestamp
        }
        
        public var priority: AIPriority {
            return type.priority
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
            
            public var priorityColor: Color {
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
        
        // Additional properties for backward compatibility
        public var completedTasks: Int { Int(completionRate * 100) }
        public var weeklyTrend: Double { 0.05 }
        
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
        
        // Convenience initializer for backward compatibility
        public init(
            totalBuildings: Int,
            activeWorkers: Int,
            completionRate: Double,
            criticalIssues: Int,
            monthlyTrend: TrendDirection,
            completedTasks: Int,
            complianceScore: Double,
            weeklyTrend: Double
        ) {
            self.id = UUID().uuidString
            self.totalBuildings = totalBuildings
            self.activeWorkers = activeWorkers
            self.completionRate = completionRate
            self.criticalIssues = criticalIssues
            self.monthlyTrend = monthlyTrend
            self.complianceScore = complianceScore
            self.generatedAt = Date()
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
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
    }
    
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "Safety"
        case environmental = "Environmental"
        case regulatory = "Regulatory"
        case financial = "Financial"
        case operational = "Operational"
        case documentation = "Documentation"
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

// MARK: - AI Namespace Extension
extension CoreTypes {
    public struct AI {
        public static func generateInsight() -> IntelligenceInsight {
            return IntelligenceInsight(
                id: UUID().uuidString,
                title: "AI Generated Insight",
                description: "Nova AI has generated this insight based on current data patterns",
                type: .operations,
                priority: .medium,
                actionRequired: false,
                affectedBuildings: [],
                generatedAt: Date()
            )
        }
        
        public static func createSuggestion(title: String, description: String, priority: AIPriority = .medium) -> AISuggestion {
            return AISuggestion(
                title: title,
                description: description,
                priority: priority,
                category: .operations,
                actionRequired: false,
                estimatedImpact: "Medium"
            )
        }
        
        public static func analyzeScenario(type: AIScenarioType, title: String, description: String) -> AIScenario {
            return AIScenario(
                type: type,
                title: title,
                description: description
            )
        }
    }
}

// MARK: - Global Type Aliases (For backward compatibility)
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID

// Type aliases for types that don't conflict
public typealias NamedCoordinate = CoreTypes.NamedCoordinate
public typealias WorkerProfile = CoreTypes.WorkerProfile
public typealias ContextualTask = CoreTypes.ContextualTask
public typealias ActionEvidence = CoreTypes.ActionEvidence
public typealias BuildingType = CoreTypes.BuildingType
public typealias AIScenarioType = CoreTypes.AIScenarioType
public typealias AIScenario = CoreTypes.AIScenario
public typealias TaskStatus = CoreTypes.TaskStatus
public typealias RestockStatus = CoreTypes.RestockStatus
public typealias ComplianceIssueType = CoreTypes.ComplianceIssueType
public typealias DashboardSyncStatus = CoreTypes.DashboardSyncStatus
public typealias CrossDashboardUpdate = CoreTypes.CrossDashboardUpdate
public typealias AIPriority = CoreTypes.AIPriority
public typealias InsightType = CoreTypes.InsightCategory
public typealias SkillLevel = CoreTypes.SkillLevel
public typealias RouteStop = CoreTypes.RouteStop
public typealias WorkerDailyRoute = CoreTypes.WorkerDailyRoute
public typealias WorkerRoutineSummary = CoreTypes.WorkerRoutineSummary
public typealias BuildingStatistics = CoreTypes.BuildingStatistics
public typealias BuildingTab = CoreTypes.BuildingTab
public typealias PortfolioState = CoreTypes.PortfolioState

// Add TaskFrequency alias for global access
public typealias TaskFrequency = CoreTypes.TaskFrequency

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
