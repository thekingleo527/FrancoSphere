//
//  ClientDashboardContainerView.swift
//  FrancoSphere v6.0
//
//  ✅ USES ONLY EXISTING VIEWMODELS AND SERVICES
//  ✅ NO INVENTED DEPENDENCIES
//  ✅ WORKS WITH ACTUAL CORETYPES
//  ✅ INTEGRATES WITH CLIENTCONTEXTENGINE
//

import SwiftUI
import Combine

struct ClientDashboardContainerView: View {
    // MARK: - Existing ViewModels Only
    @StateObject private var viewModel = ClientDashboardViewModel()
    @StateObject private var contextEngine = ClientContextEngine.shared
    
    // MARK: - Environment Objects
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State Management
    @State private var selectedBuildingId: String?
    @State private var showingBuildingSelector = false
    @State private var showingProfile = false
    @State private var showingComplianceDetail = false
    @State private var selectedComplianceIssue: CoreTypes.ComplianceIssue?
    @State private var refreshID = UUID()
    @State private var selectedTimeRange: TimeRange = .today
    
    // MARK: - App Storage
    @AppStorage("clientShowCostData") private var showCostData = true
    @AppStorage("clientDashboardLayout") private var dashboardLayout = "cards"
    
    // MARK: - Enums
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case quarter = "Quarter"
        
        var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
    }
    
    // MARK: - Computed Properties
    private var currentBuilding: CoreTypes.NamedCoordinate? {
        if let id = selectedBuildingId {
            return viewModel.buildingsList.first { $0.id == id }
        }
        return viewModel.buildingsList.first
    }
    
    private var currentBuildingMetrics: CoreTypes.BuildingMetrics? {
        guard let buildingId = selectedBuildingId ?? viewModel.buildingsList.first?.id else { return nil }
        return viewModel.buildingMetrics[buildingId]
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Header using actual data
                    ClientHeaderView(
                        clientName: contextEngine.clientProfile?.name ?? "Client",
                        selectedBuilding: currentBuilding,
                        isRefreshing: viewModel.isRefreshing,
                        onBuildingTap: { showingBuildingSelector = true },
                        onProfileTap: { showingProfile = true },
                        onRefresh: { Task { await viewModel.refreshData() } }
                    )
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Portfolio Intelligence Card (using actual data)
                            if let intelligence = viewModel.portfolioIntelligence {
                                PortfolioIntelligenceCard(intelligence: intelligence)
                                    .padding(.horizontal)
                            }
                            
                            // Metrics Overview (using actual properties)
                            MetricsOverviewGrid(
                                totalBuildings: viewModel.totalBuildings,
                                activeWorkers: viewModel.activeWorkers,
                                completionRate: viewModel.completionRate,
                                complianceScore: viewModel.complianceScore,
                                criticalIssues: viewModel.criticalIssues
                            )
                            .padding(.horizontal)
                            
                            // Building Performance (using actual buildingMetrics)
                            if !viewModel.buildingMetrics.isEmpty {
                                BuildingPerformanceSection(
                                    buildings: viewModel.buildingsList,
                                    metrics: viewModel.buildingMetrics,
                                    selectedBuildingId: $selectedBuildingId
                                )
                                .padding(.horizontal)
                            }
                            
                            // Real-time Metrics (using actual contextEngine data)
                            RealtimeMetricsCard(
                                routineMetrics: viewModel.realtimeRoutineMetrics,
                                workerStatus: viewModel.activeWorkerStatus,
                                monthlyMetrics: viewModel.monthlyMetrics
                            )
                            .padding(.horizontal)
                            
                            // Compliance Issues (using actual data)
                            if !viewModel.complianceIssues.isEmpty {
                                ComplianceIssuesSection(
                                    issues: viewModel.complianceIssues,
                                    onIssueTap: { issue in
                                        selectedComplianceIssue = issue
                                        showingComplianceDetail = true
                                    }
                                )
                                .padding(.horizontal)
                            }
                            
                            // Intelligence Insights (using actual data)
                            if !viewModel.intelligenceInsights.isEmpty {
                                IntelligenceInsightsSection(
                                    insights: viewModel.intelligenceInsights
                                )
                                .padding(.horizontal)
                            }
                            
                            // Strategic Recommendations (using actual data)
                            if !viewModel.strategicRecommendations.isEmpty {
                                StrategicRecommendationsSection(
                                    recommendations: viewModel.strategicRecommendations
                                )
                                .padding(.horizontal)
                            }
                            
                            // Bottom padding
                            Spacer(minLength: 100)
                        }
                        .padding(.top)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                    }
                }
            }
            .navigationBarHidden(true)
            .id(refreshID)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await viewModel.loadPortfolioIntelligence()
            await contextEngine.refreshContext()
        }
        .sheet(isPresented: $showingBuildingSelector) {
            BuildingSelectionSheet(
                buildings: viewModel.buildingsList,
                selectedBuildingId: $selectedBuildingId
            )
        }
        .sheet(isPresented: $showingProfile) {
            // Use existing ProfileView or create simple one
            ClientProfileSheet(profile: contextEngine.clientProfile)
        }
        .sheet(isPresented: $showingComplianceDetail) {
            if let issue = selectedComplianceIssue {
                ComplianceIssueDetailSheet(issue: issue)
            }
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "0D1117"),
                Color(hex: "161B22")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Client Header View (Simplified)
