//
//  ComplianceDataDTO.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ FIXED: Added public initializer and properties for BuildingIntelligenceDTO compatibility
//  ✅ Defines the data structure for building compliance information.
//

import Foundation

public struct ComplianceDataDTO: Codable, Hashable {
    public let buildingId: CoreTypes.BuildingID
    public let hasValidPermits: Bool
    public let lastInspectionDate: Date
    public let outstandingViolations: Int
    
    // ✅ ADDED: Public initializer for external creation
    public init(
        buildingId: CoreTypes.BuildingID,
        hasValidPermits: Bool,
        lastInspectionDate: Date,
        outstandingViolations: Int
    ) {
        self.buildingId = buildingId
        self.hasValidPermits = hasValidPermits
        self.lastInspectionDate = lastInspectionDate
        self.outstandingViolations = outstandingViolations
    }
    
    // A computed property to quickly assess compliance risk
    public var complianceStatus: ComplianceStatus {
        if !hasValidPermits || outstandingViolations > 0 {
            return .atRisk
        }
        if let daysSinceInspection = Calendar.current.dateComponents([.day], from: lastInspectionDate, to: Date()).day, daysSinceInspection > 365 {
            return .needsReview
        }
        return .compliant
    }
}
