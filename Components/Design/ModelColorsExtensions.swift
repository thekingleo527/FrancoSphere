//
//  ModelColorsExtension.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


// ModelColorExtensions.swift
// Extensions to add color properties to FrancoSphere models
// Place this file in the Extensions folder

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - WeatherCondition Color Extension
extension WeatherCondition {
    var color: Color {
        switch self {
        case .clear:        return .yellow
        case .cloudy:       return .gray
        case .rain:         return .blue
        case .snow:         return .cyan
        case .thunderstorm: return .purple
        case .fog:          return .gray
        case .other:        return .gray
        }
    }
}

// MARK: - TaskUrgency Color Extension
extension TaskUrgency {
    var color: Color {
        switch self {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - VerificationStatus Color Extension
extension VerificationStatus {
    var color: Color {
        switch self {
        case .pending:  return .orange
        case .verified: return .green
        case .rejected: return .red
        }
    }
}

// MARK: - WorkerSkill Color Extension
extension WorkerSkill {
    var color: Color {
        switch self {
        case .technical:      return .blue
        case .manual:         return .orange
        case .administrative: return .purple
        case .cleaning:       return .teal
        case .repair:         return .red
        case .inspection:     return .yellow
        case .sanitation:     return .green
        case .maintenance:    return .blue
        case .electrical:     return .yellow
        case .plumbing:       return .cyan
        case .hvac:           return .mint
        case .security:       return .red
        case .management:     return .purple
        case .boiler:         return .orange
        case .landscaping:    return .green
        }
    }
}

// MARK: - RestockStatus Color Extension
extension RestockStatus {
    var statusColor: Color {
        switch self {
        case .pending:   return .orange
        case .approved:  return .blue
        case .fulfilled: return .green
        case .rejected:  return .red
        }
    }
}

// MARK: - InventoryCategory Color Extension
extension InventoryCategory {
    var categoryColor: Color {
        switch self {
        case .cleaning:     return .blue
        case .tools:        return .orange
        case .safety:       return .red
        case .electrical:   return .yellow
        case .plumbing:     return .cyan
        case .hvac:         return .mint
        case .painting:     return .purple
        case .flooring:     return .brown
        case .hardware:     return .gray
        case .office:       return .indigo
        case .maintenance:  return .teal
        case .other:        return .gray
        }
    }
}

// MARK: - FrancoSphere.WeatherData.OutdoorWorkRisk Color Extension
extension FrancoSphere.WeatherData.OutdoorWorkRisk {
    var color: Color {
        switch self {
        case .low:      return .green
        case .moderate: return .yellow
        case .high:     return .orange
        case .extreme:  return .red
        }
    }
}
