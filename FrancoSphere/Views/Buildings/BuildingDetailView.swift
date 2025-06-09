//
//  BuildingDetailView.swift
//  FrancoSphere
//
//  Fixed implementation with all missing methods
//

import SwiftUI
import MapKit
import CoreLocation

struct BuildingDetailView: View {
    let building: FrancoSphere.NamedCoordinate
    
    // MARK: - State Management
    @State private var selectedTab = 0
    @State private var showClockInModal = false
    @State private var showAddTaskSheet = false
    @State private var showTaskDetail: FrancoSphere.MaintenanceTask? = nil
    @State private var showPhotoUploader = false
    @State private var taskForAction: FrancoSphere.MaintenanceTask? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var showCompletionConfirmation = false
    
    // Task expansion state
    @State private var expandedCategories: Set<String> = ["emergency", "cleaning"]
    @State private var expandedTasks: Set<String> = []
    
    // Data state
    @State private var routineTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var sanitationTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var inspectionTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var weatherTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var emergencyTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    
    // Managers
    @State private var sqliteManager: SQLiteManager?
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    
    private var authManager: NewAuthManager { NewAuthManager.shared }
    private let taskManager = TaskManager.shared
    private let buildingRepository = BuildingRepository.shared
    
    var body: some View {
        ZStack {
            // Background with building image blur
            buildingBackgroundView
            
            // Main content with glass cards
            ScrollView {
                VStack(spacing: 24) {
                    // Header glass overlay
                    BuildingHeaderGlassOverlay(
                        building: building,
                        clockedInStatus: clockedInStatus,
                        onClockAction: handleClockAction
                    )
                    
                    // Stats glass card
                    BuildingStatsGlassCard(
                        pendingTasksCount: getTotalPendingTasks(),
                        completedTasksCount: getTotalCompletedTasksToday(),
                        assignedWorkersCount: getAssignedWorkersCount(),
                        weatherRisk: getCurrentWeatherRisk()
                    )
                    .padding(.horizontal, 16)
                    
                    // Weather glass card (if weather data available)
                    if let weatherCard = createWeatherCard() {
                        weatherCard
                            .padding(.horizontal, 16)
                    }
                    
                    // Tab selector
                    tabSelector
                        .padding(.horizontal, 16)
                    
                    // Tab content
                    tabContent
                        .padding(.horizontal, 16)
                    
                    // Bottom spacing for scroll
                    Color.clear.frame(height: 100)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                buildingActionsMenu
            }
        }
        .task {
            await initializeData()
        }
        .onAppear {
            initializeLocationManager()
        }
        .onChange(of: clockedInStatus.isClockedIn) { _, _ in
            Task { await loadBuildingData() }
        }
        .sheet(item: $showTaskDetail) { task in
            taskDetailSheet(task)
        }
        .sheet(isPresented: $showAddTaskSheet) {
            addTaskSheet
        }
        .fullScreenCover(isPresented: $showClockInModal) {
            ClockInGlassModal(
                building: building,
                isAtLocation: isAtBuilding,
                isAdmin: isAdmin,
                clockedInStatus: clockedInStatus,
                onClockIn: handleClockIn,
                onClockOut: handleClockOut,
                onDismiss: { showClockInModal = false }
            )
        }
        .alert(isPresented: $showCompletionConfirmation) {
            Alert(
                title: Text("Confirm Task Completion"),
                message: Text("Are you sure you want to mark this task as complete?"),
                primaryButton: .default(Text("Complete")) {
                    if let task = taskForAction {
                        Task { await completeTaskWithoutVerification(task) }
                    }
                },
                secondaryButton: .cancel {
                    taskForAction = nil
                }
            )
        }
    }
    
    // MARK: - Background View
    
    private var buildingBackgroundView: some View {
        ZStack {
            // Base gradient background
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            // Building image background (blurred)
            if !building.imageAssetName.isEmpty,
               let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                    .clipped()
                    .blur(radius: 20)
                    .opacity(0.3)
                    .ignoresSafeArea()
            }
            
            // Overlay gradient for better readability
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.6),
                    Color.clear,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        GlassCard(intensity: .thin) {
            HStack(spacing: 0) {
                tabButton(title: "Tasks", icon: "checklist", tag: 0)
                tabButton(title: "Completed", icon: "checkmark.circle", tag: 1)
                tabButton(title: "Workers", icon: "person.2", tag: 2)
            }
            .padding(4)
        }
    }
    
