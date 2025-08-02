//
//  PropertyCard.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Glass morphism effects using FrancoSphereDesign
//  ✅ FIXED: Consistent dark theme styling
//  ✅ ALIGNED: With CoreTypes.BuildingMetrics properties
//

import SwiftUI

struct PropertyCard: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let mode: PropertyCardMode
    let onTap: () -> Void
    
    enum PropertyCardMode {
        case worker
        case admin
        case client
    }
    
    @State private var isPressed = false
    private let imageSize: CGFloat = 60
    
    var body: some View {
        Button(action: {
            withAnimation(FrancoSphereDesign.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(FrancoSphereDesign.Animations.quick) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            HStack(spacing: FrancoSphereDesign.Spacing.md) {
                buildingImage
                buildingContent
                Spacer()
                chevron
            }
            .francoCardPadding()
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                    .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                            .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            )
            .francoShadow(FrancoSphereDesign.Shadow.sm)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buildingImage: some View {
        Group {
            if let image = UIImage(named: buildingImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageSize, height: imageSize)
                    .cornerRadius(FrancoSphereDesign.CornerRadius.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
                            .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            } else {
                // Fallback placeholder with gradient
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
                    .fill(
                        LinearGradient(
                            colors: FrancoSphereDesign.DashboardColors.workerHeroGradient.map { $0.opacity(0.3) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: imageSize * 0.4))
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
                            .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            }
        }
    }
    
    private var buildingContent: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            Text(building.name)
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                .lineLimit(2)
            
            switch mode {
            case .worker:
                workerContent
            case .admin:
                adminContent
            case .client:
                clientContent
            }
        }
    }
    
    private var workerContent: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            if let metrics = metrics {
                HStack {
                    Label("Portfolio", systemImage: "building.2.fill")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text(metrics.pendingTasks > 0 ? "\(metrics.pendingTasks) remaining" : "All complete")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(metrics.pendingTasks > 0 ?
                            FrancoSphereDesign.DashboardColors.info :
                            FrancoSphereDesign.DashboardColors.success
                        )
                }
                
                // Progress bar
                FrancoMetricsProgress(value: metrics.completionRate, role: .worker)
                    .frame(height: FrancoSphereDesign.MetricsDisplay.progressBarHeight)
            } else {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
        }
    }
    
    private var adminContent: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            if let metrics = metrics {
                HStack {
                    Label("Efficiency", systemImage: "chart.line.uptrend.xyaxis")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(metrics.maintenanceEfficiency * 100))%")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(efficiencyColor)
                }
                
                HStack {
                    Label("Workers", systemImage: "person.3.fill")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                    
                    Text("\(metrics.activeWorkers)")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                if metrics.overdueTasks > 0 {
                    HStack {
                        Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                        
                        Spacer()
                        
                        Text("\(metrics.overdueTasks)")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    }
                }
            } else {
                FrancoLoadingView(message: "Loading metrics...", role: .admin)
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var clientContent: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
            if let metrics = metrics {
                HStack {
                    Label("Compliance", systemImage: "checkmark.shield.fill")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text(metrics.isCompliant ? "Compliant" : "Review Needed")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(metrics.isCompliant ?
                            FrancoSphereDesign.DashboardColors.compliant :
                            FrancoSphereDesign.DashboardColors.warning
                        )
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((metrics.isCompliant ?
                                    FrancoSphereDesign.DashboardColors.compliant :
                                    FrancoSphereDesign.DashboardColors.warning
                                ).opacity(0.15))
                        )
                }
                
                HStack {
                    Label("Score", systemImage: "star.fill")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(
                                    index < Int(metrics.overallScore) ?
                                    FrancoSphereDesign.DashboardColors.warning :
                                    FrancoSphereDesign.DashboardColors.inactive
                                )
                        }
                        Text(String(format: "%.1f", metrics.overallScore))
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
                
                if metrics.urgentTasksCount > 0 {
                    HStack {
                        Label("Urgent", systemImage: "flag.fill")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        
                        Spacer()
                        
                        Text("\(metrics.urgentTasksCount)")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                    }
                }
            } else {
                FrancoLoadingView(message: "Loading compliance...", role: .client)
                    .scaleEffect(0.8)
            }
        }
    }
    
    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            .padding(8)
            .background(
                Circle()
                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
            )
    }
    
    // MARK: - Helper Properties
    
    private var buildingImageName: String {
        switch building.id {
        case "1": return "12_West_18th_Street"
        case "2": return "29_East_20th_Street"
        case "3": return "135West17thStreet"
        case "4": return "104_Franklin_Street"
        case "5": return "138West17thStreet"
        case "6": return "68_Perry_Street"
        case "7": return "112_West_18th_Street"
        case "8": return "41_Elizabeth_Street"
        case "9": return "117_West_17th_Street"
        case "10": return "131_Perry_Street"
        case "11": return "123_1st_Avenue"
        case "13": return "136_West_17th_Street"
        case "14": return "Rubin_Museum_142_148_West_17th_Street"
        case "15": return "133_East_15th_Street"
        case "16": return "Stuyvesant_Cove_Park"
        case "17": return "178_Spring_Street"
        case "18": return "36_Walker_Street"
        case "19": return "115_7th_Avenue"
        case "20": return "FrancoSphere_HQ"
        default:
            print("⚠️ No image found for building ID: \(building.id)")
            return "building_placeholder"
        }
    }
    
    private var efficiencyColor: Color {
        guard let metrics = metrics else { return FrancoSphereDesign.DashboardColors.inactive }
        return FrancoSphereDesign.EnumColors.trendDirection(
            metrics.maintenanceEfficiency >= 0.9 ? .up :
            metrics.maintenanceEfficiency >= 0.7 ? .stable : .down
        )
    }
}

