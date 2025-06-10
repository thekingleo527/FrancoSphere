//
//  AdaptiveGlassModifier.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//


//
//  AdaptiveGlassModifier.swift
//  FrancoSphere
//
//  Adaptive glass material system for dynamic UI effects
//

import SwiftUI

// MARK: - Adaptive Glass View Modifier
extension View {
    /// Applies adaptive glass material with scroll-aware blur
    func adaptiveGlass(
        opacity: Double = 0.15,
        blur: CGFloat = 20,
        radius: CGFloat = 22,
        scrollOffset: CGFloat = 0,
        intensity: GlassIntensity = .regular
    ) -> some View {
        self.modifier(
            AdaptiveGlassModifier(
                opacity: opacity,
                blur: blur,
                radius: radius,
                scrollOffset: scrollOffset,
                intensity: intensity
            )
        )
    }
}

// MARK: - Adaptive Glass Modifier
struct AdaptiveGlassModifier: ViewModifier {
    let opacity: Double
    let blur: CGFloat
    let radius: CGFloat
    let scrollOffset: CGFloat
    let intensity: GlassIntensity
    
    // Dynamic calculations based on scroll
    private var dynamicBlur: CGFloat {
        let scrollImpact = min(abs(scrollOffset) / 200, 1.0)
        return blur * (1 - scrollImpact * 0.3) // Reduce blur by up to 30% when scrolling
    }
    
    private var dynamicOpacity: Double {
        let scrollImpact = min(abs(scrollOffset) / 300, 1.0)
        return opacity + (scrollImpact * 0.1) // Increase opacity slightly when scrolling
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material layer
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(intensity.material.opacity(dynamicOpacity))
                    
                    // Gradient overlay for glass effect
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle inner shadow for depth
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .blur(radius: dynamicBlur * 0.01) // Very subtle blur on the content itself
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - Glass Intensity Extension
extension GlassIntensity {
    var material: Material {
        switch self {
        case .ultraThin:
            return .ultraThinMaterial
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        case .ultraThick:
            return .ultraThickMaterial
        }
    }
}

// MARK: - Glass Shadow Modifier
extension View {
    func glassShadow(
        color: Color = .black,
        radius: CGFloat = 10,
        x: CGFloat = 0,
        y: CGFloat = 5,
        opacity: Double = 0.2
    ) -> some View {
        self.shadow(
            color: color.opacity(opacity),
            radius: radius,
            x: x,
            y: y
        )
    }
}

// MARK: - Interactive Glass Card
struct InteractiveGlassCard<Content: View>: View {
    let content: Content
    let intensity: GlassIntensity
    
    @State private var isPressed = false
    @GestureState private var dragOffset: CGSize = .zero
    
    init(
        intensity: GlassIntensity = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
    }
    
    var body: some View {
        content
            .adaptiveGlass(intensity: intensity)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .offset(dragOffset)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragOffset)
            .onLongPressGesture(
                minimumDuration: 0.1,
                maximumDistance: .infinity,
                pressing: { isPressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = isPressing
                    }
                },
                perform: {}
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
            )
    }
}