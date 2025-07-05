//
//  ModelColorsExtensions.swift
//  FrancoSphere
//

import SwiftUI

extension FrancoSphere.WeatherCondition {
    var conditionColor: Color {
        switch self {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .fog: return .gray
        case .storm: return .purple
        }
    }
}

extension FrancoSphere.TaskUrgency {
    var urgencyColor: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

extension FrancoSphere.VerificationStatus {
    var statusColor: Color {
        switch self {
        case .pending: return .orange
        case .verified: return .green
        case .failed: return .red
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
    var outdoorWorkRisk: OutdoorWorkRisk {
        switch condition {
        case .clear, .cloudy:
            return temperature < 32 ? .medium : .low
        case .rain, .snow:
            return .high
        case .storm:
            return .extreme
        case .fog:
            return .medium
        }
    }
}

enum OutdoorWorkRisk {
    case low, medium, high, extreme
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
}
