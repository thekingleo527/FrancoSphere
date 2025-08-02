//
//  ClientDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ REDESIGNED: Mirrors Worker/Admin dashboard structure
//  ✅ UNIFIED: Same MapRevealContainer + HeaderV3B pattern
//  ✅ DYNAMIC: Real-time hero card with live portfolio metrics
//  ✅ INTELLIGENT: Contextual AI insights at bottom
//  ✅ STREAMLINED: No tabs, single-scroll prioritized content
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct ClientDashboardView: View {
    @StateObject private var viewModel = ClientDashboardViewModel()
    @ObservedObject private var contextEngine = ClientContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables (Mirroring Worker/Admin)
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showAllBuildings = false
    @State private var showComplianceDetails = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    @State private var selectedComplianceIssue: CoreTypes.ComplianceIssue?
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("clientPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
    // MARK: - Enums (Same as Worker/Admin)
    enum ViewContext {
        case dashboard
        case buildingDetail
        case complianceReview
        case portfolioAnalysis
        case novaChat
        case emergency
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
            return hasUrgentMatters() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .complianceReview:
            return .expanded
        case .portfolioAnalysis:
            return .expanded
        case .novaChat:
            return .fullscreen
        case .emergency:
            return .expanded
        }
    }
    
    private func hasUrgentMatters() -> Bool {
        novaEngine.insights.contains { $0.priority == .critical } ||
        contextEngine.portfolioHealth.criticalIssues > 0 ||
        contextEngine.realtimeAlerts.contains { $0.severity == .critical }
    }
    
    var body: some View {
        // EXACT SAME STRUCTURE AS WORKER/ADMIN
        MapRevealContainer(
            buildings: contextEngine.clientBuildings,
            currentBuildingId: selectedBuilding?.id,
            focusBuildingId: selectedBuilding?.id,
            showBuildingPerformance: true, // Client sees performance overlay
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
                    // Updated HeaderV3B - Client variant (5-7%)
                    HeaderV3B(
                        workerName: authManager.currentUser?.name ?? "Client",
                        nextTaskName: getMostUrgentItem()?.title,
                        showClockPill: false, // Clients don't clock in
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
                        onClockAction: nil, // Not applicable for client
                        onVoiceCommand: voiceCommandEnabled ? handleVoiceCommand : nil,
                        onARModeToggle: arModeEnabled ? handleARMode : nil,
                        onWearableSync: nil
                    )
                    .zIndex(100)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            // Collapsible Client Hero Status Card - DYNAMIC & REAL-TIME
                            CollapsibleClientHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                portfolioHealth: contextEngine.portfolioHealth,
                                realtimeMetrics: contextEngine.realtimeMetrics,
                                activeWorkers: contextEngine.activeWorkerStatus,
                                complianceStatus: contextEngine.complianceOverview,
                                criticalAlerts: contextEngine.realtimeAlerts,
                                buildingPerformance: contextEngine.buildingPerformanceMap,
                                syncStatus: getSyncStatus(),
                                onPortfolioTap: { currentContext = .portfolioAnalysis },
                                onComplianceTap: { showComplianceDetails = true },
                                onWorkersTap: { /* Show worker overview */ },
                                onAlertsTap: { showCriticalAlerts() },
                                onSyncTap: { Task { await viewModel.forceRefresh() } }
                            )
                            .zIndex(50)
                            
                            // Priority Content Cards (replacing tabs)
                            VStack(spacing: 16) {
                                // Executive Intelligence Summary
                                if let executiveSummary = contextEngine.executiveIntelligence {
                                    ExecutiveIntelligenceCard(
                                        summary: executiveSummary,
                                        onDetailTap: { showNovaAssistant = true }
                                    )
                                }
                                
                                // Critical Compliance Issues
                                if !contextEngine.criticalComplianceIssues.isEmpty {
                                    CriticalComplianceCard(
                                        issues: contextEngine.criticalComplianceIssues,
                                        onIssueTap: { issue in
                                            selectedComplianceIssue = issue
                                            showComplianceDetails = true
                                        }
                                    )
                                }
                                
                                // Building Performance Grid
                                BuildingPerformanceGrid(
                                    buildings: contextEngine.topPerformanceBuildings,
                                    onBuildingTap: { building in
                                        selectedBuilding = building
                                        showBuildingDetail = true
                                    }
                                )
                                
                                // Worker Productivity Insights
                                if !contextEngine.workerProductivityInsights.isEmpty {
                                    WorkerProductivityCard(
                                        insights: contextEngine.workerProductivityInsights
                                    )
                                }
                            }
                            
                            // Spacer for bottom intelligence bar
                            Spacer(minLength: intelligencePanelState == .hidden ? 20 : 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.forceRefresh()
                        await contextEngine.refreshAllData()
                        refreshID = UUID()
                    }
                    
                    // Intelligence Preview Panel (SAME AS WORKER/ADMIN)
                    if intelligencePanelState != .hidden && (!novaEngine.insights.isEmpty || hasIntelligenceToShow()) {
                        IntelligencePreviewPanel(
                            insights: getCurrentInsights(),
                            displayMode: intelligencePanelState == .minimal ? .compact : .expanded,
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
            NovaInteractionView()
                .presentationDetents([.large])
                .onAppear { currentContext = .novaChat }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(building: building)
                    .onAppear { currentContext = .buildingDetail }
                    .onDisappear {
                        currentContext = .dashboard
                        Task { await contextEngine.refreshAllData() }
                    }
            }
        }
        .sheet(isPresented: $showAllBuildings) {
            NavigationView {
                ClientBuildingsListView(
                    buildings: contextEngine.clientBuildings,
                    performanceMap: contextEngine.buildingPerformanceMap,
                    onSelectBuilding: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                        showAllBuildings = false
                    }
                )
                .navigationTitle("Portfolio Buildings")
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
        .sheet(isPresented: $showComplianceDetails) {
            NavigationView {
                ClientComplianceDetailView(
                    complianceOverview: contextEngine.complianceOverview,
                    issues: contextEngine.allComplianceIssues,
                    selectedIssue: selectedComplianceIssue
                )
                .navigationTitle("Compliance Details")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showComplianceDetails = false
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
                .background(FrancoSphereDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
            .onAppear { currentContext = .complianceReview }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showMainMenu) {
            ClientMainMenuView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
            startRealtimeUpdates()
        }
        .onReceive(dashboardSync.$lastUpdate) { _ in
            // React to real-time updates
            Task {
                await contextEngine.refreshAllData()
            }
        }
    }
    
    // MARK: - Real-time Update Management
    
    private func startRealtimeUpdates() {
        // Connect to real-time data streams
        contextEngine.startRealtimeMonitoring()
        
        // Subscribe to worker activity updates
        contextEngine.subscribeToWorkerUpdates()
        
        // Monitor compliance changes
        contextEngine.monitorComplianceChanges()
    }
    
    // MARK: - Intelligence Methods (Client-specific)
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.insights
        
        // Add client-specific real-time insights
        
        // Compliance insights
        if contextEngine.complianceOverview.criticalViolations > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "\(contextEngine.complianceOverview.criticalViolations) critical compliance violations",
                description: "Immediate action required to avoid penalties",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: contextEngine.buildingsWithViolations
            ))
        }
        
        // Performance insights
        let underperformingBuildings = contextEngine.buildingPerformanceMap.filter { $0.value < 0.7 }
        if underperformingBuildings.count > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "\(underperformingBuildings.count) buildings below 70% performance",
                description: "Review staffing and task allocation for these properties",
                type: .efficiency,
                priority: .high,
                actionRequired: true,
                affectedBuildings: Array(underperformingBuildings.keys)
            ))
        }
        
        // Worker productivity insights
        if contextEngine.activeWorkerStatus.utilizationRate < 0.6 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Low worker utilization at \(Int(contextEngine.activeWorkerStatus.utilizationRate * 100))%",
                description: "Consider optimizing task distribution or adjusting workforce",
                type: .operations,
                priority: .medium,
                actionRequired: false
            ))
        }
        
        // Cost optimization insights
        if let costSavingOpportunity = contextEngine.identifyCostSavings() {
            insights.append(costSavingOpportunity)
        }
        
        return insights
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        switch target {
        case .buildings(_):
            showAllBuildings = true
            
        case .compliance(_):
            showComplianceDetails = true
            
        case .buildingDetail(let id):
            if let building = contextEngine.clientBuildings.first(where: { $0.id == id }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
            
        case .fullInsights:
            showNovaAssistant = true
            
        case .allBuildings:
            showAllBuildings = true
            
        default:
            // Handle other navigation targets
            break
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleNovaQuickAction() {
        if hasUrgentMatters() {
            // Focus on urgent matters
            currentContext = .emergency
        }
        showNovaAssistant = true
    }
    
    private func showCriticalAlerts() {
        currentContext = .emergency
        showNovaAssistant = true
    }
    
    private func handleVoiceCommand() {
        print("Client voice command activated")
    }
    
    private func handleARMode() {
        print("Client AR mode toggled - show portfolio in AR")
    }
    
    private func checkFeatureFlags() {
        #if DEBUG
        voiceCommandEnabled = false
        arModeEnabled = false
        #else
        voiceCommandEnabled = UserDefaults.standard.bool(forKey: "feature.voice.enabled")
        arModeEnabled = UserDefaults.standard.bool(forKey: "feature.ar.enabled")
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func getMostUrgentItem() -> (title: String, urgency: CoreTypes.AIPriority)? {
        // Check for critical compliance
        if contextEngine.complianceOverview.criticalViolations > 0 {
            return ("Critical compliance violations", .critical)
        }
        
        // Check for critical alerts
        if let criticalAlert = contextEngine.realtimeAlerts.first(where: { $0.severity == .critical }) {
            return (criticalAlert.title, .critical)
        }
        
        // Check for critical insights
        if let criticalInsight = novaEngine.insights.first(where: { $0.priority == .critical }) {
            return (criticalInsight.title, criticalInsight.priority)
        }
        
        return nil
    }
    
    private func getSyncStatus() -> ClientHeroStatusCard.SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced: return .synced
        case .syncing: return .syncing(progress: contextEngine.syncProgress)
        case .failed: return .error("Sync failed")
        case .offline: return .offline
        }
    }
    
    private func hasIntelligenceToShow() -> Bool {
        return !contextEngine.workerProductivityInsights.isEmpty ||
               contextEngine.complianceOverview.openIssues > 0 ||
               hasCostSavingOpportunities()
    }
    
    private func hasCostSavingOpportunities() -> Bool {
        // Check if there are any cost optimization insights
        return contextEngine.estimatedMonthlySavings > 1000
    }
}

