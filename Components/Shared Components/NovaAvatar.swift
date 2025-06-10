//
//  NovaAvatar.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//


//
//  NovaAvatar.swift
//  FrancoSphere
//
//  Animated AI Assistant Avatar Component
//

import SwiftUI

// MARK: - Nova Avatar Component
struct NovaAvatar: View {
    @EnvironmentObject var ai: AIAssistantManager
    @Environment(\.sizeCategory) var sizeCategory
    @AppStorage("aiAvatarURL") private var avatarURL = ""
    
    // Animation states
    @State private var breathe = false
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3
    @State private var rotationAngle: Double = 0
    
    // Configuration
    var size: CGFloat = 60
    var showStatus: Bool = true
    var onTap: (() -> Void)?
    var onLongPress: (() -> Void)?
    
    // Accessibility adjustments
    private var adjustedSize: CGFloat {
        sizeCategory >= .accessibilityMedium ? 48 : size
    }
    
    private var adjustedGlowOpacity: Double {
        sizeCategory >= .accessibilityMedium ? 0.2 : glowOpacity
    }
    
    var body: some View {
        ZStack {
            // Main avatar
            avatarView
                .frame(width: adjustedSize, height: adjustedSize)
                .clipShape(Circle())
                .overlay(glowEffect)
                .overlay(urgentPulseRing)
                .overlay(busyIndicator)
                .scaleEffect(breathe ? 1.03 : 0.97)
                .shadow(color: glowColor.opacity(adjustedGlowOpacity), radius: 12, x: 0, y: 4)
                .onAppear { startBreathingAnimation() }
                .onTapGesture { onTap?() }
                .onLongPressGesture { onLongPress?() }
            
            // Status badge
            if showStatus {
                statusBadge
                    .offset(x: adjustedSize * 0.35, y: -adjustedSize * 0.35)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: breathe)
    }
    
    // MARK: - Avatar Image
    @ViewBuilder
    private var avatarView: some View {
        if !avatarURL.isEmpty, let url = URL(string: avatarURL) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                defaultAvatar
            }
        } else {
            defaultAvatar
        }
    }
    
    private var defaultAvatar: some View {
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
                .font(.system(size: adjustedSize * 0.5, weight: .medium))
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
        if ai.hasUrgentInsight {
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
        if ai.isProcessing {
            ZStack {
                // Dark overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                
                // Loading spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
            }
        } else if ai.isOffline {
            ZStack {
                // Dark overlay
                Circle()
                    .fill(Color.black.opacity(0.4))
                
                // Offline icon
                Image(systemName: "wifi.slash")
                    .font(.system(size: adjustedSize * 0.3))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Status Badge
    @ViewBuilder
    private var statusBadge: some View {
        if ai.hasUrgentInsight {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
        } else if ai.unreadNotifications > 0 {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                
                Text("\(min(ai.unreadNotifications, 9))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var glowColor: Color {
        if ai.hasUrgentInsight {
            return .red
        } else if ai.isProcessing {
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

// MARK: - AI Assistant Manager Extension
extension AIAssistantManager {
    // Mock properties for preview/testing
    var hasUrgentInsight: Bool {
        // This would check actual urgent insights
        return false
    }
    
    var isProcessing: Bool {
        // This would check if AI is currently processing
        return false
    }
    
    var isOffline: Bool {
        // This would check connectivity status
        return false
    }
    
    var unreadNotifications: Int {
        // This would return actual unread count
        return 0
    }
}

// MARK: - Preview
struct NovaAvatar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Regular state
                NovaAvatar()
                    .environmentObject(AIAssistantManager.shared)
                
                // With urgent insight
                NovaAvatar()
                    .environmentObject({
                        let ai = AIAssistantManager.shared
                        // Set mock urgent state for preview
                        return ai
                    }())
                
                // Different sizes
                HStack(spacing: 30) {
                    NovaAvatar(size: 44)
                        .environmentObject(AIAssistantManager.shared)
                    
                    NovaAvatar(size: 80)
                        .environmentObject(AIAssistantManager.shared)
                }
            }
        }
    }
}