//
//  ComplianceIssue.swift
//  FrancoSphere
//

import Foundation
import SwiftUI

public struct ComplianceIssue: Identifiable, Codable {
    public let id = UUID()
    public let building: NamedCoordinate
    public let issueType: ComplianceIssueType
    public let severity: ComplianceSeverity
    public let description: String
    public let dueDate: Date?
    public let resolvedDate: Date?
    public var isResolved: Bool { resolvedDate != nil }

    public init(
        building: NamedCoordinate, issueType: ComplianceIssueType,
        severity: ComplianceSeverity, description: String,
        dueDate: Date? = nil, resolvedDate: Date? = nil
    ) {
        self.building = building; self.issueType = issueType
        self.severity = severity; self.description = description
        self.dueDate = dueDate; self.resolvedDate = resolvedDate
    }
}

public enum ComplianceIssueType: String, CaseIterable, Codable {
    case maintenanceOverdue = "Maintenance Overdue"
    case safetyViolation   = "Safety Violation"
    case documentationMissing = "Documentation Missing"
    case inspectionRequired   = "Inspection Required"
    case certificationExpired = "Certification Expired"
    public var icon: String {
        switch self {
        case .maintenanceOverdue: return "wrench.and.screwdriver"
        case .safetyViolation:   return "exclamationmark.triangle"
        case .documentationMissing: return "doc.text"
        case .inspectionRequired:   return "magnifyingglass"
        case .certificationExpired: return "calendar.badge.exclamationmark"
        }
    }
}

public enum ComplianceSeverity: String, CaseIterable, Codable {
    case low, medium, high, critical
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}
