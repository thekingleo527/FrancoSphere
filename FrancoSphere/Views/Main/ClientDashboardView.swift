//
//  ClientDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With actual project types and components
//  ✅ RESPONSIVE: Adaptive layout for all device sizes
//

import SwiftUI
import Combine

struct ClientDashboardView: View {
    @StateObject private var viewModel = ClientDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager
    
    @State private var selectedTabIndex = 0
    @State private var showingIntelligenceDetail = false
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var showingBuildingDetail = false
    @State private var selectedBuilding: NamedCoordinate?
    
    private let tabs = [
        GlassTabItem(title: "Overview", icon: "chart.pie", selectedIcon: "chart.pie.fill"),
        GlassTabItem(title: "Buildings", icon: "building.2", selectedIcon: "building.2.fill"),
        GlassTabItem(title: "Compliance", icon: "checkmark.shield", selectedIcon: "checkmark.shield.fill"),
        GlassTabItem(title: "Insights", icon: "brain", selectedIcon: "brain.fill")
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    clientHeader
                    
                    // Content
                    ScrollView {
                        tabContent
                            .padding()
                    }
                    
                    // Tab bar
                    GlassTabBar(
                        selectedTab: $selectedTabIndex,
                        tabs: tabs
                    )
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadPortfolioIntelligence()
            }
            .refreshable {
                await viewModel.forceRefresh()
            }
            .sheet(isPresented: $showingIntelligenceDetail) {
                if let insight = selectedInsight {
                    InsightDetailSheet(insight: insight)
                }
            }
            .sheet(isPresented: $showingBuildingDetail) {
                if let building = selectedBuilding {
                    BuildingDetailSheet(building: building, metrics: viewModel.getBuildingMetrics(for: building.id))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    
    private var clientHeader: some View {
        VStack(spacing: 0) {
            // Main header
            HStack(alignment: .top) {
                // Title section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Overview")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Welcome, \(authManager.currentUser?.name ?? "Client")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Nova AI Assistant
                NovaAvatar(size: 44)
                    .onTapGesture {
                        HapticManager.impact(.light)
                        // TODO: Launch Nova AI chat
                    }
            }
            .padding()
            
            // Portfolio summary metrics
            portfolioSummarySection
                .padding(.horizontal)
                .padding(.bottom)
            
            // Simple sync status
            HStack {
                Image(systemName: syncStatusIcon)
                    .foregroundColor(syncStatusColor)
                    .font(.caption)
                Text(viewModel.dashboardSyncStatus.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(.ultraThinMaterial)
    }
    
    private var syncStatusIcon: String {
        switch viewModel.dashboardSyncStatus {
        case .syncing: return "arrow.triangle.2.circlepath"
        case .synced: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .offline: return "wifi.slash"
        }
    }
    
    private var syncStatusColor: Color {
        switch viewModel.dashboardSyncStatus {
        case .syncing: return .blue
        case .synced: return .green
        case .failed: return .red
        case .offline: return .gray
        }
    }
    
    private var portfolioSummarySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Buildings metric
                PortfolioMetricCard(
                    title: "Buildings",
                    value: "\(viewModel.totalBuildings)",
                    icon: "building.2.fill",
                    color: FrancoSphereDesign.DashboardColors.clientPrimary,
                    trend: nil
                )
                
                // Compliance metric
                PortfolioMetricCard(
                    title: "Compliance",
                    value: "\(viewModel.complianceScore)%",
                    icon: "checkmark.shield.fill",
                    color: viewModel.complianceScore >= 90 ? FrancoSphereDesign.DashboardColors.compliant : FrancoSphereDesign.DashboardColors.warning,
                    trend: viewModel.monthlyTrend
                )
                
                // Active Workers metric
                PortfolioMetricCard(
                    title: "Active Workers",
                    value: "\(viewModel.activeWorkers)",
                    icon: "person.3.fill",
                    color: .blue,
                    trend: nil
                )
                
                // Critical Issues metric
                PortfolioMetricCard(
                    title: "Critical Issues",
                    value: "\(viewModel.criticalIssues)",
                    icon: "exclamationmark.triangle.fill",
                    color: viewModel.criticalIssues > 0 ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.compliant,
                    trend: nil
                )
            }
            .padding(.horizontal, 1)
        }
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private var tabContent: some View {
        switch selectedTabIndex {
        case 0:
            PortfolioOverviewTab(viewModel: viewModel)
        case 1:
            BuildingsTab(
                viewModel: viewModel,
                onBuildingTap: { building in
                    selectedBuilding = building
                    showingBuildingDetail = true
                }
            )
        case 2:
            ComplianceTab(viewModel: viewModel)
        case 3:
            InsightsTab(
                viewModel: viewModel,
                onInsightTap: { insight in
                    selectedInsight = insight
                    showingIntelligenceDetail = true
                }
            )
        default:
            PortfolioOverviewTab(viewModel: viewModel)
        }
    }
}

// MARK: - Tab Content Views

struct PortfolioOverviewTab: View {
    @ObservedObject var viewModel: ClientDashboardViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Intelligence Preview
            if !viewModel.intelligenceInsights.isEmpty {
                IntelligencePreviewPanel(
                    insights: Array(viewModel.intelligenceInsights.prefix(3)),
                    onRefresh: {
                        // Make it public in viewModel or use different approach
                        await viewModel.refreshData()
                    }
                )
            }
            
            // Performance overview
            PerformanceOverviewCard(viewModel: viewModel)
            
            // Executive Summary
            if let summary = viewModel.executiveSummary {
                ExecutiveSummaryCard(summary: summary)
                    .task {
                        await viewModel.generateExecutiveSummary()
                    }
            }
            
            // Strategic Recommendations
            if !viewModel.strategicRecommendations.isEmpty {
                StrategicRecommendationsCard(recommendations: viewModel.strategicRecommendations)
                    .task {
                        await viewModel.loadStrategicRecommendations()
                    }
            }
        }
    }
}

struct BuildingsTab: View {
    @ObservedObject var viewModel: ClientDashboardViewModel
    let onBuildingTap: (NamedCoordinate) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with filter options
            HStack {
                Text("Portfolio Buildings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    Button("All Buildings") { }
                    Button("Critical Issues") { }
                    Button("High Performance") { }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Buildings grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 300, maximum: 400))
            ], spacing: 16) {
                ForEach(viewModel.buildingsList, id: \.id) { building in
                    BuildingCard(
                        building: building,
                        metrics: viewModel.getBuildingMetrics(for: building.id),
                        onTap: { onBuildingTap(building) }
                    )
                }
            }
        }
    }
}

