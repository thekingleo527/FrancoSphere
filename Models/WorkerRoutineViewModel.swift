//
//  WorkerRoutineViewModel.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/4/25.
//


//
//  WorkerRoutineView.swift
//  FrancoSphere
//
//  Specialized view for worker routines - handles Kevin's 28 tasks across 9 buildings
//  Includes route optimization and schedule conflict detection
//

import SwiftUI
import MapKit
import Foundation
import CoreLocation

// MARK: - Worker Routine View Model
@MainActor
class WorkerRoutineViewModel: ObservableObject {
    @Published var selectedWorker = "Kevin Dutan"
    @Published var workerSummary: WorkerRoutineSummary?
    @Published var routineTasks: [String: [MaintenanceTask]] = [:]
    @Published var dailyRoute: WorkerDailyRoute?
    @Published var routeOptimizations: [RouteOptimization] = []
    @Published var scheduleConflicts: [ScheduleConflict] = []
    @Published var isLoading = false
    @Published var selectedDate = Date()
    @Published var showingMapView = false
    
    private let taskManager = TaskManager.shared
    private let routineManager = WorkerRoutineManager.shared
    
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
    
    func loadWorkerData() async {
        isLoading = true
        
        // Get worker ID
        guard let workerId = WorkerProfile.getWorkerId(byName: selectedWorker) else {
            print("❌ Worker not found: \(selectedWorker)")
            isLoading = false
            return
        }
        
        // Load routine summary
        self.workerSummary = await routineManager.getWorkerRoutineSummary(workerId: workerId)
        
        // Load routine tasks grouped by building
        self.routineTasks = await loadRoutineTasksByBuilding(workerId: workerId)
        
        // Load daily route for selected date
        do {
            self.dailyRoute = try await routineManager.getDailyRoute(workerId: workerId, date: selectedDate)
            
            // Get route optimizations
            if let route = dailyRoute {
                self.routeOptimizations = await routineManager.suggestOptimizations(for: route)
            }
        } catch {
            print("❌ Failed to load daily route: \(error)")
        }
        
        // Load schedule conflicts
        await loadScheduleConflicts(workerId: workerId)
        
        isLoading = false
    }
    
    private func loadRoutineTasksByBuilding(workerId: String) async -> [String: [MaintenanceTask]] {
        let routineTasks = await taskManager.getWorkerRoutineTasks(workerId: workerId)
        return routineTasks
    }
    
    private func loadScheduleConflicts(workerId: String) async {
        do {
            if let route = dailyRoute {
                self.scheduleConflicts = await routineManager.detectScheduleConflicts(
                    stops: route.stops,
                    date: selectedDate
                )
            }
        } catch {
            print("❌ Failed to load schedule conflicts: \(error)")
        }
    }
    
    func tasksForBuilding(_ buildingId: String) -> [MaintenanceTask] {
        return routineTasks.values.flatMap { $0 }.filter { $0.buildingID == buildingId }
    }
    
    func optimizeRoute() async {
        guard let workerId = WorkerProfile.getWorkerId(byName: selectedWorker) else { return }
        
        do {
            self.dailyRoute = try await routineManager.getDailyRoute(workerId: workerId, date: selectedDate)
            
            if let route = dailyRoute {
                self.routeOptimizations = await routineManager.suggestOptimizations(for: route)
            }
        } catch {
            print("❌ Route optimization failed: \(error)")
        }
    }
}

// MARK: - Worker Routine View
struct WorkerRoutineView: View {
    @StateObject private var viewModel = WorkerRoutineViewModel()
    @State private var selectedTab = 0
    @State private var showingTaskDetail: MaintenanceTask?
    
    private let tabs = [
        GlassTabItem(title: "Overview", icon: "chart.bar", selectedIcon: "chart.bar.fill"),
        GlassTabItem(title: "Route", icon: "map", selectedIcon: "map.fill"),
        GlassTabItem(title: "Buildings", icon: "building.2", selectedIcon: "building.2.fill")
    ]
    
    var body: some View {
        ZStack {
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    overviewTab.tag(0)
                    routeTab.tag(1)
                    buildingsTab.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                Spacer()
                
                // Custom Tab Bar
                GlassTabBar(selectedTab: $selectedTab, tabs: tabs)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            Task {
                await viewModel.loadWorkerData()
            }
        }
        .onChange(of: viewModel.selectedDate) { _ in
            Task {
                await viewModel.loadWorkerData()
            }
        }
        .sheet(item: $showingTaskDetail) { task in
            NavigationView {
                BuildingTaskDetailView(task: task)
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
        GlassNavigationBar(
            title: "Worker Routine",
            subtitle: viewModel.selectedWorker
        ) {
            HStack {
                // Date Picker
                DatePicker("", selection: $viewModel.selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
                
                // Worker Picker (for future expansion)
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
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    GlassLoadingView(message: "Loading worker routine...")
                } else {
                    // Worker Stats
                    if let summary = viewModel.workerSummary {
                        workerStatsCard(summary: summary)
                    }
                    
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
                                .glassButton()
                                .foregroundColor(.white)
                            }
                            
                            HStack(spacing: 20) {
                                RouteStatItem(title: "Stops", value: "\(route.stops.count)")
                                RouteStatItem(title: "Distance", value: formatDistance(route.totalDistance))
                                RouteStatItem(title: "Duration", value: formatDuration(route.estimatedDuration))
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
                            .glassButton()
                            .foregroundColor(.white)
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
                    
                    GlassStatusBadge(text: "\(viewModel.scheduleConflicts.count)", style: .warning, size: .small)
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
                    
                    GlassStatusBadge(text: "\(viewModel.routeOptimizations.count)", style: .warning, size: .small)
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
                    if let image = UIImage(named: building.imageAssetName) {
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
                        // Show tasks for this building
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
                    if let dailyTasks = tasksByRecurrence[.daily] {
                        TaskTypeChip(type: "Daily", count: dailyTasks.count, color: .green)
                    }
                    
                    if let weeklyTasks = tasksByRecurrence[.weekly] {
                        TaskTypeChip(type: "Weekly", count: weeklyTasks.count, color: .blue)
                    }
                    
                    if let monthlyTasks = tasksByRecurrence[.monthly] {
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

// MARK: - Route Map View
struct RouteMapView: View {
    let route: WorkerDailyRoute
    @Environment(\.presentationMode) var presentationMode
    @State private var region: MKCoordinateRegion
    
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
        
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }
    
    var body: some View {
        ZStack {
            // Map
            Map(coordinateRegion: $region, annotationItems: route.stops) { stop in
                MapAnnotation(coordinate: stop.coordinate) {
                    RouteStopMarker(stop: stop, index: route.stops.firstIndex(where: { $0.buildingId == stop.buildingId }) ?? 0)
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
                            presentationMode.wrappedValue.dismiss()
                        }
                        .glassButton()
                        .foregroundColor(.white)
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

// MARK: - Preview
struct WorkerRoutineView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerRoutineView()
            .preferredColorScheme(.dark)
    }
}
#if canImport(Glass)
import Glass
#endif
