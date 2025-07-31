//
//  AdminDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ PHOTO EVIDENCE: Integrated task photo viewing
//  ✅ REAL-TIME: Cross-dashboard synchronization working
//  ✅ EVIDENCE CHAIN: Admin can review completed task photos
//  ✅ ALIGNED: Following Photo Evidence System Integration Guide
//

import SwiftUI
import MapKit
import Combine

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @EnvironmentObject private var authManager: NewAuthManager
    @StateObject private var syncService = DashboardSyncService.shared
    
    // UI State
    @State private var selectedBuildingId: String?
    @State private var showingBuildingIntelligence = false
    @State private var showingPortfolioInsights = false
    @State private var selectedTab: AdminTab = .overview
    @State private var cancellables = Set<AnyCancellable>()
    
    // Photo Evidence States
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var taskPhotos: [PhotoEvidence] = []
    @State private var showingTaskEvidence = false
    @State private var showingCompletedTasks = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showingBuildingPhotos = false
    
    // Map region for building view
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with portfolio summary
                    adminHeader
                    
                    // Tab selector
                    adminTabBar
                    
                    // Main content based on selected tab
                    tabContent
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
                setupSyncSubscriptions()
            }
            .sheet(isPresented: $showingBuildingIntelligence) {
                buildingIntelligenceSheet
            }
            .sheet(isPresented: $showingPortfolioInsights) {
                portfolioInsightsSheet
            }
            .sheet(isPresented: $showingTaskEvidence) {
                taskEvidenceSheet
            }
            .sheet(isPresented: $showingCompletedTasks) {
                completedTasksSheet
            }
            .sheet(isPresented: $showingBuildingPhotos) {
                buildingPhotosSheet
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            syncService.enableCrossDashboardSync()
        }
    }

    // MARK: - Sync Setup
    
    private func setupSyncSubscriptions() {
        // Subscribe to cross-dashboard updates
        syncService.crossDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { update in
                handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Subscribe to admin-specific updates
        syncService.adminDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { update in
                handleAdminUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        // Handle cross-dashboard updates
        switch update.type {
        case .taskCompleted:
            Task {
                await viewModel.loadDashboardData()
                // Check if the completed task has a photo
                if let photoId = update.data["photoId"], !photoId.isEmpty {
                    // Show notification about new photo evidence
                    HapticManager.shared.notification(type: .success)
                }
            }
        case .workerClockedIn, .workerClockedOut:
            Task {
                await viewModel.loadDashboardData()
            }
        case .buildingMetricsChanged:
            Task {
                await viewModel.loadDashboardData()
            }
        default:
            break
        }
    }
    
    private func handleAdminUpdate(_ update: CoreTypes.DashboardUpdate) {
        // Handle admin-specific updates
        Task {
            await viewModel.loadDashboardData()
        }
    }

    // MARK: - Header Section

    private var adminHeader: some View {
        VStack(spacing: 16) {
            // Welcome and sync status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Admin Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Welcome, \(authManager.currentUser?.name ?? "Admin")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Quick Actions
                HStack(spacing: 12) {
                    // View Completed Tasks
                    Button(action: { showingCompletedTasks = true }) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.green)
                    }
                    
                    // Sync status indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(syncService.isLive ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(syncService.isLive ? "Live" : "Offline")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        if let lastSync = syncService.lastSyncTime {
                            Text("• \(lastSync, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            // Portfolio summary cards
            if !viewModel.isLoading {
                portfolioSummaryCards
            } else {
                ProgressView()
                    .tint(.white)
                    .frame(height: 100)
            }
        }
        .padding(.vertical)
        .background(.ultraThinMaterial)
    }

    // MARK: - Portfolio Summary Cards

    private var portfolioSummaryCards: some View {
        let summary = viewModel.getAdminPortfolioSummary()
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                AdminSummaryCard(
                    title: "Buildings",
                    value: "\(summary.totalBuildings)",
                    subtitle: "Active properties",
                    icon: "building.2.fill",
                    color: .blue
                )
                
                AdminSummaryCard(
                    title: "Workers",
                    value: "\(summary.totalWorkers)",
                    subtitle: "\(viewModel.activeWorkers.count) online",
                    icon: "person.3.fill",
                    color: .green
                )
                
                AdminSummaryCard(
                    title: "Tasks",
                    value: "\(summary.completedTasks)/\(summary.totalTasks)",
                    subtitle: "Completed today",
                    icon: "checkmark.circle.fill",
                    color: .orange
                ) {
                    // Tap action to show completed tasks
                    showingCompletedTasks = true
                }
                
                AdminSummaryCard(
                    title: "Photos",
                    value: "\(viewModel.todaysPhotoCount)",
                    subtitle: "Evidence captured",
                    icon: "camera.fill",
                    color: .purple
                )
                
                AdminSummaryCard(
                    title: "Efficiency",
                    value: summary.completionPercentage,
                    subtitle: summary.efficiencyDescription,
                    icon: summary.efficiencyStatus.icon,
                    color: summary.efficiencyStatus.color
                )
                
                AdminSummaryCard(
                    title: "Insights",
                    value: "\(summary.criticalInsights)",
                    subtitle: "Critical alerts",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Tab Bar

    private var adminTabBar: some View {
        HStack(spacing: 0) {
            ForEach(AdminTab.allCases, id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.title)
                            .font(.caption)
                    }
                    .foregroundColor(selectedTab == tab ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        selectedTab == tab ? Color.blue.opacity(0.3) : Color.clear
                    )
                }
            }
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            overviewContent
        case .buildings:
            buildingsContent
        case .workers:
            workersContent
        case .tasks:
            tasksContent
        case .intelligence:
            intelligenceContent
        }
    }

    // MARK: - Overview Tab

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Live updates section
                liveUpdatesSection
                
                // Recent task completions with photos
                recentTaskCompletionsSection
                
                // Building metrics overview
                buildingMetricsOverview
                
                // Worker status overview
                workerStatusOverview
            }
            .padding()
        }
    }

    // MARK: - Recent Task Completions Section

    private var recentTaskCompletionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Completions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingCompletedTasks = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if viewModel.recentCompletedTasks.isEmpty {
                Text("No tasks completed recently")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.recentCompletedTasks.prefix(5), id: \.id) { task in
                        CompletedTaskRow(task: task) {
                            selectedTask = task
                            loadPhotos(for: task)
                            showingTaskEvidence = true
                        }
                    }
                }
            }
        }
    }

    private var liveUpdatesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Updates")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .opacity(syncService.isLive ? 1 : 0.3)
                    
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .opacity(syncService.isLive ? 1 : 0.3)
                }
            }
            
            if syncService.liveAdminAlerts.isEmpty {
                Text("No recent alerts")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(syncService.liveAdminAlerts.prefix(5), id: \.id) { alert in
                        LiveAlertRow(adminAlert: alert)
                    }
                }
            }
        }
    }

    private var buildingMetricsOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Building Performance")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    selectedTab = .buildings
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.buildings.prefix(5), id: \.id) { building in
                        BuildingMetricCard(
                            building: building,
                            metrics: syncService.unifiedBuildingMetrics[building.id] ?? viewModel.getBuildingMetrics(for: building.id)
                        ) {
                            // Tap action to view building photos
                            selectedBuilding = building
                            showingBuildingPhotos = true
                        }
                    }
                }
            }
        }
    }

    private var workerStatusOverview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Workers")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Live worker count
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    
                    Text("\(viewModel.activeWorkers.count) online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            if !syncService.liveWorkerUpdates.isEmpty {
                LazyVStack(spacing: 8) {
                    ForEach(syncService.liveWorkerUpdates.prefix(5), id: \.id) { update in
                        LiveWorkerUpdateRow(workerUpdate: update)
                    }
                }
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.activeWorkers.prefix(5), id: \.id) { worker in
                        WorkerStatusRow(worker: worker)
                    }
                }
            }
        }
    }

    // MARK: - Buildings Tab

    private var buildingsContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.buildings, id: \.id) { building in
                    BuildingAdminCard(
                        building: building,
                        metrics: syncService.unifiedBuildingMetrics[building.id] ?? viewModel.getBuildingMetrics(for: building.id),
                        insights: viewModel.getIntelligenceInsights(for: building.id),
                        onTap: {
                            selectedBuildingId = building.id
                            showingBuildingIntelligence = true
                        },
                        onPhotosTap: {
                            selectedBuilding = building
                            showingBuildingPhotos = true
                        }
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Workers Tab

    private var workersContent: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.activeWorkers, id: \.id) { worker in
                    WorkerAdminCard(worker: worker)
                }
            }
            .padding()
        }
    }

    // MARK: - Tasks Tab (NEW)

    private var tasksContent: some View {
        CompletedTasksView(
            tasks: viewModel.completedTasks,
            isLoading: viewModel.isLoading,
            onSelectTask: { task in
                selectedTask = task
                loadPhotos(for: task)
                showingTaskEvidence = true
            },
            onRefresh: {
                Task {
                    await viewModel.loadCompletedTasks()
                }
            }
        )
    }

    // MARK: - Intelligence Tab

    private var intelligenceContent: some View {
        VStack(spacing: 16) {
            // Intelligence header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Portfolio Intelligence")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(viewModel.portfolioInsights.count) insights available")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    showingPortfolioInsights = true
                }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Unified portfolio intelligence
            if let portfolio = syncService.unifiedPortfolioIntelligence {
                PortfolioIntelligenceCard(portfolio: portfolio)
                    .padding(.horizontal)
            }
            
            // Insights list
            if viewModel.portfolioInsights.isEmpty {
                Spacer()
                
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.slash")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No insights available")
                        .foregroundColor(.gray)
                }
                
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.portfolioInsights.prefix(10), id: \.id) { insight in
                            IntelligenceInsightCard(insight: insight)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Sheets

    private var buildingIntelligenceSheet: some View {
        NavigationView {
            BuildingIntelligencePanelContent(
                buildingId: selectedBuildingId ?? "",
                buildingName: viewModel.buildings.first { $0.id == selectedBuildingId }?.name ?? "",
                insights: viewModel.selectedBuildingInsights,
                isLoading: viewModel.isLoadingIntelligence
            )
            .navigationTitle("Building Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingBuildingIntelligence = false
                        viewModel.clearBuildingIntelligence()
                    }
                }
            }
        }
        .onAppear {
            if let buildingId = selectedBuildingId {
                Task {
                    await viewModel.fetchBuildingIntelligence(for: buildingId)
                }
            }
        }
    }

    private var portfolioInsightsSheet: some View {
        NavigationView {
            IntelligenceInsightsView(
                insights: viewModel.portfolioInsights
            ) {
                Task {
                    await viewModel.loadPortfolioInsights()
                }
            }
            .navigationTitle("Portfolio Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingPortfolioInsights = false
                    }
                }
            }
        }
    }

    // MARK: - Task Evidence Sheet (NEW)

    private var taskEvidenceSheet: some View {
        NavigationView {
            if let task = selectedTask {
                TaskEvidenceView(
                    task: task,
                    photos: taskPhotos,
                    onDismiss: {
                        showingTaskEvidence = false
                        selectedTask = nil
                        taskPhotos = []
                    }
                )
            } else {
                Text("No task selected")
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Completed Tasks Sheet (NEW)

    private var completedTasksSheet: some View {
        NavigationView {
            CompletedTasksListView(
                tasks: viewModel.completedTasks,
                onSelectTask: { task in
                    selectedTask = task
                    loadPhotos(for: task)
                    showingCompletedTasks = false
                    showingTaskEvidence = true
                },
                onDismiss: {
                    showingCompletedTasks = false
                }
            )
            .navigationTitle("Completed Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingCompletedTasks = false
                    }
                }
            }
        }
    }

    // MARK: - Building Photos Sheet (NEW)

    private var buildingPhotosSheet: some View {
        NavigationView {
            if let building = selectedBuilding {
                FrancoBuildingPhotoGallery(buildingId: building.id)
                    .navigationTitle(building.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingBuildingPhotos = false
                                selectedBuilding = nil
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Helper Methods

    private func loadPhotos(for task: CoreTypes.ContextualTask) {
        Task {
            do {
                taskPhotos = try await PhotoEvidenceService.shared.loadPhotoEvidence(for: task.id)
            } catch {
                print("❌ Failed to load task photos: \(error)")
                taskPhotos = []
            }
        }
    }
}

// MARK: - Supporting Views

struct AdminSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }
}

// MARK: - Completed Task Row (NEW)

struct CompletedTaskRow: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Task icon with photo indicator
                ZStack(alignment: .bottomTrailing) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    if task.requiresPhoto ?? false {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(2)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .offset(x: 4, y: 4)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let buildingName = task.buildingName {
                            Text(buildingName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        if let completedAt = task.completedAt {
                            Text("• \(completedAt, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Task Evidence View (NEW)

struct TaskEvidenceView: View {
    let task: CoreTypes.ContextualTask
    let photos: [PhotoEvidence]
    let onDismiss: () -> Void
    
    @State private var selectedPhoto: PhotoEvidence?
    @State private var showingFullScreen = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task info header
                    taskInfoHeader
                    
                    // Photo evidence section
                    if photos.isEmpty {
                        noPhotosView
                    } else {
                        photoEvidenceGrid
                    }
                    
                    // Task details
                    taskDetailsSection
                }
                .padding()
            }
        }
        .navigationTitle("Task Evidence")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    onDismiss()
                }
            }
        }
        .sheet(item: $selectedPhoto) { photo in
            PhotoEvidenceDetailView(
                photo: photo,
                onDismiss: {
                    selectedPhoto = nil
                }
            )
        }
    }
    
    private var taskInfoHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let buildingName = task.buildingName {
                        Text(buildingName)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Completion status
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Completed")
                        .font(.caption)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .cornerRadius(20)
            }
            
            if let completedAt = task.completedAt {
                Text("Completed \(completedAt, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var noPhotosView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No photo evidence")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("This task was completed without photos")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private var photoEvidenceGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Photo Evidence")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(photos.count) photo\(photos.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(photos) { photo in
                    PhotoEvidenceThumbnail(
                        photo: photo,
                        onTap: {
                            selectedPhoto = photo
                        }
                    )
                }
            }
        }
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Details")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(label: "Category", value: task.category?.rawValue ?? "General")
                DetailRow(label: "Priority", value: task.urgency?.rawValue ?? "Normal")
                DetailRow(label: "Frequency", value: task.frequency?.displayName ?? "One-time")
                
                if let description = task.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}

