
///
//  GlassMorphismStyles.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed all duplicate declarations
//  ✅ USES: Existing GlassIntensity from GlassTypes.swift
//  ✅ USES: Existing francoGlassCard() from AdaptiveGlassModifier.swift
//  ✅ USES: Existing GlassStatusBadge, GlassNavigationBar, GlassLoadingView
//  ✅ ADDS: Only non-conflicting helper utilities
//

import SwiftUI

// MARK: - Additional Glass Effects (Non-conflicting utilities only)

extension View {
    /// Glass effect with custom background color
    func glassTinted(_ color: Color, intensity: GlassIntensity = .regular) -> some View {
        self
            .francoGlassCard(intensity: intensity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
            )
    }
    
    /// Glass effect with pulsing animation
    func glassPulsing(color: Color = .blue, intensity: GlassIntensity = .regular) -> some View {
        self
            .francoGlassCard(intensity: intensity)
            .modifier(PulsingGlassModifier(color: color))
    }
    
    /// Glass effect with shimmer animation
    func glassShimmer(intensity: GlassIntensity = .regular) -> some View {
        self
            .francoGlassCard(intensity: intensity)
            .modifier(ShimmerGlassModifier())
    }
}

// MARK: - Glass Animation Modifiers (New, non-conflicting)

struct PulsingGlassModifier: ViewModifier {
    let color: Color
    @State private var isPulsing = false
    
    init(color: Color) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(isPulsing ? 0.8 : 0.3), lineWidth: 2)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isPulsing
                    )
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerGlassModifier: ViewModifier {
    @State private var startPoint = UnitPoint.topLeading
    @State private var endPoint = UnitPoint.bottomTrailing
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: startPoint
                )
                .onAppear {
                    withAnimation {
                        startPoint = .bottomTrailing
                        endPoint = .topLeading
                    }
                }
            )
    }
}

// MARK: - Glass Typography Helpers (New utilities)

extension Text {
    /// Applies glass-friendly text styling
    func glassText(size: Font = .body, weight: Font.Weight = .medium) -> some View {
        self
            .font(size.weight(weight))
            .foregroundColor(.white)
            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
    }
    
    /// Applies glass heading styling
    func glassHeading() -> some View {
        self.glassText(size: .title2, weight: .bold)
    }
    
    /// Applies glass subtitle styling
    func glassSubtitle() -> some View {
        self.glassText(size: .subheadline, weight: .medium)
            .foregroundColor(.white.opacity(0.8))
    }
    
    /// Applies glass caption styling
    func glassCaption() -> some View {
        self.glassText(size: .caption, weight: .regular)
            .foregroundColor(.white.opacity(0.7))
    }
}

// MARK: - Glass Color Utilities (New helpers)

extension Color {
    /// Glass-friendly colors with proper opacity
    static let glassWhite = Color.white.opacity(0.15)
    static let glassBlack = Color.black.opacity(0.15)
    static let glassBlue = Color.blue.opacity(0.2)
    static let glassPurple = Color.purple.opacity(0.2)
    static let glassGreen = Color.green.opacity(0.2)
    static let glassOrange = Color.orange.opacity(0.2)
    static let glassRed = Color.red.opacity(0.2)
    
    /// Creates a glass-friendly version of any color
    func glassVariant(opacity: Double = 0.2) -> Color {
        return self.opacity(opacity)
    }
}

// MARK: - Glass Layout Helpers (New utilities)

extension View {
    /// Standard glass card spacing for FrancoSphere
    func francoSpacing() -> some View {
        self.padding(.vertical, 12)
    }
    
    /// Standard glass section spacing
    func francoSectionSpacing() -> some View {
        self.padding(.vertical, 20)
    }
    
    /// Glass-friendly divider
    func glassDivider() -> some View {
        VStack {
            self
            
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal)
        }
    }
}

// MARK: - Safe Area Utilities (Enhanced version)

extension View {
    /// Smart safe area handling for glass components
    func glassSafeArea() -> some View {
        self
            .ignoresSafeArea(edges: [.horizontal, .bottom])
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
    }
    
    /// Glass navigation bar safe area
    func glassNavigationSafeArea() -> some View {
        self.padding(.top, getSafeAreaTop())
    }
}

// MARK: - Helper Functions (New utilities)

private func getSafeAreaTop() -> CGFloat {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let window = windowScene.windows.first else {
        return 0
    }
    return window.safeAreaInsets.top
}

// MARK: - Glass Configuration (New utility)

struct GlassConfiguration {
    static let defaultCornerRadius: CGFloat = 16
    static let compactCornerRadius: CGFloat = 12
    static let defaultPadding: CGFloat = 16
    static let compactPadding: CGFloat = 12
    static let defaultShadowRadius: CGFloat = 10
    static let strokeOpacity: Double = 0.1
    
    // Animation durations
    static let quickAnimation: Double = 0.2
    static let standardAnimation: Double = 0.3
    static let slowAnimation: Double = 0.5
}

// MARK: - Preview Helper (New utility)

#if DEBUG
struct GlassPreviewHelper: View {
    var body: some View {
        ZStack {
            // Background gradient for testing glass effects
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Glass Effect Preview")
                    .glassHeading()
                
                Text("Standard glass card using existing francoGlassCard()")
                    .glassSubtitle()
                    .francoGlassCard()
                
                Text("Compact glass card using existing francoGlassCardCompact()")
                    .glassCaption()
                    .francoGlassCardCompact()
                
                Text("Tinted glass effect")
                    .glassText()
                    .glassTinted(.blue)
                
                Text("Pulsing glass effect")
                    .glassText()
                    .glassPulsing(color: .purple)
            }
            .padding()
        }
    }
}

struct GlassMorphismStyles_Previews: PreviewProvider {
    static var previews: some View {
        GlassPreviewHelper()
            .preferredColorScheme(.dark)
    }
}
#endif
