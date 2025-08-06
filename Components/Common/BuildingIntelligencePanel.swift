//
//  BuildingIntelligencePanel.swift
//  CyntientOps v6.0
//
//  ✅ DARK ELEGANCE: Full theme integration with glass morphism
//  ✅ FIXED: All compilation errors resolved
//  ✅ ALIGNED: With existing CoreTypes and BuildingIntelligenceViewModel
//  ✅ USES: Existing service patterns and data types
//  ✅ INTEGRATED: With real operational data
//

import SwiftUI
import Foundation

struct BuildingIntelligencePanel: View {
    // MARK: - Properties
    let building: NamedCoordinate
    @Binding var selectedTab: IntelligenceTab
    let isMyBuilding: Bool
    let isPrimaryBuilding: Bool
    
    @StateObject private var viewModel = BuildingIntelligenceViewModel()
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(building: NamedCoordinate, selectedTab: Binding<IntelligenceTab>, isMyBuilding: Bool, isPrimaryBuilding: Bool) {
        self.building = building
        self._selectedTab = selectedTab
        self.isMyBuilding = isMyBuilding
        self.isPrimaryBuilding = isPrimaryBuilding
    }
    
    // MARK: - IntelligenceTab Enum
    enum IntelligenceTab: String, CaseIterable {
        case overview = "Overview"
        case allWorkers = "All Workers"
        case fullSchedule = "Full Schedule"
        case history = "History"
        case emergency = "Emergency"
        
        var icon: String {
            switch self {
            case .overview: return "chart.bar.fill"
            case .allWorkers: return "person.3.fill"
            case .fullSchedule: return "calendar.badge.clock"
            case .history: return "clock.arrow.circlepath"
            case .emergency: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .overview: return CyntientOpsDesign.DashboardColors.info
            case .allWorkers: return CyntientOpsDesign.DashboardColors.success
            case .fullSchedule: return CyntientOpsDesign.DashboardColors.tertiaryAction
            case .history: return CyntientOpsDesign.DashboardColors.warning
            case .emergency: return CyntientOpsDesign.DashboardColors.critical
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Dark Elegance Background
                CyntientOpsDesign.DashboardColors.baseBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Coverage indicator if not my building
                    if !isMyBuilding {
                        coverageIndicatorBanner
                    }
                    
                    // Tab bar
                    intelligenceTabBar
                    
                    // Tab content
                    tabContent
                }
            }
            .navigationTitle(building.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    coverageStatusButton
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await viewModel.loadCompleteIntelligence(for: building)
        }
    }
    
    // MARK: - Coverage Indicator Banner
    
