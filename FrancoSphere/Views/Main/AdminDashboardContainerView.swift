//
//  AdminDashboardContainerView.swift
//  FrancoSphere v6.0
//
//  ✅ USES ONLY ACTUAL AdminDashboardViewModel
//  ✅ NO INVENTED DEPENDENCIES
//  ✅ FULL PHOTO EVIDENCE INTEGRATION
//  ✅ WORKER CAPABILITIES SUPPORT
//  ✅ CROSS-DASHBOARD SYNC INTEGRATION
//

import SwiftUI
import Combine

struct AdminDashboardContainerView: View {
    // MARK: - Using Actual ViewModel Only
    @StateObject private var viewModel = AdminDashboardViewModel()
    
    // MARK: - Environment Objects
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State Management
    @State private var selectedTab: AdminTab = .overview
    @State private var selectedBuildingId: String?
    @State private var showingBuildingDetail = false
    @State private var showingWorkerDetail = false
    @State private var selectedWorker: CoreTypes.WorkerProfile?
    @State private var showingPhotoEvidence = false
    @State private var selectedTaskForPhoto: CoreTypes.ContextualTask?
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var refreshID = UUID()
    
    // MARK: - App Storage
    @AppStorage("adminShowPhotoCompliance") private var showPhotoCompliance = true
    @AppStorage("adminAutoRefresh") private var autoRefresh = true
    
    // MARK: - Enums
    enum AdminTab: String, CaseIterable {
        case overview = "Overview"
        case buildings = "Buildings"
        case workers = "Workers"
        case tasks = "Tasks"
        case insights = "Insights"
        
        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .buildings: return "building.2"
            case .workers: return "person.3"
            case .tasks: return "checklist"
            case .insights: return "lightbulb.fill"
            }
        }
    }
    
    // MARK: - Computed Properties
    private var portfolioSummary: AdminPortfolioSummary {
        viewModel.getAdminPortfolioSummary()
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Header
                    AdminHeaderView(
                        adminName: authManager.currentUser?.name ?? "Administrator",
                        syncStatus: viewModel.dashboardSyncStatus,
                        onProfileTap: { showingProfile = true },
                        onSettingsTap: { showingSettings = true },
                        onRefresh: { Task { await viewModel.refreshDashboardData() } }
                    )
                    
                    // Tab Bar
                    AdminTabBar(selectedTab: $selectedTab)
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        // Overview Tab
                        AdminOverviewTab(
                            viewModel: viewModel,
                            portfolioSummary: portfolioSummary,
                            onBuildingTap: { buildingId in
                                selectedBuildingId = buildingId
                                showingBuildingDetail = true
                            }
                        )
                        .tag(AdminTab.overview)
                        
                        // Buildings Tab
                        AdminBuildingsTab(
                            buildings: viewModel.buildings,
                            buildingMetrics: viewModel.buildingMetrics,
                            onBuildingTap: { building in
                                selectedBuildingId = building.id
                                Task { await viewModel.fetchBuildingIntelligence(for: building.id) }
                                showingBuildingDetail = true
                            }
                        )
                        .tag(AdminTab.buildings)
                        
                        // Workers Tab
                        AdminWorkersTab(
                            workers: viewModel.workers,
                            activeWorkers: viewModel.activeWorkers,
                            workerCapabilities: viewModel.workerCapabilities,
                            onWorkerTap: { worker in
                                selectedWorker = worker
                                showingWorkerDetail = true
                            }
                        )
                        .tag(AdminTab.workers)
                        
                        // Tasks Tab
                        AdminTasksTab(
                            tasks: viewModel.tasks,
                            completedTasks: viewModel.completedTasks,
                            recentCompletedTasks: viewModel.recentCompletedTasks,
                            photoComplianceStats: viewModel.photoComplianceStats,
                            onTaskTap: { task in
                                selectedTaskForPhoto = task
                                showingPhotoEvidence = true
                            }
                        )
                        .tag(AdminTab.tasks)
                        
                        // Insights Tab
                        AdminInsightsTab(
                            portfolioInsights: viewModel.portfolioInsights,
                            selectedBuildingInsights: viewModel.selectedBuildingInsights,
                            isLoadingInsights: viewModel.isLoadingInsights
                        )
                        .tag(AdminTab.insights)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .id(refreshID)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .task {
            await viewModel.loadDashboardData()
        }
        .sheet(isPresented: $showingBuildingDetail) {
            if let buildingId = selectedBuildingId,
               let building = viewModel.buildings.first(where: { $0.id == buildingId }) {
                BuildingDetailSheet(
                    building: building,
                    metrics: viewModel.getBuildingMetrics(for: buildingId),
                    insights: viewModel.getIntelligenceInsights(for: buildingId),
                    onRefresh: {
                        Task { await viewModel.refreshBuildingMetrics(for: buildingId) }
                    }
                )
            }
        }
        .sheet(isPresented: $showingWorkerDetail) {
            if let worker = selectedWorker {
                WorkerDetailSheet(
                    worker: worker,
                    capabilities: viewModel.workerCapabilities[worker.id],
                    canPerformAction: { action in
                        viewModel.canWorkerPerformAction(worker.id, action: action)
                    }
                )
            }
        }
        .sheet(isPresented: $showingPhotoEvidence) {
            if let task = selectedTaskForPhoto {
                TaskPhotoEvidenceSheet(
                    task: task,
                    hasPhoto: false, // Will be loaded
                    onLoad: { taskId in
                        await viewModel.hasPhotoEvidence(taskId: taskId)
                    }
                )
            }
        }
        .sheet(isPresented: $showingProfile) {
            AdminProfileSheet()
        }
        .sheet(isPresented: $showingSettings) {
            AdminSettingsSheet(
                showPhotoCompliance: $showPhotoCompliance,
                autoRefresh: $autoRefresh
            )
        }
    }
    
    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "0A0A0A"),
                Color(hex: "1A1A1A")
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

