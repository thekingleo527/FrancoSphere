import SwiftUI
import Foundation
import CoreLocation
import Combine

// MARK: - ContextualTask Extensions for Immutable Updates
extension ContextualTask {
    
    /// Create a new ContextualTask with updated status
    func withUpdatedStatus(_ newStatus: String) -> ContextualTask {
        return ContextualTask(
            id: self.id,
            name: self.name,
            buildingId: self.buildingId,
            buildingName: self.buildingName,
            category: self.category,
            startTime: self.startTime,
            endTime: self.endTime,
            recurrence: self.recurrence,
            skillLevel: self.skillLevel,
            status: newStatus, // Only this changes
            urgencyLevel: self.urgencyLevel,
            assignedWorkerName: self.assignedWorkerName,
            scheduledDate: self.scheduledDate
        )
    }
}

// MARK: - Enhanced Today Tasks & Progress View Model
@MainActor
class TodayTasksViewModel: ObservableObject {
    
    // MARK: - Today's Task Organization (Original Functionality)
    @Published var morningTasks: [ContextualTask] = []
    @Published var afternoonTasks: [ContextualTask] = []
    @Published var allDayTasks: [ContextualTask] = []
    @Published var isLoading = false
    @Published var hasRouteOptimization = false
    @Published var suggestedRoute: WorkerDailyRoute?
    @Published var completionStats: TaskCompletionStats = TaskCompletionStats()
    
    // MARK: - Enhanced Progress Analytics (New Functionality)
    @Published var selectedTimeframe: Timeframe = .today
    @Published var weeklyProgress: [DayProgress] = []
    @Published var monthlyTrends: TaskTrends = TaskTrends()
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    @Published var streakData: StreakData = StreakData()
    @Published var completionGoal: Double = 90.0 // 90% completion goal
    @Published var errorMessage: String?
    @Published var isRefreshing = false
    
    // MARK: - Dependencies
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingService = BuildingService.shared
    private let authManager = NewAuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Constants
    private let refreshInterval: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    init() {
        setupReactiveBindings()
    }
    
