//
//  WorkerDashboardView.swift
//  FrancoSphere
//
//  🚨 CRITICAL: Fix compilation errors and Kevin's building assignment issue
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct WorkerDashboardView: View {
    
    // MARK: - State Management (Enhanced for Phase-2)
    @StateObject private var authManager = NewAuthManager.shared
    
    // BEGIN PATCH(HF-11-1): Fix assigned buildings reactivity
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    // END PATCH(HF-11-1)
    
    @StateObject private var weatherManager = WeatherManager.shared
    @StateObject private var workerManager = WorkerManager.shared
    @StateObject private var aiManager = AIAssistantManager.shared
    
    // MARK: - UI State Variables
    @State private var scrollOffset: CGFloat = 0
    @State private var showMapHint = !UserDefaults.standard.bool(forKey: "hasSeenMapHint")
    @State private var headerOpacity: Double = 1.0
    @State private var clockInTime: Date?
    
    // MARK: - Modal Presentation State
    @State private var showQuickActions = false
    @State private var showBuildingList = false
    @State private var showTaskDetail: ContextualTask?
    @State private var showProfileView = false
    @State private var showWeatherDetail = false
    @State private var showAllTasksView = false
    @State private var showAllBuildingsBrowser = false
    @State private var showMapOverlay = false
    
    // MARK: - Building Navigation State (Phase-2)
    @State private var selectedBuilding: FrancoSphere.NamedCoordinate?
    @State private var showBuildingDetail = false
    
    // MARK: - ✅ PHASE-2: Real Data State
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: String?) = (false, nil)
    @State private var currentBuildingName = "None"
    @State private var currentWeather: FrancoSphere.WeatherData?
    @State private var buildingWeatherMap: [String: FrancoSphere.WeatherData] = [:]
    @State private var currentTime = Date()
    @State private var timeTimer: Timer?
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties (Real Data)
    private var currentWorkerName: String {
        let name = contextEngine.getWorkerName()
        return name.isEmpty ? authManager.currentWorkerName : name
    }
    private var workerIdString: String {
        let id = contextEngine.getWorkerId()
        return id.isEmpty ? authManager.workerId : id
    }
    private var assignedBuildings: [FrancoSphere.NamedCoordinate] {
        contextEngine.getAssignedBuildings()
    }
    private var categorizedTasks: (upcoming: [ContextualTask], current: [ContextualTask], overdue: [ContextualTask]) {
        TimeBasedTaskFilter.categorizeByTimeStatus(tasks: contextEngine.getTodaysTasks())
    }
    private var hasUrgentWork: Bool {
        contextEngine.getUrgentTaskCount() > 0 || !categorizedTasks.overdue.isEmpty
    }
    private var nextTaskName: String? {
        TimeBasedTaskFilter.nextSuggestedTask(from: contextEngine.getTodaysTasks())?.name
    }
    
    // MARK: - Task Intelligence - Location+Time Filtering (Real Data)
    private var filteredTaskData: [ContextualTask] {
        filterTasksForLocationAndTime(
            all: contextEngine.getTodaysTasks(),
            clockedInBuildingId: clockedInStatus.isClockedIn ? clockedInStatus.buildingId : nil,
            now: Date()
        )
    }
    private var taskProgress: TimeBasedTaskFilter.TaskProgress {
        TimeBasedTaskFilter.calculateTaskProgress(tasks: filteredTaskData)
    }
    
    // MARK: - Body Architecture
    var body: some View {
        ZStack {
            mapBackgroundView
                .ignoresSafeArea(.all)
                .onTapGesture {
                    HapticManager.impact(.light)
                    showMapOverlay = true
                }
            
            GeometryReader { geometry in
                let containerWidth = min(geometry.size.width * 0.82, 600)
                let sideMargin = (geometry.size.width - containerWidth) / 2
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geo in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        mainContent(scrollProxy: scrollProxy)
                            .frame(width: containerWidth)
                            .padding(EdgeInsets(
                                top: 100,
                                leading: sideMargin,
                                bottom: 120,
                                trailing: sideMargin
                            ))
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        updateTransformations(for: value)
                    }
                    .highPriorityGesture(
                        DragGesture().onEnded { value in
                            if scrollOffset > -10 && value.translation.height < -80 {
                                HapticManager.impact(.medium)
                                showMapOverlay = true
                            }
                        }
                    )
                }
            }
            
            VStack {
                HeaderV3B(
                    workerName: currentWorkerName,
                    clockedInStatus: clockedInStatus.isClockedIn,
                    onClockToggle: handleClockToggle,
                    onProfilePress: { showProfileView = true },
                    nextTaskName: nextTaskName,
                    hasUrgentWork: hasUrgentWork,
                    onNovaPress: handleNovaAvatarTap,
                    onNovaLongPress: handleNovaAvatarLongPress,
                    isNovaProcessing: aiManager.isProcessing,
                    showClockPill: false
                )
                .opacity(headerOpacity)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrollOffset)
                
                Spacer()
            }
            .zIndex(999)
            
            if scrollOffset < -100 {
                HStack {
                    Spacer()
                    VStack {
                        NovaAvatar(
                            size: 44,
                            showStatus: true,
                            hasUrgentInsight: hasUrgentWork,
                            isBusy: aiManager.isProcessing,
                            onTap: handleNovaAvatarTap,
                            onLongPress: handleNovaAvatarLongPress
                        )
                        .scaleEffect(0.8)
                        Spacer()
                    }
                }
                .padding(.trailing, 20)
                .padding(.top, 80)
                .transition(.move(edge: .top).combined(with: .scale))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrollOffset)
            }
            
            if showMapHint {
                MapInteractionHint(
                    showHint: $showMapHint,
                    hasSeenHint: UserDefaults.standard.bool(forKey: "hasSeenMapHint")
                )
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenMapHint")
                }
            }
        }
        .task { await initializeDashboard() }
        .refreshable { await refreshAllData() }
        .sheet(isPresented: $showBuildingList) { buildingSelectionSheet }
        .sheet(item: $showTaskDetail) { task in taskDetailSheet(task) }
        .fullScreenCover(isPresented: $showProfileView) { ProfileView() }
        .sheet(isPresented: $showWeatherDetail) { weatherDetailSheet }
        .sheet(isPresented: $showAllTasksView) { allTasksViewSheet }
        .sheet(isPresented: $showAllBuildingsBrowser) { allBuildingsBrowserSheet }
        .sheet(isPresented: $showBuildingDetail) {
            if let b = selectedBuilding {
                BuildingMapDetailView(building: b)
            }
        }
        .fullScreenCover(isPresented: $showMapOverlay) {
            MapOverlayView(
                buildings: assignedBuildings,
                allBuildings: FrancoSphere.NamedCoordinate.allBuildings,
                currentBuildingId: clockedInStatus.buildingId,
                focusBuilding: nil,
                isPresented: $showMapOverlay
            )
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .onAppear { startRealtimeClock() }
        .onDisappear { stopRealtimeClock() }
    }
    
    // MARK: - ✅ HF-09: Enhanced Real Data Initialization with Guaranteed AI
    private func initializeDashboard() async {
        guard !authManager.workerId.isEmpty else {
            print("❌ No authenticated worker ID found")
            return
        }
        
        let workerId = authManager.workerId
        print("🚀 HF-09: Initializing dashboard for worker ID: \(workerId) (\(authManager.currentWorkerName))")
        
        await contextEngine.loadWorkerContext(workerId: workerId)
        
        // 🚨 CRITICAL-3: Emergency Kevin fix if no buildings assigned
        if workerIdString == "4", contextEngine.getAssignedBuildings().isEmpty {
            await emergencyKevinBuildingFix()
        }
        
        await initializeEnhancedAIScenarios()
        await checkClockInStatus()
        await validateRealDataLoaded()
        
        // BEGIN PATCH(HF-11-7): Guaranteed AI scenario trigger
        await guaranteedAIKickoff()
        // Secondary trigger only if no scenarios exist
        if aiManager.scenarioQueue.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                Task { await self.triggerInitialAIScenario() }
            }
        }
        // END PATCH(HF-11-7)
    }
    
    // MARK: - Enhanced AI Methods
    private func initializeEnhancedAIScenarios() async {
        while contextEngine.isLoading {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        setupAISubscriptions()
    }
    private func setupAISubscriptions() {
        contextEngine.$todaysTasks
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { tasks in
                Task { await self.triggerTaskBasedAIScenario(tasks: tasks) }
            }
            .store(in: &cancellables)
        contextEngine.$assignedBuildings
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { builds in
                Task { await self.triggerBuildingBasedAIScenario(buildings: builds) }
            }
            .store(in: &cancellables)
    }
    
    private func guaranteedAIKickoff() async {
        print("🤖 HF-09: Guaranteed AI kickoff for worker \(authManager.workerId)")
        let tasks = contextEngine.getTodaysTasks()
        let builds = contextEngine.getAssignedBuildings()
        if builds.isEmpty {
            AIAssistantManager.shared.addScenario(.pendingTasks,
                                                  buildingName: "Assignment needed",
                                                  taskCount: 0)
        } else if tasks.isEmpty {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: builds.first?.name ?? "Your site",
                                                  taskCount: 0)
        } else {
            await AIAssistantManager.shared.generateContextualScenario(
                clockedIn: false,
                currentTasks: tasks,
                overdueCount: 0,
                currentBuilding: nil,
                weatherRisk: determineWeatherRisk().rawValue
            )
        }
    }
    
    private func triggerInitialAIScenario() async {
        let tasks = contextEngine.getTodaysTasks()
        let builds = contextEngine.getAssignedBuildings()
        let urgent = contextEngine.getUrgentTaskCount()
        print("🤖 HF-09: Triggering initial AI scenario")
        await AIAssistantManager.shared.generateContextualScenario(
            clockedIn: clockedInStatus.isClockedIn,
            currentTasks: tasks,
            overdueCount: categorizedTasks.overdue.count,
            currentBuilding: clockedInStatus.isClockedIn
                ? builds.first(where: { $0.id == clockedInStatus.buildingId })
                : nil,
            weatherRisk: determineWeatherRisk().rawValue
        )
    }
    
    private func triggerTaskBasedAIScenario(tasks: [ContextualTask]) async {
        guard !tasks.isEmpty else {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: "Your sites",
                                                  taskCount: 0)
            return
        }
        let overdue = tasks.filter { task in
            guard let st = task.startTime else { return false }
            return isTaskOverdue(st)
        }
        if !overdue.isEmpty {
            AIAssistantManager.shared.addScenario(.pendingTasks,
                                                  buildingName: overdue.first?.buildingName,
                                                  taskCount: overdue.count)
        } else {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: assignedBuildings.first?.name,
                                                  taskCount: tasks.count)
        }
    }
    
    private func triggerBuildingBasedAIScenario(buildings: [FrancoSphere.NamedCoordinate]) async {
        if buildings.isEmpty {
            AIAssistantManager.shared.addScenario(.pendingTasks,
                                                  buildingName: "Unassigned",
                                                  taskCount: 0)
        } else if buildings.count > 5 {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: "Multiple sites",
                                                  taskCount: buildings.count)
        } else {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: buildings.first?.name ?? "Your sites",
                                                  taskCount: buildings.count)
        }
    }
    
    // MARK: - Emergency Kevin Fix (CRITICAL-3)
    /// Emergency Kevin building assignment fix - integrates with WorkerAssignmentManager
    private func emergencyKevinBuildingFix() async {
        guard workerIdString == "4" else { return }
        print("🆘 CRITICAL: Running emergency Kevin building fix...")
        let manager = WorkerAssignmentManager.shared
        let hasExisting = manager.hasAssignments(for: "4")
        if !hasExisting {
            print("🆘 No assignments found - creating emergency assignments…")
            let success = await manager.createEmergencyAssignments(for: "4")
            print(success
                  ? "✅ Emergency assignments created for Kevin"
                  : "❌ Emergency assignment creation failed")
        }
        await contextEngine.refreshContext()
        let count = contextEngine.getAssignedBuildings().count
        print("🚨 Emergency fix result: Kevin now has \(count) buildings")
    }
    
    // MARK: - CRITICAL-4: fixWorkerBuildingsWithDiagnostics
    private func fixWorkerBuildingsWithDiagnostics() async {
        print("🔧 DIAGNOSTICS: Fixing buildings data for \(currentWorkerName)…")
        if workerIdString == "4" {
            await emergencyKevinBuildingFix()
        } else {
            await contextEngine.refreshContext()
        }
        print("✅ DIAGNOSTICS: \(currentWorkerName) buildings refresh completed")
    }
    
    // MARK: - Data Validation
    private func validateRealDataLoaded() async {
        let tCount = contextEngine.getTasksCount()
        let bCount = contextEngine.getBuildingsCount()
        print("📊 Real data validation: Tasks: \(tCount), Buildings: \(bCount)")
    }
    
    // MARK: - Map Background View
    private var mapBackgroundView: some View {
        let center = CLLocationCoordinate2D(latitude: 40.7380, longitude: -73.9970)
        let region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08))
        return ZStack {
            if #available(iOS 17.0, *) {
                Map(initialPosition: .region(region)) {
                    ForEach(assignedBuildings, id: \.id) { building in
                        Annotation(building.name,
                                   coordinate: CLLocationCoordinate2D(
                                    latitude: building.latitude,
                                    longitude: building.longitude)) {
                            mapMarker(for: building)
                        }
                    }
                }
                .mapStyle(.standard)
                .blur(radius: 1.5)
            } else {
                Map(coordinateRegion: .constant(region),
                    annotationItems: assignedBuildings) { building in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: building.latitude,
                        longitude: building.longitude)) {
                        mapMarker(for: building)
                    }
                }
                .blur(radius: 1.5)
            }
            Color.black.opacity(0.3)
        }
    }
    
    // MARK: - Main Content
    private func mainContent(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                HeroStatusCard(
                    clockedInStatus: (
                        isClockedIn: clockedInStatus.isClockedIn,
                        buildingId: clockedInStatus.buildingId != nil
                            ? Int64(clockedInStatus.buildingId!) : nil
                    ),
                    currentBuildingName: currentBuildingName,
                    currentWeather: currentWeather,
                    taskProgress: taskProgress,
                    nextTask: TimeBasedTaskFilter.nextSuggestedTask(from: filteredTaskData),
                    elapsedTime: calculateElapsedTime(),
                    onClockToggle: handleClockToggle
                )
                .id(clockInTime ?? Date.distantPast)
                .id("heroCard")
                
                if let weather = currentWeather, clockedInStatus.isClockedIn {
                    weatherContextCard(weather)
                }
                
                taskTimelineSection
                MySitesCard(
                    workerId: workerIdString,
                    workerName: currentWorkerName,
                    assignedBuildings: assignedBuildings,
                    buildingWeatherMap: buildingWeatherMap,
                    clockedInBuildingId: clockedInStatus.buildingId,
                    isLoading: contextEngine.isLoading,
                    error: contextEngine.error,
                    forceShow: true,
                    onRefresh: { await refreshAllData() },
                    onFixBuildings: { await fixWorkerBuildingsWithDiagnostics() },
                    onBrowseAll: { showAllBuildingsBrowser = true },
                    onBuildingTap: { b in selectBuilding(b) }
                )
                
                if !filteredTaskData.isEmpty { taskOverviewSection }
                
                if categorizedTasks.overdue.contains(where: { task in
                    filteredTaskData.contains(where: { $0.id == task.id })
                }) {
                    overdueTaskBanner
                }
                
                Spacer(minLength: 40)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
    }
    
    // MARK: - Supporting Cards & Sections
    private func weatherContextCard(_ weather: FrancoSphere.WeatherData) -> some View {
        HStack {
            Image(systemName: weatherIconName(for: weather.condition))
                .foregroundColor(weatherIconColor(for: weather.condition))
            VStack(alignment: .leading, spacing: 2) {
                Text("\(weather.formattedTemperature) at \(currentBuildingName)")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(weather.condition.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            Spacer()
            if weather.condition == .rain || weather.condition == .thunderstorm {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var taskTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Timeline")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("\(taskProgress.completedTasks)/\(taskProgress.totalTasks)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            customTimelineProgressBar.frame(height: 32)
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var customTimelineProgressBar: some View {
        GeometryReader { geo in
            let progress = taskProgress.totalTasks > 0
                ? Double(taskProgress.completedTasks) / Double(taskProgress.totalTasks)
                : 0.0
            let width = geo.size.width * progress
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [.green, .blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing))
                    .frame(width: width, height: 8)
                    .animation(.easeInOut(duration: 0.8), value: progress)
                HStack {
                    ForEach(6..<18, id: \.self) { hour in
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 1, height: 16)
                        if hour < 17 { Spacer() }
                    }
                }
            }
        }
    }
    
    private var taskOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Task Overview")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("View All") { showAllTasksView = true }
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            let fc = TimeBasedTaskFilter.categorizeByTimeStatus(tasks: filteredTaskData)
            HStack(spacing: 12) {
                taskStatPill("Current",
                             count: fc.current.count,
                             color: .green)
                taskStatPill("Upcoming",
                             count: fc.upcoming.count,
                             color: .blue)
                taskStatPill("Overdue",
                             count: fc.overdue.count,
                             color: .red)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var overdueTaskBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text("You have overdue tasks at this location")
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func taskStatPill(_ label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    // BEGIN PATCH(HF-11-3): Map marker with actual thumbnails
    private func mapMarker(for building: FrancoSphere.NamedCoordinate) -> some View {
        ZStack {
            Image(building.imageAssetName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
            Circle()
                .stroke(isClockedInBuilding(building) ? .green : .blue,
                        lineWidth: 3)
                .frame(width: 48, height: 48)
        }
        .shadow(radius: 5)
    }
    // END PATCH(HF-11-3)
    
    // MARK: - Animation & Helpers
    private func updateTransformations(for offset: CGFloat) {
        headerOpacity = offset < -200 ? 0.8 : 1.0
    }
    private func weatherIconName(for cond: FrancoSphere.WeatherCondition) -> String {
        switch cond {
        case .clear: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .thunderstorm: return "cloud.bolt.fill"
        case .fog: return "cloud.fog.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    private func weatherIconColor(for cond: FrancoSphere.WeatherCondition) -> Color {
        switch cond {
        case .clear: return .yellow
        case .cloudy: return .gray
        case .rain: return .blue
        case .snow: return .cyan
        case .thunderstorm: return .purple
        case .fog: return .gray.opacity(0.7)
        case .other: return .gray
        }
    }
    private func isClockedInBuilding(_ building: FrancoSphere.NamedCoordinate) -> Bool {
        clockedInStatus.buildingId == building.id
    }
    private func calculateElapsedTime() -> String {
        guard clockedInStatus.isClockedIn, let inTime = clockInTime else { return "" }
        let elapsed = Date().timeIntervalSince(inTime)
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        return "\(h)h \(m)m"
    }
    
    private func filterTasksForLocationAndTime(
        all tasks: [ContextualTask],
        clockedInBuildingId: String?,
        now: Date = Date()
    ) -> [ContextualTask] {
        let cal = Calendar.current
        let total = cal.component(.hour, from: now) * 60
            + cal.component(.minute, from: now)
        let start = total - 180, end = total + 180
        return tasks.filter { task in
            if let bid = clockedInBuildingId,
               task.buildingId != bid {
                return false
            }
            guard let st = task.startTime,
                  let h = Int(st.split(separator: ":")[0]),
                  let mm = Int(st.split(separator: ":")[1]) else {
                return true
            }
            let tmin = h * 60 + mm
            return tmin >= start && tmin <= end
        }
    }
    /// Determine weather risk level for AI scenarios
    private func determineWeatherRisk() -> WeatherRisk {
        guard let weather = currentWeather else { return .unknown }
        
        switch weather.condition {
        case .rain, .thunderstorm:
            return .high // Rain affects outdoor work
        case .snow:
            return .critical // Snow requires immediate attention
        case .fog:
            return .medium // Reduced visibility
        case .clear, .cloudy:
            return .low // Good conditions
        case .other:
            return .unknown
        }
    }
    /// Check if task is overdue based on start time
    private func isTaskOverdue(_ startTime: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let taskTime = formatter.date(from: startTime) else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let todayStart = calendar.startOfDay(for: now)
        
        guard let todayTaskTime = calendar.date(byAdding: .second,
                                                value: Int(taskTime.timeIntervalSince1970),
                                                to: todayStart) else { return false }
        
        // Task is overdue if current time is 30+ minutes past start time
        return now.timeIntervalSince(todayTaskTime) > 1800 // 30 minutes
    }
    // MARK: - Building Navigation
    private func selectBuilding(_ namedCoordinate: FrancoSphere.NamedCoordinate) {
        selectedBuilding = namedCoordinate
        showBuildingDetail = true
        HapticManager.impact(.medium)
    }
    
    // MARK: - Action Methods
    private func handleClockToggle() {
        if clockedInStatus.isClockedIn {
            performClockOut()
        } else {
            showBuildingList = true
        }
    }
    private func performClockOut() {
        Task {
            await MainActor.run {
                clockedInStatus = (false, nil)
                currentBuildingName = "None"
                clockInTime = nil
            }
            await contextEngine.refreshContext()
        }
    }
    private func handleClockIn(
        _ building: FrancoSphere.NamedCoordinate,
        scrollProxy: ScrollViewProxy? = nil
    ) {
        Task {
            await MainActor.run {
                clockedInStatus = (true, building.id)
                currentBuildingName = building.name
                clockInTime = Date()
                showBuildingList = false
                currentWeather = buildingWeatherMap[building.id]
                if let sp = scrollProxy {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        sp.scrollTo("heroCard", anchor: .top)
                    }
                }
            }
            await contextEngine.refreshContext()
        }
    }
    
    private func handleNovaAvatarTap() {
        HapticManager.impact(.medium)
        generateEnhancedContextualScenario()
    }
    private func generateEnhancedContextualScenario() {
        let tasks = contextEngine.getTodaysTasks()
        let builds = contextEngine.getAssignedBuildings()
        let inc = tasks.filter { $0.status != "completed" }
        let hour = Calendar.current.component(.hour, from: Date())
        let morning = inc.filter { t in
            guard let st = t.startTime,
                  let h = Int(st.split(separator: ":")[0]) else { return false }
            return h <= 12
        }
        let afternoon = inc.filter { t in
            guard let st = t.startTime,
                  let h = Int(st.split(separator: ":")[0]) else { return false }
            return h > 12
        }
        if hour < 12 && !morning.isEmpty {
            AIAssistantManager.shared.addScenario(.pendingTasks,
                                                  buildingName: morning.first?.buildingName ?? "",
                                                  taskCount: morning.count)
        } else if hour >= 12 && !afternoon.isEmpty {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: afternoon.first?.buildingName ?? "",
                                                  taskCount: afternoon.count)
        } else if inc.isEmpty {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                  buildingName: builds.first?.name ?? "",
                                                  taskCount: 0)
        } else {
            AIAssistantManager.shared.addScenario(.pendingTasks,
                                                  buildingName: builds.first?.name ?? "",
                                                  taskCount: inc.count)
        }
    }
    private func handleNovaAvatarLongPress() {
        HapticManager.impact(.heavy)
        AIAssistantManager.shared.addScenario(.pendingTasks,
                                              buildingName: currentBuildingName,
                                              taskCount: categorizedTasks.overdue.count
                                                      + categorizedTasks.current.count)
    }
    
    // MARK: - Data Loading Methods
    private func refreshAllData() async {
        await contextEngine.refreshContext()
        await loadProductionWeatherData()
        await triggerPostRefreshAIScenario()
    }
    private func triggerPostRefreshAIScenario() async {
        try? await Task.sleep(nanoseconds: 500_000_000)
        let updatedTasks = contextEngine.getTodaysTasks()
        let updatedBuildings = contextEngine.getAssignedBuildings()
        if updatedTasks.count != filteredTaskData.count ||
            updatedBuildings.count != assignedBuildings.count {
            await triggerTaskBasedAIScenario(tasks: updatedTasks)
        }
    }
    private func checkClockInStatus() async {
        await MainActor.run {
            clockedInStatus = (false, nil)
            currentBuildingName = "None"
        }
    }
    private func loadProductionWeatherData() async {
        await weatherManager.loadWeatherForBuildingsWithFallback(assignedBuildings)
        await MainActor.run {
            buildingWeatherMap = weatherManager.buildingWeatherMap
            currentWeather = weatherManager.currentWeather
        }
    }
    private func startRealtimeClock() {
        currentTime = Date()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1.0,
                                         repeats: true) { _ in currentTime = Date() }
    }
    private func stopRealtimeClock() {
        timeTimer?.invalidate()
        timeTimer = nil
    }
    
    // MARK: - Sheet Views
    private var buildingSelectionSheet: some View {
        NavigationView {
            ZStack {
                Color.clear.background(.ultraThinMaterial).ignoresSafeArea()
                if contextEngine.isLoading {
                    ProgressView().tint(.white)
                } else if assignedBuildings.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(FrancoSphere.NamedCoordinate.allBuildings, id: \.id) { b in
                                buildingSelectionRow(b)
                            }
                        }.padding()
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(assignedBuildings, id: \.id) { b in
                                buildingSelectionRow(b)
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle("Select Building")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showBuildingList = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    private func buildingSelectionRow(_ building: FrancoSphere.NamedCoordinate) -> some View {
        Button { handleClockIn(building) } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(building.imageAssetName)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    if let weather = buildingWeatherMap[building.id] {
                        HStack(spacing: 12) {
                            Label(weather.formattedTemperature,
                                  systemImage: weatherIconName(for: weather.condition))
                                .font(.caption)
                                .foregroundColor(weatherIconColor(for: weather.condition))
                            Text(weather.condition.rawValue)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func taskDetailSheet(_ task: ContextualTask) -> some View {
        NavigationView {
            DashboardTaskDetailView(task: MaintenanceTask(
                name: task.name,
                buildingID: task.buildingId,
                dueDate: Date()
            ))
        }
        .preferredColorScheme(.dark)
    }
    
    private var weatherDetailSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Weather Details")
                    .font(.title)
                    .foregroundColor(.white)
                if let weather = currentWeather {
                    VStack(spacing: 12) {
                        Text(weather.formattedTemperature)
                            .font(.title.bold())
                            .foregroundColor(.white)
                        Text(weather.condition.rawValue)
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                        Text("Feels like \(String(format: "%.0f°F", weather.feelsLike))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showWeatherDetail = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var allTasksViewSheet: some View {
        NavigationView {
            VStack {
                Text("All Tasks View")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAllTasksView = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var allBuildingsBrowserSheet: some View {
        NavigationView {
            ZStack {
                Color.clear.background(.ultraThinMaterial).ignoresSafeArea()
                if contextEngine.isLoading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(FrancoSphere.NamedCoordinate.allBuildings, id: \.id) { b in
                                buildingBrowserRow(b)
                            }
                        }.padding()
                    }
                }
            }
            .navigationTitle("All Buildings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAllBuildingsBrowser = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func buildingBrowserRow(_ building: FrancoSphere.NamedCoordinate) -> some View {
        Button {
            selectBuilding(building)
            showAllBuildingsBrowser = false
        } label: {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(building.imageAssetName)
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 8) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Building ID: \(building.id)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Image(systemName: "info.circle")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// BEGIN PATCH(HF-11-8): Add WeatherRisk enum
enum WeatherRisk: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    case unknown = "Unknown"
}
// END PATCH(HF-11-8)

// MARK: - Scroll Offset Preference Key
private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview Provider
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
            .preferredColorScheme(.dark)
    }
}
