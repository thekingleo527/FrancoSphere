//
//  AdminDashboardView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/13/25.
//


import SwiftUI
import MapKit

struct AdminDashboardView: View {
    @StateObject private var authManager = AuthManager.shared
    
    // Building data
    private let buildingRepository = BuildingRepository.shared
    private var buildings: [NamedCoordinate] {
        buildingRepository.buildings
    }
    
    // State variables
    @State private var activeWorkers: [WorkerProfile] = []
    @State private var ongoingTasks: [MaintenanceTask] = []
    @State private var inventoryAlerts: [InventoryItem] = []
    @State private var selectedTab = 0
    @State private var showNewTaskSheet = false
    @State private var isRefreshing = false
    
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
                    isRefreshing = true
                    // Simulate refresh
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    loadDashboardData()
                    isRefreshing = false
                }
            }
            .navigationBarHidden(true)
            .onAppear {
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
    
    // MARK: - Buildings Map Section
    
    private var buildingsMapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Building Locations")
                .font(.headline)
            
            // In the buildingsMapSection method:
            Map(coordinateRegion: $region, annotationItems: buildings) { building in
                MapAnnotation(coordinate: building.coordinate) {
                    NavigationLink(destination: BuildingDetailView(building: building)) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 40, height: 40)  // Slightly larger
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                                .shadow(radius: 2)
                            
                            // Load building image from Preview Assets
                            let imageName = "building_\(building.id)"
                            if let uiImage = UIImage(named: imageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 36, height: 36)  // Slightly larger
                                    .clipShape(Circle())
                            } else {
                                // Fallback to building initials if image not found
                                Text(building.name.prefix(2))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Most Visited Buildings Section
    
    private var mostVisitedBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Most Visited Buildings")
                .font(.headline)
            
            ForEach(getMostVisitedBuildings(), id: \.building.id) { item in
                NavigationLink(destination: BuildingDetailView(building: item.building)) {
                    HStack {
                        // Building icon
                        if !item.building.imageAssetName.isEmpty, let uiImage = UIImage(named: item.building.imageAssetName) {
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
    
    private func workerCard(_ worker: WorkerProfile) -> some View {
        VStack(alignment: .center, spacing: 8) {
            // Worker avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 70, height: 70)
                
                Text(worker.name.prefix(2).uppercased())
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
    
    private func getWorkerRoleColor(_ role: UserRole) -> Color {
        switch role {
        case .admin:
            return .purple
        case .manager:
            return .blue
        case .worker:
            return .green
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
    
    private func taskListItem(_ task: MaintenanceTask) -> some View {
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
                        Text(buildingRepository.getBuildingName(forId: task.buildingID))
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
    
    private func inventoryAlertItem(_ item: InventoryItem) -> some View {
        NavigationLink(destination: Text("Inventory Detail")) {
            HStack(spacing: 12) {
                // Category icon
                Image(systemName: item.category.systemImage)
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(item.statusColor)
                    .cornerRadius(8)
                
                // Item details
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Building: \(buildingRepository.getBuildingName(forId: item.buildingID))")
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
                let buildingsWithRisks = buildings.filter {
                    WeatherService.shared.assessWeatherRisk(for: $0) != "No significant risks"
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
                // When a building is focused, show detailed weather
                WeatherDashboardComponent(building: selectedBuilding)
            } else if buildings.count > 0 {
                // In buildings tab, show the weather component for the first building
                WeatherDashboardComponent(building: buildings[0])
            }
        }
    }
    
    private func weatherRiskItem(_ building: NamedCoordinate) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button(action: {
                    selectedBuilding = building
                    selectedTab = 1
                }) {
                    Text("Details")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if let currentWeather = WeatherService.shared.currentWeather {
                HStack(spacing: 12) {
                    // Weather icon
                    Image(systemName: currentWeather.condition.icon)
                        .foregroundColor(currentWeather.condition.color)
                    
                    Text("\(Int(currentWeather.temperature))°F")
                        .font(.caption)
                    
                    Text(currentWeather.condition.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if currentWeather.isHazardous {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            
            if let notification = WeatherService.shared.createWeatherNotification(for: building) {
                Text(notification)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    // Track selected building for detailed view
    @State private var selectedBuilding: NamedCoordinate? = nil
    
    private func getMostVisitedBuildings() -> [(building: NamedCoordinate, visits: Int, percentage: Double)] {
        // In a real app, fetch from database
        // This is simulated data
        let totalVisits = 24
        
        // SAFETY CHECK: Ensure we have buildings to work with
        guard !buildings.isEmpty else {
            return []
        }
        
        // Take up to 3 buildings
        let availableBuildings = Array(buildings.prefix(3))
        
        // Calculate visits dynamically based on available buildings
        var result: [(building: NamedCoordinate, visits: Int, percentage: Double)] = []
        var remainingVisits = totalVisits
        
        for (index, building) in availableBuildings.enumerated() {
            let visits: Int
            if index == availableBuildings.count - 1 {
                visits = remainingVisits // Assign remaining visits to last building
            } else {
                visits = totalVisits / (index + 2) // Distribute visits
                remainingVisits -= visits
            }
            
            result.append((
                building: building,
                visits: visits,
                percentage: Double(visits) / Double(totalVisits)
            ))
        }
        
        return result
    }
    
    private func loadDashboardData() {
        // Load active workers (in a real app, fetch from database)
        activeWorkers = [
            WorkerProfile(
                id: "1",
                name: "John Smith",
                email: "john@example.com",
                role: .worker,
                skills: [.maintenance, .cleaning]
            ),
            WorkerProfile(
                id: "2",
                name: "Maria Garcia",
                email: "maria@example.com",
                role: .worker,
                skills: [.electrical, .plumbing]
            ),
            WorkerProfile(
                id: "3",
                name: "David Chen",
                email: "david@example.com",
                role: .manager,
                skills: [.management]
            )
        ]
        
        // Load ongoing tasks (in a real app, fetch from database)
        let taskManager = TaskManager.shared
        ongoingTasks = []
        
        // Get tasks for each building
        for building in buildings {
            let buildingTasks: [MaintenanceTask] = taskManager.fetchTasks(forBuilding: building.id, includePastTasks: false)
            ongoingTasks.append(contentsOf: buildingTasks)
        }
        
        // Sort by urgency
        ongoingTasks.sort { $0.urgency.rawValue > $1.urgency.rawValue }
        
        // Load inventory alerts (in a real app, fetch from database)
        inventoryAlerts = []
        
        // Get low stock items for each building - USING THE SAFE METHOD
        for building in buildings {
            let buildingInventory = InventoryManager.shared.getInventoryItemsSafe(forBuilding: building.id)
            let lowStockItems = buildingInventory.filter { $0.shouldReorder }
            inventoryAlerts.append(contentsOf: lowStockItems)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct AdminDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AdminDashboardView()
    }
}
