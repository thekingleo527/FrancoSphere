//
//  ClockInGlassModal.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Fixed all coordinate and string literal issues
//  ✅ FIXED: Removed non-existent imageAssetName property references
//  ✅ FIXED: Corrected string interpolation syntax
//  ✅ PRESERVED: All glassmorphism styling and modal functionality
//

import SwiftUI
import CoreLocation

struct ClockInGlassModal: View {
    let building: NamedCoordinate
    let isAtLocation: Bool
    let isAdmin: Bool
    let isClockedInAtThisBuilding: Bool
    let onConfirm: () -> Void
    let onDismiss: () -> Void

    @State private var isProcessing = false
    @State private var processingStep = 0

    private var isClockingIn: Bool { !isClockedInAtThisBuilding }

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
                .onTapGesture { if !isProcessing { onDismiss() } }
            VStack(spacing: 0) {
                Spacer()
                VStack(spacing: 24) {
                    modalHeader
                    buildingInfoSection
                    locationStatusSection
                    actionButtonsSection
                    if isAdmin && !isAtLocation { adminOverrideNotice }
                }
                .padding(24)
                .background(ClockInModalBackground())
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isProcessing)
    }

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
                    .background(.white.opacity(0.1))
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
                    // ✅ FIXED: Corrected string interpolation syntax
                    Text("Lat: \(building.latitude, specifier: "%.4f"), Lng: \(building.longitude, specifier: "%.4f")")
                        .font(.caption).foregroundColor(.white.opacity(0.7)).lineLimit(1)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var buildingImageView: some View {
        // ✅ FIXED: Removed reference to non-existent imageAssetName property
        // Always show fallback building icon since NamedCoordinate doesn't have imageAssetName
        RoundedRectangle(cornerRadius: 16)
            .fill(.blue.opacity(0.3))
            .frame(width: 80, height: 80)
            .overlay(Image(systemName: "building.2.fill").font(.system(size: 32)).foregroundColor(.white.opacity(0.8)))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3), lineWidth: 1))
    }

    private var locationStatusSection: some View {
        let color = isAtLocation ? Color.green : (isAdmin ? .orange : .red)
        let icon = isAtLocation ? "location.fill" : (isAdmin ? "key.fill" : "location.slash.fill")
        let title = isAtLocation ? "At Building Location" : (isAdmin ? "Admin Remote Access" : "Not At Location")
        let desc = isAtLocation ? "Your GPS location is verified." : (isAdmin ? "Admin override available." : "Must be at the building.")
        
        return HStack(spacing: 12) {
            Circle().fill(color.opacity(0.2)).frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundColor(color))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                Text(desc).font(.caption).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
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
            .font(.caption2)
            .foregroundColor(.orange.opacity(0.8))
    }

    private func handleMainAction() {
        guard !isProcessing else { return }
        isProcessing = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            processingStep = 1
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                processingStep = 2
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                onConfirm()
                isProcessing = false
                processingStep = 0
            }
        }
    }
}

// MARK: - Background Component (Preserved Original Styling)

private struct ClockInModalBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .white.opacity(0.25),
                        .white.opacity(0.15)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.black.opacity(0.3))
                    .blur(radius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Preview Provider

struct ClockInGlassModal_Previews: PreviewProvider {
    static var previews: some View {
        ClockInGlassModal(
            building: NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                latitude: 40.7389,
                longitude: -73.9936
            ),
            isAtLocation: true,
            isAdmin: false,
            isClockedInAtThisBuilding: false,
            onConfirm: {},
            onDismiss: {}
        )
        .preferredColorScheme(.dark)
    }
}