struct ComplianceTab: View {
    @ObservedObject var viewModel: ClientDashboardViewModel
    @State private var selectedSeverity: CoreTypes.ComplianceSeverity?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Compliance Overview
            ComplianceOverviewCard(
                overallScore: Double(viewModel.complianceScore) / 100.0,
                criticalIssues: viewModel.criticalIssues,
                openIssues: viewModel.complianceIssues.filter { $0.status == .open }.count
            )
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedSeverity == nil,
                        action: { selectedSeverity = nil }
                    )
                    
                    ForEach(CoreTypes.ComplianceSeverity.allCases, id: \.self) { severity in
                        FilterChip(
                            title: severity.rawValue,
                            isSelected: selectedSeverity == severity,
                            color: severityColor(for: severity),
                            action: { selectedSeverity = severity }
                        )
                    }
                }
                .padding(.horizontal, 1)
            }
            
            // Issues list
            VStack(spacing: 12) {
                ForEach(filteredComplianceIssues, id: \.id) { issue in
                    ClientComplianceIssueCard(issue: issue)
                }
            }
        }
    }
    
    private var filteredComplianceIssues: [CoreTypes.ComplianceIssue] {
        if let severity = selectedSeverity {
            return viewModel.complianceIssues.filter { $0.severity == severity }
        }
        return viewModel.complianceIssues
    }
    
    private func severityColor(for severity: CoreTypes.ComplianceSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

struct InsightsTab: View {
    @ObservedObject var viewModel: ClientDashboardViewModel
    let onInsightTap: (CoreTypes.IntelligenceInsight) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("Portfolio Insights")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.isLoadingInsights {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Full Intelligence Panel
            IntelligencePreviewPanel(
                insights: viewModel.intelligenceInsights,
                onInsightTap: onInsightTap,
                onRefresh: {
                    await viewModel.refreshData()
                }
            )
            
            // Insights by category
            if !viewModel.intelligenceInsights.isEmpty {
                InsightsCategoryBreakdown(insights: viewModel.intelligenceInsights)
            }
        }
    }
}

// MARK: - Supporting Card Components

