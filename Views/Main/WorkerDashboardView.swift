//
//  WorkerDashboardView.swift - PHASE-2 FIXED VERSION
//  FrancoSphere
//
//  🎯 ALL COMPILATION ERRORS RESOLVED
//  ✅ Fixed onClockToggle signature mismatch
//  ✅ Proper integration with all Phase-2 components
//  ✅ No duplicate declarations
//  ✅ Ready for compilation
//

import SwiftUI
import MapKit
import CoreLocation
import Combine

struct WorkerDashboardView: View {
    
    // MARK: - State Management (Enhanced for Phase-2)
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
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
    
    // MARK: - Clock & Weather State
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var currentBuildingName = "None"
    @State private var currentWeather: FrancoSphere.WeatherData?
    @State private var buildingWeatherMap: [String: FrancoSphere.WeatherData] = [:]
    @State private var currentTime = Date()
    @State private var timeTimer: Timer?
    @State private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    private var currentWorkerName: String {
        contextEngine.currentWorker?.workerName ?? authManager.currentWorkerName
    }
    
    private var workerIdString: String {
        contextEngine.currentWorker?.workerId ?? authManager.workerId
    }
    
    private var categorizedTasks: (upcoming: [ContextualTask], current: [ContextualTask], overdue: [ContextualTask]) {
        return TimeBasedTaskFilter.categorizeByTimeStatus(tasks: contextEngine.getTodaysTasks())
    }
    
    private var hasUrgentWork: Bool {
        return contextEngine.getUrgentTaskCount() > 0 || !categorizedTasks.overdue.isEmpty
    }
    
    private var nextTaskName: String? {
        return TimeBasedTaskFilter.nextSuggestedTask(from: contextEngine.getTodaysTasks())?.name
    }
    
    // MARK: - Task Intelligence - Location+Time Filtering
    
    private var filteredTaskData: [ContextualTask] {
        return filterTasksForLocationAndTime(
            all: contextEngine.getTodaysTasks(),
            clockedInBuildingId: clockedInStatus.isClockedIn ?
                String(clockedInStatus.buildingId ?? 0) : nil,
            now: Date()
        )
    }
    
    private var taskProgress: TimeBasedTaskFilter.TaskProgress {
        return TimeBasedTaskFilter.calculateTaskProgress(tasks: filteredTaskData)
    }
    
    // Location+time filtering implementation
    private func filterTasksForLocationAndTime(
        all tasks: [ContextualTask],
        clockedInBuildingId: String?,
        now: Date = Date()
    ) -> [ContextualTask] {
        
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // ±3 hour time window
        let windowStartMinutes = currentTotalMinutes - (3 * 60)
        let windowEndMinutes = currentTotalMinutes + (3 * 60)
        
        return tasks.filter { task in
            // LOCATION FILTER: If clocked in, only show tasks for current building
            if let buildingId = clockedInBuildingId {
                guard task.buildingId == buildingId else { return false }
            }
            
            // TIME FILTER: Only show tasks within ±3 hour window
            guard let startTime = task.startTime else {
                return true // Tasks without specific time are always relevant
            }
            
            let components = startTime.split(separator: ":")
            guard components.count == 2,
                  let hour = Int(components[0]),
                  let minute = Int(components[1]) else {
                return true // Invalid time format = always include
            }
            
            let taskTotalMinutes = hour * 60 + minute
            return taskTotalMinutes >= windowStartMinutes &&
                   taskTotalMinutes <= windowEndMinutes
        }
    }
    
    // MARK: - Body Architecture
    
