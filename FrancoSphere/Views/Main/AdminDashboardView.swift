//
//  AdminDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: ViewBuilder compilation error resolved
//  ✅ FIXED: MainActor isolation for AdminContextEngine
//  ✅ REDESIGNED: Mirrors WorkerDashboardView structure
//  ✅ DARK ELEGANCE: Consistent theme with worker dashboard
//  ✅ INTELLIGENT: Contextual AI insights at bottom
//  ✅ STREAMLINED: No tabs, just prioritized content
//  ✅ TWIN DESIGN: Same components, admin-specific data
//  ✅ COMPLIANCE: Integrated ComplianceOverviewView access
//

import SwiftUI
import MapKit
import CoreLocation

struct AdminDashboardView: View {
    @StateObject var viewModel: AdminDashboardViewModel
    @StateObject private var contextEngine = AdminContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @ObservedObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables (Mirroring Worker + Admin additions)
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
    
    // Admin-specific states
    @State private var showingComplianceCenter = false
    @State private var showingWorkerManagement = false
    @State private var showingReports = false
    @State private var selectedWorker: CoreTypes.WorkerProfile?
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("adminPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
    // MARK: - Initialization
    init(viewModel: AdminDashboardViewModel = AdminDashboardViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Enums (Same as Worker)
    enum ViewContext {
        case dashboard
        case buildingDetail
        case taskReview
        case workerManagement
        case novaChat
        case emergency
        case compliance
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
        case .compliance:
            return .minimal
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
                                complianceScore: contextEngine.portfolioMetrics.complianceScore,
                                onBuildingsTap: { showAllBuildings = true },
                                onWorkersTap: { showingWorkerManagement = true },
                                onAlertsTap: { showCriticalAlerts() },
                                onTasksTap: { showCompletedTasks = true },
                                onComplianceTap: { showingComplianceCenter = true },
                                onSyncTap: { Task { await viewModel.refreshData() } }
                            )
                            .zIndex(50)
                            
                            // Quick Actions Section
                            adminQuickActions
                            
                            // Live Activity Feed
                            if !contextEngine.recentActivity.isEmpty {
                                liveActivitySection
                            }
                            
                            // Critical Issues Summary
                            if contextEngine.portfolioMetrics.criticalIssues > 0 {
                                criticalIssuesSection
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
        .sheet(isPresented: $showingComplianceCenter) {
            ComplianceOverviewView(
                intelligence: contextEngine.portfolioIntelligence,
                onScheduleAudit: {
                    // Handle audit scheduling
                    Task {
                        await contextEngine.scheduleAudit()
                        await viewModel.refreshData()
                    }
                },
                onExportReport: {
                    // Handle report export
                    showingReports = true
                }
            )
            .onAppear { currentContext = .compliance }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingWorkerManagement) {
            NavigationView {
                AdminWorkerManagementView(
                    workers: contextEngine.workers,
                    onSelectWorker: { worker in
                        selectedWorker = worker
                    }
                )
                .navigationTitle("Worker Management")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingWorkerManagement = false
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
                .background(FrancoSphereDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
            .onAppear { currentContext = .workerManagement }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showingReports) {
            AdminReportsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showMainMenu) {
            AdminMainMenuView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var adminQuickActions: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            QuickActionCard(
                title: "Compliance",
                value: "\(Int(contextEngine.portfolioMetrics.complianceScore))%",
                icon: "checkmark.shield.fill",
                color: complianceScoreColor,
                showBadge: contextEngine.portfolioMetrics.criticalIssues > 0,
                badgeCount: contextEngine.portfolioMetrics.criticalIssues,
                action: { showingComplianceCenter = true }
            )
            
            QuickActionCard(
                title: "Workers",
                value: "\(contextEngine.activeWorkers.count)/\(contextEngine.workers.count)",
                icon: "person.3.fill",
                color: FrancoSphereDesign.DashboardColors.workerPrimary,
                action: { showingWorkerManagement = true }
            )
            
            QuickActionCard(
                title: "Tasks Today",
                value: "\(contextEngine.todaysTaskCount)",
                icon: "checklist",
                color: FrancoSphereDesign.DashboardColors.info,
                action: { showCompletedTasks = true }
            )
            
            QuickActionCard(
                title: "Reports",
                value: "Generate",
                icon: "doc.badge.arrow.up",
                color: FrancoSphereDesign.DashboardColors.tertiaryAction,
                action: { showingReports = true }
            )
        }
    }
    
    private var complianceScoreColor: Color {
        let score = contextEngine.portfolioMetrics.complianceScore
        if score >= 90 { return FrancoSphereDesign.DashboardColors.success }
        if score >= 80 { return FrancoSphereDesign.DashboardColors.info }
        if score >= 70 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.critical
    }
    
    // MARK: - Live Activity Section
    
    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Live Activity", systemImage: "dot.radiowaves.left.and.right")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                LiveIndicator()
            }
            
            VStack(spacing: 8) {
                ForEach(contextEngine.recentActivity.prefix(5)) { activity in
                    AdminActivityRow(activity: activity)
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Critical Issues Section
    
    private var criticalIssuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(contextEngine.portfolioMetrics.criticalIssues) Critical Issues", systemImage: "exclamationmark.triangle.fill")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                
                Spacer()
                
                Button("View All") {
                    showingComplianceCenter = true
                }
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
            }
            
            // Show top 3 critical issues
            VStack(spacing: 8) {
                ForEach(contextEngine.criticalAlerts.prefix(3)) { alert in
                    CriticalAlertRow(alert: alert) {
                        handleCriticalAlert(alert)
                    }
                }
            }
        }
        .francoCardPadding()
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                        .stroke(FrancoSphereDesign.DashboardColors.critical.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Intelligence Methods (Admin-specific)
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.insights
        
        // Add admin-specific contextual insights
        if contextEngine.portfolioMetrics.criticalIssues > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(contextEngine.portfolioMetrics.criticalIssues) critical compliance issues",
                description: "Multiple buildings require immediate attention",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                recommendedAction: "Open Compliance Center",
                affectedBuildings: contextEngine.buildingsWithIssues
            ))
        }
        
        // Worker productivity insights
        let inactiveWorkers = contextEngine.workers.filter { !$0.isActive }.count
        if inactiveWorkers > 2 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(inactiveWorkers) workers are offline",
                description: "Consider reassigning tasks or checking worker status",
                type: .operations,
                priority: .high,
                actionRequired: true,
                recommendedAction: "View Worker Management"
            ))
        }
        
        // DSNY compliance check
        let dsnyDeadlines = contextEngine.upcomingDSNYDeadlines
        if !dsnyDeadlines.isEmpty {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "DSNY deadlines approaching",
                description: "\(dsnyDeadlines.count) buildings need trash setout by 8PM",
                type: .compliance,
                priority: .high,
                actionRequired: true,
                recommendedAction: "Dispatch workers",
                affectedBuildings: dsnyDeadlines.map { $0.buildingId }
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
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
                showCompletedTasks = true
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
            
        case .compliance:
            showingComplianceCenter = true
            
        case .workerManagement:
            showingWorkerManagement = true
            
        default:
            // Handle other navigation targets
            break
        }
    }
    
    // MARK: - Action Handlers (Admin-specific)
    
    private func handleNovaQuickAction() {
        if hasCriticalAlerts() {
            // Show immediate actions for critical situations
            showNovaAssistant = true
        } else {
            showNovaAssistant = true
        }
    }
    
    private func showCriticalAlerts() {
        // Show critical alerts - prioritize compliance issues
        if contextEngine.portfolioMetrics.criticalIssues > 0 {
            showingComplianceCenter = true
        } else {
            currentContext = .emergency
            showNovaAssistant = true
        }
    }
    
    private func handleCriticalAlert(_ alert: CoreTypes.AdminAlert) {
        switch alert.type {
        case .compliance:
            showingComplianceCenter = true
        case .worker:
            showingWorkerManagement = true
        case .building:
            if let buildingId = alert.metadata["buildingId"],
               let building = contextEngine.buildings.first(where: { $0.id == buildingId }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
        case .task:
            showCompletedTasks = true
        default:
            showNovaAssistant = true
        }
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

// MARK: - CollapsibleAdminHeroWrapper (Enhanced with Compliance)

struct CollapsibleAdminHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    let portfolio: CoreTypes.PortfolioMetrics
    let activeWorkers: [CoreTypes.WorkerProfile]
    let criticalAlerts: [CoreTypes.AdminAlert]
    let syncStatus: AdminHeroStatusCard.SyncStatus
    let complianceScore: Double
    
    let onBuildingsTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onTasksTap: () -> Void
    let onComplianceTap: () -> Void
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
                    complianceScore: complianceScore,
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
                        complianceScore: complianceScore,
                        onBuildingsTap: onBuildingsTap,
                        onWorkersTap: onWorkersTap,
                        onAlertsTap: onAlertsTap,
                        onTasksTap: onTasksTap,
                        onComplianceTap: onComplianceTap,
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

// MARK: - MinimalAdminHeroCard (Enhanced)

struct MinimalAdminHeroCard: View {
    let totalBuildings: Int
    let activeWorkers: Int
    let criticalAlerts: Int
    let completionRate: Double
    let complianceScore: Double
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
                    
                    MetricPill(value: "\(Int(complianceScore))%", label: "Compliance", color: complianceColor)
                    
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
        } else if completionRate < 0.7 || complianceScore < 70 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.success
        }
    }
    
    private var hasCritical: Bool {
        criticalAlerts > 0 || complianceScore < 70
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
    
    private var complianceColor: Color {
        if complianceScore >= 90 { return FrancoSphereDesign.DashboardColors.success }
        if complianceScore >= 80 { return FrancoSphereDesign.DashboardColors.info }
        if complianceScore >= 70 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.critical
    }
}

