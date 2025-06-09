import SwiftUI
import Foundation
import CoreLocation

// MARK: - Today Tasks View Model
@MainActor
class TodayTasksViewModel: ObservableObject {
    @Published var morningTasks: [MaintenanceTask] = []
    @Published var afternoonTasks: [MaintenanceTask] = []
    @Published var allDayTasks: [MaintenanceTask] = []
    @Published var isLoading = false
    @Published var hasRouteOptimization = false
    @Published var suggestedRoute: WorkerDailyRoute?
    @Published var completionStats: TaskCompletionStats = TaskCompletionStats()
    
    private let taskManager = TaskManager.shared
    private let routineManager = WorkerRoutineManager.shared
    
    func loadTasks(for workerId: String) async {
        isLoading = true
        
        // Get today's tasks - Fixed method name
        let todayTasks = await taskManager.fetchTasksAsync(forWorker: workerId, date: Date())
        
        // Sort into time-based categories
        let calendar = Calendar.current
        var morning: [MaintenanceTask] = []
        var afternoon: [MaintenanceTask] = []
        var allDay: [MaintenanceTask] = []
        
        for task in todayTasks {
            if let startTime = task.startTime {
                let hour = calendar.component(.hour, from: startTime)
                if hour < 12 {
                    morning.append(task)
                } else {
                    afternoon.append(task)
                }
            } else {
                allDay.append(task)
            }
        }
        
        // Sort each category by start time, then urgency
        self.morningTasks = morning.sorted { task1, task2 in
            if let time1 = task1.startTime, let time2 = task2.startTime {
                return time1 < time2
            }
            return task1.urgency.rawValue > task2.urgency.rawValue
        }
        
        self.afternoonTasks = afternoon.sorted { task1, task2 in
            if let time1 = task1.startTime, let time2 = task2.startTime {
                return time1 < time2
            }
            return task1.urgency.rawValue > task2.urgency.rawValue
        }
        
        self.allDayTasks = allDay.sorted { $0.urgency.rawValue > $1.urgency.rawValue }
        
        // Calculate completion stats
        self.completionStats = calculateCompletionStats(tasks: todayTasks)
        
        // Check for route optimization
        await checkRouteOptimization(workerId: workerId)
        
        isLoading = false
    }
    
    private func calculateCompletionStats(tasks: [MaintenanceTask]) -> TaskCompletionStats {
        let total = tasks.count
        let completed = tasks.filter { $0.isComplete }.count
        let urgent = tasks.filter { $0.urgency == .urgent && !$0.isComplete }.count
        let pastDue = tasks.filter { $0.isPastDue && !$0.isComplete }.count
        
        return TaskCompletionStats(
            total: total,
            completed: completed,
            remaining: total - completed,
            urgent: urgent,
            pastDue: pastDue,
            completionRate: total > 0 ? Double(completed) / Double(total) : 0
        )
    }
    
    private func checkRouteOptimization(workerId: String) async {
        do {
            let route = try await routineManager.getDailyRoute(workerId: workerId, date: Date())
            
            // Check if route has multiple buildings (worth optimizing)
            let uniqueBuildings = Set(route.stops.map { $0.buildingId })
            
            if uniqueBuildings.count > 2 {
                self.hasRouteOptimization = true
                self.suggestedRoute = route
            }
        } catch {
            print("❌ Failed to load route optimization: \(error)")
        }
    }
}

// MARK: - Task Completion Stats
struct TaskCompletionStats {
    let total: Int
    let completed: Int
    let remaining: Int
    let urgent: Int
    let pastDue: Int
    let completionRate: Double
    
    init(total: Int = 0, completed: Int = 0, remaining: Int = 0, urgent: Int = 0, pastDue: Int = 0, completionRate: Double = 0) {
        self.total = total
        self.completed = completed
        self.remaining = remaining
        self.urgent = urgent
        self.pastDue = pastDue
        self.completionRate = completionRate
    }
}

// MARK: - Today Tasks View
struct TodayTasksView: View {
    let workerId: String
    