    // MARK: - Reactive Bindings
    private func setupReactiveBindings() {
        // Listen to timeframe changes
        $selectedTimeframe
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadProgressData()
                }
            }
            .store(in: &cancellables)
        
        // Periodic refresh
        Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshAllData()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Original Task Loading (Enhanced)
    func loadTasks(for workerId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load today's tasks using consolidated TaskService
            let todayTasks = try await taskService.getTasks(for: workerId, date: Date())
            
            // Sort into time-based categories
            let calendar = Calendar.current
            var morning: [ContextualTask] = []
            var afternoon: [ContextualTask] = []
            var allDay: [ContextualTask] = []
            
            for task in todayTasks {
                if let startTime = parseTime(task.startTime) {
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
            self.morningTasks = sortTasks(morning)
            self.afternoonTasks = sortTasks(afternoon)
            self.allDayTasks = sortTasksByUrgency(allDay)
            
            // Calculate completion stats
            self.completionStats = calculateCompletionStats(tasks: todayTasks)
            
            // Check for route optimization
            await checkRouteOptimization(workerId: workerId, tasks: todayTasks)
            
            // Load progress analytics based on current timeframe
            await loadProgressData()
            
            print("✅ Tasks and progress data loaded for worker: \(workerId)")
            
        } catch {
            errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            print("❌ Failed to load tasks: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Enhanced Progress Analytics Loading
    func loadProgressData() async {
        guard let workerId = authManager.workerId else {
            errorMessage = "No worker ID available"
            return
        }
        
        do {
            // Load data based on selected timeframe
            switch selectedTimeframe {
            case .today:
                await loadTodayAnalytics(workerId: workerId)
            case .week:
                await loadWeeklyProgress(workerId: workerId)
            case .month:
                await loadMonthlyProgress(workerId: workerId)
            }
            
            // Load performance metrics
            performanceMetrics = await calculatePerformanceMetrics(workerId: workerId)
            
            // Calculate streak data
            streakData = await calculateStreakData(workerId: workerId)
            
        } catch {
            print("Failed to load progress data: \(error)")
        }
    }
    
    private func loadTodayAnalytics(workerId: String) async {
        // Today analytics are already calculated in completionStats
        // This method can be extended for additional today-specific analytics
    }
    
    private func loadWeeklyProgress(workerId: String) async {
        var weeklyData: [DayProgress] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Get progress for each day of the current week
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                do {
                    let dayTasks = try await taskService.getTasks(for: workerId, date: date)
                    let completed = dayTasks.filter { $0.status == "completed" }.count
                    let total = dayTasks.count
                    let percentage = total > 0 ? Double(completed) / Double(total) * 100 : 0
                    
                    let dayProgress = DayProgress(
                        date: date,
                        completed: completed,
                        total: total,
                        percentage: percentage,
                        averageTaskTime: await calculateAverageTaskTime(for: dayTasks)
                    )
                    
                    weeklyData.append(dayProgress)
                } catch {
                    print("Failed to load progress for \(date): \(error)")
                }
            }
        }
        
        weeklyProgress = weeklyData.sorted { $0.date < $1.date }
    }
    
    private func loadMonthlyProgress(workerId: String) async {
        // Calculate monthly trends
        let calendar = Calendar.current
        let today = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        
        do {
            // Get tasks for each day in the past 30 days
            var monthlyTasks: [ContextualTask] = []
            for i in 0..<30 {
                if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                    let dayTasks = try await taskService.getTasks(for: workerId, date: date)
                    monthlyTasks.append(contentsOf: dayTasks)
                }
            }
            
            let totalCompleted = monthlyTasks.filter { $0.status == "completed" }.count
            let totalTasks = monthlyTasks.count
            let completionRate = totalTasks > 0 ? Double(totalCompleted) / Double(totalTasks) * 100 : 0
            
            // Calculate category breakdown
            var categoryBreakdown: [CategoryProgress] = []
            let groupedByCategory = Dictionary(grouping: monthlyTasks, by: { $0.category })
            
            for (category, tasks) in groupedByCategory {
                let completed = tasks.filter { $0.status == "completed" }.count
                let categoryProgress = CategoryProgress(
                    category: category,
                    completed: completed,
                    total: tasks.count,
                    percentage: tasks.count > 0 ? Double(completed) / Double(tasks.count) * 100 : 0
                )
                categoryBreakdown.append(categoryProgress)
            }
            
            monthlyTrends = TaskTrends(
                completionRate: completionRate,
                totalTasks: totalTasks,
                completedTasks: totalCompleted,
                averageTasksPerDay: Double(totalTasks) / 30.0,
                categoryBreakdown: categoryBreakdown,
                improvementTrend: calculateImprovementTrend(monthlyTasks)
            )
            
        } catch {
            print("Failed to load monthly progress: \(error)")
        }
    }
    
    // MARK: - Enhanced Task Completion (Original + Analytics Update)
    func markTaskComplete(_ task: ContextualTask, workerId: String) async {
        do {
            try await taskService.completeTask(
                task.id,
                workerId: workerId,
                buildingId: task.buildingId,
                evidence: nil
            )
            
            // Update local state using immutable approach
            updateTaskInLocalState(task.id, newStatus: "completed")
            
            // Refresh completion stats
            let allTasks = morningTasks + afternoonTasks + allDayTasks
            self.completionStats = calculateCompletionStats(tasks: allTasks)
            
            // Update performance metrics in real-time
            performanceMetrics = await calculatePerformanceMetrics(workerId: workerId)
            
            // Check if this completion affects streak
            await updateStreakData(workerId: workerId)
            
            print("✅ Task completed and analytics updated: \(task.name)")
            
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
            print("❌ Failed to complete task: \(error)")
        }
    }
    
    // MARK: - Refresh Operations
    func refreshTasks(for workerId: String) async {
        await loadTasks(for: workerId)
    }
    
    func refreshAllData() async {
        guard let workerId = authManager.workerId else { return }
        
        isRefreshing = true
        await loadTasks(for: workerId)
        isRefreshing = false
    }
    
    // MARK: - Analytics Calculations
    
    private func calculatePerformanceMetrics(workerId: String) async -> PerformanceMetrics {
        do {
            let todayTasks = morningTasks + afternoonTasks + allDayTasks
            let completed = todayTasks.filter { $0.status == "completed" }
            let overdue = todayTasks.filter { $0.status == "overdue" }
            
            let efficiency = todayTasks.count > 0 ? Double(completed.count) / Double(todayTasks.count) * 100 : 0
            let onTimeRate = calculateOnTimeCompletionRate(completed)
            let qualityScore = await calculateQualityScore(workerId: workerId)
            
            return PerformanceMetrics(
                efficiency: efficiency,
                onTimeCompletionRate: onTimeRate,
                qualityScore: qualityScore,
                averageTaskDuration: await calculateAverageTaskTime(for: completed),
                overdueCount: overdue.count,
                productivityTrend: await calculateProductivityTrend(workerId: workerId)
            )
            
        } catch {
            print("Failed to calculate performance metrics: \(error)")
            return PerformanceMetrics()
        }
    }
    
    private func calculateStreakData(workerId: String) async -> StreakData {
        do {
            // Calculate current completion streak
            let calendar = Calendar.current
            var currentStreak = 0
            var longestStreak = 0
            var tempStreak = 0
            
            // Check last 30 days
            for i in 0..<30 {
                if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                    let dayTasks = try await taskService.getTasks(for: workerId, date: date)
                    let completionRate = dayTasks.count > 0 ? Double(dayTasks.filter { $0.status == "completed" }.count) / Double(dayTasks.count) * 100 : 0
                    
                    if completionRate >= completionGoal {
                        if i == 0 { // Today
                            currentStreak += 1
                        }
                        tempStreak += 1
                        longestStreak = max(longestStreak, tempStreak)
                    } else {
                        if i == 0 {
                            currentStreak = 0
                        }
                        tempStreak = 0
                    }
                }
            }
            
            return StreakData(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                streakGoal: 7, // 1 week goal
                daysUntilGoal: max(0, 7 - currentStreak)
            )
            
        } catch {
            print("Failed to calculate streak data: \(error)")
            return StreakData()
        }
    }
    
    private func updateStreakData(workerId: String) async {
        // Quick update after task completion
        let allTasks = morningTasks + afternoonTasks + allDayTasks
        let completionRate = allTasks.count > 0 ? Double(allTasks.filter { $0.status == "completed" }.count) / Double(allTasks.count) * 100 : 0
        
        if completionRate >= completionGoal && streakData.currentStreak == 0 {
            // Started a new streak today
            streakData = StreakData(
                currentStreak: 1,
                longestStreak: max(1, streakData.longestStreak),
                streakGoal: streakData.streakGoal,
                daysUntilGoal: max(0, streakData.streakGoal - 1)
            )
        }
    }
    
    private func calculateAverageTaskTime(for tasks: [ContextualTask]) async -> TimeInterval {
        // This would ideally calculate from actual completion times
        // For now, estimate based on task type
        guard !tasks.isEmpty else { return 0 }
        
        let totalEstimatedTime = tasks.reduce(0.0) { sum, task in
            switch task.category.lowercased() {
            case "cleaning": return sum + 20 * 60 // 20 minutes
            case "maintenance": return sum + 45 * 60 // 45 minutes
            case "inspection": return sum + 15 * 60 // 15 minutes
            default: return sum + 30 * 60 // 30 minutes default
            }
        }
        
        return totalEstimatedTime / Double(tasks.count)
    }
    
    private func calculateOnTimeCompletionRate(_ completedTasks: [ContextualTask]) -> Double {
        guard !completedTasks.isEmpty else { return 0 }
        
        // For now, assume 90% are completed on time
        // This would be calculated from actual completion vs. scheduled times
        return 90.0
    }
    
    private func calculateQualityScore(workerId: String) async -> Double {
        // Quality score based on task completion quality, rework needed, etc.
        // For now, return a base score
        return 85.0
    }
    
    private func calculateProductivityTrend(workerId: String) async -> ProductivityTrend {
        // Compare current week to previous week
        // Simplified implementation
        return .improving
    }
    
    private func calculateImprovementTrend(_ tasks: [ContextualTask]) -> Double {
        // Calculate improvement trend over the month
        // Positive value = improving, negative = declining
        return 5.2 // 5.2% improvement
    }
    
    // MARK: - Goal Management
    func updateGoal(_ newGoal: Double) {
        completionGoal = max(0, min(100, newGoal))
        
        Task {
            // Recalculate streak data with new goal
            if let workerId = authManager.workerId {
                streakData = await calculateStreakData(workerId: workerId)
            }
        }
    }
    
    // MARK: - Computed Properties
    var isOnTrack: Bool {
        return completionStats.completionRate >= (completionGoal / 100.0)
    }
    
    var progressColor: Color {
        let percentage = completionStats.completionRate * 100
        switch percentage {
        case 90...100: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }
    
    var streakStatus: String {
        if streakData.currentStreak >= streakData.streakGoal {
            return "🔥 Goal Achieved!"
        } else if streakData.currentStreak > 0 {
            return "\(streakData.daysUntilGoal) days to goal"
        } else {
            return "Start your streak today!"
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Original Helper Methods (Preserved)
    
    private func parseTime(_ timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0,
                                 minute: components.minute ?? 0,
                                 second: 0,
                                 of: Date())
        }
        
        return nil
    }
    
    private func getUrgencyPriority(_ urgencyLevel: String) -> Int {
        switch urgencyLevel.lowercased() {
        case "urgent": return 4
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 1
        }
    }
    
    private func sortTasks(_ tasks: [ContextualTask]) -> [ContextualTask] {
        var sortedTasks = tasks
        
        sortedTasks.sort { task1, task2 in
            if let time1 = parseTime(task1.startTime),
               let time2 = parseTime(task2.startTime) {
                return time1 < time2
            }
            return getUrgencyPriority(task1.urgencyLevel) > getUrgencyPriority(task2.urgencyLevel)
        }
        
        return sortedTasks
    }
    
    private func sortTasksByUrgency(_ tasks: [ContextualTask]) -> [ContextualTask] {
        var sortedTasks = tasks
        
        sortedTasks.sort { task1, task2 in
            return getUrgencyPriority(task1.urgencyLevel) > getUrgencyPriority(task2.urgencyLevel)
        }
        
        return sortedTasks
    }
    
    private func updateTaskInLocalState(_ taskId: String, newStatus: String) {
        // Update task in morning tasks
        if let index = morningTasks.firstIndex(where: { $0.id == taskId }) {
            morningTasks[index] = morningTasks[index].withUpdatedStatus(newStatus)
        }
        
        // Update task in afternoon tasks
        if let index = afternoonTasks.firstIndex(where: { $0.id == taskId }) {
            afternoonTasks[index] = afternoonTasks[index].withUpdatedStatus(newStatus)
        }
        
        // Update task in all day tasks
        if let index = allDayTasks.firstIndex(where: { $0.id == taskId }) {
            allDayTasks[index] = allDayTasks[index].withUpdatedStatus(newStatus)
        }
    }
    
    private func calculateCompletionStats(tasks: [ContextualTask]) -> TaskCompletionStats {
        let total = tasks.count
        
        var completed = 0
        var urgent = 0
        var pastDue = 0
        
        for task in tasks {
            if task.status == "completed" {
                completed += 1
            }
            
            if task.urgencyLevel.lowercased() == "urgent" && task.status != "completed" {
                urgent += 1
            }
            
            if isTaskPastDue(task) && task.status != "completed" {
                pastDue += 1
            }
        }
        
        return TaskCompletionStats(
            total: total,
            completed: completed,
            remaining: total - completed,
            urgent: urgent,
            pastDue: pastDue,
            completionRate: total > 0 ? Double(completed) / Double(total) : 0
        )
    }
    
    private func isTaskPastDue(_ task: ContextualTask) -> Bool {
        guard let scheduledDate = task.scheduledDate else { return false }
        return Date() > scheduledDate
    }
    
    private func checkRouteOptimization(workerId: String, tasks: [ContextualTask]) async {
        var tasksByBuilding: [String: [ContextualTask]] = [:]
        var buildingIds: Set<String> = Set<String>()
        
        for task in tasks {
            let buildingId = task.buildingId
            buildingIds.insert(buildingId)
            
            if tasksByBuilding[buildingId] == nil {
                tasksByBuilding[buildingId] = []
            }
            tasksByBuilding[buildingId]?.append(task)
        }
        
        if buildingIds.count > 2 {
            self.hasRouteOptimization = true
            self.suggestedRoute = await createOptimizedRoute(
                workerId: workerId,
                tasksByBuilding: tasksByBuilding
            )
        }
    }
    
    private func createOptimizedRoute(
        workerId: String,
        tasksByBuilding: [String: [ContextualTask]]
    ) async -> WorkerDailyRoute {
        
        var stops: [RouteStop] = []
        
        for (buildingId, buildingTasks) in tasksByBuilding {
            // Get building information from BuildingService
            let buildingName = await getBuildingName(buildingId)
            let coordinate = await getBuildingCoordinate(buildingId)
            
            // Calculate estimated duration (30 minutes per task)
            let estimatedDuration = Double(buildingTasks.count) * 1800
            
            // Determine arrival time based on earliest task
            let arrivalTime = getEarliestTaskTime(buildingTasks) ?? Date()
            
            let stop = RouteStop(
                buildingId: buildingId,
                buildingName: buildingName,
                coordinate: coordinate,
                tasks: [], // Empty tasks array to avoid conversion issues
                estimatedDuration: estimatedDuration,
                estimatedTaskDuration: estimatedDuration,
                arrivalTime: arrivalTime,
                departureTime: nil
            )
            
            stops.append(stop)
        }
        
        // Sort stops by arrival time for logical route progression
        var sortedStops = stops
        sortedStops.sort { $0.arrivalTime < $1.arrivalTime }
        
        // Calculate total distance (estimate 500m between buildings)
        let totalDistance = Double(sortedStops.count - 1) * 500
        
        var totalDuration: TimeInterval = 0
        for stop in sortedStops {
            totalDuration += stop.estimatedDuration
        }
        
        return WorkerDailyRoute(
            workerId: workerId,
            date: Date(),
            stops: sortedStops,
            totalDistance: totalDistance,
            estimatedDuration: totalDuration
        )
    }
    
    private func getBuildingName(_ buildingId: String) async -> String {
        do {
            if let building = try await buildingService.getBuilding(buildingId) {
                return building.name
            }
        } catch {
            print("Failed to get building name for \(buildingId): \(error)")
        }
        return "Building \(buildingId)"
    }
    
    private func getBuildingCoordinate(_ buildingId: String) async -> CLLocationCoordinate2D {
        do {
            if let building = try await buildingService.getBuilding(buildingId) {
                return CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )
            }
        } catch {
            print("Failed to get building coordinates for \(buildingId): \(error)")
        }
        // Default NYC coordinates if building not found
        return CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
    }
    
    private func getEarliestTaskTime(_ tasks: [ContextualTask]) -> Date? {
        var earliestTime: Date?
        for task in tasks {
            guard let taskTime = parseTime(task.startTime) else { continue }
            
            if earliestTime == nil || taskTime < earliestTime! {
                earliestTime = taskTime
            }
        }
        return earliestTime
    }
}

