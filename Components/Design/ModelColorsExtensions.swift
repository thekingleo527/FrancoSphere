//
//  ModelColorsExtensions.swift
//  FrancoSphere
//
//  Fixed exhaustive switch statements for all enum cases
//

import SwiftUI

extension FrancoSphere.WeatherCondition {
    var conditionColor: Color {
        switch self {
        case .sunny, .clear: return .yellow
        case .cloudy: return .gray
        case .rainy, .rain: return .blue
        case .snowy, .snow: return .cyan
        case .foggy, .fog: return .gray
        case .stormy, .storm: return .purple
        case .windy: return .green
        }
    }
}

extension FrancoSphere.TaskUrgency {
    var urgencyColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .critical, .urgent: return .purple
        }
    }
}

extension FrancoSphere.VerificationStatus {
    var statusColor: Color {
        switch self {
        case .pending: return .orange
        case .approved, .verified: return .green
        case .rejected, .failed: return .red
        case .requiresReview: return .blue
        }
    }
}

extension FrancoSphere.WorkerSkill {
    var skillColor: Color {
        switch self {
        case .basic: return .blue
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
}

extension FrancoSphere.RestockStatus {
    var statusColor: Color {
        switch self {
        case .inStock: return .green
        case .lowStock: return .orange
        case .outOfStock: return .red
        case .ordered: return .blue
        case .inTransit: return .purple
        case .delivered: return .green
        case .cancelled: return .gray
        }
    }
}

extension FrancoSphere.InventoryCategory {
    var categoryColor: Color {
        switch self {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .safety: return .red
        case .office: return .gray
        case .other: return .secondary
        }
    }
}

extension FrancoSphere.WeatherData {
    var outdoorWorkRisk: FrancoSphere.OutdoorWorkRisk {
        switch condition {
        case .sunny, .clear, .cloudy:
            return temperature < 32 ? .medium : .low
        case .rainy, .rain, .snowy, .snow:
            return .high
        case .stormy, .storm:
            return .extreme
        case .foggy, .fog, .windy:
            return .medium
        }
    }
}

extension FrancoSphere.WeatherCondition {
    var icon: String {
        switch self {
        case .sunny, .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy, .rain: return "cloud.rain.fill"
        case .snowy, .snow: return "cloud.snow.fill"
        case .foggy, .fog: return "cloud.fog.fill"
        case .stormy, .storm: return "cloud.bolt.fill"
        case .windy: return "wind"
        }
    }
}
