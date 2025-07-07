//
//  default.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  ModelExtensions.swift
//  FrancoSphere
//
//  ✅ V6.0: Adds UI-specific properties to core data models.
//  ✅ FIXED: Resolves "'TaskCategory' has no member 'color'" errors.
//

import Foundation
import SwiftUI

// By placing UI-related properties in an extension, we keep the core
// data models clean and decoupled from the view layer.

extension TaskCategory {
    /// Provides a consistent color for each task category for use in the UI.
    var color: Color {
        switch self {
        case .cleaning:
            return .blue
        case .maintenance:
            return .orange
        case .repair:
            return .red
        case .sanitation:
            return .green
        case .inspection:
            return .purple
        // Add other cases as they are defined in your TaskCategory enum
        default:
            return .gray
        }
    }
}

extension TaskUrgency {
    /// Provides a consistent color for each urgency level for use in the UI.
    var color: Color {
        switch self {
        case .low:
            return .green
        case .medium:
            return .orange
        case .high, .urgent, .critical, .emergency:
            return .red
        // Add other cases as they are defined in your TaskUrgency enum
        default:
            return .gray
        }
    }
}