    private func tabButton(title: String, icon: String, tag: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedTab == tag ? Color.white.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tab Content
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                pendingTasksContent
            case 1:
                completedTasksContent
            case 2:
                workersContent
            default:
                pendingTasksContent
            }
        }
    }
    
    // MARK: - Pending Tasks Content
    
    private var pendingTasksContent: some View {
        LazyVStack(spacing: 16) {
            // Emergency tasks (always expanded if present)
            if !emergencyTasks.isEmpty {
                TaskCategoryGlassCard(
                    title: "⚠️ Emergency & Urgent",
                    icon: "exclamationmark.triangle.fill",
                    tasks: emergencyTasks,
                    categoryColor: .red,
                    isExpanded: true,
                    onToggleExpand: {},
                    onTaskTap: { showTaskDetail = $0 },
                    onTaskComplete: handleTaskCompletion
                )
            }
            
            // Cleaning routine
            TaskCategoryGlassCard(
                title: "Cleaning Routine",
                icon: "spray.and.wipe",
                tasks: routineTasks,
                categoryColor: .blue,
                isExpanded: expandedCategories.contains("cleaning"),
                onToggleExpand: { toggleCategory("cleaning") },
                onTaskTap: { showTaskDetail = $0 },
                onTaskComplete: handleTaskCompletion
            )
            
            // Sanitation & Garbage
            TaskCategoryGlassCard(
                title: "Sanitation & Garbage",
                icon: "trash.fill",
                tasks: sanitationTasks,
                categoryColor: .green,
                isExpanded: expandedCategories.contains("sanitation"),
                onToggleExpand: { toggleCategory("sanitation") },
                onTaskTap: { showTaskDetail = $0 },
                onTaskComplete: handleTaskCompletion
            )
            
            // Inspections & Maintenance
            TaskCategoryGlassCard(
                title: "Inspections & Maintenance",
                icon: "wrench.and.screwdriver",
                tasks: inspectionTasks,
                categoryColor: .orange,
                isExpanded: expandedCategories.contains("inspection"),
                onToggleExpand: { toggleCategory("inspection") },
                onTaskTap: { showTaskDetail = $0 },
                onTaskComplete: handleTaskCompletion
            )
            
            // Weather-related tasks
            if !weatherTasks.isEmpty {
                TaskCategoryGlassCard(
                    title: "Weather-Related Tasks",
                    icon: "cloud.rain.fill",
                    tasks: weatherTasks,
                    categoryColor: .cyan,
                    isExpanded: expandedCategories.contains("weather"),
                    onToggleExpand: { toggleCategory("weather") },
                    onTaskTap: { showTaskDetail = $0 },
                    onTaskComplete: handleTaskCompletion
                )
            }
            
            // Add task button
            addTaskButton
        }
    }
    
    // MARK: - Completed Tasks Content
    
    private var completedTasksContent: some View {
        LazyVStack(spacing: 16) {
            let todayCompleted = getCompletedTasks(for: 0)
            let yesterdayCompleted = getCompletedTasks(for: 1)
            let weekCompleted = getCompletedTasks(for: 7)
            
            if !todayCompleted.isEmpty {
                completedTasksSection(title: "Today", tasks: todayCompleted)
            }
            
            if !yesterdayCompleted.isEmpty {
                completedTasksSection(title: "Yesterday", tasks: yesterdayCompleted)
            }
            
            if !weekCompleted.isEmpty {
                completedTasksSection(title: "This Week", tasks: weekCompleted)
            }
            
            if todayCompleted.isEmpty && yesterdayCompleted.isEmpty && weekCompleted.isEmpty {
                emptyCompletedTasksView
            }
        }
    }
    
    private func completedTasksSection(title: String, tasks: [FrancoSphere.MaintenanceTask]) -> some View {
        GlassCard(intensity: .thin) {
            VStack(alignment: .leading, spacing: 16) {
                // Section header
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(tasks.count) completed")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Completed tasks
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(5)) { task in
                        CompletedTaskGlassRow(
                            task: task,
                            onTap: { showTaskDetail = task }
                        )
                    }
                }
                
                if tasks.count > 5 {
                    Button("View all \(tasks.count) completed tasks") {
                        // Navigate to full completed tasks view
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
            }
            .padding(20)
        }
    }
    
    private var emptyCompletedTasksView: some View {
        GlassCard(intensity: .thin) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 40))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("No Completed Tasks")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Completed tasks will appear here once workers finish their assignments")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Workers Content
    
    private var workersContent: some View {
        VStack(spacing: 16) {
            WorkerAssignmentGlassCard(
                workers: getAssignedWorkers(),
                clockedInStatus: clockedInStatus,
                currentWorkerId: Int64(authManager.workerId) ?? 0,
                onWorkerTap: handleWorkerTap
            )
        }
    }
    
    // MARK: - Supporting Views
    
    private var addTaskButton: some View {
        Button(action: { showAddTaskSheet = true }) {
            GlassCard(intensity: .thin) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add New Task")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Create a custom task for this building")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var buildingActionsMenu: some View {
        Menu {
            if isClockedInCurrentBuilding {
                Button {
                    showClockInModal = true
                } label: {
                    Label("Clock Out", systemImage: "clock.badge.checkmark")
                }
            } else if canClockIn {
                Button {
                    showClockInModal = true
                } label: {
                    Label("Clock In", systemImage: "clock.badge")
                }
            }
            
            Button {
                showAddTaskSheet = true
            } label: {
                Label("Add Task", systemImage: "plus.circle")
            }
            
            Button("Building Settings") {
                // Navigate to building settings
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Sheet Views
    
    private func taskDetailSheet(_ task: FrancoSphere.MaintenanceTask) -> some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        GlassCard(intensity: .thin) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text(task.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                if !task.description.isEmpty {
                                    Text(task.description)
                                        .font(.body)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                
                                // Task metadata
                                VStack(alignment: .leading, spacing: 8) {
                                    taskMetadataRow(label: "Category", value: task.category.rawValue)
                                    taskMetadataRow(label: "Priority", value: task.urgency.rawValue)
                                    taskMetadataRow(label: "Recurrence", value: task.recurrence.rawValue)
                                    if let startTime = task.startTime {
                                        taskMetadataRow(label: "Scheduled", value: formatDateTime(startTime))
                                    }
                                }
                                
                                // Complete task button if not complete
                                if !task.isComplete {
                                    Button(action: {
                                        handleTaskCompletion(task)
                                        showTaskDetail = nil
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark")
                                            Text("Mark Complete")
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green.opacity(0.8))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(20)
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                showTaskDetail = nil
            })
        }
        .preferredColorScheme(.dark)
    }
    
    private func taskMetadataRow(label: String, value: String) -> some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    private var addTaskSheet: some View {
        NavigationView {
            ZStack {
                FrancoSphereColors.primaryBackground
                    .ignoresSafeArea()
                
                VStack {
                    GlassCard(intensity: .thin) {
                        VStack(spacing: 20) {
                            Text("Add New Task")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Task creation functionality would be implemented here with form inputs for task details, assignments, and scheduling.")
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                showAddTaskSheet = false
            })
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Data Management Methods
    
    private func initializeData() async {
        do {
            sqliteManager = try await SQLiteManager.start()
            await loadBuildingData()
            await checkClockInStatus()
        } catch {
            print("❌ Failed to initialize data: \(error)")
        }
    }
    
    private func initializeLocationManager() {
        if locationManager.locationStatus == .authorizedWhenInUse {
                     // you’re at the building (or have permission)
                     // …
                 }
    }
    
    private func loadBuildingData() async {
        // Fetch weather data
        await weatherAdapter.fetchWeatherForBuildingAsync(building)
        
        // Fetch all tasks
        let allTasks = await taskManager.fetchTasksAsync(forBuilding: building.id, includePastTasks: false)
        
        // Categorize tasks
        routineTasks = allTasks.filter { $0.category == .cleaning }
        sanitationTasks = allTasks.filter { $0.category == .sanitation }
        
        var tempInspections: [FrancoSphere.MaintenanceTask] = []
        for task in allTasks {
            if task.category == .inspection || task.category == .maintenance || task.category == .repair {
                tempInspections.append(task)
            }
        }
        inspectionTasks = tempInspections
        
        weatherTasks = createWeatherRelatedTasks()
        emergencyTasks = allTasks.filter { $0.urgency == .urgent }
        
        // Auto-expand today's tasks
        for task in getTodaysTasks() {
            expandedTasks.insert(task.id)
        }
    }
    
    private func checkClockInStatus() async {
        guard let sqlite = sqliteManager else { return }
        
        let querySQL = """
            SELECT buildingId FROM worker_time_logs
            WHERE workerId = ? AND clockOutTime IS NULL
            ORDER BY clockInTime DESC
            LIMIT 1
        """
        
        do {
            let workerIdInt64 = Int64(authManager.workerId) ?? 0
            let results = try await sqlite.query(querySQL, [workerIdInt64])
            if let row = results.first,
               let buildingId = row["buildingId"] as? Int64 {
                clockedInStatus = (true, buildingId)
            } else {
                clockedInStatus = (false, nil)
            }
        } catch {
            print("❌ Error checking clock-in status: \(error)")
            clockedInStatus = (false, nil)
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockAction() {
        showClockInModal = true
    }
    
    private func handleClockIn() {
        Task {
            guard let sqlite = sqliteManager else { return }
            
            do {
                let buildingIdInt64 = Int64(building.id) ?? 0
                let workerIdInt64 = Int64(authManager.workerId) ?? 0
                try await sqlite.logClockInAsync(
                    workerId: workerIdInt64,
                    buildingId: buildingIdInt64,
                    timestamp: Date()
                )
                clockedInStatus = (true, buildingIdInt64)
            } catch {
                print("❌ Error clocking in: \(error)")
            }
        }
    }
    
    private func handleClockOut() {
        Task {
            guard let sqlite = sqliteManager else { return }
            
            do {
                let workerIdInt64 = Int64(authManager.workerId) ?? 0
                try await sqlite.logClockOutAsync(
                    workerId: workerIdInt64,
                    timestamp: Date()
                )
                clockedInStatus = (false, nil)
            } catch {
                print("❌ Error clocking out: \(error)")
            }
        }
    }
    
    private func handleTaskCompletion(_ task: FrancoSphere.MaintenanceTask) {
        taskForAction = task
        
        // Check if task requires photo or checklist verification
        let needsPhoto = requiresPhotos(task)
        let needsChecklist = requiresChecklist(task)
        
        if needsPhoto || needsChecklist {
            // For now, show confirmation - in full implementation would show photo/checklist UI
            showCompletionConfirmation = true
        } else {
            showCompletionConfirmation = true
        }
    }
    
    private func completeTaskWithoutVerification(_ task: FrancoSphere.MaintenanceTask) async {
        await taskManager.toggleTaskCompletionAsync(
            taskID: task.id,
            completedBy: String(authManager.workerId)
        )
        await loadBuildingData()
        taskForAction = nil
    }
    
    private func handleWorkerTap(_ worker: FrancoWorkerAssignment) {
        // Implement worker detail view navigation
        print("Tapped worker: \(worker.workerName)")
    }
    
    private func toggleCategory(_ category: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedCategories.contains(category) {
                expandedCategories.remove(category)
            } else {
                expandedCategories.insert(category)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isAtBuilding: Bool {
        locationManager.isWithinRange(of: building.coordinate, radius: 100)
    }
    
    private var isAdmin: Bool {
        authManager.userRole == "admin"
    }
    
    private var canClockIn: Bool {
        !isClockedInCurrentBuilding && (isAtBuilding || isAdmin)
    }
    
    private var isClockedInCurrentBuilding: Bool {
        let buildingIdInt64 = Int64(building.id) ?? 0
        return clockedInStatus.isClockedIn && clockedInStatus.buildingId == buildingIdInt64
    }
    
    // MARK: - Data Calculation Methods
    
    private func getTotalPendingTasks() -> Int {
        var total = 0
        total += routineTasks.filter { !$0.isComplete }.count
        total += sanitationTasks.filter { !$0.isComplete }.count
        total += inspectionTasks.filter { !$0.isComplete }.count
        total += weatherTasks.filter { !$0.isComplete }.count
        total += emergencyTasks.filter { !$0.isComplete }.count
        return total
    }
    
    private func getTotalCompletedTasksToday() -> Int {
        // Mock implementation - replace with real completed tasks count
        return 8
    }
    
    private func getAssignedWorkersCount() -> Int {
        getAssignedWorkers().count
    }
    
    private func getAssignedWorkers() -> [FrancoWorkerAssignment] {
        // Mock implementation - replace with real data from BuildingRepository
        switch building.id {
        case "15": // Rubin Museum
            return [
                FrancoWorkerAssignment(
                    buildingId: "15",
                    workerId: 1,
                    workerName: "Greg Hutson",
                    shift: "Day",
                    specialRole: "Museum Specialist"
                ),
                FrancoWorkerAssignment(
                    buildingId: "15",
                    workerId: 2,
                    workerName: "Edwin Lema",
                    shift: "Day",
                    specialRole: nil
                )
            ]
        case "1": // 12 West 18th
            return [
                FrancoWorkerAssignment(
                    buildingId: "1",
                    workerId: 1,
                    workerName: "Greg Hutson",
                    shift: "Day",
                    specialRole: "Lead Maintenance"
                ),
                FrancoWorkerAssignment(
                    buildingId: "1",
                    workerId: 7,
                    workerName: "Angel Guirachocha",
                    shift: "Day",
                    specialRole: nil
                )
            ]
        default:
            return [
                FrancoWorkerAssignment(
                    buildingId: building.id,
                    workerId: 4,
                    workerName: "Kevin Dutan",
                    shift: "Day",
                    specialRole: nil
                )
            ]
        }
    }
    
    private func getCurrentWeatherRisk() -> BuildingStatsGlassCard.WeatherRiskLevel? {
        // Mock implementation - integrate with real weather data
        return .moderate
    }
    
    private func createWeatherCard() -> AnyView? {
        // Mock implementation - create weather glass card if needed
        return nil
    }
    
    private func createWeatherRelatedTasks() -> [FrancoSphere.MaintenanceTask] {
        // Mock implementation - create weather-based tasks
        return []
    }
    
    private func getTodaysTasks() -> [FrancoSphere.MaintenanceTask] {
        let cal = Calendar.current
        let all = routineTasks + sanitationTasks + inspectionTasks + weatherTasks + emergencyTasks
        return all.filter { cal.isDateInToday($0.dueDate) && !$0.isComplete }
    }
    
    private func getCompletedTasks(for daysAgo: Int) -> [FrancoSphere.MaintenanceTask] {
        // Mock implementation - replace with real completed tasks data
        if daysAgo == 0 {
            return [
                FrancoSphere.MaintenanceTask(
                    id: "completed-1",
                    name: "Lobby Glass Cleaning",
                    buildingID: building.id,
                    description: "Clean all glass surfaces in lobby",
                    dueDate: Date(),
                    category: .cleaning,
                    urgency: .low,
                    recurrence: .weekly,
                    isComplete: true,
                    assignedWorkers: ["2"],
                    completionInfo: FrancoSphere.TaskCompletionInfo(date: Date())
                )
            ]
        }
        return []
    }
    
    // MARK: - Helper Methods
    
    private func requiresPhotos(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        let nameLower = task.name.lowercased()
        if task.category == .sanitation { return true }
        return nameLower.contains("stairwell")
            || nameLower.contains("trash")
            || nameLower.contains("garbage")
            || nameLower.contains("boiler")
            || nameLower.contains("tank")
            || nameLower.contains("inspection")
            || task.urgency == .urgent
    }
    
    private func requiresChecklist(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        let nameLower = task.name.lowercased()
        if task.category == .inspection { return true }
        return nameLower.contains("glass")
            || nameLower.contains("elevator")
            || nameLower.contains("walkthrough")
            || nameLower.contains("inspection")
            || nameLower.contains("hvac")
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - CompletedTaskGlassRow

struct CompletedTaskGlassRow: View {
    let task: FrancoSphere.MaintenanceTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Completion indicator
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    if let completionInfo = task.completionInfo {
                        Text("Completed: \(formatCompletionDate(completionInfo.date))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Verification status
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Verified")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(8)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCompletionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Preview

struct BuildingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BuildingDetailView(
                building: FrancoSphere.NamedCoordinate(
                    id: "15",
                    name: "Rubin Museum (142-148 W 17th)",
                    latitude: 40.740370,
                    longitude: -73.998120,
                    address: "142-148 W 17th St, New York, NY",
                    imageAssetName: "Rubin_Museum_142_148_West_17th_Street"
                )
            )
        }
        .preferredColorScheme(.dark)
    }
}
