//
//  ComplianceDataDTO.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  ComplianceDataDTO.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 1.1 - Comprehensive DTO System
//  ✅ Defines the data structure for building compliance information.
//

import Foundation

public struct ComplianceDataDTO: Codable, Hashable {
    let buildingId: CoreTypes.BuildingID
    let hasValidPermits: Bool
    let lastInspectionDate: Date
    let outstandingViolations: Int
    
    // A computed property to quickly assess compliance risk
    var complianceStatus: ComplianceStatus {
        if !hasValidPermits || outstandingViolations > 0 {
            return .atRisk
        }
        if let daysSinceInspection = Calendar.current.dateComponents([.day], from: lastInspectionDate, to: Date()).day, daysSinceInspection > 365 {
            return .needsReview
        }
        return .compliant
    }
}

public enum ComplianceStatus: String, Codable {
    case compliant = "Compliant"
    case needsReview = "Needs Review"
    case atRisk = "At Risk"
}
