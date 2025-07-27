//
//  AdminDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ COMPLETE: Production-ready admin dashboard view
//  ✅ ALIGNED: With AdminDashboardViewModel (no duplicate definitions)
//  ✅ REAL-TIME: Cross-dashboard synchronization ready
//  ✅ DESIGN: FrancoSphere glass morphism and dark theme
//  ✅ FIXED: No compilation errors or duplicate types
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
                    
                    // Main content based on selected tab
                    tabContent
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
                    
                    Text("Welcome, \(authManager.currentUser?.name ?? "Admin")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Sync status indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(viewModel.dashboardSyncStatus == .synced ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    
                    Text(viewModel.dashboardSyncStatus.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
            .padding(.horizontal)
            
            // Portfolio summary cards
            if !viewModel.isLoading {
                portfolioSummaryCards
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(height: 100)
            }
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }

    // MARK: - Portfolio Summary Cards

    private var portfolioSummaryCards: some View {
        let summary = viewModel.getAdminPortfolioSummary()
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                AdminSummaryCard(
                    title: "Buildings",
                    value: "\(summary.totalBuildings)",
                    subtitle: "Active properties",
                    icon: "building.2.fill",
                    color: .blue
                )
                
                AdminSummaryCard(
                    title: "Workers",
                    value: "\(summary.totalWorkers)",
                    subtitle: "Active workers",
                    icon: "person.3.fill",
                    color: .green
                )
                
                AdminSummaryCard(
                    title: "Tasks",
                    value: "\(summary.completedTasks)/\(summary.totalTasks)",
                    subtitle: "Completed today",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
                
                AdminSummaryCard(
                    title: "Efficiency",
                    value: summary.completionPercentage,
                    subtitle: summary.efficiencyDescription,
                    icon: summary.efficiencyStatus.icon,
                    color: summary.efficiencyStatus.color
                )
                
                AdminSummaryCard(
                    title: "Insights",
                    value: "\(summary.criticalInsights)",
                    subtitle: "Critical alerts",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Tab Bar

    private var adminTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AdminTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ? Color.blue.opacity(0.3) : Color.clear
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .buildings:
            buildingsContent
        case .workers:
            workersContent
        case .intelligence:
            intelligenceContent
        }
    }

    // MARK: - Overview Tab

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Recent updates section
                recentUpdatesSection
                
                // Building metrics overview
                buildingMetricsOverview
                
                // Worker status overview
                workerStatusOverview
            }
            .padding()
        }
    }

    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Updates")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.crossDashboardUpdates.isEmpty {
                Text("No recent updates")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.crossDashboardUpdates.prefix(5)) { update in
                        UpdateRow(update: update)
                    }
                }
            }
        }
    }

    private var buildingMetricsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Building Performance")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .buildings
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.buildings.prefix(5), id: \.id) { building in
                        BuildingMetricCard(
                            building: building,
                            metrics: viewModel.getBuildingMetrics(for: building.id)
                        )
                    }
                }
            }
        }
    }

    private var workerStatusOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Workers")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.activeWorkers.count) online")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(viewModel.activeWorkers.prefix(5), id: \.id) { worker in
                    WorkerStatusRow(worker: worker)
                }
            }
        }
    }

    // MARK: - Buildings Tab

    private var buildingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.buildings, id: \.id) { building in
                    BuildingAdminCard(
                        building: building,
                        metrics: viewModel.getBuildingMetrics(for: building.id),
                        insights: viewModel.getIntelligenceInsights(for: building.id),
                        onTap: {
                            selectedBuildingId = building.id
                            showingBuildingIntelligence = true
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Workers Tab

    private var workersContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.activeWorkers, id: \.id) { worker in
                    WorkerAdminCard(worker: worker)
                }
            }
            .padding()
        }
    }

    // MARK: - Intelligence Tab

    private var intelligenceContent: some View {
        VStack(spacing: 16) {
            // Intelligence header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Intelligence")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.portfolioInsights.count) insights available")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingPortfolioInsights = true
                }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Insights list
            if viewModel.portfolioInsights.isEmpty {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No insights available")
                        .foregroundColor(.gray)
                }
                
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.portfolioInsights.prefix(10), id: \.id) { insight in
                            IntelligenceInsightCard(insight: insight)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Sheets

    private var buildingIntelligenceSheet: some View {
        NavigationView {
            BuildingIntelligencePanelContent(
                buildingId: selectedBuildingId ?? "",
                buildingName: viewModel.buildings.first { $0.id == selectedBuildingId }?.name ?? "",
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
                _Concurrency.Task {
                    await viewModel.fetchBuildingIntelligence(for: buildingId)
                }
            }
        }
    }

    private var portfolioInsightsSheet: some View {
        NavigationView {
            IntelligenceInsightsView(
                insights: viewModel.portfolioInsights
            ) {
                _Concurrency.Task {
                    await viewModel.loadPortfolioInsights()
                }
            }
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

struct UpdateRow: View {
    let update: DashboardUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: update.source.icon)
                .font(.caption)
                .foregroundColor(update.source.color)
                .frame(width: 24, height: 24)
                .background(update.source.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(update.description)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(update.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct BuildingMetricCard: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(building.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .lineLimit(1)
            
            if let metrics = metrics {
                HStack(spacing: 4) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption2)
                    Text("\(Int(metrics.completionRate * 100))%")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(metrics.completionRate > 0.8 ? .green : .orange)
                
                Text("\(metrics.overdueTasks) overdue")
                    .font(.caption2)
                    .foregroundColor(metrics.overdueTasks > 0 ? .red : .gray)
            } else {
                Text("Loading...")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: 120)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct WorkerStatusRow: View {
    let worker: WorkerProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(worker.isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(worker.name)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(worker.role.rawValue.capitalized)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct BuildingAdminCard: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let insights: [CoreTypes.IntelligenceInsight]
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let address = building.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    if !insights.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                            Text("\(insights.count)")
                                .font(.caption)
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                if let metrics = metrics {
                    HStack(spacing: 16) {
                        MetricItem(
                            label: "Completion",
                            value: "\(Int(metrics.completionRate * 100))%",
                            color: metrics.completionRate > 0.8 ? .green : .orange
                        )
                        
                        MetricItem(
                            label: "Overdue",
                            value: "\(metrics.overdueTasks)",
                            color: metrics.overdueTasks > 0 ? .red : .green
                        )
                        
                        MetricItem(
                            label: "Score",
                            value: "\(Int(metrics.overallScore))",
                            color: .blue
                        )
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkerAdminCard: View {
    let worker: WorkerProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(worker.name.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(worker.role.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if !worker.skills.isEmpty {
                        Text("• \(worker.skills.count) skills")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(worker.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(worker.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(worker.isActive ? .green : .gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct IntelligenceInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                if insight.actionRequired {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(insight.priority.color)
                        .frame(width: 6, height: 6)
                    
                    Text(insight.priority.rawValue)
                        .font(.caption2)
                        .foregroundColor(insight.priority.color)
                }
                
                Spacer()
                
                if !insight.affectedBuildings.isEmpty {
                    Text("\(insight.affectedBuildings.count) buildings")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// Add this helper view
struct BuildingIntelligencePanelContent: View {
    let buildingId: String
    let buildingName: String
    let insights: [CoreTypes.IntelligenceInsight]
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading insights...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if insights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("No issues found")
                        .font(.headline)
                    
                    Text("This building is operating optimally")
                        .font(.caption)
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
    }
}

// Add this helper view for IntelligenceInsightsView
struct IntelligenceInsightsView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onRefreshInsights: () -> Void
    
    @State private var isRefreshing = false
    
    init(insights: [CoreTypes.IntelligenceInsight], onRefreshInsights: @escaping () -> Void) {
        self.insights = insights
        self.onRefreshInsights = onRefreshInsights
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    IntelligenceInsightCard(insight: insight)
                }
            }
            .padding()
        }
        .refreshable {
            onRefreshInsights()
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

// MARK: - Extensions

extension CoreTypes.DashboardSyncStatus {
    var description: String {
        switch self {
        case .synced: return "Synced"
        case .syncing: return "Syncing..."
        case .failed: return "Sync Failed"
        case .offline: return "Offline"
        }
    }
}

extension DashboardUpdate {
    var description: String {
        let sourcePrefix = "[\(source.displayName)]"
        let typeDescription = type.displayName
        
        if let buildingId = buildingId {
            return "\(sourcePrefix) \(typeDescription) - Building \(buildingId)"
        } else if let workerId = workerId {
            return "\(sourcePrefix) \(typeDescription) - Worker \(workerId)"
        } else {
            return "\(sourcePrefix) \(typeDescription)"
        }
    }
}
