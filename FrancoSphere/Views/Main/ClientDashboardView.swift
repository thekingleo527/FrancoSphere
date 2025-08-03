//
//  ClientDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Aligned with Worker/Admin dashboard structure
//  ✅ CONSISTENT: Uses MapRevealContainer wrapper pattern
//  ✅ COLLAPSIBLE: Hero card now matches other dashboards
//  ✅ CORRECT TYPES: Using actual types from ClientContextEngine
//  ✅ UNIFIED: Same component hierarchy and data flow
//

import SwiftUI
import MapKit
import CoreLocation

struct ClientDashboardView: View {
    @StateObject private var viewModel = ClientDashboardViewModel()
    @ObservedObject private var contextEngine = ClientContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @ObservedObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables (Aligned with Worker/Admin)
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showAllBuildings = false
    @State private var showComplianceReport = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("clientPanelPreference") private var userPanelPreference: IntelPanelState = .collapsed
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
    // MARK: - Enums (Matching Worker/Admin pattern)
    enum ViewContext {
        case dashboard
        case buildingDetail
        case compliance
        case reports
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
            return hasUrgentAlerts() ? .expanded : userPanelPreference
        case .buildingDetail:
            return .minimal
        case .compliance:
            return .minimal
        case .reports:
            return .hidden
        case .novaChat:
            return .fullscreen
        case .emergency:
            return .expanded
        }
    }
    
    private func hasUrgentAlerts() -> Bool {
        novaEngine.insights.contains { $0.priority == .critical } ||
        contextEngine.complianceOverview.criticalViolations > 0 ||
        contextEngine.realtimeRoutineMetrics.behindScheduleCount > 0
    }
    
    var body: some View {
        // WRAP IN MapRevealContainer - MATCHING PATTERN!
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
                
                // Main content - SAME STRUCTURE AS WORKER/ADMIN
                VStack(spacing: 0) {
                    // HeaderV3B - Client variant (5-7%)
                    HeaderV3B(
                        workerName: contextEngine.clientProfile?.name ?? "Client",
                        nextTaskName: getMostCriticalItem()?.title,
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
                        onClockAction: nil,
                        onVoiceCommand: voiceCommandEnabled ? handleVoiceCommand : nil,
                        onARModeToggle: arModeEnabled ? handleARMode : nil,
                        onWearableSync: nil
                    )
                    .zIndex(100)
                    
                    // Main content area with ScrollView
                    ScrollView {
                        VStack(spacing: 16) {
                            // Collapsible Client Hero Card - Using the existing ClientHeroCard
                            CollapsibleClientHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                routineMetrics: contextEngine.realtimeRoutineMetrics,
                                activeWorkers: contextEngine.activeWorkerStatus,
                                complianceStatus: contextEngine.complianceOverviewStatus,
                                monthlyMetrics: contextEngine.monthlyMetrics,
                                syncStatus: getSyncStatus(),
                                onBuildingsTap: { showAllBuildings = true },
                                onComplianceTap: { showComplianceReport = true },
                                onBudgetTap: { /* Show financial details */ },
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
                        await contextEngine.refreshContext()
                        refreshID = UUID()
                    }
                    
                    // Intelligence Preview Panel
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
            ClientProfileView()
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView(clientMode: true)
                .presentationDetents([.large])
                .onAppear { currentContext = .novaChat }
                .onDisappear { currentContext = .dashboard }
        }
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address
                )
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
                .navigationTitle("My Properties")
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
        .sheet(isPresented: $showComplianceReport) {
            NavigationView {
                ClientComplianceView(
                    complianceOverview: contextEngine.complianceOverview,
                    buildingCompliance: contextEngine.clientComplianceData,
                    onSelectBuilding: { buildingId in
                        if let building = contextEngine.clientBuildings.first(where: { $0.id == buildingId }) {
                            selectedBuilding = building
                            showBuildingDetail = true
                            showComplianceReport = false
                        }
                    }
                )
                .navigationTitle("Compliance Report")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showComplianceReport = false
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                }
                .background(FrancoSphereDesign.DashboardColors.baseBackground)
            }
            .preferredColorScheme(.dark)
            .onAppear { currentContext = .compliance }
            .onDisappear { currentContext = .dashboard }
        }
        .sheet(isPresented: $showMainMenu) {
            ClientMainMenuView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
        }
        .task {
            await contextEngine.refreshContext()
        }
    }
    
    // MARK: - Intelligence Methods
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.insights
        
        // Behind schedule buildings
        if contextEngine.realtimeRoutineMetrics.behindScheduleCount > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(contextEngine.realtimeRoutineMetrics.behindScheduleCount) properties behind schedule",
                description: "Service delays detected. Immediate attention recommended.",
                type: .operations,
                priority: .high,
                actionRequired: true,
                recommendedAction: "Contact operations team",
                affectedBuildings: contextEngine.realtimeRoutineMetrics.buildingStatuses
                    .filter { $0.value.isBehindSchedule }
                    .map { $0.key }
            ))
        }
        
        // Compliance issues
        if contextEngine.complianceOverview.criticalViolations > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(contextEngine.complianceOverview.criticalViolations) compliance violations",
                description: "Critical violations require immediate resolution",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                recommendedAction: "View compliance report",
                affectedBuildings: contextEngine.buildingsWithViolations
            ))
        }
        
        // Budget alerts
        if contextEngine.monthlyMetrics.budgetUtilization > 1.0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Monthly spending over budget",
                description: String(format: "Current spending at %.0f%% of budget",
                                  contextEngine.monthlyMetrics.budgetUtilization * 100),
                type: .cost,
                priority: .medium,
                actionRequired: false,
                recommendedAction: "Review cost analysis"
            ))
        }
        
        // Cost savings
        if contextEngine.estimatedMonthlySavings > 1000 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Potential savings: $\(Int(contextEngine.estimatedMonthlySavings))/month",
                description: "Optimization opportunities identified",
                type: .cost,
                priority: .medium,
                actionRequired: false,
                recommendedAction: "Review optimization report"
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
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
            showComplianceReport = true
            
        case .fullInsights:
            showNovaAssistant = true
            
        case .allBuildings:
            showAllBuildings = true
            
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func getMostCriticalItem() -> (title: String, urgency: CoreTypes.AIPriority)? {
        if let criticalInsight = novaEngine.insights.first(where: { $0.priority == .critical }) {
            return (criticalInsight.title, criticalInsight.priority)
        }
        
        if contextEngine.complianceOverview.criticalViolations > 0 {
            return ("\(contextEngine.complianceOverview.criticalViolations) compliance violations", .critical)
        }
        
        if contextEngine.realtimeRoutineMetrics.behindScheduleCount > 0 {
            return ("\(contextEngine.realtimeRoutineMetrics.behindScheduleCount) buildings behind", .high)
        }
        
        return nil
    }
    
    private func getSyncStatus() -> SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced: return .synced
        case .syncing: return .syncing(progress: 0.5)
        case .failed: return .error("Sync failed")
        case .offline: return .offline
        }
    }
    
    private func hasIntelligenceToShow() -> Bool {
        return contextEngine.clientBuildings.count > 5 ||
               contextEngine.complianceOverview.criticalViolations > 0 ||
               contextEngine.realtimeRoutineMetrics.behindScheduleCount > 0 ||
               contextEngine.estimatedMonthlySavings > 1000
    }
    
    private func handleNovaQuickAction() {
        if hasUrgentAlerts() {
            showNovaAssistant = true
        } else {
            showNovaAssistant = true
        }
    }
    
    private func handleVoiceCommand() {
        print("Client voice command activated")
    }
    
    private func handleARMode() {
        print("Client AR mode toggled")
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
}

