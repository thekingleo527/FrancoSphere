import SwiftUI
import MapKit
import CoreLocation

// MARK: - Helper Types

// Define the missing ChecklistItem type
struct ChecklistItem: Identifiable {
    let id: String
    let text: String
    var isCompleted: Bool
}

// MARK: - Helper View Extensions

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

struct BuildingDetailView: View {
    let building: NamedCoordinate
    
    // View state
    @State private var selectedTab = 0
    @State private var showClockInSheet = false
    @State private var showAddTaskSheet = false
    @State private var showTaskDetail: MaintenanceTask? = nil
    @State private var showCompletionConfirmation = false
    @State private var selectedImage: UIImage? = nil
    @State private var showPhotoUploader = false
    @State private var taskForAction: MaintenanceTask? = nil
    @State private var isExpanded: [String: Bool] = [:]
    @State private var showChecklist = false // Added missing state variable
    
    // New State Variables
    // Section expanded state
    @State private var isSectionExpanded: [String: Bool] = [
        "cleaning": false,      // Collapsed by default
        "sanitation": false,    // Collapsed by default
        "inspection": false,    // Collapsed by default
        "weather": true,        // Expanded by default
        "emergency": true       // Expanded by default for urgency
    ]
    
    // AI assistant state
    @State private var isAIMessageVisible = false
    @State private var currentAIMessage = ""
    @State private var checklistItems: [ChecklistItem] = []
    @State private var isChecklistComplete = false
    