// MARK: - CollapsibleClientHeroWrapper (Dynamic Real-time)

struct CollapsibleClientHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let portfolioHealth: CoreTypes.PortfolioHealth
    let realtimeMetrics: CoreTypes.RealtimePortfolioMetrics
    let activeWorkers: CoreTypes.ActiveWorkerStatus
    let complianceStatus: CoreTypes.ComplianceOverview
    let criticalAlerts: [CoreTypes.ClientAlert]
    let buildingPerformance: [String: Double]
    let syncStatus: ClientHeroStatusCard.SyncStatus
    
    let onPortfolioTap: () -> Void
    let onComplianceTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onSyncTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version with key metrics
                MinimalClientHeroCard(
                    portfolioScore: portfolioHealth.overallScore,
                    activeWorkers: activeWorkers.totalActive,
                    criticalAlerts: criticalAlerts.filter { $0.severity == .critical }.count,
                    complianceScore: complianceStatus.overallScore,
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
                        portfolioHealth: portfolioHealth,
                        realtimeMetrics: realtimeMetrics,
                        activeWorkers: activeWorkers,
                        complianceStatus: complianceStatus,
                        criticalAlerts: criticalAlerts,
                        buildingPerformance: buildingPerformance,
                        syncStatus: syncStatus,
                        onPortfolioTap: onPortfolioTap,
                        onComplianceTap: onComplianceTap,
                        onWorkersTap: onWorkersTap,
                        onAlertsTap: onAlertsTap,
                        onSyncTap: onSyncTap
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

// MARK: - MinimalClientHeroCard

struct MinimalClientHeroCard: View {
    let portfolioScore: Double
    let activeWorkers: Int
    let criticalAlerts: Int
    let complianceScore: Double
    let onExpand: () -> Void
    
    private var statusColor: Color {
        if criticalAlerts > 0 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if portfolioScore < 0.7 || complianceScore < 0.8 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.success
        }
    }
    
    private var hasCritical: Bool {
        criticalAlerts > 0
    }
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                // Status indicator with pulse animation for critical
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(statusColor.opacity(0.3), lineWidth: 8)
                            .scaleEffect(1.5)
                            .opacity(hasCritical ? 0.6 : 0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: hasCritical)
                    )
                
                // Key metrics in compact form
                HStack(spacing: 16) {
                    MetricPill(
                        value: "\(Int(portfolioScore * 100))%",
                        label: "Health",
                        color: portfolioScoreColor
                    )
                    
                    MetricPill(
                        value: "\(activeWorkers)",
                        label: "Active",
                        color: FrancoSphereDesign.DashboardColors.info
                    )
                    
                    if criticalAlerts > 0 {
                        MetricPill(
                            value: "\(criticalAlerts)",
                            label: "Critical",
                            color: FrancoSphereDesign.DashboardColors.critical
                        )
                    }
                    
                    MetricPill(
                        value: "\(Int(complianceScore * 100))%",
                        label: "Compliance",
                        color: complianceScoreColor
                    )
                }
                
                Spacer()
                
                // Real-time indicator
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                    .opacity(0.6)
                
                // Expand indicator
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
    
    private var portfolioScoreColor: Color {
        if portfolioScore > 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if portfolioScore > 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    private var complianceScoreColor: Color {
        if complianceScore > 0.9 {
            return FrancoSphereDesign.DashboardColors.compliant
        } else if complianceScore > 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.violation
        }
    }
}

