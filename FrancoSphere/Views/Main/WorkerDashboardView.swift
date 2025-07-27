//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0
//
//  ✅ CLEANED: Removed duplicate imports
//  ✅ VISUAL: Glassmorphism and floating cards
//  ✅ INTEGRATION: Uses existing WorkerContextEngineAdapter
//  ✅ NOVA AI: Fully integrated assistant
//  ✅ PRODUCTION READY: All functionality maintained
//

import Foundation
import SwiftUI
import MapKit

struct WorkerDashboardView: View {
    // MARK: - State Objects
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @EnvironmentObject private var authManager: NewAuthManager
    
    // MARK: - State Variables
    @State private var showBuildingList = false
    @State private var showMapOverlay = false
    @State private var showProfileView = false
    @State private var workerName = "Worker"
    @State private var selectedBuilding: NamedCoordinate?
    @State private var showBuildingDetail = false
    @State private var selectedBuildingIsAssigned = false
    @State private var showOnlyMyBuildings = true
    @State private var primaryBuilding: NamedCoordinate?
    
    // Nova AI state
    @State private var showNovaAssistant = false
    
    var body: some View {
        ZStack {
            // Glass map background
            mapBackgroundWithGlass
            
            // Main content with proper spacing
            ScrollView {
                VStack(spacing: 24) {
                    // Enhanced header with FrancoSphere branding
                    glassmorphicHeader
                    
                    // Nova AI Manager section (centered)
                    novaAIManagerCard
                        .padding(.horizontal, 20)
                    
                    // Clock-in card with glass effect
                    if !viewModel.isClockedIn {
                        clockInGlassCard
                            .padding(.horizontal, 20)
                    }
                    
                    // Progress overview with glass
                    if contextAdapter.todaysTasks.count > 0 {
                        progressOverviewCard
                            .padding(.horizontal, 20)
                    }
                    
                    // My buildings grid with glass cards
                    myBuildingsSection
                        .padding(.horizontal, 20)
                    
                    // Floating intelligence insights
                    if !contextAdapter.todaysTasks.isEmpty {
                        floatingInsightsSection
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 100) // Account for fixed header
            }
            
            // Fixed header overlay
            VStack {
                headerOverlay
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .task {
            await loadWorkerSpecificData()
        }
        .sheet(isPresented: $showBuildingList) {
            BuildingSelectionView(
                buildings: showOnlyMyBuildings ? contextAdapter.assignedBuildings : getAllBuildings()
            ) { building in
                navigateToBuilding(building)
                showBuildingList = false
            }
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(building: building)
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
    
    // MARK: - Glass Map Background
    
    private var mapBackgroundWithGlass: some View {
        ZStack {
            // Map with current location
            Map {
                ForEach(contextAdapter.assignedBuildings, id: \.id) { building in
                    Annotation("", coordinate: building.coordinate) {
                        buildingMapBubble(building)
                    }
                }
            }
            .mapRegion(.constant(
                MKCoordinateRegion(
                    center: primaryBuilding?.coordinate ?? CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            ))
            .ignoresSafeArea()
            .opacity(0.4)
            
            // Glass overlay gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.3),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Header Overlay (Fixed Position)
    
    private var headerOverlay: some View {
        HStack {
            // Worker profile
            Button(action: { showProfileView = true }) {
                HStack(spacing: 8) {
                    // Worker avatar
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 40, height: 40)
                        
                        Text(getWorkerInitials())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contextAdapter.currentWorker?.name ?? "Worker")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(getEnhancedWorkerRole())
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            // FrancoSphere branding
            Image("AppIcon") // Use your app icon
                .resizable()
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Spacer()
            
            // Clock-in status
            if viewModel.isClockedIn {
                GlassStatusBadge(
                    text: "Active",
                    icon: "clock.fill",
                    style: .success,
                    size: .small,
                    isPulsing: true
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(edges: .top)
    }
    
    // MARK: - Glassmorphic Header
    
    private var glassmorphicHeader: some View {
        VStack(spacing: 16) {
            Text("FrancoSphere")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            
            HStack(spacing: 20) {
                // Stats with glass effect
                statCard("Buildings", "\(contextAdapter.assignedBuildings.count)", icon: "building.2.fill", color: .blue)
                statCard("Tasks", "\(contextAdapter.todaysTasks.count)", icon: "checkmark.circle.fill", color: .green)
                statCard("Progress", "\(Int(contextAdapter.taskProgress?.progressPercentage ?? 0))%", icon: "chart.line.uptrend.xyaxis", color: .purple)
            }
        }
        .padding(.vertical, 20)
    }
    
    private func statCard(_ title: String, _ value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Nova AI Manager Card
    
    private var novaAIManagerCard: some View {
        Button(action: { showNovaAssistant = true }) {
            HStack(spacing: 16) {
                // Nova Avatar using existing AIAssistantImageLoader
                AIAssistantImageLoader.circularAIAssistantView(
                    diameter: 60,
                    borderColor: .purple
                )
                .shadow(color: .purple.opacity(0.5), radius: 10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nova AI Assistant")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Tap for portfolio intelligence")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .francoGlassCard()
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
            if contextAdapter.assignedBuildings.count > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(contextAdapter.assignedBuildings.prefix(3), id: \.id) { building in
                            quickClockInButton(for: building)
                        }
                    }
                }
            }
        }
        .francoGlassCard()
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
                    text: "\(contextAdapter.todaysTasks.filter { $0.isCompleted }.count) of \(contextAdapter.todaysTasks.count)",
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
                            width: geometry.size.width * (contextAdapter.taskProgress?.progressPercentage ?? 0) / 100,
                            height: 8
                        )
                }
            }
            .frame(height: 8)
        }
        .francoGlassCard()
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
                        Text("All")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Building grid using existing PropertyCard
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(contextAdapter.assignedBuildings, id: \.id) { building in
                    glassBuildingCard(for: building)
                }
            }
        }
    }
    
    private func glassBuildingCard(for building: NamedCoordinate) -> some View {
        Button(action: { navigateToBuilding(building) }) {
            VStack(spacing: 12) {
                // Building image
                AsyncImage(url: URL(string: building.imageAssetName ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if building.id == primaryBuilding?.id {
                        GlassStatusBadge(
                            text: "PRIMARY",
                            style: .success,
                            size: .small
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .francoGlassCardCompact()
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
            
            if let nextTask = contextAdapter.todaysTasks.first(where: { !$0.isCompleted }) {
                insightCard(
                    title: "Next Task",
                    message: nextTask.title ?? "Task available",
                    icon: "arrow.right.circle.fill",
                    color: .blue
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
        .francoGlassCardCompact(intensity: .thick)
    }
    
    // MARK: - Map Bubble Markers
    
    private func buildingMapBubble(_ building: NamedCoordinate) -> some View {
        ZStack {
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            
            Image(systemName: "building.2.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
        .scaleEffect(selectedBuilding?.id == building.id ? 1.2 : 1.0)
        .shadow(color: .white.opacity(0.3), radius: 4)
    }
    
    // MARK: - Helper Methods
    
    private func getWorkerInitials() -> String {
        guard let worker = contextAdapter.currentWorker else { return "WO" }
        let components = worker.name.components(separatedBy: " ")
        let first = components.first?.first ?? Character("W")
        let last = components.count > 1 ? components.last?.first ?? Character("O") : Character("O")
        return "\(first)\(last)"
    }
    
    private func getUrgentTaskCount() -> Int {
        return contextAdapter.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .urgent || urgency == .critical || urgency == .emergency
        }.count
    }
    
    private func quickClockInButton(for building: NamedCoordinate) -> some View {
        Button(action: {
            Task {
                do {
                    try await viewModel.clockIn(at: building)
                } catch {
                    print("❌ Failed to clock in: \(error)")
                }
            }
        }) {  // Ensure this closing brace and opening brace are correct
            Text(building.name)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.blue.opacity(0.8))
                .clipShape(Capsule())
        }
    }
    
    private func loadWorkerSpecificData() async {
        await viewModel.loadInitialData()
        
        // Update worker name from contextAdapter
        workerName = contextAdapter.currentWorker?.name ?? "Worker"
        
        // Determine primary building for current worker
        let primary = determinePrimaryBuilding(for: contextAdapter.currentWorker?.id)
        
        // Update UI state
        self.showOnlyMyBuildings = true
        self.primaryBuilding = primary
        
        print("✅ Worker dashboard loaded: \(contextAdapter.assignedBuildings.count) buildings, primary: \(primary?.name ?? "none")")
    }
    
    private func determinePrimaryBuilding(for workerId: String?) -> NamedCoordinate? {
        let buildings = contextAdapter.assignedBuildings
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
        guard let worker = contextAdapter.currentWorker else { return "Building Operations" }
        
        switch worker.id {
        case "4": return "Museum & Property Specialist"
        case "2": return "Park Operations & Maintenance"
        case "5": return "West Village Buildings"
        case "6": return "Downtown Maintenance"
        case "1": return "Building Systems Specialist"
        case "7": return "Evening Operations"
        case "8": return "Portfolio Management"
        default: return worker.role.rawValue.capitalized
        }
    }
    
    private func navigateToBuilding(_ building: NamedCoordinate) {
        let isMyBuilding = contextAdapter.assignedBuildings.contains { $0.id == building.id }
        selectedBuilding = building
        selectedBuildingIsAssigned = isMyBuilding
        showBuildingDetail = true
    }
    
    private func getAllBuildings() -> [NamedCoordinate] {
        return contextAdapter.assignedBuildings
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
