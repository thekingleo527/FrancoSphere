import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

// WorkerManager import added
import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

// UPDATED: Using centralized TypeRegistry for all types
//
//  WorkerRoutineViewModel.swift
//  FrancoSphere
//
//  ✅ ALL COMPILATION ERRORS FIXED
//  ✅ USES: Existing TaskService, WorkerManager, WorkerContextEngine, OperationalDataManager
//  ✅ USES: Existing Glass components (GlassCard, GlassTabBar, etc.)
//  ✅ MODERN: iOS 17+ compatible, proper async/await patterns
//  ✅ CORRECTED: All service dependencies updated to use actual existing services
//  ✅ REMOVED: All duplicate glass component declarations
//  Specialized view for worker routines - handles Kevin's assignments across buildings
//  Includes route optimization and schedule conflict detection
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import MapKit
// FrancoSphere Types Import
// (This comment helps identify our import)

import Foundation
// FrancoSphere Types Import
// (This comment helps identify our import)

import CoreLocation
// FrancoSphere Types Import
// (This comment helps identify our import)

import Combine
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Worker Routine View Model
@MainActor
class WorkerRoutineViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedWorker = "Kevin Dutan"
    @Published var workerSummary: WorkerRoutineSummary?
    @Published var routineTasks: [String: [MaintenanceTask]] = [:]
    @Published var dailyRoute: WorkerDailyRoute?
    @Published var routeOptimizations: [RouteOptimization] = []
    @Published var scheduleConflicts: [ScheduleConflict] = []
    @Published var isLoading = false
    @Published var selectedDate = Date()
    @Published var showingMapView = false
    @Published var errorMessage: String?
    @Published var dataHealthStatus: DataHealthStatus = .unknown
    
    // MARK: - Dependencies (Using Existing Services)
    private let taskService = TaskService.shared                 // ✅ EXISTS
    private let workerManager = WorkerService.shared             // ✅ EXISTS
    private let contextEngine = WorkerContextEngine.shared       // ✅ EXISTS
    private let operationalDataManager = OperationalDataManager.shared // ✅ EXISTS
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var buildingsWithTasks: [(building: NamedCoordinate, taskCount: Int)] {
        let allBuildings = NamedCoordinate.allBuildings
        var result: [(building: NamedCoordinate, taskCount: Int)] = []
        
        for building in allBuildings {
            let taskCount = routineTasks.values.flatMap { $0 }.filter { $0.buildingID == building.id }.count
            if taskCount > 0 {
                result.append((building: building, taskCount: taskCount))
            }
        }
        
        return result.sorted { $0.taskCount > $1.taskCount }
    }
    
    // MARK: - Initialization
    init() {
        setupReactiveBindings()
    }
    
    // MARK: - Reactive Data Binding
    private func setupReactiveBindings() {
        // React to date changes
        $selectedDate
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadWorkerData()
                }
            }
            .store(in: &cancellables)
        
        // React to worker changes
        $selectedWorker
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadWorkerData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Primary Data Loading
    func loadWorkerData() async {
        isLoading = true
        errorMessage = nil
        
        // Get worker ID
        guard let workerId = WorkerProfile.getWorkerId(byName: selectedWorker) else {
            await MainActor.run {
                errorMessage = "Worker not found: \(selectedWorker)"
                isLoading = false
            }
            return
        }
        
        // Load routine summary
        self.workerSummary = await generateWorkerSummary(workerId: workerId)
        
        // Load routine tasks grouped by building
        self.routineTasks = await loadRoutineTasksByBuilding(workerId: workerId)
        
        // Load daily route for selected date
        self.dailyRoute = await generateDailyRoute(workerId: workerId, date: selectedDate)
        
        // Get route optimizations
        if let route = dailyRoute {
            self.routeOptimizations = await generateRouteOptimizations(for: route)
        }
        
        // Load schedule conflicts
        await loadScheduleConflicts(workerId: workerId)
        
        // Kevin-specific validation
        if workerId == "4" {
            await validateKevinData()
        }
        
        await MainActor.run {
            dataHealthStatus = assessDataHealth()
            isLoading = false
        }
        
        print("✅ Worker routine data loaded: \(routineTasks.values.flatMap { $0 }.count) tasks, \(buildingsWithTasks.count) buildings")
    }
    
    // MARK: - Data Loading Helper Methods
    
    private func loadRoutineTasksByBuilding(workerId: String) async -> [String: [MaintenanceTask]] {
        // Use existing TaskService to get tasks
        do {
            let contextualTasks = try await taskService.getTasks(for: workerId, date: selectedDate)
            
            // Convert ContextualTask to MaintenanceTask and group by building
            var groupedTasks: [String: [MaintenanceTask]] = [:]
            
            for task in contextualTasks {
                let maintenanceTask = MaintenanceTask(
                    id: task.id,
                    name: task.name,
                    buildingID: task.buildingId,
                    description: task.category,
                    dueDate: selectedDate,
                    startTime: parseTimeString(task.startTime),
                    endTime: parseTimeString(task.endTime),
                    category: TaskCategory(rawValue: task.category) ?? .maintenance,
                    urgency: TaskUrgency.medium,
                    recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .daily,
                    isComplete: task.status == "completed",
                    assignedWorkers: [workerId],
                    requiredSkillLevel: task.skillLevel
                )
                
                if groupedTasks[task.buildingId] == nil {
                    groupedTasks[task.buildingId] = []
                }
                groupedTasks[task.buildingId]?.append(maintenanceTask)
            }
            
            return groupedTasks
        } catch {
            print("❌ Failed to load tasks: \(error)")
            return [:]
        }
    }
    
    private func generateWorkerSummary(workerId: String) async -> WorkerRoutineSummary? {
        // Get buildings from WorkerManager
        do {
            let buildings = try await workerManager.loadWorkerBuildings(workerId)
            let contextualTasks = try await taskService.getTasks(for: workerId, date: selectedDate)
            
            // Convert to MaintenanceTask for counting
            let maintenanceTasks = contextualTasks.map { task -> MaintenanceTask in
                MaintenanceTask(
                    id: task.id,
                    name: task.name,
                    buildingID: task.buildingId,
                    description: task.category,
                    dueDate: selectedDate,
                    startTime: parseTimeString(task.startTime),
                    endTime: parseTimeString(task.endTime),
                    category: TaskCategory(rawValue: task.category) ?? .maintenance,
                    urgency: TaskUrgency.medium,
                    recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .daily,
                    isComplete: task.status == "completed",
                    assignedWorkers: [workerId],
                    requiredSkillLevel: task.skillLevel
                )
            }
            
            // ✅ FIXED: Use correct enum syntax
            let dailyTasks = maintenanceTasks.filter { $0.recurrence == TaskRecurrence.daily }.count
            let weeklyTasks = maintenanceTasks.filter { $0.recurrence == TaskRecurrence.weekly }.count
            let monthlyTasks = maintenanceTasks.filter { $0.recurrence == TaskRecurrence.monthly }.count
            
            return WorkerRoutineSummary(
                id: UUID().uuidString,
                workerId: workerId,
                date: selectedDate,
                totalTasks: maintenanceTasks.count,
                completedTasks: maintenanceTasks.filter { $0.isComplete }.count,
                totalDistance: 0,
                estimatedDuration: Double(maintenanceTasks.count) * 1800,
                dailyTasks: dailyTasks,
                weeklyTasks: weeklyTasks,
                monthlyTasks: monthlyTasks,
                buildingCount: buildings.count,
                estimatedDailyHours: Double(maintenanceTasks.count) * 0.5,
                estimatedWeeklyHours: Double(maintenanceTasks.count) * 0.5 * 5
            )
        } catch {
            print("❌ Failed to generate worker summary: \(error)")
            return nil
        }
    }
    
    private func generateDailyRoute(workerId: String, date: Date) async -> WorkerDailyRoute? {
        do {
            // Get buildings and tasks
            let buildings = try await workerManager.loadWorkerBuildings(workerId)
            let contextualTasks = try await taskService.getTasks(for: workerId, date: date)
            
            // Convert to MaintenanceTask
            let maintenanceTasks = contextualTasks.map { task -> MaintenanceTask in
                MaintenanceTask(
                    id: task.id,
                    name: task.name,
                    buildingID: task.buildingId,
                    description: task.category,
                    dueDate: selectedDate,
                    startTime: parseTimeString(task.startTime),
                    endTime: parseTimeString(task.endTime),
                    category: TaskCategory(rawValue: task.category) ?? .maintenance,
                    urgency: TaskUrgency.medium,
                    recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .daily,
                    isComplete: task.status == "completed",
                    assignedWorkers: [workerId],
                    requiredSkillLevel: task.skillLevel
                )
            }
            
            // Create route stops
            let stops = createRouteStops(from: maintenanceTasks, buildings: buildings)
            
            if stops.isEmpty {
                return nil
            }
            
            // Calculate route metrics
            let (totalDistance, estimatedDuration) = calculateRouteMetrics(stops: stops)
            
            return WorkerDailyRoute(
                id: UUID().uuidString,
                workerId: workerId,
                date: date,
                stops: stops,
                totalDistance: totalDistance,
                estimatedDuration: estimatedDuration
            )
        } catch {
            print("❌ Failed to generate daily route: \(error)")
            return nil
        }
    }
    
    private func loadScheduleConflicts(workerId: String) async {
        // Get today's tasks
        do {
            let contextualTasks = try await taskService.getTasks(for: workerId, date: selectedDate)
            
            // Convert to MaintenanceTask for conflict detection
            let maintenanceTasks = contextualTasks.map { task -> MaintenanceTask in
                MaintenanceTask(
                    id: task.id,
                    name: task.name,
                    buildingID: task.buildingId,
                    description: task.category,
                    dueDate: selectedDate,
                    startTime: parseTimeString(task.startTime),
                    endTime: parseTimeString(task.endTime),
                    category: TaskCategory(rawValue: task.category) ?? .maintenance,
                    urgency: TaskUrgency.medium,
                    recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .daily,
                    isComplete: task.status == "completed",
                    assignedWorkers: [workerId],
                    requiredSkillLevel: task.skillLevel
                )
            }
            
            // Detect time conflicts
            var conflicts: [ScheduleConflict] = []
            
            for i in 0..<maintenanceTasks.count {
                for j in (i+1)..<maintenanceTasks.count {
                    let task1 = maintenanceTasks[i]
                    let task2 = maintenanceTasks[j]
                    
                    if hasTimeConflict(task1: task1, task2: task2) {
                        let conflict = ScheduleConflict(
                            type: .overlap,
                            description: "Time overlap between \(task1.name) and \(task2.name)",
                            severity: .medium,
                            suggestedResolution: "Adjust start time of \(task2.name) to \(suggestNewTime(for: task2, avoiding: task1))"
                        )
                        conflicts.append(conflict)
                    }
                }
            }
            
            await MainActor.run {
                self.scheduleConflicts = conflicts
            }
        } catch {
            print("❌ Failed to load schedule conflicts: \(error)")
            await MainActor.run {
                self.scheduleConflicts = []
            }
        }
    }
    
    private func generateRouteOptimizations(for route: WorkerDailyRoute) async -> [RouteOptimization] {
        var optimizations: [RouteOptimization] = []
        
        // Check for geographic inefficiencies
        if let geographicOpt = analyzeGeographicEfficiency(route: route) {
            optimizations.append(geographicOpt)
        }
        
        // Check for time-based optimizations
        if let timeOpt = analyzeTimeEfficiency(route: route) {
            optimizations.append(timeOpt)
        }
        
        // Check for skill-based groupings
        if let skillOpt = analyzeSkillGrouping(route: route) {
            optimizations.append(skillOpt)
        }
        
        return optimizations
    }
    
    // MARK: - Kevin-Specific Data Validation
    private func validateKevinData() async {
        // Kevin should have 6+ buildings including Rubin Museum
        if buildingsWithTasks.count < 6 {
            print("⚠️ Kevin has only \(buildingsWithTasks.count) buildings, checking assignments...")
            
            // Check if Rubin Museum is correctly assigned
            let hasRubin = buildingsWithTasks.contains { $0.building.id == "14" && $0.building.name.contains("Rubin") }
            let hasFranklin = buildingsWithTasks.contains { $0.building.id == "13" }
            
            if hasFranklin && !hasRubin {
                await MainActor.run {
                    errorMessage = "CRITICAL: Kevin has Franklin instead of Rubin Museum!"
                    dataHealthStatus = .critical(["Kevin missing Rubin Museum assignment"])
                }
            }
        }
        
        // Kevin should have 20+ tasks
        let totalTasks = routineTasks.values.flatMap { $0 }.count
        if totalTasks < 20 {
            print("⚠️ Kevin has only \(totalTasks) tasks, this seems low")
            await MainActor.run {
                if dataHealthStatus == .unknown {
                    dataHealthStatus = .warning(["Kevin has fewer tasks than expected"])
                }
            }
        }
        
        // Validate Rubin Museum task exists
        let hasRubinTask = routineTasks.values.flatMap { $0 }.contains { $0.buildingID == "14" }
        if !hasRubinTask {
            print("⚠️ Kevin missing Rubin Museum task")
            await MainActor.run {
                if case .unknown = dataHealthStatus {
                    dataHealthStatus = .warning(["Kevin missing Rubin Museum task"])
                }
            }
        }
    }
    
    // MARK: - Data Health Assessment
    private func assessDataHealth() -> DataHealthStatus {
        var issues: [String] = []
        
        if buildingsWithTasks.isEmpty {
            issues.append("No buildings with tasks")
        }
        
        if routineTasks.isEmpty {
            issues.append("No routine tasks loaded")
        }
        
        if dailyRoute == nil && !routineTasks.isEmpty {
            issues.append("No daily route available")
        }
        
        // Kevin-specific health checks
        if selectedWorker == "Kevin Dutan" {
            if buildingsWithTasks.count < 6 {
                issues.append("Kevin: Insufficient building assignments")
            }
            
            let hasRubin = buildingsWithTasks.contains { $0.building.id == "14" }
            if !hasRubin {
                issues.append("Kevin: Missing Rubin Museum assignment")
            }
        }
        
        if issues.isEmpty {
            return .healthy
        } else if issues.count <= 2 {
            return .warning(issues)
        } else {
            return .critical(issues)
        }
    }
    
    // MARK: - User Actions
    
    func tasksForBuilding(_ buildingId: String) -> [MaintenanceTask] {
        return routineTasks.values.flatMap { $0 }.filter { $0.buildingID == buildingId }
    }
    
    func optimizeRoute() async {
        guard let workerId = WorkerProfile.getWorkerId(byName: selectedWorker) else { return }
        
        // Regenerate route
        self.dailyRoute = await generateDailyRoute(workerId: workerId, date: selectedDate)
        
        if let route = dailyRoute {
            self.routeOptimizations = await generateRouteOptimizations(for: route)
        }
    }
    
    func refreshData() async {
        await MainActor.run {
            routineTasks = [:]
            dailyRoute = nil
            routeOptimizations = []
            scheduleConflicts = []
        }
        
        await loadWorkerData()
    }
    
    func completeTask(_ task: MaintenanceTask) async {
        guard let workerId = WorkerProfile.getWorkerId(byName: selectedWorker) else { return }
        
        // Use TaskService completion method - simplified approach
        do {
            // Create a basic ContextualTask from MaintenanceTask for completion
            let contextualTask = ContextualTask(
                id: task.id,
                name: task.name,
                buildingId: task.buildingID,
                buildingName: getBuildingName(task.buildingID),
                category: task.category.rawValue,
                startTime: formatTime(task.startTime),
                endTime: formatTime(task.endTime),
                recurrence: task.recurrence.rawValue,
                skillLevel: task.requiredSkillLevel,
                status: "completed",
                urgencyLevel: task.urgency.rawValue,
                assignedWorkerName: selectedWorker
            )
            
            // For now, just update the local state
            await MainActor.run {
                updateTaskStatus(taskId: task.id, isComplete: true)
            }
            
            print("✅ Task completed: \(task.name)")
        } catch {
            print("❌ Failed to complete task: \(error)")
        }
    }
    
    private func getBuildingName(_ buildingId: String) -> String {
        let building = NamedCoordinate.allBuildings.first { $0.id == buildingId }
        return building?.name ?? "Building \(buildingId)"
    }
    
    private func formatTime(_ date: Date?) -> String? {
        guard let date = date else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Helper Methods
    
    private func parseTimeString(_ timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            // Combine with selected date
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            
            return calendar.date(from: components)
        }
        
        return nil
    }
    
    private func updateTaskStatus(taskId: String, isComplete: Bool) {
        for (buildingId, tasks) in routineTasks {
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                var updatedTask = routineTasks[buildingId]![index]
                updatedTask.isComplete = isComplete
                routineTasks[buildingId]![index] = updatedTask
                break
            }
        }
    }
    
    private func createRouteStops(from tasks: [MaintenanceTask], buildings: [NamedCoordinate]) -> [RouteStop] {
        let buildingDict = Dictionary(uniqueKeysWithValues: buildings.map { ($0.id, $0) })
        let tasksByBuilding = Dictionary(grouping: tasks) { $0.buildingID }
        
        var stops: [RouteStop] = []
        
        for (buildingId, buildingTasks) in tasksByBuilding {
            guard let building = buildingDict[buildingId] else { continue }
            
            let arrivalTime = calculateArrivalTime(for: buildingTasks)
            let taskDuration = calculateTaskDuration(for: buildingTasks)
            
            let stop = RouteStop(
                buildingId: buildingId,
                buildingName: building.name,
                coordinate: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude),
                tasks: buildingTasks,
                estimatedDuration: taskDuration,
                estimatedTaskDuration: taskDuration,
                arrivalTime: arrivalTime,
                departureTime: nil
            )
            
            stops.append(stop)
        }
        
        return stops.sorted { $0.arrivalTime < $1.arrivalTime }
    }
    
    private func calculateRouteMetrics(stops: [RouteStop]) -> (distance: Double, duration: TimeInterval) {
        var totalDistance: Double = 0
        var totalDuration: TimeInterval = 0
        
        for i in 0..<stops.count {
            // Add task duration
            totalDuration += stops[i].estimatedTaskDuration
            
            // Add travel time to next stop
            if i < stops.count - 1 {
                let currentLocation = CLLocation(
                    latitude: stops[i].coordinate.latitude,
                    longitude: stops[i].coordinate.longitude
                )
                let nextLocation = CLLocation(
                    latitude: stops[i + 1].coordinate.latitude,
                    longitude: stops[i + 1].coordinate.longitude
                )
                
                let distance = currentLocation.distance(from: nextLocation)
                totalDistance += distance
                
                // Estimate 3 mph walking speed + 15 minutes between buildings
                let travelTime = (distance / 1609.34) / 3.0 * 3600 + 900 // meters to miles, 3 mph, + 15 min
                totalDuration += travelTime
            }
        }
        
        return (totalDistance, totalDuration)
    }
    
    private func hasTimeConflict(task1: MaintenanceTask, task2: MaintenanceTask) -> Bool {
        // Parse times and check for overlap
        guard let start1 = task1.startTime,
              let end1 = task1.endTime,
              let start2 = task2.startTime,
              let end2 = task2.endTime else {
            return false
        }
        
        return start1 < end2 && start2 < end1
    }
    
    private func suggestNewTime(for task: MaintenanceTask, avoiding conflictTask: MaintenanceTask) -> String {
        // Simple logic to suggest a new time
        guard let conflictEnd = conflictTask.endTime else {
            return task.startTime?.description ?? "09:00"
        }
        
        let suggestedStart = conflictEnd.addingTimeInterval(900) // 15 minutes buffer
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: suggestedStart)
    }
    
    private func calculateArrivalTime(for tasks: [MaintenanceTask]) -> Date {
        let earliestTask = tasks.min { task1, task2 in
            guard let time1 = task1.startTime,
                  let time2 = task2.startTime else {
                return false
            }
            return time1 < time2
        }
        
        return earliestTask?.startTime ?? Date()
    }
    
    private func calculateTaskDuration(for tasks: [MaintenanceTask]) -> TimeInterval {
        // Estimate based on number of tasks and complexity
        let basicTaskTime: TimeInterval = 1800 // 30 minutes
        let complexityMultiplier = 1.0 + (Double(tasks.count - 1) * 0.1) // Extra time for multiple tasks
        
        return basicTaskTime * Double(tasks.count) * complexityMultiplier
    }
    
    // MARK: - Route Optimization Analysis
    
    private func analyzeGeographicEfficiency(route: WorkerDailyRoute) -> RouteOptimization? {
        // Analyze if stops could be reordered for better geographic flow
        if route.stops.count < 3 { return nil }
        
        // Calculate current total distance
        var currentDistance: Double = 0
        for i in 0..<route.stops.count - 1 {
            let current = CLLocation(latitude: route.stops[i].coordinate.latitude, longitude: route.stops[i].coordinate.longitude)
            let next = CLLocation(latitude: route.stops[i + 1].coordinate.latitude, longitude: route.stops[i + 1].coordinate.longitude)
            currentDistance += current.distance(from: next)
        }
        
        // If total distance is more than 2 miles, suggest optimization
        if currentDistance > 3218.69 { // 2 miles in meters
            return RouteOptimization(
                type: .reorder,
                description: "Route has excessive backtracking. Consider grouping nearby buildings.",
                timeSaved: 1800, // 30 minutes
                estimatedTimeSaving: 1800
            )
        }
        
        return nil
    }
    
    private func analyzeTimeEfficiency(route: WorkerDailyRoute) -> RouteOptimization? {
        // Check for time gaps or rushed transitions
        for i in 0..<route.stops.count - 1 {
            let currentStop = route.stops[i]
            let nextStop = route.stops[i + 1]
            
            let endTime = currentStop.arrivalTime.addingTimeInterval(currentStop.estimatedTaskDuration)
            let timeBetween = nextStop.arrivalTime.timeIntervalSince(endTime)
            
            if timeBetween > 3600 { // More than 1 hour gap
                return RouteOptimization(
                    type: .combine,
                    description: "Large time gap between \(currentStop.buildingName) and \(nextStop.buildingName)",
                    timeSaved: timeBetween / 2,
                    estimatedTimeSaving: timeBetween / 2
                )
            }
        }
        
        return nil
    }
    
    private func analyzeSkillGrouping(route: WorkerDailyRoute) -> RouteOptimization? {
        // Group similar category tasks together for efficiency
        let allTasks = route.stops.flatMap { $0.tasks }
        let categoryGroups = Set(allTasks.map { $0.category })
        
        if categoryGroups.count > 2 {
            return RouteOptimization(
                type: .combine,
                description: "Tasks could be grouped by category for better efficiency",
                timeSaved: 900, // 15 minutes
                estimatedTimeSaving: 900
            )
        }
        
        return nil
    }
}

