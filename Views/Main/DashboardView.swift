//
//  DashboardView.swift
//  FrancoSphere
//
//  Complete implementation without duplicate declarations
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Dashboard View
struct DashboardView: SwiftUI.View {
    // MARK: - State Objects
    @StateObject private var authManager = NewAuthManager.shared
    
    // MARK: - State Properties
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var buildings: [FrancoSphere.NamedCoordinate] = []
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
    @State private var showingBuildingList = false
    @State private var isRefreshing = false
    @State private var notifications: [WorkerNotification] = []
    @State private var weatherAlerts: [String: WeatherAlert] = [:]
    @State private var tasksByCategory: [TaskCategory: [MaintenanceTask]] = [:]
    @State private var showTaskDetail: MaintenanceTask? = nil
    
    // Actors and managers
    private let buildingRepository = BuildingRepository.shared
    private let taskManager = TaskManager.shared
    
    // MARK: - Enums
    enum DashboardTab {
        case tasks
        case map
        case stats
    }
    
    // MARK: - Body
    var body: some SwiftUI.View {
        NavigationView {
            VStack(spacing: 0) {
                customNavigationHeader
                dashboardTabSelector
                
                ScrollView {
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
                loadBuildings()
                loadAllData()
            }
            .sheet(isPresented: $showingBuildingList) {
                MainBuildingSelectionView(
                    buildings: buildings,
                    onSelect: handleBuildingSelection
                )
            }
            .sheet(isPresented: $showTaskRequest) {
                // TaskRequestView is defined in TaskRequestView.swift
                TaskRequestView()
            }
            .sheet(isPresented: $showTimelineView) {
                NavigationView {
                    WorkerTimelineView(workerId: convertStringToInt64(authManager.workerId))
                }
            }
            .sheet(isPresented: $showNotifications) {
                NotificationsView(notifications: notifications, weatherAlerts: Array(weatherAlerts.values))
            }
            .fullScreenCover(item: $showTaskDetail) { task in
                NavigationView {
                    // DashboardTaskDetailView is defined in DashboardTaskDetailView.swift
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
        }
    }
    
    // MARK: - Custom Header
    private var customNavigationHeader: some SwiftUI.View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome, \(authManager.currentWorkerName)")
                        .font(.title2)
                        .bold()
                    
                    HStack {
                        Circle()
                            .fill(clockedInStatus.isClockedIn ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        
                        Text(clockedInStatus.isClockedIn ? "On Duty at \(currentBuildingName)" : "Not Clocked In")
                            .font(.subheadline)
                    }
                }
                
                Spacer()
                
                Button(action: { showNotifications = true }) {
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
                
                Menu {
                    Button(action: { showTimelineView = true }) {
                        Label("My Timeline", systemImage: "calendar")
                    }
                    
                    Button(action: { showTaskRequest = true }) {
                        Label("Submit Task Request", systemImage: "plus.square")
                    }
                    
                    Divider()
                    
                    Button(action: { authManager.logout() }) {
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
            
            if clockedInStatus.isClockedIn {
                clockedInStatusBar
            } else {
                clockInButton
            }
            
            Divider()
                .padding(.top, 8)
        }
    }
    
    private var clockedInStatusBar: some SwiftUI.View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Clocked in at \(currentBuildingName)")
                    .font(.callout)
                    .fontWeight(.medium)
                
                if let building = buildings.first(where: { Int64($0.id) == clockedInStatus.buildingId }) {
                    Text(building.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Clock out
                clockedInStatus = (false, nil)
                currentBuildingName = "None"
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
    
    private var clockInButton: some SwiftUI.View {
        Button(action: { showingBuildingList = true }) {
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
    private var dashboardTabSelector: some SwiftUI.View {
        HStack(spacing: 0) {
            tabButton(title: "Tasks", icon: "checklist", tab: .tasks)
            tabButton(title: "Map", icon: "map", tab: .map)
            tabButton(title: "Stats", icon: "chart.bar", tab: .stats)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(Divider(), alignment: .bottom)
    }
    
    private func tabButton(title: String, icon: String, tab: DashboardTab) -> some SwiftUI.View {
        Button(action: { withAnimation { selectedTab = tab } }) {
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
    
    // MARK: - Tasks Tab
    private var tasksTabContent: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 20) {
            tasksStatsCards
            taskCategoriesSection
            todaysTasksSection
            upcomingTasksSection
            Color.clear.frame(height: 20)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var tasksStatsCards: some SwiftUI.View {
        HStack(spacing: 12) {
            statsCard(count: todaysTasks.count, label: "Today", icon: "calendar", color: .blue)
            statsCard(count: getPendingTasksCount(), label: "Pending", icon: "hourglass", color: .orange)
            statsCard(count: getCompletedTasksCount(), label: "Completed", icon: "checkmark.circle", color: .green)
        }
    }
    
    private func statsCard(count: Int, label: String, icon: String, color: Color) -> some SwiftUI.View {
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
    
    private var taskCategoriesSection: some SwiftUI.View {
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
    
    private func categoryCard(category: TaskCategory, tasks: [MaintenanceTask]) -> some SwiftUI.View {
        Button(action: {}) {
            HStack {
                Image(systemName: self.getCategoryIcon(category))
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
    
    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        }
    }
    
    private var todaysTasksSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                Spacer()
                Text("\(todaysTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if todaysTasks.isEmpty {
                emptyTasksView(icon: "checkmark.circle", message: "No tasks scheduled for today")
            } else {
                ForEach(todaysTasks) { task in
                    TaskRowView(task: task)
                        .onTapGesture { showTaskDetail = task }
                }
            }
        }
    }
    
    private var upcomingTasksSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Tasks")
                    .font(.headline)
                Spacer()
                Text("\(upcomingTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if upcomingTasks.isEmpty {
                emptyTasksView(icon: "calendar", message: "No upcoming tasks scheduled")
            } else {
                ForEach(upcomingTasks.prefix(3)) { task in
                    TaskRowView(task: task)
                        .onTapGesture { showTaskDetail = task }
                }
            }
        }
    }
    
    private func emptyTasksView(icon: String, message: String) -> some SwiftUI.View {
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
    
    // MARK: - Map Tab
    private var mapTabContent: some SwiftUI.View {
        VStack(spacing: 15) {
            buildingsMapView
                .frame(height: 300)
                .cornerRadius(12)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("My Buildings")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(buildings) { building in
                            buildingCard(building)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            if !weatherAlerts.isEmpty {
                weatherAlertsSection
            }
            
            Spacer()
        }
        .padding(.top, 16)
    }
    
    private var weatherAlertsSection: some SwiftUI.View {
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
    
    private func weatherAlertCard(_ alert: WeatherAlert) -> some SwiftUI.View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: alert.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(colorForWeatherAlert(alert))
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
            
            Button(action: {}) {
                Text("Take Action")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(colorForWeatherAlert(alert))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .frame(width: 275)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var buildingsMapView: some SwiftUI.View {
        Map(coordinateRegion: $region, annotationItems: buildings) { building in
            MapAnnotation(coordinate: building.coordinate) {
                NavigationLink(destination: TempBuildingDetailView(building: building)) {
                    // BuildingMapMarker is defined in BuildingMapMarker.swift
                    BuildingMapMarker(
                        building: building,
                        isClockedIn: isClockedInBuilding(building)
                    )
                }
            }
        }
    }
    
    private func buildingCard(_ building: FrancoSphere.NamedCoordinate) -> some SwiftUI.View {
        NavigationLink(destination: TempBuildingDetailView(building: building)) {
            VStack(alignment: .leading, spacing: 10) {
                buildingImageView(building)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(building.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if isClockedInBuilding(building) {
                    Label("On Duty", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding(12)
            .frame(width: 200)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func buildingImageView(_ building: FrancoSphere.NamedCoordinate) -> some SwiftUI.View {
        Group {
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
    
    // MARK: - Stats Tab
    private var statsTabContent: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 20) {
            taskCompletionSection
            weeklyActivitySection
            mostVisitedBuildingsSection
            Color.clear.frame(height: 20)
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
    
    private var taskCompletionSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Task Completion")
                .font(.headline)
            
            HStack(spacing: 15) {
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
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Circle().fill(Color.blue).frame(width: 8, height: 8)
                        Text("Total Tasks: \(getAllTasksCount())")
                            .font(.subheadline)
                    }
                    HStack {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("Completed: \(getCompletedTasksCount())")
                            .font(.subheadline)
                    }
                    HStack {
                        Circle().fill(Color.orange).frame(width: 8, height: 8)
                        Text("Pending: \(getPendingTasksCount())")
                            .font(.subheadline)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var weeklyActivitySection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Activity")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(Color.blue)
                            .frame(height: CGFloat.random(in: 50...130))
                            .frame(maxWidth: .infinity)
                            .cornerRadius(4)
                        
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
    }
    
    private var mostVisitedBuildingsSection: some SwiftUI.View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most Visited Buildings")
                .font(.headline)
            
            VStack(spacing: 15) {
                ForEach(getMostVisitedBuildings(), id: \.building.id) { item in
                    HStack {
                        buildingImageView(item.building)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.building.name)
                                .font(.callout)
                                .fontWeight(.medium)
                            
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
    }
    
    private func getMostVisitedBuildings() -> [(building: FrancoSphere.NamedCoordinate, visits: Int, percentage: Double)] {
        guard !buildings.isEmpty else { return [] }
        
        // Simulated data - in production would come from database
        let totalVisits = 24
        let availableBuildings = Array(buildings.prefix(3))
        
        return availableBuildings.enumerated().map { index, building in
            let visits = totalVisits / (index + 2)
            return (building: building, visits: visits, percentage: Double(visits) / Double(totalVisits))
        }
    }
    
    // MARK: - Helper Methods
    private func handleBuildingSelection(_ building: FrancoSphere.NamedCoordinate) {
        if let buildingIdInt = Int64(building.id) {
            clockedInStatus = (true, buildingIdInt)
            currentBuildingName = building.name
            navigateToBuildingId = building.id
            loadTodaysTasks()
        }
        showingBuildingList = false
    }
    
    private func isClockedInBuilding(_ building: FrancoSphere.NamedCoordinate) -> Bool {
        if let buildingId = clockedInStatus.buildingId {
            return buildingId == Int64(building.id)
        }
        return false
    }
    
    private func convertStringToInt64(_ string: String) -> Int64 {
        return Int64(string) ?? 0
    }
    
    private func dayLabel(for day: Int) -> String {
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return days[day]
    }
    
    private func getAllTasksCount() -> Int {
        return todaysTasks.count + upcomingTasks.count
    }
    
    private func getPendingTasksCount() -> Int {
        return todaysTasks.filter { !$0.isComplete }.count + upcomingTasks.filter { !$0.isComplete }.count
    }
    
    private func getCompletedTasksCount() -> Int {
        return todaysTasks.filter { $0.isComplete }.count + upcomingTasks.filter { $0.isComplete }.count
    }
    
    private func getCompletionRate() -> Double {
        let total = getAllTasksCount()
        if total == 0 { return 0.0 }
        return Double(getCompletedTasksCount()) / Double(total)
    }
    
    private func getCategoryIcon(_ category: TaskCategory) -> String {
        switch category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench"
        case .repair: return "hammer"
        case .sanitation: return "trash"
        case .inspection: return "magnifyingglass"
        }
    }
    
    // MARK: - Data Loading
    private func loadBuildings() {
        Task {
            buildings = await buildingRepository.allBuildings
            if buildings.isEmpty {
                print("⚠️ No buildings loaded from repository")
            }
        }
    }
    
    private func loadAllData() {
        loadTodaysTasks()
        loadUpcomingTasks()
        loadTasksByCategory()
        loadWeatherAlerts()
        loadNotifications()
    }
    
    private func loadTodaysTasks() {
        // Simulated tasks for now - replace with actual TaskManager calls when available
        let calendar = Calendar.current
        let now = Date()
        
        todaysTasks = [
            MaintenanceTask(
                id: "1",
                name: "Inspect HVAC System",
                buildingID: "1",
                description: "Regular maintenance inspection",
                dueDate: calendar.date(byAdding: .hour, value: 2, to: now) ?? now,
                category: .maintenance,
                urgency: .medium,
                recurrence: .monthly
            ),
            MaintenanceTask(
                id: "2",
                name: "Lobby Floor Cleaning",
                buildingID: "2",
                description: "Deep clean lobby floor",
                dueDate: calendar.date(byAdding: .hour, value: 4, to: now) ?? now,
                category: .cleaning,
                urgency: .low,
                recurrence: .daily
            )
        ]
    }
    
    private func loadUpcomingTasks() {
        // Simulated tasks for now
        let calendar = Calendar.current
        let now = Date()
        
        upcomingTasks = [
            MaintenanceTask(
                id: "3",
                name: "Replace Air Filters",
                buildingID: "3",
                description: "Monthly filter replacement",
                dueDate: calendar.date(byAdding: .day, value: 2, to: now) ?? now,
                category: .maintenance,
                urgency: .medium,
                recurrence: .monthly
            ),
            MaintenanceTask(
                id: "4",
                name: "Window Cleaning",
                buildingID: "1",
                description: "Clean exterior windows",
                dueDate: calendar.date(byAdding: .day, value: 3, to: now) ?? now,
                category: .cleaning,
                urgency: .low,
                recurrence: .weekly
            )
        ]
    }
    
    private func loadTasksByCategory() {
        // Group existing tasks by category
        var allTasks = todaysTasks + upcomingTasks
        var grouped: [TaskCategory: [MaintenanceTask]] = [:]
        
        for category in TaskCategory.allCases {
            let tasksInCategory = allTasks.filter { $0.category == category }
            if !tasksInCategory.isEmpty {
                grouped[category] = tasksInCategory
            }
        }
        
        tasksByCategory = grouped
    }
    
    private func loadWeatherAlerts() {
        // Simulated weather alerts
        weatherAlerts = [
            "1": WeatherAlert(
                id: "1",
                buildingId: "1",
                buildingName: "12 West 18th Street",
                title: "Extreme Cold Alert",
                message: "Temperatures dropping below freezing tonight. Check pipes and heating systems.",
                icon: "thermometer.snowflake",
                color: .blue,
                timestamp: Date()
            ),
            "2": WeatherAlert(
                id: "2",
                buildingId: "3",
                buildingName: "36 Walker Street",
                title: "Heavy Rain Expected",
                message: "Check roof and drainage systems to prevent flooding.",
                icon: "cloud.rain.fill",
                color: .purple,
                timestamp: Date()
            )
        ]
    }
    
    private func loadNotifications() {
        // Simulated notifications
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
}

// MARK: - Supporting Views
// BuildingMapMarker is defined in BuildingMapMarker.swift

struct TaskRowView: SwiftUI.View {
    let task: MaintenanceTask
    
    var body: some SwiftUI.View {
        HStack(alignment: .top, spacing: 15) {
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
                
                Text("Building \(task.buildingID)")
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

struct NotificationsView: SwiftUI.View {
    let notifications: [WorkerNotification]
    let weatherAlerts: [WeatherAlert]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some SwiftUI.View {
        NavigationView {
            List {
                if !weatherAlerts.isEmpty {
                    Section(header: Text("Weather Alerts")) {
                        ForEach(weatherAlerts) { alert in
                            HStack(alignment: .top) {
                                Image(systemName: alert.icon)
                                    .foregroundColor(colorForWeatherAlert(alert))
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
}

struct WorkerTimelineView: SwiftUI.View {
    let workerId: Int64
    
    var body: some SwiftUI.View {
        VStack {
            Text("Timeline for Worker \(workerId)")
                .font(.title)
                .padding()
            
            Spacer()
        }
        .navigationTitle("My Timeline")
    }
}

struct TempBuildingDetailView: SwiftUI.View {
    let building: FrancoSphere.NamedCoordinate
    
    var body: some SwiftUI.View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(building.name)
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Building Detail View")
                .font(.title3)
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle(building.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MainBuildingSelectionView: SwiftUI.View {
    let buildings: [FrancoSphere.NamedCoordinate]
    let onSelect: (FrancoSphere.NamedCoordinate) -> Void
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var searchText: String = ""
    
    private var filtered: [FrancoSphere.NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some SwiftUI.View {
        NavigationView {
            List(filtered, id: \.id) { building in
                Button {
                    onSelect(building)
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
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

// MARK: - Supporting Types
// TaskRequestView is defined in TaskRequestView.swift
// BuildingMapMarker is defined in BuildingMapMarker.swift
// DashboardTaskDetailView is defined in DashboardTaskDetailView.swift

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

// Helper function
private func colorForWeatherAlert(_ alert: WeatherAlert) -> Color {
    switch alert.colorName {
    case "red": return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green": return .green
    case "blue": return .blue
    case "purple": return .purple
    default: return .blue
    }
}
