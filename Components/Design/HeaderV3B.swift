//
//  HeaderV3B.swift - CLEAN VERSION WITH WORKING AI INTEGRATION
//  FrancoSphere
//
//  ✅ FIXED: Correct AIAssistantManager method calls
//  ✅ FIXED: Proper @StateObject usage
//  ✅ FIXED: Clean structure without extra braces
//  ✅ FIXED: Simplified Nova avatar integration
//  ✅ ProfileBadge uses teal accent color
//  ✅ Maintains ≤80pt total height
//

import SwiftUI

struct HeaderV3B: View {
    let workerName: String
    let clockedInStatus: Bool
    let onClockToggle: () -> Void
    let onProfilePress: () -> Void
    let nextTaskName: String?
    let hasUrgentWork: Bool
    let onNovaPress: () -> Void
    let onNovaLongPress: () -> Void
    let isNovaProcessing: Bool
    let showClockPill: Bool
    
    // Default initializer maintains backward compatibility
    init(
        workerName: String,
        clockedInStatus: Bool,
        onClockToggle: @escaping () -> Void,
        onProfilePress: @escaping () -> Void,
        nextTaskName: String? = nil,
        hasUrgentWork: Bool = false,
        onNovaPress: @escaping () -> Void,
        onNovaLongPress: @escaping () -> Void,
        isNovaProcessing: Bool = false,
        showClockPill: Bool = false
    ) {
        self.workerName = workerName
        self.clockedInStatus = clockedInStatus
        self.onClockToggle = onClockToggle
        self.onProfilePress = onProfilePress
        self.nextTaskName = nextTaskName
        self.hasUrgentWork = hasUrgentWork
        self.onNovaPress = onNovaPress
        self.onNovaLongPress = onNovaLongPress
        self.isNovaProcessing = isNovaProcessing
        self.showClockPill = showClockPill
    }
    