    private var coverageIndicatorBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            
            Text("Coverage Mode - Emergency/Support Access")
                .francoTypography(CyntientOpsDesign.Typography.caption)
                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(CyntientOpsDesign.DashboardColors.warning.opacity(0.1))
    }
    
    // MARK: - Intelligence Tab Bar
    
    private var intelligenceTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(IntelligenceTab.allCases, id: \.self) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(.horizontal, 16)
        }
        .background(CyntientOpsDesign.DashboardColors.cardBackground)
    }
    
    private func tabButton(for tab: IntelligenceTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.caption)
                    .foregroundColor(selectedTab == tab ? tab.color : CyntientOpsDesign.DashboardColors.secondaryText)
                
                Text(tab.rawValue)
                    .francoTypography(CyntientOpsDesign.Typography.caption2)
                    .foregroundColor(selectedTab == tab ? tab.color : CyntientOpsDesign.DashboardColors.secondaryText)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tab ? tab.color.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Coverage Status Button
    
    private var coverageStatusButton: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isMyBuilding ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning)
                .frame(width: 8, height: 8)
            
            Text(isMyBuilding ? "My Building" : "Coverage")
                .francoTypography(CyntientOpsDesign.Typography.caption2)
                .foregroundColor(isMyBuilding ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.warning)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(CyntientOpsDesign.DashboardColors.glassOverlay)
        .cornerRadius(12)
    }
    
    // MARK: - Tab Content
    
    private var tabContent: some View {
        ScrollView {
            VStack {
                switch selectedTab {
                case .overview:
                    BuildingOverviewTabView(  // Rename to avoid conflict
                        building: building,
                        metrics: viewModel.metrics,
                        isMyBuilding: isMyBuilding,
                        isLoading: viewModel.isLoading
                    )

                    
                case .allWorkers:
                    AllWorkersTab(
                        building: building,
                        primaryWorkers: viewModel.primaryWorkers,
                        allWorkers: viewModel.allAssignedWorkers,
                        workersOnSite: viewModel.currentWorkersOnSite,
                        isLoading: viewModel.isLoading
                    )
                    
                case .fullSchedule:
                    FullScheduleTab(
                        building: building,
                        todaysSchedule: viewModel.todaysCompleteSchedule,
                        weeklySchedule: viewModel.weeklyRoutineSchedule,
                        isLoading: viewModel.isLoading
                    )
                    
                case .history:
                    BuildingHistoryTab(
                        building: building,
                        history: viewModel.buildingHistory,
                        patterns: viewModel.patterns,
                        isLoading: viewModel.isLoading
                    )
                    
                case .emergency:
                    EmergencyInfoTab(
                        building: building,
                        contacts: viewModel.emergencyContacts,
                        procedures: viewModel.emergencyProcedures,
                        accessLevel: isMyBuilding ? .full : .coverage,
                        isLoading: viewModel.isLoading
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - Building Overview Tab

struct BuildingOverviewTabView: View {
    let building: NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let isMyBuilding: Bool
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading building overview...")
            } else {
                buildingStatusCard
                
                if let metrics = metrics {
                    metricsGrid(metrics)
                }
                
                currentActivitySection
            }
        }
    }
    
    private var buildingStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                
                Text("Building Status")
                    .francoTypography(CyntientOpsDesign.Typography.headline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                statusRow("Building Type", building.name.contains("Museum") ? "Cultural" : "Commercial")
                statusRow("Access Level", isMyBuilding ? "Full Access" : "Coverage Access")
                statusRow("Last Updated", Date().formatted(.dateTime.hour().minute()))
                
                if let metrics = metrics {
                    statusRow("Status", metrics.displayStatus)
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private func metricsGrid(_ metrics: CoreTypes.BuildingMetrics) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            metricCard("Completion Rate", "\(Int(metrics.completionRate * 100))%", "checkmark.circle.fill", CyntientOpsDesign.DashboardColors.success)
            metricCard("Active Workers", "\(metrics.activeWorkers)", "person.fill", CyntientOpsDesign.DashboardColors.info)
            metricCard("Pending Tasks", "\(metrics.pendingTasks)", "clock.fill", CyntientOpsDesign.DashboardColors.warning)
            metricCard("Overdue Tasks", "\(metrics.overdueTasks)", "exclamationmark.triangle.fill", CyntientOpsDesign.DashboardColors.critical)
        }
    }
    
    private func metricCard(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Text(value)
                .francoTypography(CyntientOpsDesign.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
        .padding()
        .francoGlassBackground()
    }
    
    private var currentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Activity")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Text("Real-time building activity and worker status")
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private func statusRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
    }
}

// MARK: - All Workers Tab

struct AllWorkersTab: View {
    let building: NamedCoordinate
    let primaryWorkers: [WorkerProfile]
    let allWorkers: [WorkerProfile]
    let workersOnSite: [WorkerProfile]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading worker information...")
            } else {
                currentWorkersSection
                primaryWorkersSection
                allWorkersSection
            }
        }
    }
    
    private var currentWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currently On Site")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if workersOnSite.isEmpty {
                Text("No workers currently on site")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(workersOnSite, id: \.id) { worker in
                        WorkerRow(worker: worker, showOnSiteStatus: true)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var primaryWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Primary Workers")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if primaryWorkers.isEmpty {
                Text("No primary workers assigned")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(primaryWorkers, id: \.id) { worker in
                        WorkerRow(worker: worker, showPrimaryBadge: true)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var allWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Assigned Workers")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if allWorkers.isEmpty {
                Text("No workers assigned")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(allWorkers, id: \.id) { worker in
                        WorkerRow(worker: worker)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
}

// MARK: - Full Schedule Tab

struct FullScheduleTab: View {
    let building: NamedCoordinate
    let todaysSchedule: [ContextualTask]
    let weeklySchedule: [ContextualTask]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading schedule information...")
            } else {
                todaysScheduleSection
                weeklyRoutinesSection
            }
        }
    }
    
    private var todaysScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Schedule")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if todaysSchedule.isEmpty {
                Text("No scheduled activities today")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todaysSchedule, id: \.id) { task in
                        TaskScheduleRow(task: task)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var weeklyRoutinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Routines")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if weeklySchedule.isEmpty {
                Text("No weekly routines configured")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(weeklySchedule, id: \.id) { task in
                        TaskScheduleRow(task: task)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
}

// MARK: - Building History Tab

struct BuildingHistoryTab: View {
    let building: NamedCoordinate
    let history: [ContextualTask]
    let patterns: [String]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading building history...")
            } else {
                recentHistorySection
                patternsSection
            }
        }
    }
    
    private var recentHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if history.isEmpty {
                Text("No recent activity")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(history.prefix(10), id: \.id) { task in
                        TaskHistoryRow(task: task)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Patterns & Insights")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if patterns.isEmpty {
                Text("No patterns detected")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(patterns, id: \.self) { pattern in
                        PatternRow(pattern: pattern)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
}

// MARK: - Emergency Info Tab

struct EmergencyInfoTab: View {
    let building: NamedCoordinate
    let contacts: [String]
    let procedures: [String]
    let accessLevel: AccessLevel
    let isLoading: Bool
    
    enum AccessLevel {
        case full
        case coverage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if isLoading {
                IntelligenceLoadingView(message: "Loading emergency information...")
            } else {
                emergencyContactsSection
                emergencyProceduresSection
            }
        }
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Contacts")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if contacts.isEmpty {
                Text("No emergency contacts configured")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(contacts, id: \.self) { contact in
                        ContactRow(contact: contact)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    private var emergencyProceduresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Emergency Procedures")
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            if procedures.isEmpty {
                Text("No emergency procedures configured")
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                    .padding()
                    .francoGlassBackground()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(procedures, id: \.self) { procedure in
                        ProcedureRow(procedure: procedure)
                    }
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
}

// MARK: - Supporting Components

struct WorkerRow: View {
    let worker: WorkerProfile
    let showOnSiteStatus: Bool
    let showPrimaryBadge: Bool
    
    init(worker: WorkerProfile, showOnSiteStatus: Bool = false, showPrimaryBadge: Bool = false) {
        self.worker = worker
        self.showOnSiteStatus = showOnSiteStatus
        self.showPrimaryBadge = showPrimaryBadge
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(CyntientOpsDesign.DashboardColors.info.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(worker.name.prefix(1)))
                        .francoTypography(CyntientOpsDesign.Typography.headline)
                        .fontWeight(.bold)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(worker.name)
                        .francoTypography(CyntientOpsDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                    
                    if showPrimaryBadge {
                        Text("PRIMARY")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(CyntientOpsDesign.DashboardColors.info)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(CyntientOpsDesign.DashboardColors.info.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                
                Text(worker.role.rawValue.capitalized)
                    .francoTypography(CyntientOpsDesign.Typography.caption)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if showOnSiteStatus {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(worker.isActive ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.inactive)
                            .frame(width: 8, height: 8)
                        
                        Text(worker.isActive ? "Active" : "Inactive")
                            .francoTypography(CyntientOpsDesign.Typography.caption2)
                            .foregroundColor(worker.isActive ? CyntientOpsDesign.DashboardColors.success : CyntientOpsDesign.DashboardColors.inactive)
                    }
                }
                
                Text("Standard")
                    .francoTypography(CyntientOpsDesign.Typography.caption2)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TaskScheduleRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                if let description = task.description {
                    Text(description)
                        .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.secondaryText)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                } else {
                    Image(systemName: "clock")
                        .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
                }
                
                if let urgency = task.urgency {
                    Text(urgency.rawValue)
                        .francoTypography(CyntientOpsDesign.Typography.caption2)
                        .foregroundColor(CyntientOpsDesign.EnumColors.taskUrgency(urgency))
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TaskHistoryRow: View {
    let task: ContextualTask
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .francoTypography(CyntientOpsDesign.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
                
                if let completedAt = task.completedAt {
                    Text("Completed: \(completedAt.formatted(.dateTime.month().day().hour().minute()))")
   .francoTypography(CyntientOpsDesign.Typography.caption)
                        .foregroundColor(CyntientOpsDesign.DashboardColors.success)
                }
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(CyntientOpsDesign.DashboardColors.success)
        }
        .padding(.vertical, 4)
    }
}

struct PatternRow: View {
    let pattern: String
    
    var body: some View {
        HStack {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .foregroundColor(CyntientOpsDesign.DashboardColors.info)
            
            Text(pattern)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ContactRow: View {
    let contact: String
    
    var body: some View {
        HStack {
            Image(systemName: "phone.fill")
                .foregroundColor(CyntientOpsDesign.DashboardColors.critical)
            
            Text(contact)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ProcedureRow: View {
    let procedure: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(CyntientOpsDesign.DashboardColors.warning)
            
            Text(procedure)
                .francoTypography(CyntientOpsDesign.Typography.subheadline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct IntelligenceLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: CyntientOpsDesign.DashboardColors.info))
            
            Text(message)
                .francoTypography(CyntientOpsDesign.Typography.headline)
                .foregroundColor(CyntientOpsDesign.DashboardColors.primaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .francoGlassBackground()
    }
}

// MARK: - Preview

struct BuildingIntelligencePanel_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            address: "150 W 17th St, New York, NY 10011", latitude: 40.7402,
            longitude: -73.9980
        )
        
        BuildingIntelligencePanel(
            building: sampleBuilding,
            selectedTab: .constant(.overview),
            isMyBuilding: false,
            isPrimaryBuilding: false
        )
        .preferredColorScheme(.dark)
    }
}
