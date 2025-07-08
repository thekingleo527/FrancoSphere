//
//  StubFactory.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  StubFactory.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.2 - Complete StubFactory
//  ✅ Provides mock data for all new DTOs for development and testing.
//

import Foundation

public enum StubFactory {

    /// Creates a complete, stubbed BuildingIntelligenceDTO for a given building ID.
    public static func makeBuildingIntelligence(for buildingId: CoreTypes.BuildingID, workerIds: [CoreTypes.WorkerID]) -> BuildingIntelligenceDTO {
        let workerMetrics = workerIds.map { makeWorkerMetrics(for: buildingId, workerId: $0) }
        
        return BuildingIntelligenceDTO(
            buildingId: buildingId,
            operationalMetrics: makeOperationalMetrics(),
            complianceData: makeComplianceData(for: buildingId),
            workerMetrics: workerMetrics,
            buildingSpecificData: makeBuildingSpecificData(for: buildingId),
            dataQuality: makeDataQuality(),
            timestamp: Date().addingTimeInterval(-3600) // 1 hour ago
        )
    }

    /// Creates stubbed operational metrics.
    public static func makeOperationalMetrics() -> OperationalMetricsDTO {
        return OperationalMetricsDTO(
            score: Int.random(in: 75...95),
            routineAdherence: Double.random(in: 0.8...0.98),
            maintenanceEfficiency: Double.random(in: 0.8...0.95),
            averageTaskDuration: TimeInterval(Int.random(in: 1800...3600))
        )
    }

    /// Creates stubbed compliance data with building-specific logic.
    public static func makeComplianceData(for buildingId: CoreTypes.BuildingID) -> ComplianceDataDTO {
        switch buildingId {
        case "14": // Rubin Museum - higher compliance due to museum standards
            return ComplianceDataDTO(
                buildingId: buildingId,
                hasValidPermits: true,
                lastInspectionDate: Date().addingTimeInterval(-60 * 60 * 24 * 30), // 30 days ago
                outstandingViolations: 0
            )
        case "7": // 136 W 17th Street - residential condo
            return ComplianceDataDTO(
                buildingId: buildingId,
                hasValidPermits: true,
                lastInspectionDate: Date().addingTimeInterval(-60 * 60 * 24 * 90), // 90 days ago
                outstandingViolations: 1
            )
        default:
            return ComplianceDataDTO(
                buildingId: buildingId,
                hasValidPermits: Bool.random(),
                lastInspectionDate: Date().addingTimeInterval(TimeInterval(-Int.random(in: 60...400)) * 86400),
                outstandingViolations: Int.random(in: 0...2)
            )
        }
    }

    /// Creates stubbed worker metrics.
    public static func makeWorkerMetrics(for buildingId: CoreTypes.BuildingID, workerId: CoreTypes.WorkerID) -> WorkerMetricsDTO {
        return WorkerMetricsDTO(
            buildingId: buildingId,
            workerId: workerId,
            overallScore: Int.random(in: 75...95),
            taskCompletionRate: Double.random(in: 0.8...0.98),
            maintenanceEfficiency: Double.random(in: 0.8...0.95),
            workerSatisfaction: Double.random(in: 0.8...1.0),
            routineAdherence: Double.random(in: 0.9...1.0),
            specializedTasksCompleted: Int.random(in: 1...5),
            totalTasksAssigned: Int.random(in: 10...20),
            averageTaskDuration: TimeInterval(Int.random(in: 1800...3600)),
            lastActiveDate: Date().addingTimeInterval(TimeInterval(-Int.random(in: 1...5)) * 86400)
        )
    }
    
    /// Creates stubbed building-specific data.
    public static func makeBuildingSpecificData(for buildingId: CoreTypes.BuildingID) -> BuildingSpecificDataDTO {
        let type: String
        switch buildingId {
        case "14":
            type = "Cultural"
        case "7", "6", "10":
            type = "Residential"
        default:
            type = "Commercial"
        }
        return BuildingSpecificDataDTO(
            buildingType: type,
            yearBuilt: Int.random(in: 1920...2010),
            squareFootage: Int.random(in: 15000...50000)
        )
    }

    /// Creates stubbed data quality metrics.
    public static func makeDataQuality() -> DataQuality {
        return DataQuality(
            score: Double.random(in: 0.85...0.99),
            isDataStale: Bool.random(),
            missingReports: Int.random(in: 0...3)
        )
    }
}