struct ClientHeaderView: View {
    let clientName: String
    let selectedBuilding: CoreTypes.NamedCoordinate?
    let isRefreshing: Bool
    let onBuildingTap: () -> Void
    let onProfileTap: () -> Void
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Building Selector
                Button(action: onBuildingTap) {
                    HStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedBuilding?.name ?? "All Buildings")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(clientName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Actions
                HStack(spacing: 16) {
                    // Refresh
                    Button(action: {
                        Task { await onRefresh() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(
                                isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default,
                                value: isRefreshing
                            )
                    }
                    
                    // Profile
                    Button(action: onProfileTap) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
        .background(Color(hex: "161B22"))
    }
}

// MARK: - Portfolio Intelligence Card
struct PortfolioIntelligenceCard: View {
    let intelligence: CoreTypes.ClientPortfolioIntelligence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Overview")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(intelligence.totalProperties) Properties")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Overall Score
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: intelligence.serviceLevel)
                        .stroke(
                            LinearGradient(
                                colors: [Color.green, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(Int(intelligence.serviceLevel * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            
            // Trend indicator
            HStack(spacing: 12) {
                TrendIndicator(
                    title: "Trend",
                    value: intelligence.monthlyTrend.rawValue,
                    isPositive: intelligence.monthlyTrend == .improving
                )
                
                if intelligence.showCostData {
                    TrendIndicator(
                        title: "Monthly Spend",
                        value: "$\(Int(intelligence.monthlySpend))",
                        isPositive: intelligence.monthlySpend <= intelligence.monthlyBudget
                    )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Metrics Overview Grid
struct MetricsOverviewGrid: View {
    let totalBuildings: Int
    let activeWorkers: Int
    let completionRate: Double
    let complianceScore: Int
    let criticalIssues: Int
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(
                icon: "building.2",
                title: "Buildings",
                value: "\(totalBuildings)",
                color: .blue
            )
            
            MetricCard(
                icon: "person.3.fill",
                title: "Active Workers",
                value: "\(activeWorkers)",
                color: .green
            )
            
            MetricCard(
                icon: "checkmark.circle.fill",
                title: "Completion",
                value: "\(Int(completionRate * 100))%",
                color: .cyan
            )
            
            MetricCard(
                icon: "shield.fill",
                title: "Compliance",
                value: "\(complianceScore)%",
                color: complianceScore >= 90 ? .green : .orange
            )
            
            if criticalIssues > 0 {
                MetricCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Critical Issues",
                    value: "\(criticalIssues)",
                    color: .red
                )
            }
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Building Performance Section
struct BuildingPerformanceSection: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let metrics: [String: CoreTypes.BuildingMetrics]
    @Binding var selectedBuildingId: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Performance")
                .font(.headline)
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(buildings) { building in
                        BuildingPerformanceCard(
                            building: building,
                            metrics: metrics[building.id],
                            isSelected: selectedBuildingId == building.id,
                            onTap: { selectedBuildingId = building.id }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Building Performance Card
struct BuildingPerformanceCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let metrics = metrics {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                        
                        Text("\(Int(metrics.completionRate * 100))%")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    
                    if metrics.overdueTasks > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            
                            Text("\(metrics.overdueTasks) overdue")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                } else {
                    Text("No data")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 140)
            .padding()
            .background(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.03))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Realtime Metrics Card
struct RealtimeMetricsCard: View {
    let routineMetrics: CoreTypes.RealtimeRoutineMetrics
    let workerStatus: CoreTypes.ActiveWorkerStatus
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Real-time Status")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Workers")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(workerStatus.totalActive)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Behind Schedule")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(routineMetrics.behindScheduleCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(routineMetrics.behindScheduleCount > 0 ? .orange : .green)
                }
                
                if monthlyMetrics.monthlyBudget > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget Used")
                        .font(.caption)
                        .foregroundColor(.gray)
                        Text("\(Int(monthlyMetrics.currentSpend / monthlyMetrics.monthlyBudget * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Compliance Issues Section
struct ComplianceIssuesSection: View {
    let issues: [CoreTypes.ComplianceIssue]
    let onIssueTap: (CoreTypes.ComplianceIssue) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Compliance Issues")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(issues.count) issues")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            VStack(spacing: 8) {
                ForEach(issues.prefix(5)) { issue in
                    ComplianceIssueRow(issue: issue, onTap: {
                        onIssueTap(issue)
                    })
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Compliance Issue Row
struct ComplianceIssueRow: View {
    let issue: CoreTypes.ComplianceIssue
    let onTap: () -> Void
    
    var severityColor: Color {
        switch issue.severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .gray
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(severityColor)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(issue.title)
                        .font(.caption)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if let buildingName = issue.buildingName {
                        Text(buildingName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Text(issue.severity.rawValue)
                    .font(.caption2)
                    .foregroundColor(severityColor)
            }
        }
    }
}

// MARK: - Intelligence Insights Section
struct IntelligenceInsightsSection: View {
    let insights: [CoreTypes.IntelligenceInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intelligence Insights")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(insights.prefix(3)) { insight in
                    IntelligenceInsightRow(insight: insight)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Intelligence Insight Row
struct IntelligenceInsightRow: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var priorityColor: Color {
        switch insight.priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 14))
                .foregroundColor(priorityColor)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(insight.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let impact = insight.estimatedImpact {
                    Text(impact)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Strategic Recommendations Section
struct StrategicRecommendationsSection: View {
    let recommendations: [CoreTypes.StrategicRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Strategic Recommendations")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                ForEach(recommendations.prefix(3)) { recommendation in
                    RecommendationRow(recommendation: recommendation)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Recommendation Row
struct RecommendationRow: View {
    let recommendation: CoreTypes.StrategicRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(recommendation.description)
                .font(.caption2)
                .foregroundColor(.gray)
                .lineLimit(2)
            
            HStack {
                Label(recommendation.timeframe, systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(recommendation.priority.rawValue)
                    .font(.caption2)
                    .foregroundColor(recommendation.priority == .critical ? .red : .orange)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Views

struct TrendIndicator: View {
    let title: String
    let value: String
    let isPositive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 12))
                .foregroundColor(isPositive ? .green : .red)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Sheet Views

struct BuildingSelectionSheet: View {
    let buildings: [CoreTypes.NamedCoordinate]
    @Binding var selectedBuildingId: String?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // All Buildings option
                Button(action: {
                    selectedBuildingId = nil
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "building.2")
                        Text("All Buildings")
                        Spacer()
                        if selectedBuildingId == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Individual buildings
                ForEach(buildings) { building in
                    Button(action: {
                        selectedBuildingId = building.id
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "building")
                            VStack(alignment: .leading) {
                                Text(building.name)
                                Text(building.address)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedBuildingId == building.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Building")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct ClientProfileSheet: View {
    let profile: ClientProfile?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let profile = profile {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text(profile.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(profile.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    if let company = profile.company {
                        Text(company)
                            .font(.subheadline)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct ComplianceIssueDetailSheet: View {
    let issue: CoreTypes.ComplianceIssue
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Severity Badge
                HStack {
                    Text(issue.severity.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(severityColor(issue.severity))
                        .cornerRadius(12)
                    
                    Spacer()
                    
                    Text(issue.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 8) {
                    Text(issue.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(issue.description)
                        .font(.body)
                        .foregroundColor(.gray)
                }
                
                // Building Info
                if let buildingName = issue.buildingName {
                    HStack {
                        Image(systemName: "building.2")
                        Text(buildingName)
                    }
                    .foregroundColor(.blue)
                }
                
                // Type
                HStack {
                    Text("Type:")
                        .fontWeight(.medium)
                    Text(issue.type.rawValue)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Compliance Issue")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    func severityColor(_ severity: CoreTypes.ComplianceSeverity) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .gray
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#if DEBUG
struct ClientDashboardContainerView_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardContainerView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
