//
//  ClientDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: Main actor isolation issues resolved
//  ✅ FIXED: Removed duplicate type declarations
//  ✅ STREAMLINED: Real-time routine status focus
//  ✅ NO SCROLL: Everything fits on one screen
//  ✅ LIVE DATA: Shows what's happening RIGHT NOW
//  ✅ CLIENT VALUE: Immediate visibility of service delivery
//

import SwiftUI
import MapKit

struct ClientDashboardView: View {
    @StateObject private var viewModel: ClientDashboardViewModel
    @ObservedObject private var contextEngine = ClientContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    // Fix: Remove @StateObject and use @ObservedObject for shared singleton
    @ObservedObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Intelligence panel state
    @State private var currentContext: ViewContext = .dashboard
    @AppStorage("clientPanelPreference") private var userPanelPreference: IntelPanelState = .expanded
    
    // Local state properties for real-time metrics
    @State private var realtimeRoutineMetrics = CoreTypes.RealtimeRoutineMetrics()
    @State private var activeWorkerStatus = CoreTypes.ActiveWorkerStatus(
        totalActive: 0,
        byBuilding: [:],
        utilizationRate: 0.0
    )
    @State private var complianceStatus = CoreTypes.ComplianceOverview(
        overallScore: 0.85,
        criticalViolations: 0,
        pendingInspections: 0,
        lastUpdated: Date()
    )
    @State private var monthlyMetrics = CoreTypes.MonthlyMetrics(
        currentSpend: 0,
        monthlyBudget: 10000,
        projectedSpend: 0,
        daysRemaining: 30
    )
    
    // MARK: - Initialization
    init(viewModel: ClientDashboardViewModel = ClientDashboardViewModel()) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Enums
    enum ViewContext {
        case dashboard
        case buildingDetail
        case novaChat
    }
    
    enum IntelPanelState: String {
        case collapsed = "collapsed"
        case expanded = "expanded"
    }
    
    // MARK: - Computed Properties
    private var hasImportantUpdates: Bool {
        contextEngine.hasActiveIssues ||
        contextEngine.hasBehindScheduleBuildings ||
        contextEngine.hasComplianceIssues
    }
    
    var body: some View {
        ZStack {
            // Dark Elegance Background
            FrancoSphereDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            // Main content - NO SCROLL VIEW
            VStack(spacing: 0) {
                // Client Header (simplified version)
                HeaderV3B(
                    workerName: contextEngine.clientProfile?.name ?? "Client",
                    nextTaskName: nil,
                    showClockPill: false,
                    isNovaProcessing: novaEngine.processingState != .idle,
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
                
                // Map Container - Smaller height to save space
                MapRevealContainer(
                    buildings: contextEngine.clientBuildings,
                    currentBuildingId: selectedBuilding?.id,
                    focusBuildingId: selectedBuilding?.id,
                    onBuildingTap: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                    }
                )
                .frame(height: 180) // Fixed height for map
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Real-time Hero Status Card - Using CoreTypes
                ClientHeroStatusCard(
                    routineMetrics: realtimeRoutineMetrics,
                    activeWorkers: activeWorkerStatus,
                    complianceStatus: complianceStatus,
                    monthlyMetrics: monthlyMetrics,
                    onBuildingTap: { building in
                        selectedBuilding = building
                        showBuildingDetail = true
                    }
                )
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                Spacer(minLength: 0)
                
                // Intelligence Preview Panel - Always visible
                if !getClientInsights().isEmpty {
                    IntelligencePreviewPanel(
                        insights: getClientInsights(),
                        displayMode: .compact,
                        onNavigate: { target in
                            handleIntelligenceNavigation(target)
                        },
                        contextEngine: contextEngine
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(FrancoSphereDesign.Animations.spring, value: hasImportantUpdates)
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
                ClientBuildingDetailView(building: building)
                    .onAppear { currentContext = .buildingDetail }
                    .onDisappear {
                        currentContext = .dashboard
                        Task { await contextEngine.refreshContext() }
                    }
            }
        }
        .sheet(isPresented: $showMainMenu) {
            ClientMainMenuView()
                .presentationDetents([.medium])
        }
        .refreshable {
            await viewModel.refreshData()
            refreshID = UUID()
        }
        .task {
            await loadInitialData()
        }
        .onReceive(contextEngine.$realtimeRoutineMetrics) { metrics in
            self.realtimeRoutineMetrics = metrics
        }
        .onReceive(contextEngine.$activeWorkerStatus) { status in
            self.activeWorkerStatus = status
        }
        .onReceive(contextEngine.$complianceOverview) { overview in
            self.complianceStatus = overview
        }
        .onReceive(contextEngine.$monthlyMetrics) { metrics in
            self.monthlyMetrics = metrics
        }
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        await viewModel.loadPortfolioIntelligence()
        await contextEngine.refreshContext()
        
        // Update local state from context engine
        if contextEngine.realtimeRoutineMetrics.buildingStatuses.count > 0 {
            realtimeRoutineMetrics = contextEngine.realtimeRoutineMetrics
        }
        if contextEngine.activeWorkerStatus.totalActive > 0 {
            activeWorkerStatus = contextEngine.activeWorkerStatus
        }
        if contextEngine.complianceOverview.overallScore > 0 {
            complianceStatus = contextEngine.complianceOverview
        }
        if contextEngine.monthlyMetrics.monthlyBudget > 0 {
            monthlyMetrics = contextEngine.monthlyMetrics
        }
    }
    
    // MARK: - Intelligence Methods
    
    private func getClientInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Behind schedule buildings
        let behindSchedule = realtimeRoutineMetrics.buildingStatuses
            .filter { $0.value.isBehindSchedule }
        
        if !behindSchedule.isEmpty {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "\(behindSchedule.count) properties behind schedule",
                description: "Service delays detected at \(behindSchedule.compactMap { contextEngine.buildingName(for: $0.key) }.joined(separator: ", "))",
                type: .operational,
                priority: .high,
                actionRequired: true,
                recommendedAction: "Contact operations team",
                affectedBuildings: Array(behindSchedule.keys)
            ))
        }
        
