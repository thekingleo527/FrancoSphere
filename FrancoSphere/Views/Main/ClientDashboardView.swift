//
//  ClientDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
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
    @StateObject private var novaEngine = NovaIntelligenceEngine.shared
    
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
    
    // MOVED FROM EXTENSION - These properties need to be in the main struct
    @State private var realtimeRoutineMetrics = RealtimeRoutineMetrics()
    @State private var activeWorkerStatus = ActiveWorkerStatus(
        totalActive: 0,
        byBuilding: [:],
        utilizationRate: 0.0
    )
    @State private var complianceStatus = ComplianceStatus(
        overallScore: 0.85,
        criticalViolations: 0,
        pendingInspections: 0,
        lastUpdated: Date()
    )
    @State private var monthlyMetrics = MonthlyMetrics(
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
                
                // Real-time Hero Status Card - Using local state properties
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
        .onReceive(contextEngine.$complianceStatus) { status in
            self.complianceStatus = status
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
        if contextEngine.complianceStatus.overallScore > 0 {
            complianceStatus = contextEngine.complianceStatus
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
        
        return insights.sorted { $0.priority.rawValue > $1.priority.rawValue }
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
// Note: This extension adds computed properties only, no stored properties

extension ClientContextEngine {
    // These are now @Published properties in the actual ClientContextEngine class
    // We're just adding computed properties here
    
    var hasActiveIssues: Bool {
        realtimeRoutineMetrics.hasActiveIssues
    }
    
    var hasBehindScheduleBuildings: Bool {
        realtimeRoutineMetrics.buildingStatuses.contains { $0.value.isBehindSchedule }
    }
    
    var hasComplianceIssues: Bool {
        complianceStatus.criticalViolations > 0 || complianceStatus.overallScore < 0.8
    }
    
    var buildingsWithComplianceIssues: [String] {
        // Return building IDs with compliance issues
        clientComplianceData.compactMap { $0.value.score < 0.8 ? $0.key : nil }
    }
    
    func buildingName(for id: String) -> String? {
        clientBuildings.first { $0.id == id }?.name
    }
}

// MARK: - Data Models

struct RealtimeRoutineMetrics {
    var overallCompletion: Double = 0.0
    var activeWorkerCount: Int = 0
    var behindScheduleCount: Int = 0
    var buildingStatuses: [String: BuildingRoutineStatus] = [:]
    
    var hasActiveIssues: Bool {
        behindScheduleCount > 0 || buildingStatuses.contains { $0.value.hasIssue }
    }
}

// Note: Removed duplicate BuildingRoutineStatus - it should only be declared once
struct BuildingRoutineStatus {
    let buildingId: String
    let buildingName: String
    let completionRate: Double
    let timeBlock: TimeBlock
    let activeWorkerCount: Int
    let isOnSchedule: Bool
    let estimatedCompletion: Date?
    let hasIssue: Bool
    
    var isBehindSchedule: Bool {
        !isOnSchedule && completionRate < expectedCompletionForTime()
    }
    
    private func expectedCompletionForTime() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 7..<11: return 0.3  // Morning should be 30% done
        case 11..<15: return 0.6 // Afternoon should be 60% done
        case 15..<19: return 0.9 // Evening should be 90% done
        default: return 1.0
        }
    }
    
    enum TimeBlock {
        case morning, afternoon, evening, overnight
        
        static var current: TimeBlock {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 6..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<22: return .evening
            default: return .overnight
            }
        }
    }
}

struct ActiveWorkerStatus {
    let totalActive: Int
    let byBuilding: [String: Int]
    let utilizationRate: Double
    
    init(totalActive: Int = 0, byBuilding: [String: Int] = [:], utilizationRate: Double = 0.0) {
        self.totalActive = totalActive
        self.byBuilding = byBuilding
        self.utilizationRate = utilizationRate
    }
}

// Note: Using the existing ComplianceStatus from CoreTypes if it exists
// If not, this is the local definition
struct ComplianceStatus {
    let overallScore: Double
    let criticalViolations: Int
    let pendingInspections: Int
    let lastUpdated: Date
    
    init(overallScore: Double = 0.85,
         criticalViolations: Int = 0,
         pendingInspections: Int = 0,
         lastUpdated: Date = Date()) {
        self.overallScore = overallScore
        self.criticalViolations = criticalViolations
        self.pendingInspections = pendingInspections
        self.lastUpdated = lastUpdated
    }
}

struct MonthlyMetrics {
    let currentSpend: Double
    let monthlyBudget: Double
    let projectedSpend: Double
    let daysRemaining: Int
    
    init(currentSpend: Double = 0,
         monthlyBudget: Double = 10000,
         projectedSpend: Double = 0,
         daysRemaining: Int = 30) {
        self.currentSpend = currentSpend
        self.monthlyBudget = monthlyBudget
        self.projectedSpend = projectedSpend
        self.daysRemaining = daysRemaining
    }
    
    var budgetUtilization: Double {
        guard monthlyBudget > 0 else { return 0 }
        return currentSpend / monthlyBudget
    }
    
    var isOverBudget: Bool {
        projectedSpend > monthlyBudget
    }
    
    var dailyBurnRate: Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let daysPassed = daysInMonth - daysRemaining
        return daysPassed > 0 ? currentSpend / Double(daysPassed) : 0
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
