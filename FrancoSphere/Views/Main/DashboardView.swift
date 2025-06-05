//  DashboardView.swift
//  FrancoSphere
//
//  Updated by Shawn Magloire on 3/3/25.
//

import SwiftUI
import MapKit

// MARK: - Local Type Definitions
// Define these types here until they're properly accessible from FrancoSphereModels
struct WorkerNotification: Identifiable {
    let id: String
    let type: NotificationType
    let title: String
    let message: String
    let icon: String
    let timestamp: Date
    
    enum NotificationType {
        case taskAssigned
        case taskReminder
        case weatherAlert
        case systemMessage
        
        var color: Color {
            switch self {
            case .taskAssigned: return .blue
            case .taskReminder: return .orange
            case .weatherAlert: return .red
            case .systemMessage: return .purple
            }
        }
    }
}

struct WeatherAlert: Identifiable {
    let id: String
    let buildingId: String
    let buildingName: String
    let title: String
    let message: String
    let icon: String
    let color: Color
    let timestamp: Date
}

struct DashboardView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    // Repository and manager instances
    private let buildingRepository = BuildingRepository.shared
    
    // State variables
    @State private var showingBuildingList = false
    @State private var todaysTasks: [MaintenanceTask] = []
    @State private var upcomingTasks: [MaintenanceTask] = []
    @State private var selectedBuilding: FrancoSphere.NamedCoordinate?
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var currentBuildingName: String = "None"
    @State private var navigateToBuildingId: String? = nil
    @State private var showTaskRequest = false
    @State private var selectedTab: DashboardTab = .tasks
    @State private var showTimelineView = false
    @State private var showNotifications = false
    @State private var buildings: [FrancoSphere.NamedCoordinate] = []        // start empty
    @State private var isRefreshing = false
    @State private var notifications: [WorkerNotification] = []
    @State private var weatherAlerts: [String: WeatherAlert] = [:]
    @State private var tasksByCategory: [TaskCategory: [MaintenanceTask]] = [:]
    @State private var showTaskDetail: MaintenanceTask? = nil
    
    // SQLite Manager - use async approach
    @State private var sqliteManager: SQLiteManager?
    
    // Dashboard tabs
    enum DashboardTab {
        case tasks
        case map
        case stats
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom navigation header
                customNavigationHeader
                
                // Tab selection
                dashboardTabSelector
                
                // Main content area
                ScrollView {
                    // Show different content based on selected tab
                    switch selectedTab {
                    case .tasks:
                        tasksTabContent
                    case .map:
                        mapTabContent
                    case .stats:
                        statsTabContent
                    }
                }
                .refreshable {
                    isRefreshing = true
                    await refreshAllData()
                    isRefreshing = false
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Initialize SQLite manager and fetch building list
                Task {
                    do {
                        sqliteManager = try await SQLiteManager.start()
                        buildings = await buildingRepository.allBuildings
                    } catch {
                        print("Failed to initialize SQLiteManager: \(error)")
                    }
                }
                loadAllData()
                startLocationTracking()
            }
            .sheet(isPresented: $showingBuildingList) {
                MainBuildingSelectionView(
                    buildings: buildings,
                    onSelect: handleBuildingSelection
                )
            }
            .sheet(isPresented: $showTaskRequest) {
                TaskRequestView()
            }
            .sheet(isPresented: $showTimelineView) {
                NavigationView {
                    TimelineView(workerId: convertStringToInt64(authManager.workerId))
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView(notifications: notifications, weatherAlerts: Array(weatherAlerts.values))
            }
            .fullScreenCover(item: $showTaskDetail) { task in
                NavigationView {
                    DashboardTaskDetailView(task: task)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showTaskDetail = nil
                                }
                            }
                        }
                }
            }
            .onChange(of: clockedInStatus.isClockedIn) {
                loadTodaysTasks()
            }
        }
    }
    
    // MARK: - Custom Header
    
    private var customNavigationHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Worker profile and status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(authManager.currentWorkerName)")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        // Dynamic status indicator
                        Circle()
                            .fill(clockedInStatus.isClockedIn ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(clockedInStatus.isClockedIn ? "On Duty at \(currentBuildingName)" : "Not Clocked In")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                // Notification button
                Button(action: {
                    showNotifications = true
                }) {
                    ZStack {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.primary)
                        
                        if notifications.count > 0 || weatherAlerts.count > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .offset(x: 10, y: -10)
                        }
                    }
                    .padding(8)
                }
                
                // Settings/logout
                Menu {
                    Button(action: {
                        showTimelineView = true
                    }) {
                        Label("My Timeline", systemImage: "calendar")
                    }
                    
                    Button(action: {
                        showTaskRequest = true
                    }) {
                        Label("Submit Task Request", systemImage: "plus.square")
                    }
                    
                    Divider()
                    
                    Button(action: {
                        authManager.logout()
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(.primary)
                        .padding(8)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Clock in/out button
            if clockedInStatus.isClockedIn {
                clockedInStatusBar
            } else {
                clockInButton
            }
            
            Divider()
                .padding(.top, 8)
        }
    }
    
    private var clockedInStatusBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Clocked in at \(currentBuildingName)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                if let building = buildings.first(where: { Int64($0.id) == clockedInStatus.buildingId }) {
                    Text(building.address ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Dynamic Clock Out button
            Button(action: {
                Task {
                    if let sqliteManager = sqliteManager {
                        try? await sqliteManager.logClockOutAsync(
                            workerId: convertStringToInt64(authManager.workerId),
                            timestamp: Date()
                        )
                        clockedInStatus = (false, nil)
                        currentBuildingName = "None"
                    }
                }
            }) {
                Text("Clock Out")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var clockInButton: some View {
        Button(action: {
            showingBuildingList = true
        }) {
            HStack {
                Image(systemName: "building.2")
                    .font(.callout)
                
                Text("CLOCK IN")
                    .font(.callout)
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.purple)
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Tab Selector
    
    private var dashboardTabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Tasks", icon: "checklist", tab: .tasks)
            tabButton(title: "Map", icon: "map", tab: .map)
            tabButton(title: "Stats", icon: "chart.bar", tab: .stats)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    private func tabButton(title: String, icon: String, tab: DashboardTab) -> some View {
        Button(action: {
            withAnimation {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(selectedTab == tab ? .purple : .gray)
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Tasks Tab Content
    
    private var tasksTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Tasks statistics cards
            tasksStatsCards
            
            // Task categories
            taskCategoriesSection
            
            // Today's Tasks Section
            todaysTasksSection
            
            // Upcoming Tasks Section
            upcomingTasksSection
            
            // Padding at the bottom for better scrolling
            Color.clear.frame(height: 20)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var tasksStatsCards: some View {
        HStack(spacing: 12) {
            // Today's tasks card
            statsCard(
                count: todaysTasks.count,
                label: "Today",
                icon: "calendar",
                color: .blue
            )
            
            // Pending tasks card
            statsCard(
                count: getPendingTasksCount(),
                label: "Pending",
                icon: "hourglass",
                color: .orange
            )
            
            // Completed tasks card
            statsCard(
                count: getCompletedTasksCount(),
                label: "Completed",
                icon: "checkmark.circle",
                color: .green
            )
        }
    }
    
    private func statsCard(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
                
                Text("\(count)")
                    .font(.title3)
                    .bold()
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var taskCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Categories")
                .font(.headline)
            
            VStack(spacing: 12) {
                ForEach(Array(tasksByCategory.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                    if let tasks = tasksByCategory[category], !tasks.isEmpty {
                        categoryCard(category: category, tasks: tasks)
                    }
                }
            }
        }
    }
    
    private func categoryCard(category: TaskCategory, tasks: [MaintenanceTask]) -> some View {
        Button(action: {
            // Navigation to category detail could be added
        }) {
            HStack {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(categoryColor(category))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.headline)
                    
                    let pendingCount = tasks.filter { !$0.isComplete }.count
                    Text("\(pendingCount) pending of \(tasks.count) total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var todaysTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                
                Spacer()
                
                // Show task count
                Text("\(todaysTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if todaysTasks.isEmpty {
                emptyTasksView(
                    icon: "checkmark.circle",
                    message: "No tasks scheduled for today"
                )
            } else {
                ForEach(todaysTasks) { task in
                    TaskRowView(task: task)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showTaskDetail = task
                        }
                }
            }
        }
    }
    
    private var upcomingTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Tasks")
                    .font(.headline)
                
                Spacer()
                
                // Show task count
                Text("\(upcomingTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    showTimelineView = true
                }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            if upcomingTasks.isEmpty {
                emptyTasksView(
                    icon: "calendar",
                    message: "No upcoming tasks scheduled"
                )
            } else {
                ForEach(upcomingTasks.prefix(3)) { task in
                    TaskRowView(task: task)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showTaskDetail = task
                        }
                }
                
                if upcomingTasks.count > 3 {
                    Button(action: {
                        showTimelineView = true
                    }) {
                        Text("View \(upcomingTasks.count - 3) more upcoming tasks")
                            .font(.callout)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private func emptyTasksView(icon: String, message: String) -> some View {
        VStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(message)
                .font(.callout)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Map Tab Content
    
    private var mapTabContent: some View {
        VStack(spacing: 15) {
            // Map with buildings - Updated for iOS 17+
            buildingsMapView
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
            
            // Building list cards
            VStack(alignment: .leading, spacing: 12) {
                Text("My Buildings")
                    .font(.headline)
                    .padding(.horizontal)
                
                if assignedBuildings.isEmpty {
                    Text("You don't have any assigned buildings yet")
                        .font(.callout)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    // Scrollable building cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(assignedBuildings) { building in
                                buildingCard(building)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Weather alerts
            if !weatherAlerts.isEmpty {
                weatherAlertsSection
            }
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    // Simplified Map view using legacy API for compatibility
    private var buildingsMapView: some View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                NavigationLink(destination: BuildingDetailView(building: building)) {
                    BuildingMapMarker(
                        building: building,
                        isAssigned: isAssignedBuilding(building),
                        isClockedIn: isClockedInBuilding(building)
                    )
                }
            }
        }
    }
    
    private func buildingCard(_ building: FrancoSphere.NamedCoordinate) -> some View {
        NavigationLink(destination: BuildingDetailView(building: building)) {
            VStack(alignment: .leading, spacing: 10) {
                // Building image
                buildingImageView(building)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Building info
                Text(building.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let address = building.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Building status and clock in indicator
                HStack {
                    Spacer()
                    
                    if isClockedInBuilding(building) {
                        Label("On Duty", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    } else {
                        Text("Building Details")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(12)
            .frame(width: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func buildingImageView(_ building: FrancoSphere.NamedCoordinate) -> some View {
        Group {
            // Fixed conditional binding - properly handle optional imageAssetName
            if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                    
                    Image(systemName: "building.2.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private var weatherAlertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather Alerts")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(weatherAlerts.values)) { alert in
                        weatherAlertCard(alert)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func weatherAlertCard(_ alert: WeatherAlert) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: alert.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(alert.color)
                    .cornerRadius(10)
                
                Text(alert.title)
                    .font(.headline)
                
                Spacer()
                
                Text(alert.buildingName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(alert.message)
                .font(.callout)
                .lineLimit(2)
            
            Button(action: {
                // Navigate to building or create tasks
                if let building = buildings.first(where: { $0.id == alert.buildingId }) {
                    handleWeatherAlert(alert, building: building)
                }
            }) {
                Text("Take Action")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(alert.color)
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .frame(width: 275)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Stats Tab Content
    
    private var statsTabContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Performance overview
            VStack(alignment: .leading, spacing: 12) {
                Text("Task Completion")
                    .font(.headline)
                
                HStack(spacing: 15) {
                    // Completion rate circular progress
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(getCompletionRate()))
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(getCompletionRate() * 100))%")
                                .font(.title2)
                                .bold()
                            
                            Text("Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Task stats
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 8, height: 8)
                            
                            Text("Total Tasks: \(getAllTasksCount())")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text("Completed: \(getCompletedTasksCount())")
                                .font(.subheadline)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 8, height: 8)
                            
                            Text("Pending: \(getPendingTasksCount())")
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Weekly activity
            VStack(alignment: .leading, spacing: 12) {
                Text("Weekly Activity")
                    .font(.headline)
                
                HStack(alignment: .bottom, spacing: 5) {
                    ForEach(0..<7, id: \.self) { day in
                        VStack(spacing: 4) {
                            // Activity bar
                            Rectangle()
                                .fill(dayColor(for: day, height: dayHeight(for: day)))
                                .frame(height: dayHeight(for: day))
                                .frame(maxWidth: .infinity)
                                .cornerRadius(4)
                            
                            // Day label
                            Text(dayLabel(for: day))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Most visited buildings
            VStack(alignment: .leading, spacing: 12) {
                Text("Most Visited Buildings")
                    .font(.headline)
                
                VStack(spacing: 15) {
                    ForEach(getMostVisitedBuildings(), id: \.building.id) { item in
                        HStack {
                            // Building image or icon
                            buildingImageView(item.building)
                                .frame(width: 40, height: 40)
                                .cornerRadius(8)
                            
                            // Building info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.building.name)
                                    .font(.callout)
                                    .fontWeight(.medium)
                                
                                // Progress bar showing percentage of visits
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.2))
                                            .frame(width: geometry.size.width, height: 6)
                                            .cornerRadius(3)
                                        
                                        Rectangle()
                                            .fill(Color.blue)
                                            .frame(width: geometry.size.width * CGFloat(item.percentage), height: 6)
                                            .cornerRadius(3)
                                    }
                                }
                                .frame(height: 6)
                                
                                Text("\(item.visits) visits")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Padding at the bottom for better scrolling
            Color.clear.frame(height: 20)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    // MARK: - Supporting Views
    
    // Renamed to avoid conflict with the main BuildingMapMarker
    private struct BuildingMapMarker: View {
        let building: FrancoSphere.NamedCoordinate
        let isAssigned: Bool
        let isClockedIn: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(markerColor)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .shadow(radius: 2)
                    
                    // Fixed conditional binding - properly check imageAssetName
                    if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                    } else {
                        Text(building.name.prefix(2))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if isClockedIn {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 15, y: -15)
                    }
                }
                
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 12))
                    .foregroundColor(markerColor)
                    .offset(y: -5)
            }
        }
        
        private var markerColor: Color {
            if isClockedIn {
                return .green
            } else if isAssigned {
                return .purple
            } else {
                return .gray
            }
        }
    }
    
    private struct TaskRowView: View {
        let task: MaintenanceTask
        private let buildingRepository = BuildingRepository.shared
        
        var body: some View {
            HStack(alignment: .top, spacing: 15) {
                // Task status indicator
                ZStack {
                    Circle()
                        .fill(task.statusColor.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: task.isComplete ? "checkmark.circle.fill" : task.category.icon)
                        .foregroundColor(task.statusColor)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(task.name)
                            .font(.callout)
                            .fontWeight(.medium)
                        
                        if task.urgency == .urgent || task.urgency == .high {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(task.urgency == .urgent ? .red : .orange)
                                .font(.caption2)
                        }
                    }
                    
                    // Direct building name access
                    let buildingName = buildingRepository.getBuildingName(forId: task.buildingID)
                    Text(buildingName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        Label(formatTime(task.dueDate), systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if task.recurrence != .oneTime {
                            Label(task.recurrence.rawValue, systemImage: "repeat")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Task status badge
                Text(task.statusText)
                    .font(.caption)
                    .foregroundColor(task.statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.statusColor.opacity(0.1))
                    .cornerRadius(8)
            }
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        
        private func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
    }
    
    private struct NotificationsView: View {
        let notifications: [WorkerNotification]
        let weatherAlerts: [WeatherAlert]
        @Environment(\.presentationMode) var presentationMode
        
        var body: some View {
            NavigationView {
                List {
                    if !weatherAlerts.isEmpty {
                        Section(header: Text("Weather Alerts")) {
                            ForEach(weatherAlerts) { alert in
                                HStack(alignment: .top) {
                                    Image(systemName: alert.icon)
                                        .foregroundColor(alert.color)
                                        .font(.title3)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(alert.title)
                                            .font(.headline)
                                        
                                        Text(alert.buildingName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text(alert.message)
                                            .font(.callout)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    
                    if !notifications.isEmpty {
                        Section(header: Text("Notifications")) {
                            ForEach(notifications) { notification in
                                HStack(alignment: .top) {
                                    Image(systemName: notification.icon)
                                        .foregroundColor(notification.type.color)
                                        .font(.title3)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(notification.title)
                                            .font(.headline)
                                        
                                        Text(notification.message)
                                            .font(.callout)
                                        
                                        Text(formatDate(notification.timestamp))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    
                    if notifications.isEmpty && weatherAlerts.isEmpty {
                        Section {
                            Text("No notifications")
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Notifications")
                .navigationBarItems(trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                })
            }
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleBuildingSelection(_ building: FrancoSphere.NamedCoordinate) {
        if let buildingIdInt = Int64(building.id) {
            Task {
                if let sqliteManager = sqliteManager {
                    let currentStatus = await sqliteManager.isWorkerClockedInAsync(
                        workerId: convertStringToInt64(authManager.workerId)
                    )
                    
                    // Clock in the worker
                    try? await sqliteManager.logClockInAsync(
                        workerId: convertStringToInt64(authManager.workerId),
                        buildingId: buildingIdInt,
                        timestamp: Date()
                    )
                    
                    // Update status after clock in
                    clockedInStatus = (true, buildingIdInt)
                    currentBuildingName = building.name
                    // Navigate to the selected building's detail view
                    navigateToBuildingId = building.id
                    // Refresh tasks after clock-in
                    loadTodaysTasks()
                }
            }
        }
        showingBuildingList = false
    }
    
    private func handleWeatherAlert(_ alert: WeatherAlert, building: FrancoSphere.NamedCoordinate) {
        // Navigate to building details
        navigateToBuildingId = building.id
    }
    
    private var assignedBuildings: [FrancoSphere.NamedCoordinate] {
        // Temporary implementation - returns all buildings
        return buildings
    }
    
    private func isAssignedBuilding(_ building: FrancoSphere.NamedCoordinate) -> Bool {
        // Temporary implementation - returns true for all buildings
        return true
    }
    
    private func isClockedInBuilding(_ building: FrancoSphere.NamedCoordinate) -> Bool {
        if let buildingId = clockedInStatus.buildingId {
            return buildingId == Int64(building.id)
        }
        return false
    }
    
    private func dayHeight(for day: Int) -> CGFloat {
        // Simulate task data for the demo
        let heights: [CGFloat] = [80, 110, 60, 90, 130, 70, 50]
        return heights[day]
    }
    
    private func dayColor(for day: Int, height: CGFloat) -> Color {
        if height > 100 {
            return .green
        } else if height > 80 {
            return .blue
        } else if height > 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func dayLabel(for day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day]
    }
    
    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // MARK: - Task Statistics
    
    private func getAllTasksCount() -> Int {
        return todaysTasks.count + upcomingTasks.count
    }
    
    private func getPendingTasksCount() -> Int {
        return todaysTasks.filter { !$0.isComplete }.count + upcomingTasks.filter { !$0.isComplete }.count
    }
    
    private func getCompletedTasksCount() -> Int {
        return (todaysTasks.filter { $0.isComplete }.count) + (upcomingTasks.filter { $0.isComplete }.count)
    }
    
    private func getCompletionRate() -> Double {
        let total = getAllTasksCount()
        if total == 0 {
            return 0.0
        }
        return Double(getCompletedTasksCount()) / Double(total)
    }
    
    private func getMostVisitedBuildings() -> [(building: FrancoSphere.NamedCoordinate, visits: Int, percentage: Double)] {
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
        var result: [(building: FrancoSphere.NamedCoordinate, visits: Int, percentage: Double)] = []
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
    
    // MARK: - Data Loading
    
    private func loadAllData() {
        checkClockInStatus()
        loadTodaysTasks()
        loadUpcomingTasks()
        loadWeatherAlerts()
        loadNotifications()
        loadTasksByCategory()
        centerMapOnCurrentLocation()
    }
    
    private func checkClockInStatus() {
        Task {
            if let sqliteManager = sqliteManager {
                let status = await sqliteManager.isWorkerClockedInAsync(
                    workerId: convertStringToInt64(authManager.workerId)
                )
                clockedInStatus = status
                
                // Update building name if clocked in
                if status.isClockedIn, let buildingId = status.buildingId {
                    if let building = buildings.first(where: { Int64($0.id) == buildingId }) {
                        currentBuildingName = building.name
                    } else {
                        currentBuildingName = "Building #\(buildingId)"
                    }
                }
            }
        }
    }
    
    private func loadTodaysTasks() {
        // In a real app, fetch from TaskManager
        // For now, simulate with sample data
        let now = Date()
        let calendar = Calendar.current
        
        todaysTasks = [
            MaintenanceTask(
                id: "1",
                name: "Inspect HVAC System",
                buildingID: "1",
                description: "Regular maintenance inspection of HVAC units",
                dueDate: calendar.date(byAdding: .hour, value: 2, to: now) ?? now,
                category: .maintenance,
                urgency: .medium,
                recurrence: .monthly
            ),
            MaintenanceTask(
                id: "2",
                name: "Lobby Floor Cleaning",
                buildingID: "2",
                description: "Deep clean the lobby floor and entrance mats",
                dueDate: calendar.date(byAdding: .hour, value: 4, to: now) ?? now,
                category: .cleaning,
                urgency: .low,
                recurrence: .daily
            ),
            MaintenanceTask(
                id: "3",
                name: "Fix Elevator Door",
                buildingID: "1",
                description: "Door is closing too quickly, adjust timing mechanism",
                dueDate: calendar.date(byAdding: .hour, value: 1, to: now) ?? now,
                category: .repair,
                urgency: .high,
                recurrence: .oneTime,
                isComplete: false
            )
        ]
        
        // Sort by urgency then time
        todaysTasks.sort { (task1, task2) -> Bool in
            if task1.urgency != task2.urgency {
                return task1.urgency.rawValue > task2.urgency.rawValue
            }
            return task1.dueDate < task2.dueDate
        }
    }
    
    private func loadUpcomingTasks() {
        // In a real app, fetch from TaskManager
        // For now, simulate with sample data
        let now = Date()
        let calendar = Calendar.current
        
        upcomingTasks = [
            MaintenanceTask(
                id: "4",
                name: "Replace Air Filters",
                buildingID: "3",
                description: "Replace all HVAC air filters throughout the building",
                dueDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                category: .maintenance,
                urgency: .medium,
                recurrence: .monthly
            ),
            MaintenanceTask(
                id: "5",
                name: "Inspect Fire Extinguishers",
                buildingID: "1",
                description: "Check all fire extinguishers for proper pressure and expiration",
                dueDate: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                category: .inspection,
                urgency: .high,
                recurrence: .monthly
            ),
            MaintenanceTask(
                id: "6",
                name: "Clean Windows",
                buildingID: "2",
                description: "Clean all exterior windows on ground floor",
                dueDate: calendar.date(byAdding: .day, value: 1, to: now) ?? now,
                category: .cleaning,
                urgency: .low,
                recurrence: .weekly
            ),
            MaintenanceTask(
                id: "7",
                name: "Check Plumbing Systems",
                buildingID: "3",
                description: "Inspect all common area plumbing for leaks",
                dueDate: calendar.date(byAdding: .day, value: 4, to: now) ?? now,
                category: .maintenance,
                urgency: .medium,
                recurrence: .monthly
            )
        ]
        
        // Sort by date
        upcomingTasks.sort { $0.dueDate < $1.dueDate }
    }
    
    private func loadTasksByCategory() {
        // Combine today's and upcoming tasks
        var allTasks = todaysTasks + upcomingTasks
        
        // Group by category
        var groupedTasks: [TaskCategory: [MaintenanceTask]] = [:]
        
        for category in TaskCategory.allCases {
            let tasksInCategory = allTasks.filter { $0.category == category }
            if !tasksInCategory.isEmpty {
                groupedTasks[category] = tasksInCategory
            }
        }
        
        tasksByCategory = groupedTasks
    }
    
    private func loadWeatherAlerts() {
        // In a real app, fetch from weather service
        // For now, create sample alerts
        weatherAlerts = [:]
        
        // Add sample weather alerts
        let alert1 = WeatherAlert(
            id: "1",
            buildingId: "1",
            buildingName: "12 West 18th Street",
            title: "Extreme Cold Alert",
            message: "Temperatures dropping below freezing tonight. Check pipes and heating systems.",
            icon: "thermometer.snowflake",
            color: .blue,
            timestamp: Date()
        )
        
        let alert2 = WeatherAlert(
            id: "2",
            buildingId: "3",
            buildingName: "36 Walker Street",
            title: "Heavy Rain Expected",
            message: "Check roof and drainage systems to prevent flooding.",
            icon: "cloud.rain.fill",
            color: .purple,
            timestamp: Date()
        )
        
        weatherAlerts[alert1.id] = alert1
        weatherAlerts[alert2.id] = alert2
    }
    
    private func loadNotifications() {
        // In a real app, fetch from database
        // For now, create sample notifications
        notifications = [
            WorkerNotification(
                id: "1",
                type: .taskAssigned,
                title: "New Task Assigned",
                message: "You have been assigned to 'Elevator Maintenance' task",
                icon: "bell.badge.fill",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            WorkerNotification(
                id: "2",
                type: .taskReminder,
                title: "Task Due Soon",
                message: "Reminder: 'Lobby Cleaning' is due in 1 hour",
                icon: "clock.fill",
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
    }
    
    private func refreshAllData() async {
        loadAllData()
    }
    
    private func startLocationTracking() {
        // In a real app, this would use CoreLocation
        print("Starting location tracking...")
    }
    
    private func centerMapOnCurrentLocation() {
        // In a real app, use the user's current location
        // For now, center on Manhattan or first assigned building
        if let building = assignedBuildings.first {
            region = MKCoordinateRegion(
                center: building.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        }
    }
}

// MARK: - Utility Functions

// Helper function to convert String to Int64
private func convertStringToInt64(_ string: String) -> Int64 {
    return Int64(string) ?? 0
}

// MARK: - Stubs to satisfy missing types (remove or replace once real implementations exist)

import SwiftUI

/// Stub for AuthManager
/// Replace with your real AuthManager (e.g. an actor or class that provides `shared`, `currentWorkerName`, `workerId`, and `logout()`)
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    @Published var currentWorkerName: String = "Worker Name"
    let workerId: String = "worker_123"
    
    private init() { }
    func logout() { /* no-op stub */ }
}

/// Stub for MainBuildingSelectionView
/// Replace with your real view that lets the user pick a building from a list
struct MainBuildingSelectionView: View {
    let buildings: [FrancoSphere.NamedCoordinate]
    let onSelect: (FrancoSphere.NamedCoordinate) -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchText: String = ""
    
    private var filtered: [FrancoSphere.NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.address ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filtered, id: \.id) { bldg in
                    Button {
                        onSelect(bldg)
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(bldg.name).font(.headline)
                            if let addr = bldg.address {
                                Text(addr).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Building")
            .searchable(text: $searchText, prompt: "Search buildings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
