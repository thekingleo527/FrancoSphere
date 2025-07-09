//
//  CoreTypes.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: All type definitions and protocol conformance
//  ✅ FIXED: All syntax errors and missing types
//  ✅ ADDED: PortfolioIntelligence and all missing definitions
//

import Foundation
import CoreLocation
import SwiftUI

public struct CoreTypes {
    // CRITICAL: All IDs are String to match database
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // User model to replace scattered auth properties
    public struct User: Codable, Hashable {
        public let workerId: WorkerID
        public let name: String
        public let email: String
        public let role: String
        
        // Computed properties for compatibility
        public var isAdmin: Bool { role == "admin" }
        public var isWorker: Bool { role == "worker" }
        public var displayName: String { name }
        
        public init(workerId: WorkerID, name: String, email: String, role: String) {
            self.workerId = workerId
            self.name = name
            self.email = email
            self.role = role
        }
    }
    
    // Building type enum for real-world categorization
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case museum = "Museum"
        case mixedUse = "Mixed Use"
    }
    
    // ✅ FIXED: TrendDirection enum with icon property
    public enum TrendDirection: String, Codable, CaseIterable, Hashable {
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
        
        public var icon: String {  // FIXED: Changed from systemImage to icon
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        public var systemImage: String {  // Keep both for compatibility
            return icon
        }
    }
    
    // ✅ ADDED: Missing PortfolioIntelligence definition
    public struct PortfolioIntelligence: Codable, Hashable {
        public let totalBuildings: Int
        public let totalCompletedTasks: Int
        public let averageComplianceScore: Double
        public let totalActiveWorkers: Int
        public let overallEfficiency: Double
        public let trendDirection: TrendDirection
        
        public init(
            totalBuildings: Int,
            totalCompletedTasks: Int,
            averageComplianceScore: Double,
            totalActiveWorkers: Int,
            overallEfficiency: Double,
            trendDirection: TrendDirection
        ) {
            self.totalBuildings = totalBuildings
            self.totalCompletedTasks = totalCompletedTasks
            self.averageComplianceScore = averageComplianceScore
            self.totalActiveWorkers = totalActiveWorkers
            self.overallEfficiency = overallEfficiency
            self.trendDirection = trendDirection
        }
    }
    
    // ✅ FIXED: TaskProgress with required properties
    public struct TaskProgress: Codable, Hashable {
        public let completed: Int      // Required by HeroStatusCard
        public let total: Int
        public let remaining: Int
        public let percentage: Double
        public let overdueTasks: Int
        
        public init(completed: Int, total: Int, remaining: Int, percentage: Double, overdueTasks: Int) {
            self.completed = completed
            self.total = total
            self.remaining = remaining
            self.percentage = percentage
            self.overdueTasks = overdueTasks
        }
    }
    
    // ✅ FIXED: BuildingAnalytics definition
    public struct BuildingAnalytics: Codable, Hashable {
        public let buildingId: String
        public let completionRate: Double
        public let totalTasks: Int
        public let completedTasks: Int
        public let overdueTasks: Int
        public let activeWorkers: Int
        public let uniqueWorkers: Int
        public let lastUpdate: Date
        
        public init(
            buildingId: String,
            completionRate: Double,
            totalTasks: Int,
            completedTasks: Int,
            overdueTasks: Int,
            activeWorkers: Int,
            uniqueWorkers: Int,
            lastUpdate: Date = Date()
        ) {
            self.buildingId = buildingId
            self.completionRate = completionRate
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.overdueTasks = overdueTasks
            self.activeWorkers = activeWorkers
            self.uniqueWorkers = uniqueWorkers
            self.lastUpdate = lastUpdate
        }
    }
    
    // ✅ FIXED: Intelligence Types
    public enum InsightType: String, Codable, CaseIterable {
        case performance, maintenance, compliance, efficiency, cost, safety
        
        public var icon: String {
            switch self {
            case .performance: return "chart.line.uptrend.xyaxis"
            case .maintenance: return "wrench.and.screwdriver"
            case .compliance: return "checkmark.shield"
            case .efficiency: return "speedometer"
            case .safety: return "shield.lefthalf.filled"
            case .cost: return "dollarsign.circle"
            }
        }
        
        public var color: Color {
            switch self {
            case .performance: return .blue
            case .maintenance: return .orange
            case .compliance: return .green
            case .efficiency: return .purple
            case .safety: return .red
            case .cost: return .yellow
            }
        }
    }
    
    public enum InsightPriority: String, Codable, CaseIterable {
        case low, medium, high, critical
        
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
    
    // ✅ ADDED: IntelligenceInsight definition
    public struct IntelligenceInsight: Identifiable, Codable, Hashable {
        public let id = UUID()
        public let title: String
        public let description: String
        public let type: InsightType
        public let priority: InsightPriority
        public let actionable: Bool
        public let timestamp: Date
        
        public init(
            title: String,
            description: String,
            type: InsightType,
            priority: InsightPriority,
            actionable: Bool,
            timestamp: Date = Date()
        ) {
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionable = actionable
            self.timestamp = timestamp
        }
    }
    
    // ✅ ADDED: Building Status & Types
    public enum BuildingStatus: String, Codable, CaseIterable {
        case operational, maintenance, emergency, offline
    }
    
    public enum BuildingTab: String, CaseIterable {
        case overview, tasks, maintenance, compliance, workers
    }
    
    public struct BuildingInsight: Identifiable, Codable, Hashable {
        public let id = UUID()
        public let buildingId: String
        public let title: String
        public let description: String
        public let type: InsightType
        public let actionRequired: Bool
        public let generatedAt: Date
        
        public init(
            buildingId: String,
            type: InsightType,
            title: String,
            description: String,
            actionRequired: Bool,
            generatedAt: Date = Date()
        ) {
            self.buildingId = buildingId
            self.type = type
            self.title = title
            self.description = description
            self.actionRequired = actionRequired
            self.generatedAt = generatedAt
        }
    }
    
    // ✅ ADDED: InsightFilter definition
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
    
    // ✅ FIXED: PerformanceMetrics
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
    
    // ✅ FIXED: BuildingStatistics
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
    
    // ✅ FIXED: TaskTrends
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
}

// ✅ FIXED: ComplianceStatus (single definition)
public enum ComplianceStatus: String, Codable {
    case compliant = "Compliant"
    case needsReview = "Needs Review"
    case atRisk = "At Risk"
}

// ✅ Global type aliases for compatibility
public typealias TaskProgress = CoreTypes.TaskProgress
public typealias PortfolioIntelligence = CoreTypes.PortfolioIntelligence
public typealias BuildingAnalytics = CoreTypes.BuildingAnalytics
public typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
public typealias TrendDirection = CoreTypes.TrendDirection
public typealias BuildingStatus = CoreTypes.BuildingStatus
public typealias BuildingTab = CoreTypes.BuildingTab
public typealias InsightType = CoreTypes.InsightType
public typealias InsightPriority = CoreTypes.InsightPriority