    // Managers and services
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var locationManager = LocationManager()
    private let buildingStatusManager = BuildingStatusManager.shared // Changed from StateObject
    private let taskManager = TaskManager.shared
    private let buildingRepository = BuildingRepository.shared
    private let simpleTaskCompletionManager = SimpleTaskCompletionManager.shared
    private let taskCompletionManager = TaskCompletionManager.shared
    // Added weather service for dynamic task generation
    private let weatherService = WeatherService.shared
    private let aiAssistantManager = AIAssistantManager.shared
    // Task data
    @State private var routineTasks: [MaintenanceTask] = []
    @State private var sanitationTasks: [MaintenanceTask] = []
    @State private var inspectionTasks: [MaintenanceTask] = []
    @State private var weatherTasks: [MaintenanceTask] = []
    @State private var emergencyTasks: [MaintenanceTask] = []
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    
    var body: some View {
        ZStack {
            ScrollView {
                // Building header with image, status, and basic info
                buildingHeaderSection
                
                // Quick stats (pending tasks, completed tasks, workers)
                quickStatsSection
                
                // Weather forecast card
                WeatherDashboardComponent(building: building)
                    .padding(.horizontal)
                    .padding(.top, 16)
                
                // Task sections
                VStack(spacing: 16) {
                    // Tab selector for different views
                    Picker("View", selection: $selectedTab) {
                        Text("Pending Tasks").tag(0)
                        Text("Completed Tasks").tag(1)
                        Text("Workers").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Show different content based on selected tab
                    if selectedTab == 0 {
                        taskListSection
                    } else if selectedTab == 1 {
                        completedTasksSection
                    } else {
                        workersSection
                        AIAvatarOverlayView()
                                    .edgesIgnoringSafeArea(.all)                    }
                }
                .padding(.top, 16)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if isClockedInCurrentBuilding {
                        Button(action: { handleClockOut() }) {
                            Label("Clock Out", systemImage: "clock.badge.checkmark")
                        }
                    } else if canClockIn {
                        Button(action: { showClockInSheet = true }) {
                            Label("Clock In", systemImage: "clock.badge")
                        }
                    }
                    
                    Button(action: { showAddTaskSheet = true }) {
                        Label("Add Task", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadBuildingData()
            checkClockInStatus()
            
            // Initialize expanded state for today's tasks
            for task in getTodaysTasks() {
                isExpanded[task.id] = true
            }
            
            // Check for incomplete cleaning tasks to trigger AI assistant
            if hasIncompleteCleaningTasks() {
                // Uncomment when AIAvatarOverlayView is available
                // AIAvatarOverlayView.trigger(for: .routineIncomplete)
            }
        }
        .onChange(of: clockedInStatus.isClockedIn) { _, _ in
            loadBuildingData()
        }
        .sheet(isPresented: $showClockInSheet) {
            clockInView
        }
        .sheet(isPresented: $showAddTaskSheet) {
            TaskFormView(buildingID: building.id)
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                DashboardTaskDetailView(task: task)
            }
        }
        .sheet(isPresented: $showPhotoUploader) {
            if let task = taskForAction {
                // Use the existing PhotoUploaderView component
                PhotoUploaderView(image: $selectedImage, onPhotoSelected: { image in
                    // Using the image directly since it's non-optional
                    completeTaskWithPhoto(task)
                    taskForAction = nil
                })
            }
        }
        .alert(isPresented: $showCompletionConfirmation) {
            Alert(
                title: Text("Confirm Task Completion"),
                message: Text("Are you sure you want to mark this task as complete?"),
                primaryButton: .default(Text("Complete"), action: {
                    if let task = taskForAction {
                        completeTaskWithoutVerification(task)
                    }
                }),
                secondaryButton: .cancel {
                    taskForAction = nil
                }
            )
        }
    }
    
    // MARK: - Building Header Section
    
    private var buildingHeaderSection: some View {
        ZStack(alignment: .bottom) {
            // Building image
            Group {
                if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
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
            
            // Building info overlay
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("\(building.address ?? "")")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Building status badge
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
                    // Location coordinates
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Lat: \(String(format: "%.4f", building.latitude)), Long: \(String(format: "%.4f", building.longitude))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    // Check-in status
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
            .padding()
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
            // Pending tasks
            statCard(
                count: getTotalPendingTasks(),
                label: "Pending Tasks",
                icon: "clock",
                color: .blue
            )
            
            // Completed tasks
            statCard(
                count: getTotalCompletedTasks(),
                label: "Completed Tasks",
                icon: "checkmark.circle",
                color: .green
            )
            
            // Assigned workers
            statCard(
                count: getAssignedWorkersCount(),
                label: "Workers",
                icon: "person.2",
                color: .orange
            )
        }
        .padding(.top, 8)
    }
    
    private func statCard(count: Int, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
    
    // MARK: - Task List Section
    
    private var taskListSection: some View {
        VStack(spacing: 20) {
            // Routine cleaning tasks
            taskSectionView(
                title: "Cleaning Routine",
                icon: "spray.and.wipe",
                tasks: routineTasks,
                systemImage: "bubbles.and.sparkles"
            )
            
            // Sanitation/garbage tasks
            taskSectionView(
                title: "Sanitation & Garbage",
                icon: "trash",
                tasks: sanitationTasks,
                systemImage: "trash"
            )
            
            // Inspections & building maintenance (renamed from "Maintenance & Repairs")
            taskSectionView(
                title: "Inspections & Building Maintenance",
                icon: "wrench.and.screwdriver",
                tasks: inspectionTasks,
                systemImage: "checklist"
            )
            
            // Weather-related tasks
            if !weatherTasks.isEmpty {
                taskSectionView(
                    title: "Weather-Related Tasks",
                    icon: "cloud.rain",
                    tasks: weatherTasks,
                    systemImage: "cloud"
                )
            }
            
            // Emergency & admin tasks (optional section)
            if !emergencyTasks.isEmpty {
                taskSectionView(
                    title: "⚠️ Emergency & Admin Tasks",
                    icon: "exclamationmark.triangle",
                    tasks: emergencyTasks,
                    systemImage: "exclamationmark.triangle"
                )
            }
            
            // Add task button
            Button(action: {
                showAddTaskSheet = true
            }) {
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
    
    private func taskSectionView(title: String, icon: String, tasks: [MaintenanceTask], systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                // Task count
                Text("\(tasks.filter { !$0.isComplete }.count) pending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            if tasks.filter({ !$0.isComplete }).isEmpty {
                // Empty state
                Text("No pending tasks in this category")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                // List of tasks
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
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Completed Tasks Section
    
    private var completedTasksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Completed Tasks")
                .font(.headline)
                .padding(.horizontal)
            
            // Today's completed tasks
            if let todayCompleted = getRecentlyCompletedTasks(days: 0), !todayCompleted.isEmpty {
                completedTasksGroup(title: "Today", tasks: todayCompleted)
            }
            
            // Yesterday's completed tasks
            if let yesterdayCompleted = getRecentlyCompletedTasks(days: 1), !yesterdayCompleted.isEmpty {
                completedTasksGroup(title: "Yesterday", tasks: yesterdayCompleted)
            }
            
            // This week's completed tasks
            if let weekCompleted = getRecentlyCompletedTasks(days: 7), !weekCompleted.isEmpty {
                completedTasksGroup(title: "This Week", tasks: weekCompleted)
            }
            
            // Empty state
            if getRecentlyCompletedTasks(days: 7)?.isEmpty ?? true {
                Text("No completed tasks in the last 7 days")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    private func completedTasksGroup(title: String, tasks: [MaintenanceTask]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
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
                .padding(.horizontal)
            
            let assignedWorkers = buildingRepository.getAssignedWorkers(for: building.id)
            
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
                .padding(.horizontal)
            }
        }
    }
    
    private func workerRow(_ assignment: FrancoWorkerAssignment) -> some View {
        HStack {
            // Worker avatar/icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(String(assignment.workerName.prefix(1)).uppercased())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Worker info
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.workerName)
                    .font(.headline)
                
                if let shift = assignment.shift {
                    Text("Shift: \(shift)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let specialRole = assignment.specialRole {
                    Text("Role: \(specialRole)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Worker status - clock in indicator
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
    
    // MARK: - Clock In View
    
    private var clockInView: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Building info
                VStack(spacing: 12) {
                    // Building image or icon
                    if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
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
                        .font(.title2)
                        .bold()
                    
                    Text(building.address ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Location status
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
                
                // Clock in button
                Button(action: {
                    handleClockIn()
                }) {
                    Text("CLOCK IN")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isAtBuilding || isAdmin ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!(isAtBuilding || isAdmin))
                .padding(.horizontal)
                
                // Admin override notice
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
    
    // MARK: - Helper View Extensions
    
    struct CustomTaskRow: View {
        let task: MaintenanceTask
        let isToday: Bool
        let isExpanded: Bool
        let onToggleExpand: () -> Void
        let onComplete: () -> Void
        let onTap: () -> Void
        
        @State private var isTapped = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Task header (always visible)
                Button(action: {
                    // On small tap, toggle expanded state
                    onToggleExpand()
                }) {
                    HStack {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(getCategoryColor().opacity(0.2))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: getCategoryIcon())
                                .foregroundColor(getCategoryColor())
                        }
                        
                        // Task title and basic info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(task.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                // Time or recurrence info
                                if let startTime = task.startTime {
                                    Text(formatTime(startTime))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(task.recurrence.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Verification status indicators
                                if requiresBeforePhoto(task) {
                                    Image(systemName: hasBeforePhoto(task) ? "photo.fill" : "photo")
                                        .foregroundColor(hasBeforePhoto(task) ? .green : .yellow)
                                        .font(.caption)
                                }
                                
                                if requiresAfterPhoto(task) {
                                    Image(systemName: hasAfterPhoto(task) ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                                        .foregroundColor(hasAfterPhoto(task) ? .green : .yellow)
                                        .font(.caption)
                                }
                                
                                if requiresChecklist(task) {
                                    Image(systemName: hasCompletedChecklist(task) ? "checklist.checked" : "checklist")
                                        .foregroundColor(hasCompletedChecklist(task) ? .green : .yellow)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        // Urgency indicator and expander icon
                        VStack(alignment: .trailing, spacing: 2) {
                            // Urgency pill
                            Text(task.urgency.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(task.urgency.color.opacity(0.2))
                                .foregroundColor(task.urgency.color)
                                .cornerRadius(10)
                            
                            // Expand/collapse icon
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .padding(12)
                .background(isTapped ? Color(.systemGray4) : (isToday ? Color(.systemGray6) : Color(.systemGray5)))
                .cornerRadius(12)
                .scaleEffect(isTapped ? 0.98 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isTapped)
                .onTapGesture {
                    // Quick visual feedback
                    isTapped = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTapped = false
                        onTap()
                    }
                }
                
                // Expanded task details
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        // Task description
                        if !task.description.isEmpty {
                            Text(task.description)
                                .font(.callout)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        // Assigned workers
                        if !task.assignedWorkers.isEmpty {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                
                                Text("Assigned to: \(getAssignedWorkerNames(task))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Completion requirements
                        if requiresBeforePhoto(task) || requiresAfterPhoto(task) || requiresChecklist(task) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Completion Requirements:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 10) {
                                    if requiresBeforePhoto(task) {
                                        HStack {
                                            Image(systemName: hasBeforePhoto(task) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(hasBeforePhoto(task) ? .green : .gray)
                                            
                                            Text("Before Photo")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if requiresAfterPhoto(task) {
                                        HStack {
                                            Image(systemName: hasAfterPhoto(task) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(hasAfterPhoto(task) ? .green : .gray)
                                            
                                            Text("After Photo")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if requiresChecklist(task) {
                                        HStack {
                                            Image(systemName: hasCompletedChecklist(task) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(hasCompletedChecklist(task) ? .green : .gray)
                                            
                                            Text("Checklist")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Complete button
                        Button(action: {
                            onComplete()
                        }) {
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
                    .clipShape(RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight]))
                }
            }
            .opacity(isToday ? 1.0 : 0.8)
        }
        
        // Helper methods
        private func getCategoryIcon() -> String {
            switch task.category {
            case .cleaning: return "bubbles.and.sparkles"
            case .maintenance: return "wrench.and.screwdriver"
            case .repair: return "hammer"
            case .sanitation: return "trash"
            case .inspection: return "checklist"
            }
        }
        
        private func getCategoryColor() -> Color {
            switch task.category {
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
        
        private func getAssignedWorkerNames(_ task: MaintenanceTask) -> String {
            // In a real implementation, we would look up the names from IDs
            // This is a placeholder implementation
            return task.assignedWorkers.map { "Worker #\($0)" }.joined(separator: ", ")
        }
        
        // Verification helpers
        private func requiresBeforePhoto(_ task: MaintenanceTask) -> Bool {
            let taskName = task.name.lowercased()
            return taskName.contains("stairwell cleaning") ||
                   taskName.contains("trash room") ||
                   taskName.contains("garbage")
        }
        
        private func requiresAfterPhoto(_ task: MaintenanceTask) -> Bool {
            let taskName = task.name.lowercased()
            return taskName.contains("stairwell cleaning") ||
                   taskName.contains("trash room") ||
                   taskName.contains("garbage")
        }
        
        private func requiresChecklist(_ task: MaintenanceTask) -> Bool {
            let taskName = task.name.lowercased()
            return taskName.contains("glass") ||
                   taskName.contains("elevator") ||
                   taskName.contains("inspection")
        }
        
        private func hasBeforePhoto(_ task: MaintenanceTask) -> Bool {
            // This would check if the task has a before photo attached
            return false
        }
        
        private func hasAfterPhoto(_ task: MaintenanceTask) -> Bool {
            // This would check if the task has an after photo attached
            return false
        }
        
        private func hasCompletedChecklist(_ task: MaintenanceTask) -> Bool {
            // This would check if the task has a completed checklist
            return false
        }
    }
    
    // MARK: - Completed Task Row
    
    struct CompletedTaskRow: View {
        let task: MaintenanceTask
        
        var body: some View {
            HStack {
                // Task status indicator
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.name)
                        .font(.headline)
                    
                    if let completionInfo = task.completionInfo {
                        Text("Completed: \(formatDate(completionInfo.date))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Simplified status display without using verificationStatus directly
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
            .padding(.horizontal)
        }
        
        private func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadBuildingData() {
        // Comment out or replace with a correct method call
        // buildingStatusManager.updateStatus(forBuilding: building.id)
        
        // Here we would load all task data from the CSV or database
        // For now, using hardcoded tasks based on the master task tables
        
        // Cleaning routine tasks
        routineTasks = [
            MaintenanceTask(
                id: "1",
                name: "Lobby Floor Cleaning",
                buildingID: building.id,
                description: "Deep clean the lobby floor and entrance mats",
                dueDate: Date(),
                category: .cleaning,
                urgency: .medium,
                recurrence: .daily,
                assignedWorkers: ["1"]
            ),
            MaintenanceTask(
                id: "2",
                name: "Stairwell Cleaning",
                buildingID: building.id,
                description: "Sweep and mop all stairwells, front and back",
                dueDate: Date().addingTimeInterval(86400),
                category: .cleaning,
                urgency: .medium,
                recurrence: .weekly,
                assignedWorkers: ["1"]
            ),
            MaintenanceTask(
                id: "3",
                name: "Elevator Cleaning",
                buildingID: building.id,
                description: "Clean elevator floor, walls, and control panel",
                dueDate: Date(),
                category: .cleaning,
                urgency: .low,
                recurrence: .daily,
                assignedWorkers: ["2"]
            )
        ]
        
        // Sanitation tasks
        sanitationTasks = [
            MaintenanceTask(
                id: "4",
                name: "Trash Room Cleaning",
                buildingID: building.id,
                description: "Clean and sanitize trash room, replace bin liners",
                dueDate: Date(),
                category: .sanitation,
                urgency: .high,
                recurrence: .daily,
                assignedWorkers: ["3"]
            ),
            MaintenanceTask(
                id: "5",
                name: "Garbage Collection",
                buildingID: building.id,
                description: "Collect garbage from all floors and bring to main disposal",
                dueDate: Date(),
                category: .sanitation,
                urgency: .high,
                recurrence: .daily,
                assignedWorkers: ["3"]
            )
        ]
        
        // Inspection and maintenance tasks
        inspectionTasks = [
            MaintenanceTask(
                id: "6",
                name: "Boiler Blowdown",
                buildingID: building.id,
                description: "Perform routine boiler blowdown procedure",
                dueDate: Date().addingTimeInterval(172800),
                category: .maintenance,
                urgency: .high,
                recurrence: .weekly,
                assignedWorkers: ["4"]
            ),
            MaintenanceTask(
                id: "7",
                name: "Water Tank Inspection",
                buildingID: building.id,
                description: "Check water tank levels and condition",
                dueDate: Date().addingTimeInterval(86400),
                category: .inspection,
                urgency: .medium,
                recurrence: .weekly,
                assignedWorkers: ["4"]
            ),
            MaintenanceTask(
                id: "8",
                name: "Roof Drain Inspection",
                buildingID: building.id,
                description: "Inspect and clear all roof drains",
                dueDate: Date().addingTimeInterval(259200),
                category: .inspection,
                urgency: .medium,
                recurrence: .monthly,
                assignedWorkers: ["1"]
            ),
            MaintenanceTask(
                id: "9",
                name: "Utility Room Walkthrough",
                buildingID: building.id,
                description: "Perform visual inspection of all utility rooms",
                dueDate: Date(),
                category: .inspection,
                urgency: .low,
                recurrence: .weekly,
                assignedWorkers: ["2"]
            )
        ]
        
        // Weather tasks (would be dynamically generated based on forecast)
        weatherTasks = [
            MaintenanceTask(
                id: "10",
                name: "Clear Ice from Entrance",
                buildingID: building.id,
                description: "Apply salt and clear ice from building entrance",
                dueDate: Date(),
                category: .maintenance,
                urgency: .high,
                recurrence: .oneTime,
                assignedWorkers: ["1"]
            )
        ]
        
        // Emergency tasks
        emergencyTasks = [
            MaintenanceTask(
                id: "11",
                name: "Fix Leaking Pipe",
                buildingID: building.id,
                description: "Emergency repair needed for leaking pipe in basement",
                dueDate: Date(),
                category: .repair,
                urgency: .urgent,
                recurrence: .oneTime,
                assignedWorkers: ["4"]
            )
        ]
    }
    
    // New method to load all data using the weather service and task manager
    private func loadAllData() {
        // Get current date
        let today = Date()
        
        // Get all tasks for this building
        let allTasks = taskManager.getTasks(forBuilding: building.id)
        // Sort into categories - Fixed: Use explicit TaskCategory enum
        routineTasks = allTasks.filter { $0.category == TaskCategory.cleaning }
        sanitationTasks = allTasks.filter { $0.category == TaskCategory.sanitation }
        
        // Breaking up complex expression into smaller parts - FIXED LINE 1155
        inspectionTasks = allTasks.filter {
            $0.category == .inspection || $0.category == .maintenance || $0.category == .repair
        };do {
            // Fallback in case of type mismatch
            inspectionTasks = allTasks.filter {
                $0.category == TaskCategory.inspection ||
                $0.category == TaskCategory.maintenance ||
                $0.category == TaskCategory.repair
            }
        }
        
        // Get weather-related tasks
        weatherTasks = weatherService.generateWeatherTasks(for: building)
        
        // Get emergency tasks (urgent ones and weather emergencies)
        // Fixed: Use explicit TaskUrgency enum
        let urgentTasks = allTasks.filter { $0.urgency == TaskUrgency.urgent }
        
        if let weatherEmergency = weatherService.createWeatherEmergencyTask(for: building) {
            emergencyTasks = urgentTasks + [weatherEmergency]
        } else {
            emergencyTasks = urgentTasks
        }
    }
    
    private func checkClockInStatus() {
        // Get clock-in status from SQLite
        clockedInStatus = SQLiteManager.shared.isWorkerClockedIn(workerId: authManager.workerId)
    }
    
    // MARK: - Action Handlers
    
    private func handleClockIn() {
        if isAtBuilding || isAdmin {
            SQLiteManager.shared.logClockIn(
                workerId: authManager.workerId,
                buildingId: Int64(building.id) ?? 0,
                timestamp: Date()
            )
            
            // Update status after clock in
            clockedInStatus = (true, Int64(building.id))
            
            showClockInSheet = false
        }
    }
    
    private func handleClockOut() {
        SQLiteManager.shared.logClockOut(
            workerId: authManager.workerId,
            timestamp: Date()
        )
        clockedInStatus = (false, nil)
    }
    
    // Updated handleTaskCompletion with verification options
    private func handleTaskCompletion(_ task: MaintenanceTask) {
        taskForAction = task
        
        // Determine verification requirements
        let needsPhoto = requiresPhotos(task)
        let needsChecklist = requiresChecklist(task)
        
        if needsPhoto && needsChecklist {
            // Task requires both verifications - show options
            showVerificationOptions(for: task)
        } else if needsPhoto {
            // Task requires only photo verification
            showPhotoUploader = true
        } else if needsChecklist {
            // Task requires only checklist verification
            checklistItems = generateChecklistItems(for: task)
            isChecklistComplete = false
            showChecklist = true
        } else {
            // Simple confirmation for tasks without verification
            showCompletionConfirmation = true
        }
    }
    
    private func completeTaskWithPhoto(_ task: MaintenanceTask) {
        if let selectedImage = self.selectedImage {
            // Use _ to explicitly discard the result - FIXED WARNING
            _ = simpleTaskCompletionManager.completeTask(
                taskID: task.id,
                buildingID: building.id,
                workerID: String(authManager.workerId),
                image: selectedImage
            )
            
            // Refresh task lists
            loadAllData()
            
            taskForAction = nil
        }
    }
    
    private func completeTaskWithoutVerification(_ task: MaintenanceTask) {
        taskManager.toggleTaskCompletion(taskID: task.id)
        
        // Refresh task lists
        loadBuildingData()
        
        taskForAction = nil
    }
    
    private func toggleExpanded(_ task: MaintenanceTask) {
        isExpanded[task.id] = !(isExpanded[task.id] ?? false)
    }
    
    // MARK: - Helper Computed Properties
    
    private var isAtBuilding: Bool {
        // Check if the worker is within range of the building
        return locationManager.isWithinRange(
            of: building.coordinate,
            radius: 100 // 100 meters
        )
    }
    
    private var isAdmin: Bool {
        // Check if the current user is an admin
        return authManager.userRole == "admin"
    }
    
    private var canClockIn: Bool {
        // Check if the worker can clock in to this building
        return !isClockedInCurrentBuilding && (isAtBuilding || isAdmin)
    }
    
    private var isClockedInCurrentBuilding: Bool {
        // Check if the worker is already clocked in to this building
        return clockedInStatus.isClockedIn && clockedInStatus.buildingId == Int64(building.id)
    }
    
    // MARK: - Data Helper Methods
    
    private func getTotalPendingTasks() -> Int {
        // Breaking up complex expression to avoid compiler error
        let routineCount = routineTasks.filter({ !$0.isComplete }).count
        let sanitationCount = sanitationTasks.filter({ !$0.isComplete }).count
        let inspectionCount = inspectionTasks.filter({ !$0.isComplete }).count
        let weatherCount = weatherTasks.filter({ !$0.isComplete }).count
        let emergencyCount = emergencyTasks.filter({ !$0.isComplete }).count
        
        return routineCount + sanitationCount + inspectionCount + weatherCount + emergencyCount
    }
    
    private func getTotalCompletedTasks() -> Int {
        // In a real implementation, we would query the database
        // For now, return a placeholder value
        return 15
    }
    
    private func getAssignedWorkersCount() -> Int {
        return buildingRepository.getAssignedWorkers(for: building.id).count
    }
    
    private func isWorkerClockedIn(workerId: Int64) -> Bool {
        // Check if a worker is clocked in to this building
        let status = SQLiteManager.shared.isWorkerClockedIn(workerId: workerId)
        return status.isClockedIn && status.buildingId == Int64(building.id)
    }
    
    private func isScheduledForToday(_ task: MaintenanceTask) -> Bool {
        // Check if the task is scheduled for today
        let calendar = Calendar.current
        return calendar.isDateInToday(task.dueDate)
    }
    
    private func getTodaysTasks() -> [MaintenanceTask] {
        // Combine all tasks scheduled for today
        let calendar = Calendar.current
        
        let todayRoutine = routineTasks.filter { calendar.isDateInToday($0.dueDate) && !$0.isComplete }
        let todaySanitation = sanitationTasks.filter { calendar.isDateInToday($0.dueDate) && !$0.isComplete }
        let todayInspection = inspectionTasks.filter { calendar.isDateInToday($0.dueDate) && !$0.isComplete }
        let todayWeather = weatherTasks.filter { calendar.isDateInToday($0.dueDate) && !$0.isComplete }
        let todayEmergency = emergencyTasks.filter { calendar.isDateInToday($0.dueDate) && !$0.isComplete }
        
        return todayRoutine + todaySanitation + todayInspection + todayWeather + todayEmergency
    }
    
    private func getRecentlyCompletedTasks(days: Int) -> [MaintenanceTask]? {
        // In a real implementation, we would query the database
        // For now, return nil or a placeholder
        if days == 0 {
            // Today's completed tasks
            return [
                MaintenanceTask(
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
            // Yesterday's completed tasks
            return [
                MaintenanceTask(
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
        } else if days == 7 {
            // This week's completed tasks
            return [
                MaintenanceTask(
                    id: "102",
                    name: "Replace Hallway Light Fixtures",
                    buildingID: building.id,
                    description: "Replace burned out light fixtures in all hallways",
                    dueDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                    category: .maintenance,
                    urgency: .medium,
                    recurrence: .oneTime,
                    isComplete: true,
                    assignedWorkers: ["1"]
                )
            ]
        }
        
        return nil
    }
    
    private func hasIncompleteCleaningTasks() -> Bool {
        // Check if there are any incomplete cleaning tasks for triggering AI assistant
        let incompleteCleaningTasks = routineTasks.filter {
            !$0.isComplete &&
            $0.category == .cleaning &&
            Calendar.current.isDateInToday($0.dueDate)
        }
        
        return !incompleteCleaningTasks.isEmpty
    }
    
    // MARK: - Verification Methods (Updated)
    
    private func requiresPhotos(_ task: MaintenanceTask) -> Bool {
        let taskName = task.name.lowercased()
        let category = task.category
        
        // Tasks that always require photos based on category
        if category == .sanitation {
            return true // Sanitation tasks require photo proof
        }
        
        // Specific tasks requiring photos
        return taskName.contains("stairwell") ||
               taskName.contains("trash") ||
               taskName.contains("garbage") ||
               taskName.contains("boiler") ||
               taskName.contains("tank") ||
               taskName.contains("inspection") ||
               task.urgency == .urgent
    }
    
    private func requiresChecklist(_ task: MaintenanceTask) -> Bool {
        let taskName = task.name.lowercased()
        let category = task.category
        
        // Tasks that require checklists based on category
        if category == .inspection {
            return true // All inspection tasks require checklists
        }
        
        // Specific tasks requiring checklists
        return taskName.contains("glass") ||
               taskName.contains("elevator") ||
               taskName.contains("walkthrough") ||
               taskName.contains("inspection") ||
               taskName.contains("hvac")
    }
    
    // Placeholder implementations for showing verification options and generating checklist items
    private func showVerificationOptions(for task: MaintenanceTask) {
        // Implementation for showing verification options (e.g., present an action sheet)
    }
    
    private func generateChecklistItems(for task: MaintenanceTask) -> [ChecklistItem] {
        // Implementation for generating checklist items based on the task
        return [
            ChecklistItem(id: "1", text: "Item 1", isCompleted: false),
            ChecklistItem(id: "2", text: "Item 2", isCompleted: false),
            ChecklistItem(id: "3", text: "Item 3", isCompleted: false)
        ]
    }
}

// MARK: - Preview

struct BuildingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BuildingDetailView(
                building: NamedCoordinate(
                    id: "15",
                    name: "Rubin Museum (142-148 W 17th)",
                    latitude: 40.740370,
                    longitude: -73.998120,
                    address: "142-148 West 17th Street, New York, NY",
                    imageAssetName: "Rubin_Museum_142...8_West_17th_Street"
                )
            )
        }
    }
}
