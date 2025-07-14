//
//  ModelColorsExtensions.swift
//  FrancoSphere v6.0
//
//  ✅ EXHAUSTIVE: All enum cases covered from CoreTypes.swift
//  ✅ PURPOSE: Domain-specific enum → UI color/icon mappings
//  ✅ COMPLEMENTS: FrancoSphereColors (general palette) + Design files
//

import SwiftUI
import Foundation

// MARK: - TaskUrgency Color Extensions (EXHAUSTIVE)
extension FrancoSphere.TaskUrgency {
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

// MARK: - VerificationStatus Color Extensions (EXHAUSTIVE)
extension VerificationStatus {
    public var displayColor: Color {
        switch self {
        case .pending: return .yellow
        case .verified: return .green
        case .failed: return .red
        case .rejected: return .red
        case .inProgress: return .blue
        case .needsReview: return .orange
        }
    }
    
    public var icon: String {
        switch self {
        case .pending: return "clock"
        case .verified: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .inProgress: return "gear"
        case .needsReview: return "questionmark.circle.fill"
        }
    }
}

// MARK: - TaskCategory Color Extensions (EXHAUSTIVE)
extension FrancoSphere.TaskCategory {
    public var displayColor: Color {
        switch self {
        case .maintenance: return .orange
        case .cleaning: return .blue
        case .repair: return .red
        case .inspection: return .purple
        case .installation: return .green
        case .utilities: return .yellow
        case .emergency: return .red
        case .renovation: return .brown
        case .landscaping: return .green
        case .security: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .maintenance: return "wrench.and.screwdriver"
        case .cleaning: return "sparkles"
        case .repair: return "hammer"
        case .inspection: return "magnifyingglass"
        case .installation: return "plus.square"
        case .utilities: return "bolt"
        case .emergency: return "exclamationmark.triangle.fill"
        case .renovation: return "building.2"
        case .landscaping: return "leaf"
        case .security: return "shield"
        }
    }
}

// MARK: - InventoryCategory Color Extensions (EXHAUSTIVE)
extension InventoryCategory {
    public var displayColor: Color {
        switch self {
        case .tools: return .gray
        case .supplies: return .blue
        case .equipment: return .purple
        case .materials: return .brown
        case .safety: return .red
        case .other: return .gray
        }
    }
    
    public var icon: String {
        switch self {
        case .tools: return "wrench"
        case .supplies: return "shippingbox"
        case .equipment: return "gear"
        case .materials: return "cube"
        case .safety: return "shield"
        case .other: return "square.stack"
        }
    }
}

// MARK: - OutdoorWorkRisk Color Extensions (EXHAUSTIVE)
extension OutdoorWorkRisk {
    public var displayColor: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .medium: return .orange
        case .high: return .orange
        case .extreme: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .low: return "checkmark.shield"
        case .moderate: return "exclamationmark.shield"
        case .medium: return "exclamationmark.triangle"
        case .high: return "exclamationmark.triangle.fill"
        case .extreme: return "xmark.shield"
        }
    }
}

