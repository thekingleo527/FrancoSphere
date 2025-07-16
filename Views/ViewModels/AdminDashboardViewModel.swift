//
//  AdminDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: Production-ready admin dashboard with sophisticated features
//  ✅ ALIGNED: With fixed AdminDashboardViewModel and CoreTypes
//  ✅ REAL-TIME: Cross-dashboard synchronization and live updates
//  ✅ DESIGN: FrancoSphere glass morphism and dark theme
//  ✅ INTELLIGENCE: Building analytics and portfolio insights
//

import SwiftUI
import MapKit

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager
    
    // UI State
    @State private var selectedBuildingId: String?
    @State private var showingBuildingIntelligence = false
    @State private var showingPortfolioInsights = false
    @State private var selectedTab: AdminTab = .overview
    
    // Map region for building view
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with portfolio summary
                    adminHeader
                    
                    // Tab selector
                    adminTabBar
                    
                    // Main content
                    TabView(selection: $selectedTab) {
                        overviewTab
                            .tag(AdminTab.overview)
                        
                        buildingsTab
                            .tag(AdminTab.buildings)
                        
                        workersTab
                            .tag(AdminTab.workers)
                        
                        intelligenceTab
                            .tag(AdminTab.intelligence)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
            }
            .sheet(isPresented: $showingBuildingIntelligence) {
                buildingIntelligenceSheet
            }
            .sheet(isPresented: $showingPortfolioInsights) {
                portfolioInsightsSheet
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header Section

    private var adminHeader: some View {
        VStack(spacing: 16) {
            // Welcome and sync status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Admin Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Welcome, \(authManager.currentUser?.name ?? "Administrator")")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Sync status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.dashboardSyncStatus.color)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.dashboardSyncStatus.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            
            // Portfolio summary cards
            portfolioSummaryCards
            
            // Last update time
            if let lastUpdate = viewModel.lastUpdateTime {
                Text("Last updated: \(lastUpdate.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    // MARK: - Portfolio Summary Cards

    private var portfolioSummaryCards: some View {
        let summary = viewModel.getAdminPortfolioSummary()
        
        return HStack(spacing: 12) {
            // Buildings card
            AdminSummaryCard(
                title: "Buildings",
                value: "\(summary.totalBuildings)",
                subtitle: summary.completionPercentage,
                icon: "building.2.fill",
                color: .blue
            )
            
            // Workers card
            AdminSummaryCard(
                title: "Workers",
                value: "\(summary.totalWorkers)",
                subtitle: "Active",
                icon: "person.3.fill",
                color: .green
            )
            
            // Tasks card
            AdminSummaryCard(
                title: "Tasks",
                value: "\(summary.completedTasks)/\(summary.totalTasks)",
                subtitle: "Completed",
                icon: "checkmark.circle.fill",
                color: .orange
            )
            
            // Insights card
            AdminSummaryCard(
                title: "Critical",
                value: "\(summary.criticalInsights)",
                subtitle: "Issues",
                icon: "exclamationmark.triangle.fill",
                color: summary.criticalInsights > 0 ? .red : .gray
            )
        }
    }

    // MARK: - Tab Bar

    private var adminTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AdminTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        selectedTab == tab ?
                        Color.blue.opacity(0.3) : Color.clear
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    // MARK: - Tab Content

    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Real-time metrics grid
                buildingMetricsGrid
                
                // Recent cross-dashboard updates
                crossDashboardUpdatesSection
                
                // Quick actions
                quickActionsSection
            }
            .padding()
        }
        .refreshable {
            await viewModel.refreshDashboardData()
        }
    }

    private var buildingsTab: some View {
        VStack(spacing: 0) {
            // Buildings map
            Map(coordinateRegion: $region, annotationItems: viewModel.buildings) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )) {
                    BuildingMapAnnotation(
                        building: building,
                        metrics: viewModel.getBuildingMetrics(for: building.id),
                        onTap: {
                            selectedBuildingId = building.id
                            showingBuildingIntelligence = true
                        }
                    )
                }
            }
            .frame(height: 300)
            .cornerRadius(12)
            .padding()
            
            // Buildings list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.buildings, id: \.id) { building in
                        BuildingAdminCard(
                            building: building,
                            metrics: viewModel.getBuildingMetrics(for: building.id),
                            onIntelligenceAction: {
                                selectedBuildingId = building.id
                                showingBuildingIntelligence = true
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }

    private var workersTab: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.activeWorkers, id: \.id) { worker in
                    WorkerAdminCard(worker: worker)
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadDashboardData()
        }
    }

    private var intelligenceTab: some View {
        VStack(spacing: 16) {
            // Portfolio insights header
            HStack {
                Text("Portfolio Intelligence")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isLoadingInsights {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Button("Refresh") {
                        Task {
                            await viewModel.loadPortfolioInsights()
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Intelligence insights
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.portfolioInsights, id: \.id) { insight in
                        IntelligenceInsightCard(insight: insight)
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Building Metrics Grid

    private var buildingMetricsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(viewModel.buildingMetrics.prefix(6)), id: \.key) { buildingId, metrics in
                    BuildingMetricsCard(
                        buildingId: buildingId,
                        buildingName: viewModel.buildings.first { $0.id == buildingId }?.name ?? "Building \(buildingId)",
                        metrics: metrics,
                        onTap: {
                            selectedBuildingId = buildingId
                            showingBuildingIntelligence = true
                        }
                    )
                }
            }
        }
    }

    // MARK: - Cross-Dashboard Updates Section

    private var crossDashboardUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Live Updates")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.crossDashboardUpdates.isEmpty {
                Text("No recent updates")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                ForEach(viewModel.crossDashboardUpdates.prefix(5), id: \.description) { update in
                    CrossDashboardUpdateRow(update: update)
                }
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                AdminQuickActionButton(
                    title: "Portfolio Insights",
                    icon: "brain.head.profile",
                    color: .purple
                ) {
                    showingPortfolioInsights = true
                }
                
                AdminQuickActionButton(
                    title: "Refresh Data",
                    icon: "arrow.clockwise",
                    color: .blue,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.refreshDashboardData()
                    }
                }
            }
        }
    }

    // MARK: - Sheets

    private var buildingIntelligenceSheet: some View {
        NavigationView {
            BuildingIntelligenceDetailView(
                buildingId: selectedBuildingId ?? "",
                insights: viewModel.selectedBuildingInsights,
                isLoading: viewModel.isLoadingIntelligence
            )
            .navigationTitle("Building Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingBuildingIntelligence = false
                        viewModel.clearBuildingIntelligence()
                    }
                }
            }
        }
        .onAppear {
            if let buildingId = selectedBuildingId {
                Task {
                    await viewModel.fetchBuildingIntelligence(for: buildingId)
                }
            }
        }
    }

    private var portfolioInsightsSheet: some View {
        NavigationView {
            IntelligenceInsightsView(
                insights: viewModel.portfolioInsights,
                onRefreshInsights: {
                    await viewModel.loadPortfolioInsights()
                }
            )
            .navigationTitle("Portfolio Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingPortfolioInsights = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct AdminSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct BuildingMapAnnotation: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    )
                
                Text(building.name)
                    .font(.caption2)
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.9))
                    .cornerRadius(4)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        guard let metrics = metrics else { return .gray }
        
        if metrics.overdueTasks > 0 { return .red }
        if metrics.urgentTasksCount > 0 { return .orange }
        if metrics.completionRate >= 0.8 { return .green }
        return .blue
    }
}

