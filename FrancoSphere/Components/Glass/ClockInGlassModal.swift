//
//  ClockInGlassModal.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Integrated with FrancoSphereDesign color system
//  ✅ IMPROVED: Glass effects and animations
//  ✅ OPTIMIZED: Better visual hierarchy with dark theme
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
    @State private var modalOffset: CGFloat = 0
    @State private var modalOpacity: Double = 0

    private var isClockingIn: Bool { !isClockedInAtThisBuilding }

    var body: some View {
        ZStack {
            // Dark background overlay
            FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isProcessing {
                        dismissModal()
                    }
                }
            
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
                .background(ClockInModalBackground())
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(
                    color: FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.5),
                    radius: 30,
                    x: 0,
                    y: 10
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
                .offset(y: modalOffset)
                .opacity(modalOpacity)
            }
        }
        .animation(FrancoSphereDesign.Animations.spring, value: isProcessing)
        .animation(FrancoSphereDesign.Animations.spring, value: modalOffset)
        .onAppear {
            presentModal()
        }
    }

    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isClockingIn ? "Clock In" : "Clock Out")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(isClockingIn ? "Start your shift at this location" : "End your shift")
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                if !isProcessing {
                    dismissModal()
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    .frame(width: 32, height: 32)
                    .background(FrancoSphereDesign.DashboardColors.glassOverlay)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
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
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    Text("Lat: \(building.latitude, specifier: "%.4f"), Lng: \(building.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
    }

    @ViewBuilder
    private var buildingImageView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(FrancoSphereDesign.DashboardColors.info.opacity(0.2))
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "building.2.fill")
                    .font(.system(size: 32))
                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(FrancoSphereDesign.DashboardColors.info.opacity(0.3), lineWidth: 1)
            )
    }

    private var locationStatusSection: some View {
        let color = isAtLocation ? FrancoSphereDesign.DashboardColors.success :
                   (isAdmin ? FrancoSphereDesign.DashboardColors.warning : FrancoSphereDesign.DashboardColors.critical)
        let icon = isAtLocation ? "location.fill" : (isAdmin ? "key.fill" : "location.slash.fill")
        let title = isAtLocation ? "At Building Location" : (isAdmin ? "Admin Remote Access" : "Not At Location")
        let desc = isAtLocation ? "Your GPS location is verified." :
                  (isAdmin ? "Admin override available." : "Must be at the building.")
        
        return HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                )
                .overlay(
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(desc)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var actionButtonsSection: some View {
        let canPerformAction = isAtLocation || isAdmin
        
        return Button(action: handleMainAction) {
            HStack(spacing: 8) {
                if isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: isClockingIn ? "clock.badge.checkmark" : "clock.badge.xmark")
                        .font(.body)
                }
                
                Text(isProcessing ? "Processing..." : (isClockingIn ? "Confirm Clock-In" : "Confirm Clock-Out"))
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                canPerformAction ?
                (isClockingIn ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.critical) :
                FrancoSphereDesign.DashboardColors.inactive
            )
            .cornerRadius(12)
            .opacity(canPerformAction ? 1.0 : 0.6)
        }
        .disabled(!canPerformAction || isProcessing)
    }

    private var adminOverrideNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            
            Text("Admin override will be logged.")
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
        }
    }

    private func handleMainAction() {
        guard !isProcessing else { return }
        isProcessing = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
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

    private func presentModal() {
        modalOffset = 50
        modalOpacity = 0
        
        withAnimation(FrancoSphereDesign.Animations.spring) {
            modalOffset = 0
            modalOpacity = 1
        }
    }

    private func dismissModal() {
        withAnimation(FrancoSphereDesign.Animations.spring) {
            modalOffset = 50
            modalOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Background Component

private struct ClockInModalBackground: View {
    var body: some View {
        ZStack {
            // Dark base
            RoundedRectangle(cornerRadius: 20)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.95))
            
            // Glass material
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.5))
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            FrancoSphereDesign.DashboardColors.glassOverlay.opacity(0.3),
                            FrancoSphereDesign.DashboardColors.glassOverlay.opacity(0.1),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Border
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - View Extension for Modal Presentation

extension View {
    func clockInModal(
        isPresented: Binding<Bool>,
        building: NamedCoordinate,
        isAtLocation: Bool,
        isAdmin: Bool,
        isClockedInAtThisBuilding: Bool,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    ClockInGlassModal(
                        building: building,
                        isAtLocation: isAtLocation,
                        isAdmin: isAdmin,
                        isClockedInAtThisBuilding: isClockedInAtThisBuilding,
                        onConfirm: {
                            isPresented.wrappedValue = false
                            onConfirm()
                        },
                        onDismiss: {
                            isPresented.wrappedValue = false
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        )
    }
}

// MARK: - Preview Provider

struct ClockInGlassModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Dark Elegance background
            FrancoSphereDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack {
                Text("Background Content")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
        }
        .overlay(
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
                onConfirm: {
                    print("Clock in confirmed")
                },
                onDismiss: {
                    print("Modal dismissed")
                }
            )
        )
        .preferredColorScheme(.dark)
    }
}
