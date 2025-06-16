////
//  NovaAvatar.swift
//  FrancoSphere
//
//  Standalone Nova AI Assistant Avatar Component
//  Created by Shawn Magloire on 6/9/25.
//

import SwiftUI

// MARK: - Nova Avatar Component
struct NovaAvatar: View {
    // Configuration
    let size: CGFloat
    let showStatus: Bool
    let hasUrgentInsight: Bool
    let isBusy: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    // Animation states
    @State private var breathe = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var rotationAngle: Double = 0
    
    init(
        size: CGFloat = 60,
        showStatus: Bool = true,
        hasUrgentInsight: Bool = false,
        isBusy: Bool = false,
        onTap: @escaping () -> Void = {},
        onLongPress: @escaping () -> Void = {}
    ) {
        self.size = size
        self.showStatus = showStatus
        self.hasUrgentInsight = hasUrgentInsight
        self.isBusy = isBusy
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        ZStack {
            // Main avatar
            avatarView
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(glowEffect)
                .overlay(urgentPulseRing)
                .overlay(busyIndicator)
                .scaleEffect(breathe ? 1.03 : 0.97)
                .shadow(color: glowColor.opacity(glowOpacity), radius: 12, x: 0, y: 4)
                .onAppear { startBreathingAnimation() }
                .onTapGesture { onTap() }
                .onLongPressGesture { onLongPress() }
            
            // Status badge
            if showStatus {
                statusBadge
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: breathe)
    }
    
    // MARK: - Avatar Image
    private var avatarView: some View {
        ZStack {
            // Background gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // AI Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: size * 0.5, weight: .medium))
                .foregroundColor(.white)
                .rotationEffect(.degrees(rotationAngle))
        }
    }
    
    // MARK: - Glow Effect
    private var glowEffect: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        glowColor.opacity(0.6),
                        glowColor.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 2
            )
            .blur(radius: 4)
            .opacity(breathe ? 0.8 : 0.4)
    }
    
    // MARK: - Urgent Pulse Ring
    @ViewBuilder
    private var urgentPulseRing: some View {
        if hasUrgentInsight {
            PulseRing(
                color: .red,
                animationDuration: 1.0,
                maxScale: 1.5
            )
        }
    }
    
    // MARK: - Busy/Offline Indicator
    @ViewBuilder
    private var busyIndicator: some View {
        if isBusy {
            ZStack {
                // Dark overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                
                // Loading spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        }
    }
    
    // MARK: - Status Badge
    @ViewBuilder
    private var statusBadge: some View {
        if hasUrgentInsight {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        }
    }
    
    // MARK: - Computed Properties
    private var glowColor: Color {
        if hasUrgentInsight {
            return .red
        } else if isBusy {
            return .orange
        } else {
            return .blue
        }
    }
    
    // MARK: - Animations
    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 3)
            .repeatForever(autoreverses: true)
        ) {
            breathe.toggle()
        }
        
        // Subtle rotation for the icon
        withAnimation(
            .linear(duration: 20)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
}

// MARK: - Pulse Ring Component
struct PulseRing: View {
    let color: Color
    let animationDuration: Double
    let maxScale: CGFloat
    
    @State private var isAnimating = false
    @State private var opacity: Double = 0.8
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .scaleEffect(isAnimating ? maxScale : 1.0)
            .opacity(isAnimating ? 0 : opacity)
            .onAppear {
                withAnimation(
                    .easeOut(duration: animationDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Preview
struct NovaAvatar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            FrancoSphereColors.primaryBackground.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Regular state
                NovaAvatar(
                    size: 60,
                    showStatus: true,
                    hasUrgentInsight: false,
                    isBusy: false,
                    onTap: {},
                    onLongPress: {}
                )
                
                // With urgent insight
                NovaAvatar(hasUrgentInsight: true)
                
                // Busy state
                NovaAvatar(isBusy: true)
                
                // Different sizes
                HStack(spacing: 30) {
                    NovaAvatar(size: 44)
                    NovaAvatar(size: 80)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
