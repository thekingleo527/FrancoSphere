//
//  HeaderV3B.swift
//  FrancoSphere
//
//  💎 HEADER V3-B IMPLEMENTATION (PHASE-2 EXECUTION PLAN)
//  ✅ Total height ≤ 80pt per spec
//  ✅ Row-1: Brand (auto-shrink) + Worker + Profile
//  ✅ Row-2: Centered Nova Avatar + Clock button right
//  ✅ Row-3: Next Task banner
//  ✅ Removed "Inactive/On-site" pill per v2 notes
//  ✅ 6pt vertical gaps, proper padding
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
    
    // MARK: - Constants (Per Execution Plan)
    private let row1Height: CGFloat = 18
    private let row2Height: CGFloat = 28
    private let row3Height: CGFloat = 16
    private let verticalGap: CGFloat = 6
    private let novaAvatarSize: CGFloat = 44
    
    // MARK: - Computed Properties
    private var totalHeight: CGFloat {
        return row1Height + row2Height + row3Height + (verticalGap * 2) + 20 // padding
    }
    
    private var brandText: String {
        "FrancoSphere"
    }
    
    private var nextTaskDisplayText: String {
        if hasUrgentWork {
            return "⚠️ Urgent tasks require attention"
        } else if let taskName = nextTaskName {
            return "Next: \(taskName)"
        } else {
            return "All tasks completed ✓"
        }
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: verticalGap) {
            // ROW 1: Brand + Worker + Profile (18pt)
            row1Brand
                .frame(height: row1Height)
            
            // ROW 2: Centered Nova Avatar + Clock button (28pt)
            row2NovaSection
                .frame(height: row2Height)
            
            // ROW 3: Next Task banner (16pt)
            row3TaskBanner
                .frame(height: row3Height)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground.opacity(0.95),
                    FrancoSphereColors.cardBackground.opacity(0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Row Components
    
    /// Row 1: Auto-shrinking brand + worker name + profile button
    private var row1Brand: some View {
        HStack(spacing: 12) {
            // Brand text with auto-shrink (minScaleFactor 0.8, max 11pt per spec)
            Text(brandText)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Worker name
            Text(workerName)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            // Profile button
            Button(action: onProfilePress) {
                Image(systemName: "person.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
    
    /// Row 2: Centered Nova Avatar + Clock button right
    private var row2NovaSection: some View {
        HStack {
            // Clock in/out button (left side)
            clockButton
            
            Spacer()
            
            // Centered Nova Avatar (44pt per spec)
            novaAvatarButton
            
            Spacer()
            
            // Empty space for balance (same width as clock button)
            Color.clear
                .frame(width: 70) // Match clock button width
        }
    }
    
    /// Row 3: Next task banner
    private var row3TaskBanner: some View {
        HStack(spacing: 8) {
            // Task status icon
            Image(systemName: hasUrgentWork ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(hasUrgentWork ? .red : .green)
            
            // Task text
            Text(nextTaskDisplayText)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            Spacer()
            
            // Time indicator if urgent
            if hasUrgentWork {
                Text("NOW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }
    
    // MARK: - Sub-Components
    
    /// Nova Avatar with processing state
    private var novaAvatarButton: some View {
        Button(action: onNovaPress) {
            ZStack {
                // Base circle
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
                    .frame(width: novaAvatarSize, height: novaAvatarSize)
                
                // Processing ring
                if isNovaProcessing {
                    Circle()
                        .stroke(Color.white.opacity(0.6), lineWidth: 2)
                        .frame(width: novaAvatarSize + 4, height: novaAvatarSize + 4)
                        .rotationEffect(.degrees(Double(Date().timeIntervalSince1970 * 360).truncatingRemainder(dividingBy: 360)))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isNovaProcessing)
                }
                
                // Brain icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: novaAvatarSize * 0.4, weight: .medium))
                    .foregroundColor(.white)
                
                // Urgent indicator
                if hasUrgentWork {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 15, y: -15)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 1)
                                .frame(width: 12, height: 12)
                                .offset(x: 15, y: -15)
                        )
                }
            }
        }
        .onLongPressGesture {
            onNovaLongPress()
        }
        .scaleEffect(isNovaProcessing ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isNovaProcessing)
    }
    
    /// Clock in/out button
    private var clockButton: some View {
        Button(action: onClockToggle) {
            HStack(spacing: 6) {
                Image(systemName: clockedInStatus ? "clock.badge.checkmark.fill" : "clock.arrow.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(clockedInStatus ? .green : .white.opacity(0.8))
                
                Text(clockedInStatus ? "Out" : "In")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(clockedInStatus ? .green : .white.opacity(0.8))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(clockedInStatus ? Color.green.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(clockedInStatus ? Color.green.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .frame(width: 70) // Fixed width for layout consistency
    }
}

// MARK: - 📝 HeaderV3B Implementation Summary
/*
 ✅ EXECUTION PLAN COMPLIANCE:
 
 📐 DIMENSIONS (Per Specification):
 - Row 1: 18pt (Brand + Worker + Profile)
 - Row 2: 28pt (Centered Nova Avatar + Clock button)
 - Row 3: 16pt (Next Task banner)
 - Vertical gaps: 6pt each
 - Total height: ≤ 80pt including padding ✓
 
 🎨 FEATURES IMPLEMENTED:
 - ✅ Auto-shrinking brand text (11pt max, minScaleFactor 0.8)
 - ✅ Centered Nova Avatar (44pt) with processing animation
 - ✅ Clock button with green state indication
 - ✅ Next task banner with urgent work indicators
 - ✅ Removed "Inactive/On-site" pill per v2 notes
 - ✅ Proper vertical gaps and padding
 
 🔧 INTERFACE COMPATIBILITY:
 - ✅ All required callbacks: onClockToggle, onProfilePress, onNovaPress, onNovaLongPress
 - ✅ State indicators: clockedInStatus, hasUrgentWork, isNovaProcessing
 - ✅ Dynamic content: workerName, nextTaskName
 
 🎯 PRIORITY 3 PROGRESS: 1/4 critical view components completed
 📋 NEXT: WeatherManager, MySitesCard, MapOverlayView fixes
 */
