//
//  ClockInGlassModal.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


//
//  ClockInGlassModal.swift
//  FrancoSphere
//
//  Glass modal for clock-in/clock-out functionality with GPS verification
//

import SwiftUI
import CoreLocation

struct ClockInGlassModal: View {
    let building: FrancoSphere.NamedCoordinate
    let isAtLocation: Bool
    let isAdmin: Bool
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let onClockIn: () -> Void
    let onClockOut: () -> Void
    let onDismiss: () -> Void
    
    @State private var isProcessing = false
    @State private var showConfirmation = false
    @State private var processingStep = 0
    
    private var isClockingIn: Bool {
        !isClockedInCurrentBuilding
    }
    
    private var isClockedInCurrentBuilding: Bool {
        clockedInStatus.isClockedIn && 
        clockedInStatus.buildingId == Int64(building.id)
    }
    
    var body: some View {
        ZStack {
            // Background blur overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isProcessing {
                        onDismiss()
                    }
                }
            
            // Modal content
            VStack(spacing: 0) {
                Spacer()
                
                GlassCard(intensity: .regular) {
                    VStack(spacing: 24) {
                        // Header with dismiss
                        modalHeader
                        
                        // Building info section
                        buildingInfoSection
                        
                        // Location status verification
                        locationStatusSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        // Admin override notice
                        if isAdmin && !isAtLocation {
                            adminOverrideNotice
                        }
                    }
                    .padding(24)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProcessing)
        .onAppear {
            resetModalState()
        }
    }
    
    // MARK: - Sub-components
    
    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isClockingIn ? "Clock In" : "Clock Out")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(isClockingIn ? "Start your shift at this location" : "End your shift")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button(action: {
                if !isProcessing {
                    onDismiss()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(16)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isProcessing)
        }
    }
    
    private var buildingInfoSection: some View {
        HStack(spacing: 16) {
            // Building image or icon
            buildingImageView
            
            VStack(alignment: .leading, spacing: 8) {
                Text(building.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                if let address = building.address {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }
                }
                
                // Building status
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("Operational")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Current time
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(getCurrentTimeString())
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Spacer()
        }
    }
    
    private var buildingImageView: some View {
        Group {
            if !building.imageAssetName.isEmpty,
               let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var locationStatusSection: some View {
        VStack(spacing: 12) {
            // Location status indicator
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(locationStatusColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: locationStatusIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(locationStatusColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(locationStatusTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(locationStatusDescription)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            .padding(16)
            .background(locationStatusColor.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(locationStatusColor.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            
            // GPS accuracy info
            if isAtLocation {
                HStack(spacing: 6) {
                    Image(systemName: "location.north.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("GPS accuracy: High (±5m)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text("Location verified")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            } else if isAdmin {
                HStack(spacing: 6) {
                    Image(systemName: "key.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Admin access enabled")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Spacer()
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Main action button
            Button(action: handleMainAction) {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: isClockingIn ? "clock.badge.plus" : "clock.badge.minus")
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(getActionButtonText())
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(getActionButtonColor())
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
            }
            .disabled(isProcessing || (!canPerformAction && !isAdmin))
            .buttonStyle(PlainButtonStyle())
            
            // Processing status or error message
            if isProcessing {
                processingStatusView
            } else if !canPerformAction && !isAdmin {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text("You must be at the building location to clock in")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var adminOverrideNotice: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("Admin Override")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("Remote Access")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text("You can clock in remotely as an administrator. This action will be logged with admin override status.")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.leading)
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private var processingStatusView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(processingStep >= 1 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(processingStep >= 1 ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.3), value: processingStep)
                
                Text("Verifying location...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(processingStep >= 1 ? 1.0 : 0.5))
                
                Spacer()
                
                if processingStep >= 1 {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 8) {
                Circle()
                    .fill(processingStep >= 2 ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(processingStep >= 2 ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.3), value: processingStep)
                
                Text("Recording timestamp...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(processingStep >= 2 ? 1.0 : 0.5))
                
                Spacer()
                
                if processingStep >= 2 {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            HStack(spacing: 8) {
                Circle()
                    .fill(processingStep >= 3 ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .scaleEffect(processingStep >= 3 ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 0.3), value: processingStep)
                
                Text(isClockingIn ? "Clocked in successfully!" : "Clocked out successfully!")
                    .font(.caption)
                    .foregroundColor(.white.opacity(processingStep >= 3 ? 1.0 : 0.5))
                
                Spacer()
                
                if processingStep >= 3 {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var canPerformAction: Bool {
        isAtLocation || isAdmin
    }
    
    private var locationStatusColor: Color {
        if isAtLocation { return .green }
        if isAdmin { return .orange }
        return .red
    }
    
    private var locationStatusIcon: String {
        if isAtLocation { return "location.fill" }
        if isAdmin { return "key.fill" }
        return "location.slash.fill"
    }
    
    private var locationStatusTitle: String {
        if isAtLocation { return "At Building Location" }
        if isAdmin { return "Admin Remote Access" }
        return "Not At Location"
    }
    
    private var locationStatusDescription: String {
        if isAtLocation {
            return "Your GPS location matches this building within the required range"
        } else if isAdmin {
            return "Admin override available for remote clock-in operations"
        } else {
            return "You must be within 100 meters of the building to clock in"
        }
    }
    
    private func getActionButtonText() -> String {
        if isProcessing {
            return "Processing..."
        } else if isClockingIn {
            return "CLOCK IN"
        } else {
            return "CLOCK OUT"
        }
    }
    
    private func getActionButtonColor() -> Color {
        if !canPerformAction && !isAdmin {
            return Color.gray.opacity(0.5)
        } else if isClockingIn {
            return Color.green.opacity(0.8)
        } else {
            return Color.red.opacity(0.8)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    private func resetModalState() {
        isProcessing = false
        showConfirmation = false
        processingStep = 0
    }
    
    // MARK: - Actions
    
    private func handleMainAction() {
        guard !isProcessing else { return }
        
        if isClockingIn {
            performClockIn()
        } else {
            performClockOut()
        }
    }
    
    private func performClockIn() {
        isProcessing = true
        processingStep = 0
        
        // Simulate processing steps with realistic timing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                processingStep = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    processingStep = 2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        processingStep = 3
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onClockIn()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onDismiss()
                        }
                    }
                }
            }
        }
    }
    
    private func performClockOut() {
        isProcessing = true
        processingStep = 0
        
        // Similar processing for clock out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 0.3)) {
                processingStep = 1
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    processingStep = 2
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        processingStep = 3
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onClockOut()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onDismiss()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct ClockInGlassModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            // Simulate background content
            VStack {
                Text("Background Content")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            
            // Clock in modal - At Location
            ClockInGlassModal(
                building: FrancoSphere.NamedCoordinate(
                    id: "15",
                    name: "Rubin Museum (142-148 W 17th)",
                    latitude: 40.740370,
                    longitude: -73.998120,
                    address: "142-148 W 17th St, New York, NY",
                    imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
                ),
                isAtLocation: true,
                isAdmin: false,
                clockedInStatus: (false, nil),
                onClockIn: {},
                onClockOut: {},
                onDismiss: {}
            )
        }
        .preferredColorScheme(.dark)
    }
}