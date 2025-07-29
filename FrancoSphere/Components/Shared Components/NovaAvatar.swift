import SwiftUI
// Import Nova Types
// All Nova types (NovaContext, NovaPrompt, etc.) come from NovaTypes.swift

//
//  NovaAvatar.swift - UNIFIED VERSION
//  FrancoSphere
//
//  ✅ Uses Size enum pattern
//  ✅ Integrates AIAssistantImageLoader.circularAIAssistantView
//  ✅ Maintains sophisticated animations
//  ✅ Circular image with pulsating effects
//  ✅ FIXED: iOS 17 onChange syntax and method parameters
//

import SwiftUI

// MARK: - Nova Avatar Component
struct NovaAvatar: View {
    // Configuration
    let size: Size
    let isActive: Bool
    let hasUrgentInsights: Bool
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
        size: Size = .large,
        isActive: Bool = false,
        hasUrgentInsights: Bool = false,
        isBusy: Bool = false,
        onTap: @escaping () -> Void = {},
        onLongPress: @escaping () -> Void = {}
    ) {
        self.size = size
        self.isActive = isActive
        self.hasUrgentInsights = hasUrgentInsights
        self.isBusy = isBusy
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        ZStack {
            // Pulsating ring when busy
            if isBusy {
                busyPulseRing
            }
            
            // Main avatar using AIAssistantImageLoader
            avatarView
                .overlay(glowEffect)
                .overlay(urgentPulseRing)
                .scaleEffect(breathe ? 1.03 : 0.97)
                .shadow(
                    color: glowColor.opacity(glowOpacity),
                    radius: size.shadowRadius,
                    x: 0,
                    y: size.shadowOffset
                )
                .onAppear {
                    startBreathingAnimation()
                    if isBusy {
                        startBusyAnimation()
                    }
                }
                .onTapGesture { onTap() }
                .onLongPressGesture { onLongPress() }
            
            // Status badge
            if isActive || hasUrgentInsights || isBusy {
                statusBadge
                    .offset(
                        x: size.dimension * 0.35,
                        y: -size.dimension * 0.35
                    )
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: breathe)
        .onChange(of: isBusy) { oldValue, newValue in
            if newValue {
                startBusyAnimation()
            } else {
                stopBusyAnimation()
            }
        }
    }
    
    // MARK: - Avatar View using AIAssistantImageLoader
    private var avatarView: some View {
        ZStack {
            // Base avatar with custom border
            AIAssistantImageLoader.circularAIAssistantView(
                diameter: size.dimension,
                borderColor: borderColor
            )
            
            // Custom border overlay for width control
            Circle()
                .stroke(borderColor, lineWidth: borderWidth)
                .frame(width: size.dimension, height: size.dimension)
            
            // Rotation effect overlay when busy
            if isBusy {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.6),
                                Color.blue.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: size.dimension, height: size.dimension)
                    .rotationEffect(.degrees(rotationAngle))
            }
        }
    }
    
    // MARK: - Busy Pulse Ring
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
            .frame(
                width: size.dimension + 16,
                height: size.dimension + 16
            )
            .scaleEffect(busyPulse ? 1.2 : 1.0)
            .opacity(busyPulse ? 0.0 : 0.8)
            .animation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: false),
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
            if hasUrgentInsights {
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(
                        width: size.dimension + 8,
                        height: size.dimension + 8
                    )
                    .scaleEffect(pulseScale)
                    .opacity(2.0 - pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: false),
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
                .frame(
                    width: size.badgeSize,
                    height: size.badgeSize
                )
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            statusIcon
                .font(.system(size: size.badgeIconSize, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Computed Properties
    
    private var borderColor: Color {
        if hasUrgentInsights { return .orange }
        if isBusy { return .purple }
        if isActive { return .green }
        return .purple
    }
    
    private var borderWidth: CGFloat {
        isActive || hasUrgentInsights || isBusy ? 2 : 1
    }
    
    private var glowColor: Color {
        if isBusy { return .purple }
        if hasUrgentInsights { return .orange }
        if isActive { return .green }
        return .blue
    }
    
    private var statusBadgeColor: Color {
        if isBusy { return .purple }
        if hasUrgentInsights { return .orange }
        if isActive { return .green }
        return .blue
    }
    
    private var statusIcon: Image {
        if isBusy {
            return Image(systemName: "brain")
        } else if hasUrgentInsights {
            return Image(systemName: "exclamationmark")
        } else if isActive {
            return Image(systemName: "waveform")
        } else {
            return Image(systemName: "checkmark")
        }
    }
    
    // MARK: - Animation Methods
    
    private func startBreathingAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
        ) {
            breathe = true
        }
        
        withAnimation(
            Animation.easeInOut(duration: 3.0)
                .repeatForever(autoreverses: true)
        ) {
            glowOpacity = 0.8
        }
    }
    
    private func startBusyAnimation() {
        withAnimation(
            Animation.easeInOut(duration: 1.0)
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

// MARK: - Size Enum
extension NovaAvatar {
    enum Size {
        case small   // 40x40
        case medium  // 50x50
        case large   // 60x60
        
        var dimension: CGFloat {
            switch self {
            case .small: return 40
            case .medium: return 50
            case .large: return 60
            }
        }
        
        var badgeSize: CGFloat {
            dimension * 0.25
        }
        
        var badgeIconSize: CGFloat {
            dimension * 0.12
        }
        
        var shadowRadius: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 12
            }
        }
        
        var shadowOffset: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
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
                // Size variations
                HStack(spacing: 30) {
                    VStack {
                        NovaAvatar(size: .small)
                        Text("Small")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack {
                        NovaAvatar(size: .medium)
                        Text("Medium")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    VStack {
                        NovaAvatar(size: .large)
                        Text("Large")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // State variations
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        VStack {
                            NovaAvatar(
                                size: .large,
                                isActive: true,
                                onTap: { print("Active Nova tapped") }
                            )
                            Text("Active")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            NovaAvatar(
                                size: .large,
                                hasUrgentInsights: true,
                                onTap: { print("Urgent Nova tapped") }
                            )
                            Text("Urgent")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            NovaAvatar(
                                size: .large,
                                isBusy: true,
                                onTap: { print("Busy Nova tapped") }
                            )
                            Text("Busy")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    HStack(spacing: 30) {
                        VStack {
                            NovaAvatar(
                                size: .large,
                                isActive: true,
                                hasUrgentInsights: true,
                                onTap: { print("Active + Urgent Nova tapped") }
                            )
                            Text("Active + Urgent")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        VStack {
                            NovaAvatar(
                                size: .large,
                                hasUrgentInsights: true,
                                isBusy: true,
                                onTap: { print("Busy + Urgent Nova tapped") }
                            )
                            Text("Busy + Urgent")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                
                Text("Tap any Nova avatar to test interactions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .preferredColorScheme(.dark)
    }
}