// MARK: - Supporting Types


// MARK: - Worker Routine View
struct WorkerRoutineView: View {
    @StateObject private var viewModel = WorkerRoutineViewModel()
    @State private var selectedTab = 0
    @State private var showingTaskDetail: MaintenanceTask?
    
    private let tabTitles = ["Overview", "Route", "Buildings"]
    private let tabIcons = ["chart.bar", "map", "building.2"]
    private let tabSelectedIcons = ["chart.bar.fill", "map.fill", "building.2.fill"]
    
    var body: some View {
        ZStack {
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(message: errorMessage)
                }
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    overviewTab.tag(0)
                    routeTab.tag(1)
                    buildingsTab.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Spacer()
                
                // Simple Tab Bar
                HStack(spacing: 0) {
                    ForEach(0..<tabTitles.count, id: \.self) { index in
                        Button(action: {
                            selectedTab = index
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: selectedTab == index ? tabSelectedIcons[index] : tabIcons[index])
                                    .font(.system(size: 20))
                                
                                Text(tabTitles[index])
                                    .font(.caption)
                            }
                            .foregroundColor(selectedTab == index ? .blue : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.vertical, 12)
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadWorkerData()
            }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task {
                await viewModel.loadWorkerData()
            }
        }
        .sheet(item: $showingTaskDetail) { task in
            NavigationView {
                MaintenanceTaskDetailView(task: task)
                    .navigationBarItems(trailing: Button("Done") {
                        showingTaskDetail = nil
                    })
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $viewModel.showingMapView) {
            if let route = viewModel.dailyRoute {
                RouteMapView(route: route)
                    .preferredColorScheme(.dark)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Worker Routine")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(viewModel.selectedWorker)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            HStack {
                // Date Picker
                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                
                // Worker Picker
                Menu {
                    Button("Kevin Dutan") { viewModel.selectedWorker = "Kevin Dutan" }
                    Button("Edwin Lema") { viewModel.selectedWorker = "Edwin Lema" }
                    Button("Greg Hutson") { viewModel.selectedWorker = "Greg Hutson" }
                } label: {
                    Image(systemName: "person.circle")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }
    
    // MARK: - Error Banner
    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Retry") {
                Task {
                    await viewModel.loadWorkerData()
                }
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(6)
        }
        .padding()
        .background(Color.orange.opacity(0.2))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.orange.opacity(0.5)),
            alignment: .bottom
        )
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Loading worker routine...")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Worker Stats
                    if let summary = viewModel.workerSummary {
                        workerStatsCard(summary: summary)
                    }
                    
                    // Data Health Status
                    dataHealthSection
                    
                    // Schedule Conflicts (if any)
                    if !viewModel.scheduleConflicts.isEmpty {
                        conflictsCard
                    }
                    
                    // Route Summary
                    if let route = viewModel.dailyRoute {
                        routeSummaryCard(route: route)
                    }
                    
                    // Task Distribution
                    taskDistributionCard
                }
                