// MARK: - TrendDirection Color Extensions (EXHAUSTIVE)
extension TrendDirection {
    public var displayColor: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .gray
        case .improving: return .green
        case .declining: return .red
        case .unknown: return .gray
        }
    }
    
    // Note: TrendDirection already has icon property in CoreTypes.swift
    // This provides a secondary icon mapping if needed
    public var alternateIcon: String {
        switch self {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .improving: return "chart.line.uptrend.xyaxis"
        case .declining: return "chart.line.downtrend.xyaxis"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - WorkerSkill Color Extensions (EXHAUSTIVE - Fixed missing cases)
extension WorkerSkill {
    public var displayColor: Color {
        switch self {
        case .plumbing: return .blue
        case .electrical: return .yellow
        case .hvac: return .orange
        case .carpentry: return .brown
        case .painting: return .purple
        case .cleaning: return .blue
        case .landscaping: return .green
        case .security: return .red
        case .museumSpecialist: return .purple
        case .parkMaintenance: return .green
        }
    }
    
    public var icon: String {
        switch self {
        case .plumbing: return "drop"
        case .electrical: return "bolt"
        case .hvac: return "wind"
        case .carpentry: return "hammer"
        case .painting: return "paintbrush"
        case .cleaning: return "sparkles"
        case .landscaping: return "leaf"
        case .security: return "shield"
        case .museumSpecialist: return "building.columns"
        case .parkMaintenance: return "tree"
        }
    }
}

// MARK: - WorkerStatus Color Extensions
extension WorkerStatus {
    public var displayColor: Color {
        switch self {
        case .available: return .green
        case .clockedIn: return .blue
        case .onBreak: return .orange
        case .offline: return .gray
        }
    }
    
    public var icon: String {
        switch self {
        case .available: return "checkmark.circle.fill"
        case .clockedIn: return "clock.fill"
        case .onBreak: return "pause.circle.fill"
        case .offline: return "moon.fill"
        }
    }
}

// MARK: - BuildingType Color Extensions
extension BuildingType {
    public var displayColor: Color {
        switch self {
        case .residential: return .blue
        case .commercial: return .gray
        case .museum: return .purple
        case .cultural: return .purple
        case .mixedUse: return .orange
        case .retail: return .green
        case .park: return .green
        }
    }
    
    public var icon: String {
        switch self {
        case .residential: return "house"
        case .commercial: return "building"
        case .museum: return "building.columns"
        case .cultural: return "theatermasks"
        case .mixedUse: return "building.2"
        case .retail: return "storefront"
        case .park: return "tree"
        }
    }
}

// MARK: - ComplianceStatus Color Extensions
extension ComplianceStatus {
    public var displayColor: Color {
        switch self {
        case .compliant: return .green
        case .needsReview: return .orange
        case .atRisk: return .orange
        case .nonCompliant: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .compliant: return "checkmark.shield"
        case .needsReview: return "questionmark.shield"
        case .atRisk: return "exclamationmark.shield"
        case .nonCompliant: return "xmark.shield"
        }
    }
}

// MARK: - WeatherCondition Color Extensions
extension FrancoSphere.WeatherCondition {
    public var displayColor: Color {
        switch self {
        case .clear: return .yellow
        case .sunny: return .orange
        case .cloudy: return .gray
        case .rainy: return .blue
        case .snowy: return .white
        case .stormy: return .purple
        case .foggy: return .gray
        case .windy: return .cyan
        case .partlyCloudy: return .gray
        case .overcast: return .gray
        }
    }
    
    public var icon: String {
        switch self {
        case .clear: return "sun.max"
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud"
        case .rainy: return "cloud.rain"
        case .snowy: return "cloud.snow"
        case .stormy: return "cloud.bolt"
        case .foggy: return "cloud.fog"
        case .windy: return "wind"
        case .partlyCloudy: return "cloud.sun"
        case .overcast: return "cloud.fill"
        }
    }
}

// MARK: - Helper Extensions for UI Consistency

extension Color {
    /// Adaptive color that works in both light and dark mode
    public static func adaptiveColor(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

// MARK: - Status Badge Helper
extension View {
    /// Applies appropriate status badge styling based on any enum with displayColor
    public func statusBadge<T>(for value: T) -> some View where T: RawRepresentable, T.RawValue == String {
        self.padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - TaskUrgency Additional Properties (HeaderV3B Fix)

extension TaskUrgency {
    /// Font weight for UI display
    public var fontWeight: Font.Weight {
        switch self {
        case .low: return .regular
        case .medium: return .medium
        case .high: return .semibold
        case .critical, .emergency, .urgent: return .bold
        }
    }
    
    /// Haptic feedback style for interactions
    public var feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .low: return .light
        case .medium: return .medium
        case .high, .critical, .emergency, .urgent: return .heavy
        }
    }
}
