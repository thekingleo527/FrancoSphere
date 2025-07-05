//
//  FrancoSphereExtensions.swift
//  FrancoSphere
//
//  Extensions to provide missing properties referenced in ViewModels
//

import Foundation
import CoreLocation

// MARK: - RouteStop Extensions
extension FrancoSphere.RouteStop {
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)  // Default NYC
    }
    
    public var estimatedTaskDuration: TimeInterval {
        TimeInterval(tasks.count * 1800)  // 30 minutes per task
    }
    
    public var arrivalTime: Date {
        estimatedArrival
    }
    
    public var buildingName: String {
        location
    }
}

// MARK: - MaintenanceTask Extensions
extension FrancoSphere.MaintenanceTask {
    public var requiredSkillLevel: String {
        requiredSkills.first ?? "basic"
    }
}

// MARK: - WorkerDailyRoute Extensions
extension FrancoSphere.WorkerDailyRoute {
    public var totalDistance: Double {
        Double(stops.count * 1000)  // Estimate 1km between stops
    }
}

// MARK: - WorkerRoutineSummary Extensions
extension FrancoSphere.WorkerRoutineSummary {
    public var dailyTasks: Int {
        totalTasks
    }
}

// MARK: - TaskCategory Extensions
extension FrancoSphere.TaskCategory {
    public var categoryColor: String {
        switch self {
        case .cleaning: return "blue"
        case .maintenance: return "orange"
        case .inspection: return "green"
        case .repair: return "red"
        case .security: return "purple"
        case .landscaping: return "lime"
        case .administrative: return "gray"
        case .emergency: return "red"
        case .sanitation: return "teal"
        }
    }
}

// MARK: - NamedCoordinate Extensions
extension Array where Element == FrancoSphere.NamedCoordinate {
    public static var allBuildings: [FrancoSphere.NamedCoordinate] {
        [
            FrancoSphere.NamedCoordinate(id: "1", name: "Building 1", latitude: 40.7128, longitude: -74.0060),
            FrancoSphere.NamedCoordinate(id: "2", name: "Building 2", latitude: 40.7589, longitude: -73.9851)
        ]
    }
}
