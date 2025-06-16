//
//  BuildingDetailView.swift
//  FrancoSphere
//
//  🎯 FINAL VERSION - ALL COMPILATION ERRORS RESOLVED
//  ✅ FIXED: Removed duplicate EmptyTasksView declaration (uses shared component)
//  ✅ FIXED: Date to String conversion in TaskDetailRow (task.startTime is String, not Date)
//  ✅ Uses existing shared EmptyTasksView from TodaysTasksGlassCard
//  ✅ All ViewBuilder and type issues resolved
//

import SwiftUI
import MapKit
import CoreLocation

struct BuildingDetailView: View {
    // FIXED: Accept NamedCoordinate directly to match the rest of the codebase
    let building: FrancoSphere.NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State Management
    @State private var selectedTab = 0
    @State private var showClockInAlert = false
    @State private var showTaskDetail: MaintenanceTask? = nil
    
    // Data state
    @State private var buildingWeather: FrancoSphere.WeatherData?
    @State private var buildingTasks: [MaintenanceTask] = []
    @State private var assignedWorkers: [FrancoWorkerAssignment] = []
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var isLoading = true
    @State private var loadingError: String?
    
    // Managers
    @StateObject private var weatherManager = WeatherManager.shared
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                buildingBackgroundView
                
                contentView
            }
            .navigationTitle("Building Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadBuildingData()
        }
        .alert("Clock In", isPresented: $showClockInAlert) {
            Button("Clock In") {
                handleClockIn()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to clock in at \(building.name)?")
        }
        .sheet(item: $showTaskDetail) { task in
            TaskDetailSheet(task: task, showTaskDetail: $showTaskDetail)
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            LoadingView()
        } else if let error = loadingError {
            ErrorView(error: error) {
                Task { await loadBuildingData() }
            }
        } else {
            MainContentView(
                building: building,
                buildingWeather: buildingWeather,
                selectedTab: $selectedTab,
                buildingTasks: buildingTasks,
                assignedWorkers: assignedWorkers,
                clockedInStatus: clockedInStatus,
                onClockInTap: { showClockInAlert = true },
                onTaskTap: { task in showTaskDetail = task }
            )
        }
    }
    
    // MARK: - Background View
    
    private var buildingBackgroundView: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .gray.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // FIXED: Proper imageAssetName handling
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
            
            Color.black.opacity(0.4)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Data Loading
    
    private func loadBuildingData() async {
        await MainActor.run {
            isLoading = true
            loadingError = nil
        }
        
        await loadWeatherData()
        await loadTasksData()
        await loadWorkersData()
        await checkClockInStatus()
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func loadWeatherData() async {
        do {
            let weather = try await weatherManager.fetchWithRetry(for: building)
            await MainActor.run {
                self.buildingWeather = weather
            }
        } catch {
            print("⚠️ Could not load weather for building: \(error)")
        }
    }
    
    private func loadTasksData() async {
        await MainActor.run {
            self.buildingTasks = []
        }
        print("📋 Loaded \(buildingTasks.count) tasks for building \(building.name)")
    }
    
    private func loadWorkersData() async {
        let assignments = await BuildingRepository.shared.assignments(for: building.id)
        await MainActor.run {
            self.assignedWorkers = assignments
        }
        print("👥 Loaded \(assignedWorkers.count) workers for building \(building.name)")
    }
    
    private func checkClockInStatus() async {
        await MainActor.run {
            self.clockedInStatus = (false, nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleClockIn() {
        guard let buildingIdInt64 = Int64(building.id) else { return }
        clockedInStatus = (true, buildingIdInt64)
        print("🟢 Clocked in at \(building.name)")
    }
}

// MARK: - Supporting Views

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading building data...")
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to Load Data")
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Text(error)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry", action: onRetry)
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MainContentView: View {
    // FIXED: Use NamedCoordinate type
    let building: FrancoSphere.NamedCoordinate
    let buildingWeather: FrancoSphere.WeatherData?
    @Binding var selectedTab: Int
    let buildingTasks: [MaintenanceTask]
    let assignedWorkers: [FrancoWorkerAssignment]
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let onClockInTap: () -> Void
    let onTaskTap: (MaintenanceTask) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                BuildingHeaderSection(
                    building: building,
                    clockedInStatus: clockedInStatus,
                    onClockInTap: onClockInTap
                )
                
                if let weather = buildingWeather {
                    WeatherSection(weather: weather)
                }
                
                TabSelector(selectedTab: $selectedTab)
                
                TabContent(
                    selectedTab: selectedTab,
                    building: building,
                    buildingTasks: buildingTasks,
                    assignedWorkers: assignedWorkers,
                    onTaskTap: onTaskTap
                )
                
                Spacer(minLength: 100)
            }
            .padding()
        }
    }
}

