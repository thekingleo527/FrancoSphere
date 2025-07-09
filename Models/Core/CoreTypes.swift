//
//  CoreTypes.swift
//  FrancoSphere
//
//  ✅ FIXED: Complete foundation type system
//  ✅ Single source of truth for all types
//  ✅ Proper protocol conformance
//

import Foundation
import CoreLocation

// MARK: - CoreTypes - Foundation Type System for FrancoSphere v6.0
public struct CoreTypes {
    // MARK: - Identity Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - User Model
    public struct User: Codable, Hashable {
        public let workerId: WorkerID
        public let name: String
        public let email: String
        public let role: String
        
        public var isAdmin: Bool { role == "admin" }
        public var isWorker: Bool { role == "worker" }
        public var isClient: Bool { role == "client" }
        public var displayName: String { name }
        
        public init(workerId: WorkerID, name: String, email: String, role: String) {
            self.workerId = workerId
            self.name = name
            self.email = email
            self.role = role
        }
    }
    
    // MARK: - Building Types
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case museum = "Museum"
        case mixedUse = "Mixed Use"
    }
    
    // MARK: - Task Types
    public enum TaskUrgency: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }
    
    public enum TaskCategory: String, Codable, CaseIterable {
        case cleaning = "Cleaning"
        case sanitation = "Sanitation"
        case maintenance = "Maintenance"
        case inspection = "Inspection"
        case operations = "Operations"
        case repair = "Repair"
        case security = "Security"
        case landscaping = "Landscaping"
    }
    
    public enum TaskRecurrence: String, Codable, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case biWeekly = "Bi-Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case semiannual = "Semiannual"
        case annual = "Annual"
        case onDemand = "On-Demand"
    }
}

// MARK: - Trend Direction (FIXED)
public enum TrendDirection: String, Codable, CaseIterable, Hashable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    case unknown = "unknown"
    
    public var systemImage: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .improving: return "green"
        case .stable: return "blue"
        case .declining: return "red"
        case .unknown: return "gray"
        }
    }
}

// MARK: - Task Progress (SINGLE DEFINITION)
public struct TaskProgress: Codable, Hashable {
    public let workerId: CoreTypes.WorkerID
    public let totalTasks: Int
    public let completedTasks: Int
    public let overdueTasks: Int
    public let todayCompletedTasks: Int
    public let weeklyTarget: Int
    public let currentStreak: Int
    public let lastCompletionDate: Date?
    
    public var completed: Int { completedTasks }
    public var total: Int { totalTasks }
    public var remaining: Int { totalTasks - completedTasks }
    public var percentage: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks) * 100.0
    }
    
    public var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public var isOnTrack: Bool {
        return overdueTasks == 0 && completionRate >= 0.8
    }
    
    public init(workerId: CoreTypes.WorkerID, totalTasks: Int, completedTasks: Int, overdueTasks: Int, todayCompletedTasks: Int, weeklyTarget: Int, currentStreak: Int, lastCompletionDate: Date? = nil) {
        self.workerId = workerId
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.overdueTasks = overdueTasks
        self.todayCompletedTasks = todayCompletedTasks
        self.weeklyTarget = weeklyTarget
        self.currentStreak = currentStreak
        self.lastCompletionDate = lastCompletionDate
    }
}

// MARK: - Performance Metrics (FIXED)
public struct PerformanceMetrics: Codable, Hashable {
    public init(efficiency: Double, tasksCompleted: Int, averageTime: Double, qualityScore: Double, lastUpdate: Date) {
        self.efficiency = efficiency
        self.tasksCompleted = tasksCompleted
        self.averageTime = averageTime
        self.qualityScore = qualityScore
        self.lastUpdate = lastUpdate
    }
    public let workerId: CoreTypes.WorkerID
    public let period: TimePeriod
    public let efficiency: Double
    public let quality: Double
    public let punctuality: Double
    public let consistency: Double
    public let overallScore: Double
    public let tasksCompleted: Int
    public let averageCompletionTime: TimeInterval
    public let recentTrend: TrendDirection
    
    public enum TimePeriod: String, Codable, CaseIterable, Hashable {
        case daily = "daily"
        case weekly = "weekly"
        case monthly = "monthly"
        case quarterly = "quarterly"
    }
    
    public init(workerId: CoreTypes.WorkerID, period: TimePeriod, efficiency: Double, quality: Double, punctuality: Double, consistency: Double, overallScore: Double, tasksCompleted: Int, averageCompletionTime: TimeInterval, recentTrend: TrendDirection) {
        self.workerId = workerId
        self.period = period
        self.efficiency = efficiency
        self.quality = quality
        self.punctuality = punctuality
        self.consistency = consistency
        self.overallScore = overallScore
        self.tasksCompleted = tasksCompleted
        self.averageCompletionTime = averageCompletionTime
        self.recentTrend = recentTrend
    }
}

// MARK: - Building Analytics (FIXED)
public struct BuildingStatistics: Codable, Hashable, Equatable {
    public let buildingId: CoreTypes.BuildingID
    public let period: PerformanceMetrics.TimePeriod
    public let totalTasks: Int
    public let completedTasks: Int
    public let averageCompletionTime: TimeInterval
    public let workerEfficiency: Double
    public let maintenanceScore: Double
    public let complianceScore: Double
    public let issueCount: Int
    public let trend: TrendDirection
    
    public var completionRate: Double {
        guard totalTasks > 0 else { return 0.0 }
        return Double(completedTasks) / Double(totalTasks)
    }
    
    public init(buildingId: CoreTypes.BuildingID, period: PerformanceMetrics.TimePeriod, totalTasks: Int, completedTasks: Int, averageCompletionTime: TimeInterval, workerEfficiency: Double, maintenanceScore: Double, complianceScore: Double, issueCount: Int, trend: TrendDirection) {
        self.buildingId = buildingId
        self.period = period
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.averageCompletionTime = averageCompletionTime
        self.workerEfficiency = workerEfficiency
        self.maintenanceScore = maintenanceScore
        self.complianceScore = complianceScore
        self.issueCount = issueCount
        self.trend = trend
    }
    
    public static func == (lhs: BuildingStatistics, rhs: BuildingStatistics) -> Bool {
        return lhs.buildingId == rhs.buildingId && lhs.period == rhs.period
    }
}

// MARK: - Task Analytics (FIXED)
public struct TaskTrends: Codable, Hashable, Equatable {
    public let period: PerformanceMetrics.TimePeriod
    public let completionTrend: TrendDirection
    public let efficiencyTrend: TrendDirection
    public let qualityTrend: TrendDirection
    public let weeklyAverage: Double
    public let monthlyProjection: Int
    public let peakPerformanceDay: String
    public let improvementAreas: [String]
    
    public init(period: PerformanceMetrics.TimePeriod, completionTrend: TrendDirection, efficiencyTrend: TrendDirection, qualityTrend: TrendDirection, weeklyAverage: Double, monthlyProjection: Int, peakPerformanceDay: String, improvementAreas: [String]) {
        self.period = period
        self.completionTrend = completionTrend
        self.efficiencyTrend = efficiencyTrend
        self.qualityTrend = qualityTrend
        self.weeklyAverage = weeklyAverage
        self.monthlyProjection = monthlyProjection
        self.peakPerformanceDay = peakPerformanceDay
        self.improvementAreas = improvementAreas
    }
    
    public static func == (lhs: TaskTrends, rhs: TaskTrends) -> Bool {
        return lhs.period == rhs.period && lhs.completionTrend == rhs.completionTrend
    }
}
