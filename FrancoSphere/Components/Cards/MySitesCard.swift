//
//  MySitesCard.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Complete Dark Elegance overhaul
//  ✅ ENHANCED: Rich visual design with images and metrics
//  ✅ ALIGNED: With FrancoSphereDesign system
//  ✅ IMPROVED: Multiple layout options for different contexts
//

import SwiftUI

struct MySitesCard: View {
    let building: NamedCoordinate
    var metrics: BuildingMetrics? = nil
    var showMetrics: Bool = true
    var style: CardStyle = .standard
    
    enum CardStyle {
        case standard
        case compact
        case grid
        case hero
    }
    
    @State private var imageLoadFailed = false
    
    var body: some View {
        switch style {
        case .standard:
            standardCard
        case .compact:
            compactCard
        case .grid:
            gridCard
        case .hero:
            heroCard
        }
    }
    
    // MARK: - Standard Card (List View)
    
    private var standardCard: some View {
        VStack(spacing: 0) {
            // Building image with overlay
            ZStack(alignment: .bottomLeading) {
                buildingImageView(height: 120)
                
                // Gradient overlay for text readability
                LinearGradient(
                    colors: [
                        Color.clear,
                        FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Building name overlay
                Text(building.name)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .padding(FrancoSphereDesign.Spacing.sm)
            }
            .frame(height: 120)
            
            // Metrics section (if available)
            if showMetrics, let metrics = metrics {
                metricsSection(metrics)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
        )
        .francoShadow(FrancoSphereDesign.Shadow.sm)
    }
    
    // MARK: - Compact Card (Horizontal List)
    
    private var compactCard: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            buildingImageView(width: 60, height: 60)
                .cornerRadius(FrancoSphereDesign.CornerRadius.sm)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                if let metrics = metrics {
                    HStack(spacing: FrancoSphereDesign.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                        
                        Text("\(Int(metrics.completionRate * 100))%")
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        
                        if metrics.pendingTasks > 0 {
                            Text("•")
                                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                            
                            Text("\(metrics.pendingTasks) pending")
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(FrancoSphereDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
        )
    }
    
    // MARK: - Grid Card (Collection View)
    
    private var gridCard: some View {
        VStack(spacing: 0) {
            // Square image
            buildingImageView(height: 140)
                .aspectRatio(1, contentMode: .fill)
                .clipped()
            
            // Building info
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let metrics = metrics {
                    HStack {
                        Circle()
                            .fill(statusColor(for: metrics))
                            .frame(width: 6, height: 6)
                        
                        Text(statusText(for: metrics))
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        
                        Spacer()
                    }
                }
            }
            .padding(FrancoSphereDesign.Spacing.sm)
        }
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
        )
        .francoShadow(FrancoSphereDesign.Shadow.sm)
    }
    
    // MARK: - Hero Card (Featured Display)
    
    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-width image
            buildingImageView(height: 200)
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.9)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content overlay
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
                Text(building.name)
                    .francoTypography(FrancoSphereDesign.Typography.title3)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let metrics = metrics {
                    HStack(spacing: FrancoSphereDesign.Spacing.md) {
                        metricPill(
                            icon: "checkmark.circle",
                            value: "\(Int(metrics.completionRate * 100))%",
                            color: FrancoSphereDesign.DashboardColors.success
                        )
                        
                        if metrics.activeWorkers > 0 {
                            metricPill(
                                icon: "person.2",
                                value: "\(metrics.activeWorkers)",
                                color: FrancoSphereDesign.DashboardColors.info
                            )
                        }
                        
                        if metrics.urgentTasksCount > 0 {
                            metricPill(
                                icon: "flag",
                                value: "\(metrics.urgentTasksCount)",
                                color: FrancoSphereDesign.DashboardColors.warning
                            )
                        }
                    }
                }
            }
            .padding(FrancoSphereDesign.Spacing.md)
        }
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.xl)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.xl)
                .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
        )
        .francoShadow(FrancoSphereDesign.Shadow.md)
    }
    
    // MARK: - Shared Components
    
    private func buildingImageView(width: CGFloat? = nil, height: CGFloat) -> some View {
        Group {
            if let imageName = buildingImageName,
               let image = UIImage(named: imageName),
               !imageLoadFailed {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                // Fallback gradient with icon
                ZStack {
                    LinearGradient(
                        colors: gradientColors(for: building.id),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: buildingIcon(for: building.name))
                        .font(.system(size: min(width ?? height, height) * 0.4))
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: width, height: height)
            }
        }
    }
    
    private var metricsSection: (BuildingMetrics) -> some View {
        { metrics in
            VStack(spacing: FrancoSphereDesign.Spacing.xs) {
                // Completion progress
                HStack {
                    Text("Completion")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(Int(metrics.completionRate * 100))%")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                FrancoMetricsProgress(value: metrics.completionRate, role: .worker)
                
                // Quick stats
                HStack {
                    if metrics.pendingTasks > 0 {
                        Label("\(metrics.pendingTasks)", systemImage: "clock")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                    }
                    
                    if metrics.activeWorkers > 0 {
                        Label("\(metrics.activeWorkers)", systemImage: "person.fill")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    }
                    
                    Spacer()
                    
                    FrancoStatusIndicator(
                        isActive: metrics.completionRate == 1.0,
                        role: .worker
                    )
                }
            }
            .padding(FrancoSphereDesign.Spacing.sm)
        }
    }
    
    private func metricPill(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private var buildingImageName: String? {
        // Map building IDs to image names
        let imageMap = [
            "1": "12_West_18th_Street",
            "2": "29_East_20th_Street",
            "3": "135West17thStreet",
            "4": "104_Franklin_Street",
            "5": "138West17thStreet",
            "6": "68_Perry_Street",
            "7": "112_West_18th_Street",
            "8": "41_Elizabeth_Street",
            "9": "117_West_17th_Street",
            "10": "131_Perry_Street",
            "11": "123_1st_Avenue",
            "13": "136_West_17th_Street",
            "14": "Rubin_Museum_142_148_West_17th_Street",
            "15": "133_East_15th_Street",
            "16": "Stuyvesant_Cove_Park",
            "17": "178_Spring_Street",
            "18": "36_Walker_Street",
            "19": "115_7th_Avenue",
            "20": "FrancoSphere_HQ"
        ]
        
        return imageMap[building.id]
    }
    
    private func gradientColors(for buildingId: String) -> [Color] {
        // Generate consistent gradient colors based on building ID
        let hash = buildingId.hashValue
        let hue = Double(abs(hash) % 360) / 360.0
        
        return [
            Color(hue: hue, saturation: 0.6, brightness: 0.4),
            Color(hue: hue, saturation: 0.7, brightness: 0.3)
        ]
    }
    
    private func buildingIcon(for name: String) -> String {
        let lowercased = name.lowercased()
        if lowercased.contains("museum") {
            return "building.columns.fill"
        } else if lowercased.contains("park") {
            return "leaf.fill"
        } else if lowercased.contains("hq") || lowercased.contains("headquarters") {
            return "star.fill"
        } else {
            return "building.2.fill"
        }
    }
    
    private func statusColor(for metrics: BuildingMetrics) -> Color {
        if metrics.completionRate == 1.0 {
            return FrancoSphereDesign.DashboardColors.success
        } else if metrics.overdueTasks > 0 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if metrics.pendingTasks > 0 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.info
        }
    }
    
    private func statusText(for metrics: BuildingMetrics) -> String {
        if metrics.completionRate == 1.0 {
            return "Complete"
        } else if metrics.overdueTasks > 0 {
            return "\(metrics.overdueTasks) overdue"
        } else if metrics.pendingTasks > 0 {
            return "\(metrics.pendingTasks) pending"
        } else {
            return "In progress"
        }
    }
}

