//
//  GlassIntensity.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  GlassTypes.swift
//  FrancoSphere
//
//  Created by Assistant on 6/8/25.
//  Shared glass component types - COMPLETE VERSION

import SwiftUI

// MARK: - Glass Intensity Levels
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
            return 0.5
        case .thin:
            return 0.6
        case .regular:
            return 0.7
        case .thick:
            return 0.8
        }
    }
    
    public var blurRadius: CGFloat {
        switch self {
        case .ultraThin:
            return 20
        case .thin:
            return 30
        case .regular:
            return 40
        case .thick:
            return 50
        }
    }
}

// MARK: - Glass Button Styles
public enum GlassButtonStyle {
    case primary
    case secondary
    case tertiary
    case destructive
    
    public var baseColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .gray
        case .tertiary: return .clear
        case .destructive: return .red
        }
    }
    
    public var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .white
        case .tertiary: return .blue
        case .destructive: return .white
        }
    }
    
    public var intensity: GlassIntensity {
        switch self {
        case .primary: return .regular
        case .secondary: return .thin
        case .tertiary: return .ultraThin
        case .destructive: return .regular
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
        case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
        case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        }
    }
    
    public var font: Font {
        switch self {
        case .small: return .caption.weight(.semibold)
        case .medium: return .subheadline.weight(.semibold)
        case .large: return .headline.weight(.semibold)
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

// MARK: - Glass Tab Item
public struct GlassTabItem {
    public let title: String
    public let icon: String
    public let selectedIcon: String
    
    public init(title: String, icon: String, selectedIcon: String? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
    }
}