// MARK: - AdminHeroStatusCard (Enhanced)

struct AdminHeroStatusCard: View {
    // Real-time data inputs
    let portfolio: CoreTypes.PortfolioMetrics
    let activeWorkers: [CoreTypes.WorkerProfile]
    let criticalAlerts: [CoreTypes.AdminAlert]
    let syncStatus: SyncStatus
    let complianceScore: Double
    
    // Callbacks
    let onBuildingsTap: () -> Void
    let onWorkersTap: () -> Void
    let onAlertsTap: () -> Void
    let onTasksTap: () -> Void
    let onComplianceTap: () -> Void
    let onSyncTap: () -> Void
    
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case error(String)
        case offline
        
        var isLive: Bool {
            switch self {
            case .synced, .syncing: return true
            default: return false
            }
        }
    }
    
    // Real-time computed properties
    private var workersOnSite: Int {
        activeWorkers.filter { $0.isClockedIn }.count
    }
    
    private var buildingsWithCoverage: Int {
        Set(activeWorkers.compactMap { $0.currentBuildingId }).count
    }
    
    private var recentActivityFeed: [String] {
        // Most recent 3 activities from workers
        DashboardSyncService.shared.liveWorkerUpdates
            .prefix(3)
            .map { update in
                "\(update.workerName ?? "Worker") \(update.action) • \(update.timestamp.formatted(.relative(presentation: .named)))"
            }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with live indicator
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Overview")
                        .francoTypography(FrancoSphereDesign.Typography.dashboardTitle)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text("Real-time data from \(activeWorkers.count) workers across \(portfolio.totalBuildings) buildings")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                
                Spacer()
                
                // Live sync indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(syncStatus.isLive ? 1 : 0.3)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: syncStatus.isLive)
                    
                    Text("LIVE")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
            
            // Real-time metrics grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Workers metric
                MetricCard(
                    value: "\(workersOnSite)/\(activeWorkers.count)",
                    label: "Workers Active",
                    subtitle: "\(activeWorkers.count - workersOnSite) on break",
                    color: FrancoSphereDesign.DashboardColors.success,
                    icon: "person.3.fill",
                    onTap: onWorkersTap
                ) {
                    // Live worker status dots
                    HStack(spacing: 2) {
                        ForEach(0..<min(3, workersOnSite), id: \.self) { _ in
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                // Buildings coverage
                MetricCard(
                    value: "\(buildingsWithCoverage)/\(portfolio.totalBuildings)",
                    label: "Buildings Covered",
                    subtitle: "\(portfolio.totalBuildings - buildingsWithCoverage) need attention",
                    color: FrancoSphereDesign.DashboardColors.info,
                    icon: "building.2.fill",
                    onTap: onBuildingsTap
                )
                
                // Compliance score
                MetricCard(
                    value: "\(Int(complianceScore))%",
                    label: "Compliance Score",
                    subtitle: portfolio.criticalIssues > 0 ? "\(portfolio.criticalIssues) issues" : "Good standing",
                    color: complianceScoreColor,
                    icon: "checkmark.shield.fill",
                    onTap: onComplianceTap
                ) {
                    if portfolio.criticalIssues > 0 {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Task completion (real-time)
                MetricCard(
                    value: "\(Int(portfolio.overallCompletionRate * 100))%",
                    label: "Completion Rate",
                    color: completionRateColor,
                    icon: "chart.line.uptrend.xyaxis",
                    onTap: onTasksTap
                ) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(completionRateColor)
                                .frame(width: geometry.size.width * portfolio.overallCompletionRate, height: 6)
                                .animation(.easeOut(duration: 0.5), value: portfolio.overallCompletionRate)
                        }
                    }
                    .frame(height: 6)
                }
            }
            
            // Critical alerts
            if !criticalAlerts.isEmpty {
                HStack(spacing: 12) {
                    MetricCard(
                        value: "\(criticalAlerts.count)",
                        label: "Critical Alerts",
                        subtitle: "Action required",
                        color: FrancoSphereDesign.DashboardColors.critical,
                        icon: "exclamationmark.triangle.fill",
                        onTap: onAlertsTap
                    ) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .opacity(0.6)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: criticalAlerts.count)
                    }
                }
            }
            
            // Live activity feed
            if !recentActivityFeed.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Activity")
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    
                    ForEach(recentActivityFeed.prefix(2), id: \.self) { activity in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            
                            Text(activity)
                                .francoTypography(FrancoSphereDesign.Typography.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                )
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var completionRateColor: Color {
        if portfolio.overallCompletionRate > 0.8 {
            return FrancoSphereDesign.DashboardColors.success
        } else if portfolio.overallCompletionRate > 0.6 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    private var complianceScoreColor: Color {
        if complianceScore >= 90 { return FrancoSphereDesign.DashboardColors.success }
        if complianceScore >= 80 { return FrancoSphereDesign.DashboardColors.info }
        if complianceScore >= 70 { return FrancoSphereDesign.DashboardColors.warning }
        return FrancoSphereDesign.DashboardColors.critical
    }
}

// MARK: - Supporting Components (FIXED)

struct MetricCard<CustomContent: View>: View {
    let value: String
    let label: String
    var subtitle: String? = nil
    let color: Color
    let icon: String
    let onTap: () -> Void
    let customContent: () -> CustomContent
    
    // Standard initializer without custom content
    init(
        value: String,
        label: String,
        subtitle: String? = nil,
        color: Color,
        icon: String,
        onTap: @escaping () -> Void
    ) where CustomContent == EmptyView {
        self.value = value
        self.label = label
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
        self.onTap = onTap
        self.customContent = { EmptyView() }
    }
    
    // Initializer with custom content using @ViewBuilder
    init(
        value: String,
        label: String,
        subtitle: String? = nil,
        color: Color,
        icon: String,
        onTap: @escaping () -> Void,
        @ViewBuilder customContent: @escaping () -> CustomContent
    ) {
        self.value = value
        self.label = label
        self.subtitle = subtitle
        self.color = color
        self.icon = icon
        self.onTap = onTap
        self.customContent = customContent
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    customContent()
                }
                
                Text(value)
                    .francoTypography(FrancoSphereDesign.Typography.title2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(label)
                    .francoTypography(FrancoSphereDesign.Typography.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var showBadge: Bool = false
    var badgeCount: Int = 0
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Text(value)
                        .francoTypography(FrancoSphereDesign.Typography.headline)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text(title)
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .francoDarkCardBackground()
                
                if showBadge && badgeCount > 0 {
                    Text("\(badgeCount)")
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: -8, y: 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

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

struct AdminActivityRow: View {
    let activity: AdminActivity
    
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
                
                HStack(spacing: 4) {
                    if let workerName = activity.workerName {
                        Text(workerName)
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                    
                    if let buildingName = activity.buildingName {
                        Text("• \(buildingName)")
                            .francoTypography(FrancoSphereDesign.Typography.caption2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
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
        case .workerClockIn: return FrancoSphereDesign.DashboardColors.info
        case .violation: return FrancoSphereDesign.DashboardColors.critical
        case .photoUploaded: return FrancoSphereDesign.DashboardColors.tertiaryAction
        default: return FrancoSphereDesign.DashboardColors.secondaryText
        }
    }
}

struct CriticalAlertRow: View {
    let alert: CoreTypes.AdminAlert
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: alertIcon)
                    .font(.title3)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(alert.title)
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    if let building = alert.affectedBuilding {
                        Text(building)
                            .francoTypography(FrancoSphereDesign.Typography.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(alert.urgency.rawValue)
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(urgencyColor)
                    
                    Text(alert.timestamp, style: .relative)
                        .francoTypography(FrancoSphereDesign.Typography.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var alertIcon: String {
        switch alert.type {
        case .compliance: return "exclamationmark.shield"
        case .worker: return "person.fill.xmark"
        case .building: return "building.2.fill"
        case .task: return "checklist"
        default: return "exclamationmark.triangle.fill"
        }
    }
    
    private var urgencyColor: Color {
        FrancoSphereDesign.EnumColors.aiPriority(alert.urgency)
    }
}

struct LiveIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(FrancoSphereDesign.DashboardColors.success)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            
            Text("LIVE")
                .francoTypography(FrancoSphereDesign.Typography.caption2)
                .fontWeight(.semibold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.success)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Admin Main Menu View

struct AdminMainMenuView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Management") {
                    Label("Compliance Center", systemImage: "checkmark.shield")
                    Label("Worker Management", systemImage: "person.3")
                    Label("Building Portfolio", systemImage: "building.2")
                    Label("Task Review", systemImage: "checklist")
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
                
                Section("Analytics") {
                    Label("Reports", systemImage: "doc.text")
                    Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                    Label("Insights", systemImage: "lightbulb")
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
                
                Section("Tools") {
                    Label("Schedule Audit", systemImage: "calendar.badge.plus")
                    Label("Export Data", systemImage: "doc.badge.arrow.up")
                    Label("Messages", systemImage: "message")
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
                
                Section("Support") {
                    Label("Help", systemImage: "questionmark.circle")
                    Label("Settings", systemImage: "gear")
                }
                .listRowBackground(FrancoSphereDesign.DashboardColors.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(FrancoSphereDesign.DashboardColors.baseBackground)
            .navigationTitle("Admin Menu")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Supporting Types

struct AdminActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let description: String
    let workerName: String?
    let buildingName: String?
    let timestamp: Date
    
    enum ActivityType {
        case taskCompleted
        case workerClockIn
        case workerClockOut
        case violation
        case photoUploaded
        case issueResolved
    }
}

// MARK: - Admin Context Engine (Mock)

@MainActor
class AdminContextEngine: ObservableObject {
    static let shared = AdminContextEngine()
    
    @Published var adminProfile: AdminProfile?
    @Published var buildings: [CoreTypes.NamedCoordinate] = []
    @Published var workers: [CoreTypes.WorkerProfile] = []
    @Published var activeWorkers: [CoreTypes.WorkerProfile] = []
    @Published var portfolioMetrics = CoreTypes.PortfolioMetrics(
        totalBuildings: 12,
        totalWorkers: 24,
        activeWorkers: 18,
        overallCompletionRate: 0.87,
        criticalIssues: 3,
        complianceScore: 85
    )
    @Published var criticalAlerts: [CoreTypes.AdminAlert] = []
    @Published var completedTasks: [CoreTypes.ContextualTask] = []
    @Published var recentActivity: [AdminActivity] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published var todaysTaskCount = 47
    @Published var buildingsWithIssues: [String] = []
    @Published var upcomingDSNYDeadlines: [(buildingId: String, deadline: Date)] = []
    
    func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        // Handle incoming dashboard updates
    }
    
    func refreshContext() async {
        // Refresh all admin data
    }
    
    func scheduleAudit() async {
        // Schedule compliance audit
    }
}

struct AdminProfile {
    let id: String
    let name: String
    let email: String
    let role: CoreTypes.UserRole
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
