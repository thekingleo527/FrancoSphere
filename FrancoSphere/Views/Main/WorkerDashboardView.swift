//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ REFACTORED: Dual-mode map system with MapRevealContainer
//  ✅ FIXED: Nova AI centered in header
//  ✅ ALIGNED: With consolidated WorkerContextEngine
//  ✅ INTEGRATED: Building intelligence on map
//

import Foundation
import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    // MARK: - State Objects
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @EnvironmentObject private var authManager: NewAuthManager
    
    // MARK: - State Variables
    @State private var showBuildingList = false
    @State private var showProfileView = false
    @State private var showBuildingDetail = false
    @State private var selectedBuilding: NamedCoordinate?
    @State private var showNovaAssistant = false
    @State private var showOnlyMyBuildings = true
    @State private var primaryBuilding: NamedCoordinate?
    
    var body: some View {
        MapRevealContainer(
            buildings: contextEngine.assignedBuildings,
            currentBuildingId: contextEngine.currentBuilding?.id,  // Pass current clocked-in building
            focusBuildingId: selectedBuilding?.id,  // Pass focused building
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
                
                // Scrollable content
                ScrollView {
                    VStack(spacing: 24) {
                        // Clock-in card
                        if !contextEngine.clockInStatus.isClockedIn {
                            clockInGlassCard
                        }
                        
                        // Progress overview
                        if contextEngine.todaysTasks.count > 0 {
                            progressOverviewCard
                        }
                        
                        // Today's tasks card
                        if contextEngine.todaysTasks.count > 0 {
                            TodaysTasksGlassCard(tasks: contextEngine.todaysTasks)
                        }
                        
                        // My buildings section
                        myBuildingsSection
                        
                        // Floating intelligence insights
                        if !contextEngine.todaysTasks.isEmpty {
                            floatingInsightsSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 120) // Account for fixed header
                }
                
                // Fixed header overlay
                VStack {
                    headerOverlay
                    Spacer()
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
                BuildingDetailView(building: building)
                    .onDisappear {
                        // Clear selection when sheet dismisses
                        selectedBuilding = nil
                    }
            }
        }
        .sheet(isPresented: $showProfileView) {
            ProfileView()
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
                .presentationDetents([.large])
        }
    }
    
    // MARK: - Header Overlay (Reorganized)
    
    private var headerOverlay: some View {
        HStack(spacing: 16) {
            // FrancoSphere logo on left
            Image("AppIcon")
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.3), radius: 4)
            
            Spacer()
            
            // Nova AI in center
            NovaAvatar(
                size: .medium,
                isActive: contextEngine.hasPendingScenario,
                hasUrgentInsights: getUrgentTaskCount() > 0,
                isBusy: contextEngine.isLoading,
                onTap: { showNovaAssistant = true },
                onLongPress: { showNovaAssistant = true }
            )
            .shadow(color: .purple.opacity(0.5), radius: 10)
            
            Spacer()
            
            // Profile and clock status on right
            HStack(spacing: 12) {
                // Worker profile button
                Button(action: { showProfileView = true }) {
                    HStack(spacing: 8) {
                        // Worker avatar
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                            
                            Text(getWorkerInitials())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        // Show name only on larger screens
                        if UIScreen.main.bounds.width > 390 {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(contextEngine.currentWorker?.name ?? "Worker")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                
                                Text(getEnhancedWorkerRole())
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Clock-in status
                if contextEngine.clockInStatus.isClockedIn {
                    GlassStatusBadge(
                        text: "Active",
                        icon: "clock.fill",
                        style: .success,
                        size: .small,
                        isPulsing: true
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Clock In Glass Card
    
    private var clockInGlassCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Clock In")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Select a building to start")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            // Quick clock-in buttons
            if contextEngine.assignedBuildings.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(contextEngine.assignedBuildings.prefix(3), id: \.id) { building in
                            Button(action: {
                                Task {
                                    await viewModel.clockIn(at: building)
                                    // Update context engine after clock in
                                    await contextEngine.updateClockInStatus(for: contextEngine.currentWorker?.id ?? "")
                                }
                            }) {
                                Text(building.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Capsule().fill(Color.blue.opacity(0.8)))
                            }
                        }
                    }
                }
            }
        }
        .francoCardPadding()
        .francoGlassBackground()
        .francoShadow(FrancoSphereDesign.Shadow.glassCard)
    }
    
    // MARK: - Progress Overview Card
    
    private var progressOverviewCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                GlassStatusBadge(
                    text: "\(contextEngine.todaysTasks.filter { $0.isCompleted }.count) of \(contextEngine.todaysTasks.count)",
                    style: .info,
                    size: .small
                )
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * contextEngine.getCompletionPercentage() / 100,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
            
            // Quick stats
            HStack(spacing: 20) {
                statPill("Completed", "\(contextEngine.todaysTasks.filter { $0.isCompleted }.count)", color: .green)
                statPill("Remaining", "\(contextEngine.todaysTasks.filter { !$0.isCompleted }.count)", color: .blue)
                if getUrgentTaskCount() > 0 {
                    statPill("Urgent", "\(getUrgentTaskCount())", color: .orange)
                }
            }
        }
        .francoCardPadding()
        .francoGlassBackground()
        .francoShadow(FrancoSphereDesign.Shadow.glassCard)
    }
    
    private func statPill(_ title: String, _ value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
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
    
    private func glassBuildingCard(for building: NamedCoordinate) -> some View {
        Button(action: {
            selectedBuilding = building
            showBuildingDetail = true
        }) {
            VStack(spacing: 12) {
                // Building image using PropertyCard's logic
                PropertyCard.buildingImage(for: building)
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
                                style: .default,
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
    
    // MARK: - Floating Insights Section
    
    private var floatingInsightsSection: some View {
        VStack(spacing: 12) {
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
    
    private func insightCard(title: String, message: String, icon: String, color: Color) -> some View {
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
        }
        .padding(12)
        .francoPropertyCardBackground()
        .francoShadow(FrancoSphereDesign.Shadow.propertyCard)
    }
    
    // MARK: - Helper Methods
    
    private func getWorkerInitials() -> String {
        guard let worker = contextEngine.currentWorker else { return "WO" }
        let components = worker.name.components(separatedBy: " ")
        let first = components.first?.first ?? Character("W")
        let last = components.count > 1 ? components.last?.first ?? Character("O") : Character("O")
        return "\(first)\(last)"
    }
    
    private func getUrgentTaskCount() -> Int {
        return contextEngine.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .urgent || urgency == .critical || urgency == .emergency
        }.count
    }
    
    private func loadWorkerSpecificData() async {
        await viewModel.loadInitialData()
        
        // Load context for current worker
        if let currentUser = await authManager.getCurrentUser(),
           let workerId = currentUser.workerId {
            try? await contextEngine.loadContext(for: workerId)
        }
        
        let primary = determinePrimaryBuilding(for: contextEngine.currentWorker?.id)
        self.showOnlyMyBuildings = true
        self.primaryBuilding = primary
        
        print("✅ Worker dashboard loaded: \(contextEngine.assignedBuildings.count) buildings, primary: \(primary?.name ?? "none")")
    }
    
    private func determinePrimaryBuilding(for workerId: String?) -> NamedCoordinate? {
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
    
    private func getEnhancedWorkerRole() -> String {
        guard let worker = contextEngine.currentWorker else { return "Building Operations" }
        
        switch worker.id {
        case "4": return "Museum Specialist"
        case "2": return "Park Operations"
        case "5": return "West Village"
        case "6": return "Downtown"
        case "1": return "Systems Specialist"
        case "7": return "Evening Ops"
        case "8": return "Portfolio Mgmt"
        default: return worker.role.rawValue.capitalized
        }
    }
}

// MARK: - Preview Provider

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
            .environmentObject(NewAuthManager.shared)
            .preferredColorScheme(.dark)
    }
}
