//
//  ModelExtensions.swift
//  FrancoSphere
//
//  Generated extensions for missing properties
//

import SwiftUI

// MARK: - Type Extensions for Missing Properties

extension NamedCoordinate {
    public static var allBuildings: [NamedCoordinate] {
        return [
            NamedCoordinate(id: "1", name: "12 West 18th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7389, longitude: -73.9936)),
            NamedCoordinate(id: "2", name: "29-31 East 20th Street", coordinate: CLLocationCoordinate2D(latitude: 40.7386, longitude: -73.9883)),
            NamedCoordinate(id: "3", name: "36 Walker Street", coordinate: CLLocationCoordinate2D(latitude: 40.7171, longitude: -74.0026)),
            NamedCoordinate(id: "4", name: "41 Elizabeth Street", coordinate: CLLocationCoordinate2D(latitude: 40.7178, longitude: -73.9965)),
            NamedCoordinate(id: "14", name: "Rubin Museum", coordinate: CLLocationCoordinate2D(latitude: 40.7402, longitude: -73.9980))
        ]
    }
    
    public static func getBuilding(id: String) -> NamedCoordinate? {
        return allBuildings.first { $0.id == id }
    }
}

extension TaskCategory {
    public var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench"
        case .inspection: return "eye"
        case .repair: return "hammer"
        case .security: return "shield"
        case .landscaping: return "leaf"
        case .administrative: return "doc"
        case .emergency: return "exclamationmark.triangle"
        case .sanitation: return "trash"
        }
    }
}

extension InventoryCategory {
    public var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench"
        case .safety: return "shield"
        case .office: return "building"
        case .tools: return "hammer"
        case .paint: return "paintbrush"
        case .seasonal: return "snowflake"
        case .other: return "cube"
        }
    }
    
    public var systemImage: String { icon }
}

extension Int {
    public var color: Color {
        switch self {
        case 1: return .blue
        case 2: return .green
        case 3: return .orange
        case 4: return .red
        default: return .gray
        }
    }
    
    public var high: Int { 3 }
    public var medium: Int { 2 }
    public var low: Int { 1 }
}

extension BuildingInsight {
    public var icon: String { "lightbulb" }
    public var color: Color { .yellow }
}

extension AIScenarioData {
    public var message: String { context }
    public var actionText: String { "Take Action" }
    public var icon: String { "sparkles" }
}

extension AISuggestion {
    public var icon: String { "lightbulb" }
}

extension MaintenanceRecord {
    public var taskName: String { description }
    public var completedBy: String { workerId }
}

extension WorkerSkill {
    public var rawValue: String {
        switch self {
        case .basic: return "Basic"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        case .maintenance: return "Maintenance"
        case .electrical: return "Electrical"
        case .plumbing: return "Plumbing"
        case .hvac: return "HVAC"
        case .painting: return "Painting"
        case .carpentry: return "Carpentry"
        case .landscaping: return "Landscaping"
        case .security: return "Security"
        case .specialized: return "Specialized"
        case .cleaning: return "Cleaning"
        case .repair: return "Repair"
        case .inspection: return "Inspection"
        case .sanitation: return "Sanitation"
        }
    }
}

extension RouteStop {
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
    }
    
    public var estimatedTaskDuration: TimeInterval { 3600 }
    public var buildingName: String { location }
    public var tasks: [MaintenanceTask] { [] }
}

extension WorkerDailyRoute {
    public var estimatedDuration: TimeInterval { 28800 } // 8 hours
}

extension WorkerRoutineSummary {
    public var dailyTasks: [MaintenanceTask] { [] }
}

extension WorkerAssignment {
    public var workerName: String { workerId }
}