    var body: some View {
        VStack(spacing: 6) {
            // Row 1: Brand + Worker + Profile (18pt)
            GeometryReader { geometry in
                let sideWidth = geometry.size.width * 0.35
                let centerWidth = geometry.size.width * 0.3
                
                HStack(spacing: 0) {
                    // Left: Brand + Optional Clock Pill (35%)
                    HStack(spacing: 12) {
                        Text("FrancoSphere")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 80, alignment: .leading)
                        
                        if showClockPill {
                            clockPillButton
                        }
                        
                        Spacer()
                    }
                    .frame(width: sideWidth)
                    
                    // Center: Spacer (30%)
                    Spacer()
                        .frame(width: centerWidth)
                    
                    // Right: Worker + Profile (35%)
                    HStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Text(workerName)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            
                            ProfileBadge(
                                workerName: workerName,
                                imageUrl: "",
                                isCompact: true,
                                onTap: onProfilePress,
                                accentColor: .teal
                            )
                        }
                    }
                    .frame(width: sideWidth)
                }
            }
            .frame(height: 18)
            
            // Row 2: Nova Avatar (28pt)
            GeometryReader { geometry in
                HStack {
                    Spacer()
                    
                    SimpleNovaAvatar(
                        size: 44,
                        hasUrgentInsight: hasUrgentWork,
                        isBusy: isNovaProcessing,
                        onTap: handleNovaPress,
                        onLongPress: handleNovaLongPress
                    )
                    
                    Spacer()
                }
            }
            .frame(height: 28)
            
            // Row 3: Next Task Banner (16pt)
            if let taskName = nextTaskName {
                nextTaskBanner(taskName)
            } else {
                Spacer()
                    .frame(height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
        .frame(maxHeight: 80)
    }
    
    // MARK: - ✅ SIMPLIFIED: AI Integration Methods
    
    private func handleNovaPress() {
        HapticManager.impact(.medium)
        print("🤖 Nova tapped in header")
        
        // Call the provided handler (maintains existing integration)
        onNovaPress()
        
        // ✅ FIXED: Direct call to AIAssistantManager.shared
        AIAssistantManager.shared.addScenario(.routineIncomplete, buildingName: "Current Location")
    }
    
    private func handleNovaLongPress() {
        HapticManager.impact(.heavy)
        print("🎤 Nova long press")
        
        // Call the provided handler
        onNovaLongPress()
        
        // ✅ FIXED: Direct call to AIAssistantManager.shared
        AIAssistantManager.shared.addScenario(.pendingTasks, taskCount: 1)
    }
    
    // MARK: - UI Components
    
    private var clockPillButton: some View {
        Button(action: onClockToggle) {
            HStack(spacing: 6) {
                Image(systemName: clockedInStatus ? "location.fill" : "location")
                    .font(.system(size: 10))
                
                Text(clockedInStatus ? "Clock Out" : "Clock In")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(clockedInStatus ? .white : .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(clockedInStatus ? Color.green : Color.white.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(clockedInStatus ? Color.green : Color.blue, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func nextTaskBanner(_ taskName: String) -> some View {
        HStack {
            Image(systemName: hasUrgentWork ? "exclamationmark.triangle.fill" : "clock")
                .font(.system(size: 12))
                .foregroundColor(hasUrgentWork ? .orange : .blue)
            
            Text("Next: \(taskName)")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
        }
        .frame(height: 16)
    }
}

// MARK: - ✅ SIMPLIFIED: Nova Avatar Component

struct SimpleNovaAvatar: View {
    let size: CGFloat
    let hasUrgentInsight: Bool
    let isBusy: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var breathe: Bool = false
    @State private var rotationAngle: Double = 0
    
    private var glowColor: Color {
        if hasUrgentInsight { return .orange }
        if isBusy { return .purple }
        return .blue
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glow effect
                if isBusy || hasUrgentInsight {
                    Circle()
                        .stroke(glowColor.opacity(0.6), lineWidth: 3)
                        .frame(width: size + 8, height: size + 8)
                        .scaleEffect(breathe ? 1.1 : 1.0)
                        .opacity(breathe ? 0.3 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: breathe)
                }
                
                // Main avatar
                avatarView
                    .frame(width: size, height: size)
                    .scaleEffect(breathe ? 1.03 : 0.97)
                    .shadow(color: glowColor.opacity(0.4), radius: 12, x: 0, y: 4)
                
                // Status badge
                if hasUrgentInsight || isBusy {
                    statusBadge
                        .offset(x: size * 0.35, y: -size * 0.35)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            startAnimations()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    private var avatarView: some View {
        ZStack {
            // Background gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            glowColor.opacity(0.8),
                            glowColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Avatar image with fallback
            Group {
                if let aiImage = UIImage(named: "AIAssistant") {
                    Image(uiImage: aiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size * 0.85, height: size * 0.85)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    // Fallback icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: size * 0.7, height: size * 0.7)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: size * 0.4, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .rotationEffect(.degrees(rotationAngle))
        }
    }
    
    private var statusBadge: some View {
        ZStack {
            Circle()
                .fill(hasUrgentInsight ? Color.orange : Color.purple)
                .frame(width: 14, height: 14)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                )
            
            Image(systemName: hasUrgentInsight ? "exclamationmark" : "brain")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(breathe ? 1.1 : 0.9)
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breathe = true
        }
        
        if isBusy {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Preview

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal state (no clock pill)
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: false,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "HVAC Filter Replacement",
                hasUrgentWork: false,
                onNovaPress: { print("Nova tapped") },
                onNovaLongPress: { print("Nova long pressed") },
                isNovaProcessing: false
            )
            
            // Urgent state
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Emergency Repair",
                hasUrgentWork: true,
                onNovaPress: { print("Urgent Nova tapped") },
                onNovaLongPress: { print("Urgent Nova long pressed") },
                isNovaProcessing: false
            )
            
            // Processing state
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: nil,
                hasUrgentWork: false,
                onNovaPress: { print("Processing Nova tapped") },
                onNovaLongPress: { print("Processing Nova long pressed") },
                isNovaProcessing: true
            )
            
            Spacer()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
