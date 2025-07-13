//
//  GlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Glass Card View
struct GlassCard<Content: View>: View {
    // Content
    let content: Content
    
    // Customization
    var intensity: GlassIntensity
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowRadius: CGFloat
    var borderWidth: CGFloat
    var isHovering: Bool
    var hasGlow: Bool
    var glowColor: Color
    
    // Animation state
    @State private var isPressed = false
    @State private var isHovered = false
    
    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        borderWidth: CGFloat = 1,
        isHovering: Bool = false,
        hasGlow: Bool = false,
        glowColor: Color = Color.blue,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.borderWidth = borderWidth
        self.isHovering = isHovering
        self.hasGlow = hasGlow
        self.glowColor = glowColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(glassBackground)
            .overlay(borderOverlay)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(0.2),
                radius: shadowRadius,
                x: 0,
                y: 5
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .onTapGesture {
                withAnimation(AnimationAnimation.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AnimationAnimation.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        ZStack {
            // Base material blur using existing GlassIntensity.material
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(intensity.material)
            
            // Glass gradient overlay
            RoundedRectangle(cornerRadius: cornerRadius)
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
            
            // Glow effect (optional)
            if hasGlow {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(glowColor.opacity(0.1))
                    .blur(radius: 10)
            }
        }
    }
    
    // MARK: - Border Overlay
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.6),
                        Color.white.opacity(0.2),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: borderWidth
            )
    }
}

// MARK: - Convenience Initializers
extension GlassCard {
    // Convenience initializer with just intensity
    init(
        intensity: GlassIntensity = .regular,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            intensity: intensity,
            cornerRadius: 20,
            padding: 20,
            shadowRadius: 10,
            borderWidth: 1,
            isHovering: false,
            hasGlow: false,
            glowColor: Color.blue,
            content: content
        )
    }
    
    // Convenience initializer with corner radius and padding
    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat,
        padding: CGFloat = 20,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            intensity: intensity,
            cornerRadius: cornerRadius,
            padding: padding,
            shadowRadius: 10,
            borderWidth: 1,
            isHovering: false,
            hasGlow: false,
            glowColor: Color.blue,
            content: content
        )
    }
}
