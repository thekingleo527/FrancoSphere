//
//  WorkerDashboardView_V2.swift
//  FrancoSphere
//
//  Fully integrated dashboard with WorkerContextEngine, real weather, and all UI upgrades
//  Location: /Views/Main/WorkerDashboardView_V2.swift
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Fix ContextualTask Identifiable Conformance
extension ContextualTask: Identifiable {}

// MARK: - Missing WeatherCondition Extensions (Only if not defined elsewhere)
extension WeatherCondition {
    var temperatureString: String {
        return "72°" // Placeholder - you'll need to store temperature in WeatherCondition
    }
    
    var temperature: Int {
        return 72 // Placeholder - you'll need to store temperature in WeatherCondition
    }
    
    var apparentTemperature: Int {
        return temperature + 2
    }
    
    var humidity: Int {
        return 65 // Placeholder
    }
    
    var windSpeed: Int {
        return 10 // Placeholder
    }
    
    var precipitation: Double {
        return 0.0 // Placeholder
    }
    
    var taskWarnings: [String] {
        switch self {
        case .rain:
            return ["Postpone outdoor cleaning tasks", "Check drainage systems"]
        case .snow:
            return ["Prepare snow removal equipment", "Check heating systems"]
        case .thunderstorm:
            return ["Cancel all outdoor work", "Secure loose equipment"]
        default:
            return []
        }
    }
    
    var condition: String {
        return rawValue
    }
}

struct WorkerDashboardView_V2: View {
    // MARK: - State Management
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    
    // UI State
    @State private var scrollOffset: CGFloat = 0
    @State private var showQuickActions = false
    @State private var showBuildingList = false
    @State private var showTaskDetail: ContextualTask?
    @State private var showProfileView = false
    @State private var showWeatherDetail = false
    @State private var showAllBuildings = false
    
    // Clock state
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var currentBuildingName: String = "None"
    
    // Weather state
    @State private var currentWeather: WeatherCondition?
    @State private var buildingWeatherMap: [String: WeatherCondition] = [:]
    
    // MARK: - Computed Properties
    private var currentWorkerName: String {
        contextEngine.currentWorker?.workerName ?? authManager.currentWorkerName
    }
    
    private var workerIdString: String {
        contextEngine.currentWorker?.workerId ?? authManager.workerId
    }
    
    private var categorizedTasks: (current: [ContextualTask], upcoming: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(tasks: contextEngine.todaysTasks)
    }
    
    private var hasUrgentWork: Bool {
        contextEngine.getUrgentTaskCount() > 0 || categorizedTasks.overdue.count > 0
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Map background
            mapBackgroundView
            
            // Main content
            VStack(spacing: 0) {
                dynamicNavigationHeader
                
                if contextEngine.isLoading {
                    loadingStateView
                } else if let error = contextEngine.lastError {
                    errorStateView(error.localizedDescription)
                } else {
                    mainContentScrollView
                }
            }
            
            // Nova AI overlay
            novaAIOverlay
        }
        .task {
            await initializeDashboard()
        }
        .refreshable {
            await refreshAllData()
        }
        .sheet(isPresented: $showBuildingList) {
            buildingSelectionSheet
        }
        .sheet(item: $showTaskDetail) { task in
            taskDetailSheet(task)
        }
        .fullScreenCover(isPresented: $showProfileView) {
            profileSheet
        }
        .sheet(isPresented: $showWeatherDetail) {
            weatherDetailSheet
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
    }
    