struct PortfolioMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: CoreTypes.TrendDirection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                if let trend = trend {
                    TrendIndicator(trend: trend)
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct PerformanceOverviewCard: View {
    @ObservedObject var viewModel: ClientDashboardViewModel
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Performance Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Metrics grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    PerformanceMetric(
                        title: "Efficiency",
                        value: viewModel.portfolioIntelligence?.completionRate ?? 0,
                        color: .blue
                    )
                    
                    PerformanceMetric(
                        title: "Task Completion",
                        value: viewModel.completionRate,
                        color: .green
                    )
                    
                    PerformanceMetric(
                        title: "Compliance",
                        value: Double(viewModel.complianceScore) / 100.0,
                        color: viewModel.complianceScore >= 90 ? .green : .orange
                    )
                }
            }
            .padding()
        }
    }
}

struct PerformanceMetric: View {
    let title: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(Int(value * 100))%")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 4)
        }
    }
}

struct BuildingCard: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        // ✅ FIXED: Removed nil coalescing operator
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    if let metrics = metrics {
                        Circle()
                            .fill(metricsStatusColor(metrics))
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Metrics
                if let metrics = metrics {
                    HStack(spacing: 20) {
                        MetricLabel(
                            title: "Completion",
                            value: "\(Int(metrics.completionRate * 100))%",
                            color: metricsStatusColor(metrics)
                        )
                        
                        MetricLabel(
                            title: "Overdue",
                            value: "\(metrics.overdueTasks)",
                            color: metrics.overdueTasks > 0 ? .orange : .green
                        )
                        
                        MetricLabel(
                            title: "Workers",
                            value: "\(metrics.activeWorkers)",
                            color: .blue
                        )
                    }
                } else {
                    // Loading state
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading metrics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .francoGlassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func metricsStatusColor(_ metrics: CoreTypes.BuildingMetrics) -> Color {
        if metrics.completionRate >= 0.9 {
            return .green
        } else if metrics.completionRate >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}

struct MetricLabel: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct ComplianceOverviewCard: View {
    let overallScore: Double
    let criticalIssues: Int
    let openIssues: Int
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Compliance Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Overall score gauge
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Overall Score")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(overallScore * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 8)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(scoreColor)
                                .frame(width: geometry.size.width * overallScore, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Issue counts
                HStack(spacing: 20) {
                    IssueCountBadge(
                        title: "Critical",
                        count: criticalIssues,
                        color: .red
                    )
                    
                    IssueCountBadge(
                        title: "Open Issues",
                        count: openIssues,
                        color: .orange
                    )
                }
            }
            .padding()
        }
    }
    
    private var scoreColor: Color {
        if overallScore >= 0.9 {
            return .green
        } else if overallScore >= 0.7 {
            return .orange
        } else {
            return .red
        }
    }
}

struct IssueCountBadge: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct ClientComplianceIssueCard: View {
    let issue: CoreTypes.ComplianceIssue
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Severity indicator
            Circle()
                .fill(severityColor)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            // Issue details
            VStack(alignment: .leading, spacing: 4) {
                Text(issue.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(issue.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    if let buildingId = issue.buildingId {
                        Label(buildingId, systemImage: "building.2")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    
                    if let dueDate = issue.dueDate {
                        Label(dueDate.formatted(.dateTime.day().month()), systemImage: "calendar")
                            .font(.caption2)
                            .foregroundColor(Date() > dueDate ? .red : .secondary)
                    }
                }
            }
            
            Spacer()
            
            // Status badge
            Text(issue.status.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.2))
                )
                .foregroundColor(statusColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
    
    private var statusColor: Color {
        switch issue.status {
        case .open: return .orange
        case .inProgress: return .blue
        case .resolved: return .green
        default: return .gray
        }
    }
}

struct ExecutiveSummaryCard: View {
    let summary: CoreTypes.ExecutiveSummary
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Executive Summary")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(summary.generatedAt, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    SummaryItem(
                        icon: "building.2",
                        title: "Total Buildings",
                        value: "\(summary.totalBuildings)"
                    )
                    
                    SummaryItem(
                        icon: "person.3",
                        title: "Total Workers",
                        value: "\(summary.totalWorkers)"
                    )
                    
                    SummaryItem(
                        icon: "heart.circle",
                        title: "Portfolio Health",
                        value: "\(Int(summary.portfolioHealth * 100))%"
                    )
                    
                    SummaryItem(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Monthly Performance",
                        value: summary.monthlyPerformance
                    )
                }
            }
            .padding()
        }
    }
}

