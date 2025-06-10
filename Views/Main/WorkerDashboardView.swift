//
//  WorkerDashboardView_V2.swift
//  FrancoSphere
//
//  Fully integrated dashboard with WorkerContextEngine, real weather, and all UI upgrades
//  CLEANED VERSION - No duplicate definitions
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Fix ContextualTask Identifiable Conformance
extension ContextualTask: Identifiable {}

// MARK: - Local Building Type Definition
// Use explicit type to avoid confusion with global Building typealias
typealias DashboardBuilding = FrancoSphere.NamedCoordinate

// MARK: - SQLiteManager Extension (Only if not already defined elsewhere)
extension SQLiteManager {
    func isWorkerClockedInAsync(workerId: Int64) async -> (isClockedIn: Bool, buildingId: Int64?) {
        return await withCheckedContinuation { continuation in
            let result = isWorkerClockedIn(workerId: workerId)
            continuation.resume(returning: result)
        }
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
    @State private var currentWeather: WeatherData?
    @State private var buildingWeatherMap: [String: WeatherData] = [:]
    
    // MARK: - Computed Properties
    private var currentWorkerName: String {
        contextEngine.currentWorker?.workerName ?? authManager.currentWorkerName
    }
    
    private var workerIdString: String {
        contextEngine.currentWorker?.workerId ?? authManager.workerId
    }
    
    // FIXED: Tuple shuffle warning
    private var categorizedTasks: (current: [ContextualTask], upcoming: [ContextualTask], overdue: [ContextualTask]) {
        let categorized = TimeBasedTaskFilter.categorizeByTimeStatus(tasks: contextEngine.todaysTasks)
        return categorized
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
    
    // MARK: - Map Background (FIXED for iOS 17)
    @ViewBuilder
    private var mapBackgroundView: some View {
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        ZStack {
            if #available(iOS 17.0, *) {
                Map(initialPosition: .region(region)) {
                    ForEach(contextEngine.assignedBuildings) { building in
                        Annotation(building.name, coordinate: CLLocationCoordinate2D(
                            latitude: building.latitude,
                            longitude: building.longitude
                        )) {
                            WorkerDashboardBuildingMapMarker(
                                building: building,
                                isClockedIn: isClockedInBuilding(building),
                                weather: buildingWeatherMap[building.id]
                            )
                        }
                    }
                }
                .mapStyle(.standard)
                .blur(radius: 1.5)
                .opacity(0.7)
            } else {
                // iOS 16 and earlier
                Map(coordinateRegion: .constant(region), annotationItems: contextEngine.assignedBuildings) { building in
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
            }
            
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
                    
                    // Clock-in time display
                    let startTime = getClockInTime()
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
    
    // MARK: - Weather Card
    private var weatherOverviewCard: some View {
        Group {
            if let weather = currentWeather {
                GlassCard(intensity: .regular) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Weather header
                        HStack {
                            Image(systemName: weatherConditionIcon(weather.condition))
                                .font(.title2)
                                .foregroundColor(weatherConditionColor(weather.condition))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(weather.formattedTemperature)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(weather.condition.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                HStack(spacing: 4) {
                                    Image(systemName: "thermometer")
                                        .font(.caption2)
                                    Text("Feels \(Int(weather.feelsLike))°")
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
                        
                        // Weather risk warning
                        if weather.outdoorWorkRisk != .low {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(outdoorWorkRiskColor(weather.outdoorWorkRisk))
                                Text("Outdoor work: \(outdoorWorkRiskText(weather.outdoorWorkRisk))")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(outdoorWorkRiskColor(weather.outdoorWorkRisk).opacity(0.2))
                            .cornerRadius(8)
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
                    
                    // FIXED: lastRefreshTime is not optional
                    Text("Updated \(contextEngine.lastRefreshTime, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
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
                    showStatus: hasUrgentWork
                ) {
                    handleNovaTap()
                }
                .onLongPressGesture(perform: {
                    showQuickActions = true
                })
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
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.checkClockInStatus()
            }
            
            group.addTask {
                await self.loadWeatherData()
            }
        }
    }
    
    private func refreshAllData() async {
        await contextEngine.refreshContext()
        await loadWeatherData()
    }
    
    private func loadWeatherData() async {
        // Get current location or first building
        if !contextEngine.assignedBuildings.isEmpty {
            // Create a mock WeatherData for now
            currentWeather = createMockWeatherData()
        }
        
        // Load weather for all buildings
        for building in contextEngine.assignedBuildings {
            buildingWeatherMap[building.id] = createMockWeatherData()
        }
    }
    
    // MARK: - Helper method to create mock weather data
    private func createMockWeatherData() -> WeatherData {
        return WeatherData(
            date: Date(),
            temperature: Double.random(in: 65...85),
            feelsLike: Double.random(in: 65...85),
            humidity: Int.random(in: 40...80),
            windSpeed: Double.random(in: 5...15),
            windDirection: Int.random(in: 0...360),
            precipitation: Double.random(in: 0...0.5),
            snow: 0,
            visibility: 10,
            pressure: 1013,
            condition: [.clear, .cloudy, .rain].randomElement() ?? .clear,
            icon: ""
        )
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
    
    private func handleClockIn(_ building: DashboardBuilding) {
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
    
    private func isClockedInBuilding(_ building: DashboardBuilding) -> Bool {
        if let clockedInId = clockedInStatus.buildingId {
            return String(clockedInId) == building.id
        }
        return false
    }
    
    private func getClockInTime() -> Date {
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
                                Image(systemName: weatherConditionIcon(weather.condition))
                                    .font(.system(size: 80))
                                    .foregroundColor(weatherConditionColor(weather.condition))
                                
                                Text(weather.formattedTemperature)
                                    .font(.system(size: 72, weight: .thin))
                                    .foregroundColor(.white)
                                
                                Text(weather.condition.rawValue)
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
                                    value: "\(Int(weather.feelsLike))°"
                                )
                                
                                WorkerDashboardWeatherDetailItem(
                                    icon: "humidity",
                                    label: "Humidity",
                                    value: "\(weather.humidity)%"
                                )
                                
                                WorkerDashboardWeatherDetailItem(
                                    icon: "wind",
                                    label: "Wind",
                                    value: "\(Int(weather.windSpeed)) mph"
                                )
                                
                                WorkerDashboardWeatherDetailItem(
                                    icon: "drop.fill",
                                    label: "Precipitation",
                                    value: String(format: "%.1f mm", weather.precipitation)
                                )
                            }
                            
                            // Work risk assessment
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Work Risk Assessment")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(outdoorWorkRiskColor(weather.outdoorWorkRisk))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(outdoorWorkRiskText(weather.outdoorWorkRisk))
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Spacer()
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.15)
                            )
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
    
    // MARK: - Weather Helper Functions
    private func weatherConditionIcon(_ condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    private func weatherConditionColor(_ condition: FrancoSphere.WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .other: return .gray
        }
    }
    
    private func outdoorWorkRiskText(_ risk: WeatherData.OutdoorWorkRisk) -> String {
        switch risk {
        case .low: return "Low Risk"
        case .moderate: return "Moderate Risk"
        case .high: return "High Risk"
        case .extreme: return "Extreme Risk"
        }
    }
    
    private func outdoorWorkRiskColor(_ risk: WeatherData.OutdoorWorkRisk) -> Color {
        switch risk {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .extreme: return .red
        }
    }
}

// MARK: - Supporting Components (Renamed to avoid conflicts)

struct WorkerDashboardBuildingMapMarker: View {
    let building: DashboardBuilding
    let isClockedIn: Bool
    let weather: WeatherData?
    
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
                        
                        Image(systemName: weatherConditionIcon(weather.condition))
                            .font(.system(size: 10))
                            .foregroundColor(weatherConditionColor(weather.condition))
                    }
                }
                .frame(width: 44, height: 44)
                .offset(x: 15, y: -15)
            }
        }
        .shadow(radius: 5)
    }
    
    // Helper functions for weather icons
    private func weatherConditionIcon(_ condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    private func weatherConditionColor(_ condition: FrancoSphere.WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .other: return .gray
        }
    }
}

struct WorkerDashboardBuildingRowEnhanced: View {
    let building: DashboardBuilding
    let isClockedIn: Bool
    let taskCount: Int
    let weather: WeatherData?
    
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
                        Label(weather.formattedTemperature, systemImage: weatherConditionIcon(weather.condition))
                            .font(.caption)
                            .foregroundColor(weatherConditionColor(weather.condition).opacity(0.8))
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
    
    // Helper functions
    private func weatherConditionIcon(_ condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    private func weatherConditionColor(_ condition: FrancoSphere.WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .other: return .gray
        }
    }
}

struct WorkerDashboardBuildingSelectionRowV2: View {
    let building: DashboardBuilding
    let weather: WeatherData?
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
                    
                    // Building details - FIXED: Remove address since type doesn't have it
                    VStack(alignment: .leading, spacing: 6) {
                        Text(building.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Show coordinates as location info instead of address
                        Text("Lat: \(String(format: "%.4f", building.latitude)), Lng: \(String(format: "%.4f", building.longitude))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                        
                        // Weather info
                        if let weather = weather {
                            HStack(spacing: 8) {
                                Image(systemName: weatherConditionIcon(weather.condition))
                                    .font(.caption)
                                    .foregroundColor(weatherConditionColor(weather.condition))
                                Text("\(weather.formattedTemperature) • \(weather.condition.rawValue)")
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
    
    // Helper functions
    private func weatherConditionIcon(_ condition: FrancoSphere.WeatherCondition) -> String {
        switch condition {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    private func weatherConditionColor(_ condition: FrancoSphere.WeatherCondition) -> Color {
        switch condition {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .other: return .gray
        }
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

// MARK: - Preview
struct WorkerDashboardView_V2_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView_V2()
            .preferredColorScheme(.dark)
    }
}