// MARK: - Photo Evidence Thumbnail (NEW)

struct PhotoEvidenceThumbnail: View {
    let photo: PhotoEvidence
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
                
                // Upload status overlay
                VStack {
                    HStack {
                        Spacer()
                        
                        uploadStatusIcon
                            .padding(4)
                    }
                    
                    Spacer()
                    
                    // Timestamp
                    HStack {
                        Text(photo.capturedAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(4)
                        
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadThumbnail()
        }
    }
    
    @ViewBuilder
    private var uploadStatusIcon: some View {
        switch photo.uploadStatus {
        case .uploaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.white)
                .background(Circle().fill(Color.green).frame(width: 20, height: 20))
        case .uploading:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.6)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))
        case .pending:
            Image(systemName: "arrow.up.circle.fill")
                .font(.caption)
                .foregroundColor(.white)
                .background(Circle().fill(Color.orange).frame(width: 20, height: 20))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
                .foregroundColor(.white)
                .background(Circle().fill(Color.red).frame(width: 20, height: 20))
        }
    }
    
    private func loadThumbnail() {
        if let thumb = photo.thumbnail {
            thumbnail = thumb
        } else if let fullImage = photo.image {
            // Create thumbnail from full image
            thumbnail = fullImage.preparingThumbnail(of: CGSize(width: 200, height: 200))
        }
    }
}

