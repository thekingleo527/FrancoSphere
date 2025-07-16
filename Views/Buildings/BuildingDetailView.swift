//
//  BuildingDetailView.swift
//  FrancoSphere
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ROBUST: Dynamic real-world data for any building selected
//  ✅ REAL DATA: Integrates with BuildingService, TaskService, WorkerService
//  ✅ COMPLETE: All required parameters and proper type handling
//

import SwiftUI
import MapKit

struct BuildingDetailView: View {
    let building: NamedCoordinate
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var showingClockIn = false
    @State private var clockInTime: Date?
    
    // Real data integration with services
    @State private var buildingTasks: [ContextualTask] = []
    @State private var workersOnSite: [WorkerProfile] = []
    @State private var isCurrentlyClockedIn = false
    @State private var buildingMetrics: CoreTypes.BuildingMetrics?
    @State private var errorMessage: String?
    
    // Services for real data
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .task {
                await loadBuildingData()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var loadingView: some View {
        return VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading \(building.name)...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    private var mainContent: some View {
        return ScrollView {
            VStack(spacing: 20) {
                buildingHeader
                tabSection
                contentSection
            }
            .padding()
        }
    }
    
    private var buildingHeader: some View {
        return VStack(spacing: 16) {
            // Building image
            buildingImageView
            
            // Clock-in section
            if isCurrentlyClockedIn {
                clockedInStatus
            } else {
                clockInButton
            }
        }
    }
    
    private var buildingImageView: some View {
        return ZStack {
            if let imageName = building.imageAssetName,
               let image = UIImage(named: imageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "building.2.fill")
                                .font(.largeTitle)
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text(building.name)
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    )
            }
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    
                    // Real task count and metrics
                    if buildingTasks.count > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(buildingTasks.count) tasks")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                            
                            if let metrics = buildingMetrics {
                                Text("\(Int(metrics.completionRate * 100))% complete")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.green.opacity(0.7), in: Capsule())
                            }
                        }
                    }
                }
                .padding(12)
                
                Spacer()
            }
        )
    }
    
    private var clockInButton: some View {
        return Button {
            handleClockIn()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clock In Here")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Start your shift at \(building.name)")
                        .font(.caption)
                        .opacity(0.8)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(16)
            .background(Color.blue.opacity(0.8))
            .cornerRadius(12)
        }
    }
    
    private var clockedInStatus: some View {
        return HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Clocked In")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                if let clockInTime = clockInTime {
                    Text("Since \(clockInTime, style: .time)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            Button("Clock Out") {
                handleClockOut()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red.opacity(0.8))
            .cornerRadius(8)
        }
        .foregroundColor(.white)
        .padding(16)
        .background(Color.green.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var tabSection: some View {
        return HStack(spacing: 0) {
            let tabs = ["Overview", "Tasks", "Workers", "Analytics"]
            
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(action: {
                    selectedTab = index
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(selectedTab == index ? .semibold : .regular)
                        .foregroundColor(selectedTab == index ? .blue : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var contentSection: some View {
        return Group {
            switch selectedTab {
            case 0:
                overviewTab
            case 1:
                tasksTab
            case 2:
                workersTab
            case 3:
                analyticsTab
            default:
                overviewTab
            }
        }
    }
    
    private var overviewTab: some View {
        return VStack(alignment: .leading, spacing: 16) {
            Text("Building Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Real building statistics
            VStack(spacing: 12) {
                statRow("Building ID", building.id)
                statRow("Total Tasks", "\(buildingTasks.count)")
                statRow("Completed", "\(buildingTasks.filter { $0.isCompleted }.count)")
                statRow("Overdue", "\(buildingTasks.filter { !$0.isCompleted && ($0.dueDate ?? Date.distantFuture) < Date() }.count)")
                statRow("Workers Assigned", "\(workersOnSite.count)")
                
                if let metrics = buildingMetrics {
                    statRow("Completion Rate", "\(Int(metrics.completionRate * 100))%")
                    statRow("Overall Score", "\(metrics.overallScore)")
                    statRow("Compliance", metrics.isCompliant ? "✅ Compliant" : "⚠️ Needs Attention")
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            if let address = building.address {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Address")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private var tasksTab: some View {
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tasks")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Refresh") {
                    Task { await loadBuildingTasks() }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if buildingTasks.isEmpty {
                Text("No tasks found for this building")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(buildingTasks, id: \.id) { task in
                        taskCard(task)
                    }
                }
            }
        }
    }
    
    private var workersTab: some View {
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Workers")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Refresh") {
                    Task { await loadBuildingWorkers() }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if workersOnSite.isEmpty {
                Text("No workers currently assigned to this building")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(workersOnSite, id: \.id) { worker in
                        workerCard(worker)
                    }
                }
            }
        }
    }
    
    private var analyticsTab: some View {
        return VStack(alignment: .leading, spacing: 16) {
            Text("Analytics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            if let metrics = buildingMetrics {
                VStack(spacing: 12) {
                    analyticsRow("Completion Rate", "\(Int(metrics.completionRate * 100))%", metrics.completionRate > 0.8 ? .green : .orange)
                    analyticsRow("Pending Tasks", "\(metrics.pendingTasks)", metrics.pendingTasks == 0 ? .green : .blue)
                    analyticsRow("Overdue Tasks", "\(metrics.overdueTasks)", metrics.overdueTasks == 0 ? .green : .red)
                    analyticsRow("Active Workers", "\(metrics.activeWorkers)", .blue)
                    analyticsRow("Urgent Tasks", "\(metrics.urgentTasksCount)", metrics.urgentTasksCount == 0 ? .green : .orange)
                    analyticsRow("Overall Score", "\(metrics.overallScore)", scoreColor(metrics.overallScore))
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                Text("Loading analytics...")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func taskCard(_ task: ContextualTask) -> some View {
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .white.opacity(0.7))
                
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let urgency = task.urgency {
                    Text(urgency.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(urgencyColor(urgency))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(urgencyColor(urgency).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Task metadata
            HStack(spacing: 12) {
                if let dueDate = task.dueDate {
                    Label {
                        Text(dueDate, style: .date)
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                if let category = task.category {
                    Label {
                        Text(category.rawValue)
                    } icon: {
                        Image(systemName: "tag")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func workerCard(_ worker: WorkerProfile) -> some View {
        return HStack(spacing: 12) {
            // Worker avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(worker.name.prefix(2).uppercased())
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                // ✅ FIXED: Remove optional chaining on non-optional UserRole
                Text(worker.role.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !worker.email.isEmpty {
                    Text(worker.email)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Worker status indicator
            Circle()
                .fill(worker.isActive ? .green : .gray)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
    
    private func statRow(_ label: String, _ value: String) -> some View {
        return HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    private func analyticsRow(_ label: String, _ value: String, _ color: Color) -> some View {
        return HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
    
    private func urgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical, .urgent, .emergency: return .red
        }
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 70...89: return .blue
        case 50...69: return .orange
        default: return .red
        }
    }
    
    // MARK: - Actions
    
    private func handleClockIn() {
        isCurrentlyClockedIn = true
        clockInTime = Date()
        
        // TODO: Integrate with actual clock-in system
        print("🕐 Clocked in at \(building.name)")
    }
    
    private func handleClockOut() {
        isCurrentlyClockedIn = false
        clockInTime = nil
        
        // TODO: Integrate with actual clock-out system
        print("🕐 Clocked out from \(building.name)")
    }
    
    // MARK: - Data Loading
    
    private func loadBuildingData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all building data concurrently
            async let tasks = loadBuildingTasks()
            async let workers = loadBuildingWorkers()
            async let metrics = loadBuildingMetrics()
            
            await tasks
            await workers
            await metrics
            
            print("✅ Building data loaded for \(building.name): \(buildingTasks.count) tasks, \(workersOnSite.count) workers")
            
        } catch {
            errorMessage = "Failed to load building data: \(error.localizedDescription)"
            print("❌ Failed to load building data: \(error)")
        }
        
        isLoading = false
    }
    
    private func loadBuildingTasks() async {
        do {
            // Get all tasks and filter for this building
            let allTasks = try await taskService.getAllTasks()
            
            buildingTasks = allTasks.filter { task in
                // Match by building ID or building object
                if let taskBuildingId = task.buildingId {
                    return taskBuildingId == building.id
                } else if let taskBuilding = task.building {
                    return taskBuilding.id == building.id
                }
                return false
            }
            
        } catch {
            print("❌ Failed to load building tasks: \(error)")
            buildingTasks = []
        }
    }
    
    private func loadBuildingWorkers() async {
        do {
            // Get workers assigned to this building
            workersOnSite = try await workerService.getActiveWorkersForBuilding(building.id)
            
        } catch {
            print("❌ Failed to load building workers: \(error)")
            workersOnSite = []
        }
    }
    
    private func loadBuildingMetrics() async {
        do {
            // Get real-time metrics for this building
            buildingMetrics = try await buildingMetricsService.calculateMetrics(for: building.id)
            
        } catch {
            print("❌ Failed to load building metrics: \(error)")
            buildingMetrics = nil
        }
    }
}
