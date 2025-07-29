//
//  BuildingDetailView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ ENHANCED: Preserves ALL existing functionality
//  ✅ ADDED: Coverage detection and intelligence panel integration
//  ✅ MAINTAINS: Real data integration, clock in/out, four-tab system
//

import SwiftUI
import MapKit

struct BuildingDetailView: View {
    let building: NamedCoordinate
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    // PRESERVED: All existing state variables
    @State private var selectedTab = 0
    @State private var isLoading = true
    @State private var showingClockIn = false
    @State private var clockInTime: Date?
    
    // PRESERVED: Real data integration with services
    @State private var buildingTasks: [ContextualTask] = []
    @State private var workersOnSite: [WorkerProfile] = []
    @State private var isCurrentlyClockedIn = false
    @State private var buildingMetrics: CoreTypes.BuildingMetrics?
    @State private var errorMessage: String?
    
    // PRESERVED: Services for real data
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    // NEW: Intelligence Panel Integration
    @State private var showIntelligencePanel = false
    @State private var selectedIntelligenceTab = BuildingIntelligencePanel.IntelligenceTab.overview
    
    // NEW: Coverage Detection
    private var isMyBuilding: Bool {
        contextAdapter.assignedBuildings.contains { $0.id == building.id }
    }
    
    private var isPrimaryBuilding: Bool {
        let primary = determinePrimaryBuilding(for: contextAdapter.currentWorker?.id ?? "")
        return primary?.id == building.id
    }
    
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
            .sheet(isPresented: $showIntelligencePanel) {
                // NEW: Intelligence Panel Integration
                BuildingIntelligencePanel(
                    building: building,
                    selectedTab: $selectedIntelligenceTab,
                    isMyBuilding: isMyBuilding,
                    isPrimaryBuilding: isPrimaryBuilding
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // PRESERVED: Existing loading view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Loading \(building.name)...")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
    
    // ENHANCED: Main content with coverage detection
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // ENHANCED: Building header with coverage indicator
                enhancedBuildingHeader
                
                // NEW: Coverage info card for non-assigned buildings
                if !isMyBuilding {
                    CoverageInfoCard(building: building) {
                        selectedIntelligenceTab = .overview
                        showIntelligencePanel = true
                    }
                }
                
                // PRESERVED: Existing tab section
                tabSection
                
                // PRESERVED: Existing content section
                contentSection
                
                // NEW: Intelligence access button
                intelligenceAccessButton
            }
            .padding()
        }
    }
    
    // ENHANCED: Building header with coverage indicator
    private var enhancedBuildingHeader: some View {
        VStack(spacing: 16) {
            // PRESERVED: Building image
            buildingImageView
            
            // NEW: Coverage indicator for non-assigned buildings
            if !isMyBuilding {
                coverageIndicator
            }
            
            // PRESERVED: Clock-in section (only for assigned buildings)
            if isMyBuilding {
                if isCurrentlyClockedIn {
                    clockedInStatus
                } else {
                    clockInButton
                }
            }
        }
    }
    
    // NEW: Coverage indicator
    private var coverageIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.orange)
            
            Text("Coverage Mode - Not Your Assigned Building")
                .font(.subheadline)
                .foregroundColor(.orange)
            
            Spacer()
        }
        .padding()
        .background(.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // PRESERVED: Building image view with ALL existing functionality
    private var buildingImageView: some View {
        ZStack {
            // Try to get image from imageAssetName or use fallback
            if let image = getBuildingImage() {
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
                    
                    // PRESERVED: Real task count and metrics
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
    
    // Helper function to get building image
    private func getBuildingImage() -> UIImage? {
        // Try imageAssetName first
        if let imageName = building.imageAssetName,
           !imageName.isEmpty,
           let image = UIImage(named: imageName) {
            return image
        }
        
        // Try standardized name based on building name
        let standardName = building.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
        
        if let image = UIImage(named: standardName) {
            return image
        }
        
        // No image found
        return nil
    }
    
    // PRESERVED: Clock in button with ALL existing functionality
    private var clockInButton: some View {
        Button {
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
    
    // PRESERVED: Clocked in status with ALL existing functionality
    private var clockedInStatus: some View {
        HStack(spacing: 12) {
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
    
    // PRESERVED: Tab section with ALL existing functionality
    private var tabSection: some View {
        HStack(spacing: 0) {
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
    
    // PRESERVED: Content section with ALL existing functionality
    private var contentSection: some View {
        Group {
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
    
    // PRESERVED: Overview tab with ALL existing functionality
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Building Overview")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // PRESERVED: Real building statistics
            VStack(spacing: 12) {
                statRow("Building ID", building.id)
                statRow("Total Tasks", "\(buildingTasks.count)")
                statRow("Completed", "\(buildingTasks.filter { $0.isCompleted }.count)")
                statRow("Overdue", "\(buildingTasks.filter { !$0.isCompleted && ($0.dueDate ?? Date.distantFuture) < Date() }.count)")
                statRow("Workers Assigned", "\(workersOnSite.count)")
                
                if let metrics = buildingMetrics {
                    statRow("Completion Rate", "\(Int(metrics.completionRate * 100))%")
                    statRow("Overall Score", String(format: "%.1f", metrics.overallScore))
                    statRow("Compliance", metrics.isCompliant ? "✅ Compliant" : "⚠️ Needs Attention")
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            // Show address if available
            if let address = building.address, !address.isEmpty {
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
    
    // PRESERVED: Tasks tab with ALL existing functionality
    private var tasksTab: some View {
        VStack(alignment: .leading, spacing: 16) {
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
    
    // PRESERVED: Workers tab with ALL existing functionality
    private var workersTab: some View {
        VStack(alignment: .leading, spacing: 16) {
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
    
    // PRESERVED: Analytics tab with ALL existing functionality
    private var analyticsTab: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    analyticsRow("Overall Score", String(format: "%.1f", metrics.overallScore), scoreColor(metrics.overallScore))
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
    
    // NEW: Intelligence access button
    private var intelligenceAccessButton: some View {
        Button(action: {
            selectedIntelligenceTab = .overview
            showIntelligencePanel = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Building Intelligence")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Complete building information and insights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.subheadline)
                    .foregroundColor(.purple)
            }
            .padding()
            .background(.purple.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.purple.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // PRESERVED: All existing card functions
    private func taskCard(_ task: ContextualTask) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
            
            // PRESERVED: Task metadata
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
    
    // PRESERVED: Worker card function
    private func workerCard(_ worker: WorkerProfile) -> some View {
        HStack(spacing: 12) {
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
    
    // PRESERVED: All existing helper functions
    private func statRow(_ label: String, _ value: String) -> some View {
        HStack {
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
        HStack {
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
    
    private func scoreColor(_ score: Double) -> Color {
        switch Int(score) {
        case 90...100: return .green
        case 70...89: return .blue
        case 50...69: return .orange
        default: return .red
        }
    }
    
    // PRESERVED: All existing actions
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
    
    // PRESERVED: All existing data loading methods
    private func loadBuildingData() async {
        isLoading = true
        errorMessage = nil
        
        // Load all data concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadBuildingTasks() }
            group.addTask { await self.loadBuildingWorkers() }
            group.addTask { await self.loadBuildingMetrics() }
        }
        
        print("✅ Building data loaded for \(building.name): \(buildingTasks.count) tasks, \(workersOnSite.count) workers")
        
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
    
    // NEW: Primary building detection helper
    private func determinePrimaryBuilding(for workerId: String) -> NamedCoordinate? {
        let buildings = contextAdapter.assignedBuildings
        
        switch workerId {
        case "4": // Kevin Dutan - Rubin Museum specialist
            return buildings.first { $0.name.contains("Rubin") }
        case "2": // Edwin Lema - Park operations
            return buildings.first { $0.name.contains("Stuyvesant") || $0.name.contains("Park") }
        case "5": // Mercedes Inamagua - Perry Street
            return buildings.first { $0.name.contains("131 Perry") }
        case "6": // Luis Lopez - Elizabeth Street
            return buildings.first { $0.name.contains("41 Elizabeth") }
        case "1": // Greg Salinas - 12 West 18th Street
            return buildings.first { $0.name.contains("12 West 18th") }
        case "7": // Angel Marin - Evening Operations
            return buildings.first { $0.name.contains("West 17th") }
        case "8": // Shawn Magloire - Portfolio Management
            return buildings.first // Portfolio manager can access all
        default:
            return buildings.first
        }
    }
}

// MARK: - Preview
struct BuildingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleBuilding = NamedCoordinate(
            id: "14",
            name: "Rubin Museum",
            latitude: 40.7402,
            longitude: -73.9980
        )
        
        BuildingDetailView(building: sampleBuilding)
    }
}