        // Compliance issues
        if complianceStatus.criticalViolations > 0 {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Compliance violations detected",
                description: "\(complianceStatus.criticalViolations) critical violations require immediate attention",
                type: .compliance,
                priority: .critical,
                actionRequired: true,
                recommendedAction: "View compliance report",
                affectedBuildings: contextEngine.buildingsWithComplianceIssues
            ))
        }
        
        // Budget alerts
        if monthlyMetrics.isOverBudget {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "Monthly spending over budget",
                description: String(format: "Current spending is %.0f%% of budget", monthlyMetrics.budgetUtilization * 100),
                type: .cost,
                priority: .medium,
                actionRequired: false,
                recommendedAction: "Review cost analysis"
            ))
        }
        
        // No workers on site warning
        let buildingsWithoutWorkers = realtimeRoutineMetrics.buildingStatuses
            .filter { $0.value.activeWorkerCount == 0 && $0.value.completionRate < 1.0 }
        
        if !buildingsWithoutWorkers.isEmpty && isWorkingHours() {
            insights.append(CoreTypes.IntelligenceInsight(
                id: UUID().uuidString,
                title: "No workers on site",
                description: "\(buildingsWithoutWorkers.count) properties have no active workers",
                type: .operational,
                priority: .high,
                actionRequired: true,
                recommendedAction: "Check worker assignments"
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        switch target {
        case .buildingDetail(let id):
            if let building = contextEngine.clientBuildings.first(where: { $0.id == id }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
        case .compliance:
            // Show compliance in building detail
            if let buildingId = contextEngine.buildingsWithComplianceIssues.first,
               let building = contextEngine.clientBuildings.first(where: { $0.id == buildingId }) {
                selectedBuilding = building
                showBuildingDetail = true
            }
        case .fullInsights:
            showNovaAssistant = true
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleNovaQuickAction() {
        showNovaAssistant = true
    }
    
    private func isWorkingHours() -> Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 7 && hour <= 18 // 7 AM to 6 PM
    }
}

// MARK: - Enhanced Client Context Engine Extension
// This extension only adds computed properties, no stored properties

extension ClientContextEngine {
    // These computed properties work with the @Published properties in ClientContextEngine
    
    var hasActiveIssues: Bool {
        realtimeRoutineMetrics.hasActiveIssues
    }
    
    var hasBehindScheduleBuildings: Bool {
        realtimeRoutineMetrics.buildingStatuses.contains { $0.value.isBehindSchedule }
    }
    
    var hasComplianceIssues: Bool {
        complianceOverview.criticalViolations > 0 || complianceOverview.overallScore < 0.8
    }
    
    var buildingsWithComplianceIssues: [String] {
        // Return building IDs with compliance issues
        clientComplianceData.compactMap { $0.value.score < 0.8 ? $0.key : nil }
    }
    
    func buildingName(for id: String) -> String? {
        clientBuildings.first { $0.id == id }?.name
    }
}

// MARK: - Client Hero Status Card Component
// This should be in a separate file normally, but including here for completeness

struct ClientHeroStatusCard: View {
    let routineMetrics: CoreTypes.RealtimeRoutineMetrics
    let activeWorkers: CoreTypes.ActiveWorkerStatus
    let complianceStatus: CoreTypes.ComplianceOverview
    let monthlyMetrics: CoreTypes.MonthlyMetrics
    let onBuildingTap: (CoreTypes.NamedCoordinate) -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Main metrics row
            HStack(spacing: 16) {
                // Completion metric
                MetricCard(
                    title: "Today's Progress",
                    value: String(format: "%.0f%%", routineMetrics.overallCompletion * 100),
                    subtitle: "\(routineMetrics.activeWorkerCount) workers active",
                    color: .green
                )
                
                // Compliance metric
                MetricCard(
                    title: "Compliance",
                    value: String(format: "%.0f%%", complianceStatus.overallScore * 100),
                    subtitle: complianceStatus.criticalViolations > 0 ?
                        "\(complianceStatus.criticalViolations) violations" : "All clear",
                    color: complianceStatus.criticalViolations > 0 ? .red : .blue
                )
            }
            
            // Budget metric (if visible)
            if monthlyMetrics.monthlyBudget > 0 {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.green)
                    Text(String(format: "$%.0f / $%.0f",
                               monthlyMetrics.currentSpend,
                               monthlyMetrics.monthlyBudget))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(monthlyMetrics.daysRemaining) days left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Behind schedule alert (if any)
            if routineMetrics.behindScheduleCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(routineMetrics.behindScheduleCount) buildings behind schedule")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Metric Card Component
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
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
