//
//  AssignedBuildingsView.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Uses reusable PropertyCard component
//  ✅ INTEGRATED: FrancoSphereDesign system
//  ✅ IMPROVED: Better visual hierarchy and animations
//  ✅ OPTIMIZED: Consistent with BuildingsView pattern
//

import SwiftUI
import Foundation

struct AssignedBuildingsView: View {
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @Environment(\.dismiss) private var dismiss
    
    // Use BuildingService directly without StateObject
    private let buildingService = BuildingService.shared
    
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var isLoading = true
    
    var assignedBuildings: [NamedCoordinate] {
        contextEngine.assignedBuildings
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark Elegance Background
                FrancoSphereDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerView
                    
                    // Content
                    if assignedBuildings.isEmpty {
                        emptyState
                    } else {
                        buildingsList
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .task {
                await loadBuildingMetrics()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Buildings")
                        .francoTypography(FrancoSphereDesign.Typography.title)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    if !assignedBuildings.isEmpty {
                        Text("\(assignedBuildings.count) assigned")
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                }
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .francoTypography(FrancoSphereDesign.Typography.body)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
            }
            .padding(FrancoSphereDesign.Spacing.md)
            
            // Separator
            Rectangle()
                .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                .frame(height: 1)
        }
        .background(FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.95))
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        FrancoEmptyState(
            icon: "building.2.crop.circle",
            title: "No Buildings Assigned",
            message: "Contact your supervisor to get building assignments",
            action: contactSupervisor,
            actionTitle: "Contact Supervisor",
            role: .worker
        )
        .padding(FrancoSphereDesign.Spacing.lg)
    }
    
    // MARK: - Buildings List
    
    private var buildingsList: some View {
        ScrollView {
            LazyVStack(spacing: FrancoSphereDesign.Spacing.sm) {
                ForEach(assignedBuildings, id: \.id) { building in
                    NavigationLink {
                        BuildingDetailView(
                            buildingId: building.id,
                            buildingName: building.name,
                            buildingAddress: building.address
                        )
                    } label: {
                        AssignedBuildingCard(
                            building: building,
                            metrics: buildingMetrics[building.id],
                            isCurrentBuilding: isCurrentBuilding(building),
                            isPrimaryAssignment: isPrimaryAssignment(building),
                            taskCount: getTaskCount(for: building)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(FrancoSphereDesign.Spacing.md)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isCurrentBuilding(_ building: NamedCoordinate) -> Bool {
        contextEngine.clockInStatus.isClockedIn &&
        contextEngine.clockInStatus.building?.id == building.id
    }
    
    private func isPrimaryAssignment(_ building: NamedCoordinate) -> Bool {
        contextEngine.assignedBuildings.first?.id == building.id
    }
    
    private func getTaskCount(for building: NamedCoordinate) -> Int {
        contextEngine.getTasksForBuilding(building.id).count
    }
    
    private func contactSupervisor() {
        if let url = URL(string: "mailto:shawn@francomanagementgroup.com?subject=Building%20Assignment%20Request") {
            UIApplication.shared.open(url)
        }
    }
    
    private func loadBuildingMetrics() async {
        isLoading = true
        
        // Load metrics for each assigned building
        await withTaskGroup(of: (String, BuildingMetrics?).self) { group in
            for building in assignedBuildings {
                group.addTask {
                    do {
                        let metrics = try await self.buildingService.getMetrics(for: building.id)
                        return (building.id, metrics)
                    } catch {
                        return (building.id, nil)
                    }
                }
            }
            
            // Collect results
            var metricsMap: [String: BuildingMetrics] = [:]
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    metricsMap[buildingId] = metrics
                }
            }
            
            await MainActor.run {
                self.buildingMetrics = metricsMap
                self.isLoading = false
            }
        }
    }
}

// MARK: - Assigned Building Card Component

struct AssignedBuildingCard: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let isCurrentBuilding: Bool
    let isPrimaryAssignment: Bool
    let taskCount: Int
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.md) {
            // Building image using MySitesCard
            MySitesCard(
                building: building,
                metrics: metrics,
                showMetrics: false,
                style: .compact
            )
            .frame(width: 60, height: 60)
            
            // Building info
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
                Text(building.displayName)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(2)
                
                Text(building.fullAddress)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    .lineLimit(1)
                
                // Status badges
                HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                    if isCurrentBuilding {
                        BuildingStatusBadge(
                            title: "CURRENT",
                            icon: "location.fill",
                            color: FrancoSphereDesign.DashboardColors.success
                        )
                    } else if isPrimaryAssignment {
                        BuildingStatusBadge(
                            title: "PRIMARY",
                            icon: "star.fill",
                            color: FrancoSphereDesign.DashboardColors.warning
                        )
                    } else {
                        BuildingStatusBadge(
                            title: "Assigned",
                            icon: "checkmark.circle.fill",
                            color: FrancoSphereDesign.DashboardColors.info
                        )
                    }
                    
                    Spacer()
                    
                    // Task count with metrics
                    if let metrics = metrics {
                        HStack(spacing: 4) {
                            if metrics.urgentTasksCount > 0 {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                            }
                            
                            Text("\(taskCount) tasks")
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .foregroundColor(taskCount > 0 ?
                                    FrancoSphereDesign.DashboardColors.warning :
                                    FrancoSphereDesign.DashboardColors.tertiaryText
                                )
                        }
                    } else if taskCount > 0 {
                        Text("\(taskCount) tasks")
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                    }
                }
                
                // Completion progress if available
                if let metrics = metrics {
                    FrancoMetricsProgress(value: metrics.completionRate, role: .worker)
                        .frame(height: 4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
        .francoCardPadding()
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(isCurrentBuilding ?
                    FrancoSphereDesign.DashboardColors.success.opacity(0.1) :
                    FrancoSphereDesign.DashboardColors.cardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                        .stroke(
                            isCurrentBuilding ?
                            FrancoSphereDesign.DashboardColors.success.opacity(0.3) :
                            FrancoSphereDesign.DashboardColors.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
        .francoShadow(FrancoSphereDesign.Shadow.sm)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            withAnimation(FrancoSphereDesign.Animations.quick) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(FrancoSphereDesign.Animations.quick) {
                    isPressed = false
                }
            }
        }
    }
}

// MARK: - Building Status Badge Component (Renamed to avoid conflict)

struct BuildingStatusBadge: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        Label(title, systemImage: icon)
            .francoTypography(FrancoSphereDesign.Typography.caption2)
            .fontWeight(.medium)
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
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

// MARK: - Preview

struct AssignedBuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        AssignedBuildingsView()
            .preferredColorScheme(.dark)
    }
}
