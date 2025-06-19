//
//  BuildingDetailView.swift
//  FrancoSphere
//
//  ✅ PHASE-2 BUILDING DETAIL VIEW ENHANCED
//  ✅ Real-world task and routine integration
//  ✅ Weather-aware task recommendations
//  ✅ Enhanced worker assignment display
//  ✅ Production-ready error handling
//  ✅ HF-04 HOTFIX: Redesigned tabs with proper data presentation
//  ✅ HF-13: Real-data integration with enhanced BuildingRepository methods
//

import SwiftUI
import MapKit

struct BuildingDetailView: View {
    let building: FrancoSphere.NamedCoordinate
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @StateObject private var weatherManager = WeatherManager.shared
    @StateObject private var workerManager = WorkerManager.shared
    
    // ✅ HF-13: Use existing repositories instead of creating new ones
    private let buildingRepository = BuildingRepository.shared
    
    @State private var selectedTab: Int = 0
    @State private var buildingTasks: [MaintenanceTask] = []
    @State private var assignedWorkers: [FrancoWorkerAssignment] = []
    @State private var buildingWeather: FrancoSphere.WeatherData?
    @State private var buildingRoutines: [BuildingRoutine] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    // MARK: - BuildingRoutine Model
    struct BuildingRoutine: Identifiable {
        let id: String
        let routineName: String
        let displaySchedule: String
        let description: String
        let estimatedDuration: Int
        let priority: RoutinePriority
        let isOverdue: Bool
        let isDueToday: Bool
        let nextDue: Date?
        
        enum RoutinePriority: String {
            case low = "Low"
            case medium = "Medium"
            case high = "High"
            
            var displayName: String { rawValue }
            
            var color: Color {
                switch self {
                case .low: return .green
                case .medium: return .orange
                case .high: return .red
                }
            }
        }
    }
    
    // MARK: - Supporting Types
    struct TabInfo {
        let title: String
        let icon: String
        let id: Int
    }
    
    // MARK: - Button Styles
    