// MARK: - Photo Evidence Detail View (NEW)

struct PhotoEvidenceDetailView: View {
    let photo: PhotoEvidence
    let onDismiss: () -> Void
    
    @State private var isZoomed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = photo.image {
                    FrancoPhotoZoomView(image: image, isZoomed: $isZoomed)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // Overlay info when not zoomed
                if !isZoomed {
                    VStack {
                        Spacer()
                        
                        photoInfoOverlay
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                if !isZoomed {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
    }
    
    private var photoInfoOverlay: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Upload status
            HStack {
                uploadStatusBadge
                
                Spacer()
                
                if photo.fileSize > 0 {
                    Text(formatFileSize(photo.fileSize))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(photo.capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                }
                .foregroundColor(.white.opacity(0.8))
                
                if let location = photo.location {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                        Text("GPS: \(location.coordinate.latitude), \(location.coordinate.longitude)")
                            .font(.caption)
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                
                if let notes = photo.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    @ViewBuilder
    private var uploadStatusBadge: some View {
        HStack(spacing: 4) {
            switch photo.uploadStatus {
            case .uploaded:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Uploaded")
                    .foregroundColor(.green)
            case .uploading:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
                Text("Uploading...")
                    .foregroundColor(.blue)
            case .pending:
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
                Text("Pending")
                    .foregroundColor(.orange)
            case .failed:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Failed")
                    .foregroundColor(.red)
            }
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Completed Tasks View (NEW)

struct CompletedTasksView: View {
    let tasks: [CoreTypes.ContextualTask]
    let isLoading: Bool
    let onSelectTask: (CoreTypes.ContextualTask) -> Void
    let onRefresh: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading tasks...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if tasks.isEmpty {
                emptyStateView
            } else {
                tasksList
            }
        }
        .refreshable {
            onRefresh()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.gray)
            
            Text("No completed tasks")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Tasks will appear here once completed")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    CompletedTaskRow(task: task) {
                        onSelectTask(task)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Completed Tasks List View (NEW)

struct CompletedTasksListView: View {
    let tasks: [CoreTypes.ContextualTask]
    let onSelectTask: (CoreTypes.ContextualTask) -> Void
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var selectedBuilding: String? = nil
    
    var filteredTasks: [CoreTypes.ContextualTask] {
        tasks.filter { task in
            let matchesSearch = searchText.isEmpty ||
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.buildingName ?? "").localizedCaseInsensitiveContains(searchText)
            
            let matchesBuilding = selectedBuilding == nil ||
                task.buildingId == selectedBuilding
            
            return matchesSearch && matchesBuilding
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search and filters
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    // Building filter
                    if !uniqueBuildings.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    title: "All Buildings",
                                    isSelected: selectedBuilding == nil,
                                    action: { selectedBuilding = nil }
                                )
                                
                                ForEach(uniqueBuildings, id: \.0) { buildingId, buildingName in
                                    FilterChip(
                                        title: buildingName,
                                        isSelected: selectedBuilding == buildingId,
                                        action: { selectedBuilding = buildingId }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
                .background(.ultraThinMaterial)
                
                // Tasks list
                if filteredTasks.isEmpty {
                    Spacer()
                    Text("No tasks found")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredTasks, id: \.id) { task in
                                CompletedTaskRow(task: task) {
                                    onSelectTask(task)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
    }
    
    private var uniqueBuildings: [(String, String)] {
        let buildings = tasks.compactMap { task -> (String, String)? in
            guard let id = task.buildingId,
                  let name = task.buildingName else { return nil }
            return (id, name)
        }
        
        // Remove duplicates
        var seen = Set<String>()
        return buildings.filter { seen.insert($0.0).inserted }
    }
}

// MARK: - Helper Views

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.white)
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("Search tasks...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .foregroundColor(isSelected ? .white : .gray)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.blue : Color.white.opacity(0.1)
                )
                .cornerRadius(20)
        }
    }
}

struct LiveAlertRow: View {
    let adminAlert: DashboardSyncService.LiveAdminAlert
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(adminAlert.severity.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(adminAlert.title)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Text(adminAlert.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(adminAlert.severity.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(adminAlert.severity.color)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct LiveWorkerUpdateRow: View {
    let workerUpdate: DashboardSyncService.LiveWorkerUpdate
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(workerUpdate.workerName ?? "Worker") \(workerUpdate.action)")
                    .font(.caption)
                    .foregroundColor(.white)
                
                if let buildingName = workerUpdate.buildingName {
                    Text("at \(buildingName)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(workerUpdate.timestamp, style: .relative)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct PortfolioIntelligenceCard: View {
    let portfolio: CoreTypes.PortfolioIntelligence
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Portfolio Overview")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: portfolio.monthlyTrend.icon)
                        .font(.caption)
                    Text(portfolio.monthlyTrend.rawValue)
                        .font(.caption)
                }
                .foregroundColor(trendColor(for: portfolio.monthlyTrend))
            }
            
            HStack(spacing: 16) {
                MetricItem(
                    label: "Completion",
                    value: "\(Int(portfolio.completionRate * 100))%",
                    color: portfolio.completionRate > 0.8 ? .green : .orange
                )
                
                MetricItem(
                    label: "Compliance",
                    value: "\(Int(portfolio.complianceScore * 100))%",
                    color: portfolio.complianceScore > 0.9 ? .green : .orange
                )
                
                MetricItem(
                    label: "Critical Issues",
                    value: "\(portfolio.criticalIssues)",
                    color: portfolio.criticalIssues > 0 ? .red : .green
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func trendColor(for trend: CoreTypes.TrendDirection) -> Color {
        switch trend {
        case .up, .improving: return .green
        case .down, .declining: return .red
        case .stable, .unknown: return .gray
        }
    }
}

struct BuildingMetricCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 8) {
                Text(building.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let metrics = metrics {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption2)
                        Text("\(Int(metrics.completionRate * 100))%")
                            .font(.caption)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(metrics.completionRate > 0.8 ? .green : .orange)
                    
                    Text("\(metrics.overdueTasks) overdue")
                        .font(.caption2)
                        .foregroundColor(metrics.overdueTasks > 0 ? .red : .gray)
                    
                    if metrics.hasWorkerOnSite {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 4, height: 4)
                            Text("On-site")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    Text("Loading...")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 120)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerStatusRow: View {
    let worker: CoreTypes.WorkerProfile
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(worker.isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            Text(worker.name)
                .font(.caption)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(worker.role.displayName)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct BuildingAdminCard: View {
    let building: CoreTypes.NamedCoordinate
    let metrics: CoreTypes.BuildingMetrics?
    let insights: [CoreTypes.IntelligenceInsight]
    let onTap: () -> Void
    let onPhotosTap: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(building.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(building.address)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if !insights.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                Text("\(insights.count)")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                        }
                    }
                    
                    if let metrics = metrics {
                        HStack(spacing: 16) {
                            MetricItem(
                                label: "Completion",
                                value: "\(Int(metrics.completionRate * 100))%",
                                color: metrics.completionRate > 0.8 ? .green : .orange
                            )
                            
                            MetricItem(
                                label: "Overdue",
                                value: "\(metrics.overdueTasks)",
                                color: metrics.overdueTasks > 0 ? .red : .green
                            )
                            
                            MetricItem(
                                label: "Score",
                                value: "\(Int(metrics.overallScore))",
                                color: .blue
                            )
                            
                            if metrics.hasWorkerOnSite {
                                MetricItem(
                                    label: "Status",
                                    value: "On-site",
                                    color: .green
                                )
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Photos button
            Button(action: onPhotosTap) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.caption)
                    Text("View Photos")
                        .font(.caption)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.blue)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WorkerAdminCard: View {
    let worker: CoreTypes.WorkerProfile
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(worker.name.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text(worker.role.displayName)
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    if let skills = worker.skills, !skills.isEmpty {
                        Text("• \(skills.count) skills")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
            
            // Status
            HStack(spacing: 4) {
                Circle()
                    .fill(worker.isActive ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(worker.isActive ? "Active" : "Inactive")
                    .font(.caption)
                    .foregroundColor(worker.isActive ? .green : .gray)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct IntelligenceInsightCard: View {
    let insight: CoreTypes.IntelligenceInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                if insight.actionRequired {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Text(insight.description)
                .font(.caption)
                .foregroundColor(.gray)
                .lineLimit(3)
            
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(FrancoSphereDesign.EnumColors.aiPriority(insight.priority))
                        .frame(width: 6, height: 6)
                    
                    Text(insight.priority.rawValue)
                        .font(.caption2)
                        .foregroundColor(FrancoSphereDesign.EnumColors.aiPriority(insight.priority))
                }
                
                Spacer()
                
                if !insight.affectedBuildings.isEmpty {
                    Text("\(insight.affectedBuildings.count) buildings")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Helper Views

struct BuildingIntelligencePanelContent: View {
    let buildingId: String
    let buildingName: String
    let insights: [CoreTypes.IntelligenceInsight]
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading insights...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if insights.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.largeTitle)
                        .foregroundColor(.green)
                    
                    Text("No issues found")
                        .font(.headline)
                    
                    Text("This building is operating optimally")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(insights, id: \.id) { insight in
                            IntelligenceInsightCard(insight: insight)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct IntelligenceInsightsView: View {
    let insights: [CoreTypes.IntelligenceInsight]
    let onRefreshInsights: () -> Void
    
    @State private var isRefreshing = false
    
    init(insights: [CoreTypes.IntelligenceInsight], onRefreshInsights: @escaping () -> Void) {
        self.insights = insights
        self.onRefreshInsights = onRefreshInsights
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(insights, id: \.id) { insight in
                    IntelligenceInsightCard(insight: insight)
                }
            }
            .padding()
        }
        .refreshable {
            onRefreshInsights()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Tab Enum

enum AdminTab: String, CaseIterable {
    case overview = "overview"
    case buildings = "buildings"
    case workers = "workers"
    case tasks = "tasks"
    case intelligence = "intelligence"
    
    var title: String {
        switch self {
        case .overview: return "Overview"
        case .buildings: return "Buildings"
        case .workers: return "Workers"
        case .tasks: return "Tasks"
        case .intelligence: return "Intelligence"
        }
    }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .buildings: return "building.2.fill"
        case .workers: return "person.3.fill"
        case .tasks: return "checkmark.circle.fill"
        case .intelligence: return "brain.head.profile"
        }
    }
}

// MARK: - Preview

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
            .preferredColorScheme(.dark)
    }
}
