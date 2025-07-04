//
//  GlassTypes.swift
//  FrancoSphere
//
//  Central location for all Glass component types and enums
//  Created by Shawn Magloire on 6/5/25.
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Glass Intensity
public enum GlassIntensity {
    case ultraThin
    case thin
    case regular
    case thick
    
    public var material: Material {
        switch self {
        case .ultraThin:
            return .ultraThinMaterial
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        }
    }
    
    public var opacity: Double {
        switch self {
        case .ultraThin:
            return 0.05
        case .thin:
            return 0.1
        case .regular:
            return 0.15
        case .thick:
            return 0.25
        }
    }
    
    public var blurRadius: CGFloat {
        switch self {
        case .ultraThin:
            return 10
        case .thin:
            return 15
        case .regular:
            return 20
        case .thick:
            return 30
        }
    }
}

// MARK: - Glass Button Style
public enum GlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    case custom(baseColor: Color, textColor: Color)
    
    public var baseColor: Color {
        switch self {
        case .primary:
            return .blue
        case .secondary:
            return .gray
        case .tertiary:
            return .clear
        case .destructive:
            return .red
        case .custom(let baseColor, _):
            return baseColor
        }
    }
    
    public var textColor: Color {
        switch self {
        case .primary, .secondary, .destructive:
            return .white
        case .tertiary:
            return .white.opacity(0.8)
        case .custom(_, let textColor):
            return textColor
        }
    }
    
    public var intensity: GlassIntensity {
        switch self {
        case .primary:
            return .regular
        case .secondary:
            return .thin
        case .tertiary:
            return .ultraThin
        case .destructive:
            return .regular
        case .custom:
            return .regular
        }
    }
}

// MARK: - Glass Button Size
public enum GlassButtonSize {
    case small
    case medium
    case large
    
    public var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium:
            return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        case .large:
            return EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        }
    }
    
    public var font: Font {
        switch self {
        case .small:
            return .subheadline
        case .medium:
            return .body
        case .large:
            return .headline
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .small:
            return 12
        case .medium:
            return 16
        case .large:
            return 20
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

// MARK: - Glass Modal Size
public enum GlassModalSize {
    case small
    case medium
    case large
    case fullScreen
    
    public var width: CGFloat? {
        switch self {
        case .small:
            return 300
        case .medium:
            return 400
        case .large:
            return 600
        case .fullScreen:
            return nil
        }
    }
    
    public var height: CGFloat? {
        switch self {
        case .small:
            return 200
        case .medium:
            return 400
        case .large:
            return 600
        case .fullScreen:
            return nil
        }
    }
}

// MARK: - Glass Modal Style
public enum GlassModalStyle {
    case centered
    case bottom
    case fullScreen
}

// MARK: - Glass Navigation Style
public enum GlassNavigationStyle {
    case inline
    case large
    case transparent
    
    public var intensity: GlassIntensity {
        switch self {
        case .inline:
            return .regular
        case .large:
            return .thick
        case .transparent:
            return .ultraThin
        }
    }
}

// MARK: - Glass Loading Style
public enum GlassLoadingStyle {
    case spinner
    case progress
    case pulse
    
    public var color: Color {
        return .white
    }
}

// MARK: - Glass Transition
public enum GlassTransition {
    case fade
    case scale
    case slide(Edge)
    case blur
    
    public var animation: Animation {
        switch self {
        case .fade, .blur:
            return .easeInOut(duration: 0.3)
        case .scale:
            return .spring(response: 0.4, dampingFraction: 0.8)
        case .slide:
            return .spring(response: 0.5, dampingFraction: 0.85)
        }
    }
}

// MARK: - Glass Deck Style
public enum GlassDeckStyle {
    case stacked
    case carousel
    case grid
    
    public var spacing: CGFloat {
        switch self {
        case .stacked:
            return -50
        case .carousel:
            return 20
        case .grid:
            return 16
        }
    }
}

// MARK: - Glass Status
public enum GlassStatus {
    case active
    case inactive
    case loading
    case error
    case success
    
    public var color: Color {
        switch self {
        case .active:
            return .green
        case .inactive:
            return .gray
        case .loading:
            return .blue
        case .error:
            return .red
        case .success:
            return .green
        }
    }
    
    public var icon: String {
        switch self {
        case .active:
            return "checkmark.circle.fill"
        case .inactive:
            return "circle"
        case .loading:
            return "arrow.clockwise"
        case .error:
            return "exclamationmark.triangle.fill"
        case .success:
            return "checkmark.circle.fill"
        }
    }
}

// MARK: - Type Aliases for compatibility
// These ensure compatibility with existing code
public typealias GlassCardStyle = GlassIntensity
public typealias GlassEffectStyle = GlassIntensity
