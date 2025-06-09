//
//  WorkerDashboardView.swift
//  FrancoSphere
//
//  Glassmorphism Sprint - COMPILATION ERRORS FIXED
//  Fixed: String → Int64 conversions, removed duplicate declarations
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - AuthManager Extension
extension AuthManager {
    /// Computed property to check authentication status
    var isAuthenticated: Bool {
        return Int64(workerId) != nil && !currentWorkerName.isEmpty
    }
}

// MARK: - Building Selection Row Component
struct BuildingSelectionRow: View {
    let building: NamedCoordinate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            GlassCard(intensity: .thin, padding: 16) {
                HStack(spacing: 16) {
                    buildingImage
                    buildingDetails
                    Spacer()
                    Image(systemName: "clock.badge.plus")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var buildingImage: some View {
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
    }

    private var buildingDetails: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(building.name)
                .font(.headline).fontWeight(.semibold).foregroundColor(.white).lineLimit(2)
            if let addr = building.address {
                Text(addr)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            HStack(spacing: 8) {
                Image(systemName: "location")
                    .font(.caption2)
                    .foregroundColor(.blue)
                Text("Tap to clock in")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - WorkerDashboardView
struct WorkerDashboardView: View {
    // MARK: Properties
    @StateObject private var authManager = NewAuthManager.shared
    private let taskManager = TaskManager.shared

    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var currentBuildingName: String = "None"
    @State private var assignedBuildings: [NamedCoordinate] = []
    @State private var todaysTasks: [MaintenanceTask] = []
    @State private var weatherAlerts: [WeatherAlert] = []

    @State private var showProfileView = false
    @State private var showBuildingList = false
    @State private var showTaskDetail: MaintenanceTask? = nil
    @State private var showWeatherDetail = false

    @State private var currentTemperature: Int = 72
    @State private var currentCondition: String = "Partly Cloudy"
    @State private var showAllBuildings = false

    @State private var isLoading = true
    @State private var dataLoadingError: String? = nil

    // MARK: Computed
    private var currentWorkerName: String {
        let name = authManager.currentWorkerName
        return name.isEmpty ? "Worker" : name
    }
    private var workerIdString: String { authManager.workerId }
    private var pendingTaskCount: Int { todaysTasks.filter { !$0.isComplete }.count }
    private var completedTaskCount: Int { todaysTasks.filter { $0.isComplete }.count }

    // MARK: Body
    var body: some View {
        ZStack {
            mapBackgroundView

            VStack(spacing: 0) {
                dynamicNavigationHeader

                if isLoading {
                    loadingStateView
                } else if let error = dataLoadingError {
                    errorStateView(error)
                } else {
                    mainContentView
                }
            }

            aiAvatarOverlay
        }
        .task { await initializeWorkerDashboard() }
        .refreshable { await refreshWorkerData() }
        .sheet(isPresented: $showBuildingList) { buildingSelectionSheet }
        .sheet(item: $showTaskDetail) { taskDetailSheet($0) }
        .fullScreenCover(isPresented: $showProfileView) { profileSheet }
        .sheet(isPresented: $showWeatherDetail) { weatherDetailSheet }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
    }

    // MARK: Map Background
    private var mapBackgroundView: some View {
        ZStack {
            Map(coordinateRegion: .constant(
                    MKCoordinateRegion(
                        center: CLLocationCoordinate2D(latitude: 40.7590, longitude: -73.9845),
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                ),
                annotationItems: assignedBuildings
            ) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                                latitude: building.latitude,
                                longitude: building.longitude
                              )) {
                    Button {
                        navigateToBuildingDetail(building)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .shadow(radius: 5)
                    }
                }
            }
            .blur(radius: 1.5)
            .opacity(0.7)

            Color.black.opacity(0.3)
        }
        .ignoresSafeArea()
    }

    // MARK: Navigation Header
    private var dynamicNavigationHeader: some View {
        GlassCard(intensity: .regular, cornerRadius: 0, padding: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("FRANCOSPHERE")
                        .font(.headline).fontWeight(.bold).foregroundColor(.white)
                    Text(currentWorkerName)
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                HStack(spacing: 12) {
                    clockInOutButton
                    statusIndicator
                    profileMenuButton
                }
            }
        }
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
            .padding(.horizontal, 16).padding(.vertical, 8)
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
                .font(.caption).foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
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
                Task { await forceDataRefresh() }
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
                Circle().fill(Color.white.opacity(0.15)).frame(width: 36, height: 36)
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
    }

    // MARK: Main Content
    private var mainContentView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if clockedInStatus.isClockedIn {
                    CurrentBuildingStatusCard(buildingName: currentBuildingName)
                }
                weatherOverviewCard
                todaysTasksCard
                workerBuildingsSection
                if !todaysTasks.isEmpty {
                    taskSummaryCard
                }
                debugInfoCard
                Color.clear.frame(height: 100)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }

    private var todaysTasksCard: some View {
        GlassCard(intensity: .regular) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.clipboard").foregroundColor(.white)
                    Text("Today's Tasks").font(.headline).foregroundColor(.white)
                    Spacer()
                    Text("\(todaysTasks.count)")
                        .font(.title2).fontWeight(.bold).foregroundColor(.blue)
                }
                if todaysTasks.isEmpty {
                    emptyTasksView
                } else {
                    VStack(spacing: 8) {
                        ForEach(Array(todaysTasks.prefix(3).enumerated()), id: \.offset) { idx, task in
                            taskRowPreview(task: task)
                            if idx < min(2, todaysTasks.count - 1) {
                                Divider().background(Color.white.opacity(0.2))
                            }
                        }
                        if todaysTasks.count > 3 {
                            Button("View All \(todaysTasks.count) Tasks") {
                                // handle
                            }
                            .font(.caption).foregroundColor(.blue)
                            .padding(.top, 8)
                        }
                    }
                }
            }
        }
    }

    private func taskRowPreview(task: MaintenanceTask) -> some View {
        Button {
            showTaskDetail = task
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    let color = task.isComplete
                        ? Color.green
                        : getUrgencyColor(task.urgency)
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(Circle().stroke(color, lineWidth: 2))
                    Image(systemName: task.isComplete ? "checkmark" : task.category.icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .font(.subheadline).fontWeight(.medium).foregroundColor(.white)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(task.category.rawValue)
                            .font(.caption2).foregroundColor(.white.opacity(0.6))
                        Text("•").foregroundColor(.white.opacity(0.4))
                        Text(task.urgency.rawValue)
                            .font(.caption2)
                            .foregroundColor(getUrgencyColor(task.urgency))
                    }
                }
                Spacer()
                if let start = task.startTime {
                    Text(start, style: .time)
                        .font(.caption).foregroundColor(.white.opacity(0.7))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption).foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var emptyTasksView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40)).foregroundColor(.green.opacity(0.6))
            Text("All tasks completed!")
                .font(.subheadline).foregroundColor(.white.opacity(0.8))
            Text("Great work today")
                .font(.caption).foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var loadingStateView: some View {
        VStack {
            Spacer()
            GlassCard(intensity: .thin) {
                VStack(spacing: 16) {
                    ProgressView().scaleEffect(1.2).tint(.blue)
                    Text("Loading \(currentWorkerName)'s dashboard...")
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                    Text("Importing tasks and assignments...")
                        .font(.caption).foregroundColor(.white.opacity(0.6))
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
                        .font(.system(size: 40)).foregroundColor(.orange)
                    Text("Data Loading Error")
                        .font(.headline).foregroundColor(.white)
                    Text(error)
                        .font(.subheadline).foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await refreshWorkerData() }
                    }
                    .foregroundColor(.blue)
                }
                .padding(.vertical, 20)
            }
            .padding()
            Spacer()
        }
    }

    // MARK: Content Cards (weather, buildings, summary, debug)
    private var weatherOverviewCard: some View {
        GlassCard(intensity: .regular) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: weatherIcon).font(.title2).foregroundColor(weatherIconColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(currentTemperature)°F")
                            .font(.headline).foregroundColor(.white)
                        Text(currentCondition)
                            .font(.caption).foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(pendingTaskCount)")
                            .font(.title2).fontWeight(.bold).foregroundColor(.orange)
                        Text("pending").font(.caption).foregroundColor(.white.opacity(0.6))
                    }
                }
                Text("Weather conditions look good for outdoor tasks today")
                    .font(.caption).foregroundColor(.white.opacity(0.7))
            }
        }
        .onTapGesture { showWeatherDetail = true }
    }

    private var workerBuildingsSection: some View {
        GlassCard(intensity: .regular) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "building.2").foregroundColor(.white)
                    Text("Assigned Buildings")
                        .font(.headline).foregroundColor(.white)
                    Spacer()
                    Text("\(assignedBuildings.count)")
                        .font(.title2).fontWeight(.bold).foregroundColor(.blue)
                    if assignedBuildings.count > 3 {
                        Button {
                            withAnimation { showAllBuildings.toggle() }
                        } label: {
                            Text(showAllBuildings ? "Show Less" : "Show All")
                                .font(.caption).foregroundColor(.blue)
                        }
                    }
                }
                if assignedBuildings.isEmpty {
                    emptyBuildingsView
                } else {
                    VStack(spacing: 12) {
                        ForEach(showAllBuildings ? assignedBuildings : Array(assignedBuildings.prefix(3))) { b in
                            NavigationLink(destination: buildingDetailView(b)) {
                                WorkerBuildingRow(
                                    building: b,
                                    isClockedIn: isClockedInBuilding(b),
                                    taskCount: getTaskCount(for: b)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private var taskSummaryCard: some View {
        GlassCard(intensity: .regular) {
            VStack(spacing: 16) {
                HStack {
                    Text("Today's Summary").font(.headline).foregroundColor(.white)
                    Spacer()
                }
                HStack(spacing: 20) {
                    TaskSummaryItem(count: completedTaskCount, label: "Completed", color: .green)
                    Divider().frame(height: 40).background(Color.white.opacity(0.3))
                    TaskSummaryItem(count: pendingTaskCount, label: "Pending", color: .orange)
                    Divider().frame(height: 40).background(Color.white.opacity(0.3))
                    TaskSummaryItem(
                        count: todaysTasks.filter { !$0.isComplete && $0.isPastDue }.count,
                        label: "Overdue",
                        color: .red
                    )
                }
            }
        }
    }

    private var debugInfoCard: some View {
        GlassCard(intensity: .thin) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Debug Info")
                    .font(.caption.bold()).foregroundColor(.white.opacity(0.8))
                Text("Worker ID: \(workerIdString)")
                    .font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("Buildings: \(assignedBuildings.count)")
                    .font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("Tasks: \(todaysTasks.count)")
                    .font(.caption2).foregroundColor(.white.opacity(0.6))
                Text("Auth Status: \(authManager.isAuthenticated ? "✅" : "❌")")
                    .font(.caption2).foregroundColor(.white.opacity(0.6))
            }
        }
    }

    private var emptyBuildingsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 40)).foregroundColor(.gray.opacity(0.6))
            Text("No buildings assigned")
                .font(.subheadline).foregroundColor(.white.opacity(0.7))
            Text("Contact your supervisor to get building assignments")
                .font(.caption).foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private var aiAvatarOverlay: some View {
        VStack {
            HStack {
                Spacer()
                Button { /* AI Action */ } label: {
                    ZStack {
                        Circle().fill(.ultraThinMaterial).frame(width: 60, height: 60)
                            .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                        Image(systemName: "brain.head.profile")
                            .font(.title2).foregroundColor(.blue)
                    }
                }
                .shadow(radius: 10)
                .padding(.trailing, 20)
                .padding(.top, 120)
            }
            Spacer()
        }
    }

    // MARK: Data Loading
    private func initializeWorkerDashboard() async {
        isLoading = true
        dataLoadingError = nil
        do {
            await triggerCSVImportIfNeeded()
            async let clockIn = checkClockInStatus()
            async let loadBld = loadWorkerAssignedBuildings()
            async let loadTasks = loadWorkerTasks()
            async let loadWeather = loadWeatherData()      // <-- now finds loadWeatherData()
            _ = await (clockIn, loadBld, loadTasks, loadWeather)
            await MainActor.run { isLoading = false }
        } catch {
            await MainActor.run {
                isLoading = false
                dataLoadingError = error.localizedDescription
            }
        }
    }

    private func refreshWorkerData() async {
        await initializeWorkerDashboard()
    }

    private func forceDataRefresh() async {
        await MainActor.run {
            assignedBuildings = []
            todaysTasks = []
        }
        await initializeWorkerDashboard()
    }

    private func triggerCSVImportIfNeeded() async {
        do {
            let importer = CSVDataImporter.shared
            _ = try await importer.importRealWorldTasks()
        } catch {
            print("CSV import failed: \(error)")
        }
    }

    private func loadWorkerAssignedBuildings() async {
        let all = await BuildingRepository.shared.allBuildings
        let profile = WorkerProfile.allWorkers.first { $0.id == workerIdString }
        let ids = profile?.assignedBuildings ?? []
        await MainActor.run {
            assignedBuildings = all.filter { ids.contains($0.id) }
        }
    }

    private func loadWorkerTasks() async {
        let tasks = await taskManager.fetchTasksAsync(forWorker: workerIdString, date: Date())
        await MainActor.run {
            todaysTasks = tasks.sorted { lhs, rhs in
                if lhs.isComplete != rhs.isComplete {
                    return !lhs.isComplete && rhs.isComplete
                }
                return lhs.dueDate < rhs.dueDate
            }
        }
    }

    /// **Missing method** — now added back
    private func loadWeatherData() async {
        // Replace with real weather fetch if available
        await MainActor.run {
            currentTemperature = 72
            currentCondition = "Partly Cloudy"
        }
    }

    // MARK: - Clock In/Out

    private func checkClockInStatus() async {
        do {
            let sql = try await SQLiteManager.start()
            guard let workerInt = Int64(authManager.workerId) else { return }
            let status = await sql.isWorkerClockedInAsync(workerId: workerInt)
            await MainActor.run {
                clockedInStatus = status
                if let bId = status.buildingId {
                    currentBuildingName = BuildingRepository
                        .shared
                        .getBuildingName(forId: String(bId))
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
                guard let workerInt = Int64(authManager.workerId) else { return }
                try await sql.logClockOutAsync(workerId: workerInt, timestamp: Date())
                await MainActor.run {
                    clockedInStatus = (false, nil)
                    currentBuildingName = "None"
                }
            } catch {
                print("Clock-out failed: \(error)")
            }
        }
    }

    private func handleClockIn(_ building: NamedCoordinate) {
        Task {
            do {
                let sql = try await SQLiteManager.start()
                guard
                    let workerInt = Int64(authManager.workerId),
                    let bId = Int64(building.id)
                else {
                    await MainActor.run {
                        dataLoadingError = "Invalid ID format"
                    }
                    return
                }
                try await sql.logClockInAsync(workerId: workerInt, buildingId: bId, timestamp: Date())
                await MainActor.run {
                    clockedInStatus = (true, bId)
                    currentBuildingName = building.name
                    showBuildingList = false
                }
                await loadWorkerTasks()
            } catch {
                await MainActor.run {
                    dataLoadingError = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Building Detail & Helpers

    private func navigateToBuildingDetail(_ building: NamedCoordinate) {
        // implement navigation
    }

    private func buildingDetailView(_ building: NamedCoordinate) -> some View {
        ZStack {
            FrancoSphereColors.primaryBackground.ignoresSafeArea()
            VStack(spacing: 20) {
                if let img = UIImage(named: building.imageAssetName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                }
                Text(building.name)
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text("Tasks for this building: \(getTaskCount(for: building))")
                    .font(.subheadline).foregroundColor(.white.opacity(0.8))
            }
            .padding()
        }
        .navigationTitle(building.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func getTaskCount(for building: NamedCoordinate) -> Int {
        todaysTasks.filter { $0.buildingID == building.id }.count
    }

    private func getUrgencyColor(_ u: TaskUrgency) -> Color {
        switch u {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .red
        case .urgent: return .purple
        }
    }

    // MARK: - Sheets & Modals

    private var buildingSelectionSheet: some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(assignedBuildings) { b in
                            BuildingSelectionRow(building: b) {
                                handleClockIn(b)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Building")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showBuildingList = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func taskDetailSheet(_ task: MaintenanceTask) -> some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground.ignoresSafeArea()
                ScrollView {
                    GlassCard(intensity: .thin) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(task.name)
                                .font(.title2).fontWeight(.bold).foregroundColor(.white)
                            Text(task.description)
                                .font(.body).foregroundColor(.white.opacity(0.8))
                            taskMetadataSection(task)
                        }
                        .padding(20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Task Details")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showTaskDetail = nil }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func taskMetadataSection(_ task: MaintenanceTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Category", systemImage: task.category.icon)
                Spacer()
                Text(task.category.rawValue)
            }
            .font(.subheadline).foregroundColor(.white.opacity(0.7))

            HStack {
                Label("Urgency", systemImage: "exclamationmark.triangle")
                Spacer()
                Text(task.urgency.rawValue)
                    .foregroundColor(getUrgencyColor(task.urgency))
            }
            .font(.subheadline)

            if let start = task.startTime {
                HStack {
                    Label("Start Time", systemImage: "clock")
                    Spacer()
                    Text(start, style: .time)
                }
                .font(.subheadline).foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private var profileSheet: some View {
        NavigationView {
            ProfileView()
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { showProfileView = false }
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
                GlassCard(intensity: .regular) {
                    VStack(spacing: 30) {
                        Image(systemName: weatherIcon)
                            .font(.system(size: 80)).foregroundColor(weatherIconColor)
                        Text("\(currentTemperature)°")
                            .font(.system(size: 72, weight: .thin))
                            .foregroundColor(.white)
                        Text(currentCondition)
                            .font(.title2).foregroundColor(.white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
                .padding()
            }
            .navigationTitle("Weather")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showWeatherDetail = false }
                        .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func logoutUser() {
        authManager.logout()
    }

    private func isClockedInBuilding(_ building: NamedCoordinate) -> Bool {
        if let b = clockedInStatus.buildingId {
            return String(b) == building.id
        }
        return false
    }

    // MARK: Utilities

    private var weatherIcon: String {
        let cond = currentCondition.lowercased()
        if cond.contains("rain")    { return "cloud.rain.fill" }
        if cond.contains("snow")    { return "snow" }
        if cond.contains("cloud")   { return "cloud.fill" }
        if cond.contains("thunder") { return "cloud.bolt.fill" }
        if cond.contains("fog")     { return "cloud.fog.fill" }
        return "sun.max.fill"
    }

    private var weatherIconColor: Color {
        let cond = currentCondition.lowercased()
        if cond.contains("rain")    { return .blue }
        if cond.contains("snow")    { return .cyan }
        if cond.contains("cloud")   { return .gray }
        if cond.contains("thunder") { return .purple }
        if cond.contains("fog")     { return .gray }
        return .yellow
    }
}

// MARK: - Previews
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
            .preferredColorScheme(.dark)
    }
}