// MARK: - Supporting Components

struct ExecutiveIntelligenceCard: View {
    let summary: CoreTypes.ExecutiveIntelligence
    let onDetailTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Executive Intelligence", systemImage: "brain")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
                
                Spacer()
                
                Text("Live")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(FrancoSphereDesign.DashboardColors.success)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(summary.keyInsights.prefix(3), id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(FrancoSphereDesign.DashboardColors.clientAccent)
                            .frame(width: 4, height: 4)
                            .padding(.top, 6)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
            }
            
            Button(action: onDetailTap) {
                Text("View Full Analysis")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.clientPrimary)
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
}

struct CriticalComplianceCard: View {
    let issues: [CoreTypes.ComplianceIssue]
    let onIssueTap: (CoreTypes.ComplianceIssue) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Critical Compliance", systemImage: "exclamationmark.shield")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                
                Spacer()
                
                Text("\(issues.count) issues")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
            }
            
            VStack(spacing: 8) {
                ForEach(issues.prefix(3)) { issue in
                    Button(action: { onIssueTap(issue) }) {
                        ComplianceIssueRow(issue: issue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
}

struct BuildingPerformanceGrid: View {
    let buildings: [NamedCoordinate]
    let onBuildingTap: (NamedCoordinate) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Performance")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(buildings.prefix(4), id: \.id) { building in
                    BuildingPerformanceTile(
                        building: building,
                        onTap: { onBuildingTap(building) }
                    )
                }
            }
        }
    }
}