struct BuildingAdminCard: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onIntelligenceAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Building icon and status
            VStack {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(statusColor)
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
            }
            
            // Building info
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let metrics = metrics {
                    Text(metrics.displayStatus)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(metrics.pendingTasks) pending • \(metrics.activeWorkers) workers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Metrics summary
            if let metrics = metrics {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(metrics.completionRate * 100))%")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Complete")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            // Intelligence button
            Button(action: onIntelligenceAction) {
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.purple)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        guard let metrics = metrics else { return .gray }
        
        if metrics.overdueTasks > 0 { return .red }
        if metrics.urgentTasksCount > 0 { return .orange }
        if metrics.completionRate >= 0.8 { return .green }
        return .blue
    }
}

struct WorkerAdminCard: View {
    let worker: WorkerProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Worker avatar
            Circle()
                .fill(.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(worker.name.prefix(1))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            // Worker info
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(worker.role.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct BuildingMetricsCard: View {
    let buildingId: String
    let buildingName: String
    let metrics: CoreTypes.BuildingMetrics
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(buildingName)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                }
                
                Text("\(Int(metrics.completionRate * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("\(metrics.pendingTasks) pending")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding()
            .frame(height: 80)
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        if metrics.overdueTasks > 0 { return .red }
        if metrics.urgentTasksCount > 0 { return .orange }
        if metrics.completionRate >= 0.8 { return .green }
        return .blue
    }
}

struct CrossDashboardUpdateRow: View {
    let update: CoreTypes.CrossDashboardUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.blue.opacity(0.3))
                .frame(width: 8, height: 8)
            
            Text(update.description)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Text("Now")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct AdminQuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var isLoading: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    Image(systemName: icon)
                        .font(.headline)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.3))
            .cornerRadius(8)
        }
        .disabled(isLoading)
    }
}

struct IntelligenceInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(insight.priority.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(priorityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .cornerRadius(4)
            }
            
            Text(insight.description)
                .font(.body)
                .foregroundColor(.gray)
            
            if insight.actionRequired {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Action Required")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct BuildingIntelligenceDetailView: View {
    let buildingId: String
    let insights: [CoreTypes.IntelligenceInsight]
    let isLoading: Bool
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Analyzing building data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if insights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    
                    Text("No intelligence data available")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(insights, id: \.id) { insight in
                            IntelligenceInsightCard(insight: insight)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Tab Enum

enum AdminTab: String, CaseIterable {
    case overview = "overview"
    case buildings = "buildings"
    case workers = "workers"
    case intelligence = "intelligence"
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .buildings: return "Buildings"
        case .workers: return "Workers"
        case .intelligence: return "Intelligence"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .buildings: return "building.2.fill"
        case .workers: return "person.3.fill"
        case .intelligence: return "brain.head.profile"
        }
    }
}