    @StateObject private var viewModel = TodayTasksViewModel()
    @State private var selectedTask: MaintenanceTask?
    @State private var showingRouteOptimization = false
    
    // Helper function for urgency color
    private func getUrgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .red
        case .urgent: return .purple
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                FrancoSphereColors.primaryBackground
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading today's tasks...")
                        .foregroundColor(.white)
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Stats Header
                            statsHeaderView
                            
                            // Route Optimization Card
                            if viewModel.hasRouteOptimization {
                                routeOptimizationCard
                            }
                            
                            // Morning Tasks Section
                            if !viewModel.morningTasks.isEmpty {
                                TaskSection(
                                    title: "Morning Tasks",
                                    subtitle: "7:00 AM - 12:00 PM",
                                    tasks: viewModel.morningTasks,
                                    iconName: "sunrise.fill",
                                    iconColor: .orange,
                                    onTaskTap: { task in selectedTask = task }
                                )
                            }
                            
                            // Afternoon Tasks Section
                            if !viewModel.afternoonTasks.isEmpty {
                                TaskSection(
                                    title: "Afternoon Tasks",
                                    subtitle: "12:00 PM - 6:00 PM",
                                    tasks: viewModel.afternoonTasks,
                                    iconName: "sun.max.fill",
                                    iconColor: .yellow,
                                    onTaskTap: { task in selectedTask = task }
                                )
                            }
                            
                            // All Day Tasks Section
                            if !viewModel.allDayTasks.isEmpty {
                                TaskSection(
                                    title: "Flexible Tasks",
                                    subtitle: "Complete anytime today",
                                    tasks: viewModel.allDayTasks,
                                    iconName: "clock.fill",
                                    iconColor: .blue,
                                    onTaskTap: { task in selectedTask = task }
                                )
                            }
                            
                            // Empty State
                            if viewModel.morningTasks.isEmpty &&
                               viewModel.afternoonTasks.isEmpty &&
                               viewModel.allDayTasks.isEmpty {
                                emptyStateView
                            }
                            
