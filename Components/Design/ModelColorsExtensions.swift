//
//  ModelColorsExtensions.swift
//  FrancoSphere v6.0
//
//  ⚠️  MINIMAL VERSION - Bypassing compilation errors temporarily
//  🎯 This allows Nova AI implementation to continue
//

import SwiftUI
import Foundation

// MARK: - Basic Color Extensions (No Switch Statements)

extension Color {
    /// Generic status color helper
    static func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "verified", "completed", "success": return .green
        case "pending", "in progress": return .orange
        case "failed", "error": return .red
        default: return .gray
        }
    }
    
    /// Generic category color helper
    static func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "maintenance": return .orange
        case "cleaning": return .blue
        case "repair": return .red
        case "inspection": return .purple
        case "emergency": return .red
        default: return .gray
        }
    }
}

// MARK: - String-based Icon Helpers (Bypasses enum issues)

extension String {
    /// Returns SF Symbol icon for status strings
    var statusIcon: String {
        switch self.lowercased() {
        case "verified", "completed": return "checkmark.circle.fill"
        case "pending": return "clock.fill"
        case "failed", "error": return "xmark.circle.fill"
        case "in progress": return "gear"
        default: return "questionmark.circle"
        }
    }
    
    /// Returns SF Symbol icon for category strings
    var categoryIcon: String {
        switch self.lowercased() {
        case "maintenance": return "wrench.and.screwdriver"
        case "cleaning": return "sparkles"
        case "repair": return "hammer"
        case "inspection": return "magnifyingglass"
        case "emergency": return "exclamationmark.triangle.fill"
        default: return "square.grid.3x3"
        }
    }
}

// MARK: - Placeholder Extensions (To satisfy any existing code)

// These empty extensions prevent "cannot find in scope" errors
// while we focus on Nova AI implementation

public struct PlaceholderEnum {
    public static let defaultColor: Color = .gray
    public static let defaultIcon: String = "square.fill"
}

