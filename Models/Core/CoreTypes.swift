//
//  CoreTypes.swift
//  FrancoSphere v6.0 - SINGLE SOURCE OF TRUTH
//
//  🚨 CRITICAL FIX: Single definitions for all types to prevent ambiguity
//  ✅ FIXED: All duplicate type declarations resolved
//  ✅ ENHANCED: Complete protocol conformance for all types
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

// MARK: - CoreTypes Namespace (Single Source of Truth)
public struct CoreTypes {
    
    // MARK: - Core ID Types
    public typealias WorkerID = String
    public typealias BuildingID = String
    public typealias TaskID = String
    public typealias AssignmentID = String
    public typealias RoleID = String
    
    // MARK: - Task Enums (DEFINITIVE DEFINITIONS)
    public enum TaskCategory: String, Codable, CaseIterable, Hashable {
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
        
        public var icon: String {
            switch self {
            case .maintenance: return "wrench.and.screwdriver"
            case .cleaning: return "sparkles"
            case .inspection: return "magnifyingglass"
            case .repair: return "hammer"
            case .security: return "lock.shield"
            case .landscaping: return "leaf"
            case .utilities: return "bolt"
            case .emergency: return "exclamationmark.triangle.fill"
            case .renovation: return "building.2"
            case .installation: return "plus.square"
            case .sanitation: return "trash"
            }
        }
    }
    
    public enum TaskUrgency: String, Codable, CaseIterable, Hashable {
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
    }
    
    // MARK: - User Types
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
        
        public var icon: String {
            switch self {
            case .clear: return "sun.max"
            case .sunny: return "sun.max.fill"
            case .cloudy: return "cloud"
            case .rainy: return "cloud.rain"
            case .snowy: return "cloud.snow"
            case .stormy: return "cloud.bolt"
            case .foggy: return "cloud.fog"
            case .windy: return "wind"
            case .partlyCloudy: return "cloud.sun"
            case .overcast: return "cloud.fill"
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
        
        public var icon: String {
            switch self {
            case .performance: return "chart.line.uptrend.xyaxis"
            case .maintenance: return "wrench.and.screwdriver"
            case .efficiency: return "speedometer"
            case .compliance: return "checkmark.shield"
            case .cost: return "dollarsign.circle"
            }
        }
        
        public var color: Color {
            switch self {
            case .performance: return .blue
            case .maintenance: return .orange
            case .efficiency: return .green
            case .compliance: return .purple
            case .cost: return .red
            }
        }
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
    
    // MARK: - Intelligence Insight
    public struct IntelligenceInsight: Identifiable, Codable, Hashable, Equatable {
        public let id: String
        public let title: String
        public let description: String
        public let type: InsightType
        public let priority: InsightPriority
        public let actionRequired: Bool
        public let timestamp: Date
        public let affectedBuildings: [String]
        
        public init(
            id: String = UUID().uuidString,
            title: String,
            description: String,
            type: InsightType,
            priority: InsightPriority,
            actionRequired: Bool = false,
            timestamp: Date = Date(),
            affectedBuildings: [String] = []
        ) {
            self.id = id
            self.title = title
            self.description = description
            self.type = type
            self.priority = priority
            self.actionRequired = actionRequired
            self.timestamp = timestamp
            self.affectedBuildings = affectedBuildings
        }
        
        // MARK: - Equatable Conformance
        public static func == (lhs: IntelligenceInsight, rhs: IntelligenceInsight) -> Bool {
            return lhs.id == rhs.id
        }
        
        // MARK: - Hashable Conformance
        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    // MARK: - Portfolio Intelligence
    public struct PortfolioIntelligence: Codable, Hashable {
        public let complianceScore: Double
        public let overallEfficiency: Double
        public let criticalIssues: Int
        public let totalBuildings: Int
        public let lastUpdated: Date
        
        public init(
            complianceScore: Double,
            overallEfficiency: Double, 
            criticalIssues: Int,
            totalBuildings: Int,
            lastUpdated: Date = Date()
        ) {
            self.complianceScore = complianceScore
            self.overallEfficiency = overallEfficiency
            self.criticalIssues = criticalIssues
            self.totalBuildings = totalBuildings
            self.lastUpdated = lastUpdated
        }
    }
    
    // MARK: - Task Progress
    public struct TaskProgress: Codable, Hashable {
        public let totalTasks: Int
        public let completedTasks: Int
        public let percentage: Double
        
        public init(totalTasks: Int, completedTasks: Int, percentage: Double) {
            self.totalTasks = totalTasks
            self.completedTasks = completedTasks
            self.percentage = percentage
        }
    }
    
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
}

// MARK: - Global Type Aliases (DEFINITIVE - USE THESE EVERYWHERE)
public typealias TaskCategory = CoreTypes.TaskCategory
public typealias TaskUrgency = CoreTypes.TaskUrgency
public typealias WeatherCondition = CoreTypes.WeatherCondition
public typealias WorkerStatus = CoreTypes.WorkerStatus
public typealias WorkerSkill = CoreTypes.WorkerSkill
public typealias InsightType = CoreTypes.InsightType
public typealias InsightPriority = CoreTypes.InsightPriority
public typealias IntelligenceInsight = CoreTypes.IntelligenceInsight
public typealias PortfolioIntelligence = CoreTypes.PortfolioIntelligence
public typealias TaskProgress = CoreTypes.TaskProgress

// MARK: - ID Type Aliases
public typealias WorkerID = CoreTypes.WorkerID
public typealias BuildingID = CoreTypes.BuildingID
public typealias TaskID = CoreTypes.TaskID
public typealias AssignmentID = CoreTypes.AssignmentID
public typealias RoleID = CoreTypes.RoleID
