//
//  WorkerMetricsDTO.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ Defines the performance metrics for a worker at a specific building.
//

import Foundation

public struct WorkerMetricsDTO: Codable, Hashable, Identifiable {
    public var id: String { "\(buildingId)-\(workerId)" }
    
    let buildingId: CoreTypes.BuildingID
    let workerId: CoreTypes.WorkerID
    
    // Core Performance Metrics
    let overallScore: Int
    let taskCompletionRate: Double
    let maintenanceEfficiency: Double
    let routineAdherence: Double
    
    // Supporting Data
    let specializedTasksCompleted: Int
    let totalTasksAssigned: Int
    let averageTaskDuration: TimeInterval
    let lastActiveDate: Date
    
    /// A convenience computed property to quickly identify top performers.
    var isHighPerformer: Bool {
        return overallScore >= 90 && taskCompletionRate >= 0.95
    }
}
