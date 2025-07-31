//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ REDESIGNED: Clean, focused dashboard with clear separation of concerns
//  ✅ STREAMLINED: Header | Hero | Next Steps | Intelligence
//  ✅ INTEGRATED: End-of-day reporting via Intelligence Panel
//  ✅ ENHANCED: Worker notes and photos throughout the day
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct WorkerDashboardView: View {
    @StateObject var viewModel: WorkerDashboardViewModel
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var novaEngine = NovaIntelligenceEngine.shared
    
    // MARK: - State Variables
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showTaskDetail = false
    @State private var showAllTasks = false
    @State private var showDepartureChecklist = false
    @State private var refreshID = UUID()
    
    var body: some View {
        MapRevealContainer(
            buildings: viewModel.workerCapabilities?.canViewMap ?? true ? contextEngine.assignedBuildings : [],
            currentBuildingId: contextEngine.currentBuilding?.id,
            focusBuildingId: nil,
            onBuildingTap: { building in
                // Handle building tap if needed
            }
        ) {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.95),
                        Color.black.opacity(0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Main content
                VStack(spacing: 0) {
                    // Persistent header
                    persistentHeader
                        .zIndex(100)
                    
                    // Scrollable dashboard content
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. Hero Status Card
                            HeroStatusCard(
                                worker: contextEngine.currentWorker,
                                building: contextEngine.currentBuilding,
                                weather: viewModel.weatherData,
                                progress: getTaskProgress(),
                                clockInStatus: getClockInStatus(),
                                capabilities: getWorkerCapabilities(),
                                syncStatus: getSyncStatus(),
                                onClockInTap: handleClockInTap,
                                onBuildingTap: { /* Handled by map */ },
                                onTasksTap: { showAllTasks = true },
                                onEmergencyTap: { /* Show emergency contacts */ },
                                onSyncTap: { Task { await viewModel.refreshData() } }
                            )
                            
                            // 2. Next Steps Section
                            if !contextEngine.todaysTasks.isEmpty {
                                NextStepsSection(
                                    currentTask: getCurrentTask(),
                                    upcomingTasks: getUpcomingTasks(),
                                    currentBuilding: contextEngine.currentBuilding,
                                    onStartTask: { task in
                                        selectedTask = task
                                        showTaskDetail = true
                                    },
                                    onSeeAll: { showAllTasks = true }
                                )
                            }
                            
                            // 3. Nova Intelligence Panel
                            if !novaEngine.currentInsights.isEmpty || hasIntelligenceToShow() {
                                IntelligencePreviewPanel(
                                    insights: novaEngine.currentInsights,
                                    onInsightTap: { insight in
                                        // Handle specific insight actions
                                        handleInsightAction(insight)
                                    },
                                    onRefresh: {
                                        await refreshIntelligence()
                                    }
                                )
                                .overlay(alignment: .topTrailing) {
                                    // Quick actions for intelligence
                                    intelligenceQuickActions
                                }
                            }
                            
                            // Departure button (if clocked in and tasks complete)
                            if shouldShowDepartureButton() {
                                departureSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                        refreshID = UUID()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showProfileView) {
            if let workerId = authManager.workerId {
                WorkerProfileView(workerId: workerId)
            }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showTaskDetail) {
            if let task = selectedTask {
                TaskDetailView(task: task)
                    .onDisappear {
                        Task {
                            await contextEngine.refreshContext()
                        }
                    }
            }
        }
        .sheet(isPresented: $showAllTasks) {
            NavigationView {
                TaskListView(
                    tasks: contextEngine.todaysTasks,
                    title: "Today's Tasks"
                )
            }
        }
        .sheet(isPresented: $showDepartureChecklist) {
            if let worker = contextEngine.currentWorker,
               let building = contextEngine.currentBuilding {
                SiteDepartureView(
                    viewModel: SiteDepartureViewModel(
                        workerId: worker.id,
                        currentBuilding: building,
                        capabilities: convertToSiteDepartureCapability(viewModel.workerCapabilities),
                        availableBuildings: contextEngine.assignedBuildings
                    )
                )
            }
        }
    }
    
    // MARK: - Persistent Header
    
    private var persistentHeader: some View {
        HStack(spacing: 0) {
            // Logo (Left)
            HStack(spacing: 8) {
                Image(systemName: "building.2.crop.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Franco")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                + Text("Sphere")
                    .font(.headline)
                    .fontWeight(.light)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Nova Button (Center)
            Button(action: { showNovaAssistant = true }) {
                ZStack {
                    // AI button with context indicator
                    Circle()
                        .fill(novaButtonGradient)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    // Processing indicator
                    if novaEngine.isProcessing {
                        Circle()
                            .stroke(
                                AngularGradient(
                                    colors: [.white.opacity(0.8), .clear],
                                    center: .center
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(novaEngine.isProcessing ? 360 : 0))
                            .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: novaEngine.isProcessing)
                    }
                    
                    // Context badge
                    if hasActiveNovaContext() {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .offset(x: 14, y: -14)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            
            // Profile/Clock (Right)
            HStack(spacing: 12) {
                // Clock time if clocked in
                if contextEngine.clockInStatus.isClockedIn {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(getElapsedTime())
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("On Site")
                            .font(.caption2)
                            .foregroundColor(.green.opacity(0.8))
                    }
                }
                
                // Profile button
                Button(action: { showProfileView = true }) {
                    ZStack {
                        Circle()
                            .fill(profileGradient)
                            .frame(width: 40, height: 40)
                        
                        Text(getInitials())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
    
    // MARK: - Intelligence Quick Actions
    
    private var intelligenceQuickActions: some View {
        Menu {
            Button(action: { showNovaAssistant = true }) {
                Label("Ask Nova", systemImage: "message.fill")
            }
            
            Button(action: { /* Show route map */ }) {
                Label("View Route Map", systemImage: "map")
            }
            
            if contextEngine.todaysTasks.filter({ $0.isCompleted }).count > 0 {
                Button(action: { /* Generate report */ }) {
                    Label("Generate Day Report", systemImage: "doc.text")
                }
            }
            
            Button(action: { /* Add note */ }) {
                Label("Add Note", systemImage: "note.text.badge.plus")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(8)
        }
    }
    
    // MARK: - Departure Section
    
    private var departureSection: some View {
        Button(action: { showDepartureChecklist = true }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to Leave?")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("All tasks complete at \(contextEngine.currentBuilding?.name ?? "this location")")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.square.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.green.opacity(0.8), Color.green],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentTask() -> CoreTypes.ContextualTask? {
        contextEngine.todaysTasks.first { !$0.isCompleted }
    }
    
    private func getUpcomingTasks() -> [CoreTypes.ContextualTask] {
        Array(contextEngine.todaysTasks
            .filter { !$0.isCompleted }
            .dropFirst()
            .prefix(5))
    }
    
    private func getTaskProgress() -> CoreTypes.TaskProgress {
        CoreTypes.TaskProgress(
            totalTasks: contextEngine.todaysTasks.count,
            completedTasks: contextEngine.todaysTasks.filter { $0.isCompleted }.count
        )
    }
    
    private func getClockInStatus() -> HeroStatusCard.ClockInStatus {
        if contextEngine.clockInStatus.isClockedIn,
           let building = contextEngine.currentBuilding {
            return .clockedIn(
                building: building.name,
                buildingId: building.id,
                time: viewModel.clockInTime ?? Date(),
                location: CLLocation(
                    latitude: building.latitude,
                    longitude: building.longitude
                )
            )
        }
        return .notClockedIn
    }
    
    private func getWorkerCapabilities() -> HeroStatusCard.WorkerCapabilities? {
        guard let caps = viewModel.workerCapabilities else { return nil }
        
        return HeroStatusCard.WorkerCapabilities(
            canUploadPhotos: caps.canUploadPhotos,
            canAddNotes: caps.canAddNotes,
            canViewMap: caps.canViewMap,
            canAddEmergencyTasks: caps.canAddEmergencyTasks,
            requiresPhotoForSanitation: caps.requiresPhotoForSanitation,
            simplifiedInterface: caps.simplifiedInterface
        )
    }
    
    private func getSyncStatus() -> HeroStatusCard.SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced: return .synced
        case .syncing: return .syncing(progress: 0.5)
        case .failed: return .error("Sync failed")
        case .offline: return .offline
        }
    }
    
    private func handleClockInTap() {
        if contextEngine.clockInStatus.isClockedIn {
            showDepartureChecklist = true
        } else if let firstBuilding = contextEngine.assignedBuildings.first {
            Task {
                await viewModel.clockIn(at: firstBuilding)
                await contextEngine.refreshContext()
            }
        }
    }
    
    private func getInitials() -> String {
        guard let name = contextEngine.currentWorker?.name else { return "FS" }
        let components = name.components(separatedBy: " ")
        let first = components.first?.first ?? "F"
        let last = components.count > 1 ? components.last?.first ?? "S" : "S"
        return "\(first)\(last)".uppercased()
    }
    
    private func getElapsedTime() -> String {
        guard let clockInTime = viewModel.clockInTime else { return "0:00" }
        let elapsed = Date().timeIntervalSince(clockInTime)
        let hours = Int(elapsed) / 3600
        let minutes = (Int(elapsed) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func hasActiveNovaContext() -> Bool {
        !novaEngine.currentInsights.isEmpty ||
        contextEngine.todaysTasks.contains { $0.urgency == .urgent || $0.urgency == .critical }
    }
    
    private func hasIntelligenceToShow() -> Bool {
        // Show intelligence if:
        // - Route optimization available (multiple buildings)
        // - Performance insights available
        // - Compliance deadlines approaching
        // - End of day summary ready
        
        return contextEngine.assignedBuildings.count > 1 ||
               contextEngine.todaysTasks.filter { $0.isCompleted }.count > 3 ||
               hasUpcomingDeadlines()
    }
    
    private func hasUpcomingDeadlines() -> Bool {
        // Check for DSNY or other time-sensitive tasks
        contextEngine.todaysTasks.contains { task in
            task.title.lowercased().contains("dsny") ||
            task.urgency == .urgent ||
            task.urgency == .critical
        }
    }
    
    private func shouldShowDepartureButton() -> Bool {
        guard contextEngine.clockInStatus.isClockedIn,
              let building = contextEngine.currentBuilding else { return false }
        
        // Show if all tasks at current building are complete
        let buildingTasks = contextEngine.getTasksForBuilding(building.id)
        let incompleteTasks = buildingTasks.filter { !$0.isCompleted }
        
        return incompleteTasks.isEmpty && !buildingTasks.isEmpty
    }
    
    private func handleInsightAction(_ insight: CoreTypes.IntelligenceInsight) {
        switch insight.type {
        case .routing:
            // Show route map
            NotificationCenter.default.post(name: .showRouteOnMap, object: nil)
        case .compliance:
            // Navigate to specific task
            if let taskId = insight.affectedBuildings.first,
               let task = contextEngine.todaysTasks.first(where: { $0.id == taskId }) {
                selectedTask = task
                showTaskDetail = true
            }
        case .efficiency:
            // Show performance analytics
            showNovaAssistant = true
        default:
            break
        }
    }
    
    private func refreshIntelligence() async {
        await novaEngine.analyzeContext(
            NovaContext(
                worker: contextEngine.currentWorker,
                currentBuilding: contextEngine.currentBuilding,
                currentTask: getCurrentTask(),
                todaysTasks: contextEngine.todaysTasks,
                timeOfDay: .afternoon,
                weather: viewModel.weatherData,
                urgentItems: []
            )
        )
    }
    
    // MARK: - Computed Properties
    
    private var novaButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue,
                Color.purple
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var profileGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.blue,
                Color.blue.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func convertToSiteDepartureCapability(_ capabilities: WorkerDashboardViewModel.WorkerCapabilities?) -> SiteDepartureViewModel.WorkerCapability? {
        guard let caps = capabilities else { return nil }
        
        return SiteDepartureViewModel.WorkerCapability(
            canUploadPhotos: caps.canUploadPhotos,
            canAddNotes: caps.canAddNotes,
            canViewMap: caps.canViewMap,
            canAddEmergencyTasks: caps.canAddEmergencyTasks,
            requiresPhotoForSanitation: caps.requiresPhotoForSanitation,
            simplifiedInterface: caps.simplifiedInterface
        )
    }
}

// MARK: - Next Steps Section Component

struct NextStepsSection: View {
    let currentTask: CoreTypes.ContextualTask?
    let upcomingTasks: [CoreTypes.ContextualTask]
    let currentBuilding: CoreTypes.NamedCoordinate?
    let onStartTask: (CoreTypes.ContextualTask) -> Void
    let onSeeAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Label("Next Steps", systemImage: "checklist")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: onSeeAll) {
                    Text("All Tasks →")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            VStack(spacing: 12) {
                // Current location context
                if let building = currentBuilding {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("CURRENT LOCATION: \(building.name)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Current task (prominent)
                if let task = currentTask {
                    CurrentTaskCard(
                        task: task,
                        onStart: { onStartTask(task) }
                    )
                }
                
                // Upcoming tasks (compact)
                if !upcomingTasks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UPCOMING (\(upcomingTasks.count) remaining)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.6))
                        
                        ForEach(upcomingTasks.prefix(2)) { task in
                            UpcomingTaskRow(task: task)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
}

// MARK: - Task Card Components

struct CurrentTaskCard: View {
    let task: CoreTypes.ContextualTask
    let onStart: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("NOW:")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if task.urgency == .urgent || task.urgency == .critical {
                    Label(task.urgency?.rawValue ?? "", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            
            Text(task.title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                if let location = task.location {
                    Label(location, systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                if task.requiresPhoto {
                    Label("Photo required", systemImage: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                
                if let duration = task.estimatedDuration {
                    Label("\(Int(duration / 60)) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Button(action: onStart) {
                Text("START TASK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct UpcomingTaskRow: View {
    let task: CoreTypes.ContextualTask
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 6, height: 6)
            
            Text(task.title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            if let duration = task.estimatedDuration {
                Text("\(Int(duration / 60))m")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Preview Provider

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView(viewModel: WorkerDashboardViewModel())
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
