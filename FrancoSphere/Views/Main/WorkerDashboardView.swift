//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Space-optimized with collapsible hero
//  ✅ INTEGRATED: Updated HeaderV3B with brand-AI-user layout
//  ✅ FOCUSED: 35-40% screen usage when collapsed
//  ✅ FUTURE-READY: Prepared for voice, AR, wearables
//  ✅ UPDATED: Now uses IntelligencePreviewPanel for AI insights
//  ✅ FIXED: Switch statements are now exhaustive
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
    @State private var isHeroCollapsed = false
    @State private var showProfileView = false
    @State private var showNovaAssistant = false
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showTaskDetail = false
    @State private var showAllTasks = false
    @State private var showDepartureChecklist = false
    @State private var showMainMenu = false
    @State private var refreshID = UUID()
    @State private var selectedInsight: CoreTypes.IntelligenceInsight?
    
    // Future phase states
    @State private var voiceCommandEnabled = false
    @State private var arModeEnabled = false
    
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
                    // Updated HeaderV3B with brand-AI-user layout (5-7%)
                    HeaderV3B(
                        workerName: contextEngine.currentWorker?.name ?? "Worker",
                        nextTaskName: getCurrentTask()?.title,
                        showClockPill: true, // Always show clock status
                        isNovaProcessing: {
                            switch novaEngine.processingState {
                            case .idle: return false
                            default: return true
                            }
                        }(),
                        onProfileTap: { showProfileView = true },
                        onNovaPress: { showNovaAssistant = true },
                        onNovaLongPress: {
                            // Long press for quick Nova actions
                            handleNovaQuickAction()
                        },
                        // Optional callbacks
                        onLogoTap: { showMainMenu = true },
                        onClockAction: handleClockAction,
                        // Future phase callbacks (nil for now, ready for feature flags)
                        onVoiceCommand: voiceCommandEnabled ? handleVoiceCommand : nil,
                        onARModeToggle: arModeEnabled ? handleARMode : nil,
                        onWearableSync: nil // Phase 4
                    )
                    .zIndex(100)
                    
                    // Main content area
                    ScrollView {
                        VStack(spacing: 16) {
                            // 1. Collapsible Hero Status Card (5% collapsed, 25-30% expanded)
                            CollapsibleHeroWrapper(
                                isCollapsed: $isHeroCollapsed,
                                worker: contextEngine.currentWorker,
                                building: contextEngine.currentBuilding,
                                weather: viewModel.weatherData,
                                progress: getTaskProgress(),
                                clockInStatus: getClockInStatus(),
                                capabilities: getWorkerCapabilities(),
                                syncStatus: getSyncStatus(),
                                onClockInTap: handleClockAction, // Use same handler
                                onBuildingTap: { /* Handled by map */ },
                                onTasksTap: { showAllTasks = true },
                                onEmergencyTap: handleEmergencyAction,
                                onSyncTap: { Task { await viewModel.refreshData() } }
                            )
                            .zIndex(50)
                            
                            // 2. Next Steps View - ALWAYS VISIBLE (15-18%)
                            if !contextEngine.todaysTasks.isEmpty {
                                NextStepsView(
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
                            
                            // Spacer for bottom intelligence bar
                            Spacer(minLength: 80)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                    .refreshable {
                        await viewModel.refreshData()
                        refreshID = UUID()
                    }
                    
                    // 3. Intelligence Preview Panel in Compact Mode (10%)
                    if !novaEngine.insights.isEmpty || hasIntelligenceToShow() {
                        IntelligencePreviewPanel(
                            insights: getCurrentInsights(),
                            displayMode: .compact,
                            onNavigate: { target in
                                handleIntelligenceNavigation(target)
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .sheet(item: $selectedInsight) { insight in
            InsightDetailView(insight: insight)
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
                VStack {
                    List(contextEngine.todaysTasks) { task in
                        WorkerTaskRowView(task: task) {
                            selectedTask = task
                            showTaskDetail = true
                            showAllTasks = false
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                .navigationTitle("Today's Tasks")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showAllTasks = false
                        }
                    }
                }
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
        .sheet(isPresented: $showMainMenu) {
            MainMenuView()
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            checkFeatureFlags()
        }
    }
    
    // MARK: - Intelligence Methods
    
    private func getCurrentInsights() -> [CoreTypes.IntelligenceInsight] {
        var insights = novaEngine.insights
        
        // Add contextual insights based on current state
        if hasUrgentTasks() {
            let urgentCount = contextEngine.todaysTasks.filter {
                $0.urgency == .urgent || $0.urgency == .critical
            }.count
            
            insights.append(CoreTypes.IntelligenceInsight(
                title: "\(urgentCount) urgent tasks require attention",
                description: "Priority tasks need immediate action to maintain schedule",
                type: .operations,
                priority: .high,
                actionRequired: true,
                affectedBuildings: Array(Set(contextEngine.todaysTasks.compactMap { $0.buildingId }))
            ))
        }
        
        // Check for DSNY deadlines
        let dsnyTasks = contextEngine.todaysTasks.filter {
            $0.title.lowercased().contains("dsny") ||
            $0.title.lowercased().contains("trash")
        }
        
        if !dsnyTasks.isEmpty {
            let buildingIds = Array(Set(dsnyTasks.compactMap { $0.buildingId }))
            insights.append(CoreTypes.IntelligenceInsight(
                title: "DSNY compliance deadline approaching",
                description: "Trash must be set out by 8:00 PM for \(buildingIds.count) buildings",
                type: .compliance,
                priority: dsnyTasks.contains { $0.urgency == .critical } ? .critical : .high,
                actionRequired: true,
                affectedBuildings: buildingIds
            ))
        }
        
        return insights
    }
    
    private func handleIntelligenceNavigation(_ target: IntelligencePreviewPanel.NavigationTarget) {
        switch target {
        case .tasks(let urgentCount):
            // Filter to urgent tasks
            showAllTasks = true
            
        case .buildings(let affected):
            // Could implement building filter view
            print("Navigate to buildings: \(affected)")
            
        case .compliance(let deadline):
            // Show compliance-specific view
            showAllTasks = true
            
        case .maintenance(let overdue):
            // Show maintenance tasks
            showAllTasks = true
            
        case .fullInsights:
            showNovaAssistant = true
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockAction() {
        if contextEngine.clockInStatus.isClockedIn {
            showDepartureChecklist = true
        } else if let firstBuilding = contextEngine.assignedBuildings.first {
            Task {
                await viewModel.clockIn(at: firstBuilding)
                await contextEngine.refreshContext()
            }
        }
    }
    
    private func handleNovaQuickAction() {
        // Quick action menu or immediate AI response
        if hasUrgentTasks() {
            // Immediate response for urgent situations
            showNovaAssistant = true
        } else {
            // Could show quick action menu
            showNovaAssistant = true
        }
    }
    
    private func handleEmergencyAction() {
        // Show emergency contacts or create emergency task
        if viewModel.workerCapabilities?.canAddEmergencyTasks == true {
            // Show emergency task creation
            print("Emergency task creation")
        } else {
            // Show emergency contacts
            print("Show emergency contacts")
        }
    }
    
    private func handleVoiceCommand() {
        // Phase 1: Voice command handling
        print("Voice command activated")
        // Future: Integrate with speech recognition
    }
    
    private func handleARMode() {
        // Phase 2: AR mode activation
        print("AR mode toggled")
        // Future: Launch AR view for building navigation
    }
    
    private func checkFeatureFlags() {
        // Check for enabled features
        // This would typically come from a feature flag service
        #if DEBUG
        // Enable in debug builds for testing
        voiceCommandEnabled = false // Set to true to test
        arModeEnabled = false // Set to true to test
        #else
        // Production feature flags
        voiceCommandEnabled = UserDefaults.standard.bool(forKey: "feature.voice.enabled")
        arModeEnabled = UserDefaults.standard.bool(forKey: "feature.ar.enabled")
        #endif
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
    
    private func hasIntelligenceToShow() -> Bool {
        return contextEngine.assignedBuildings.count > 1 ||
               contextEngine.todaysTasks.filter { $0.isCompleted }.count > 3 ||
               hasUpcomingDeadlines()
    }
    
    private func hasUpcomingDeadlines() -> Bool {
        contextEngine.todaysTasks.contains { task in
            task.title.lowercased().contains("dsny") ||
            task.urgency == .urgent ||
            task.urgency == .critical
        }
    }
    
    private func hasUrgentTasks() -> Bool {
        contextEngine.todaysTasks.contains { task in
            task.urgency == .urgent ||
            task.urgency == .critical ||
            task.urgency == .emergency
        }
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

// MARK: - Worker Task Row View

struct WorkerTaskRowView: View {
    let task: CoreTypes.ContextualTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Task icon
                Image(systemName: task.category?.icon ?? "checkmark.circle")
                    .font(.title3)
                    .foregroundColor(urgencyColor)
                    .frame(width: 32, height: 32)
                    .background(urgencyColor.opacity(0.1))
                    .cornerRadius(8)
                
                // Task details
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let building = task.building {
                            Label(building.name, systemImage: "building.2")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let dueDate = task.dueDate {
                            Label(dueDate.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                } else if task.urgency == .critical || task.urgency == .urgent {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var urgencyColor: Color {
        // Handle optional urgency with nil-coalescing
        switch task.urgency ?? .low {
        case .critical, .emergency:
            return .red
        case .urgent, .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
}

// MARK: - Main Menu View (Placeholder)

struct MainMenuView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Navigation") {
                    Label("Dashboard", systemImage: "house")
                    Label("All Tasks", systemImage: "checklist")
                    Label("Buildings", systemImage: "building.2")
                    Label("Schedule", systemImage: "calendar")
                }
                
                Section("Tools") {
                    Label("Reports", systemImage: "doc.text")
                    Label("Inventory", systemImage: "shippingbox")
                    Label("Messages", systemImage: "message")
                }
                
                Section("Support") {
                    Label("Help", systemImage: "questionmark.circle")
                    Label("Settings", systemImage: "gear")
                }
            }
            .navigationTitle("FrancoSphere")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - CollapsibleHeroWrapper Component

struct CollapsibleHeroWrapper: View {
    @Binding var isCollapsed: Bool
    
    // All the existing HeroStatusCard props
    let worker: WorkerProfile?
    let building: CoreTypes.NamedCoordinate?
    let weather: CoreTypes.WeatherData?
    let progress: CoreTypes.TaskProgress
    let clockInStatus: HeroStatusCard.ClockInStatus
    let capabilities: HeroStatusCard.WorkerCapabilities?
    let syncStatus: HeroStatusCard.SyncStatus
    
    let onClockInTap: () -> Void
    let onBuildingTap: () -> Void
    let onTasksTap: () -> Void
    let onEmergencyTap: () -> Void
    let onSyncTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            if isCollapsed {
                // Minimal collapsed version
                MinimalHeroCard(
                    worker: worker,
                    building: building,
                    progress: progress,
                    clockInStatus: clockInStatus,
                    onExpand: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCollapsed = false
                        }
                    }
                )
                
            } else {
                // Full existing HeroStatusCard with collapse button
                ZStack(alignment: .topTrailing) {
                    HeroStatusCard(
                        worker: worker,
                        building: building,
                        weather: weather,
                        progress: progress,
                        clockInStatus: clockInStatus,
                        capabilities: capabilities,
                        syncStatus: syncStatus,
                        onClockInTap: onClockInTap,
                        onBuildingTap: onBuildingTap,
                        onTasksTap: onTasksTap,
                        onEmergencyTap: onEmergencyTap,
                        onSyncTap: onSyncTap
                    )
                    
                    // Collapse button overlay
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isCollapsed = true
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(8)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .padding(8)
                }
            }
        }
    }
}

// MARK: - MinimalHeroCard Component

struct MinimalHeroCard: View {
    let worker: WorkerProfile?
    let building: CoreTypes.NamedCoordinate?
    let progress: CoreTypes.TaskProgress
    let clockInStatus: HeroStatusCard.ClockInStatus
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
                            .opacity(isClocked ? 0.6 : 0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isClocked)
                    )
                
                // Worker info
                if let worker = worker {
                    Text(worker.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                
                Text("•")
                    .foregroundColor(.white.opacity(0.5))
                
                // Progress
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(progress.completedTasks)/\(progress.totalTasks)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Building if clocked in
                if let building = building {
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(building.name)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Expand indicator
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        if case .clockedIn = clockInStatus {
            return .green
        } else {
            return .gray
        }
    }
    
    private var isClocked: Bool {
        if case .clockedIn = clockInStatus {
            return true
        } else {
            return false
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
