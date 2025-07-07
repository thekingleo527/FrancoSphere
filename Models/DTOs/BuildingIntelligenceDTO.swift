//
//  BuildingIntelligenceDTO.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  BuildingIntelligenceDTO.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ The central data model for the new intelligence dashboard features.
//

import Foundation

// MARK: - Main DTO

/// The primary Data Transfer Object for aggregated building intelligence.
/// This will be used to pass data to the Admin and Client dashboards.
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


// MARK: - Component DTOs
// These are the building blocks for the main DTO. We will create their
// full implementations in subsequent steps.

public struct OperationalMetricsDTO: Codable, Hashable {
    let score: Int
    let routineAdherence: Double
    let maintenanceEfficiency: Double
    let averageTaskDuration: TimeInterval
}

public struct ComplianceDataDTO: Codable, Hashable {
    let buildingId: CoreTypes.BuildingID
    let hasValidPermits: Bool
    let lastInspectionDate: Date
    let outstandingViolations: Int
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

// MARK: - Error Type
enum BuildingIntelligenceError: LocalizedError {
    case invalidBuildingId
    case dataAggregationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidBuildingId:
            return "The provided building ID was invalid."
        case .dataAggregationFailed:
            return "Failed to aggregate intelligence data for the building."
        }
    }
}
