//
//  CoreTypes.swift
//  FrancoSphere v6.0 - MASTER FIXED VERSION
//
//  ✅ ALL TYPES: Complete unified type system
//  ✅ NO CONFLICTS: Single source of truth
//  ✅ PRODUCTION READY: All compilation errors resolved
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - CoreTypes Namespace (Primary Definitions)
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
        
        public init(id: String, workerId: WorkerID, name: String, email: String, role: String) {
            self.id = id
            self.workerId = workerId
            self.name = name
            self.email = email
            self.role = role
        }
    }
    
    // MARK: - AI Types (Unified from all sources)
    public struct AISuggestion: Codable, Hashable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: AIPriority
        public let category: String
        public let estimatedImpact: String
        public let buildingId: BuildingID?
        public let createdAt: Date
        
        public init(id: String, title: String, description: String, priority: AIPriority, category: String, estimatedImpact: String, buildingId: BuildingID? = nil, createdAt: Date = Date()) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
            self.category = category
            self.estimatedImpact = estimatedImpact
            self.buildingId = buildingId
            self.createdAt = createdAt
        }
    }
    
    public enum AIPriority: String, Codable, CaseIterable {
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
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
    
    // MARK: - Compliance Types (Unified)
    public enum ComplianceIssueType: String, Codable, CaseIterable {
        case safety = "safety"
        case environmental = "environmental"
        case accessibility = "accessibility"
        case fire = "fire"
        case health = "health"
        case structural = "structural"
        
        public var displayName: String {
            switch self {
            case .safety: return "Safety"
            case .environmental: return "Environmental"
            case .accessibility: return "Accessibility"
            case .fire: return "Fire Safety"
            case .health: return "Health"
            case .structural: return "Structural"
            }
        }
    }
    
    public enum ComplianceSeverity: String, Codable, CaseIterable {
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
        public let title: String
        public let description: String
        public let buildingId: BuildingID
        public let discoveredAt: Date
        public let resolvedAt: Date?
        public let isResolved: Bool
        
        public init(id: String, type: ComplianceIssueType, severity: ComplianceSeverity, title: String, description: String, buildingId: BuildingID, discoveredAt: Date = Date(), resolvedAt: Date? = nil, isResolved: Bool = false) {
            self.id = id
            self.type = type
            self.severity = severity
            self.title = title
            self.description = description
            self.buildingId = buildingId
            self.discoveredAt = discoveredAt
            self.resolvedAt = resolvedAt
            self.isResolved = isResolved
        }
    }
    
    // MARK: - Intelligence Types
    public struct IntelligenceInsight: Codable, Hashable, Identifiable {
        public let id: String
        public let title: String
        public let description: String
        public let priority: InsightPriority
        public let category: InsightCategory
        public let source: InsightSource
        public let confidence: Double
        public let buildingIds: [BuildingID]
        public let createdAt: Date
        public let expiresAt: Date?
        public let actionable: Bool
        public let estimatedImpact: String
        
        public init(id: String, title: String, description: String, priority: InsightPriority, category: InsightCategory, source: InsightSource, confidence: Double, buildingIds: [BuildingID], createdAt: Date = Date(), expiresAt: Date? = nil, actionable: Bool = true, estimatedImpact: String) {
            self.id = id
            self.title = title
            self.description = description
            self.priority = priority
            self.category = category
            self.source = source
            self.confidence = confidence
            self.buildingIds = buildingIds
            self.createdAt = createdAt
            self.expiresAt = expiresAt
            self.actionable = actionable
            self.estimatedImpact = estimatedImpact
        }
    }
    
    public enum InsightPriority: String, Codable, CaseIterable {
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
        case efficiency = "efficiency"
        case maintenance = "maintenance"
        case compliance = "compliance"
        case cost = "cost"
        case performance = "performance"
        case risk = "risk"
        
        public var displayName: String {
            switch self {
            case .efficiency: return "Efficiency"
            case .maintenance: return "Maintenance"
            case .compliance: return "Compliance"
            case .cost: return "Cost"
            case .performance: return "Performance"
            case .risk: return "Risk"
            }
        }
    }
    
    public enum InsightSource: String, Codable, CaseIterable {
        case ai = "ai"
        case sensor = "sensor"
        case worker = "worker"
        case system = "system"
        case analytics = "analytics"
        
        public var displayName: String {
            switch self {
            case .ai: return "AI Analysis"
            case .sensor: return "Sensor Data"
            case .worker: return "Worker Report"
            case .system: return "System"
            case .analytics: return "Analytics"
            }
        }
    }
    
    // MARK: - Building Metrics Types
    public struct BuildingMetrics: Codable, Hashable {
        public let buildingId: BuildingID
        public let overallScore: Double
        public let efficiencyScore: Double
        public let maintenanceScore: Double
        public let complianceScore: Double
        public let lastUpdated: Date
        public let totalTasks: Int
        public let completedTasks: Int
        public let pendingTasks: Int
        public let overdueTasks: Int
        
        public init(buildingId: BuildingID, overallScore: Double, efficiencyScore: Double, maintenanceScore: Double, complianceScore: Double, lastUpdated: Date = Date(), totalTasks: Int, completedTasks: Int, pendingTasks: Int, overdueTasks: Int) {
            self.buildingId = buildingId
            self.overallScore = overallScore
            self.efficiencyScore = efficiencyScore
            self.maintenanceScore = maintenanceScore
            self.complianceScore = complianceScore
            self.lastUpdated = lastUpdated
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.pendingTasks = pendingTasks
            self.overdueTasks = overdueTasks
        }
        
        public var completionPercentage: Double {
            guard totalTasks > 0 else { return 0 }
            return Double(completedTasks) / Double(totalTasks) * 100
        }
    }
    
    // MARK: - Portfolio Intelligence Types
    public struct PortfolioIntelligence: Codable, Hashable {
        public let totalBuildings: Int
        public let averageScore: Double
        public let totalTasks: Int
        public let completedTasks: Int
        public let pendingIssues: Int
        public let criticalIssues: Int
        public let complianceRate: Double
        public let insights: [IntelligenceInsight]
        public let lastUpdated: Date
        
        public init(totalBuildings: Int, averageScore: Double, totalTasks: Int, completedTasks: Int, pendingIssues: Int, criticalIssues: Int, complianceRate: Double, insights: [IntelligenceInsight], lastUpdated: Date = Date()) {
            self.totalBuildings = totalBuildings
            self.averageScore = averageScore
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.pendingIssues = pendingIssues
            self.criticalIssues = criticalIssues
            self.complianceRate = complianceRate
            self.insights = insights
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Dashboard Sync Types
    public enum DashboardSyncStatus: String, Codable, CaseIterable {
        case synced = "synced"
        case syncing = "syncing"
        case failed = "failed"
        case offline = "offline"
        
        public var displayName: String {
            switch self {
            case .synced: return "Synced"
            case .syncing: return "Syncing"
            case .failed: return "Failed"
            case .offline: return "Offline"
            }
        }
        
        public var color: Color {
            switch self {
            case .synced: return .green
            case .syncing: return .blue
            case .failed: return .red
            case .offline: return .gray
            }
        }
    }
    
    public struct CrossDashboardUpdate: Codable, Hashable, Identifiable {
        public let id: String
        public let type: UpdateType
        public let source: DashboardType
        public let data: String
        public let timestamp: Date
        
        public init(id: String, type: UpdateType, source: DashboardType, data: String, timestamp: Date = Date()) {
            self.id = id
            self.type = type
            self.source = source
            self.data = data
            self.timestamp = timestamp
        }
    }
    
    public enum UpdateType: String, Codable, CaseIterable {
        case taskCompleted = "task_completed"
        case workerAssigned = "worker_assigned"
        case buildingUpdated = "building_updated"
        case complianceIssue = "compliance_issue"
        case aiInsight = "ai_insight"
        
        public var displayName: String {
            switch self {
            case .taskCompleted: return "Task Completed"
            case .workerAssigned: return "Worker Assigned"
            case .buildingUpdated: return "Building Updated"
            case .complianceIssue: return "Compliance Issue"
            case .aiInsight: return "AI Insight"
            }
        }
    }
    
    public enum DashboardType: String, Codable, CaseIterable {
        case worker = "worker"
        case admin = "admin"
        case client = "client"
        
        public var displayName: String {
            switch self {
            case .worker: return "Worker"
            case .admin: return "Admin"
            case .client: return "Client"
            }
        }
    }
    
    // MARK: - Weather Types (Unified)
    public enum WeatherCondition: String, Codable, CaseIterable {
        case clear = "clear"
        case cloudy = "cloudy"
        case rainy = "rainy"
        case stormy = "stormy"
        case snowy = "snowy"
        case foggy = "foggy"
        case windy = "windy"
        case sunny = "sunny"
        
        public var displayName: String {
            switch self {
            case .clear: return "Clear"
            case .cloudy: return "Cloudy"
            case .rainy: return "Rainy"
            case .stormy: return "Stormy"
            case .snowy: return "Snowy"
            case .foggy: return "Foggy"
            case .windy: return "Windy"
            case .sunny: return "Sunny"
            }
        }
        
        public var icon: String {
            switch self {
            case .clear: return "sun.max"
            case .cloudy: return "cloud"
            case .rainy: return "cloud.rain"
            case .stormy: return "cloud.bolt"
            case .snowy: return "cloud.snow"
            case .foggy: return "cloud.fog"
            case .windy: return "wind"
            case .sunny: return "sun.max.fill"
            }
        }
    }
}