// MARK: - Mini Property Card (for lists)

struct MiniPropertyCard: View {
    let building: NamedCoordinate
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                // Building icon
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(FrancoSphereDesign.DashboardColors.secondaryAction.opacity(0.15))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.name)
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    Text(subtitle)
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            .padding(FrancoSphereDesign.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview Provider

struct PropertyCard_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: FrancoSphereDesign.Spacing.md) {
                // Worker mode
                PropertyCard(
                    building: NamedCoordinate(
                        id: "14",
                        name: "Rubin Museum of Art",
                        latitude: 40.7401,
                        longitude: -73.9978
                    ),
                    metrics: BuildingMetrics(
                        buildingId: "14",
                        completionRate: 0.75,
                        overdueTasks: 1,
                        totalTasks: 12,
                        activeWorkers: 2,
                        overallScore: 4.2,
                        pendingTasks: 3,
                        urgentTasksCount: 1
                    ),
                    mode: .worker,
                    onTap: {}
                )
                
                // Admin mode
                PropertyCard(
                    building: NamedCoordinate(
                        id: "1",
                        name: "12 West 18th Street",
                        latitude: 40.7389,
                        longitude: -73.9936
                    ),
                    metrics: BuildingMetrics(
                        buildingId: "1",
                        completionRate: 0.92,
                        overdueTasks: 0,
                        totalTasks: 8,
                        activeWorkers: 3,
                        overallScore: 4.8,
                        pendingTasks: 1,
                        urgentTasksCount: 0,
                        maintenanceEfficiency: 0.88
                    ),
                    mode: .admin,
                    onTap: {}
                )
                
                // Client mode
                PropertyCard(
                    building: NamedCoordinate(
                        id: "16",
                        name: "Stuyvesant Cove Park",
                        latitude: 40.7335,
                        longitude: -73.9745
                    ),
                    metrics: BuildingMetrics(
                        buildingId: "16",
                        completionRate: 1.0,
                        overdueTasks: 0,
                        totalTasks: 5,
                        activeWorkers: 1,
                        overallScore: 5.0,
                        pendingTasks: 0,
                        urgentTasksCount: 0,
                        isCompliant: true
                    ),
                    mode: .client,
                    onTap: {}
                )
                
                // Loading state
                PropertyCard(
                    building: NamedCoordinate(
                        id: "999",
                        name: "Loading Building",
                        latitude: 0,
                        longitude: 0
                    ),
                    metrics: nil,
                    mode: .worker,
                    onTap: {}
                )
                
                // Mini cards
                VStack(spacing: 8) {
                    Text("Mini Cards")
                        .francoTypography(FrancoSphereDesign.Typography.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    MiniPropertyCard(
                        building: NamedCoordinate(
                            id: "1",
                            name: "12 West 18th Street",
                            latitude: 40.7389,
                            longitude: -73.9936
                        ),
                        subtitle: "3 tasks remaining",
                        onTap: {}
                    )
                    
                    MiniPropertyCard(
                        building: NamedCoordinate(
                            id: "14",
                            name: "Rubin Museum",
                            latitude: 40.7401,
                            longitude: -73.9978
                        ),
                        subtitle: "All tasks complete",
                        onTap: {}
                    )
                }
                .padding(.top)
            }
            .padding()
        }
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
