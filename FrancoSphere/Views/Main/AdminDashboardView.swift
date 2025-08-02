//
//  AdminDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ REDESIGNED: Mirrors WorkerDashboardView structure
//  ✅ DARK ELEGANCE: Consistent theme with worker dashboard
//  ✅ INTELLIGENT: Contextual AI insights at bottom
//  ✅ STREAMLINED: No tabs, just prioritized content
//  ✅ TWIN DESIGN: Same components, admin-specific data
//

import SwiftUI
import MapKit
import CoreLocation

struct AdminDashboardView: View {
    @StateObject var viewModel: AdminDashboardViewModel
    @ObservedObject private var contextEngine = AdminContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables (Mirroring Worker)
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showAllBuildings = false
    @State private var showCompletedTasks = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("adminPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
    // MARK: - Enums (Same as Worker)
    enum ViewContext {
        case dashboard
        case buildingDetail
        case taskReview
        case workerManagement
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
            return hasCriticalAlerts() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .taskReview:
            return .hidden
        case .workerManagement:
            return .minimal
        case .novaChat:
            return .fullscreen
        case .emergency:
            return .expanded
        }
    }
    
    private func hasCriticalAlerts() -> Bool {
        novaEngine.insights.contains { $0.priority == .critical } ||
        contextEngine.portfolioMetrics.criticalIssues > 0
    }
    
    var body: some View {
        // EXACT SAME STRUCTURE AS WORKER
        MapRevealContainer(
            buildings: contextEngine.buildings,
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
                    // Updated HeaderV3B - Admin variant (5-7%)
                    HeaderV3B(
                        workerName: contextEngine.adminProfile?.name ?? "Admin",
                        nextTaskName: getMostCriticalItem()?.title,
                        showClockPill: false, // Admins don't clock in
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
                        onClockAction: nil, // Not applicable for admin
                        onVoiceCommand: voiceCommandEnabled ? handleVoiceCommand : nil,
                        onARModeToggle: arModeEnabled ? handleARMode : nil,
                        onWearableSync: nil
                    )
                    .zIndex(100)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            // Collapsible Admin Hero Status Card
                            CollapsibleAdminHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                portfolio: contextEngine.portfolioMetrics,
                                activeWorkers: contextEngine.activeWorkers,
                                criticalAlerts: contextEngine.criticalAlerts,
                                syncStatus: getSyncStatus(),
                                onBuildingsTap: { showAllBuildings = true },
                                onWorkersTap: { currentContext = .workerManagement },
                                onAlertsTap: { showCriticalAlerts() },
                                onTasksTap: { showCompletedTasks = true },
                                onSyncTap: { Task { await viewModel.refreshData() } }
                            )
                            .zIndex(50)
                            
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
                    
                    // Intelligence Preview Panel (SAME AS WORKER)
                    if intelligencePanelState != .hidden && (!novaEngine.insights.isEmpty || hasIntelligenceToShow()) {
                        IntelligencePreviewPanel(
                            insights: getCurrentInsights(),
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
            AdminProfileView()
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
                        Task { await contextEngine.refreshContext() }
                    }
            }
        }
        .sheet(isPresented: $showAllBuildings) {
            NavigationView {
                AdminBuildingsListView(
                    buildings: contextEngine.buildings,
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
        .sheet(isPresented: $showCompletedTasks) {
            NavigationView {
                AdminTaskReviewView(
                    tasks: contextEngine.completedTasks,
                    onSelectTask: { task in
                        // Handle task review
                        currentContext = .taskReview
                    }
                )
                .navigationTitle("Task Review")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showCompletedTasks = false
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
                .background(FrancoSphereDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
            .onAppear { currentContext = .taskReview }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showMainMenu) {
            AdminMainMenuView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
        }
    }
    
    // MARK: - Intelligence Methods (Admin-specific)
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.insights
        
        // Add admin-specific contextual insights
        if contextEngine.portfolioMetrics.criticalIssues > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "\(contextEngine.portfolioMetrics.criticalIssues) critical issues require attention",
                description: "Multiple buildings have compliance or maintenance issues",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                affectedBuildings: contextEngine.buildingsWithIssues
            ))
        }
        
        // Worker productivity insights
        let inactiveWorkers = contextEngine.workers.filter { !$0.isActive }.count
        if inactiveWorkers > 2 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "\(inactiveWorkers) workers are offline",
                description: "Consider reassigning tasks or checking worker status",
                type: .operations,
                priority: .high,
                actionRequired: true
            ))
        }
        
        return insights
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        // Same pattern as worker, admin-specific actions
        switch target {
        case .buildings(_):
            showAllBuildings = true
            
        case .taskDetail(let id):
            // Show task review for specific task
            if let task = contextEngine.completedTasks.first(where: { $0.id == id }) {
                // Handle task detail
            }
            
        case .buildingDetail(let id):
            if let building = contextEngine.buildings.first(where: { $0.id == id }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
            
        case .fullInsights:
            showNovaAssistant = true
            
        case .allTasks:
            showCompletedTasks = true
            
        default:
            // Handle other navigation targets
            break
        }
    }
    
    // MARK: - Action Handlers (Admin-specific)
    
    private func handleNovaQuickAction() {
        if hasCriticalAlerts() {
            showNovaAssistant = true
        } else {
            showNovaAssistant = true
        }
    }
    
    private func showCriticalAlerts() {
        // Show critical alerts in Nova or dedicated view
        currentContext = .emergency
        showNovaAssistant = true
    }
    
    private func handleVoiceCommand() {
        print("Admin voice command activated")
    }
    
    private func handleARMode() {
        print("Admin AR mode toggled")
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
    
    private func getMostCriticalItem() -> (title: String, urgency: CoreTypes.AIPriority)? {
        if let criticalInsight = novaEngine.insights.first(where: { $0.priority == .critical }) {
            return (criticalInsight.title, criticalInsight.priority)
        }
        
        if contextEngine.portfolioMetrics.criticalIssues > 0 {
            return ("\(contextEngine.portfolioMetrics.criticalIssues) critical issues", .critical)
        }
        
        return nil
    }
    
    private func getSyncStatus() -> AdminHeroStatusCard.SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced: return .synced
        case .syncing: return .syncing(progress: 0.5)
        case .failed: return .error("Sync failed")
        case .offline: return .offline
        }
    }
    
    private func hasIntelligenceToShow() -> Bool {
        return contextEngine.buildings.count > 5 ||
               contextEngine.portfolioMetrics.criticalIssues > 0 ||
               hasLowPerformanceBuildings()
    }
    
    private func hasLowPerformanceBuildings() -> Bool {
        contextEngine.buildingMetrics.values.contains { metrics in
            metrics.completionRate < 0.7 || metrics.overdueTasks > 3
        }
    }
}