// MARK: - Preview Provider

struct MySitesCard_Previews: PreviewProvider {
    static let sampleBuilding = NamedCoordinate(
        id: "14",
        name: "Rubin Museum of Art",
        latitude: 40.7401,
        longitude: -73.9978
    )
    
    static let sampleMetrics = BuildingMetrics(
        buildingId: "14",
        completionRate: 0.75,
        overdueTasks: 1,
        totalTasks: 12,
        activeWorkers: 2,
        overallScore: 4.2,
        pendingTasks: 3,
        urgentTasksCount: 1
    )
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: FrancoSphereDesign.Spacing.lg) {
                // Standard cards
                Text("Standard Style")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                MySitesCard(
                    building: sampleBuilding,
                    metrics: sampleMetrics,
                    style: .standard
                )
                
                MySitesCard(
                    building: NamedCoordinate(
                        id: "999",
                        name: "Unknown Building with a Very Long Name That Wraps",
                        latitude: 0,
                        longitude: 0
                    ),
                    metrics: nil,
                    style: .standard
                )
                
                // Compact cards
                Text("Compact Style")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                MySitesCard(
                    building: sampleBuilding,
                    metrics: sampleMetrics,
                    style: .compact
                )
                
                // Grid layout
                Text("Grid Style")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: FrancoSphereDesign.Spacing.md) {
                    ForEach(["14", "1", "16", "999"], id: \.self) { id in
                        MySitesCard(
                            building: NamedCoordinate(
                                id: id,
                                name: id == "14" ? "Rubin Museum" :
                                      id == "1" ? "12 West 18th St" :
                                      id == "16" ? "Stuyvesant Cove Park" :
                                      "Unknown Building",
                                latitude: 0,
                                longitude: 0
                            ),
                            metrics: id == "999" ? nil : sampleMetrics,
                            style: .grid
                        )
                    }
                }
                
                // Hero card
                Text("Hero Style")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                MySitesCard(
                    building: sampleBuilding,
                    metrics: sampleMetrics,
                    style: .hero
                )
            }
            .padding()
        }
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
