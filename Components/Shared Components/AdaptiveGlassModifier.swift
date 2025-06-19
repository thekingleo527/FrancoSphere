//
//  AdaptiveGlassModifier.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//  Consolidated adaptive glass material system with enhanced features
//

import SwiftUI
import Foundation

// MARK: - Enhanced Adaptive Glass Modifier
struct AdaptiveGlassModifier: ViewModifier {
    let scrollOffset: CGFloat
    let intensity: GlassIntensity
    let cornerRadius: CGFloat
    let opacity: Double
    let blur: CGFloat
    
    // Dynamic calculations based on scroll
    private var dynamicBlur: CGFloat {
        let scrollImpact = min(abs(scrollOffset) / 200, 1.0)
        return blur * (1 - scrollImpact * 0.3) // Reduce blur by up to 30% when scrolling
    }
    
    private var dynamicOpacity: Double {
        let scrollImpact = min(abs(scrollOffset) / 300, 1.0)
        let baseOpacity = opacity > 0 ? opacity : intensity.opacity
        return baseOpacity + (scrollImpact * 0.1) // Increase opacity slightly when scrolling
    }
    
    private var adaptiveIntensity: GlassIntensity {
        // Increase glass intensity when scrolling
        let scrollFactor = min(abs(scrollOffset) / 200, 1.0)
        
        switch intensity {
        case .ultraThin:
            return scrollFactor > 0.5 ? .thin : .ultraThin
        case .thin:
            return scrollFactor > 0.5 ? .regular : .thin
        case .regular:
            return scrollFactor > 0.7 ? .thick : .regular
        case .thick:
            return .thick
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base material layer
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(adaptiveIntensity.material.opacity(dynamicOpacity))
                    
                    // Glass background with ultra thin material
                    Rectangle()
                        .fill(Color.white.opacity(adaptiveIntensity.opacity * 0.3))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                    
                    // Gradient overlay for glass effect
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
                    
                    // Border with gradient
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(adaptiveIntensity.opacity * 2),
                                    Color.white.opacity(adaptiveIntensity.opacity)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .blur(radius: dynamicBlur * 0.01) // Very subtle blur on the content itself
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

// MARK: - View Extension
extension View {
    /// Applies adaptive glass material with scroll-aware effects
    func adaptiveGlass(
        scrollOffset: CGFloat = 0,
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 16,
        opacity: Double = 0,
        blur: CGFloat = 20
    ) -> some View {
        self.modifier(
            AdaptiveGlassModifier(
                scrollOffset: scrollOffset,
                intensity: intensity,
                cornerRadius: cornerRadius,
                opacity: opacity,
                blur: blur
            )
        )
    }
    
    /// Enhanced adaptive glass with simplified parameters
    func enhancedAdaptiveGlass(
        scrollOffset: CGFloat,
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 16
    ) -> some View {
        self.adaptiveGlass(
            scrollOffset: scrollOffset,
            intensity: intensity,
            cornerRadius: cornerRadius,
            opacity: intensity.opacity,
            blur: intensity.blurRadius
        )
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
    let cornerRadius: CGFloat
    
    @State private var isPressed = false
    @GestureState private var dragOffset: CGSize = .zero
    @State private var scrollOffset: CGFloat = 0
    
    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        content
            .adaptiveGlass(
                scrollOffset: scrollOffset,
                intensity: intensity,
                cornerRadius: cornerRadius
            )
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
                    .onChanged { value in
                        scrollOffset = value.translation.height
                    }
            )
    }
}

// MARK: - Preview Provider
struct AdaptiveGlassModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Regular glass effect
                    Text("Adaptive Glass Effect")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .adaptiveGlass(
                            scrollOffset: 0,
                            intensity: .regular
                        )
                    
                    // Enhanced glass effect
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enhanced Glass")
                            .font(.headline)
                        Text("With scroll-aware effects")
                            .font(.subheadline)
                            .opacity(0.8)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .enhancedAdaptiveGlass(
                        scrollOffset: 50,
                        intensity: .thin
                    )
                    
                    // Interactive glass card
                    InteractiveGlassCard(intensity: .regular) {
                        VStack(spacing: 12) {
                            Image(systemName: "cube.transparent")
                                .font(.largeTitle)
                            Text("Interactive Glass Card")
                                .font(.headline)
                            Text("Drag or press to interact")
                                .font(.caption)
                                .opacity(0.7)
                        }
                        .foregroundColor(.white)
                        .padding()
                    }
                    
                    // Different intensities
                    ForEach([GlassIntensity.ultraThin, .thin, .regular, .thick], id: \.self) { intensity in
                        HStack {
                            Text("\(String(describing: intensity).capitalized) Intensity")
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .adaptiveGlass(intensity: intensity)
                        }
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
// MARK: - FrancoSphere Convenience Methods
extension View {
    /// Standard FrancoSphere glass card style
    func francoGlassCard() -> some View {
        self.adaptiveGlass(
            intensity: .regular,
            cornerRadius: 16,
            opacity: 0.1,
            blur: 20
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    /// Compact FrancoSphere glass card style
    func francoGlassCardCompact() -> some View {
        self.adaptiveGlass(
            intensity: .thin,
            cornerRadius: 12,
            opacity: 0.08,
            blur: 15
        )
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}
