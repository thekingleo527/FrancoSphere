//
//  AdaptiveGlassModifier.swift
//  FrancoSphere
//
//  🔧 HF-25: UNIFIED GLASSMORPHISM SYSTEM (2040 STANDARD)
//  🔧 FIX #1: Backward compatibility for existing code
//  Consistent glass styling across all FrancoSphere components
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct AdaptiveGlassModifier: ViewModifier {
    let isCompact: Bool
    let intensity: GlassIntensity
    
    enum GlassIntensity {
        case subtle, standard, bold
        
        var strokeOpacity: Double {
            switch self {
            case .subtle: return 0.05
            case .standard: return 0.1
            case .bold: return 0.15
            }
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .subtle: return 6
            case .standard: return 12
            case .bold: return 20
            }
        }
    }
    
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
    func francoGlassCard(intensity: AdaptiveGlassModifier.GlassIntensity = .standard) -> some View {
        self
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(intensity.strokeOpacity), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: intensity.shadowRadius, x: 0, y: 6)
    }
    
    /// Compact Franco glass card for list items and smaller components
    func francoGlassCardCompact(intensity: AdaptiveGlassModifier.GlassIntensity = .standard) -> some View {
        self
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(max(0.08, intensity.strokeOpacity)), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.1), radius: intensity.shadowRadius * 0.67, x: 0, y: 4)
    }
    
    /// Adaptive glass wrapper with size-based selection
    func adaptiveGlass(compact: Bool = false, intensity: AdaptiveGlassModifier.GlassIntensity = .standard) -> some View {
        self.modifier(AdaptiveGlassModifier(isCompact: compact, intensity: intensity))
    }
    
    // 🔧 FIX #1: Backward compatibility for existing code
    @available(*, deprecated, message: "Use adaptiveGlass(compact:) instead")
    func adaptiveGlassModifier(useCompact: Bool = false) -> some View {
        self.adaptiveGlass(compact: useCompact, intensity: .standard)
    }
}

// MARK: - 🔧 SPECIALIZED GLASS VARIANTS

extension View {
    /// Glass card optimized for hero/status cards
    func francoGlassHero() -> some View {
        self.francoGlassCard(intensity: .bold)
    }
    
    /// Glass card optimized for list rows
    func francoGlassRow() -> some View {
        self.francoGlassCardCompact(intensity: .subtle)
    }
    
    /// Glass card for modal/overlay content
    func francoGlassModal() -> some View {
        self
            .padding(20)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
    }
}

// MARK: - 🔧 DESIGN SYSTEM VALIDATION

#if DEBUG
struct GlassCardPreview: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Franco Glass System Demo")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .francoGlassHero()
                
                HStack(spacing: 16) {
                    VStack {
                        Text("Standard")
                            .foregroundColor(.white)
                    }
                    .francoGlassCard()
                    
                    VStack {
                        Text("Compact")
                            .foregroundColor(.white)
                    }
                    .francoGlassCardCompact()
                }
                
                VStack {
                    Text("List Row Example")
                        .foregroundColor(.white)
                }
                .francoGlassRow()
                
                Text("All glass cards use .ultraThinMaterial, consistent stroke opacity, and proportional shadows")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .francoGlassCardCompact()
            }
            .padding(20)
        }
    }
}

struct AdaptiveGlassModifier_Previews: PreviewProvider {
    static var previews: some View {
        GlassCardPreview()
            .preferredColorScheme(.dark)
    }
}
#endif
