//
//  BuildingSelectionView.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Uses PropertyCard for building display
//  ✅ INTEGRATED: FrancoSphereDesign system
//  ✅ IMPROVED: Better map integration and transitions
//  ✅ OPTIMIZED: Consistent with other building views
//  ✅ FIXED: Renamed BuildingMapPin to avoid redeclaration
//

import SwiftUI
import MapKit
import CoreLocation

struct BuildingSelectionView: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    var purpose: SelectionPurpose = .clockIn
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var selectedBuilding: NamedCoordinate?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7401, longitude: -73.9978),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    enum ViewMode {
        case list
        case map
    }
    
    enum SelectionPurpose {
        case clockIn
        case assignment
        case navigation
        
        var title: String {
            switch self {
            case .clockIn: return "Select Building to Clock In"
            case .assignment: return "Select Building"
            case .navigation: return "Select Destination"
            }
        }
        
        var actionText: String {
            switch self {
            case .clockIn: return "Clock In Here"
            case .assignment: return "Select"
            case .navigation: return "Navigate"
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredBuildings: [NamedCoordinate] {
        if searchText.isEmpty {
            return buildings
        } else {
            return buildings.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dark Elegance Background
                FrancoSphereDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerView
                    
                    // View content
                    if viewMode == .list {
                        listContent
                    } else {
                        mapContent
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
            // Title bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .francoTypography(FrancoSphereDesign.Typography.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                
                Spacer()
                
                Text(purpose.title)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                // View mode toggle
                Button(action: toggleViewMode) {
                    Image(systemName: viewMode == .list ? "map" : "list.bullet")
                        .font(.title3)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                        )
                }
            }
            .padding(FrancoSphereDesign.Spacing.md)
            
            // Search bar
            searchBar
            
            // Separator
            Rectangle()
                .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                .frame(height: 1)
        }
        .background(FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.95))
    }
    
    private var searchBar: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            
            TextField("Search buildings...", text: $searchText)
                .francoTypography(FrancoSphereDesign.Typography.body)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
        }
        .padding(FrancoSphereDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
        )
        .padding(.horizontal, FrancoSphereDesign.Spacing.md)
        .padding(.bottom, FrancoSphereDesign.Spacing.sm)
    }
    
    // MARK: - List Content
    
    private var listContent: some View {
        ScrollView {
            if filteredBuildings.isEmpty {
                emptySearchState
            } else {
                LazyVStack(spacing: FrancoSphereDesign.Spacing.sm) {
                    ForEach(filteredBuildings) { building in
                        SelectableBuildingCard(
                            building: building,
                            metrics: buildingMetrics[building.id],
                            purpose: purpose,
                            onSelect: {
                                handleSelection(building)
                            }
                        )
                    }
                }
                .padding(FrancoSphereDesign.Spacing.md)
            }
        }
    }
    
    // MARK: - Map Content
    
    private var mapContent: some View {
        ZStack {
            Map(coordinateRegion: $region, annotationItems: filteredBuildings) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )) {
                    BuildingSelectionMapPin(
                        building: building,
                        isSelected: selectedBuilding?.id == building.id,
                        onTap: {
                            withAnimation(FrancoSphereDesign.Animations.spring) {
                                selectedBuilding = building
                            }
                        }
                    )
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Selected building detail overlay
            if let selected = selectedBuilding {
                VStack {
                    Spacer()
                    
                    SelectedBuildingOverlay(
                        building: selected,
                        metrics: buildingMetrics[selected.id],
                        purpose: purpose,
                        onSelect: {
                            handleSelection(selected)
                        },
                        onDismiss: {
                            withAnimation(FrancoSphereDesign.Animations.spring) {
                                selectedBuilding = nil
                            }
                        }
                    )
                    .padding(FrancoSphereDesign.Spacing.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptySearchState: some View {
        FrancoEmptyState(
            icon: "magnifyingglass",
            title: "No Results",
            message: "No buildings match '\(searchText)'",
            action: { searchText = "" },
            actionTitle: "Clear Search",
            role: .worker
        )
        .padding(FrancoSphereDesign.Spacing.lg)
    }
    
    // MARK: - Helper Methods
    
    private func toggleViewMode() {
        withAnimation(FrancoSphereDesign.Animations.spring) {
            viewMode = viewMode == .list ? .map : .list
        }
    }
    
    private func handleSelection(_ building: NamedCoordinate) {
        onSelect(building)
        dismiss()
    }
    
    private func loadBuildingMetrics() async {
        // Load metrics for buildings (similar to AssignedBuildingsView)
        await withTaskGroup(of: (String, BuildingMetrics?).self) { group in
            for building in buildings {
                group.addTask {
                    // Simulate metrics loading - replace with actual service call
                    let mockMetrics = BuildingMetrics(
                        buildingId: building.id,
                        completionRate: Double.random(in: 0.5...1.0),
                        overdueTasks: Int.random(in: 0...3),
                        totalTasks: Int.random(in: 5...15),
                        activeWorkers: Int.random(in: 1...5),
                        overallScore: Double.random(in: 3.5...5.0),
                        pendingTasks: Int.random(in: 0...5),
                        urgentTasksCount: Int.random(in: 0...2)
                    )
                    return (building.id, mockMetrics)
                }
            }
            
            var metricsMap: [String: BuildingMetrics] = [:]
            for await (buildingId, metrics) in group {
                if let metrics = metrics {
                    metricsMap[buildingId] = metrics
                }
            }
            
            await MainActor.run {
                self.buildingMetrics = metricsMap
            }
        }
    }
}

// MARK: - Selectable Building Card

struct SelectableBuildingCard: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let purpose: BuildingSelectionView.SelectionPurpose
    let onSelect: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: FrancoSphereDesign.Spacing.md) {
                // Building info using PropertyCard components
                PropertyCard(
                    building: building,
                    metrics: metrics,
                    mode: .worker,
                    onTap: {}
                )
                .allowsHitTesting(false) // Disable inner tap
                .overlay(
                    HStack {
                        Spacer()
                        
                        // Action button
                        VStack {
                            Image(systemName: actionIcon)
                                .font(.title2)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                            
                            Text(purpose.actionText)
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                        }
                        .padding(.trailing, FrancoSphereDesign.Spacing.md)
                    }
                )
            }
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(FrancoSphereDesign.Animations.quick) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var actionIcon: String {
        switch purpose {
        case .clockIn: return "clock.fill"
        case .assignment: return "checkmark.circle.fill"
        case .navigation: return "location.fill"
        }
    }
}

// MARK: - Selected Building Overlay (for Map View)

struct SelectedBuildingOverlay: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let purpose: BuildingSelectionView.SelectionPurpose
    let onSelect: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.md) {
            // Dismiss handle
            Capsule()
                .fill(FrancoSphereDesign.DashboardColors.tertiaryText)
                .frame(width: 40, height: 4)
                .padding(.top, 8)
            
            // Building card
            MySitesCard(
                building: building,
                metrics: metrics,
                style: .hero
            )
            
            // Action button
            Button(action: onSelect) {
                HStack {
                    Image(systemName: actionIcon)
                    Text(purpose.actionText)
                }
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(FrancoSphereDesign.DashboardColors.primaryAction)
                .cornerRadius(FrancoSphereDesign.CornerRadius.md)
            }
        }
        .padding(FrancoSphereDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.xl)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .francoShadow(FrancoSphereDesign.Shadow.lg)
        )
        .onTapGesture {
            onDismiss()
        }
    }
    
    private var actionIcon: String {
        switch purpose {
        case .clockIn: return "clock.fill"
        case .assignment: return "checkmark.circle.fill"
        case .navigation: return "location.fill"
        }
    }
}

// MARK: - Building Selection Map Pin (Renamed from BuildingMapPin to avoid conflict)

struct BuildingSelectionMapPin: View {
    let building: NamedCoordinate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                    .font(.title)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                    .animation(FrancoSphereDesign.Animations.spring, value: isSelected)
                
                if !isSelected {
                    // Small label when not selected
                    Text(building.name)
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                                .francoShadow(FrancoSphereDesign.Shadow.sm)
                        )
                        .offset(y: -5)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview("List View") {
    BuildingSelectionView(
        buildings: [
            NamedCoordinate(
                id: "1",
                name: "12 West 18th Street",
                address: "12 West 18th Street, New York, NY",
                latitude: 40.7389,
                longitude: -73.9936
            ),
            NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7401,
                longitude: -73.9978
            )
        ],
        onSelect: { building in
            print("Selected: \(building.name)")
        },
        purpose: .clockIn
    )
    .preferredColorScheme(.dark)
}

#Preview("Map View") {
    BuildingSelectionView(
        buildings: CoreTypes.productionBuildings,
        onSelect: { building in
            print("Selected: \(building.name)")
        },
        purpose: .navigation
    )
    .preferredColorScheme(.dark)
}
