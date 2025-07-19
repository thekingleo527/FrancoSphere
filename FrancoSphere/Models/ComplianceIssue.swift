//
//  ComplianceIssue.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/19/25.
//


//
//  ComplianceIssue.swift
//  FrancoSphere v6.0
//
//  ✅ CREATED: Missing file to resolve build dependency
//  ✅ IMPORTS: All types from CoreTypes.swift (no conflicts)
//

import Foundation
import SwiftUI

// MARK: - Re-export CoreTypes for backward compatibility
public typealias ComplianceIssue = CoreTypes.ComplianceIssue
public typealias ComplianceIssueType = CoreTypes.ComplianceIssueType
public typealias ComplianceSeverity = CoreTypes.ComplianceSeverity

// MARK: - Helper Extensions
extension CoreTypes.ComplianceIssue {
    
    /// Generate a mock compliance issue for testing
    static func mockIssue(for buildingId: String, buildingName: String) -> CoreTypes.ComplianceIssue {
        return CoreTypes.ComplianceIssue(
            buildingId: buildingId,
            buildingName: buildingName,
            issueType: .maintenanceOverdue,
            severity: .high,
            description: "Routine maintenance inspection overdue",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            assignedTo: "Maintenance Team"
        )
    }
    
    /// Priority sorting helper
    var sortPriority: Int {
        switch severity {
        case .critical: return 4
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

extension CoreTypes.ComplianceIssueType {
    
    /// Display name for UI
    var displayName: String {
        return rawValue
    }
}

extension CoreTypes.ComplianceSeverity {
    
    /// Display name for UI
    var displayName: String {
        return rawValue
    }
    
    /// Badge text for severity
    var badgeText: String {
        switch self {
        case .critical: return "CRITICAL"
        case .high: return "HIGH"
        case .medium: return "MEDIUM"
        case .low: return "LOW"
        }
    }
}