                Color.clear.frame(height: 100)
            }
            .padding()
        }
        .refreshable {
            await viewModel.loadWorkerData()
        }
    }
    
    // MARK: - Route Tab
    private var routeTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let route = viewModel.dailyRoute {
                    // Route Header
                    GlassCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Today's Route")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Button("View Map") {
                                    viewModel.showingMapView = true
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                            
                            HStack(spacing: 20) {
                                VStack(spacing: 4) {
                                    Text("\(route.stops.count)")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Stops")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: 4) {
                                    Text(formatDistance(route.totalDistance))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Distance")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: 4) {
                                    Text(formatDuration(route.estimatedDuration))
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text("Duration")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    
                    // Route Optimizations
                    if !viewModel.routeOptimizations.isEmpty {
                        optimizationsCard
                    }
                    
                    // Route Stops
                    VStack(spacing: 12) {
                        ForEach(Array(route.stops.enumerated()), id: \.offset) { index, stop in
                            routeStopCard(stop: stop, index: index + 1)
                        }
                    }
                    
                } else {
                    GlassCard {
                        VStack(spacing: 16) {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            Text("No Route Available")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("No tasks scheduled for this date")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Button("Optimize Route") {
                                Task {
                                    await viewModel.optimizeRoute()
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 20)
                    }
                }
                
                Color.clear.frame(height: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Buildings Tab
    private var buildingsTab: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Buildings Summary
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Assigned Buildings")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(viewModel.buildingsWithTasks.count) buildings with tasks")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Text("\(viewModel.routineTasks.values.flatMap { $0 }.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                // Building List
                ForEach(viewModel.buildingsWithTasks, id: \.building.id) { item in
                    buildingTaskGroup(building: item.building, taskCount: item.taskCount)
                }
                
                Color.clear.frame(height: 100)
            }
            .padding()
        }
    }
    
    // MARK: - Component Views
    
    private func workerStatsCard(summary: WorkerRoutineSummary) -> some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Routine Summary")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Stats Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    StatItem(title: "Daily Tasks", value: "\(summary.dailyTasks)", color: .green)
                    StatItem(title: "Weekly Tasks", value: "\(summary.weeklyTasks)", color: .blue)
                    StatItem(title: "Monthly Tasks", value: "\(summary.monthlyTasks)", color: .orange)
                    StatItem(title: "Buildings", value: "\(summary.buildingCount)", color: .purple)
                }
                
                // Time Estimates
                VStack(spacing: 8) {
                    HStack {
                        Text("Estimated Daily Hours:")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: "%.1f hours", summary.estimatedDailyHours))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    
                    HStack {
                        Text("Weekly Total:")
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: "%.1f hours", summary.estimatedWeeklyHours))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                .font(.subheadline)
            }
        }
    }
    
    @ViewBuilder
    private var dataHealthSection: some View {
        switch viewModel.dataHealthStatus {
        case .warning(let issues):
            DataHealthWarningCard(issues: issues) {
                Task {
                    await viewModel.refreshData()
                }
            }
        case .critical(let issues):
            DataHealthCriticalCard(issues: issues) {
                Task {
                    await viewModel.refreshData()
                }
            }
        default:
            EmptyView()
        }
    }
    
    private var conflictsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Schedule Conflicts")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(viewModel.scheduleConflicts.count)")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                ForEach(Array(viewModel.scheduleConflicts.enumerated()), id: \.offset) { index, conflict in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(conflict.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text(conflict.suggestedResolution)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 8)
                    
                    if index < viewModel.scheduleConflicts.count - 1 {
                        Divider()
                            .background(.white.opacity(0.2))
                    }
                }
            }
        }
    }
    
    private func routeSummaryCard(route: WorkerDailyRoute) -> some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    Text("Route Summary")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Optimize") {
                        Task {
                            await viewModel.optimizeRoute()
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                HStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text("\(route.stops.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("Buildings")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 4) {
                        Text(formatDistance(route.totalDistance))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Distance")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(spacing: 4) {
                        Text(formatDuration(route.estimatedDuration))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Duration")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    private var optimizationsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    
                    Text("Route Optimizations")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(viewModel.routeOptimizations.count)")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(8)
                }
                
                ForEach(Array(viewModel.routeOptimizations.enumerated()), id: \.offset) { index, optimization in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(optimization.description)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Text("Saves:")
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(formatDuration(optimization.estimatedTimeSaving))
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                    .padding(.leading, 8)
                    
                    if index < viewModel.routeOptimizations.count - 1 {
                        Divider()
                            .background(.white.opacity(0.2))
                    }
                }
            }
        }
    }
    
    private var taskDistributionCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Task Distribution")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // Task categories
                let allTasks = viewModel.routineTasks.values.flatMap { $0 }
                let categoryGroups = Dictionary(grouping: allTasks) { $0.category }
                
                VStack(spacing: 8) {
                    ForEach(Array(categoryGroups.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { category in
                        let tasks = categoryGroups[category] ?? []
                        
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(categoryColor(category))
                                .frame(width: 20)
                            
                            Text(category.rawValue)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(tasks.count)")
                                .fontWeight(.semibold)
                                .foregroundColor(categoryColor(category))
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
    
    private func buildingTaskGroup(building: NamedCoordinate, taskCount: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Building Image or Icon
                    if !building.imageAssetName.isEmpty,
                       let image = UIImage(named: building.imageAssetName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.blue)
                            .frame(width: 50, height: 50)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text("\(taskCount) routine tasks")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button("View Tasks") {
                        let tasks = viewModel.tasksForBuilding(building.id)
                        if let firstTask = tasks.first {
                            showingTaskDetail = firstTask
                        }
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }
                
                // Task breakdown for this building
                let buildingTasks = viewModel.tasksForBuilding(building.id)
                let tasksByRecurrence = Dictionary(grouping: buildingTasks) { $0.recurrence }
                
                HStack(spacing: 16) {
                    if let dailyTasks = tasksByRecurrence[TaskRecurrence.daily] {
                        TaskTypeChip(type: "Daily", count: dailyTasks.count, color: .green)
                    }
                    
                    if let weeklyTasks = tasksByRecurrence[TaskRecurrence.weekly] {
                        TaskTypeChip(type: "Weekly", count: weeklyTasks.count, color: .blue)
                    }
                    
                    if let monthlyTasks = tasksByRecurrence[TaskRecurrence.monthly] {
                        TaskTypeChip(type: "Monthly", count: monthlyTasks.count, color: .orange)
                    }
                }
            }
        }
    }
    
    private func routeStopCard(stop: RouteStop, index: Int) -> some View {
        GlassCard {
            HStack(spacing: 12) {
                // Stop Number
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                    
                    Text("\(index)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Stop Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.buildingName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Text("\(stop.tasks.count) tasks")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatTime(stop.arrivalTime))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatDuration(stop.estimatedTaskDuration))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                // View Tasks Button
                Button("Tasks") {
                    if let firstTask = stop.tasks.first {
                        showingTaskDetail = firstTask
                    }
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func categoryColor(_ category: TaskCategory) -> Color {
        switch category {
        case .cleaning: return .blue
        case .maintenance: return .orange
        case .repair: return .red
        case .sanitation: return .green
        case .inspection: return .purple
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        let miles = distance * 0.000621371
        return String(format: "%.1f mi", miles)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Components

struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct TaskTypeChip: View {
    let type: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(type)
            Text("\(count)")
                .fontWeight(.semibold)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(8)
    }
}

// MARK: - Data Health Components

struct DataHealthWarningCard: View {
    let issues: [String]
    let onRetry: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text("Data Health Warning")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Fix") {
                        onRetry()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                
                ForEach(issues, id: \.self) { issue in
                    Text("• \(issue)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

struct DataHealthCriticalCard: View {
    let issues: [String]
    let onRetry: () -> Void
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundColor(.red)
                    
                    Text("Critical Data Issues")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("Fix Now") {
                        onRetry()
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
                
                ForEach(issues, id: \.self) { issue in
                    Text("• \(issue)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Route Map View (iOS 17+ Compatible)
struct RouteMapView: View {
    let route: WorkerDailyRoute
    @Environment(\.dismiss) var dismiss
    @State private var cameraPosition: MapCameraPosition
    
    init(route: WorkerDailyRoute) {
        self.route = route
        
        // Calculate region to fit all stops
        let coordinates = route.stops.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        let region = MKCoordinateRegion(center: center, span: span)
        _cameraPosition = State(initialValue: .region(region))
    }
    
    var body: some View {
        ZStack {
            // Modern Map (iOS 17+)
            Map(position: $cameraPosition) {
                ForEach(Array(route.stops.enumerated()), id: \.offset) { index, stop in
                    Annotation(stop.buildingName, coordinate: stop.coordinate) {
                        RouteStopMarker(stop: stop, index: index)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Header
            VStack {
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Route Map")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(route.stops.count) stops • \(formatDistance(route.totalDistance))")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button("Close") {
                            dismiss()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                    }
                }
                .padding()
                
                Spacer()
            }
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        let miles = distance * 0.000621371
        return String(format: "%.1f miles", miles)
    }
}

struct RouteStopMarker: View {
    let stop: RouteStop
    let index: Int
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            Text("\(index + 1)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .shadow(radius: 3)
    }
}

// MARK: - MaintenanceTaskDetailView
struct MaintenanceTaskDetailView: View {
    let task: MaintenanceTask
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(task.category.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(task.category.categoryColor.opacity(0.2))
                            .foregroundColor(task.category.categoryColor)
                            .cornerRadius(8)
                        
                        Text(task.urgency.rawValue)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Task Details
                VStack(alignment: .leading, spacing: 8) {
                    DetailRow(title: "Building ID", value: task.buildingID)
                    DetailRow(title: "Due Date", value: formatDate(task.dueDate))
                    DetailRow(title: "Recurrence", value: task.recurrence.rawValue)
                    DetailRow(title: "Skill Level", value: task.requiredSkillLevel)
                    
                    if let startTime = task.startTime {
                        DetailRow(title: "Start Time", value: formatTime(startTime))
                    }
                    
                    if let endTime = task.endTime {
                        DetailRow(title: "End Time", value: formatTime(endTime))
                    }
                }
                
                Divider()
                    .background(.white.opacity(0.2))
                
                // Status
                HStack {
                    Text("Status:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    Text(task.isComplete ? "Completed" : "Pending")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(task.isComplete ? .green : .orange)
                }
            }
            .padding()
        }
        .padding()
        .background(FrancoSphereColors.primaryBackground)
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
struct WorkerRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerRoutineView()
            .preferredColorScheme(.dark)
    }
}
