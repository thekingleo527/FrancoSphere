//
//  NovaAvatar.swift - PHASE-2 FIXED VERSION
//  FrancoSphere
//
//  ✅ Fixed to load AIAssistant image from Assets
//  ✅ Added pulsating ring when isBusy
//  ✅ Circular image loading with fallback
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


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
    @State private var busyPulse = false
    
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
            // ✅ FIXED: Pulsating ring when busy
            if isBusy {
                busyPulseRing
            }
            
            // Main avatar
            avatarView
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(glowEffect)
                .overlay(urgentPulseRing)
                .scaleEffect(breathe ? 1.03 : 0.97)
                .shadow(color: glowColor.opacity(glowOpacity), radius: 12, x: 0, y: 4)
                .onAppear {
                    startBreathingAnimation()
                    if isBusy {
                        startBusyAnimation()
                    }
                }
                .onTapGesture { onTap() }
                .onLongPressGesture { onLongPress() }
            
            // Status badge
            if showStatus {
                statusBadge
                    .offset(x: size * 0.35, y: -size * 0.35)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: breathe)
        .onChange(of: isBusy) { newValue in
            if newValue {
                startBusyAnimation()
            } else {
                stopBusyAnimation()
            }
        }
    }
    
    // MARK: - ✅ FIXED: Avatar Image (loads AIAssistant from Assets)
    private var avatarView: some View {
        ZStack {
            // Background gradient (fallback)
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
            
            // ✅ FIXED: Load AIAssistant image from Assets
            if let aiAssistantImage = UIImage(named: "AIAssistant") {
                Image(uiImage: aiAssistantImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Fallback to system icon if image not found
                Image(systemName: "brain.head.profile")
                    .font(.system(size: size * 0.5, weight: .medium))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(rotationAngle))
            }
        }
    }
    
    // MARK: - ✅ NEW: Busy Pulse Ring
    private var busyPulseRing: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color.blue,
                        Color.purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 3
            )
            .frame(width: size + 16, height: size + 16)
            .scaleEffect(busyPulse ? 1.2 : 1.0)
            .opacity(busyPulse ? 0.0 : 0.8)
            .animation(
                AnimationAnimation.easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                value: busyPulse
            )
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
            .opacity(breathe ? 0.9 : 0.6)
    }
    
    // MARK: - Urgent Pulse Ring
    private var urgentPulseRing: some View {
        Group {
            if hasUrgentInsight {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: size + 8, height: size + 8)
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                    .animation(
                        AnimationAnimation.easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                        value: pulseScale
                    )
                    .onAppear {
                        pulseScale = 1.3
                    }
            }
        }
    }
    
    // MARK: - Status Badge
    private var statusBadge: some View {
        ZStack {
            Circle()
                .fill(statusBadgeColor)
                .frame(width: size * 0.25, height: size * 0.25)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            if isBusy {
                Image(systemName: "brain")
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundColor(.white)
            } else if hasUrgentInsight {
                Image(systemName: "exclamationmark")
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var glowColor: Color {
        if isBusy { return .purple }
        if hasUrgentInsight { return .orange }
        return .blue
    }
    
    private var statusBadgeColor: Color {
        if isBusy { return .purple }
        if hasUrgentInsight { return .orange }
        return .green
    }
    
    // MARK: - Animation Methods
    
    private func startBreathingAnimation() {
        withAnimation(
            AnimationAnimation.easeInOut(duration: 2.0)
            .repeatForever(autoreverses: true)
        ) {
            breathe = true
        }
        
        withAnimation(
            AnimationAnimation.easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.8
        }
    }
    
    private func startBusyAnimation() {
        withAnimation(
            AnimationAnimation.easeInOut(duration: 1.0)
            .repeatForever(autoreverses: false)
        ) {
            busyPulse = true
        }
        
        withAnimation(
            Animation.linear(duration: 4.0)
            .repeatForever(autoreverses: false)
        ) {
            rotationAngle = 360
        }
    }
    
    private func stopBusyAnimation() {
        busyPulse = false
        rotationAngle = 0
    }
}

// MARK: - Animation Helper Views

struct PulseRing: View {
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let animationDuration: Double
    let maxScale: CGFloat
    let opacity: Double
    
    @State private var isAnimating = false
    
    init(
        color: Color,
        size: CGFloat,
        lineWidth: CGFloat = 2,
        animationDuration: Double = 1.0,
        maxScale: CGFloat = 1.3,
        opacity: Double = 0.6
    ) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.animationDuration = animationDuration
        self.maxScale = maxScale
        self.opacity = opacity
    }
    
    var body: some View {
        Circle()
            .stroke(color, lineWidth: lineWidth)
            .frame(width: size, height: size)
            .scaleEffect(isAnimating ? maxScale : 1.0)
            .opacity(isAnimating ? 0 : opacity)
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: animationDuration)
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
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Regular state
                NovaAvatar(
                    size: 60,
                    showStatus: true,
                    hasUrgentInsight: false,
                    isBusy: false,
                    onTap: { print("Nova tapped") },
                    onLongPress: { print("Nova long pressed") }
                )
                
                // With urgent insight
                NovaAvatar(
                    size: 60,
                    hasUrgentInsight: true,
                    onTap: { print("Urgent Nova tapped") }
                )
                
                // Busy state
                NovaAvatar(
                    size: 60,
                    isBusy: true,
                    onTap: { print("Busy Nova tapped") }
                )
                
                // Different sizes
                HStack(spacing: 30) {
                    NovaAvatar(size: 44)
                    NovaAvatar(size: 80)
                    NovaAvatar(size: 100, isBusy: true)
                }
                
                Text("Tap any Nova avatar to test interactions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .preferredColorScheme(.dark)
    }
}