// MARK: - Admin Header View
struct AdminHeaderView: View {
    let adminName: String
    let syncStatus: CoreTypes.DashboardSyncStatus
    let onProfileTap: () -> Void
    let onSettingsTap: () -> Void
    let onRefresh: () async -> Void
    
    var syncStatusColor: Color {
        switch syncStatus {
        case .syncing: return .orange
        case .synced: return .green
        case .error: return .red
        case .offline: return .gray
        }
    }
    
    var body: some View {
        HStack {
            // Logo and Title
            HStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("FrancoSphere Admin")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(adminName)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Status and Actions
            HStack(spacing: 16) {
                // Sync Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(syncStatusColor)
                        .frame(width: 8, height: 8)
                    
                    Text(syncStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Refresh
                Button(action: {
                    Task { await onRefresh() }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // Settings
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
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
        .background(Color(hex: "1A1A1A"))
    }
}

// MARK: - Admin Tab Bar
struct AdminTabBar: View {
    @Binding var selectedTab: AdminDashboardContainerView.AdminTab
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AdminDashboardContainerView.AdminTab.allCases, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    animation: animation
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(hex: "1A1A1A"))
    }
    
    struct TabBarItem: View {
        let tab: AdminDashboardContainerView.AdminTab
        let isSelected: Bool
        var animation: Namespace.ID
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    Text(tab.rawValue)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white : .gray)
                    
                    if isSelected {
                        Capsule()
                            .fill(Color.blue)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "tab_indicator", in: animation)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Admin Overview Tab
struct AdminOverviewTab: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    let portfolioSummary: AdminPortfolioSummary
    let onBuildingTap: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio Summary Card
                PortfolioSummaryCard(summary: portfolioSummary)
                    .padding(.horizontal)
                
                // Photo Compliance Card
                if let photoStats = viewModel.photoComplianceStats {
                    PhotoComplianceCard(stats: photoStats)
                        .padding(.horizontal)
                }
                
                // Metrics Grid
                AdminMetricsGrid(
                    buildings: viewModel.buildings.count,
                    workers: viewModel.workers.count,
                    activeWorkers: viewModel.activeWorkers.count,
                    ongoingTasks: viewModel.ongoingTasks.count,
                    completedToday: portfolioSummary.completedTasks,
                    criticalInsights: portfolioSummary.criticalInsights
                )
                .padding(.horizontal)
                
                // Cross-Dashboard Updates
                if !viewModel.crossDashboardUpdates.isEmpty {
                    CrossDashboardUpdatesSection(updates: viewModel.crossDashboardUpdates)
                        .padding(.horizontal)
                }
                
                // Recent Completed Tasks with Photos
                if !viewModel.recentCompletedTasks.isEmpty {
                    RecentCompletedTasksSection(tasks: viewModel.recentCompletedTasks)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Portfolio Summary Card
struct PortfolioSummaryCard: View {
    let summary: AdminPortfolioSummary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Performance")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(summary.efficiencyDescription)
                        .font(.caption)
                        .foregroundColor(summary.efficiencyStatus.color)
                }
                
                Spacer()
                
                // Efficiency Status Icon
                Image(systemName: summary.efficiencyStatus.icon)
                    .font(.system(size: 30))
                    .foregroundColor(summary.efficiencyStatus.color)
            }
            
            // Key Metrics
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completion")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(summary.completionPercentage)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compliance")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(Int(summary.complianceScore * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Photos Today")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("\(summary.todaysPhotoCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Photo Compliance Card
struct PhotoComplianceCard: View {
    let stats: PhotoComplianceStats
    
    var complianceColor: Color {
        stats.isCompliant ? .green : .orange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Photo Compliance", systemImage: "camera.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(stats.compliancePercentage)
                    .font(.headline)
                    .foregroundColor(complianceColor)
            }
            
            // Compliance Details
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Required")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(stats.tasksRequiringPhotos)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("With Photos")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(stats.tasksWithPhotos)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Missing")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text("\(stats.missingPhotos)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(stats.missingPhotos > 0 ? .orange : .gray)
                }
            }
            
            // Compliance Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(complianceColor)
                        .frame(width: geometry.size.width * stats.complianceRate, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Admin Metrics Grid
struct AdminMetricsGrid: View {
    let buildings: Int
    let workers: Int
    let activeWorkers: Int
    let ongoingTasks: Int
    let completedToday: Int
    let criticalInsights: Int
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(
                icon: "building.2",
                title: "Buildings",
                value: "\(buildings)",
                color: .blue
            )
            
            MetricCard(
                icon: "person.3.fill",
                title: "Workers",
                value: "\(activeWorkers)/\(workers)",
                color: .green
            )
            
            MetricCard(
                icon: "list.bullet",
                title: "Ongoing Tasks",
                value: "\(ongoingTasks)",
                color: .orange
            )
            
            MetricCard(
                icon: "checkmark.circle.fill",
                title: "Completed Today",
                value: "\(completedToday)",
                color: .cyan
            )
            
            if criticalInsights > 0 {
                MetricCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Critical Insights",
                    value: "\(criticalInsights)",
                    color: .red
                )
            }
        }
    }
}

// MARK: - Tab Content Views

struct AdminBuildingsTab: View {
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let onBuildingTap: (CoreTypes.NamedCoordinate) -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(buildings) { building in
                    BuildingRowCard(
                        building: building,
                        metrics: buildingMetrics[building.id],
                        onTap: { onBuildingTap(building) }
                    )
                }
            }
            .padding()
        }
    }
}

