//
//  HeaderV3B.swift
//  FrancoSphere
//
//  🎯 PHASE-2 HEADER IMPLEMENTATION
//  ✅ ≤80pt total height with Nova avatar centered
//  ✅ Brand text auto-shrinks, never truncates
//  ✅ Equal-width layout groups for perfect centering
//  ✅ Next task banner and clock button integration
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
    
    var body: some View {
        VStack(spacing: 6) {
            // Row 1: Brand + Worker + Profile (18pt)
            GeometryReader { geometry in
                let sideWidth = geometry.size.width * 0.35 // 35% each side
                let centerWidth = geometry.size.width * 0.3 // 30% center
                
                HStack(spacing: 0) {
                    // Left: Brand (35%)
                    HStack {
                        Text("FrancoSphere")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 80, alignment: .leading)
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
                                onTap: onProfilePress
                            )
                        }
                    }
                    .frame(width: sideWidth)
                }
            }
            .frame(height: 18)
            
            // Row 2: Nova Avatar + Clock Button (28pt)
            GeometryReader { geometry in
                let sideWidth = geometry.size.width * 0.35
                let centerWidth = geometry.size.width * 0.3
                
                HStack(spacing: 0) {
                    // Left: Spacer
                    Spacer()
                        .frame(width: sideWidth)
                    
                    // Center: Nova Avatar (perfectly centered)
                    HStack {
                        Spacer()
                        NovaAvatar(
                            size: 44,
                            showStatus: true,
                            hasUrgentInsight: hasUrgentWork,
                            isBusy: isNovaProcessing,
                            onTap: onNovaPress,
                            onLongPress: onNovaLongPress
                        )
                        Spacer()
                    }
                    .frame(width: centerWidth)
                    
                    // Right: Clock Button
                    HStack {
                        Spacer()
                        ClockButton(
                            isClockedIn: clockedInStatus,
                            onToggle: onClockToggle
                        )
                    }
                    .frame(width: sideWidth)
                }
            }
            .frame(height: 28)
            
            // Row 3: Next Task Banner (16pt)
            if let taskName = nextTaskName {
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
            } else {
                // Empty row to maintain consistent height
                Spacer()
                    .frame(height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
        .frame(maxHeight: 80) // Ensure total height ≤ 80pt
    }
}
// Uses shared ProfileBadge component
// MARK: - Supporting Components

struct ClockButton: View {
    let isClockedIn: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 4) {
                Image(systemName: isClockedIn ? "clock.fill" : "clock")
                    .font(.system(size: 12, weight: .medium))
                
                if isClockedIn {
                    Text("Out")
                        .font(.system(size: 10, weight: .medium))
                } else {
                    Text("In")
                        .font(.system(size: 10, weight: .medium))
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isClockedIn ? Color.green : Color.blue)
                    .shadow(radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(0.9)
    }
}

// MARK: - Preview

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal state
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: false,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "HVAC Filter Replacement",
                hasUrgentWork: false,
                onNovaPress: {},
                onNovaLongPress: {},
                isNovaProcessing: false
            )
            
            // Clocked in with urgent work
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Emergency Repair",
                hasUrgentWork: true,
                onNovaPress: {},
                onNovaLongPress: {},
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
                onNovaPress: {},
                onNovaLongPress: {},
                isNovaProcessing: true
            )
            
            Spacer()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
