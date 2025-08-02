//
//  CoverageInfoCard.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Renamed StatusPill to CoverageStatusPill to avoid conflicts
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Glass morphism effects
//  ✅ INTEGRATED: FrancoSphereDesign system
//  ✅ IMPROVED: Visual hierarchy and animations
//  ✅ MAINTAINED: All three access variants (Coverage, Emergency, Training)
//

import SwiftUI
import Foundation

// MARK: - Coverage Info Card (Default)

struct CoverageInfoCard: View {
    let building: NamedCoordinate
    let onViewFullInfo: () -> Void
    
    // Services
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @State private var primaryWorker: String?
    @State private var isLoadingWorkerInfo = false
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            coverageHeader
            
            coverageDescription
            
            primaryWorkerInfo
            
            emergencyAccessNote
            
            actionButton
        }
        .francoCardPadding()
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                        .stroke(FrancoSphereDesign.DashboardColors.warning.opacity(0.2), lineWidth: 1)
                )
        )
        .francoShadow(FrancoSphereDesign.Shadow.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(FrancoSphereDesign.Animations.quick, value: isPressed)
        .task {
            await loadPrimaryWorkerInfo()
        }
    }
    
    // MARK: - Coverage Header
    
    private var coverageHeader: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Coverage Mode")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                
                Text("Emergency/Support Access")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            // Current worker indicator
            if let currentWorker = contextEngine.currentWorker {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("You")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    Text(currentWorker.name)
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
            }
        }
    }
    
    // MARK: - Coverage Description
    
    private var coverageDescription: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            Text("This building is not in your regular assignments.")
                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text("You have access to complete building information for coverage support, emergency situations, or cross-training purposes.")
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Primary Worker Info
    
    private var primaryWorkerInfo: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            Text("Primary Coverage")
                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if isLoadingWorkerInfo {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text("Loading worker information...")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                .padding(FrancoSphereDesign.Spacing.sm)
            } else if let worker = primaryWorker {
                primaryWorkerRow(worker)
            } else {
                noPrimaryWorkerView
            }
        }
        .padding(FrancoSphereDesign.Spacing.sm)
        .francoGlassBackground(cornerRadius: FrancoSphereDesign.CornerRadius.md)
    }
    
    // MARK: - Primary Worker Row
    
    private func primaryWorkerRow(_ workerName: String) -> some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            // Worker avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: FrancoSphereDesign.DashboardColors.workerHeroGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text(String(workerName.prefix(1)))
                    .francoTypography(FrancoSphereDesign.Typography.callout)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(workerName)
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("Primary Worker")
                    .francoTypography(FrancoSphereDesign.Typography.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            // Status indicator - renamed to avoid conflict
            CoverageStatusPill(
                text: "Available",
                icon: "circle.fill",
                color: FrancoSphereDesign.DashboardColors.success
            )
        }
    }
    
    // MARK: - No Primary Worker View
    
    private var noPrimaryWorkerView: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Circle()
                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.title3)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No primary worker assigned")
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Text("Contact management for assistance")
                    .francoTypography(FrancoSphereDesign.Typography.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Emergency Access Note
    
    private var emergencyAccessNote: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            
            Text("Emergency situations grant full access to all building systems and procedures.")
                .francoTypography(FrancoSphereDesign.Typography.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                .italic()
        }
        .padding(FrancoSphereDesign.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
                .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.1))
        )
    }
    
    // MARK: - Action Button
    
    private var actionButton: some View {
        Button(action: {
            withAnimation(FrancoSphereDesign.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(FrancoSphereDesign.Animations.quick) {
                    isPressed = false
                }
                onViewFullInfo()
            }
        }) {
            HStack(spacing: FrancoSphereDesign.Spacing.xs) {
                Image(systemName: "brain.head.profile")
                    .font(.subheadline)
                
                Text("View Complete Building Intelligence")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                    .fill(FrancoSphereDesign.DashboardColors.warning)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Data Loading
    
    private func loadPrimaryWorkerInfo() async {
        isLoadingWorkerInfo = true
        
        let primaryWorkerName = await getPrimaryWorkerForBuilding(building.id)
        
        await MainActor.run {
            self.primaryWorker = primaryWorkerName
            self.isLoadingWorkerInfo = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPrimaryWorkerForBuilding(_ buildingId: String) async -> String? {
        // Worker assignments mapped to buildings
        switch buildingId {
        case "14": return "Kevin Dutan"
        case "1": return "Greg Miller"
        case "10": return "Mercedes Inamagua"
        case "4": return "Luis Lopez"
        case "6": return "Luis Lopez"
        case "16": return "Edwin Lema"
        case "7": return "Angel Cornejo"
        case "8": return "Angel Cornejo"
        case "9": return "Angel Cornejo"
        case "5": return "Mercedes Inamagua"
        case "13": return "Shawn Magloire"
        default: return nil
        }
    }
}

// MARK: - Emergency Access Card

struct EmergencyAccessCard: View {
    let building: NamedCoordinate
    let onViewFullInfo: () -> Void
    
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            // Header with pulse animation
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                }
                .overlay(
                    Circle()
                        .stroke(FrancoSphereDesign.DashboardColors.critical.opacity(0.3), lineWidth: 2)
                        .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                        .opacity(pulseAnimation ? 0 : 1)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Emergency Access")
                        .francoTypography(FrancoSphereDesign.Typography.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    
                    Text("Complete building access authorized")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                // Emergency timestamp
                VStack(alignment: .trailing, spacing: 2) {
                    Text("EMERGENCY")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    
                    Text(Date().formatted(.dateTime.hour().minute()))
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            
            Text("Emergency situation detected. You have full access to all building information and emergency procedures.")
                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            // Emergency contacts quick access
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                EmergencyButton(
                    title: "911",
                    action: {
                        if let phoneURL = URL(string: "tel://911") {
                            UIApplication.shared.open(phoneURL)
                        }
                    },
                    isPrimary: true
                )
                
                EmergencyButton(
                    title: "Security",
                    action: {
                        // Contact building security
                    },
                    isPrimary: false
                )
                
                Spacer()
            }
            
            // Main action button
            Button(action: {
                withAnimation(FrancoSphereDesign.Animations.quick) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(FrancoSphereDesign.Animations.quick) {
                        isPressed = false
                    }
                    onViewFullInfo()
                }
            }) {
                HStack(spacing: FrancoSphereDesign.Spacing.xs) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.subheadline)
                    
                    Text("Access Emergency Information")
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                        .fill(FrancoSphereDesign.DashboardColors.critical)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .francoCardPadding()
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                        .stroke(FrancoSphereDesign.DashboardColors.critical.opacity(0.2), lineWidth: 1)
                )
        )
        .francoShadow(FrancoSphereDesign.Shadow.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(FrancoSphereDesign.Animations.quick, value: isPressed)
        .onAppear {
            pulseAnimation = true
        }
    }
}

// MARK: - Training Access Card

struct TrainingAccessCard: View {
    let building: NamedCoordinate
    let onViewFullInfo: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(FrancoSphereDesign.DashboardColors.info.opacity(0.15))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Training Mode")
                        .francoTypography(FrancoSphereDesign.Typography.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    
                    Text("Cross-training access")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
            }
            
            Text("You're accessing this building for training purposes. View complete procedures and learn the systems.")
                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            // Training progress indicator
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
                HStack {
                    Text("Training Progress")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text("0% Complete")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                
                FrancoMetricsProgress(value: 0, role: .worker)
                    .frame(height: 4)
            }
            .padding(FrancoSphereDesign.Spacing.sm)
            .francoGlassBackground(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
            
            Button(action: {
                withAnimation(FrancoSphereDesign.Animations.quick) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(FrancoSphereDesign.Animations.quick) {
                        isPressed = false
                    }
                    onViewFullInfo()
                }
            }) {
                HStack(spacing: FrancoSphereDesign.Spacing.xs) {
                    Image(systemName: "graduationcap.fill")
                        .font(.subheadline)
                    
                    Text("Access Training Materials")
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                        .fill(FrancoSphereDesign.DashboardColors.info)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .francoCardPadding()
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(FrancoSphereDesign.DashboardColors.info.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                        .stroke(FrancoSphereDesign.DashboardColors.info.opacity(0.2), lineWidth: 1)
                )
        )
        .francoShadow(FrancoSphereDesign.Shadow.md)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(FrancoSphereDesign.Animations.quick, value: isPressed)
    }
}

// MARK: - Supporting Components (Renamed to avoid conflicts)

struct CoverageStatusPill: View {
    let text: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(color)
            
            Text(text)
                .francoTypography(FrancoSphereDesign.Typography.caption2)
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

struct EmergencyButton: View {
    let title: String
    let action: () -> Void
    let isPrimary: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .fontWeight(isPrimary ? .bold : .medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
                        .fill(isPrimary ?
                            FrancoSphereDesign.DashboardColors.critical :
                            FrancoSphereDesign.DashboardColors.warning
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct CoverageInfoCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        ScrollView {
            VStack(spacing: FrancoSphereDesign.Spacing.lg) {
                CoverageInfoCard(building: sampleBuilding) {
                    print("View full info tapped")
                }
                
                EmergencyAccessCard(building: sampleBuilding) {
                    print("Emergency access tapped")
                }
                
                TrainingAccessCard(building: sampleBuilding) {
                    print("Training access tapped")
                }
            }
            .padding()
        }
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