// MARK: - CollapsibleAdminHeroWrapper (Mirrors Worker)

struct CollapsibleAdminHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let portfolio: CoreTypes.PortfolioMetrics
    let activeWorkers: [CoreTypes.WorkerProfile]
    let criticalAlerts: [CoreTypes.AdminAlert]
    let syncStatus: AdminHeroStatusCard.SyncStatus
    
    let onBuildingsTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onTasksTap: () -> Void
    let onSyncTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalAdminHeroCard(
                    totalBuildings: portfolio.totalBuildings,
                    activeWorkers: activeWorkers.count,
                    criticalAlerts: criticalAlerts.count,
                    completionRate: portfolio.overallCompletionRate,
                    onExpand: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
                
            } else {
                // Full AdminHeroStatusCard with collapse button
                ZStack(alignment: .topTrailing) {
                    AdminHeroStatusCard(
                        portfolio: portfolio,
                        activeWorkers: activeWorkers,
                        criticalAlerts: criticalAlerts,
                        syncStatus: syncStatus,
                        onBuildingsTap: onBuildingsTap,
                        onWorkersTap: onWorkersTap,
                        onAlertsTap: onAlertsTap,
                        onTasksTap: onTasksTap,
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

// MARK: - MinimalAdminHeroCard

struct MinimalAdminHeroCard: View {
    let totalBuildings: Int
    let activeWorkers: Int
    let criticalAlerts: Int
    let completionRate: Double
    let onExpand: () -> Void
    
    var body: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                // Status indicator
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
                
                // Portfolio summary
                HStack(spacing: 16) {
                    MetricPill(value: "\(totalBuildings)", label: "Buildings", color: FrancoSphereDesign.DashboardColors.info)
                    MetricPill(value: "\(activeWorkers)", label: "Active", color: FrancoSphereDesign.DashboardColors.success)
                    
                    if criticalAlerts > 0 {
                        MetricPill(value: "\(criticalAlerts)", label: "Alerts", color: FrancoSphereDesign.DashboardColors.critical)
                    }
                    
                    MetricPill(value: "\(Int(completionRate * 100))%", label: "Complete", color: completionColor)
                }
                
                Spacer()
                
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
    
    private var statusColor: Color {
        if criticalAlerts > 0 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if completionRate < 0.7 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.success
        }
    }
    
    private var hasCritical: Bool {
        criticalAlerts > 0
    }
    
    private var completionColor: Color {
        if completionRate > 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if completionRate > 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
}

// MARK: - MetricPill Component

struct MetricPill: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
        }
    }
}

// MARK: - Preview Provider

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView(viewModel: AdminDashboardViewModel())
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
