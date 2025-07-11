//
//  ClockInGlassModal.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Aligned with new architecture.
//  ✅ PRESERVED: All original glassmorphism styling and UI components.
//  ✅ FIXED: Uses CoreTypes for type safety and simplifies state management.
//

import SwiftUI
import CoreLocation

struct ClockInGlassModal: View {
    // MARK: - Properties (Passed from Parent)
    let building: NamedCoordinate
    let isAtLocation: Bool
    let isAdmin: Bool
    let isClockedInAtThisBuilding: Bool
    
    // Actions
    let onConfirm: () -> Void
    let onDismiss: () -> Void
    
    // MARK: - Private State
    @State private var isProcessing = false
    @State private var processingStep = 0
    
    private var isClockingIn: Bool {
        !isClockedInAtThisBuilding
    }
    
    var body: some View {
        ZStack {
            // Background blur overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isProcessing { onDismiss() }
                }

            // Modal content
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 24) {
                    modalHeader
                    buildingInfoSection
                    locationStatusSection
                    actionButtonsSection
                    
                    if isAdmin && !isAtLocation {
                        adminOverrideNotice
                    }
                }
                .padding(24)
                .background(GlassBackground())
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProcessing)
    }
    
    // MARK: - Sub-components (Preserving Original Style)
    
    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isClockingIn ? "Clock In" : "Clock Out")
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(isClockingIn ? "Start your shift at this location" : "End your shift")
                    .font(.subheadline).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
            Button(action: { if !isProcessing { onDismiss() } }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
        }
    }
    
    private var buildingInfoSection: some View {
        HStack(spacing: 16) {
            buildingImageView
            VStack(alignment: .leading, spacing: 8) {
                Text(building.name)
                    .font(.headline).fontWeight(.semibold).foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                    Text("Lat: \(building.latitude, specifier: "%.4f"), Lng: \(building.longitude, specifier: "%.4f")")
                        .font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var buildingImageView: some View {
        // ✅ FIXED: Safely unwraps the optional image asset name
        if let assetName = building.imageAssetName, !assetName.isEmpty, let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable().scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 80, height: 80)
                .overlay(Image(systemName: "building.2.fill").font(.system(size: 32)).foregroundColor(.white.opacity(0.8)))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
        }
    }
    
    private var locationStatusSection: some View {
        let statusColor = isAtLocation ? Color.green : (isAdmin ? .orange : .red)
        let iconName = isAtLocation ? "location.fill" : (isAdmin ? "key.fill" : "location.slash.fill")
        let title = isAtLocation ? "At Building Location" : (isAdmin ? "Admin Remote Access" : "Not At Location")
        let description = isAtLocation ? "Your GPS location is verified." : (isAdmin ? "Admin override available for remote clock-in." : "You must be at the building to clock in.")

        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(statusColor.opacity(0.2)).frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium)).foregroundColor(statusColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                Text(description).font(.caption).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(16)
        .background(statusColor.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(statusColor.opacity(0.3), lineWidth: 1))
        .cornerRadius(12)
    }

    private var actionButtonsSection: some View {
        let canPerformAction = isAtLocation || isAdmin
        
        return Button(action: handleMainAction) {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8)
                } else {
                    Image(systemName: isClockingIn ? "clock.badge.plus" : "clock.badge.minus")
                }
                Text(isProcessing ? "Processing..." : (isClockingIn ? "Confirm Clock-In" : "Confirm Clock-Out"))
            }
            .font(.headline.weight(.semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canPerformAction ? (isClockingIn ? Color.green : Color.red) : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!canPerformAction || isProcessing)
    }
    
    private var adminOverrideNotice: some View {
        Text("Admin override will be logged.")
            .font(.caption2).foregroundColor(.orange.opacity(0.8))
    }

    // MARK: - Action Handling
    
    private func handleMainAction() {
        isProcessing = true
        // Simulate network/database operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            onConfirm()
            HapticManager.success()
            onDismiss()
        }
    }
}

// MARK: - Reusable Glass Background
private struct GlassBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
    }
}
