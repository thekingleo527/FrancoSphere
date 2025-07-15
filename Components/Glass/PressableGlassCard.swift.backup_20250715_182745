//
//  PressableGlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  PressableGlassCard.swift
//  FrancoSphere
//
//  Pressable glass card component for interactive cards
//  Created by Assistant on 6/8/25.

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Pressable Glass Card
struct PressableGlassCard<Content: View>: View {
    // Content
    let content: Content
    let action: () -> Void
    
    // Style properties
    var intensity: GlassIntensity
    var cornerRadius: CGFloat
    var padding: CGFloat
    var shadowRadius: CGFloat
    var borderWidth: CGFloat
    var hasGlow: Bool
    var glowColor: Color
    
    // Animation state
    @State private var isPressed = false
    
    init(
        intensity: GlassIntensity = .regular,
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        shadowRadius: CGFloat = 10,
        borderWidth: CGFloat = 1,
        hasGlow: Bool = false,
        glowColor: Color = .blue,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.action = action
        self.intensity = intensity
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.shadowRadius = shadowRadius
        self.borderWidth = borderWidth
        self.hasGlow = hasGlow
        self.glowColor = glowColor
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            content
                .padding(padding)
                .background(glassBackground)
                .overlay(borderOverlay)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .shadow(
            color: Color.black.opacity(isPressed ? 0.3 : 0.2),
            radius: isPressed ? shadowRadius + 5 : shadowRadius,
            x: 0,
            y: isPressed ? 8 : 5
        )
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(AnimationAnimation.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    // MARK: - Glass Background
    private var glassBackground: some View {
        ZStack {
            // Base material blur
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(intensity.material)
            
            // Glass gradient overlay
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isPressed ? 0.05 : 0.15),
                            Color.white.opacity(isPressed ? 0.02 : 0.05),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Glow effect (optional)
            if hasGlow {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(glowColor.opacity(isPressed ? 0.15 : 0.1))
                    .blur(radius: 10)
            }
            
            // Pressed state overlay
            if isPressed {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white.opacity(0.05))
            }
        }
    }
    
    // MARK: - Border Overlay
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(isPressed ? 0.4 : 0.6),
                        Color.white.opacity(isPressed ? 0.1 : 0.2),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: borderWidth
            )
    }
}

// MARK: - Preview
struct PressableGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                PressableGlassCard(intensity: .regular) {
                    print("Clock In tapped")
                } content: {
                    HStack {
                        Image(systemName: "clock.badge.checkmark")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text("CLOCK IN")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                }
                
                PressableGlassCard(intensity: .thin, hasGlow: true, glowColor: .green) {
                    print("Task tapped")
                } content: {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("Complete Task")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                PressableGlassCard(intensity: .thick, cornerRadius: 30) {
                    print("Settings tapped")
                } content: {
                    VStack(spacing: 12) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.white)
                        Text("Settings")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        Text("Configure your preferences")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}