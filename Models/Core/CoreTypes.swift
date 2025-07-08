//
//  CoreTypes.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  CoreTypes.swift
//  FrancoSphere
//
//  🎯 PHASE 0.1: FOUNDATIONAL TYPE SYSTEM
//  ✅ Provides all type aliases used throughout the app
//  ✅ Centralizes User model for auth consistency  
//  ✅ Defines building categorization for intelligence
//  ✅ Must be created FIRST - everything depends on this
//

import Foundation
import CoreLocation

/// Central namespace for all core type definitions used throughout FrancoSphere
public struct CoreTypes {
    
    // MARK: - ID Type Aliases
    // CRITICAL: All IDs are String to match SQLite database schema
    
    /// Worker identifier - maps to workers.id in database
    public typealias WorkerID = String
    
    /// Building identifier - maps to buildings.id in database  
    public typealias BuildingID = String
    
    /// Task identifier - maps to AllTasks.id in database
    public typealias TaskID = String
    
    /// Assignment identifier - maps to worker_building_assignments.id
    public typealias AssignmentID = String
    
    /// Role identifier for worker roles and permissions
    public typealias RoleID = String
    
    // MARK: - User Model
    // Replaces scattered auth properties across ViewModels
    
    /// Unified user model for authentication and authorization
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
        
        // MARK: - Computed Properties for Compatibility
        
        /// Admin role check for dashboard access control
        public var isAdmin: Bool { 
            role.lowercased() == "admin" || role.lowercased() == "supervisor" 
        }
        
        /// Worker role check for worker dashboard access
        public var isWorker: Bool { 
            role.lowercased() == "worker" || role.lowercased() == "maintenance"
        }
        
        /// Client role check for client dashboard access
        public var isClient: Bool {
            role.lowercased() == "client" || role.lowercased() == "property_manager"
        }
        
        /// Display name for UI components
        public var displayName: String { name }
        
        /// Email for notifications and communication
        public var emailAddress: String { email }
    }
    
    // MARK: - Building Classification
    // Used for intelligence calculations and compliance requirements
    
    /// Building type enumeration for real-world categorization
    public enum BuildingType: String, Codable, CaseIterable {
        case residential = "Residential"
        case commercial = "Commercial"
        case museum = "Museum"          // For Rubin Museum of Art
        case mixedUse = "Mixed Use"
        case retail = "Retail"
        case office = "Office"
        
        /// Compliance requirements based on building type
        public var complianceRequirements: [String] {
            switch self {
            case .museum:
                return ["Fire Safety", "HVAC Climate Control", "Security Systems", "ADA Compliance"]
            case .residential:
                return ["Habitability Standards", "Fire Safety", "Building Maintenance"]
            case .commercial, .office:
                return ["Fire Safety", "ADA Compliance", "HVAC Systems", "Elevator Maintenance"]
            case .mixedUse:
                return ["Fire Safety", "ADA Compliance", "Mixed-Use Zoning", "HVAC Systems"]
            case .retail:
                return ["Fire Safety", "ADA Compliance", "Customer Safety", "HVAC Systems"]
            }
        }
        
        /// Estimated maintenance frequency (in days)
        public var maintenanceFrequency: Int {
            switch self {
            case .museum: return 7      // Weekly (high standards)
            case .residential: return 30    // Monthly
            case .commercial, .office: return 14    // Bi-weekly
            case .mixedUse: return 21       // Every 3 weeks
            case .retail: return 14         // Bi-weekly
            }
        }
    }
    
    // MARK: - Status Enumerations
    
    /// Worker availability and operational status
    public enum WorkerStatus: String, Codable, CaseIterable {
        case available = "Available"
        case clockedIn = "Clocked In"
        case onBreak = "On Break"
        case offDuty = "Off Duty"
        case onVacation = "On Vacation"
        case sick = "Sick Leave"
        
        /// Status color for UI indicators
        public var statusColor: String {
            switch self {
            case .available: return "green"
            case .clockedIn: return "blue"
            case .onBreak: return "orange"
            case .offDuty: return "gray"
            case .onVacation, .sick: return "red"
            }
        }
    }
    
    /// Task completion and verification status
    public enum TaskStatus: String, Codable, CaseIterable {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
        case verified = "Verified"
        case rejected = "Rejected"
        case overdue = "Overdue"
        
        /// Priority level for task status
        public var priority: Int {
            switch self {
            case .overdue: return 5
            case .rejected: return 4
            case .inProgress: return 3
            case .pending: return 2
            case .completed: return 1
            case .verified: return 0
            }
        }
    }
    
    // MARK: - Real-World Building Data
    // Based on actual NYC properties in the system
    
    /// Known building mappings for image assets and real data
    public static let buildingAssetMappings: [BuildingID: String] = [
        "14": "Rubin_Museum_142_148_West_17th_Street",
        "13": "104_Franklin_Street", 
        "7": "136_West_17th_Street",
        "1": "12_West_18th_Street",
        "2": "Building_Placeholder",
        "3": "Building_Placeholder"
    ]
    
    /// Building type mappings for known properties  
    public static let buildingTypeMappings: [BuildingID: BuildingType] = [
        "14": .museum,              // Rubin Museum of Art
        "13": .residential,         // 104 Franklin Street
        "7": .commercial,           // 136 West 17th Street  
        "1": .commercial,           // 12 West 18th Street
        "2": .mixedUse,
        "3": .retail
    ]
    
    /// NYC building construction years (for compliance calculations)
    public static let buildingYearBuilt: [BuildingID: Int] = [
        "14": 1920,     // Rubin Museum
        "13": 1881,     // 104 Franklin Street
        "7": 1915,      // 136 West 17th Street
        "1": 1910,      // 12 West 18th Street
        "2": 1950,
        "3": 1960
    ]
    
    // MARK: - Utility Methods
    
    /// Get building type for a given building ID
    public static func buildingType(for buildingId: BuildingID) -> BuildingType {
        return buildingTypeMappings[buildingId] ?? .mixedUse
    }
    
    /// Get asset name for building image
    public static func buildingAsset(for buildingId: BuildingID) -> String {
        return buildingAssetMappings[buildingId] ?? "building_placeholder"
    }
    
    /// Get construction year for building
    public static func yearBuilt(for buildingId: BuildingID) -> Int {
        return buildingYearBuilt[buildingId] ?? 1950
    }
    
    /// Calculate building age for compliance assessments
    public static func buildingAge(for buildingId: BuildingID) -> Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - yearBuilt(for: buildingId)
    }
}