struct BuildingHeaderSection: View {
    // FIXED: Use NamedCoordinate type
    let building: FrancoSphere.NamedCoordinate
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let onClockInTap: () -> Void
    
    private var isClockedInCurrentBuilding: Bool {
        guard let buildingIdInt64 = Int64(building.id) else { return false }
        return clockedInStatus.isClockedIn && clockedInStatus.buildingId == buildingIdInt64
    }
    
    var body: some View {
        VStack(spacing: 16) {
            BuildingImageView(building: building)
            
            VStack(spacing: 8) {
                Text(building.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Building ID: \(building.id)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Text("Coordinates: \(String(format: "%.6f", building.latitude)), \(String(format: "%.6f", building.longitude))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            ClockInButton(
                isClockedIn: isClockedInCurrentBuilding,
                onTap: onClockInTap
            )
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct BuildingImageView: View {
    // FIXED: Use NamedCoordinate type
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        Group {
            if !building.imageAssetName.isEmpty,
               let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(16)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No Image Available")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    )
            }
        }
    }
}

struct ClockInButton: View {
    let isClockedIn: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if isClockedIn {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Clocked In")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Text("Clock In at This Building")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                isClockedIn ? Color.green.opacity(0.2) : Color.blue,
                in: RoundedRectangle(cornerRadius: 12)
            )
        }
    }
}

struct WeatherSection: View {
    let weather: FrancoSphere.WeatherData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Weather")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                Image(systemName: weather.icon)
                    .font(.system(size: 40))
                    .foregroundColor(weatherIconColor(for: weather.condition))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.formattedTemperature)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text(weather.condition.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Feels like \(String(format: "%.0f°F", weather.feelsLike))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Humidity: \(weather.humidity)%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Wind: \(String(format: "%.1f", weather.windSpeed)) mph")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
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
}

struct TabSelector: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(title: "Tasks", icon: "checklist", tag: 0, selectedTab: $selectedTab)
            TabButton(title: "Info", icon: "info.circle", tag: 1, selectedTab: $selectedTab)
            TabButton(title: "Workers", icon: "person.2", tag: 2, selectedTab: $selectedTab)
            TabButton(title: "Map", icon: "map", tag: 3, selectedTab: $selectedTab)
        }
        .padding(4)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let tag: Int
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tag
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedTab == tag ? .white : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedTab == tag ? Color.white.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabContent: View {
    let selectedTab: Int
    // FIXED: Use NamedCoordinate type
    let building: FrancoSphere.NamedCoordinate
    let buildingTasks: [MaintenanceTask]
    let assignedWorkers: [FrancoWorkerAssignment]
    let onTaskTap: (MaintenanceTask) -> Void
    
    var body: some View {
        Group {
            switch selectedTab {
            case 0:
                TasksTab(buildingTasks: buildingTasks, onTaskTap: onTaskTap)
            case 1:
                InfoTab(building: building, buildingTasks: buildingTasks, assignedWorkers: assignedWorkers)
            case 2:
                WorkersTab(assignedWorkers: assignedWorkers)
            case 3:
                MapTab(building: building)
            default:
                TasksTab(buildingTasks: buildingTasks, onTaskTap: onTaskTap)
            }
        }
    }
}

