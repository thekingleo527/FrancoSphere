//
//  BuildingsView.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Reusable building components
//  ✅ INTEGRATED: FrancoSphereDesign system
//  ✅ IMPROVED: Better empty states and loading
//  ✅ OPTIMIZED: Uses PropertyCard and MySitesCard
//

import SwiftUI
import MapKit

struct BuildingsView: View {
    // MARK: - State
    @State private var buildings: [NamedCoordinate] = []
    @State private var buildingMetrics: [String: BuildingMetrics] = [:]
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var errorMessage: String?
    @State private var selectedFilter: BuildingFilter = .all
    @State private var showingMapView = false
    
    // Services
    private let buildingService = BuildingService.shared
    
    // MARK: - Enums
    enum BuildingFilter: String, CaseIterable {
        case all = "All"
        case residential = "Residential"
        case commercial = "Commercial"
        case cultural = "Cultural"
        case park = "Park"
        
        var icon: String {
            switch self {
            case .all: return "building.2"
            case .residential: return "house"
            case .commercial: return "building"
            case .cultural: return "building.columns"
            case .park: return "leaf"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return FrancoSphereDesign.DashboardColors.primaryAction
            case .residential: return FrancoSphereDesign.DashboardColors.info
            case .commercial: return FrancoSphereDesign.DashboardColors.warning
            case .cultural: return FrancoSphereDesign.DashboardColors.tertiaryAction
            case .park: return FrancoSphereDesign.DashboardColors.success
            }
        }
    }
    
    // MARK: - Computed Properties
    private var filteredBuildings: [NamedCoordinate] {
        var filtered = buildings
        
        // Apply filter
        if selectedFilter != .all {
            filtered = filtered.filter { building in
                getBuildingType(building) == selectedFilter
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.address.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { $0.name < $1.name }
    }
    
    private var buildingStats: (total: Int, residential: Int, commercial: Int, cultural: Int, park: Int) {
        let total = buildings.count
        let residential = buildings.filter { getBuildingType($0) == .residential }.count
        let commercial = buildings.filter { getBuildingType($0) == .commercial }.count
        let cultural = buildings.filter { getBuildingType($0) == .cultural }.count
        let park = buildings.filter { getBuildingType($0) == .park }.count
        return (total, residential, commercial, cultural, park)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                FrancoSphereDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom header
                    headerView
                    
                    // Content
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else if filteredBuildings.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            VStack(spacing: FrancoSphereDesign.Spacing.lg) {
                                // Portfolio stats
                                if !buildings.isEmpty && selectedFilter == .all {
                                    portfolioStatsView
                                }
                                
                                // Filter pills
                                filterPillsView
                                
                                // Buildings list
                                buildingsListView
                            }
                            .padding(FrancoSphereDesign.Spacing.md)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.dark)
            .task {
                await loadBuildings()
            }
            .sheet(isPresented: $showingMapView) {
                BuildingsMapView(buildings: filteredBuildings)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Building Portfolio")
                        .francoTypography(FrancoSphereDesign.Typography.title)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text("\(buildings.count) properties managed")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                    Button(action: { showingMapView = true }) {
                        Image(systemName: "map")
                            .font(.title3)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                            )
                    }
                    
                    Button(action: { Task { await loadBuildings() } }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                            )
                            .rotationEffect(.degrees(isLoading ? 360 : 0))
                            .animation(isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isLoading)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(FrancoSphereDesign.Spacing.md)
            
            // Search bar
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                TextField("Search buildings or addresses", text: $searchText)
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
            
            // Separator
            Rectangle()
                .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                .frame(height: 1)
        }
        .background(FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.95))
    }
    
    // MARK: - Portfolio Stats View
    private var portfolioStatsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                CompactStatCard(
                    title: "Total",
                    value: "\(buildingStats.total)",
                    icon: "building.2",
                    color: FrancoSphereDesign.DashboardColors.primaryAction
                )
                
                CompactStatCard(
                    title: "Residential",
                    value: "\(buildingStats.residential)",
                    icon: "house",
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                CompactStatCard(
                    title: "Commercial",
                    value: "\(buildingStats.commercial)",
                    icon: "building",
                    color: FrancoSphereDesign.DashboardColors.warning
                )
                
                CompactStatCard(
                    title: "Cultural",
                    value: "\(buildingStats.cultural)",
                    icon: "building.columns",
                    color: FrancoSphereDesign.DashboardColors.tertiaryAction
                )
                
                if buildingStats.park > 0 {
                    CompactStatCard(
                        title: "Parks",
                        value: "\(buildingStats.park)",
                        icon: "leaf",
                        color: FrancoSphereDesign.DashboardColors.success
                    )
                }
            }
        }
    }
    
    // MARK: - Filter Pills View
    private var filterPillsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                ForEach(BuildingFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedFilter == filter,
                        color: filter.color
                    ) {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            selectedFilter = filter
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Buildings List View
    private var buildingsListView: some View {
        LazyVStack(spacing: FrancoSphereDesign.Spacing.sm) {
            ForEach(filteredBuildings, id: \.id) { building in
                NavigationLink {
                    BuildingDetailView(
                        buildingId: building.id,
                        buildingName: building.name,
                        buildingAddress: building.address
                    )
                } label: {
                    BuildingRowCard(
                        building: building,
                        metrics: buildingMetrics[building.id],
                        type: getBuildingType(building)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.lg) {
            Spacer()
            
            FrancoLoadingView(
                message: "Loading portfolio...",
                role: .admin
            )
            
            Spacer()
        }
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: FrancoSphereDesign.Spacing.lg) {
            Spacer()
            
            VStack(spacing: FrancoSphereDesign.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                
                Text("Error Loading Buildings")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(message)
                    .francoTypography(FrancoSphereDesign.Typography.body)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    .multilineTextAlignment(.center)
                
                Button(action: { Task { await loadBuildings() } }) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(FrancoSphereDesign.DashboardColors.primaryAction)
                        .cornerRadius(FrancoSphereDesign.CornerRadius.md)
                }
                .padding(.top)
            }
            .padding(FrancoSphereDesign.Spacing.lg)
            
            Spacer()
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        FrancoEmptyState(
            icon: searchText.isEmpty ? "building.2.crop.circle" : "magnifyingglass",
            title: searchText.isEmpty ? "No Buildings" : "No Results",
            message: searchText.isEmpty ?
                "Buildings will appear here once added to the system" :
                "No buildings match '\(searchText)'",
            action: searchText.isEmpty ? nil : { searchText = "" },
            actionTitle: searchText.isEmpty ? nil : "Clear Search",
            role: .admin
        )
    }
    
    // MARK: - Helper Functions
    
    private func getBuildingType(_ building: NamedCoordinate) -> BuildingFilter {
        let name = building.name.lowercased()
        
        if name.contains("museum") {
            return .cultural
        } else if name.contains("park") {
            return .park
        } else if name.contains("perry") || name.contains("elizabeth") || name.contains("walker") {
            return .residential
        } else {
            return .commercial
        }
    }
    
    // MARK: - Data Loading
    
    private func loadBuildings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let loadedBuildings = try await buildingService.getAllBuildings()
            
            // Load metrics for each building
            await withTaskGroup(of: (String, BuildingMetrics?).self) { group in
                for building in loadedBuildings {
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
                }
            }
            
            await MainActor.run {
                self.buildings = loadedBuildings
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to load buildings: \(error.localizedDescription)"
                self.isLoading = false
                
                // Fallback to production buildings for preview/debug
                #if DEBUG
                self.buildings = CoreTypes.productionBuildings
                #endif
            }
        }
    }
}