// MARK: - Supporting Types

// MARK: - Original Struct (Enhanced)
extension TodayTasksViewModel {
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
}

// MARK: - New Analytics Types
enum Timeframe: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
}

struct DayProgress {
    let date: Date
    let completed: Int
    let total: Int
    let percentage: Double
    let averageTaskTime: TimeInterval
}

struct TaskTrends {
    let completionRate: Double
    let totalTasks: Int
    let completedTasks: Int
    let averageTasksPerDay: Double
    let categoryBreakdown: [CategoryProgress]
    let improvementTrend: Double
    
    init(completionRate: Double = 0, totalTasks: Int = 0, completedTasks: Int = 0, averageTasksPerDay: Double = 0, categoryBreakdown: [CategoryProgress] = [], improvementTrend: Double = 0) {
        self.completionRate = completionRate
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.averageTasksPerDay = averageTasksPerDay
        self.categoryBreakdown = categoryBreakdown
        self.improvementTrend = improvementTrend
    }
}

struct CategoryProgress {
    let category: String
    let completed: Int
    let total: Int
    let percentage: Double
}

struct PerformanceMetrics {
    let efficiency: Double
    let onTimeCompletionRate: Double
    let qualityScore: Double
    let averageTaskDuration: TimeInterval
    let overdueCount: Int
    let productivityTrend: ProductivityTrend
    
