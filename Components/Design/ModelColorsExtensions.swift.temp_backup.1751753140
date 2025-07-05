//
//  ModelColorsExtensions.swift
//  FrancoSphere
//
//  ✅ COMPLETE REBUILD - All enum cases included
//

import SwiftUI
import Foundation

// MARK: - TaskUrgency Color Extensions
extension TaskUrgency {
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .emergency: return .red
        case .urgent: return .red  // ✅ Added missing case
        }
    }
}

// MARK: - VerificationStatus Color Extensions
extension VerificationStatus {
    public var color: Color {
        switch self {
        case .pending: return .yellow
        case .approved: return .green  // ✅ Added missing case
        case .rejected: return .red
        case .failed: return .red  // ✅ Added missing case
        case .requiresReview: return .orange  // ✅ Added missing case
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .requiresReview: return "questionmark.circle.fill"
        }
    }
}

// MARK: - TaskCategory Color Extensions
extension TaskCategory {
    public var color: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .inspection: return .purple
        case .repair: return .red
        case .installation: return .green
        case .landscaping: return .green
        case .security: return .red
        case .utilities: return .yellow
        case .emergency: return .red
        case .renovation: return .brown
        case .sanitation: return .blue
        }
    }
}

// MARK: - InventoryCategory Color Extensions
extension InventoryCategory {
    public var color: Color {
        switch self {
        case .tools: return .gray
        case .supplies: return .blue
        case .cleaning: return .cyan  // ✅ Added missing case
        case .maintenance: return .orange  // ✅ Added missing case
        case .safety: return .red
        case .office: return .green
        case .plumbing: return .blue  // ✅ Added missing case
        case .electrical: return .yellow  // ✅ Added missing case
        case .paint: return .purple  // ✅ Added missing case
        }
    }
}

// MARK: - OutdoorWorkRisk Color Extensions (✅ Added missing type)
extension OutdoorWorkRisk {
    public var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .low: return "checkmark.shield"
        case .medium: return "exclamationmark.shield"
        case .high: return "exclamationmark.triangle"
        case .extreme: return "xmark.shield"
        }
    }
}

// MARK: - TrendDirection Color Extensions
extension TrendDirection {
    public var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - WorkerSkill Color Extensions
extension WorkerSkill {
    public var color: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .inspection: return .purple
        case .repair: return .red
        case .installation: return .green
        case .landscaping: return .green
        case .security: return .red
        case .utilities: return .yellow
        case .plumbing: return .blue
        case .electrical: return .yellow
        }
    }
}

// MARK: - RestockStatus Color Extensions
extension RestockStatus {
    public var color: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        case .onOrder: return .blue
        }
    }
}

// MARK: - DataHealthStatus Color Extensions
extension DataHealthStatus {
    public var color: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .yellow
        case .error: return .red
        }
    }
}