// MARK: - Building Row Card Component

struct BuildingRowCard: View {
    let building: NamedCoordinate
    let metrics: BuildingMetrics?
    let type: BuildingsView.BuildingFilter
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.md) {
            // Building image
            buildingImage
            
            // Building info
            VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs) {
                Text(building.name)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                Text(building.address)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    .lineLimit(2)
                
                // Type badge and metrics
                HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                    // Building type
                    BuildingTypeBadge(type: type)
                    
                    Spacer()
                    
                    // Quick metrics
                    if let metrics = metrics {
                        BuildingQuickMetrics(metrics: metrics)
                    }
                }
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
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
    
    private var buildingImage: some View {
        MySitesCard(
            building: building,
            metrics: metrics,
            showMetrics: false,
            style: .compact
        )
        .frame(width: 80, height: 60)
    }
}

// MARK: - Building Type Badge

struct BuildingTypeBadge: View {
    let type: BuildingsView.BuildingFilter
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption2)
            
            Text(type.rawValue)
                .francoTypography(FrancoSphereDesign.Typography.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(type.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(type.color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(type.color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Building Quick Metrics

struct BuildingQuickMetrics: View {
    let metrics: BuildingMetrics
    
    var body: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            // Completion rate
            HStack(spacing: 2) {
                Circle()
                    .fill(completionColor)
                    .frame(width: 6, height: 6)
                
                Text("\(Int(metrics.completionRate * 100))%")
                    .francoTypography(FrancoSphereDesign.Typography.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            // Active workers
            if metrics.activeWorkers > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    
                    Text("\(metrics.activeWorkers)")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
            }
            
            // Urgent indicator
            if metrics.urgentTasksCount > 0 {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            }
        }
    }
    
    private var completionColor: Color {
        if metrics.completionRate >= 0.9 {
            return FrancoSphereDesign.DashboardColors.success
        } else if metrics.completionRate >= 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
}

// MARK: - Filter Pill Component

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                
                Text(title)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : FrancoSphereDesign.DashboardColors.primaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? color : FrancoSphereDesign.DashboardColors.glassOverlay)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? color.opacity(0.5) : FrancoSphereDesign.DashboardColors.borderSubtle,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Buildings Map View

struct BuildingsMapView: View {
    let buildings: [NamedCoordinate]
    @Environment(\.dismiss) private var dismiss
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7401, longitude: -73.9978),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            Map(coordinateRegion: $region, annotationItems: buildings) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )) {
                    BuildingMapPin(building: building)
                }
            }
            .ignoresSafeArea()
            .navigationTitle("Building Locations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Building Map Pin

struct BuildingMapPin: View {
    let building: NamedCoordinate
    @State private var showingDetail = false
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "mappin.circle.fill")
                .font(.title)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
            
            if showingDetail {
                Text(building.name)
                    .francoTypography(FrancoSphereDesign.Typography.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                            .francoShadow(FrancoSphereDesign.Shadow.sm)
                    )
                    .offset(y: -5)
            }
        }
        .onTapGesture {
            withAnimation(FrancoSphereDesign.Animations.spring) {
                showingDetail.toggle()
            }
        }
    }
}

// MARK: - Preview

struct BuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        BuildingsView()
            .preferredColorScheme(.dark)
    }
}
