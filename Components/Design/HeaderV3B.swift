//
//  HeaderV3B.swift
//  FrancoSphere
//
//  🚀 HEADER V3-B: COMPACT DESIGN ≤80PT (PHASE-2)
//  ✅ Row-1: Brand + Worker + Profile (18pt)
//  ✅ Row-2: NovaAvatar centered + Clock button (28pt)
//  ✅ Row-3: Next-Task banner (16pt)
//  ✅ 6pt gaps → Total ≈78pt including padding
//  ✅ Removed "Inactive/On-site" pill - state shown by green clock button + map markers
//

import SwiftUI

struct HeaderV3B: View {
    
    // MARK: - Properties
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
            row1BrandAndWorker
            
            // Row 2: Nova Avatar (centered) + Clock Button (28pt)
            row2NovaAndClock
            
            // Row 3: Next Task Banner (16pt)
            if let nextTaskName = nextTaskName {
                row3NextTaskBanner(nextTaskName)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Row 1: Brand + Worker + Profile (18pt)
    
    private var row1BrandAndWorker: some View {
        HStack(spacing: 12) {
            // Brand text with auto-shrinking (never truncate)
            Text("FrancoSphere")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            Spacer()
            
            // Worker name
            Text(workerName)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            // Profile button
            Button(action: onProfilePress) {
                Image(systemName: "person.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(height: 18)
    }
    
    // MARK: - Row 2: Nova Avatar + Clock Button (28pt)
    
    private var row2NovaAndClock: some View {
        HStack {
            // Left spacer for centering
            Spacer()
            
            // Nova Avatar (centered, 44pt)
            Button(action: onNovaPress) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                    
                    // Nova AI icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    // Processing indicator
                    if isNovaProcessing {
                        Circle()
                            .stroke(Color.blue, lineWidth: 2)
                            .frame(width: 48, height: 48)
                            .opacity(0.6)
                            .scaleEffect(1.1)
                        
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white.opacity(0.8))
                    }
                }
            }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onEnded { _ in
                        onNovaLongPress()
                    }
            )
            
            // Right spacer for centering
            Spacer()
            
            // Clock button (positioned right)
            clockButton
        }
        .frame(height: 28)
    }
    
    // MARK: - Clock Button
    
    private var clockButton: some View {
        Button(action: onClockToggle) {
            HStack(spacing: 6) {
                Image(systemName: clockedInStatus ? "checkmark.circle.fill" : "clock")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(clockedInStatus ? .green : .white.opacity(0.8))
                
                Text(clockedInStatus ? "Clocked In" : "Clock In")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(clockedInStatus ? .green : .white.opacity(0.8))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(clockedInStatus ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(clockedInStatus ? Color.green.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Row 3: Next Task Banner (16pt)
    
    private func row3NextTaskBanner(_ taskName: String) -> some View {
        HStack(spacing: 8) {
            // Urgency indicator
            Circle()
                .fill(hasUrgentWork ? Color.red : Color.blue)
                .frame(width: 6, height: 6)
            
            // Task text
            Text("Next: \(taskName)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            // Task count or urgency indicator
            if hasUrgentWork {
                Text("URGENT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red.opacity(0.2))
                    )
            }
        }
        .frame(height: 16)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Preview

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            // Clocked out state
            HeaderV3B(
                workerName: "Edwin Martinez",
                clockedInStatus: false,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Lobby Cleaning",
                hasUrgentWork: false,
                onNovaPress: {},
                onNovaLongPress: {},
                isNovaProcessing: false
            )
            
            Spacer()
            
            // Clocked in state with urgent work
            HeaderV3B(
                workerName: "Edwin Martinez",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Emergency Repair - Water Leak",
                hasUrgentWork: true,
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
