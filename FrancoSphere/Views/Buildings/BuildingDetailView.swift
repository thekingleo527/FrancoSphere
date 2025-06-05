//  BuildingDetailView.swift
//  FrancoSphere
//
//  Fixed version - removes duplicate declarations and fixes type errors

import SwiftUI
import MapKit
import CoreLocation
import Foundation

// MARK: - Helper Types

/// Simple checklist item
struct ChecklistItem: Identifiable {
    let id: String
    let text: String
    var isCompleted: Bool
}

// MARK: - View Extensions for Corner Radius

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Local Placeholder Components (renamed to avoid conflicts)

struct LocalTaskFormView: View {
    let buildingID: String
    var body: some View {
        Text("Task Form – Building \(buildingID)")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(white: 0.1))
            .foregroundColor(.white)
    }
}

struct LocalPhotoUploaderView: View {
    @Binding var image: UIImage?
    let onPhotoSelected: (UIImage) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Photo Uploader")
                .font(.headline)

            if let ui = image {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(12)
            }

            Button("Pick a Photo") {
                // In a real implementation, you'd present PHPicker or UIImagePickerController here.
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
    }
}

struct LocalWeatherDashboardComponent: View {
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
                Text("Weather Conditions")
                    .font(.headline)
                Spacer()
                Text("72°F")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text("Clear skies expected. Good conditions for outdoor maintenance tasks.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct LocalAIAvatarOverlayView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    // AI assistant action
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 60, height: 60)
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .shadow(radius: 4)
                .padding()
            }
        }
    }
}

// MARK: - Main View

struct BuildingDetailView: View {
    let building: FrancoSphere.NamedCoordinate

    // MARK: View state
    @State private var selectedTab = 0
    @State private var showClockInSheet = false
    @State private var showAddTaskSheet = false
    @State private var showTaskDetail: FrancoSphere.MaintenanceTask? = nil
    @State private var showCompletionConfirmation = false
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoUploader = false
    @State private var taskForAction: FrancoSphere.MaintenanceTask? = nil
    @State private var isExpanded: [String: Bool] = [:]
    @State private var showChecklist = false

    @State private var isSectionExpanded: [String: Bool] = [
        "cleaning": false,
        "sanitation": false,
        "inspection": false,
        "weather": true,
        "emergency": true
    ]

    // AI assistant state
    @State private var isAIMessageVisible = false
    @State private var currentAIMessage = ""
    @State private var checklistItems: [ChecklistItem] = []
    @State private var isChecklistComplete = false

    // SQLiteManager instance (actor)
    @State private var sqliteManager: SQLiteManager?

    // Reference existing managers - using correct NewAuthManager
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherAdapter = WeatherDataAdapter.shared
    
    // Use computed property for NewAuthManager access
    private var authManager: NewAuthManager { NewAuthManager.shared }

    private let taskManager = TaskManager.shared
    private let buildingRepository = BuildingRepository.shared

    // Tasks by category
    @State private var routineTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var sanitationTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var inspectionTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var weatherTasks: [FrancoSphere.MaintenanceTask] = []
    @State private var emergencyTasks: [FrancoSphere.MaintenanceTask] = []