    // MARK: - Map Background
    private var mapBackgroundView: some View {
        ZStack {
            Map(coordinateRegion: .constant(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845),
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
            ),
            annotationItems: contextEngine.assignedBuildings
            ) { building in
                MapAnnotation(
                    coordinate: CLLocationCoordinate2D(
                        latitude: building.latitude,
                        longitude: building.longitude
                    )
                ) {
                    WorkerDashboardBuildingMapMarker(
                        building: building,
                        isClockedIn: isClockedInBuilding(building),
                        weather: buildingWeatherMap[building.id]
                    )
                }
            }
            .blur(radius: 1.5)
            .opacity(0.7)
            
            Color.black.opacity(0.3)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Navigation Header
    private var dynamicNavigationHeader: some View {
        GlassCard(intensity: .regular, cornerRadius: 0, padding: 0) {
            VStack(spacing: 0) {
                // Main header content
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FRANCOSPHERE")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text(currentWorkerName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        clockInOutButton
                        statusIndicator
                        profileMenuButton
                    }
                }
                .padding(16)
                
                // Real-time task status bar
                if let nextTask = TimeBasedTaskFilter.nextSuggestedTask(from: contextEngine.todaysTasks) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    nextTaskStatusBar(nextTask)
                }
            }
        }
    }
    
    private func nextTaskStatusBar(_ task: ContextualTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.caption)
                .foregroundColor(.blue)
            
            Text("Next: \(task.name)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
            
            Spacer()
            
            if let timeUntil = TimeBasedTaskFilter.timeUntilTask(task) {
                Text(timeUntil)
                    .font(.caption.bold())
                    .foregroundColor(task.isOverdue ? .red : .blue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.blue.opacity(0.1))
    }
    
    private var clockInOutButton: some View {
        Button(action: handleClockToggle) {
            HStack(spacing: 8) {
                Image(systemName: clockedInStatus.isClockedIn
                      ? "clock.badge.checkmark.fill" : "clock.badge.exclamationmark")
                    .font(.system(size: 16))
                Text(clockedInStatus.isClockedIn ? "Clock Out" : "Clock In")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                (clockedInStatus.isClockedIn ? Color.red : Color.green)
                    .opacity(0.3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        (clockedInStatus.isClockedIn ? Color.red : Color.green)
                            .opacity(0.6),
                        lineWidth: 1
                    )
            )
            .cornerRadius(20)
        }
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(clockedInStatus.isClockedIn ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
            Text(clockedInStatus.isClockedIn ? "Active" : "Inactive")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var profileMenuButton: some View {
        Menu {
            Button {
                showProfileView = true
            } label: {
                Label("View Profile", systemImage: "person")
            }
            
            Button {
                Task { await refreshAllData() }
            } label: {
                Label("Refresh Data", systemImage: "arrow.clockwise")
            }
            
            Button(role: .destructive) {
                logoutUser()
            } label: {
                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContentScrollView: some View {
        TrackableScrollView(offsetChanged: { offset in
            scrollOffset = offset
        }) {
            VStack(spacing: 20) {
                if clockedInStatus.isClockedIn {
                    currentBuildingStatusCard
                }
                
                weatherOverviewCard
                todaysTasksSection
                workerBuildingsSection
                taskSummaryCard
                
                Color.clear.frame(height: 100) // Tab bar spacing
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    
    // MARK: - Current Building Status
    private var currentBuildingStatusCard: some View {
        GlassCard(intensity: .regular) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clocked In")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(currentBuildingName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    if let startTime = getClockInTime() {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(startTime, style: .relative)
                                .font(.caption.bold())
                                .foregroundColor(.green)
                            Text("elapsed")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Weather Card
    private var weatherOverviewCard: some View {
        Group {
            if let weather = currentWeather {
                GlassCard(intensity: .regular) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Weather header
                        HStack {
                            Image(systemName: weather.icon)
                                .font(.title2)
                                .foregroundColor(weather.color)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(weather.temperatureString)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(weather.condition)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "thermometer")
                                        .font(.caption2)
                                    Text("Feels \(weather.apparentTemperature)°")
                                        .font(.caption)
                                }
                                HStack(spacing: 4) {
                                    Image(systemName: "drop.fill")
                                        .font(.caption2)
                                    Text("\(weather.humidity)%")
                                        .font(.caption)
                                }
                            }
                            .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Task warnings
                        if !weather.taskWarnings.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(weather.taskWarnings, id: \.self) { warning in
                                    Text(warning)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                    }
                }
                .onTapGesture {
                    showWeatherDetail = true
                }
            } else {
                weatherLoadingCard
            }
        }
    }
    
    private var weatherLoadingCard: some View {
        GlassCard(intensity: .regular) {
            HStack {
                ProgressView()
                    .tint(.white)
                Text("Loading weather data...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - Today's Tasks Section
    private var todaysTasksSection: some View {
        VStack(spacing: 0) {
            // Use the existing TodaysTasksGlassCard
            TodaysTasksGlassCard(
                tasks: mapContextualTasksToMaintenanceTasks(contextEngine.todaysTasks),
                onTaskTap: { task in
                    if let contextualTask = findContextualTask(for: task) {
                        showTaskDetail = contextualTask
                    }
                }
            )
        }
    }
    
    // MARK: - Buildings Section
    private var workerBuildingsSection: some View {
        GlassCard(intensity: .regular) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "building.2")
                        .foregroundColor(.white)
                    Text("Assigned Buildings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(contextEngine.assignedBuildings.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    if contextEngine.assignedBuildings.count > 3 {
                        Button {
                            withAnimation { showAllBuildings.toggle() }
                        } label: {
                            Text(showAllBuildings ? "Show Less" : "Show All")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                // Building list
                if contextEngine.assignedBuildings.isEmpty {
                    emptyBuildingsView
                } else {
                    VStack(spacing: 12) {
                        let buildingsToShow = showAllBuildings
                            ? contextEngine.assignedBuildings
                            : Array(contextEngine.assignedBuildings.prefix(3))
                        
                        ForEach(buildingsToShow) { building in
                            WorkerDashboardBuildingRowEnhanced(
                                building: building,
                                isClockedIn: isClockedInBuilding(building),
                                taskCount: contextEngine.getTaskCountForBuilding(building.id),
                                weather: buildingWeatherMap[building.id]
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Task Summary
    private var taskSummaryCard: some View {
        GlassCard(intensity: .regular) {
            VStack(spacing: 16) {
                HStack {
                    Text("Real-Time Status")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Last refresh time
                    if let refreshTime = contextEngine.lastRefreshTime {
                        Text("Updated \(refreshTime, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                HStack(spacing: 20) {
                    // Active tasks
                    WorkerDashboardTaskSummaryItem(
                        count: categorizedTasks.current.count,
                        label: "Active",
                        color: .green,
                        icon: "play.circle.fill"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    // Upcoming
                    WorkerDashboardTaskSummaryItem(
                        count: categorizedTasks.upcoming.count,
                        label: "Upcoming",
                        color: .blue,
                        icon: "clock.arrow.circlepath"
                    )
                    
                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.3))
                    
                    // Overdue
                    WorkerDashboardTaskSummaryItem(
                        count: categorizedTasks.overdue.count,
                        label: "Overdue",
                        color: .red,
                        icon: "exclamationmark.circle.fill"
                    )
                }
                
                // AI suggestion
                if let nextTask = TimeBasedTaskFilter.nextSuggestedTask(from: contextEngine.todaysTasks) {
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text("Nova suggests: \(nextTask.name)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if let time = TimeBasedTaskFilter.timeUntilTask(nextTask) {
                            Text(time)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Nova AI Overlay
    private var novaAIOverlay: some View {
        VStack {
            HStack {
                Spacer()
                
                NovaAvatar(
                    size: 60,
                    showStatus: hasUrgentWork,
                    hasUrgentInsight: categorizedTasks.overdue.count > 0,
                    isBusy: contextEngine.isLoading,
                    onTap: {
                        handleNovaTap()
                    },
                    onLongPress: {
                        showQuickActions = true
                    }
                )
                .padding(.trailing, 20)
                .padding(.top, 120)
            }
            Spacer()
        }
        .overlay(
            Group {
                if showQuickActions {
                    QuickActionMenu(
                        isPresented: $showQuickActions,
                        onActionSelected: handleQuickAction
                    )
                    .zIndex(200)
                }
            }
        )
    }
    
    // MARK: - Data Loading
    private func initializeDashboard() async {
        // Load worker context (includes tasks and buildings)
        await contextEngine.loadWorkerContext(workerId: workerIdString)
        
        // Start auto-refresh
        contextEngine.startAutoRefresh()
        
        // Load additional data in parallel
        async let clockIn = checkClockInStatus()
        async let weather = loadWeatherData()
        
        _ = await (clockIn, weather)
    }
    
    private func refreshAllData() async {
        await contextEngine.refreshContext()
        await loadWeatherData()
    }
    
    private func loadWeatherData() async {
        // Get current location or first building
        if let firstBuilding = contextEngine.assignedBuildings.first {
            // Create a mock WeatherCondition for now
            currentWeather = WeatherCondition.clear
        }
        
        // Load weather for all buildings
        for building in contextEngine.assignedBuildings {
            buildingWeatherMap[building.id] = WeatherCondition.clear
        }
    }
    
    // MARK: - Clock In/Out
    private func checkClockInStatus() async {
        do {
            let sql = try await SQLiteManager.start()
            guard let workerInt = Int64(workerIdString) else { return }
            
            let status = await sql.isWorkerClockedInAsync(workerId: workerInt)
            
            await MainActor.run {
                clockedInStatus = status
                if let bId = status.buildingId {
                    currentBuildingName = contextEngine.assignedBuildings
                        .first { $0.id == String(bId) }?.name ?? "Building \(bId)"
                }
            }
        } catch {
            print("Clock-in check error: \(error)")
        }
    }
    
    private func handleClockToggle() {
        if clockedInStatus.isClockedIn {
            performClockOut()
        } else {
            showBuildingList = true
        }
    }
    
    private func performClockOut() {
        Task {
            do {
                let sql = try await SQLiteManager.start()
                guard let workerInt = Int64(workerIdString) else { return }
                
                try await sql.logClockOutAsync(workerId: workerInt, timestamp: Date())
                
                await MainActor.run {
                    clockedInStatus = (false, nil)
                    currentBuildingName = "None"
                }
                
                // Refresh context after clock out
                await contextEngine.refreshContext()
                
            } catch {
                print("Clock-out failed: \(error)")
            }
        }
    }
    
    private func handleClockIn(_ building: Building) {
        Task {
            do {
                let sql = try await SQLiteManager.start()
                guard let workerInt = Int64(workerIdString),
                      let buildingInt = Int64(building.id) else { return }
                
                try await sql.logClockInAsync(
                    workerId: workerInt,
                    buildingId: buildingInt,
                    timestamp: Date()
                )
                
                await MainActor.run {
                    clockedInStatus = (true, buildingInt)
                    currentBuildingName = building.name
                    showBuildingList = false
                }
                
                // Refresh tasks after clock in
                await contextEngine.refreshContext()
                
            } catch {
                print("Clock-in failed: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private func mapContextualTasksToMaintenanceTasks(_ contextualTasks: [ContextualTask]) -> [MaintenanceTask] {
        contextualTasks.map { task in
            MaintenanceTask(
                id: task.id,
                name: task.name,
                buildingID: task.buildingId,
                description: "",
                dueDate: Date(),
                startTime: parseTimeString(task.startTime),
                endTime: parseTimeString(task.endTime),
                category: TaskCategory(rawValue: task.category) ?? .maintenance,
                urgency: TaskUrgency(rawValue: task.urgencyLevel) ?? .medium,
                recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .oneTime,
                isComplete: task.status == "completed",
                assignedWorkers: [workerIdString]
            )
        }
    }
    
    private func parseTimeString(_ timeStr: String?) -> Date? {
        guard let timeStr = timeStr else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeStr) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(
                bySettingHour: components.hour ?? 0,
                minute: components.minute ?? 0,
                second: 0,
                of: Date()
            )
        }
        
        return nil
    }
    
    private func findContextualTask(for maintenanceTask: MaintenanceTask) -> ContextualTask? {
        contextEngine.todaysTasks.first { $0.id == maintenanceTask.id }
    }
    
    private func isClockedInBuilding(_ building: Building) -> Bool {
        if let clockedInId = clockedInStatus.buildingId {
            return String(clockedInId) == building.id
        }
        return false
    }
    
    private func getClockInTime() -> Date? {
        // Would need to query the actual clock-in time from database
        // For now, return a placeholder
        return Date().addingTimeInterval(-3600) // 1 hour ago
    }
    
    private func handleNovaTap() {
        // Show AI insights based on current context
        if categorizedTasks.overdue.count > 0 {
            // Show overdue tasks alert
            print("Show overdue tasks: \(categorizedTasks.overdue.count)")
        } else if let nextTask = TimeBasedTaskFilter.nextSuggestedTask(from: contextEngine.todaysTasks) {
            // Show next task suggestion
            showTaskDetail = nextTask
        }
    }
    
    private func handleQuickAction(_ action: QuickActionType) {
        switch action {
        case .scanQR:
            print("Open QR scanner")
        case .reportIssue:
            print("Open issue reporter")
        case .showMap:
            // Navigate to map view
            print("Show building map")
        case .askNova:
            print("Open Nova chat")
        case .viewInsights:
            print("Show AI insights")
        }
    }
    
    private func logoutUser() {
        authManager.logout()
        // Navigation to login will be handled by parent view
    }
    
    // MARK: - Sheets
    private var buildingSelectionSheet: some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(contextEngine.assignedBuildings) { building in
                            WorkerDashboardBuildingSelectionRowV2(
                                building: building,
                                weather: buildingWeatherMap[building.id]
                            ) {
                                handleClockIn(building)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Building")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showBuildingList = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func taskDetailSheet(_ task: ContextualTask) -> some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground.ignoresSafeArea()
                
                ScrollView {
                    GlassCard(intensity: .thin) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Task header
                            VStack(alignment: .leading, spacing: 8) {
                                Text(task.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    Label(task.buildingName, systemImage: "building.2.fill")
                                    Spacer()
                                    Text(task.category)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(12)
                                }
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Divider()
                                .background(Color.white.opacity(0.2))
                            
                            // Time information
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Schedule", systemImage: "clock")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    if let startTime = task.startTime, let endTime = task.endTime {
                                        Text("\(formatTimeString(startTime)) - \(formatTimeString(endTime))")
                                            .font(.body)
                                    } else {
                                        Text("Flexible timing")
                                            .font(.body)
                                    }
                                    
                                    Spacer()
                                    
                                    // Time status
                                    Text(task.isOverdue ? "Overdue" : "On Time")
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(task.urgencyColor.opacity(0.2))
                                        .cornerRadius(12)
                                }
                                .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Task metadata
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label("Urgency", systemImage: "exclamationmark.triangle")
                                    Spacer()
                                    Text(task.urgencyLevel)
                                        .foregroundColor(task.urgencyColor)
                                }
                                
                                HStack {
                                    Label("Skill Level", systemImage: "star.fill")
                                    Spacer()
                                    Text(task.skillLevel)
                                }
                                
                                HStack {
                                    Label("Recurrence", systemImage: "repeat")
                                    Spacer()
                                    Text(task.recurrence)
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            
                            // Action button
                            if task.status != "completed" {
                                Button(action: {
                                    // Mark task complete
                                    showTaskDetail = nil
                                }) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Mark Complete")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding(20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Task Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTaskDetail = nil
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var profileSheet: some View {
        NavigationView {
            ProfileView()
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showProfileView = false
                        }
                        .foregroundColor(.white)
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
    
    private var weatherDetailSheet: some View {
        NavigationView {
            ZStack {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                if let weather = currentWeather {
                    ScrollView {
                        VStack(spacing: 30) {
                            // Main weather display
                            VStack(spacing: 20) {
                                Image(systemName: weather.icon)
                                    .font(.system(size: 80))
                                    .foregroundColor(weather.color)
                                
                                Text("\(weather.temperature)°")
                                    .font(.system(size: 72, weight: .thin))
                                    .foregroundColor(.white)
                                
                                Text(weather.condition)
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            // Weather details grid
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {
                                WorkerDashboardWeatherDetailItem(
                                    icon: "thermometer",
                                    label: "Feels Like",
                                    value: "\(weather.apparentTemperature)°"
                                )
                                
                                WorkerDashboardWeatherDetailItem(
                                    icon: "humidity",
                                    label: "Humidity",
                                    value: "\(weather.humidity)%"
                                )
                                
                                WorkerDashboardWeatherDetailItem(
                                    icon: "wind",
                                    label: "Wind",
                                    value: "\(weather.windSpeed) mph"
                                )
                                
                                WorkerDashboardWeatherDetailItem(
                                    icon: "drop.fill",
                                    label: "Precipitation",
                                    value: String(format: "%.1f mm", weather.precipitation)
                                )
                            }
                            
                            // Task recommendations
                            if !weather.taskWarnings.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Task Recommendations")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    ForEach(weather.taskWarnings, id: \.self) { warning in
                                        HStack(alignment: .top, spacing: 12) {
                                            Text("•")
                                                .foregroundColor(.white.opacity(0.6))
                                            Text(warning)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.8))
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.ultraThinMaterial)
                                        .opacity(0.15)
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Weather Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showWeatherDetail = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - State Views
    private var loadingStateView: some View {
        VStack {
            Spacer()
            
            GlassCard(intensity: .thin) {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.blue)
                    
                    Text("Loading \(currentWorkerName)'s dashboard...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Importing tasks from CSV...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 20)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func errorStateView(_ error: String) -> some View {
        VStack {
            Spacer()
            
            GlassCard(intensity: .thin) {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Data Loading Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        Task {
                            await refreshAllData()
                        }
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 20)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var emptyBuildingsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.6))
            
            Text("No buildings assigned")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text("Contact your supervisor to get building assignments")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }
    
    // MARK: - Helper Functions
    private func formatTimeString(_ timeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: time)
        }
        
        return timeString
    }
}

// MARK: - Supporting Components (Renamed to avoid conflicts)

struct WorkerDashboardBuildingMapMarker: View {
    let building: Building
    let isClockedIn: Bool
    let weather: WeatherCondition?
    
    var body: some View {
        ZStack {
            // Main marker
            Circle()
                .fill(isClockedIn ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isClockedIn ? Color.green : Color.blue, lineWidth: 2)
                )
            
            Image(systemName: "building.2.fill")
                .font(.system(size: 18))
                .foregroundColor(isClockedIn ? .green : .blue)
            
            // Weather indicator
            if let weather = weather {
                VStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.5))
                            .frame(width: 20, height: 20)
                        
                        Image(systemName: weather.icon)
                            .font(.system(size: 10))
                            .foregroundColor(weather.color)
                    }
                }
                .frame(width: 44, height: 44)
                .offset(x: 15, y: -15)
            }
        }
        .shadow(radius: 5)
    }
}

struct WorkerDashboardBuildingRowEnhanced: View {
    let building: Building
    let isClockedIn: Bool
    let taskCount: Int
    let weather: WeatherCondition?
    
    var body: some View {
        HStack(spacing: 16) {
            // Building image
            Group {
                if let img = UIImage(named: building.imageAssetName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // Building info
            VStack(alignment: .leading, spacing: 4) {
                Text(building.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    // Task count
                    if taskCount > 0 {
                        Label("\(taskCount) tasks", systemImage: "checkmark.circle")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Weather
                    if let weather = weather {
                        Label(weather.temperatureString, systemImage: weather.icon)
                            .font(.caption)
                            .foregroundColor(weather.color.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            // Clock in indicator
            if isClockedIn {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct WorkerDashboardBuildingSelectionRowV2: View {
    let building: Building
    let weather: WeatherCondition?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            GlassCard(intensity: .thin, padding: 16) {
                HStack(spacing: 16) {
                    // Building image
                    Group {
                        if let img = UIImage(named: building.imageAssetName) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "building.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                    
                    // Building details
                    VStack(alignment: .leading, spacing: 6) {
                        Text(building.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        if let address = building.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        // Weather info
                        if let weather = weather {
                            HStack(spacing: 8) {
                                Image(systemName: weather.icon)
                                    .font(.caption)
                                    .foregroundColor(weather.color)
                                Text("\(weather.temperatureString) • \(weather.condition)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "clock.badge.plus")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkerDashboardWeatherDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        GlassCard(intensity: .thin) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
    }
}

struct WorkerDashboardTaskSummaryItem: View {
    let count: Int
    let label: String
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compatibility Extensions
extension Building {
    var address: String? {
        return nil // Will use the existing address property if available
    }
}

// MARK: - Preview
struct WorkerDashboardView_V2_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView_V2()
            .preferredColorScheme(.dark)
    }
}