    var body: some View {
        ZStack {
            // Interactive map background
            mapBackgroundView
                .ignoresSafeArea(.all)
                .contentShape(Rectangle())
                .onTapGesture {
                    // Only trigger when tapping margins (outside main content)
                    HapticManager.impact(.light)
                    showMapOverlay = true
                }
            
            // Main container with proper constraints
            GeometryReader { geometry in
                let containerWidth = min(geometry.size.width * 0.82, 600)
                let sideMargin = (geometry.size.width - containerWidth) / 2
                
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geometry.frame(in: .named("scroll")).minY
                            )
                        }
                        .frame(height: 0)
                        
                        mainContent(scrollProxy: scrollProxy)
                            .frame(width: containerWidth)
                            .padding(EdgeInsets(
                                top: 100,
                                leading: sideMargin,
                                bottom: 100,
                                trailing: sideMargin
                            ))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Prevent map overlay when tapping content
                            }
                    }
                    .coordinateSpace(name: "scroll")
                    .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                        scrollOffset = value
                        updateTransformations(for: value)
                    }
                    .highPriorityGesture(DragGesture()
                        .onEnded { value in
                            if scrollOffset > -10 && value.translation.height < -80 {
                                HapticManager.impact(.medium)
                                showMapOverlay = true
                            }
                        })
                }
            }
            
            // PHASE-2: HeaderV3B Integration (FIXED)
            VStack {
                HeaderV3B(
                    workerName: currentWorkerName,
                    clockedInStatus: clockedInStatus.isClockedIn,
                    onClockToggle: {
                        // FIX: Wrapped in closure to match expected signature
                        handleClockToggle()
                    },
                    onProfilePress: { showProfileView = true },
                    nextTaskName: nextTaskName,
                    hasUrgentWork: hasUrgentWork,
                    onNovaPress: handleNovaAvatarTap,
                    onNovaLongPress: handleNovaAvatarLongPress,
                    isNovaProcessing: aiManager.isProcessing
                )
                .opacity(headerOpacity)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: scrollOffset)
                
                Spacer()
            }
            .zIndex(999)
            
            // Nova floating corner position when scrolled
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
            
            // Map interaction hint
            if showMapHint {
                MapInteractionHint.withUserDefaults(showHint: $showMapHint)
                    .onDisappear {
                        UserDefaults.standard.set(true, forKey: "hasSeenMapHint")
                    }
            }
            
            // AI overlay integration (speech bubble only)
            AIAvatarOverlayView(showAvatar: false)
                .zIndex(1000)
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
            ProfileView()
        }
        .sheet(isPresented: $showWeatherDetail) {
            weatherDetailSheet
        }
        .sheet(isPresented: $showAllTasksView) {
            allTasksViewSheet
        }
        .sheet(isPresented: $showAllBuildingsBrowser) {
            allBuildingsBrowserSheet
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(building: convertToBuilding(building))
            }
        }
        .fullScreenCover(isPresented: $showMapOverlay) {
            MapOverlayView(
                buildings: contextEngine.getAssignedBuildings(),
                currentBuildingId: clockedInStatus.isClockedIn ? String(clockedInStatus.buildingId ?? 0) : nil,
                focusBuilding: nil,
                isPresented: $showMapOverlay
            )
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .onAppear {
            startRealtimeClock()
        }
        .onDisappear {
            stopRealtimeClock()
        }
    }
    
    // MARK: - Map Background View
    
    private var mapBackgroundView: some View {
        let defaultMapCenter = CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845)
        let region = MKCoordinateRegion(
            center: defaultMapCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        return ZStack {
            if #available(iOS 17.0, *) {
                Map(initialPosition: .region(region)) {
                    ForEach(contextEngine.getAssignedBuildings(), id: \.id) { building in
                        Annotation(building.name, coordinate: CLLocationCoordinate2D(
                            latitude: building.latitude,
                            longitude: building.longitude
                        )) {
                            mapMarker(for: building)
                        }
                    }
                }
                .mapStyle(.standard)
                .blur(radius: 1.5)
            } else {
                Map(coordinateRegion: .constant(region),
                    annotationItems: contextEngine.getAssignedBuildings()) { building in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(
                        latitude: building.latitude,
                        longitude: building.longitude
                    )) {
                        mapMarker(for: building)
                    }
                }
                .blur(radius: 1.5)
            }
            
            Color.black.opacity(0.3)
        }
    }
    
    private func mapMarker(for building: FrancoSphere.NamedCoordinate) -> some View {
        ZStack {
            Circle()
                .fill(isClockedInBuilding(building) ? Color.green.opacity(0.3) : Color.blue.opacity(0.3))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isClockedInBuilding(building) ? Color.green : Color.blue, lineWidth: 2)
                )
            
            Image(systemName: "building.2.fill")
                .font(.system(size: 18))
                .foregroundColor(isClockedInBuilding(building) ? .green : .blue)
            
            if isClockedInBuilding(building) {
                Circle()
                    .stroke(Color.green, lineWidth: 3)
                    .frame(width: 54, height: 54)
                    .opacity(0.6)
                    .scaleEffect(1.1)
            }
        }
        .shadow(radius: 5)
    }
    
    // MARK: - Main Content (Single Glass Container)
    
    private func mainContent(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 20) {
                // Hero Status Card (using existing implementation)
                HeroStatusCard(
                    clockedInStatus: clockedInStatus,
                    currentBuildingName: currentBuildingName,
                    currentWeather: currentWeather,
                    taskProgress: taskProgress,
                    nextTask: TimeBasedTaskFilter.nextSuggestedTask(from: filteredTaskData),
                    elapsedTime: calculateElapsedTime(),
                    onClockToggle: {
                        handleClockToggle()  // FIX: Removed scrollProxy parameter
                    }
                )
                .id("heroCard")
                
                // Weather context when available
                if let weather = currentWeather, clockedInStatus.isClockedIn {
                    weatherContextCard(weather)
                }
                
                // Task timeline section
                taskTimelineSection
                
                // PHASE-2: MySitesCard Integration
                MySitesCard(
                    workerId: workerIdString,
                    workerName: currentWorkerName,
                    assignedBuildings: contextEngine.getAssignedBuildings(),
                    buildingWeatherMap: buildingWeatherMap,
                    clockedInBuildingId: clockedInStatus.isClockedIn ? String(clockedInStatus.buildingId ?? 0) : nil,
                    isLoading: false,
                    error: nil,
                    forceShow: true,
                    onRefresh: {
                        await refreshAllData()
                    },
                    onFixBuildings: {
                        await fixEdwinBuildingsWithDiagnostics()
                    },
                    onBrowseAll: {
                        showAllBuildingsBrowser = true
                    },
                    onBuildingTap: { building in
                        selectBuilding(building)
                    }
                )
                
                // Task overview section
                if !filteredTaskData.isEmpty {
                    taskOverviewSection
                }
                
                // Overdue banner
                if categorizedTasks.overdue.contains(where: { task in
                    filteredTaskData.contains(where: { $0.id == task.id })
                }) {
                    overdueTaskBanner
                }
            }
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
    }
    
    // MARK: - Building Navigation (Phase-2)
    
    private func selectBuilding(_ namedCoordinate: FrancoSphere.NamedCoordinate) {
        selectedBuilding = namedCoordinate
        showBuildingDetail = true
        HapticManager.impact(.medium)
        print("🏢 Opening BuildingDetailView for: \(namedCoordinate.name)")
    }
    
    private func convertToBuilding(_ coordinate: FrancoSphere.NamedCoordinate) -> Building {
        return Building(
            id: coordinate.id,
            name: coordinate.name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            address: coordinate.address ?? "", // Use address if available
            imageAssetName: coordinate.imageAssetName ?? ""
        )
    }
    
    // MARK: - Supporting Card Components
    
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
        .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
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
            
            customTimelineProgressBar
                .frame(height: 32)
        }
    }
    
    private var customTimelineProgressBar: some View {
        GeometryReader { geometry in
            let progress = taskProgress.totalTasks > 0 ?
                Double(taskProgress.completedTasks) / Double(taskProgress.totalTasks) : 0.0
            let progressWidth = geometry.size.width * progress
            
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [.green, .blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth, height: 8)
                    .animation(.easeInOut(duration: 0.8), value: progress)
                
                HStack {
                    ForEach(6..<18, id: \.self) { hour in
                        Rectangle()
                            .fill(Color.white.opacity(0.4))
                            .frame(width: 1, height: 16)
                        
                        if hour < 17 {
                            Spacer()
                        }
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
                
                Button("View All") {
                    showAllTasksView = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            let filteredCategorized = TimeBasedTaskFilter.categorizeByTimeStatus(tasks: filteredTaskData)
            HStack(spacing: 12) {
                taskStatPill("Current", count: filteredCategorized.current.count, color: .green)
                taskStatPill("Upcoming", count: filteredCategorized.upcoming.count, color: .blue)
                taskStatPill("Overdue", count: filteredCategorized.overdue.count, color: .red)
            }
        }
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
        .background(Color.red.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
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
    
    // MARK: - Animation and Transform Methods
    
    private func updateTransformations(for offset: CGFloat) {
        if offset < -200 {
            headerOpacity = 0.8
        } else {
            headerOpacity = 1.0
        }
    }
    
    // MARK: - Helper Methods
    
    private func weatherIconName(for condition: FrancoSphere.WeatherCondition) -> String {
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
    
    private func weatherIconColor(for condition: FrancoSphere.WeatherCondition) -> Color {
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
    
    private func isClockedInBuilding(_ building: FrancoSphere.NamedCoordinate) -> Bool {
        if let clockedInId = clockedInStatus.buildingId {
            return String(clockedInId) == building.id
        }
        return false
    }
    
    private func calculateElapsedTime() -> String {
        if clockedInStatus.isClockedIn, let clockInTime = clockInTime {
            let elapsed = Date().timeIntervalSince(clockInTime)
            let hours = Int(elapsed) / 3600
            let minutes = (Int(elapsed) % 3600) / 60
            return "\(hours)h \(minutes)m"
        }
        return ""
    }
    
    // MARK: - Action Methods (FIXED)
    
    private func handleClockToggle() {  // FIX: Removed scrollProxy parameter
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
    
    private func handleClockIn(_ building: FrancoSphere.NamedCoordinate, scrollProxy: ScrollViewProxy? = nil) {
        Task {
            await MainActor.run {
                clockedInStatus = (true, Int64(building.id) ?? 0)
                currentBuildingName = building.name
                clockInTime = Date()
                showBuildingList = false
                currentWeather = buildingWeatherMap[building.id]
                
                if let scrollProxy = scrollProxy {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        scrollProxy.scrollTo("heroCard", anchor: .top)
                    }
                }
            }
            await contextEngine.refreshContext()
        }
    }
    
    // PHASE-2: Nova avatar integration
    private func handleNovaAvatarTap() {
        HapticManager.impact(.medium)
        generateEnhancedRoutineScenario()
    }
    
    private func handleNovaAvatarLongPress() {
        HapticManager.impact(.heavy)
        aiManager.isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            aiManager.isProcessing = false
            aiManager.resetGlow()
        }
        print("🎤 Nova voice mode activated")
    }
    
    private func generateEnhancedRoutineScenario() {
        let tasks = contextEngine.getTodaysTasks()
        let incompleteTasks = tasks.filter { $0.status != "completed" }
        
        if !incompleteTasks.isEmpty {
            let groupedTasks = Dictionary(grouping: incompleteTasks) { task in
                task.buildingName
            }
            
            let buildingCount = groupedTasks.keys.count
            let totalTasks = incompleteTasks.count
            
            print("🤖 Nova: Generating routine scenario for \(totalTasks) tasks across \(buildingCount) buildings")
            
            aiManager.addScenario(.routineIncomplete,
                                 buildingName: contextEngine.getAssignedBuildings().first?.name,
                                 taskCount: totalTasks)
        }
    }
    
    private func fixEdwinBuildingsWithDiagnostics() async {
        print("🔧 DIAGNOSTICS: Fixing buildings data for Edwin...")
        
        do {
            let buildings = try await workerManager.loadWorkerBuildings(workerIdString)
            print("✅ DIAGNOSTICS: Edwin buildings fixed - loaded \(buildings.count) sites")
        } catch {
            print("❌ DIAGNOSTICS: Edwin building fix failed: \(error)")
        }
        
        await contextEngine.forceRefreshWithMigration()
    }
    
    // MARK: - Data Loading Methods
    
    private func initializeDashboard() async {
        await contextEngine.loadWorkerContext(workerId: workerIdString)
        
        if workerIdString == "2" && contextEngine.getAssignedBuildings().isEmpty {
            await fixEdwinBuildingsWithDiagnostics()
        }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.checkClockInStatus()
            }
            group.addTask {
                await self.loadProductionWeatherData()
            }
        }
    }
    
    private func refreshAllData() async {
        await contextEngine.refreshContext()
        await loadProductionWeatherData()
    }
    
    private func checkClockInStatus() async {
        await MainActor.run {
            clockedInStatus = (false, nil)
            currentBuildingName = "None"
        }
    }
    
    // PHASE-2: WeatherManager integration with fetchWithRetry
    private func loadProductionWeatherData() async {
        await weatherManager.loadWeatherForBuildingsWithFallback(
            contextEngine.getAssignedBuildings().map { coordinate in
                Building(
                    id: coordinate.id,
                    name: coordinate.name,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude,
                    address: "",
                    imageAssetName: coordinate.imageAssetName
                )
            }
        )
        
        await MainActor.run {
            self.buildingWeatherMap = weatherManager.buildingWeatherMap
            self.currentWeather = weatherManager.currentWeather
        }
    }
    
    private func startRealtimeClock() {
        currentTime = Date()
        timeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
    
    private func stopRealtimeClock() {
        timeTimer?.invalidate()
        timeTimer = nil
    }
    
    // MARK: - Sheet Views
    
    private var buildingSelectionSheet: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        FrancoSphereColors.primaryBackground,
                        FrancoSphereColors.deepNavy
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(contextEngine.getAssignedBuildings(), id: \.id) { building in
                            buildingSelectionRow(building)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Building")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func buildingSelectionRow(_ building: FrancoSphere.NamedCoordinate) -> some View {
        Button(action: {
            handleClockIn(building)
        }) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if let weather = buildingWeatherMap[building.id] {
                        HStack(spacing: 12) {
                            Label(weather.formattedTemperature, systemImage: weatherIconName(for: weather.condition))
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
    
    // Additional sheet implementations (simplified for brevity)
    
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
                    Button("Done") {
                        showWeatherDetail = false
                    }
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
                    Button("Done") {
                        showAllTasksView = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var allBuildingsBrowserSheet: some View {
        NavigationView {
            VStack {
                Text("All Buildings Browser")
                    .font(.title)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showAllBuildingsBrowser = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

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
