//
//  DashboardSyncStatus.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/16/25.
//


//
//  CrossDashboardTypes.swift
//  FrancoSphere v6.0
//
//  ✅ SHARED TYPES: Cross-dashboard synchronization types
//  ✅ SINGLE SOURCE: Eliminates duplicate type definitions
//  ✅ PHASE 1.2 READY: Prepared for full cross-dashboard integration
//
//  📝 USAGE:
//  This file provides shared types used by AdminDashboardViewModel and ClientDashboardViewModel
//  for cross-dashboard synchronization. Once added, remove duplicate definitions from ViewModels.
//

import Foundation
import SwiftUI

// MARK: - Cross-Dashboard Synchronization Status

public enum DashboardSyncStatus {
    case synced
    case syncing
    case error
    
    public var description: String {
        switch self {
        case .synced: return "Synced"
        case .syncing: return "Syncing..."
        case .error: return "Sync Error"
        }
    }
    
    public var color: Color {
        switch self {
        case .synced: return .green
        case .syncing: return .blue
        case .error: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .synced: return "checkmark.circle.fill"
        case .syncing: return "arrow.clockwise.circle"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Cross-Dashboard Update Events

public enum CrossDashboardUpdate {
    case taskCompleted(buildingId: String)
    case workerClockedIn(buildingId: String)
    case metricsUpdated(buildingIds: [String])
    case insightsUpdated(count: Int)
    case buildingIntelligenceUpdated(buildingId: String)
    case complianceUpdated(buildingIds: [String])
    
    public var description: String {
        switch self {
        case .taskCompleted(let buildingId):
            return "Task completed at building \(buildingId)"
        case .workerClockedIn(let buildingId):
            return "Worker clocked in at building \(buildingId)"
        case .metricsUpdated(let buildingIds):
            return "Metrics updated for \(buildingIds.count) buildings"
        case .insightsUpdated(let count):
            return "\(count) portfolio insights updated"
        case .buildingIntelligenceUpdated(let buildingId):
            return "Intelligence updated for building \(buildingId)"
        case .complianceUpdated(let buildingIds):
            return "Compliance updated for \(buildingIds.count) buildings"
        }
    }
    
    public var category: UpdateCategory {
        switch self {
        case .taskCompleted, .workerClockedIn:
            return .worker
        case .metricsUpdated, .insightsUpdated, .buildingIntelligenceUpdated:
            return .admin
        case .complianceUpdated:
            return .compliance
        }
    }
    
    public var priority: UpdatePriority {
        switch self {
        case .taskCompleted, .workerClockedIn:
            return .normal
        case .metricsUpdated, .buildingIntelligenceUpdated:
            return .high
        case .insightsUpdated, .complianceUpdated:
            return .critical
        }
    }
}

// MARK: - Supporting Enums

public enum UpdateCategory {
    case worker
    case admin
    case compliance
    
    public var color: Color {
        switch self {
        case .worker: return .blue
        case .admin: return .orange
        case .compliance: return .purple
        }
    }
    
    public var icon: String {
        switch self {
        case .worker: return "person.fill.checkmark"
        case .admin: return "chart.line.uptrend.xyaxis"
        case .compliance: return "checkmark.shield.fill"
        }
    }
}

public enum UpdatePriority {
    case low
    case normal
    case high
    case critical
    
    public var color: Color {
        switch self {
        case .low: return .gray
        case .normal: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    public var displayName: String {
        switch self {
        case .low: return "Low"
        case .normal: return "Normal"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }
}