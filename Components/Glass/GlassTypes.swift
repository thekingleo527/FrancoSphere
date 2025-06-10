//
//  GlassTypes.swift
//  FrancoSphere
//
//  Glass component types and styles - Compatible with existing implementations
//

import SwiftUI

// MARK: - Glass Button Style
public enum GlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    
    public var baseColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .gray
        case .tertiary: return .purple
        case .destructive: return .red
        }
    }
    
    public var textColor: Color {
        switch self {
        case .primary, .destructive: return .white
        case .secondary, .tertiary: return .white.opacity(0.9)
        }
    }
    
    public var intensity: GlassIntensity {
        switch self {
        case .primary: return .regular
        case .secondary: return .thin
        case .tertiary: return .thick
        case .destructive: return .regular
        }
    }
}

// MARK: - Glass Button Size
public enum GlassButtonSize {
    case small
    case medium
    case large
    
    public var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .headline
        }
    }
    
    public var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .medium: return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        case .large: return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
}

// MARK: - Glass Intensity
public enum GlassIntensity {
    case thin
    case regular
    case thick
    
    public var material: Material {
        switch self {
        case .thin: return .ultraThinMaterial
        case .regular: return .thinMaterial
        case .thick: return .regularMaterial
        }
    }
    
    public var opacity: Double {
        switch self {
        case .thin: return 0.1
        case .regular: return 0.2
        case .thick: return 0.3
        }
    }
}

// MARK: - Glass Tab Item
public struct GlassTabItem {
    public let title: String
    public let icon: String
    public let selectedIcon: String
    
    public init(title: String, icon: String, selectedIcon: String) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon
    }
}

// MARK: - Aliases for existing badge types (to match your existing implementations)
public typealias GlassStatusBadgeStyle = GlassBadgeStyle
public typealias GlassStatusBadgeSize = GlassBadgeSize
