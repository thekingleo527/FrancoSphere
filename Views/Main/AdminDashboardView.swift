//
//  AdminDashboardView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/13/25.
//

import SwiftUI
import MapKit

struct AdminDashboardView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    // Building data - Use @State for async loading
    @State private var buildings: [FrancoSphere.NamedCoordinate] = []
    @State private var isLoadingBuildings = false
    
    // State variables
    @State private var activeWorkers: [FrancoSphere.WorkerProfile] = []
    @State private var ongoingTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var inventoryAlerts: [FrancoSphere.InventoryItem] = []
    @State private var selectedTab = 0
    @State private var showNewTaskSheet = false
    @State private var isRefreshing = false
    @State private var selectedBuilding: FrancoSphere.NamedCoordinate? = nil
    
    // Map region
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom dashboard header with profile and quick actions
                adminDashboardHeader
                
                // Main scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        // Statistics cards grid
                        statisticsSection
                        
                        // Buildings map
                        buildingsMapSection
                        
                        // Most visited buildings
                        mostVisitedBuildingsSection
                        
                        // Active workers
                        activeWorkersSection
                        
                        // Ongoing tasks
                        ongoingTasksSection
                        
                        // Inventory alerts
                        if !inventoryAlerts.isEmpty {
                            inventoryAlertsSection
                        }
                        
                        // Weather insights for all buildings
                        weatherInsightsSection
                    }
                    .padding(.horizontal)
                }
                .refreshable {
                    await refreshData()
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadBuildings()
                loadDashboardData()
            }
            .sheet(isPresented: $showNewTaskSheet) {
                TaskRequestView()
            }
        }
    }
    
    // MARK: - Dashboard Header
    
    private var adminDashboardHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // User profile and greeting
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(authManager.currentWorkerName)")
                        .font(.title2)
                        .bold()
                    
                    Text("Admin Dashboard")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        showNewTaskSheet = true
                    }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.blue)
                    }
                    
                    Menu {
                        Button(action: {
                            authManager.logout()
                        }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        
                        Button(action: {
                            // Settings action
                        }) {
                            Label("Settings", systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.system(size: 22))
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Tab selector
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Buildings").tag(1)
                Text("Workers").tag(2)
                Text("Tasks").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
                .padding(.top, 8)
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            statisticsCard(
                title: "Buildings",
                value: "\(buildings.count)",
                icon: "building.2.fill",
                color: .blue
            )
            
            statisticsCard(
                title: "Active Workers",
                value: "\(activeWorkers.count)",
                icon: "person.fill",
                color: .green
            )
            
            statisticsCard(
                title: "Tasks Today",
                value: "\(ongoingTasks.count)",
                icon: "checklist.checked",
                color: .orange
            )
            
            statisticsCard(
                title: "Inventory Alerts",
                value: "\(inventoryAlerts.count)",
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
    }
    
    private func statisticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Buildings Map Section (FIXED COMPLEX EXPRESSION)
    
    private var buildingsMapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Building Locations")
                .font(.headline)
            
            if isLoadingBuildings {
                ProgressView()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            } else {
                buildingsMap
            }
        }
    }
    
    // BROKEN DOWN TO FIX COMPLEX EXPRESSION
    private var buildingsMap: some View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                AdminBuildingMarker(building: building)
            }
        }
        .frame(height: 200)
        .cornerRadius(12)
    }
    
    // MARK: - Most Visited Buildings Section
    
    private var mostVisitedBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Most Visited Buildings")
                .font(.headline)
            
            ForEach(getMostVisitedBuildings(), id: \.building.id) { item in
                NavigationLink(destination: AdminBuildingDetailView(building: item.building)) {
                    HStack {
                        // Building icon
                        buildingIcon(for: item.building)
                        
                        // Building info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.building.name)
                                .font(.headline)
                            
                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: geometry.size.width, height: 6)
                                        .opacity(0.3)
                                        .foregroundColor(.blue)
                                    
                                    Rectangle()
                                        .frame(width: min(CGFloat(item.percentage) * geometry.size.width, geometry.size.width), height: 6)
                                        .foregroundColor(.blue)
                                }
                                .cornerRadius(3)
                            }
                            .frame(height: 6)
                            
                            Text("\(item.visits) visits (\(Int(item.percentage * 100))%)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Active Workers Section
    
    private var activeWorkersSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Workers")
                .font(.headline)
            
            if activeWorkers.isEmpty {
                Text("No workers are currently active")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeWorkers) { worker in
                            workerCard(worker)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    private func workerCard(_ worker: FrancoSphere.WorkerProfile) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // Worker avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Text(String(worker.name.prefix(2).uppercased()))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Worker name
            Text(worker.name)
                .font(.callout)
                .fontWeight(.medium)
                .lineLimit(1)
            
            // Worker status
            Text(worker.role.rawValue)
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(getWorkerRoleColor(worker.role))
                .cornerRadius(8)
        }
        .frame(width: 120)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func getWorkerRoleColor(_ role: FrancoSphere.UserRole) -> Color {
        switch role {
        case .admin:
            return .purple
        case .manager:
            return .blue
        case .worker:
            return .green
        @unknown default:
            return .gray
        }
    }
    
    // MARK: - Ongoing Tasks Section
    
    private var ongoingTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Ongoing Tasks")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: Text("Task Management")) {
                    HStack {
                        Text("View All")
                            .font(.caption)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                }
            }
            
            if ongoingTasks.isEmpty {
                Text("No ongoing tasks")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(ongoingTasks.prefix(3), id: \.id) { task in
                    taskListItem(task)
                }
            }
        }
    }
    
    private func taskListItem(_ task: FrancoSphere.MaintenanceTask) -> some View {
        NavigationLink(destination: Text("Task Detail View")) {
            HStack(spacing: 12) {
                // Task icon with status color
                Image(systemName: task.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(task.statusColor)
                    .cornerRadius(8)
                
                // Task details
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    // Location and time
                    HStack(spacing: 8) {
                        Text(getBuildingName(for: task.buildingID))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let startTime = task.startTime {
                            Text(formatTime(startTime))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Status pill
                Text(task.statusText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.statusColor.opacity(0.1))
                    .foregroundColor(task.statusColor)
                    .cornerRadius(12)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Inventory Alerts Section
    
    private var inventoryAlertsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Inventory Alerts")
                .font(.headline)
            
            ForEach(inventoryAlerts) { item in
                inventoryAlertItem(item)
            }
        }
    }
    
    private func inventoryAlertItem(_ item: FrancoSphere.InventoryItem) -> some View {
        NavigationLink(destination: Text("Inventory Detail")) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: item.category.systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(item.quantity <= 0 ? Color.red : (item.quantity <= item.minimumQuantity ? Color.orange : Color.green))
                    .cornerRadius(8)
                
                // Item details
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Building: \(getBuildingName(for: item.buildingID))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Quantity pill
                VStack(alignment: .trailing, spacing: 2) {
                    Text(item.statusText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(item.statusColor.opacity(0.1))
                        .foregroundColor(item.statusColor)
                        .cornerRadius(12)
                    
                    Text("\(item.quantity) \(item.unit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Weather Insights Section
    
    private var weatherInsightsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌦 Weather Insights")
                .font(.headline)
            
            if selectedTab == 0 {
                // In overview tab, show a summary
                let buildingsWithRisks = buildings.filter { building in
                    // Simplified check - in real app, use WeatherService
                    false // Placeholder
                }
                
                if buildingsWithRisks.isEmpty {
                    Text("No weather risks identified for buildings")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    ForEach(buildingsWithRisks.prefix(3)) { building in
                        weatherRiskItem(building)
                    }
                    
                    if buildingsWithRisks.count > 3 {
                        Button(action: {
                            // Navigate to a more detailed weather view
                            selectedTab = 1 // Switch to buildings tab
                        }) {
                            Text("View \(buildingsWithRisks.count - 3) more affected buildings")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            } else if let selectedBuilding = selectedBuilding {
                // Show weather details for selected building
                weatherRiskItem(selectedBuilding)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() async {
        isRefreshing = true
        await loadBuildings()
        loadDashboardData()
        isRefreshing = false
    }
    
    private func loadBuildings() async {
        isLoadingBuildings = true
        
        // Load buildings from repository
        Task { @MainActor in
            buildings = await BuildingRepository.shared.allBuildings
            isLoadingBuildings = false
        }
    }
    
    private func loadDashboardData() {
        // Load active workers
        activeWorkers = FrancoSphere.WorkerProfile.allWorkers
        
        // Load ongoing tasks from all buildings
        var allTasks: [FrancoSphere.MaintenanceTask] = []
        for building in buildings {
            let buildingTasks = TaskManager.shared.fetchTasks(forBuilding: building.id, includePastTasks: false)
            allTasks.append(contentsOf: buildingTasks)
        }
        ongoingTasks = allTasks.filter { !$0.isComplete }
        
        // Load inventory alerts from all buildings
        var allInventoryAlerts: [FrancoSphere.InventoryItem] = []
        for building in buildings {
            // Create mock inventory items since InventoryManager might not exist
            let mockItems = createMockInventoryItems(forBuilding: building.id)
            let alerts = mockItems.filter { $0.needsReorder }
            allInventoryAlerts.append(contentsOf: alerts)
        }
        inventoryAlerts = allInventoryAlerts
    }
    
    // MARK: - Helper Components
    
    private func buildingIcon(for building: FrancoSphere.NamedCoordinate) -> some View {
        Group {
            if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.gray)
                    .frame(width: 50, height: 50)
            }
        }
    }
    
    // Building visit data structure
    struct BuildingVisitData {
        let building: FrancoSphere.NamedCoordinate
        let visits: Int
        let percentage: Double
    }
    
    private func getMostVisitedBuildings() -> [BuildingVisitData] {
        // Mock data for most visited buildings
        let mockVisits: [(String, Int)] = [
            ("1", 45),  // 12 West 18th Street
            ("2", 38),  // 29-31 East 20th Street
            ("3", 32),  // 36 Walker Street
            ("7", 28),  // 112 West 18th Street
            ("8", 25)   // 117 West 17th Street
        ]
        
        let totalVisits = mockVisits.reduce(0) { $0 + $1.1 }
        
        return mockVisits.compactMap { (buildingId, visits) in
            guard let building = buildings.first(where: { $0.id == buildingId }) else { return nil }
            let percentage = Double(visits) / Double(totalVisits)
            return BuildingVisitData(building: building, visits: visits, percentage: percentage)
        }
        .sorted { $0.visits > $1.visits }
        .prefix(5)
        .map { $0 }
    }
    
    private func getBuildingName(for buildingID: String) -> String {
        return buildings.first { $0.id == buildingID }?.name ?? "Unknown Building"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func weatherRiskItem(_ building: FrancoSphere.NamedCoordinate) -> some View {
        HStack(spacing: 12) {
            // Weather icon
            Image(systemName: "cloud.rain.fill")
                .font(.system(size: 18))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.orange)
                .cornerRadius(8)
            
            // Building details
            VStack(alignment: .leading, spacing: 3) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("Rain expected - Check drainage systems")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Risk level
            Text("Moderate")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .foregroundColor(.orange)
                .cornerRadius(12)
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func createMockInventoryItems(forBuilding buildingId: String) -> [FrancoSphere.InventoryItem] {
        // Create mock inventory items for demo
        return [
            FrancoSphere.InventoryItem(
                name: "Paper Towels",
                buildingID: buildingId,
                category: .cleaning,
                quantity: 2,
                unit: "rolls",
                minimumQuantity: 5,
                needsReorder: true
            ),
            FrancoSphere.InventoryItem(
                name: "Light Bulbs",
                buildingID: buildingId,
                category: .electrical,
                quantity: 0,
                unit: "units",
                minimumQuantity: 10,
                needsReorder: true
            )
        ]
    }
}

// MARK: - Supporting Components

// FIXED: Admin Building Marker Component (simplified to avoid complex expression)
private struct AdminBuildingMarker: View {
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        NavigationLink(destination: AdminBuildingDetailView(building: building)) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(radius: 2)
                
                buildingContent
            }
        }
    }
    
    @ViewBuilder
    private var buildingContent: some View {
        if !building.imageAssetName.isEmpty,
           let uiImage = UIImage(named: building.imageAssetName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())
        } else {
            Text(String(building.name.prefix(2)))
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// FIXED: Placeholder for building detail view
private struct AdminBuildingDetailView: View {
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(building.name)
                .font(.title2)
                .fontWeight(.bold)
            
            // FIXED: Replace address with coordinate information since address property doesn't exist
            VStack(spacing: 4) {
                Text("Location")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Lat: \(String(format: "%.4f", building.latitude))")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("Lng: \(String(format: "%.4f", building.longitude))")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            Text("Admin Building Detail View")
                .font(.title3)
                .foregroundColor(.gray)
            
            Text("This will be enhanced with admin-specific building management features")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .navigationTitle(building.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