    init(efficiency: Double = 0, onTimeCompletionRate: Double = 0, qualityScore: Double = 0, averageTaskDuration: TimeInterval = 0, overdueCount: Int = 0, productivityTrend: ProductivityTrend = .stable) {
        self.efficiency = efficiency
        self.onTimeCompletionRate = onTimeCompletionRate
        self.qualityScore = qualityScore
        self.averageTaskDuration = averageTaskDuration
        self.overdueCount = overdueCount
        self.productivityTrend = productivityTrend
    }
}

enum ProductivityTrend {
    case improving
    case stable
    case declining
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .orange
        case .declining: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
}

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let streakGoal: Int
    let daysUntilGoal: Int
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, streakGoal: Int = 7, daysUntilGoal: Int = 7) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakGoal = streakGoal
        self.daysUntilGoal = daysUntilGoal
    }
}            return StreakData()
        }
    }
    
    private func updateStreakData(workerId: String) async {
        // Quick update after task completion
        let allTasks = morningTasks + afternoonTasks + allDayTasks
        let completionRate = allTasks.count > 0 ? Double(allTasks.filter { $0.status == "completed" }.count) / Double(allTasks.count) * 100 : 0
        
        if completionRate >= completionGoal && streakData.currentStreak == 0 {
            // Started a new streak today
            streakData = StreakData(
                currentStreak: 1,
                longestStreak: max(1, streakData.longestStreak),
                streakGoal: streakData.streakGoal,
                daysUntilGoal: max(0, streakData.streakGoal - 1)
            )
        }
    }
    
    private func calculateAverageTaskTime(for tasks: [ContextualTask]) async -> TimeInterval {
        // This would ideally calculate from actual completion times
        // For now, estimate based on task type
        guard !tasks.isEmpty else { return 0 }
        
        let totalEstimatedTime = tasks.reduce(0.0) { sum, task in
            switch task.category.lowercased() {
            case "cleaning": return sum + 20 * 60 // 20 minutes
            case "maintenance": return sum + 45 * 60 // 45 minutes
            case "inspection": return sum + 15 * 60 // 15 minutes
            default: return sum + 30 * 60 // 30 minutes default
            }
        }
        
        return totalEstimatedTime / Double(tasks.count)
    }
    
    private func calculateOnTimeCompletionRate(_ completedTasks: [ContextualTask]) -> Double {
        guard !completedTasks.isEmpty else { return 0 }
        
        // For now, assume 90% are completed on time
        // This would be calculated from actual completion vs. scheduled times
        return 90.0
    }
    
    private func calculateQualityScore(workerId: String) async -> Double {
        // Quality score based on task completion quality, rework needed, etc.
        // For now, return a base score
        return 85.0
    }
    
    private func calculateProductivityTrend(workerId: String) async -> ProductivityTrend {
        // Compare current week to previous week
        // Simplified implementation
        return .improving
    }
    
    private func calculateImprovementTrend(_ tasks: [ContextualTask]) -> Double {
        // Calculate improvement trend over the month
        // Positive value = improving, negative = declining
        return 5.2 // 5.2% improvement
    }
    
    // MARK: - Goal Management
    func updateGoal(_ newGoal: Double) {
        completionGoal = max(0, min(100, newGoal))
        
        Task {
            // Recalculate streak data with new goal
            if let workerId = authManager.workerId {
                streakData = await calculateStreakData(workerId: workerId)
            }
        }
    }
    
    // MARK: - Computed Properties
    var isOnTrack: Bool {
        return completionStats.completionRate >= (completionGoal / 100.0)
    }
    
    var progressColor: Color {
        let percentage = completionStats.completionRate * 100
        switch percentage {
        case 90...100: return .green
        case 70..<90: return .orange
        default: return .red
        }
    }
    
    var streakStatus: String {
        if streakData.currentStreak >= streakData.streakGoal {
            return "🔥 Goal Achieved!"
        } else if streakData.currentStreak > 0 {
            return "\(streakData.daysUntilGoal) days to goal"
        } else {
            return "Start your streak today!"
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Original Helper Methods (Preserved)
    
    private func parseTime(_ timeString: String?) -> Date? {
        guard let timeString = timeString else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0,
                                 minute: components.minute ?? 0,
                                 second: 0,
                                 of: Date())
        }
        
        return nil
    }
    
    private func getUrgencyPriority(_ urgencyLevel: String) -> Int {
        switch urgencyLevel.lowercased() {
        case "urgent": return 4
        case "high": return 3
        case "medium": return 2
        case "low": return 1
        default: return 1
        }
    }
    
    private func sortTasks(_ tasks: [ContextualTask]) -> [ContextualTask] {
        var sortedTasks = tasks
        
        sortedTasks.sort { task1, task2 in
            if let time1 = parseTime(task1.startTime ?? ""),
               let time2 = parseTime(task2.startTime ?? "") {
                return time1 < time2
            }
            return getUrgencyPriority(task1.urgencyLevel) > getUrgencyPriority(task2.urgencyLevel)
        }
        
        return sortedTasks
    }
    
    private func sortTasksByUrgency(_ tasks: [ContextualTask]) -> [ContextualTask] {
        var sortedTasks = tasks
        
        sortedTasks.sort { task1, task2 in
            return getUrgencyPriority(task1.urgencyLevel) > getUrgencyPriority(task2.urgencyLevel)
        }
        
        return sortedTasks
    }
    
    private func updateTaskInLocalState(_ taskId: String, newStatus: String) {
        // Update task in morning tasks
        if let index = morningTasks.firstIndex(where: { $0.id == taskId }) {
            morningTasks[index] = morningTasks[index].withUpdatedStatus(newStatus)
        }
        
        // Update task in afternoon tasks
        if let index = afternoonTasks.firstIndex(where: { $0.id == taskId }) {
            afternoonTasks[index] = afternoonTasks[index].withUpdatedStatus(newStatus)
        }
        
        // Update task in all day tasks
        if let index = allDayTasks.firstIndex(where: { $0.id == taskId }) {
            allDayTasks[index] = allDayTasks[index].withUpdatedStatus(newStatus)
        }
    }
    
    private func calculateCompletionStats(tasks: [ContextualTask]) -> TaskCompletionStats {
        let total = tasks.count
        
        var completed = 0
        var urgent = 0
        var pastDue = 0
        
        for task in tasks {
            if task.status == "completed" {
                completed += 1
            }
            
            if task.urgencyLevel.lowercased() == "urgent" && task.status != "completed" {
                urgent += 1
            }
            
            if isTaskPastDue(task) && task.status != "completed" {
                pastDue += 1
            }
        }
        
        return TaskCompletionStats(
            total: total,
            completed: completed,
            remaining: total - completed,
            urgent: urgent,
            pastDue: pastDue,
            completionRate: total > 0 ? Double(completed) / Double(total) : 0
        )
    }
    
    private func isTaskPastDue(_ task: ContextualTask) -> Bool {
        guard let scheduledDate = task.scheduledDate else { return false }
        return Date() > scheduledDate
    }
    
    private func checkRouteOptimization(workerId: String, tasks: [ContextualTask]) async {
        var tasksByBuilding: [String: [ContextualTask]] = [:]
        var buildingIds: Set<String> = Set<String>()
        
        for task in tasks {
            let buildingId = task.buildingId
            buildingIds.insert(buildingId)
            
            if tasksByBuilding[buildingId] == nil {
                tasksByBuilding[buildingId] = []
            }
            tasksByBuilding[buildingId]?.append(task)
        }
        
        if buildingIds.count > 2 {
            self.hasRouteOptimization = true
            self.suggestedRoute = await createOptimizedRoute(
                workerId: workerId,
                tasksByBuilding: tasksByBuilding
            )
        }
    }
    
    private func createOptimizedRoute(
        workerId: String,
        tasksByBuilding: [String: [ContextualTask]]
    ) async -> WorkerDailyRoute {
        
        var stops: [RouteStop] = []
        
        for (buildingId, buildingTasks) in tasksByBuilding {
            // Get building information from BuildingService
            let buildingName = await getBuildingName(buildingId)
            let coordinate = await getBuildingCoordinate(buildingId)
            
            // Calculate estimated duration (30 minutes per task)
            let estimatedDuration = Double(buildingTasks.count) * 1800
            
            // Determine arrival time based on earliest task
            let arrivalTime = getEarliestTaskTime(buildingTasks) ?? Date()
            
            let stop = RouteStop(
                buildingId: buildingId,
                buildingName: buildingName,
                coordinate: coordinate,
                tasks: [], // Empty tasks array to avoid conversion issues
                estimatedDuration: estimatedDuration,
                estimatedTaskDuration: estimatedDuration,
                arrivalTime: arrivalTime,
                departureTime: nil
            )
            
            stops.append(stop)
        }
        
        // Sort stops by arrival time for logical route progression
        var sortedStops = stops
        sortedStops.sort { $0.arrivalTime < $1.arrivalTime }
        
        // Calculate total distance (estimate 500m between buildings)
        let totalDistance = Double(sortedStops.count - 1) * 500
        
        var totalDuration: TimeInterval = 0
        for stop in sortedStops {
            totalDuration += stop.estimatedDuration
        }
        
        return WorkerDailyRoute(
            workerId: workerId,
            date: Date(),
            stops: sortedStops,
            totalDistance: totalDistance,
            estimatedDuration: totalDuration
        )
    }
    
    private func getBuildingName(_ buildingId: String) async -> String {
        do {
            if let building = try await buildingService.getBuilding(buildingId) {
                return building.name
            }
        } catch {
            print("Failed to get building name for \(buildingId): \(error)")
        }
        return "Building \(buildingId)"
    }
    
    private func getBuildingCoordinate(_ buildingId: String) async -> CLLocationCoordinate2D {
        do {
            if let building = try await buildingService.getBuilding(buildingId) {
                return CLLocationCoordinate2D(
                    latitude: building.latitude,
                    longitude: building.longitude
                )
            }
        } catch {
            print("Failed to get building coordinates for \(buildingId): \(error)")
        }
        // Default NYC coordinates if building not found
        return CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
    }
    
    private func getEarliestTaskTime(_ tasks: [ContextualTask]) -> Date? {
        var earliestTime: Date?
        for task in tasks {
            guard let startTimeString = task.startTime else { continue }
            guard let taskTime = parseTime(startTimeString) else { continue }
            
            if earliestTime == nil || taskTime < earliestTime! {
                earliestTime = taskTime
            }
        }
        return earliestTime
    }
}