struct TasksTab: View {
    let buildingTasks: [MaintenanceTask]
    let onTaskTap: (MaintenanceTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tasks for This Building")
                .font(.headline)
                .foregroundColor(.white)
            
            if buildingTasks.isEmpty {
                // ✅ FIXED: Use shared EmptyTasksView from TodaysTasksGlassCard instead of declaring our own
                EmptyTasksView()
            } else {
                ForEach(buildingTasks, id: \.id) { task in
                    TaskRow(task: task, onTap: { onTaskTap(task) })
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// ✅ REMOVED: Duplicate EmptyTasksView declaration - using shared component from TodaysTasksGlassCard

struct TaskRow: View {
    let task: MaintenanceTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(task.isComplete ? Color.green : urgencyColor(for: task.urgency))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.name)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                    
                    // FIXED: Proper time handling - startTime is String, not Date
                    if let taskStartTime = task.startTime {
                        Text("Scheduled: \(taskStartTime)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(task.category.rawValue.capitalized)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Text(task.isComplete ? "Complete" : task.urgency.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (task.isComplete ? Color.green : urgencyColor(for: task.urgency)).opacity(0.3),
                        in: Capsule()
                    )
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func urgencyColor(for urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .red
        }
    }
}

struct InfoTab: View {
    // FIXED: Use NamedCoordinate type
    let building: FrancoSphere.NamedCoordinate
    let buildingTasks: [MaintenanceTask]
    let assignedWorkers: [FrancoWorkerAssignment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Building Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                InfoRow(label: "Building ID", value: building.id)
                InfoRow(label: "Name", value: building.name)
                InfoRow(label: "Location", value: "Building coordinates available")
                InfoRow(label: "Coordinates", value: String(format: "%.6f, %.6f", building.latitude, building.longitude))
                InfoRow(label: "Image Asset", value: building.imageAssetName.isEmpty ? "Default" : building.imageAssetName)
                InfoRow(label: "Total Tasks", value: "\(buildingTasks.count)")
                InfoRow(label: "Completed Tasks", value: "\(buildingTasks.filter { $0.isComplete }.count)")
                InfoRow(label: "Assigned Workers", value: "\(assignedWorkers.count)")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct WorkersTab: View {
    let assignedWorkers: [FrancoWorkerAssignment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Assigned Workers")
                .font(.headline)
                .foregroundColor(.white)
            
            if assignedWorkers.isEmpty {
                EmptyWorkersView()
            } else {
                ForEach(assignedWorkers, id: \.id) { worker in
                    WorkerRow(worker: worker)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EmptyWorkersView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No Workers Assigned")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("Worker assignments will be loaded from your CSV data.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WorkerRow: View {
    let worker: FrancoWorkerAssignment
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(worker.workerName.prefix(1)))
                        .font(.headline)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.workerName)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Text("Worker ID: \(worker.workerId)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if let shift = worker.shift {
                    Text("Shift: \(shift)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MapTab: View {
    // FIXED: Use NamedCoordinate type
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.white)
            
            // FIXED: Simplified Map usage to avoid buildExpression issues
            if #available(iOS 17.0, *) {
                Map {
                    Marker(building.name, coordinate: CLLocationCoordinate2D(
                        latitude: building.latitude,
                        longitude: building.longitude
                    ))
                    .tint(.blue)
                }
                .mapStyle(.standard)
                .frame(height: 300)
                .cornerRadius(12)
            } else {
                // Fallback for iOS 16
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Map not available")
                                .foregroundColor(.gray)
                        }
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Location Details")
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                
                Text("Latitude: \(String(format: "%.6f", building.latitude))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text("Longitude: \(String(format: "%.6f", building.longitude))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct TaskDetailSheet: View {
    let task: MaintenanceTask
    @Binding var showTaskDetail: MaintenanceTask?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(task.name)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            if !task.description.isEmpty {
                                Text(task.description)
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        TaskMetadataSection(task: task)
                        
                        if !task.isComplete {
                            TaskCompletionButton {
                                showTaskDetail = nil
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
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
}

struct TaskMetadataSection: View {
    let task: MaintenanceTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TaskDetailRow(label: "Category", value: task.category.rawValue.capitalized)
            TaskDetailRow(label: "Priority", value: task.urgency.rawValue.capitalized)
            TaskDetailRow(label: "Recurrence", value: task.recurrence.rawValue.capitalized)
            TaskDetailRow(label: "Status", value: task.isComplete ? "Complete" : "Pending")
            
            // ✅ FIXED: task.startTime is String (HH:mm format), not Date
            if let taskStartTime = task.startTime {
                TaskDetailRow(label: "Scheduled Time", value: taskStartTime)
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            TaskDetailRow(label: "Due Date", value: dateFormatter.string(from: task.dueDate))
        }
    }
}

struct TaskDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.caption.weight(.medium))
                .foregroundColor(.white)
        }
    }
}

struct TaskCompletionButton: View {
    let onComplete: () -> Void
    
    var body: some View {
        Button("Mark as Complete", action: onComplete)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

struct BuildingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // FIXED: Use NamedCoordinate directly instead of conversion
        let realBuilding = FrancoSphere.NamedCoordinate(
            id: "1",
            name: "12 West 18th Street",
            latitude: 40.7390,
            longitude: -73.9930,
            imageAssetName: "12_West_18th_Street"
        )
        
        BuildingDetailView(building: realBuilding)
            .preferredColorScheme(.dark)
    }
}