// MARK: - Collapsible Wrapper - Uses existing ClientHeroCard

struct CollapsibleClientHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    // Using the actual types from ClientContextEngine
    let routineMetrics: RealtimeRoutineMetrics
    let activeWorkers: ActiveWorkerStatus
    let complianceStatus: CoreTypes.ComplianceOverview
    let monthlyMetrics: MonthlyMetrics
    let syncStatus: SyncStatus
    
    let onBuildingsTap: () -> Void
    let onComplianceTap: () -> Void
    let onBudgetTap: () -> Void
    let onSyncTap: () -> Void
    
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case error(String)
        case offline
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalClientHeroCard(
                    totalBuildings: routineMetrics.buildingStatuses.count,
                    behindSchedule: routineMetrics.behindScheduleCount,
                    completionRate: routineMetrics.overallCompletion,
                    activeWorkers: activeWorkers.totalActive,
                    complianceScore: complianceStatus.overallScore,
                    budgetUtilization: monthlyMetrics.budgetUtilization,
                    onExpand: {
                        withAnimation(FrancoSphereDesign.Animations.spring) {
                            isCollapsed = false
                        }
                    }
                )
                
            } else {
                // Full ClientHeroCard with collapse button
                ZStack(alignment: .topTrailing) {
                    // Using the existing ClientHeroCard from paste.txt
                    ClientHeroCard(
                        routineMetrics: CoreTypes.RealtimeRoutineMetrics(
                            overallCompletion: routineMetrics.overallCompletion,
                            activeWorkerCount: routineMetrics.activeWorkerCount,
                            behindScheduleCount: routineMetrics.behindScheduleCount,
                            buildingStatuses: routineMetrics.buildingStatuses
                        ),
                        activeWorkers: CoreTypes.ActiveWorkerStatus(
                            totalActive: activeWorkers.totalActive,
                            byBuilding: activeWorkers.byBuilding,
                            utilizationRate: activeWorkers.utilizationRate
                        ),
                        complianceStatus: complianceStatus,
                        monthlyMetrics: CoreTypes.MonthlyMetrics(
                            currentSpend: monthlyMetrics.currentSpend,
                            monthlyBudget: monthlyMetrics.monthlyBudget,
                            projectedSpend: monthlyMetrics.projectedSpend,
                            daysRemaining: monthlyMetrics.daysRemaining
                        ),
                        onBuildingTap: { building in
                            // Handle building tap
                            onBuildingsTap()
                        }
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

// MARK: - Minimal Hero Card (Collapsed State)

struct MinimalClientHeroCard: View {
    let totalBuildings: Int
    let behindSchedule: Int
    let completionRate: Double
    let activeWorkers: Int
    let complianceScore: Double
    let budgetUtilization: Double
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
                    MetricPill(value: "\(totalBuildings)", label: "Properties", color: FrancoSphereDesign.DashboardColors.info)
                    
                    if behindSchedule > 0 {
                        MetricPill(value: "\(behindSchedule)", label: "Behind", color: FrancoSphereDesign.DashboardColors.warning)
                    }
                    
                    MetricPill(value: "\(Int(completionRate * 100))%", label: "Complete", color: completionColor)
                    
                    if budgetUtilization > 1.0 {
                        MetricPill(value: "\(Int(budgetUtilization * 100))%", label: "Budget", color: FrancoSphereDesign.DashboardColors.critical)
                    }
                    
                    MetricPill(value: "\(activeWorkers)", label: "Active", color: FrancoSphereDesign.DashboardColors.success)
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
        if behindSchedule > 0 || complianceScore < 0.7 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if completionRate < 0.7 || budgetUtilization > 0.9 {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.success
        }
    }
    
    private var hasCritical: Bool {
        behindSchedule > 0 || complianceScore < 0.7 || budgetUtilization > 1.0
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

// MARK: - Supporting Components

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

// MARK: - Placeholder Views (Implementation needed)

struct ClientBuildingsListView: View {
    let buildings: [NamedCoordinate]
    let onSelectBuilding: (NamedCoordinate) -> Void
    
    var body: some View {
        List(buildings) { building in
            Button(action: { onSelectBuilding(building) }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(building.name)
                            .font(.headline)
                        Text(building.address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct ClientComplianceView: View {
    let complianceOverview: CoreTypes.ComplianceOverview
    let buildingCompliance: [String: ComplianceData]
    let onSelectBuilding: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Overall score
                HStack {
                    VStack(alignment: .leading) {
                        Text("Overall Compliance")
                            .font(.headline)
                        Text("\(Int(complianceOverview.overallScore * 100))%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                .padding()
                .francoDarkCardBackground()
            }
            .padding()
        }
    }
}

// MARK: - Type Aliases for ClientContextEngine compatibility

typealias NamedCoordinate = CoreTypes.NamedCoordinate
typealias RealtimeRoutineMetrics = CoreTypes.RealtimeRoutineMetrics
typealias ActiveWorkerStatus = CoreTypes.ActiveWorkerStatus
typealias MonthlyMetrics = CoreTypes.MonthlyMetrics
typealias ComplianceData = CoreTypes.ComplianceData

// MARK: - Preview

struct ClientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}

// Type aliases for ClientContextEngine compatibility
extension ClientDashboardView {
    enum SyncStatus {
        case synced
        case syncing(progress: Double)
        case error(String)
        case offline
    }
}
