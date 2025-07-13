//
//  CoreTypes.swift
//  FrancoSphere
//
//  ✅ CRITICAL: Foundation type system that everything depends on
//  ✅ All type aliases, User model, and core enums
//  ✅ Building types, trend directions, and analytics structures
//  ✅ Must be created first - everything else imports from here
//

import Foundation
import CoreLocation

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
        
        // Computed properties for compatibility
        public var isAdmin: Bool { role == "admin" }
        public var isWorker: Bool { role == "worker" }
        public var displayName: String { name }
    }
    
    // MARK: - Building Type Classification
    public enum BuildingType: String, Codable, CaseIterable, Hashable {
        case residential = "Residential"
        case commercial = "Commercial"
        case museum = "Museum"      // For Rubin Museum
        case cultural = "Cultural"
        case mixedUse = "Mixed Use"
        case retail = "Retail"
        
        public var displayName: String { rawValue }
        
        public var iconName: String {
            switch self {
            case .residential: return "house.fill"
            case .commercial: return "building.2.fill"
            case .museum, .cultural: return "building.columns.fill"
            case .mixedUse: return "building.fill"
            case .retail: return "storefront.fill"
            }
        }
    }
    
    // MARK: - Trend Direction for Analytics
    public enum TrendDirection: String, Codable, CaseIterable, Hashable {
        case improving = "improving"
        case declining = "declining"
        case stable = "stable"
        case unknown = "unknown"
        
        public var displayName: String {
            switch self {
            case .improving: return "Improving"
            case .declining: return "Declining"
            case .stable: return "Stable"
            case .unknown: return "Unknown"
            }
        }
        
        public var systemImage: String {
            switch self {
            case .improving: return "arrow.up.circle.fill"
            case .declining: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        public var color: String {
            switch self {
            case .improving: return "green"
            case .declining: return "red"
            case .stable: return "blue"
            case .unknown: return "gray"
            }
        }
    }
    
    // MARK: - Building Analytics Structure
    public struct BuildingAnalytics: Codable, Hashable {
        public let buildingId: BuildingID
        public let totalTasks: Int
        public let completedTasks: Int
        public let overdueTasks: Int
        public let uniqueWorkers: Int
        public let completionRate: Double
        public let averageTasksPerDay: Double
        public let periodDays: Int
        
        public init(
            buildingId: BuildingID,
            totalTasks: Int,
            completedTasks: Int,
            overdueTasks: Int,
            uniqueWorkers: Int,
            completionRate: Double,
            averageTasksPerDay: Double,
            periodDays: Int
        ) {
            self.buildingId = buildingId
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.overdueTasks = overdueTasks
            self.uniqueWorkers = uniqueWorkers
            self.completionRate = completionRate
            self.averageTasksPerDay = averageTasksPerDay
            self.periodDays = periodDays
        }
        
        // Factory method for empty analytics
        public static func empty(buildingId: BuildingID) -> BuildingAnalytics {
            return BuildingAnalytics(
                buildingId: buildingId,
                totalTasks: 0,
                completedTasks: 0,
                overdueTasks: 0,
                uniqueWorkers: 0,
                completionRate: 0.0,
                averageTasksPerDay: 0.0,
                periodDays: 30
            )
        }
        
        // Computed properties
        public var pendingTasks: Int { totalTasks - completedTasks }
        public var completionPercentage: Int { Int(completionRate * 100) }
        public var isPerformingWell: Bool { completionRate >= 0.8 && overdueTasks == 0 }
    }
    
    // MARK: - Building Statistics for Dashboard
    public struct BuildingStatistics: Codable, Hashable {
        public let buildingId: BuildingID
        public let completionRate: Double
        public let tasksCompleted: Int
        public let totalTasks: Int
        public let averageCompletionTime: TimeInterval
        public let trend: TrendDirection
        
        public init(
            buildingId: BuildingID,
            completionRate: Double,
            tasksCompleted: Int,
            totalTasks: Int,
            averageCompletionTime: TimeInterval,
            trend: TrendDirection
        ) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.tasksCompleted = tasksCompleted
            self.totalTasks = totalTasks
            self.averageCompletionTime = averageCompletionTime
            self.trend = trend
        }
        
        // Computed properties
        public var completionPercentage: Int { Int(completionRate * 100) }
        public var pendingTasks: Int { totalTasks - tasksCompleted }
        public var isHealthy: Bool { completionRate >= 0.8 }
    }
    
    // MARK: - Task Trends for Analytics
    public struct TaskTrends: Codable, Hashable {
        public let dailyCompletions: [Int]
        public let weeklyCompletions: [Int]
        public let monthlyCompletions: [Int]
        public let overallTrend: TrendDirection
        
        public init(
            dailyCompletions: [Int],
            weeklyCompletions: [Int],
            monthlyCompletions: [Int],
            overallTrend: TrendDirection
        ) {
            self.dailyCompletions = dailyCompletions
            self.weeklyCompletions = weeklyCompletions
            self.monthlyCompletions = monthlyCompletions
            self.overallTrend = overallTrend
        }
        
        // Empty factory method
        public static var empty: TaskTrends {
            return TaskTrends(
                dailyCompletions: [],
                weeklyCompletions: [],
                monthlyCompletions: [],
                overallTrend: .unknown
            )
        }
    }
    
    // MARK: - Worker Status
    public enum WorkerStatus: String, Codable, CaseIterable {
        case available = "available"
        case clockedIn = "clocked_in"
        case onBreak = "on_break"
        case offDuty = "off_duty"
        
        public var displayName: String {
            switch self {
            case .available: return "Available"
            case .clockedIn: return "Clocked In"
            case .onBreak: return "On Break"
            case .offDuty: return "Off Duty"
            }
        }
        
        public var color: String {
            switch self {
            case .available: return "green"
            case .clockedIn: return "blue"
            case .onBreak: return "orange"
            case .offDuty: return "gray"
            }
        }
    }
    
    // MARK: - Maintenance Priority
    public enum MaintenancePriority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
        
        public var displayName: String {
            switch self {
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .critical: return "Critical"
            }
        }
        
        public var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
    }
}

// MARK: - Legacy Compatibility Extensions

// Ensure backward compatibility with existing code
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias BuildingAnalytics = CoreTypes.BuildingAnalytics
public typealias BuildingStatistics = CoreTypes.BuildingStatistics
public typealias TaskTrends = CoreTypes.TaskTrends
public typealias TrendDirection = CoreTypes.TrendDirection