struct SummaryItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct StrategicRecommendationsCard: View {
    let recommendations: [CoreTypes.StrategicRecommendation]
    @State private var expandedRecommendation: String?
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Strategic Recommendations")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    ForEach(recommendations.prefix(3), id: \.id) { recommendation in
                        RecommendationRow(
                            recommendation: recommendation,
                            isExpanded: expandedRecommendation == recommendation.id,
                            onTap: {
                                withAnimation(.spring()) {
                                    expandedRecommendation = expandedRecommendation == recommendation.id ? nil : recommendation.id
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
}

struct RecommendationRow: View {
    let recommendation: CoreTypes.StrategicRecommendation
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    // Priority indicator
                    Circle()
                        .fill(priorityColor)
                        .frame(width: 8, height: 8)
                    
                    // Title
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label(recommendation.timeframe, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        
                        Label(recommendation.estimatedImpact, systemImage: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                .padding(.leading, 16)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .green
        }
    }
}

// ✅ FIXED: Extracted array to avoid complex expression
struct InsightsCategoryBreakdown: View {
    let insights: [CoreTypes.IntelligenceInsight]
    
    var categoryCounts: [CoreTypes.InsightCategory: Int] {
        Dictionary(grouping: insights, by: { $0.type })
            .mapValues { $0.count }
    }
    
    // ✅ FIXED: Created computed property to simplify ForEach
    private var insightCategories: [CoreTypes.InsightCategory] {
        [.efficiency, .maintenance, .compliance, .safety, .cost]
    }
    
    // ✅ FIXED: Extract grid columns to reduce complexity
    private var gridColumns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible())]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            categoryHeader
            
            // ✅ FIXED: Simplified grid by extracting components
            categoryGrid
        }
    }
    
    private var categoryHeader: some View {
        Text("Insights by Category")
            .font(.headline)
            .foregroundColor(.white)
    }
    
    private var categoryGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: 12) {
            ForEach(insightCategories, id: \.self) { category in
                CategoryCard(
                    type: category,
                    count: categoryCounts[category] ?? 0
                )
            }
        }
    }
}

// ✅ FIXED: Using design system colors instead of type.color
struct CategoryCard: View {
    let type: CoreTypes.InsightCategory
    let count: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(FrancoSphereDesign.EnumColors.insightCategory(type))
            }
            
            Spacer()
            
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(FrancoSphereDesign.EnumColors.insightCategory(type).opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrancoSphereDesign.EnumColors.insightCategory(type).opacity(0.1))
        )
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TrendIndicator: View {
    let trend: CoreTypes.TrendDirection
    
    var body: some View {
        Image(systemName: trendIcon)
            .font(.caption2)
            .foregroundColor(trendColor)
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .improving: return "arrow.up.right.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    private var trendColor: Color {
        switch trend {
        case .up, .improving: return .green
        case .down, .declining: return .red
        case .stable: return .orange
        case .unknown: return .gray
        }
    }
}

// MARK: - Detail Sheets

struct InsightDetailSheet: View {
    let insight: CoreTypes.IntelligenceInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(insight.type.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(priorityColor)
                            
                            Spacer()
                            
                            if insight.actionRequired {
                                Label("Action Required", systemImage: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Text(insight.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(insight.description)
                            .font(.body)
                            .foregroundColor(.white)
                        
                        if !insight.affectedBuildings.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Affected Buildings")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                ForEach(insight.affectedBuildings, id: \.self) { buildingId in
                                    HStack {
                                        Image(systemName: "building.2")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("Building \(buildingId)")
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                    }
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.white.opacity(0.05))
                                    )
                                }
                            }
                        }
                        
                        // Actions
                        if insight.actionRequired {
                            VStack(spacing: 12) {
                                Button(action: {
                                    // TODO: Implement action
                                }) {
                                    Label("Take Action", systemImage: "arrow.right.circle.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassButtonStyle(style: .primary))
                                
                                Button(action: {
                                    // TODO: Implement dismiss
                                }) {
                                    Label("Dismiss", systemImage: "xmark.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassButtonStyle(style: .secondary))
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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

struct BuildingDetailSheet: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header using the correct parameters
                    BuildingHeaderGlassOverlay(
                        building: building,
                        clockedInStatus: (false, nil),  // Client doesn't clock in
                        onClockAction: { }  // No-op for client
                    )
                    
                    // ✅ FIXED: Calculate completedTasksCount
                    if let metrics = metrics {
                        BuildingStatsGlassCard(
                            pendingTasksCount: metrics.pendingTasks,
                            completedTasksCount: metrics.totalTasks - metrics.pendingTasks,
                            assignedWorkersCount: metrics.activeWorkers,
                            weatherRisk: .low // Default
                        )
                        .padding()
                    }
                    
                    // Additional details would go here
                }
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview

struct ClientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardView()
            .environmentObject(NewAuthManager.shared)
            .preferredColorScheme(.dark)
    }
}
