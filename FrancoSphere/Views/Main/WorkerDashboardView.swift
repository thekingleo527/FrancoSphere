//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Integrated ProfileBadge component
//  ✅ FIXED: Removed redundant custom components
//  ✅ ENHANCED: Real-time status updates via ProfileBadge
//  ✅ INTEGRATED: MapRevealContainer with layered content
//  ✅ FIXED: All compilation errors resolved
//  ✅ NEW: Added navigation to TodaysProgressDetailView
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation

struct WorkerDashboardView: View {
    // MARK: - State Objects
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State Variables
    @State private var showBuildingList = false
    @State private var showProfileView = false
    @State private var showBuildingDetail = false
    @State private var selectedBuilding: CoreTypes.NamedCoordinate?
    @State private var showNovaAssistant = false
    @State private var showOnlyMyBuildings = true
    @State private var primaryBuilding: CoreTypes.NamedCoordinate?
    @State private var selectedTask: CoreTypes.ContextualTask?
    @State private var showTaskDetail = false
    @State private var showEmergencyContacts = false
    @State private var isNovaProcessing = false
    @State private var showProgressDetail = false
    
    var body: some View {
        MapRevealContainer(
            buildings: contextEngine.assignedBuildings,
            currentBuildingId: contextEngine.currentBuilding?.id,
            focusBuildingId: selectedBuilding?.id,
            onBuildingTap: { building in
                selectedBuilding = building
                showBuildingDetail = true
            }
        ) {
            // Main dashboard content
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.9),
                        Color.black.opacity(0.7)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                // Main content with fixed header
                VStack(spacing: 0) {
                    // Enhanced header with ProfileBadge
                    workerDashboardHeader
                        .zIndex(100) // Keep header on top
                    
                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Hero Status Card
                            HeroStatusCard(
                                worker: contextEngine.currentWorker,
                                building: contextEngine.currentBuilding,
                                weather: viewModel.weatherData,
                                progress: getTaskProgress(),
                                clockInStatus: getClockInStatus(),
                                capabilities: getWorkerCapabilities(),
                                syncStatus: getSyncStatus(),
                                onClockInTap: handleClockInTap,
                                onBuildingTap: handleBuildingTap,
                                onTasksTap: handleTasksTap,
                                onEmergencyTap: handleEmergencyTap,
                                onSyncTap: handleSyncTap
                            )
                            .padding(.horizontal, 20)
                            
                            // Today's tasks section with analytics button
                            if !contextEngine.todaysTasks.isEmpty {
                                VStack(spacing: 16) {
                                    // Tasks header with analytics button
                                    HStack {
                                        Text("Today's Tasks")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        // Analytics button
                                        Button(action: { showProgressDetail = true }) {
                                            HStack(spacing: 4) {
                                                Text("View Analytics")
                                                Image(systemName: "chart.bar.fill")
                                            }
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    
                                    // Tasks card
                                    TodaysTasksGlassCard(
                                        tasks: contextEngine.todaysTasks.map { convertToMaintenanceTask($0) },
                                        onTaskTap: { task in
                                            // Convert back to ContextualTask for selectedTask
                                            if let contextualTask = contextEngine.todaysTasks.first(where: { $0.id == task.id }) {
                                                selectedTask = contextualTask
                                                showTaskDetail = true
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            
                            // My buildings section
                            myBuildingsSection
                                .padding(.horizontal, 20)
                            
                            // Smart route section (if multiple buildings)
                            if contextEngine.assignedBuildings.count > 1 {
                                smartRouteSection
                                    .padding(.horizontal, 20)
                            }
                            
                            // Floating intelligence insights
                            if !contextEngine.todaysTasks.isEmpty {
                                floatingInsightsSection
                                    .padding(.horizontal, 20)
                            }
                            
                            Spacer(minLength: 100)
                        }
                        .padding(.top, 20)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            await loadWorkerSpecificData()
        }
        .sheet(isPresented: $showBuildingList) {
            BuildingSelectionView(
                buildings: showOnlyMyBuildings ? contextEngine.assignedBuildings : contextEngine.portfolioBuildings
            ) { building in
                selectedBuilding = building
                showBuildingDetail = true
                showBuildingList = false
            }
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(
                    buildingId: building.id,
                    buildingName: building.name,
                    buildingAddress: building.address ?? ""
                )
                .onDisappear {
                    selectedBuilding = nil
                }
            }
        }
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
            }
        }
        .sheet(isPresented: $showEmergencyContacts) {
            EmergencyContactsSheet()
        }
        .sheet(isPresented: $showProgressDetail) {
            NavigationView {
                TodaysProgressDetailView()
            }
        }
    }
    
    // MARK: - Enhanced Header with ProfileBadge
    
    private var workerDashboardHeader: some View {
        VStack(spacing: 0) {
            // Glass background
            ZStack {
                // Background blur
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                
                // Main header content
                VStack(spacing: 16) {
                    // Top row with profile and Nova
                    HStack(alignment: .center, spacing: 16) {
                        // Profile badge with real-time status
                        if let worker = contextEngine.currentWorker {
                            ProfileBadge(
                                worker: worker,
                                size: .standard,
                                context: .worker,
                                onTap: { showProfileView = true }
                            )
                        }
                        
                        // Worker info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(getGreeting())
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(contextEngine.currentWorker?.name ?? "Worker")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            // Next task preview
                            if let nextTask = getNextTaskName() {
                                Text(nextTask)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                        
                        // Nova AI Button
                        NovaAvatar(
                            size: .medium,
                            isProcessing: isNovaProcessing,
                            onTap: { showNovaAssistant = true },
                            onLongPress: { showNovaAssistant = true }
                        )
                    }
                    
                    // Clock-in status pill (if clocked in)
                    if contextEngine.clockInStatus.isClockedIn,
                       let building = contextEngine.currentBuilding {
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            
                            Text("Clocked in at \(building.name)")
                                .font(.caption)
                            
                            Spacer()
                            
                            if let clockInTime = viewModel.clockInTime {
                                Text(clockInTime, style: .time)
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
        }
    }
    
    // MARK: - My Buildings Section
    
    private var myBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("My Buildings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showBuildingList = true }) {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Building grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(contextEngine.assignedBuildings.prefix(4), id: \.id) { building in
                    glassBuildingCard(for: building)
                }
            }
        }
    }
    
    private func glassBuildingCard(for building: CoreTypes.NamedCoordinate) -> some View {
        Button(action: {
            selectedBuilding = building
            showBuildingDetail = true
        }) {
            VStack(spacing: 12) {
                // Building image
                buildingImage(for: building)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    // Show status badges
                    HStack(spacing: 4) {
                        if building.id == primaryBuilding?.id {
                            GlassStatusBadge(
                                text: "PRIMARY",
                                style: .success,
                                size: .small
                            )
                        }
                        
                        if building.id == contextEngine.currentBuilding?.id {
                            GlassStatusBadge(
                                text: "ACTIVE",
                                icon: "clock.fill",
                                style: .info,
                                size: .small
                            )
                        }
                        
                        // Show task count for building
                        let buildingTasks = contextEngine.getTasksForBuilding(building.id)
                        if !buildingTasks.isEmpty {
                            GlassStatusBadge(
                                text: "\(buildingTasks.count)",
                                icon: "checklist",
                                style: .info,
                                size: .small
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(12)
        .francoPropertyCardBackground()
        .francoShadow(FrancoSphereDesign.Shadow.propertyCard)
    }
    
    // MARK: - Smart Route Section
    
    private var smartRouteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.title3)
                    .foregroundColor(.purple)
                
                Text("Smart Route")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    // Trigger map reveal with route
                    NotificationCenter.default.post(name: .showRouteOnMap, object: nil)
                }) {
                    Text("View Route")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }
            
            // Route summary
            HStack(spacing: 20) {
                routeStat("Buildings", "\(contextEngine.assignedBuildings.count)")
                routeStat("Est. Time", getEstimatedRouteTime())
                routeStat("Distance", getRouteDistance())
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private func routeStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Floating Insights Section
    
    private var floatingInsightsSection: some View {
        VStack(spacing: 12) {
            // Progress insight card
            insightCard(
                title: "Daily Progress",
                message: "\(contextEngine.todaysTasks.filter { $0.isCompleted }.count) of \(contextEngine.todaysTasks.count) tasks completed",
                icon: "chart.line.uptrend.xyaxis",
                color: .green,
                action: { showProgressDetail = true }
            )
            
            if getUrgentTaskCount() > 0 {
                insightCard(
                    title: "Urgent Tasks",
                    message: "\(getUrgentTaskCount()) tasks need immediate attention",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
            
            if let nextTask = contextEngine.todaysTasks.first(where: { !$0.isCompleted }) {
                insightCard(
                    title: "Next Task",
                    message: nextTask.title,
                    icon: "arrow.right.circle.fill",
                    color: .blue
                )
            }
            
            if contextEngine.assignedBuildings.count > 1 {
                insightCard(
                    title: "Route Optimization",
                    message: "Swipe up on the map to view optimal route",
                    icon: "map.fill",
                    color: .purple
                )
            }
            
            // Weather-based insights
            if let weather = viewModel.weatherData,
               weather.outdoorWorkRisk != .low {
                insightCard(
                    title: "Weather Alert",
                    message: "\(weather.condition) - \(weather.outdoorWorkRisk.rawValue) risk for outdoor work",
                    icon: "cloud.bolt.fill",
                    color: .yellow
                )
            }
            
            // Suggest clock out if all tasks at current building are done
            if contextEngine.shouldSuggestClockOut() {
                insightCard(
                    title: "Tasks Complete",
                    message: "All tasks at \(contextEngine.currentBuilding?.name ?? "this building") are done",
                    icon: "checkmark.seal.fill",
                    color: .green
                )
            }
        }
    }
    
    private func insightCard(title: String, message: String, icon: String, color: Color, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
                    .background(color.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(message)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(12)
            .francoPropertyCardBackground()
            .francoShadow(FrancoSphereDesign.Shadow.propertyCard)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
    
    // MARK: - Building Image Helper
    
    @ViewBuilder
    private func buildingImage(for building: CoreTypes.NamedCoordinate) -> some View {
        let buildingAssetMap: [String: String] = [
            "1": "12_West_18th_Street",
            "2": "29_31_East_20th_Street",
            "3": "36_Walker_Street",
            "4": "41_Elizabeth_Street",
            "5": "68_Perry_Street",
            "6": "104_Franklin_Street",
            "7": "112_West_18th_Street",
            "8": "117_West_17th_Street",
            "9": "123_1st_Avenue",
            "10": "131_Perry_Street",
            "11": "133_East_15th_Street",
            "12": "135West17thStreet",
            "13": "136_West_17th_Street",
            "14": "Rubin_Museum_142_148_West_17th_Street",
            "15": "138West17thStreet",
            "16": "41_Elizabeth_Street",
            "park": "Stuyvesant_Cove_Park"
        ]
        
        if let assetName = buildingAssetMap[building.id], let image = UIImage(named: assetName) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            // Fallback gradient
            LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
            .overlay(
                Image(systemName: "building.2.fill")
                    .font(.title)
                    .foregroundColor(.gray.opacity(0.7))
            )
        }
    }
    
    // MARK: - Adapter Methods for HeroStatusCard
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }
    
    private func getNextTaskName() -> String? {
        contextEngine.todaysTasks.first(where: { !$0.isCompleted })?.title
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
        guard let worker = contextEngine.currentWorker else { return nil }
        
        // Check actual capabilities from database or use defaults based on worker
        let isSimplified = worker.id == "5" // Mercedes uses simplified UI
        let canAddEmergency = worker.role == .admin || worker.role == .manager
        
        return HeroStatusCard.WorkerCapabilities(
            canUploadPhotos: !isSimplified,
            canAddNotes: !isSimplified,
            canViewMap: true,
            canAddEmergencyTasks: canAddEmergency,
            requiresPhotoForSanitation: true,
            simplifiedInterface: isSimplified
        )
    }
    
    private func getSyncStatus() -> HeroStatusCard.SyncStatus {
        switch viewModel.dashboardSyncStatus {
        case .synced:
            return .synced
        case .syncing:
            return .syncing(progress: 0.5)
        case .failed:
            return .error("Sync failed")
        case .offline:
            return .offline
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockInTap() {
        if contextEngine.clockInStatus.isClockedIn {
            Task {
                await viewModel.clockOut()
                await contextEngine.refreshContext()
            }
        } else if let firstBuilding = contextEngine.assignedBuildings.first {
            Task {
                await viewModel.clockIn(at: firstBuilding)
                await contextEngine.refreshContext()
            }
        } else {
            // Show building selection
            showBuildingList = true
        }
    }
    
    private func handleBuildingTap() {
        if let building = contextEngine.currentBuilding {
            selectedBuilding = building
            showBuildingDetail = true
        } else {
            showBuildingList = true
        }
    }
    
    private func handleTasksTap() {
        // Navigate to the progress detail view
        showProgressDetail = true
    }
    
    private func handleEmergencyTap() {
        showEmergencyContacts = true
    }
    
    private func handleSyncTap() {
        Task {
            await viewModel.refreshData()
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUrgentTaskCount() -> Int {
        return contextEngine.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .urgent || urgency == .critical || urgency == .emergency
        }.count
    }
    
    private func getEstimatedRouteTime() -> String {
        let totalTasks = contextEngine.todaysTasks.count
        let estimatedHours = Double(totalTasks) * 0.5 // 30 min per task average
        
        if estimatedHours < 1 {
            return "\(Int(estimatedHours * 60))m"
        } else {
            return String(format: "%.1fh", estimatedHours)
        }
    }
    
    private func getRouteDistance() -> String {
        // Calculate based on building locations
        // For now, return estimate
        let buildingCount = contextEngine.assignedBuildings.count
        let avgDistance = 0.8 // miles between buildings
        let total = Double(buildingCount - 1) * avgDistance
        return String(format: "%.1f mi", total)
    }
    
    private func loadWorkerSpecificData() async {
        await viewModel.loadInitialData()
        
        // Load context for current worker using the correct property access
        if let workerId = authManager.workerId {
            try? await contextEngine.loadContext(for: workerId)
        }
        
        let primary = determinePrimaryBuilding(for: contextEngine.currentWorker?.id)
        self.showOnlyMyBuildings = true
        self.primaryBuilding = primary
        
        print("✅ Worker dashboard loaded: \(contextEngine.assignedBuildings.count) buildings, primary: \(primary?.name ?? "none")")
    }
    
    private func determinePrimaryBuilding(for workerId: String?) -> CoreTypes.NamedCoordinate? {
        let buildings = contextEngine.assignedBuildings
        guard let workerId = workerId else { return buildings.first }
        
        switch workerId {
        case "4": return buildings.first { $0.name.contains("Rubin") }
        case "2": return buildings.first { $0.name.contains("Stuyvesant") || $0.name.contains("Park") }
        case "5": return buildings.first { $0.name.contains("131 Perry") }
        case "6": return buildings.first { $0.name.contains("41 Elizabeth") }
        case "1": return buildings.first { $0.name.contains("12 West 18th") }
        case "7": return buildings.first { $0.name.contains("West 17th") }
        case "8": return buildings.first
        default: return buildings.first
        }
    }
    
    // MARK: - Task Conversion Helper
    
    private func convertToMaintenanceTask(_ contextualTask: CoreTypes.ContextualTask) -> CoreTypes.MaintenanceTask {
        let status: CoreTypes.TaskStatus = contextualTask.isCompleted ? .completed :
                                (contextualTask.isOverdue ? .overdue : .pending)
        
        return CoreTypes.MaintenanceTask(
            id: contextualTask.id,
            title: contextualTask.title,
            description: contextualTask.description ?? "",
            category: contextualTask.category ?? .maintenance,
            urgency: contextualTask.urgency ?? .medium,
            status: status,
            buildingId: contextualTask.buildingId ?? "",
            assignedWorkerId: contextualTask.assignedWorkerId ?? contextualTask.worker?.id,
            estimatedDuration: 3600,
            createdDate: Date(),
            dueDate: contextualTask.dueDate,
            completedDate: contextualTask.completedDate,
            instructions: nil,
            requiredSkills: [],
            isRecurring: false,
            parentTaskId: nil
        )
    }
}

// MARK: - Notification Names Extension

extension Notification.Name {
    static let showRouteOnMap = Notification.Name("showRouteOnMap")
}

// MARK: - Preview Provider

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
            .environmentObject(NewAuthManager.shared)
            .environmentObject(DashboardSyncService.shared)
            .preferredColorScheme(.dark)
    }
}
