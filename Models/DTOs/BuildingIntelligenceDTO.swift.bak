//
//  BuildingIntelligenceDTO.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ FIXED: Conformance issues by ensuring all child DTOs are also Codable/Hashable.
//

import Foundation

public struct BuildingIntelligenceDTO: Codable, Hashable, Identifiable {
    public var id: CoreTypes.BuildingID { buildingId }
    
    let buildingId: CoreTypes.BuildingID
    let operationalMetrics: OperationalMetricsDTO
    let complianceData: ComplianceDataDTO
    let workerMetrics: [WorkerMetricsDTO] // An array to hold metrics for all assigned workers
    let buildingSpecificData: BuildingSpecificDataDTO
    let dataQuality: DataQuality
    let timestamp: Date
    
    // A convenience computed property to get the overall building score
    var overallScore: Int {
        return operationalMetrics.score
    }
}

// Ensure these supporting DTOs are also Codable and Hashable
public struct OperationalMetricsDTO: Codable, Hashable {
    let score: Int
    let routineAdherence: Double
    let maintenanceEfficiency: Double
    let averageTaskDuration: TimeInterval
}

public struct BuildingSpecificDataDTO: Codable, Hashable {
    let buildingType: String // e.g., "Commercial", "Residential", "Cultural"
    let yearBuilt: Int
    let squareFootage: Int
}

public struct DataQuality: Codable, Hashable {
    let score: Double
    let isDataStale: Bool
    let missingReports: Int
}
