//
//  ModelColorsExtensions.swift
//  FrancoSphere
//
//  ✅ SURGICAL FIX - All enum cases corrected, no invalid references
//

import SwiftUI
import Foundation


// MARK: - TaskUrgency Color Extensions
extension TaskUrgency {
    public var displayColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        case .emergency: return .red
        case .urgent: return .red
        
        default: return Color.gray}
    }
    
    public var icon: String {
        switch self {
        case .low: return "circle.fill" // TODO: Fix color for "checkmark.circle"
        case .medium: return "exclamationmark.circle"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        case .emergency: return "exclamationmark.octagon.fill"
        case .urgent: return "flame.fill"
        
        default: return "circle.fill"}
    }
}


// MARK: - VerificationStatus Color Extensions
extension VerificationStatus {
    public var displayColor: Color {
        switch self {
        case .pending: return .yellow
        case .approved: return .green
        case .rejected: return .red
        case .failed: return .red
        case .requiresReview: return .orange
        
        default: return Color.gray}
    }
    
    public var icon: String {
        switch self {
        case .pending: return "circle.fill" // TODO: Fix color for "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .requiresReview: return "questionmark.circle.fill"
        
        default: return "circle.fill"}
    }
}


// MARK: - TaskCategory Color Extensions
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
        
        default: return Color.gray}
    }
}

// MARK: - InventoryCategory Color Extensions
extension InventoryCategory {
    public var displayColor: Color {
        switch self {
        case .tools: return Color.gray
        case .supplies: return .blue
        case .cleaning: return .cyan
        case .maintenance: return .orange
        case .safety: return .red
        case .office: return .green
        case .plumbing: return .blue
        case .electrical: return .yellow
        case .paint: return .purple
        
        default: return Color.gray}
    }
}

// MARK: - OutdoorWorkRisk Color Extensions
extension OutdoorWorkRisk {
    public var displayColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        
        default: return Color.gray}
    }
    
    public var icon: String {
        switch self {
        case .low: return "circle.fill" // TODO: Fix color for "checkmark.shield"
        case .medium: return "exclamationmark.shield"
        case .high: return "exclamationmark.triangle"
        case .extreme: return "xmark.shield"
        
        default: return "circle.fill"}
    }
}

// MARK: - FrancoSphere.TrendDirection Color Extensions
extension FrancoSphere.TrendDirection {
    public var displayColor: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return Color.gray
        
        default: return Color.gray}
    }
}

// MARK: - WorkerSkill Color Extensions
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
        
        default: return Color.gray}
    }
}

// MARK: - RestockStatus Color Extensions
extension RestockStatus {
    public var displayColor: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .yellow
        case .outOfStock: return .red
        case .onOrder: return .blue
        
        default: return Color.gray}
    }
}

// MARK: - DataHealthStatus Color Extensions
extension DataHealthStatus {
    public var displayColor: Color {
        switch self {
        case .healthy: return .green
        case .warning: return .yellow
        case .error: return .red
        
        default: return Color.gray}
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