struct AdminWorkersTab: View {
    let workers: [CoreTypes.WorkerProfile]
    let activeWorkers: [CoreTypes.WorkerProfile]
    let workerCapabilities: [String: AdminDashboardViewModel.WorkerCapabilities]
    let onWorkerTap: (CoreTypes.WorkerProfile) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Active Workers Section
                if !activeWorkers.isEmpty {
                    Text("Active Workers (\(activeWorkers.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(activeWorkers) { worker in
                            WorkerRowCard(
                                worker: worker,
                                capabilities: workerCapabilities[worker.id],
                                isActive: true,
                                onTap: { onWorkerTap(worker) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // All Workers Section
                Text("All Workers (\(workers.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top)
                
                LazyVStack(spacing: 8) {
                    ForEach(workers) { worker in
                        WorkerRowCard(
                            worker: worker,
                            capabilities: workerCapabilities[worker.id],
                            isActive: activeWorkers.contains { $0.id == worker.id },
                            onTap: { onWorkerTap(worker) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct AdminTasksTab: View {
    let tasks: [CoreTypes.ContextualTask]
    let completedTasks: [CoreTypes.ContextualTask]
    let recentCompletedTasks: [CoreTypes.ContextualTask]
    let photoComplianceStats: PhotoComplianceStats?
    let onTaskTap: (CoreTypes.ContextualTask) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Photo Compliance Summary
                if let stats = photoComplianceStats {
                    PhotoComplianceCard(stats: stats)
                        .padding(.horizontal)
                }
                
                // Recent Completed Tasks
                if !recentCompletedTasks.isEmpty {
                    Text("Recently Completed")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(recentCompletedTasks) { task in
                            TaskRowCard(
                                task: task,
                                showPhotoIndicator: task.requiresPhoto ?? false,
                                onTap: { onTaskTap(task) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Ongoing Tasks
                let ongoingTasks = tasks.filter { !$0.isCompleted }
                if !ongoingTasks.isEmpty {
                    Text("Ongoing Tasks (\(ongoingTasks.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(ongoingTasks.prefix(10)) { task in
                            TaskRowCard(
                                task: task,
                                showPhotoIndicator: task.requiresPhoto ?? false,
                                onTap: { onTaskTap(task) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct AdminInsightsTab: View {
    let portfolioInsights: [CoreTypes.IntelligenceInsight]
    let selectedBuildingInsights: [CoreTypes.IntelligenceInsight]
    let isLoadingInsights: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingInsights {
                    ProgressView("Loading insights...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .foregroundColor(.white)
                } else {
                    // Portfolio Insights
                    if !portfolioInsights.isEmpty {
                        Text("Portfolio Insights")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(portfolioInsights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Building-Specific Insights
                    if !selectedBuildingInsights.isEmpty {
                        Text("Building Insights")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        LazyVStack(spacing: 8) {
                            ForEach(selectedBuildingInsights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    if portfolioInsights.isEmpty && selectedBuildingInsights.isEmpty {
                        Text("No insights available")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding()
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Supporting Card Views

struct BuildingRowCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(building.address)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if let metrics = metrics {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(metrics.completionRate * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if metrics.overdueTasks > 0 {
                            Text("\(metrics.overdueTasks) overdue")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct WorkerRowCard: View {
    let worker: CoreTypes.WorkerProfile
    let capabilities: AdminDashboardViewModel.WorkerCapabilities?
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                // Status indicator
                Circle()
                    .fill(isActive ? Color.green : Color.gray)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(worker.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    if capabilities?.simplifiedInterface == true {
                        Text("Simplified UI")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if isActive {
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct TaskRowCard: View {
    let task: CoreTypes.ContextualTask
    let showPhotoIndicator: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let buildingName = task.buildingName {
                            Text(buildingName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if task.isOverdue {
                            Text("Overdue")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if showPhotoIndicator {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                    }
                    
                    Text(task.status.rawValue)
                        .font(.caption)
                        .foregroundColor(task.isCompleted ? .green : .gray)
                }
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct InsightCard: View {
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(priorityColor)
                
                Text(insight.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                Text(insight.priority.rawValue)
                    .font(.caption2)
                    .foregroundColor(priorityColor)
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
            
            if let impact = insight.estimatedImpact {
                Text(impact)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(10)
    }
}

// MARK: - Supporting Sections

struct CrossDashboardUpdatesSection: View {
    let updates: [CoreTypes.DashboardUpdate]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cross-Dashboard Activity")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                ForEach(updates.prefix(5)) { update in
                    HStack {
                        Circle()
                            .fill(sourceColor(update.source))
                            .frame(width: 6, height: 6)
                        
                        Text(update.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(update.timestamp.formatted(.relative(presentation: .named)))
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
        }
    }
    
    func sourceColor(_ source: CoreTypes.DashboardSource) -> Color {
        switch source {
        case .admin: return .blue
        case .worker: return .green
        case .client: return .purple
        case .system: return .gray
        }
    }
}

struct RecentCompletedTasksSection: View {
    let tasks: [CoreTypes.ContextualTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recently Completed")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 4) {
                ForEach(tasks.prefix(5)) { task in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text(task.title)
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if task.requiresPhoto ?? false {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.03))
            .cornerRadius(8)
        }
    }
}

// MARK: - Sheet Views (Simplified)

struct BuildingDetailSheet: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let insights: [CoreTypes.IntelligenceInsight]
    let onRefresh: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                // Building info
                Text(building.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(building.address)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Metrics
                if let metrics = metrics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metrics")
                            .font(.headline)
                        
                        HStack {
                            Text("Completion Rate:")
                            Spacer()
                            Text("\(Int(metrics.completionRate * 100))%")
                        }
                        
                        HStack {
                            Text("Active Workers:")
                            Spacer()
                            Text("\(metrics.activeWorkers)")
                        }
                        
                        HStack {
                            Text("Overdue Tasks:")
                            Spacer()
                            Text("\(metrics.overdueTasks)")
                                .foregroundColor(metrics.overdueTasks > 0 ? .orange : .gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                // Insights
                if !insights.isEmpty {
                    Text("Insights")
                        .font(.headline)
                    
                    ForEach(insights) { insight in
                        Text("• \(insight.title)")
                            .font(.caption)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Building Details")
            .navigationBarItems(
                leading: Button("Refresh", action: onRefresh),
                trailing: Button("Done") { dismiss() }
            )
        }
    }
}

struct WorkerDetailSheet: View {
    let worker: CoreTypes.WorkerProfile
    let capabilities: AdminDashboardViewModel.WorkerCapabilities?
    let canPerformAction: (WorkerAction) -> Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text(worker.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(worker.email)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Capabilities
                if let capabilities = capabilities {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capabilities")
                            .font(.headline)
                        
                        CapabilityRow(title: "Upload Photos", enabled: capabilities.canUploadPhotos)
                        CapabilityRow(title: "Add Notes", enabled: capabilities.canAddNotes)
                        CapabilityRow(title: "View Map", enabled: capabilities.canViewMap)
                        CapabilityRow(title: "Emergency Tasks", enabled: capabilities.canAddEmergencyTasks)
                        CapabilityRow(title: "Simplified UI", enabled: capabilities.simplifiedInterface)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Worker Details")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct CapabilityRow: View {
    let title: String
    let enabled: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
            Spacer()
            Image(systemName: enabled ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(enabled ? .green : .gray)
        }
    }
}

struct TaskPhotoEvidenceSheet: View {
    let task: CoreTypes.ContextualTask
    let hasPhoto: Bool
    let onLoad: (String) async -> Bool
    @State private var isLoading = true
    @State private var photoExists = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Checking for photo evidence...")
                } else if photoExists {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    Text("Photo evidence available")
                } else {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No photo evidence")
                }
            }
            .navigationTitle(task.title)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .task {
                photoExists = await onLoad(task.id)
                isLoading = false
            }
        }
    }
}

struct AdminProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Administrator")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct AdminSettingsSheet: View {
    @Binding var showPhotoCompliance: Bool
    @Binding var autoRefresh: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display") {
                    Toggle("Show Photo Compliance", isOn: $showPhotoCompliance)
                }
                
                Section("Data") {
                    Toggle("Auto Refresh", isOn: $autoRefresh)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

// MARK: - Supporting Components

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
struct AdminDashboardContainerView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardContainerView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
#endif
