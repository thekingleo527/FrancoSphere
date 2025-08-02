//
//  ClientDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ CLIENT-SPECIFIC: Only shows data for client's buildings
//  ✅ PRIVACY: Anonymized worker information
//  ✅ FILTERED: All metrics scoped to client's properties
//  ✅ DARK ELEGANCE: Consistent with admin/worker dashboards
//

import SwiftUI
import MapKit

struct ClientDashboardView: View {
    @StateObject private var viewModel: ClientDashboardViewModel
    @ObservedObject private var contextEngine = ClientContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showAllBuildings = false
    @State private var showReports = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Client-specific states
    @State private var showingCostAnalysis = false
    @State private var showingComplianceReport = false
    @State private var showingServiceHistory = false
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("clientPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // MARK: - Enums
    enum ViewContext {
        case dashboard
        case buildingDetail
        case costAnalysis
        case compliance
        case novaChat
        case reports
    }
    
    enum IntelPanelState: String {
        case hidden = "hidden"
        case minimal = "minimal"
        case collapsed = "collapsed"
        case expanded = "expanded"
        case fullscreen = "fullscreen"
    }
    
    // MARK: - Computed Properties
    private var intelligencePanelState: IntelPanelState {
        switch currentContext {
        case .dashboard:
            return hasImportantUpdates() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .costAnalysis:
            return .hidden
        case .compliance:
            return .minimal
        case .novaChat:
            return .fullscreen
        case .reports:
            return .hidden
        }
    }
    
    private func hasImportantUpdates() -> Bool {
        contextEngine.clientMetrics.complianceScore < 80 ||
        contextEngine.clientMetrics.hasOverdueTasks ||
        !contextEngine.recentActivity.isEmpty
    }
    
    var body: some View {
        // Only show client's buildings on the map
        MapRevealContainer(
            buildings: contextEngine.clientBuildings,
            currentBuildingId: selectedBuilding?.id,
            focusBuildingId: selectedBuilding?.id,
            onBuildingTap: { building in
                selectedBuilding = building
                showBuildingDetail = true
            }
        ) {
            ZStack {
                // Dark Elegance Background
                FrancoSphereDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Client Header (simplified version)
                    HeaderV3B(
                        workerName: contextEngine.clientProfile?.name ?? "Client",
                        nextTaskName: nil, // Clients don't have tasks
                        showClockPill: false, // No clock for clients
                        isNovaProcessing: {
                            switch novaEngine.processingState {
                            case .idle: return false
                            default: return true
                            }
                        }(),
                        onProfileTap: { showProfileView = true },
                        onNovaPress: { showNovaAssistant = true },
                        onNovaLongPress: { handleNovaQuickAction() },
                        onLogoTap: { showMainMenu = true },
                        onClockAction: nil,
                        onVoiceCommand: nil,
                        onARModeToggle: nil,
                        onWearableSync: nil
                    )
                    .zIndex(100)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            // Collapsible Client Hero Status Card
                            CollapsibleClientHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                metrics: contextEngine.clientMetrics,
                                buildings: contextEngine.clientBuildings,
                                recentActivity: contextEngine.recentActivity,
                                onBuildingsTap: { showAllBuildings = true },
                                onComplianceTap: { showingComplianceReport = true },
                                onCostTap: { showingCostAnalysis = true },
                                onReportsTap: { showReports = true },
                                onRefreshTap: { Task { await viewModel.refreshData() } }
                            )
                            .zIndex(50)
                            
                            // Quick Actions Section
                            clientQuickActions
                            
                            // Recent Updates (anonymized)
                            if !contextEngine.recentActivity.isEmpty {
                                recentUpdatesSection
                            }
                            
                            // Building Performance Summary
                            if contextEngine.clientBuildings.count > 1 {
                                buildingPerformanceSection
                            }
                            
                            // Spacer for bottom intelligence bar
                            Spacer(minLength: intelligencePanelState == .hidden ? 20 : 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                        refreshID = UUID()
                    }
                    
                    // Intelligence Preview Panel (Client-focused)
                    if intelligencePanelState != .hidden && (!novaEngine.insights.isEmpty || hasIntelligenceToShow()) {
                        IntelligencePreviewPanel(
                            insights: getClientInsights(),
                            displayMode: intelligencePanelState == .minimal ? .compact : .compact,
                            onNavigate: { target in
                                handleIntelligenceNavigation(target)
                            },
                            contextEngine: contextEngine
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(FrancoSphereDesign.Animations.spring, value: intelligencePanelState)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileView) {
            ClientProfileView()
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView(clientMode: true) // Limited to client queries
                .presentationDetents([.large])
                .onAppear { currentContext = .novaChat }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                ClientBuildingDetailView(building: building)
                    .onAppear { currentContext = .buildingDetail }
                    .onDisappear {
                        currentContext = .dashboard
                        Task { await contextEngine.refreshContext() }
                    }
            }
        }
        .sheet(isPresented: $showAllBuildings) {
            NavigationView {
                ClientBuildingsListView(
                    buildings: contextEngine.clientBuildings,
                    onSelectBuilding: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                        showAllBuildings = false
                    }
                )
                .navigationTitle("Your Properties")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAllBuildings = false
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
                .background(FrancoSphereDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingComplianceReport) {
            ClientComplianceView(
                buildings: contextEngine.clientBuildings,
                complianceData: contextEngine.clientComplianceData
            )
            .onAppear { currentContext = .compliance }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingCostAnalysis) {
            ClientCostAnalysisView(
                buildings: contextEngine.clientBuildings,
                costData: contextEngine.clientCostData
            )
            .onAppear { currentContext = .costAnalysis }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showReports) {
            ClientReportsView()
                .presentationDetents([.medium, .large])
                .onAppear { currentContext = .reports }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showMainMenu) {
            ClientMainMenuView()
                .presentationDetents([.medium, .large])
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var clientQuickActions: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            QuickActionCard(
                title: "Compliance",
                value: "\(Int(contextEngine.clientMetrics.complianceScore))%",
                icon: "checkmark.shield.fill",
                color: complianceScoreColor,
                showBadge: contextEngine.clientMetrics.hasComplianceIssues,
                badgeCount: contextEngine.clientMetrics.complianceIssueCount,
                action: { showingComplianceReport = true }
            )
            
            QuickActionCard(
                title: "Service Level",
                value: "\(Int(contextEngine.clientMetrics.serviceLevel * 100))%",
                icon: "star.fill",
                color: FrancoSphereDesign.DashboardColors.tertiaryAction,
                action: { showingServiceHistory = true }
            )
            
            QuickActionCard(
                title: "This Month",
                value: formatCurrency(contextEngine.clientMetrics.monthlySpend),
                icon: "dollarsign.circle",
                color: FrancoSphereDesign.DashboardColors.info,
                action: { showingCostAnalysis = true }
            )
            
            QuickActionCard(
                title: "Reports",
                value: "View",
                icon: "doc.text",
                color: FrancoSphereDesign.DashboardColors.secondaryAction,
                action: { showReports = true }
            )
        }
    }
    
    // MARK: - Recent Updates Section (Anonymized)
    
    private var recentUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Updates", systemImage: "clock")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                ForEach(contextEngine.recentActivity.prefix(5)) { activity in
                    ClientActivityRow(activity: activity)
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Building Performance Section
    
    private var buildingPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Performance")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            ForEach(contextEngine.clientBuildings.prefix(3)) { building in
                BuildingPerformanceRow(
                    building: building,
                    metrics: contextEngine.buildingMetrics[building.id] ?? CoreTypes.BuildingMetrics.empty,
                    onTap: {
                        selectedBuilding = building
                        showBuildingDetail = true
                    }
                )
            }
            
            if contextEngine.clientBuildings.count > 3 {
                Button(action: { showAllBuildings = true }) {
                    Text("View All Properties")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Intelligence Methods (Client-specific)
    
    private func getClientInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.insights.filter { insight in
            // Filter insights to only client's buildings
            insight.affectedBuildings.isEmpty ||
            insight.affectedBuildings.contains { buildingId in
                contextEngine.clientBuildings.contains { $0.id == buildingId }
            }
        }
        
        // Add client-specific insights
        if contextEngine.clientMetrics.complianceScore < 80 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Compliance needs attention",
                description: "Your properties have compliance scores below target",
                type: .compliance,
                priority: .high,
                actionRequired: true,
                recommendedAction: "View Compliance Report",
                affectedBuildings: contextEngine.clientBuildings.map { $0.id }
            ))
        }
        
        // Cost optimization insights
        if contextEngine.clientMetrics.monthlySpend > contextEngine.clientMetrics.monthlyBudget * 1.1 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Monthly spending exceeds budget",
                description: "Current spending is 10% over your monthly budget",
                type: .cost,
                priority: .medium,
                actionRequired: false,
                recommendedAction: "Review Cost Analysis"
            ))
        }
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        switch target {
        case .buildings(_):
            showAllBuildings = true
            
        case .buildingDetail(let id):
            if let building = contextEngine.clientBuildings.first(where: { $0.id == id }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
            
        case .compliance:
            showingComplianceReport = true
            
        case .fullInsights:
            showNovaAssistant = true
            
        case .profile:
            showProfileView = true
            
        case .settings:
            showMainMenu = true
            
        default:
            // Handle other navigation targets
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleNovaQuickAction() {
        if hasImportantUpdates() {
            showNovaAssistant = true
        } else {
            showNovaAssistant = true
        }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
    
    private var complianceScoreColor: Color {
        let score = contextEngine.clientMetrics.complianceScore
        if score >= 90 { return FrancoSphereDesign.DashboardColors.success }
        if score >= 80 { return FrancoSphereDesign.DashboardColors.info }
        if score >= 70 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.critical
    }
    
    private func hasIntelligenceToShow() -> Bool {
        return contextEngine.clientBuildings.count > 0 ||
               contextEngine.clientMetrics.hasComplianceIssues ||
               contextEngine.clientMetrics.hasOverdueTasks
    }
}

// MARK: - Collapsible Client Hero Wrapper

struct CollapsibleClientHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let metrics: ClientMetrics
    let buildings: [CoreTypes.NamedCoordinate]
    let recentActivity: [ClientActivity]
    
    let onBuildingsTap: () -> Void
    let onComplianceTap: () -> Void
    let onCostTap: () -> Void
    let onReportsTap: () -> Void
    let onRefreshTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalClientHeroCard(
                    propertyCount: buildings.count,
                    complianceScore: metrics.complianceScore,
                    serviceLevel: metrics.serviceLevel,
                    hasAlerts: metrics.hasComplianceIssues || metrics.hasOverdueTasks,
                    onExpand: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
                
            } else {
                // Full ClientHeroStatusCard with collapse button
                ZStack(alignment: .topTrailing) {
                    ClientHeroStatusCard(
                        metrics: metrics,
                        buildings: buildings,
                        recentActivity: recentActivity,
                        onBuildingsTap: onBuildingsTap,
                        onComplianceTap: onComplianceTap,
                        onCostTap: onCostTap,
                        onReportsTap: onReportsTap,
                        onRefreshTap: onRefreshTap
                    )
                    
                    // Collapse button overlay
                    Button(action: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = true
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                            .padding(8)
                            .background(Circle().fill(FrancoSphereDesign.DashboardColors.glassOverlay))
                    }
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - Client Hero Status Card

struct ClientHeroStatusCard: View {
    let metrics: ClientMetrics
    let buildings: [CoreTypes.NamedCoordinate]
    let recentActivity: [ClientActivity]
    
    let onBuildingsTap: () -> Void
    let onComplianceTap: () -> Void
    let onCostTap: () -> Void
    let onReportsTap: () -> Void
    let onRefreshTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Property Overview")
                        .francoTypography(FrancoSphereDesign.Typography.dashboardTitle)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text("\(buildings.count) properties managed by FrancoSphere")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                
                Spacer()
            }
            
            // Metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    value: "\(buildings.count)",
                    label: "Properties",
                    icon: "building.2.fill",
                    color: FrancoSphereDesign.DashboardColors.info,
                    onTap: onBuildingsTap
                )
                
                MetricCard(
                    value: "\(Int(metrics.complianceScore))%",
                    label: "Compliance",
                    subtitle: metrics.hasComplianceIssues ? "Issues detected" : "Good standing",
                    color: complianceColor,
                    icon: "checkmark.shield.fill",
                    onTap: onComplianceTap
                )
                
                MetricCard(
                    value: "\(Int(metrics.serviceLevel * 100))%",
                    label: "Service Level",
                    icon: "star.fill",
                    color: FrancoSphereDesign.DashboardColors.tertiaryAction,
                    onTap: onReportsTap
                )
                
                MetricCard(
                    value: formatCurrency(metrics.monthlySpend),
                    label: "Monthly Spend",
                    subtitle: spendingStatus,
                    color: spendingColor,
                    icon: "dollarsign.circle",
                    onTap: onCostTap
                )
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var complianceColor: Color {
        if metrics.complianceScore >= 90 { return FrancoSphereDesign.DashboardColors.success }
        if metrics.complianceScore >= 80 { return FrancoSphereDesign.DashboardColors.info }
        if metrics.complianceScore >= 70 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.critical
    }
    
    private var spendingStatus: String {
        let percentOfBudget = metrics.monthlySpend / metrics.monthlyBudget
        if percentOfBudget > 1.1 { return "Over budget" }
        if percentOfBudget > 0.9 { return "Near budget" }
        return "On track"
    }
    
    private var spendingColor: Color {
        let percentOfBudget = metrics.monthlySpend / metrics.monthlyBudget
        if percentOfBudget > 1.1 { return FrancoSphereDesign.DashboardColors.critical }
        if percentOfBudget > 0.9 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.success
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// MARK: - Supporting Types

struct ClientMetrics {
    let complianceScore: Double
    let serviceLevel: Double
    let monthlySpend: Double
    let monthlyBudget: Double
    let hasComplianceIssues: Bool
    let complianceIssueCount: Int
    let hasOverdueTasks: Bool
}

struct ClientActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let buildingName: String?
    let timestamp: Date
    
    enum ActivityType {
        case taskCompleted
        case complianceUpdate
        case serviceComplete
        case reportAvailable
    }
}

// MARK: - Client Context Engine

class ClientContextEngine: ObservableObject {
    static let shared = ClientContextEngine()
    
    @Published var clientProfile: ClientProfile?
    @Published var clientBuildings: [CoreTypes.NamedCoordinate] = []
    @Published var clientMetrics = ClientMetrics(
        complianceScore: 85,
        serviceLevel: 0.92,
        monthlySpend: 15000,
        monthlyBudget: 18000,
        hasComplianceIssues: false,
        complianceIssueCount: 0,
        hasOverdueTasks: false
    )
    @Published var recentActivity: [ClientActivity] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var clientComplianceData: [String: ComplianceData] = [:]
    @Published var clientCostData: [String: CostData] = [:]
    
    func refreshContext() async {
        // Refresh client-specific data
    }
}

struct ClientProfile {
    let id: String
    let name: String
    let email: String
    let buildingIds: [String]
}

struct ComplianceData {
    let buildingId: String
    let score: Double
    let violations: [String]
    let lastInspection: Date
}

struct CostData {
    let buildingId: String
    let monthlyAverage: Double
    let currentMonth: Double
    let trend: CoreTypes.TrendDirection
}

// MARK: - Additional Components

struct MinimalClientHeroCard: View {
    let propertyCount: Int
    let complianceScore: Double
    let serviceLevel: Double
    let hasAlerts: Bool
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                // Property count
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.caption)
                    Text("\(propertyCount)")
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Text("•")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                // Compliance
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield")
                        .font(.caption)
                    Text("\(Int(complianceScore))%")
                }
                .foregroundColor(complianceColor)
                
                Text("•")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                
                // Service level
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .font(.caption)
                    Text("\(Int(serviceLevel * 100))%")
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                if hasAlerts {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                }
                
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .francoDarkCardBackground(cornerRadius: 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        if hasAlerts || complianceScore < 70 {
            return FrancoSphereDesign.DashboardColors.warning
        }
        return FrancoSphereDesign.DashboardColors.success
    }
    
    private var complianceColor: Color {
        if complianceScore >= 90 { return FrancoSphereDesign.DashboardColors.success }
        if complianceScore >= 80 { return FrancoSphereDesign.DashboardColors.info }
        if complianceScore >= 70 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.critical
    }
}

struct ClientActivityRow: View {
    let activity: ClientActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activityColor)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                if let buildingName = activity.buildingName {
                    Text(buildingName)
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
            }
            
            Spacer()
            
            Text(activity.timestamp, style: .relative)
                .francoTypography(FrancoSphereDesign.Typography.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
        .padding(.vertical, 4)
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .taskCompleted: return FrancoSphereDesign.DashboardColors.success
        case .complianceUpdate: return FrancoSphereDesign.DashboardColors.info
        case .serviceComplete: return FrancoSphereDesign.DashboardColors.tertiaryAction
        case .reportAvailable: return FrancoSphereDesign.DashboardColors.secondaryAction
        }
    }
}

struct BuildingPerformanceRow: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text("\(metrics.totalTasks) tasks • \(Int(metrics.completionRate * 100))% complete")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ClientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardView(viewModel: ClientDashboardViewModel())
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
