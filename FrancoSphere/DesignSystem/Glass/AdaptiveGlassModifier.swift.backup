//
//  AdaptiveGlassModifier.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed conflicting GlassIntensity enum
//  ✅ UNIFIED: Now uses GlassIntensity from GlassTypes.swift
//  ✅ ALIGNED: Backward compatibility for existing code maintained
//  🔧 HF-25: UNIFIED GLASSMORPHISM SYSTEM (2040 STANDARD)
//  Consistent glass styling across all FrancoSphere components
//

import SwiftUI

struct AdaptiveGlassModifier: ViewModifier {
    let isCompact: Bool
    let intensity: GlassIntensity  // ✅ FIXED: Using unified GlassIntensity from GlassTypes.swift
    
    func body(content: Content) -> some View {
        if isCompact {
            content.francoGlassCardCompact(intensity: intensity)
        } else {
            content.francoGlassCard(intensity: intensity)
        }
    }
}

// MARK: - 🔧 HF-25: UNIFIED GLASS CARD EXTENSIONS

extension View {
    /// Standard Franco glass card with consistent Material Design 2040 styling
    func francoGlassCard(intensity: GlassIntensity = .regular) -> some View {
        self
            .padding(16)
            .background(intensity.material, in: RoundedRectangle(cornerRadius: 16))  // ✅ Using unified GlassIntensity.material
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(intensity.strokeOpacity), lineWidth: 1)  // ✅ Using unified GlassIntensity.strokeOpacity
            )
            .shadow(color: .black.opacity(0.15), radius: intensity.shadowRadius, x: 0, y: 6)  // ✅ Using unified GlassIntensity.shadowRadius
    }
    
    /// Compact glass card for tight spaces
    func francoGlassCardCompact(intensity: GlassIntensity = .thin) -> some View {
        self
            .padding(12)
            .background(intensity.material, in: RoundedRectangle(cornerRadius: 12))  // ✅ Using unified GlassIntensity.material
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(intensity.strokeOpacity), lineWidth: 0.5)  // ✅ Using unified GlassIntensity.strokeOpacity
            )
            .shadow(color: .black.opacity(0.1), radius: intensity.shadowRadius * 0.6, x: 0, y: 3)  // ✅ Using unified GlassIntensity.shadowRadius
    }
    
    /// Adaptive glass modifier that switches between regular and compact
    func adaptiveGlass(isCompact: Bool, intensity: GlassIntensity = .regular) -> some View {
        self.modifier(AdaptiveGlassModifier(isCompact: isCompact, intensity: intensity))
    }
}

// MARK: - Glass Effect Presets for Common Use Cases

extension View {
    /// Property card glass effect (optimized for dashboard cards)
    func propertyCardGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.regular)
    }
    
    /// Metric card glass effect (optimized for data display)
    func metricCardGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.thin)
    }
    
    /// Header glass effect (optimized for navigation)
    func headerGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.ultraThin)
    }
    
    /// Modal glass effect (optimized for overlays)
    func modalGlass() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.thick)
    }
}

// MARK: - Backward Compatibility
// Keep old function names working for existing code

extension View {
    @available(*, deprecated, message: "Use francoGlassCard(intensity:) instead")
    func glassMorphismCard() -> some View {
        self.francoGlassCard(intensity: GlassIntensity.regular)
    }
    
    @available(*, deprecated, message: "Use francoGlassCardCompact(intensity:) instead")
    func glassMorphismCardCompact() -> some View {
        self.francoGlassCardCompact(intensity: GlassIntensity.thin)
    }
}