struct WorkerProductivityCard: View {
    let insights: [CoreTypes.WorkerProductivityInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Worker Productivity", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.info)
            
            VStack(spacing: 8) {
                ForEach(insights.prefix(3)) { insight in
                    HStack {
                        Image(systemName: insight.trend.icon)
                            .font(.caption)
                            .foregroundColor(insight.trend.color)
                        
                        Text(insight.description)
                            .font(.subheadline)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        
                        Spacer()
                        
                        Text(insight.metric)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(insight.trend.color)
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// MARK: - Helper Views

struct ComplianceIssueRow: View {
    let issue: CoreTypes.ComplianceIssue
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(severityColor)
                .frame(width: 6, height: 6)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(issue.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                if let building = issue.buildingName {
                    Text(building)
                        .font(.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            
            Spacer()
            
            if let dueDate = issue.dueDate {
                Text(dueDate.formatted(.dateTime.day().month()))
                    .font(.caption2)
                    .foregroundColor(Date() > dueDate ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.secondaryText)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
        )
    }
    
    private var severityColor: Color {
        switch issue.severity {
        case .critical: return FrancoSphereDesign.DashboardColors.critical
        case .high: return FrancoSphereDesign.DashboardColors.warning
        case .medium: return Color(hex: "fbbf24")
        case .low: return FrancoSphereDesign.DashboardColors.info
        }
    }
}

struct BuildingPerformanceTile: View {
    let building: NamedCoordinate
    let onTap: () -> Void
    @ObservedObject private var contextEngine = ClientContextEngine.shared
    
    private var performance: Double {
        contextEngine.buildingPerformanceMap[building.id] ?? 0.0
    }
    
    private var performanceColor: Color {
        if performance > 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if performance > 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "building.2")
                        .font(.caption)
                        .foregroundColor(performanceColor)
                    
                    Spacer()
                    
                    Text("\(Int(performance * 100))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(performanceColor)
                }
                
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                // Mini progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(performanceColor)
                            .frame(width: geometry.size.width * performance)
                    }
                }
                .frame(height: 4)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(performanceColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ClientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
