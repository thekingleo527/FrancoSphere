//
//  ModelColorsExtensions.swift
//  FrancoSphere
//
//  ✅ CLEAN VERSION - Proper extension syntax, no conflicts
//

import SwiftUI
import Foundation

// MARK: - TaskUrgency Display Colors
extension TaskUrgency {
    public var displayColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .emergency: return .red
        case .urgent: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .low: return "checkmark.circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        case .emergency: return "exclamationmark.octagon.fill"
        case .urgent: return "flame.fill"
        }
    }
}

// MARK: - VerificationStatus Display Colors
extension VerificationStatus {
    public var displayColor: Color {
        switch self {
        case .pending: return .yellow
        case .approved: return .green
        case .rejected: return .red
        case .failed: return .red
        case .requiresReview: return .orange
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

// MARK: - TaskCategory Display Colors
extension TaskCategory {
    public var displayColor: Color {
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

// MARK: - InventoryCategory Display Colors
extension InventoryCategory {
    public var displayColor: Color {
        switch self {
        case .tools: return .gray
        case .supplies: return .blue
        case .cleaning: return .cyan
        case .maintenance: return .orange
        case .safety: return .red
        case .office: return .green
        case .plumbing: return .blue
        case .electrical: return .yellow
        case .paint: return .purple
        }
    }
}

// MARK: - OutdoorWorkRisk Display Colors
extension OutdoorWorkRisk {
    public var displayColor: Color {
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

// MARK: - TrendDirection Display Colors
extension TrendDirection {
    public var displayColor: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        }
    }
}

// MARK: - WorkerSkill Display Colors
extension WorkerSkill {
    public var displayColor: Color {
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

// MARK: - RestockStatus Display Colors
extension RestockStatus {
    public var displayColor: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        case .onOrder: return .blue
        }
    }
}

// MARK: - DataHealthStatus Display Colors
extension DataHealthStatus {
    public var displayColor: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .yellow
        case .error: return .red
        }
    }
}