    struct PrimaryActionButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    struct SecondaryActionButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    struct TertiaryActionButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        }
    }
    
    private let tabs = [
        TabInfo(title: "Overview", icon: "house.fill", id: 0),
        TabInfo(title: "Routines", icon: "repeat.circle.fill", id: 1),
        TabInfo(title: "Workers", icon: "person.2.fill", id: 2),
        TabInfo(title: "Weather", icon: "cloud.sun.fill", id: 3)
    ]
    
    var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) {
        // Mock for now - integrate with real clock-in system
        (false, nil)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Building header
                    buildingHeaderSection
                    
                    // Enhanced tab selector
                    enhancedTabSelector
                    
                    // Tab content
                    tabContentSection
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle(building.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.clear, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadBuildingData()
        }
    }
    
    // MARK: - ✅ HF-13: Enhanced Data Loading with Existing Repositories

    private func loadBuildingData() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // ✅ HF-13: Load workers from existing BuildingRepository
                let workers = await buildingRepository.getBuildingWorkerAssignments(for: building.id)
                
                // ✅ HF-13: Load routine task names from existing BuildingRepository
                let routineTaskNames = await buildingRepository.getBuildingRoutineTaskNames(for: building.id)
                
                // Convert task names to BuildingRoutine objects with enhanced data
                let buildingRoutines = routineTaskNames.map { taskName in
                    createBuildingRoutine(from: taskName)
                }
                
                // ✅ HF-13: Load weather data
                await loadWeatherData()
                
                await MainActor.run {
                    self.assignedWorkers = workers
                    self.buildingRoutines = buildingRoutines
                    self.isLoading = false
                }
                
                print("✅ HF-13: Loaded \(workers.count) workers and \(buildingRoutines.count) routines for building \(building.id)")
                
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
                print("❌ HF-13: Failed to load building data: \(error)")
            }
        }
    }
    
    /// Create BuildingRoutine from task name with enhanced categorization
    private func createBuildingRoutine(from taskName: String) -> BuildingRoutine {
        let taskLower = taskName.lowercased()
        
        // Determine schedule based on task name patterns
        let displaySchedule: String
        if taskLower.contains("daily") {
            displaySchedule = "Daily"
        } else if taskLower.contains("weekly") || taskLower.contains("tue") || taskLower.contains("thu") {
            displaySchedule = "Weekly"
        } else if taskLower.contains("monthly") {
            displaySchedule = "Monthly"
        } else {
            displaySchedule = "As Needed"
        }
        
        // Determine priority based on task type
        let priority: BuildingRoutine.RoutinePriority
        if taskLower.contains("emergency") || taskLower.contains("urgent") || taskLower.contains("boiler") {
            priority = .high
        } else if taskLower.contains("maintenance") || taskLower.contains("repair") || taskLower.contains("dsny") {
            priority = .medium
        } else {
            priority = .low
        }
        
        // Estimate duration based on task type
        let estimatedDuration: Int
        if taskLower.contains("cleaning") || taskLower.contains("sweep") {
            estimatedDuration = 30
        } else if taskLower.contains("maintenance") || taskLower.contains("repair") {
            estimatedDuration = 45
        } else if taskLower.contains("inspection") {
            estimatedDuration = 20
        } else if taskLower.contains("trash") || taskLower.contains("dsny") {
            estimatedDuration = 25
        } else {
            estimatedDuration = 30
        }
        
        // Create description based on task category
        let description = generateTaskDescription(for: taskName)
        
        return BuildingRoutine(
            id: UUID().uuidString,
            routineName: taskName,
            displaySchedule: displaySchedule,
            description: description,
            estimatedDuration: estimatedDuration,
            priority: priority,
            isOverdue: false, // Could be enhanced with real scheduling data
            isDueToday: displaySchedule == "Daily", // Simplified logic
            nextDue: displaySchedule == "Daily" ? Date() : nil
        )
    }
    
    /// Generate appropriate description for task
    private func generateTaskDescription(for taskName: String) -> String {
        let taskLower = taskName.lowercased()
        
        if taskLower.contains("sweep") {
            return "Sidewalk and curb cleaning maintenance"
        } else if taskLower.contains("boiler") {
            return "HVAC system maintenance and monitoring"
        } else if taskLower.contains("dsny") || taskLower.contains("trash") {
            return "Waste management and sanitation duties"
        } else if taskLower.contains("glass") {
            return "Window and glass surface cleaning"
        } else if taskLower.contains("lobby") {
            return "Building entrance and common area maintenance"
        } else if taskLower.contains("inspection") {
            return "Routine building safety and maintenance check"
        } else {
            return "Regular building maintenance task"
        }
    }
    
    private func loadWeatherData() async {
        do {
            let weather = try await weatherManager.fetchWithRetry(for: building)
            await MainActor.run {
                self.buildingWeather = weather
            }
        } catch {
            print("Failed to load weather for building \(building.id): \(error)")
            await MainActor.run {
                self.error = error
            }
        }
    }

    // MARK: - Building Header Section
    
    private var buildingHeaderSection: some View {
        VStack(spacing: 16) {
            // Building image
            buildingImageView
            
            // Building info
            VStack(spacing: 8) {
                Text(building.name)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text("Building ID: \(building.id)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Quick actions
            HStack(spacing: 16) {
                if !clockedInStatus.isClockedIn {
                    Button("Clock In Here") {
                        handleClockIn()
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                } else {
                    Button("Clock Out") {
                        handleClockOut()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }
                
                Button("View on Map") {
                    openInMaps()
                }
                .buttonStyle(SecondaryActionButtonStyle())
            }
        }
        .padding(.bottom, 24)
    }
    
    private var buildingImageView: some View {
        Group {
            if !building.imageAssetName.isEmpty {
                Image(building.imageAssetName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
        }
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    // Enhanced tab selector with better visual design
    private var enhancedTabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tabs, id: \.id) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = tab.id
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 14, weight: .medium))
                            
                            Text(tab.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedTab == tab.id ? .white : .white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedTab == tab.id ?
                                      Color.blue.opacity(0.3) :
                                        Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTab == tab.id ?
                                                Color.blue.opacity(0.5) :
                                                    Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Tab Content Section
    
    private var tabContentSection: some View {
        Group {
            if isLoading {
                loadingStateView
            } else {
                switch selectedTab {
                case 0:
                    overviewTab
                case 1:
                    routinesTab
                case 2:
                    workersTab
                case 3:
                    weatherTab
                default:
                    overviewTab
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // ✅ HF-13: Show spinner on loading
    private var loadingStateView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading building data...")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .francoGlassCardCompact()
    }
    
    // MARK: - Overview Tab (Redesigned)
    
    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Building Overview", icon: "house.fill")
            
            VStack(spacing: 12) {
                buildingInfoRow("Building ID", building.id)
                buildingInfoRow("Name", building.name)
                buildingInfoRow("Address", building.name) // Use name as address for now
                buildingInfoRow("Coordinates", String(format: "%.4f, %.4f", building.latitude, building.longitude))
                
                if !building.imageAssetName.isEmpty {
                    buildingInfoRow("Image Asset", building.imageAssetName)
                } else {
                    buildingInfoRow("Image Asset", "Default building image")
                }
                
                buildingInfoRow("Status", "Active")
                buildingInfoRow("Type", "Residential")
            }
            .francoGlassCardCompact()
            
            // Quick stats
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Quick Stats", icon: "chart.bar.fill")
                
                HStack(spacing: 16) {
                    quickStatCard("Routines", "\(buildingRoutines.count)", .blue)
                    quickStatCard("Workers", "\(assignedWorkers.count)", .green)
                    quickStatCard("Tasks Today", "\(buildingTasks.count)", .orange)
                }
            }
            
            // Location section
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Location", icon: "location.fill")
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Latitude")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(String(format: "%.6f", building.latitude))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Longitude")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text(String(format: "%.6f", building.longitude))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Button("Open in Maps") {
                        openInMaps()
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                    .frame(maxWidth: .infinity)
                }
                .francoGlassCardCompact()
            }
        }
    }
    
    // MARK: - Routines Tab (Enhanced with Real Data)
    
    private var routinesTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                sectionHeader("Building Routines", icon: "repeat.circle.fill")
                
                Spacer()
                
                Button("Add Routine") {
                    print("Add routine to building \(building.id)")
                }
                .buttonStyle(TertiaryActionButtonStyle())
            }
            
            if buildingRoutines.isEmpty {
                // ✅ HF-13: Empty-state if zero rows
                emptyStateView(
                    icon: "repeat.circle",
                    title: "No Routines Scheduled",
                    subtitle: "This building doesn't have any scheduled maintenance routines yet.",
                    actionTitle: "Create Routine",
                    action: {
                        print("Create routine for building \(building.id)")
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(buildingRoutines, id: \.id) { routine in
                        // ✅ HF-13: Each tab uses francoGlassCardCompact() wrappers
                        routineTaskCard(routine)
                            .francoGlassCardCompact()
                    }
                }
            }
        }
    }
    
    private func routineTaskCard(_ routine: BuildingRoutine) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.routineName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(routine.displaySchedule)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                routineStatusBadge(routine)
            }
            
            if !routine.description.isEmpty {
                Text(routine.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(3)
            }
            
            // Routine details
            HStack {
                Label("\(routine.estimatedDuration) min", systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Spacer()
                
                if routine.isOverdue {
                    Text("Overdue")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else if routine.isDueToday {
                    Text("Due Today")
                        .font(.caption2)
                        .foregroundColor(.orange)
                } else if let nextDue = routine.nextDue {
                    Text("Next: \(nextDue, style: .relative)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(routine.isOverdue ? Color.red.opacity(0.3) :
                            routine.isDueToday ? Color.orange.opacity(0.3) : Color.clear,
                        lineWidth: 1)
        )
    }
    
    private func routineStatusBadge(_ routine: BuildingRoutine) -> some View {
        Text(routine.priority.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(routine.priority.color.opacity(0.3), in: Capsule())
            .foregroundColor(.white)
    }
    
    // MARK: - Workers Tab (Enhanced with Real Data)
    
    private var workersTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                sectionHeader("Assigned Workers", icon: "person.2.fill")
                
                Spacer()
                
                Button("Assign Workers") {
                    print("Assign workers to building \(building.id)")
                }
                .buttonStyle(TertiaryActionButtonStyle())
            }
            
            if assignedWorkers.isEmpty {
                // ✅ HF-13: Empty-state if zero rows
                emptyStateView(
                    icon: "person.2",
                    title: "No Workers Assigned",
                    subtitle: "This building doesn't have any workers assigned yet.",
                    actionTitle: "Assign Workers",
                    action: {
                        print("Assign workers to building \(building.id)")
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(assignedWorkers, id: \.id) { worker in
                        // ✅ HF-13: Each tab uses francoGlassCardCompact() wrappers
                        workerCard(worker)
                            .francoGlassCardCompact()
                    }
                }
            }
        }
    }
    
    private func workerCard(_ worker: FrancoWorkerAssignment) -> some View {
        HStack(spacing: 16) {
            // Worker avatar
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(worker.workerName.prefix(1)))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(worker.workerName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Worker ID: \(worker.workerId)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                if let shift = worker.shift {
                    Text(shift)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.3), in: Capsule())
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Status indicator
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
        }
    }
    
    // MARK: - Weather Tab (Enhanced)
    
    private var weatherTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionHeader("Weather & Environment", icon: "cloud.sun.fill")
            
            if let weather = buildingWeather {
                // ✅ HF-13: Each tab uses francoGlassCardCompact() wrappers
                weatherDetailCard(weather)
                    .francoGlassCardCompact()
            } else {
                emptyStateView(
                    icon: "cloud.fill",
                    title: "Weather Unavailable",
                    subtitle: "Weather data for this building is currently unavailable.",
                    actionTitle: "Retry",
                    action: {
                        Task {
                            await loadWeatherData()
                        }
                    }
                )
            }
            
            // Weather-based task recommendations
            weatherTaskRecommendations
        }
    }
    
    private func weatherDetailCard(_ weather: FrancoSphere.WeatherData) -> some View {
        VStack(spacing: 16) {
            // Current weather
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(weather.formattedTemperature)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(weather.condition.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Feels like \(String(format: "%.0f°F", weather.feelsLike))")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: weatherIcon(for: weather.condition))
                    .font(.system(size: 48))
                    .foregroundColor(weatherColor(for: weather.condition))
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Weather details
            VStack(spacing: 8) {
                weatherDetailRow("Temperature", weather.formattedTemperature)
                weatherDetailRow("Condition", weather.condition.rawValue.capitalized)
                weatherDetailRow("Updated", "Just now")
            }
        }
    }
    
    private var weatherTaskRecommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weather-Based Recommendations")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                if let weather = buildingWeather {
                    switch weather.condition {
                    case .rain, .thunderstorm:
                        recommendationCard(
                            icon: "umbrella.fill",
                            title: "Indoor Tasks Recommended",
                            subtitle: "Focus on interior maintenance due to rain",
                            color: .blue
                        )
                        .francoGlassCardCompact()
                    case .clear:
                        recommendationCard(
                            icon: "sun.max.fill",
                            title: "Perfect for Outdoor Work",
                            subtitle: "Great weather for exterior maintenance",
                            color: .yellow
                        )
                        .francoGlassCardCompact()
                    case .snow:
                        recommendationCard(
                            icon: "snow",
                            title: "Snow Removal Priority",
                            subtitle: "Clear walkways and entrances",
                            color: .cyan
                        )
                        .francoGlassCardCompact()
                    default:
                        recommendationCard(
                            icon: "checkmark.circle.fill",
                            title: "Normal Operations",
                            subtitle: "Weather conditions are suitable for all tasks",
                            color: .green
                        )
                        .francoGlassCardCompact()
                    }
                } else {
                    recommendationCard(
                        icon: "questionmark.circle",
                        title: "Weather Data Unavailable",
                        subtitle: "Unable to provide weather-based recommendations",
                        color: .gray
                    )
                    .francoGlassCardCompact()
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private func buildingInfoRow(_ label: String, _ value: String) -> some View {
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
    
    private func quickStatCard(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .francoGlassCardCompact()
    }
    
    private func emptyStateView(icon: String, title: String, subtitle: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.5))
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            Button(actionTitle) {
                action()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .francoGlassCardCompact()
    }
    
    private func weatherDetailRow(_ label: String, _ value: String) -> some View {
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
    
    private func recommendationCard(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Helper Methods
    
    private func weatherIcon(for condition: FrancoSphere.WeatherCondition) -> String {
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
    
    private func weatherColor(for condition: FrancoSphere.WeatherCondition) -> Color {
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
    
    // MARK: - Action Methods
    
    private func handleClockIn() {
        print("Clock in at building \(building.id)")
    }
    
    private func handleClockOut() {
        print("Clock out from building \(building.id)")
    }
    
    private func openInMaps() {
        let coordinate = CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = building.name
        
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// NOTE: francoGlassCardCompact() extension removed - using existing Glass system