    // Clock-in status - use Int64 for building ID to match database
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)

    var body: some View {
        ZStack {
            ScrollView {
                // 1) Building header with image, status, and basic info
                buildingHeaderSection

                // 2) Quick stats row
                quickStatsSection

                // 3) Weather card for this building
                LocalWeatherDashboardComponent(building: building)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // 4) Tab view for tasks / workers
                VStack(spacing: 16) {
                    Picker("View", selection: $selectedTab) {
                        Text("Pending Tasks").tag(0)
                        Text("Completed Tasks").tag(1)
                        Text("Workers").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 16)

                    if selectedTab == 0 {
                        taskListSection
                    } else if selectedTab == 1 {
                        completedTasksSection
                    } else {
                        workersSection
                        LocalAIAvatarOverlayView()
                    }
                }
                .padding(.top, 16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if isClockedInCurrentBuilding {
                        Button {
                            Task { await handleClockOut() }
                        } label: {
                            Label("Clock Out", systemImage: "clock.badge.checkmark")
                        }
                    } else if canClockIn {
                        Button { showClockInSheet = true } label: {
                            Label("Clock In", systemImage: "clock.badge")
                        }
                    }

                    Button { showAddTaskSheet = true } label: {
                        Label("Add Task", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            // Initialize SQLiteManager and load data once on appear
            do {
                sqliteManager = try await SQLiteManager.start()
                await loadBuildingData()
                await checkClockInStatus()
            } catch {
                print("❌ Failed to initialize SQLiteManager: \(error)")
            }
        }
        .onAppear {
            // Ensure location manager is initialized
            if locationManager.locationStatus == .unknown {
                locationManager.requestLocation()
            }
        }
        .onChange(of: clockedInStatus.isClockedIn) { _, _ in
            Task { await loadBuildingData() }
        }
        .sheet(isPresented: $showClockInSheet) {
            clockInView
        }
        .sheet(isPresented: $showAddTaskSheet) {
            LocalTaskFormView(buildingID: building.id)
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                VStack {
                    Text("Task Details")
                        .font(.title)
                        .padding()
                    Text(task.name)
                        .font(.headline)
                        .padding()
                    Text(task.description)
                        .padding()
                    Spacer()
                }
                .navigationTitle("Task")
            }
        }
        .sheet(isPresented: $showPhotoUploader) {
            if let task = taskForAction {
                LocalPhotoUploaderView(image: $selectedImage) { image in
                    Task { await completeTaskWithPhoto(task) }
                    taskForAction = nil
                }
            }
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

    // MARK: - Building Header Section

    private var buildingHeaderSection: some View {
        ZStack(alignment: .bottom) {
            // Building image or placeholder
            Group {
                if !building.imageAssetName.isEmpty,
                   let uiImage = UIImage(named: building.imageAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                        )
                }
            }

            // Overlay at bottom: name, address, status
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.title2).bold()
                            .foregroundColor(.white)

                        if let addr = building.address {
                            Text(addr)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    Spacer()

                    // Status badge
                    Text("Operational")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }

                HStack {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        Text(
                            "Lat: \(String(format: "%.4f", building.latitude)), " +
                            "Lon: \(String(format: "%.4f", building.longitude))"
                        )
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                    }
                    Spacer()

                    if isClockedInCurrentBuilding {
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Clocked In")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
        }
    }

    // MARK: - Quick Stats Section

    private var quickStatsSection: some View {
        HStack(spacing: 0) {
            statCard(
                count: getTotalPendingTasks(),
                label: "Pending Tasks",
                icon: "clock",
                color: .blue
            )

            statCard(
                count: getTotalCompletedTasks(),
                label: "Completed Tasks",
                icon: "checkmark.circle",
                color: .green
            )

            statCard(
                count: getAssignedWorkersCount(),
                label: "Workers",
                icon: "person.2",
                color: .orange
            )
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func statCard(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text("\(count)")
                .font(.title3).fontWeight(.bold)
            Text(label)
                .font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Task List Section (Pending)

    private var taskListSection: some View {
        VStack(spacing: 20) {
            groupTaskSection(
                title: "Cleaning Routine",
                icon: "spray.and.wipe",
                tasks: routineTasks,
                categoryIcon: "bubbles.and.sparkles"
            )

            groupTaskSection(
                title: "Sanitation & Garbage",
                icon: "trash",
                tasks: sanitationTasks,
                categoryIcon: "trash"
            )

            groupTaskSection(
                title: "Inspections & Maintenance",
                icon: "wrench.and.screwdriver",
                tasks: inspectionTasks,
                categoryIcon: "checklist"
            )

            if !weatherTasks.isEmpty {
                groupTaskSection(
                    title: "Weather-Related Tasks",
                    icon: "cloud.rain",
                    tasks: weatherTasks,
                    categoryIcon: "cloud"
                )
            }

            if !emergencyTasks.isEmpty {
                groupTaskSection(
                    title: "⚠️ Emergency & Admin Tasks",
                    icon: "exclamationmark.triangle",
                    tasks: emergencyTasks,
                    categoryIcon: "exclamationmark.triangle"
                )
            }

            Button(action: { showAddTaskSheet = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add New Task")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    private func groupTaskSection(
        title: String,
        icon: String,
        tasks: [FrancoSphere.MaintenanceTask],
        categoryIcon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(tasks.filter { !$0.isComplete }.count) pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)

            if tasks.filter({ !$0.isComplete }).isEmpty {
                Text("No pending tasks in this category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.filter { !$0.isComplete }) { task in
                        CustomTaskRow(
                            task: task,
                            isToday: isScheduledForToday(task),
                            isExpanded: isExpanded[task.id] ?? isScheduledForToday(task),
                            onToggleExpand: { toggleExpanded(task) },
                            onComplete: { handleTaskCompletion(task) },
                            onTap: { showTaskDetail = task }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Completed Tasks Section

    private var completedTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completed Tasks")
                .font(.headline)
                .padding(.horizontal, 16)

            if let today = getRecentlyCompletedTasks(days: 0), !today.isEmpty {
                completedTasksGroup(title: "Today", tasks: today)
            }
            if let yesterday = getRecentlyCompletedTasks(days: 1), !yesterday.isEmpty {
                completedTasksGroup(title: "Yesterday", tasks: yesterday)
            }
            if let week = getRecentlyCompletedTasks(days: 7), !week.isEmpty {
                completedTasksGroup(title: "This Week", tasks: week)
            }

            if getRecentlyCompletedTasks(days: 7)?.isEmpty ?? true {
                Text("No completed tasks in the last 7 days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }

    private func completedTasksGroup(title: String, tasks: [FrancoSphere.MaintenanceTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 16)
            ForEach(tasks) { task in
                CompletedTaskRow(task: task)
                    .onTapGesture {
                        showTaskDetail = task
                    }
            }
            Divider()
                .padding(.vertical, 8)
        }
    }

    // MARK: - Workers Section

    private var workersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workers Assigned to This Building")
                .font(.headline)
                .padding(.horizontal, 16)

            let assignedWorkers = getAssignedWorkers(for: building.id)
            if assignedWorkers.isEmpty {
                Text("No workers currently assigned to this building")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(assignedWorkers, id: \.workerId) { assignment in
                    workerRow(assignment)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func workerRow(_ assignment: FrancoWorkerAssignment) -> some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                Text(String(assignment.workerName.prefix(1)).uppercased())
                    .font(.title2).bold()
                    .foregroundColor(.blue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.workerName)
                    .font(.headline)
                if let shift = assignment.shift {
                    Text("Shift: \(shift)")
                        .font(.caption).foregroundColor(.secondary)
                }
                if let specialRole = assignment.specialRole {
                    Text("Role: \(specialRole)")
                        .font(.caption).foregroundColor(.secondary)
                }
            }
            Spacer()
            if isWorkerClockedIn(workerId: assignment.workerId) {
                Label("On Site", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            } else {
                Text("Off Site")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Clock In Sheet

    private var clockInView: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    if !building.imageAssetName.isEmpty,
                       let uiImage = UIImage(named: building.imageAssetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .frame(width: 120, height: 120)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }

                    Text(building.name)
                        .font(.title2).bold()
                    if let addr = building.address {
                        Text(addr)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()

                HStack {
                    Image(systemName: isAtBuilding ? "location.fill" : "location.slash.fill")
                        .foregroundColor(isAtBuilding ? .green : .red)
                        .font(.title2)
                    Text(isAtBuilding ? "You are at this location" : "You are not at this location")
                        .font(.callout)
                        .foregroundColor(isAtBuilding ? .green : .red)
                }
                .padding()
                .background(Color(isAtBuilding ? .green : .red).opacity(0.1))
                .cornerRadius(10)

                Spacer()

                Button(action: {
                    Task { await handleClockIn() }
                }) {
                    Text("CLOCK IN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((isAtBuilding || isAdmin) ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!(isAtBuilding || isAdmin))
                .padding(.horizontal, 16)

                if isAdmin && !isAtBuilding {
                    Text("Admin override: You can clock in remotely")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                }
            }
            .padding()
            .navigationTitle("Clock In")
            .navigationBarItems(trailing: Button("Cancel") {
                showClockInSheet = false
            })
        }
    }

    // MARK: - Async Helpers

    /// Loads weather & tasks for this building
    private func loadBuildingData() async {
        // 1) Fetch weather
        await weatherAdapter.fetchWeatherForBuildingAsync(building)

        // 2) Fetch all tasks from local/remote store
        let allTasks = await taskManager.fetchTasksAsync(forBuilding: building.id, includePastTasks: false)

        // 3) Split them by category
        routineTasks = allTasks.filter { $0.category == .cleaning }
        sanitationTasks = allTasks.filter { $0.category == .sanitation }

        var tempInspections: [FrancoSphere.MaintenanceTask] = []
        for t in allTasks {
            if t.category == .inspection ||
               t.category == .maintenance ||
               t.category == .repair {
                tempInspections.append(t)
            }
        }
        inspectionTasks = tempInspections

        // 4) Weather-related tasks
        weatherTasks = createWeatherRelatedTasks()

        // 5) Emergency tasks
        let urgentTasks = allTasks.filter { $0.urgency == .urgent }
        emergencyTasks = urgentTasks

        // 6) Expand today's tasks by default
        for task in getTodaysTasks() {
            isExpanded[task.id] = true
        }
    }

    private func createWeatherRelatedTasks() -> [FrancoSphere.MaintenanceTask] {
        // Return empty for now – or insert real logic
        return []
    }

    /// Checks the worker_time_logs table for an open clock-in
    private func checkClockInStatus() async {
        guard let sqlite = sqliteManager else { return }
        let querySQL = """
            SELECT buildingId FROM worker_time_logs
            WHERE workerId = ? AND clockOutTime IS NULL
            ORDER BY clockInTime DESC
            LIMIT 1
        """
        do {
            let results = try await sqlite.query(querySQL, parameters: [AuthManager.shared.workerId])
            if let row = results.first,
               let bid = row["buildingId"] as? Int64 {
                clockedInStatus = (true, bid)
            } else {
                clockedInStatus = (false, nil)
            }
        } catch {
            print("Error checking clock-in status: \(error)")
            clockedInStatus = (false, nil)
        }
    }

    // MARK: - Action Handlers

    private func handleClockIn() async {
        guard let sqlite = sqliteManager else { return }
        if isAtBuilding || isAdmin {
            let sql = """
                INSERT INTO worker_time_logs (workerId, buildingId, clockInTime)
                VALUES (?, ?, ?)
            """
            do {
                try await sqlite.execute(sql, parameters: [
                    authManager.workerId,
                    Int64(building.id) ?? 0,
                    Date()
                ])
                clockedInStatus = (true, Int64(building.id) ?? 0)
                showClockInSheet = false
            } catch {
                print("Error clocking in: \(error)")
            }
        }
    }

    private func handleClockOut() async {
        guard let sqlite = sqliteManager else { return }
        let sql = """
            UPDATE worker_time_logs
            SET clockOutTime = ?
            WHERE workerId = ? AND clockOutTime IS NULL
        """
        do {
            try await sqlite.execute(sql, parameters: [
                Date(),
                authManager.workerId
            ])
            clockedInStatus = (false, nil)
        } catch {
            print("Error clocking out: \(error)")
        }
    }

    private func handleTaskCompletion(_ task: FrancoSphere.MaintenanceTask) {
        taskForAction = task

        let needsPhoto = requiresPhotos(task)
        let needsChecklist = requiresChecklist(task)

        if needsPhoto && needsChecklist {
            showVerificationOptions(for: task)
        } else if needsPhoto {
            showPhotoUploader = true
        } else if needsChecklist {
            checklistItems = generateChecklistItems(for: task)
            isChecklistComplete = false
            showChecklist = true
        } else {
            showCompletionConfirmation = true
        }
    }

    private func completeTaskWithPhoto(_ task: FrancoSphere.MaintenanceTask) async {
        guard let selectedImage = self.selectedImage else { return }

        if let jpegData = selectedImage.jpegData(compressionQuality: 0.8) {
            let photoPath = "photos/\(task.id)/\(UUID().uuidString).jpg"
            print("Would save photo to: \(photoPath)")
            await completeTaskInDatabase(task, photoPath: photoPath)
            await loadBuildingData()
            taskForAction = nil
            self.selectedImage = nil
        }
    }

    private func completeTaskWithoutVerification(_ task: FrancoSphere.MaintenanceTask) async {
        await completeTaskInDatabase(task, photoPath: nil)
        await loadBuildingData()
        taskForAction = nil
    }

    private func completeTaskInDatabase(_ task: FrancoSphere.MaintenanceTask, photoPath: String?) async {
        // Toggle completion via TaskManager
        await taskManager.toggleTaskCompletionAsync(
            taskID: task.id,
            completedBy: String(authManager.workerId)
        )
    }

    private func toggleExpanded(_ task: FrancoSphere.MaintenanceTask) {
        isExpanded[task.id] = !(isExpanded[task.id] ?? false)
    }

    // MARK: - Computed Properties

    private var isAtBuilding: Bool {
        return locationManager.isWithinRange(
            of: building.coordinate,
            radius: 100
        )
    }

    private var isAdmin: Bool {
        authManager.userRole == "admin"
    }

    private var canClockIn: Bool {
        !isClockedInCurrentBuilding && (isAtBuilding || isAdmin)
    }

    private var isClockedInCurrentBuilding: Bool {
        clockedInStatus.isClockedIn &&
        clockedInStatus.buildingId == Int64(building.id)
    }

    // MARK: - Data Helper Methods

    private func getTotalPendingTasks() -> Int {
        var total = 0
        total += routineTasks.filter { !$0.isComplete }.count
        total += sanitationTasks.filter { !$0.isComplete }.count
        total += inspectionTasks.filter { !$0.isComplete }.count
        total += weatherTasks.filter { !$0.isComplete }.count
        total += emergencyTasks.filter { !$0.isComplete }.count
        return total
    }

    private func getTotalCompletedTasks() -> Int {
        // Placeholder: replace with real DB query if needed
        return 15
    }

    private func getAssignedWorkersCount() -> Int {
        getAssignedWorkers(for: building.id).count
    }

    private func getAssignedWorkers(for buildingId: String) -> [FrancoWorkerAssignment] {
        // Sample implementation – replace with real data
        switch buildingId {
        case "1":
            return [
                FrancoWorkerAssignment(buildingId: "1", workerId: 1, workerName: "Greg", shift: nil, specialRole: nil),
                FrancoWorkerAssignment(buildingId: "1", workerId: 7, workerName: "Angel", shift: nil, specialRole: nil)
            ]
        case "2":
            return [
                FrancoWorkerAssignment(buildingId: "2", workerId: 3, workerName: "Jose", shift: nil, specialRole: nil),
                FrancoWorkerAssignment(buildingId: "2", workerId: 2, workerName: "Edwin", shift: nil, specialRole: nil)
            ]
        default:
            return []
        }
    }

    private func isWorkerClockedIn(workerId: Int64) -> Bool {
        return clockedInStatus.isClockedIn &&
        clockedInStatus.buildingId == Int64(building.id) &&
        authManager.workerId == workerId
    }

    private func isScheduledForToday(_ task: FrancoSphere.MaintenanceTask) -> Bool {
        Calendar.current.isDateInToday(task.dueDate)
    }

    private func getTodaysTasks() -> [FrancoSphere.MaintenanceTask] {
        let cal = Calendar.current
        let all = routineTasks + sanitationTasks + inspectionTasks + weatherTasks + emergencyTasks
        return all.filter { cal.isDateInToday($0.dueDate) && !$0.isComplete }
    }

    private func getRecentlyCompletedTasks(days: Int) -> [FrancoSphere.MaintenanceTask]? {
        // Sample implementation – replace with real data
        if days == 0 {
            return [
                FrancoSphere.MaintenanceTask(
                    id: "100",
                    name: "Lobby Glass Cleaning",
                    buildingID: building.id,
                    description: "Clean all glass surfaces in the lobby",
                    dueDate: Date(),
                    category: .cleaning,
                    urgency: .low,
                    recurrence: .weekly,
                    isComplete: true,
                    assignedWorkers: ["2"]
                )
            ]
        } else if days == 1 {
            return [
                FrancoSphere.MaintenanceTask(
                    id: "101",
                    name: "Elevator Inspection",
                    buildingID: building.id,
                    description: "Monthly safety inspection of all elevators",
                    dueDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                    category: .inspection,
                    urgency: .medium,
                    recurrence: .monthly,
                    isComplete: true,
                    assignedWorkers: ["4"]
                )
            ]
        }
        return nil
    }

    // MARK: - Verification Methods

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

    private func showVerificationOptions(for task: FrancoSphere.MaintenanceTask) {
        // Implement your own UI here if needed
    }

    private func generateChecklistItems(for task: FrancoSphere.MaintenanceTask) -> [ChecklistItem] {
        return [
            ChecklistItem(id: "1", text: "Item 1", isCompleted: false),
            ChecklistItem(id: "2", text: "Item 2", isCompleted: false),
            ChecklistItem(id: "3", text: "Item 3", isCompleted: false)
        ]
    }
}

// MARK: - Custom Task Row View

struct CustomTaskRow: View {
    let task: FrancoSphere.MaintenanceTask
    let isToday: Bool
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onComplete: () -> Void
    let onTap: () -> Void

    @State private var isTapped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                onToggleExpand()
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(getCategoryColor().opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: getCategoryIcon())
                            .foregroundColor(getCategoryColor())
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        HStack {
                            if let startTime = task.startTime {
                                Text(formatTime(startTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text(task.recurrence.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(task.urgency.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(task.urgency.color.opacity(0.2))
                            .foregroundColor(task.urgency.color)
                            .cornerRadius(10)
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(12)
            .background(
                isTapped
                    ? Color(.systemGray4)
                    : (isToday ? Color(.systemGray6) : Color(.systemGray5))
            )
            .cornerRadius(12)
            .scaleEffect(isTapped ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isTapped)
            .onTapGesture {
                isTapped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isTapped = false
                    onTap()
                }
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Button {
                        onComplete()
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark")
                            Text("Mark Complete")
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(
                    RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight])
                )
            }
        }
        .opacity(isToday ? 1.0 : 0.8)
    }

    private func getCategoryIcon() -> String {
        switch task.category {
        case .cleaning:     return "bubbles.and.sparkles"
        case .maintenance:  return "wrench.and.screwdriver"
        case .repair:       return "hammer"
        case .sanitation:   return "trash"
        case .inspection:   return "checklist"
        }
    }

    private func getCategoryColor() -> Color {
        switch task.category {
        case .cleaning:     return .blue
        case .maintenance:  return .orange
        case .repair:       return .red
        case .sanitation:   return .green
        case .inspection:   return .purple
        }
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }
}

// MARK: - Completed Task Row

struct CompletedTaskRow: View {
    let task: FrancoSphere.MaintenanceTask

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.name).font(.headline)
                if let completionInfo = task.completionInfo {
                    Text("Completed: \(formatDate(completionInfo.date))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Verified")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .cornerRadius(10)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
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
    }
}