                            // Bottom spacing
                            Color.clear.frame(height: 100)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Today's Tasks")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
            .refreshable {
                await viewModel.loadTasks(for: workerId)
            }
            .sheet(item: $selectedTask) { task in
                NavigationView {
                    BuildingTaskDetailView(task: task)
                        .navigationBarItems(trailing: Button("Done") {
                            selectedTask = nil
                        })
                }
                .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showingRouteOptimization) {
                if let route = viewModel.suggestedRoute {
                    RouteOptimizationView(route: route)
                        .preferredColorScheme(.dark)
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadTasks(for: workerId)
                }
            }
        }
    }
    
    // MARK: - Stats Header
    private var statsHeaderView: some View {
        GlassCard {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Progress")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("\(viewModel.completionStats.completed) of \(viewModel.completionStats.total) tasks completed")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        
                        Circle()
                            .trim(from: 0, to: viewModel.completionStats.completionRate)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1), value: viewModel.completionStats.completionRate)
                        
                        Text("\(Int(viewModel.completionStats.completionRate * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Quick Stats Row
                HStack(spacing: 20) {
                    StatBadge(
                        title: "Remaining",
                        value: "\(viewModel.completionStats.remaining)",
                        color: .blue
                    )
                    
                    if viewModel.completionStats.urgent > 0 {
                        StatBadge(
                            title: "Urgent",
                            value: "\(viewModel.completionStats.urgent)",
                            color: .red
                        )
                    }
                    
                    if viewModel.completionStats.pastDue > 0 {
                        StatBadge(
                            title: "Past Due",
                            value: "\(viewModel.completionStats.pastDue)",
                            color: .orange
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Route Optimization Card
    private var routeOptimizationCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Route Optimization Available")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let route = viewModel.suggestedRoute {
                            Text("\(route.stops.count) buildings • \(formatDistance(route.totalDistance))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    Button("Optimize") {
                        showingRouteOptimization = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if let route = viewModel.suggestedRoute {
                    HStack {
                        Text("Estimated time:")
                        Text(formatDuration(route.estimatedDuration))
                            .foregroundColor(.blue)
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        GlassCard {
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("All Done for Today!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("You've completed all your scheduled tasks. Great work!")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("View Weekly Schedule") {
                    // Navigate to weekly view
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDistance(_ distance: Double) -> String {
        let miles = distance * 0.000621371 // Convert meters to miles
        return String(format: "%.1f miles", miles)
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
}

// MARK: - Task Section Component
struct TaskSection: View {
    let title: String
    let subtitle: String
    let tasks: [MaintenanceTask]
    let iconName: String
    let iconColor: Color
    let onTaskTap: (MaintenanceTask) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text("\(tasks.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(iconColor.opacity(0.2))
                    .foregroundColor(iconColor)
                    .cornerRadius(8)
            }
            
            // Tasks
            VStack(spacing: 8) {
                ForEach(tasks, id: \.id) { task in
                    TaskRowCompact(task: task, onTap: { onTaskTap(task) })
                }
            }
        }
    }
}

// MARK: - Compact Task Row
struct TaskRowCompact: View {
    let task: MaintenanceTask
    let onTap: () -> Void
    
    // Helper function for urgency color
    private func getUrgencyColor(_ urgency: TaskUrgency) -> Color {
        switch urgency {
        case .low:    return .green
        case .medium: return .yellow
        case .high:   return .red
        case .urgent: return .purple
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            GlassCard {
                HStack(spacing: 12) {
                    // Status Indicator - Fixed color access
                    ZStack {
                        Circle()
                            .fill(task.isComplete ? Color.green : getUrgencyColor(task.urgency))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: task.isComplete ? "checkmark" : task.category.icon)
                            .foregroundColor(.white)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    
                    // Task Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(task.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 8) {
                            // Building
                            Text(BuildingRepository.shared.getBuildingName(forId: task.buildingID))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                            
                            // Time
                            if let startTime = task.startTime {
                                Text("•")
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(formatTime(startTime))
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Urgency Badge
                            if task.urgency == .urgent || task.urgency == .high {
                                Text(task.urgency.rawValue.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(getUrgencyColor(task.urgency))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                        }
                    }
                    
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Route Optimization View
struct RouteOptimizationView: View {
    let route: WorkerDailyRoute
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Route Summary
                    GlassCard {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Optimized Route")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            
                            HStack(spacing: 20) {
                                RouteStatItem(title: "Buildings", value: "\(route.stops.count)")
                                RouteStatItem(title: "Distance", value: formatDistance(route.totalDistance))
                                RouteStatItem(title: "Time", value: formatDuration(route.estimatedDuration))
                            }
                        }
                    }
                    
                    // Route Stops
                    VStack(spacing: 12) {
                        ForEach(Array(route.stops.enumerated()), id: \.offset) { index, stop in
                            RouteStopCard(stop: stop, index: index + 1)
                        }
                    }
                    
                    Color.clear.frame(height: 50)
                }
                .padding()
            }
            .background(FrancoSphereColors.primaryBackground)
            .navigationTitle("Route Optimization")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
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
}

// MARK: - Route Components

struct RouteStopCard: View {
    let stop: RouteStop
    let index: Int
    
    var body: some View {
        GlassCard {
            HStack(spacing: 12) {
                // Stop Number
                ZStack {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                    
                    Text("\(index)")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                // Building Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(stop.buildingName)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(stop.tasks.count) tasks • \(formatTime(stop.arrivalTime))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Duration
                Text(formatDuration(stop.estimatedTaskDuration))
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
            }
        }
    }
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "TBD" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        return "\(minutes)m"
    }
}

// MARK: - Preview
struct TodayTasksView_Previews: PreviewProvider {
    static var previews: some View {
        TodayTasksView(workerId: "4") // Kevin Dutan
            .preferredColorScheme(.dark)
    }
}