// MARK: - Supporting Types

// MARK: - Original Struct (Enhanced)
extension TodayTasksViewModel {
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
}

// MARK: - New Analytics Types
enum Timeframe: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
}

struct DayProgress {
    let date: Date
    let completed: Int
    let total: Int
    let percentage: Double
    let averageTaskTime: TimeInterval
}

struct TaskTrends {
    let completionRate: Double
    let totalTasks: Int
    let completedTasks: Int
    let averageTasksPerDay: Double
    let categoryBreakdown: [CategoryProgress]
    let improvementTrend: Double
    
    init(completionRate: Double = 0, totalTasks: Int = 0, completedTasks: Int = 0, averageTasksPerDay: Double = 0, categoryBreakdown: [CategoryProgress] = [], improvementTrend: Double = 0) {
        self.completionRate = completionRate
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.averageTasksPerDay = averageTasksPerDay
        self.categoryBreakdown = categoryBreakdown
        self.improvementTrend = improvementTrend
    }
}

struct CategoryProgress {
    let category: String
    let completed: Int
    let total: Int
    let percentage: Double
}

struct PerformanceMetrics {
    let efficiency: Double
    let onTimeCompletionRate: Double
    let qualityScore: Double
    let averageTaskDuration: TimeInterval
    let overdueCount: Int
    let productivityTrend: ProductivityTrend
    
    init(efficiency: Double = 0, onTimeCompletionRate: Double = 0, qualityScore: Double = 0, averageTaskDuration: TimeInterval = 0, overdueCount: Int = 0, productivityTrend: ProductivityTrend = .stable) {
        self.efficiency = efficiency
        self.onTimeCompletionRate = onTimeCompletionRate
        self.qualityScore = qualityScore
        self.averageTaskDuration = averageTaskDuration
        self.overdueCount = overdueCount
        self.productivityTrend = productivityTrend
    }
}

enum ProductivityTrend {
    case improving
    case stable
    case declining
    
    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .orange
        case .declining: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .improving: return "arrow.up.circle.fill"
        case .stable: return "minus.circle.fill"
        case .declining: return "arrow.down.circle.fill"
        }
    }
}

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let streakGoal: Int
    let daysUntilGoal: Int
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, streakGoal: Int = 7, daysUntilGoal: Int = 7) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakGoal = streakGoal
        self.daysUntilGoal = daysUntilGoal
    }
}
