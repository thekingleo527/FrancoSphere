//
//  TodayTasksViewModel.swift (Fixed)
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed duplicate TaskTrends and StreakData definitions
//  ✅ USES: CoreTypes.TaskTrends and CoreTypes.StreakData instead
//  ✅ RESOLVED: Ambiguous type lookup errors
//  ✅ MAINTAINED: All existing functionality
//

import SwiftUI
import Combine

@MainActor
class TodayTasksViewModel: ObservableObject {
    @Published var tasks: [ContextualTask] = []
    @Published var completedTasks: [ContextualTask] = []
    @Published var pendingTasks: [ContextualTask] = []
    @Published var overdueTasks: [ContextualTask] = []
    @Published var isLoading = false
    
    // ✅ FIXED: Use CoreTypes instead of local definitions
    @Published var progress: TaskProgress?
    @Published var taskTrends: CoreTypes.TaskTrends?
    @Published var performanceMetrics: PerformanceMetrics?
    @Published var streakData: CoreTypes.StreakData?
    
    private let taskService = TaskService.shared
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup Methods
    
    private func setupBindings() {
        // Set up any reactive bindings if needed
        print("🔗 TodayTasksViewModel bindings set up")
    }
    
    // MARK: - Main Loading Function
    func loadTodaysTasks() async {
        isLoading = true
        
        let currentUser = await NewAuthManager.shared.getCurrentUser()
        let workerId = currentUser?.workerId ?? ""
        
        guard !workerId.isEmpty else {
            print("⚠️ No valid worker ID found")
            isLoading = false
            return
        }
        
        do {
            let todaysTasks = try await taskService.getTasks(for: workerId, date: Date())
            
            await MainActor.run {
                self.tasks = todaysTasks
                
                // Filter tasks by completion status
                self.completedTasks = todaysTasks.filter { $0.isCompleted }
                self.pendingTasks = todaysTasks.filter { !$0.isCompleted }
                self.overdueTasks = todaysTasks.filter { task in
                    guard let dueDate = task.dueDate else { return false }
                    return !task.isCompleted && dueDate < Date()
                }
                
                // Update analytics
                self.updateAnalytics()
            }
            
        } catch {
            print("❌ Error loading tasks: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Analytics Update
    private func updateAnalytics() {
        // Update task progress
        let totalTasks = tasks.count
        let completed = completedTasks.count
        let percentage = totalTasks > 0 ?
            Double(completed) / Double(totalTasks) * 100 : 0
        
        progress = TaskProgress(
            completedTasks: completed,
            totalTasks: totalTasks,
            progressPercentage: percentage
        )
        
        // Update performance metrics
        performanceMetrics = calculatePerformanceMetrics()
        
        // Update task trends using CoreTypes
        Task {
            taskTrends = await calculateTaskTrends()
        }
        
        // Update streak data using CoreTypes
        streakData = calculateStreakData()
    }
    
    // MARK: - Analytics Calculations
    
    private func calculatePerformanceMetrics() -> PerformanceMetrics {
        let totalTasks = tasks.count
        guard totalTasks > 0 else {
            return PerformanceMetrics(
                efficiency: 0,
                tasksCompleted: 0,
                averageTime: 0,
                qualityScore: 0
            )
        }
        
        let completionRate = Double(completedTasks.count) / Double(totalTasks) * 100
        let efficiency = max(0, completionRate - Double(overdueTasks.count) * 10)
        let averageTime: TimeInterval = 1800 // 30 minutes average
        let qualityScore = efficiency * 0.9
        
        return PerformanceMetrics(
            efficiency: efficiency,
            tasksCompleted: completedTasks.count,
            averageTime: averageTime,
            qualityScore: qualityScore
        )
    }
    
    // ✅ FIXED: Use CoreTypes.TaskTrends
    private func calculateTaskTrends() async -> CoreTypes.TaskTrends {
        // Build category breakdown
        var categoryBreakdown: [String: Int] = [:]
        for task in tasks {
            let category = task.category?.rawValue ?? "Unknown"
            categoryBreakdown[category, default: 0] += 1
        }
        
        // Get real weekly completion data
        let weeklyCompletion = await getWeeklyCompletionData()
        let changePercentage = await calculateRealChangePercentage()
        
        // Determine trend direction
        let trend: CoreTypes.TrendDirection = {
            if changePercentage > 5 {
                return .improving
            } else if changePercentage < -5 {
                return .declining
            } else {
                return .stable
            }
        }()
        
        // ✅ FIXED: Use CoreTypes.TaskTrends constructor
        return CoreTypes.TaskTrends(
            weeklyCompletion: weeklyCompletion,
            categoryBreakdown: categoryBreakdown,
            changePercentage: changePercentage,
            comparisonPeriod: "Previous Week",
            trend: trend
        )
    }
    
    // ✅ FIXED: Use CoreTypes.StreakData
    private func calculateStreakData() -> CoreTypes.StreakData {
        // Calculate task completion streaks
        let currentStreak = calculateCurrentStreak()
        let longestStreak = max(currentStreak, 7) // Default minimum streak
        
        // ✅ FIXED: Use CoreTypes.StreakData constructor
        return CoreTypes.StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastUpdate: Date()
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        // Simple streak calculation based on recent completion rate
        let completionRate = tasks.isEmpty ? 0.0 : Double(completedTasks.count) / Double(tasks.count)
        
        if completionRate >= 0.9 {
            return 5 // High performance streak
        } else if completionRate >= 0.7 {
            return 3 // Good performance streak
        } else {
            return 1 // Minimum streak
        }
    }
    
    // MARK: - Real Data Methods
    
    private func getWeeklyCompletionData() async -> [Double] {
        let calendar = Calendar.current
        var weeklyData: [Double] = []
        
        // Get current user for data retrieval
        guard let currentUser = await NewAuthManager.shared.getCurrentUser() else {
            return Array(repeating: 0.0, count: 7)
        }
        
        for dayOffset in -6...0 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            
            do {
                let dayTasks = try await taskService.getTasks(for: currentUser.workerId, date: date)
                let completionRate = dayTasks.isEmpty ? 0.0 :
                    Double(dayTasks.filter { $0.isCompleted }.count) / Double(dayTasks.count)
                weeklyData.append(completionRate)
            } catch {
                weeklyData.append(0.0)
            }
        }
        
        return weeklyData
    }
    
    private func calculateRealChangePercentage() async -> Double {
        let weeklyData = await getWeeklyCompletionData()
        guard weeklyData.count >= 2 else { return 0.0 }
        
        let currentWeek = weeklyData.suffix(3).reduce(0, +) / 3.0 // Last 3 days
        let previousWeek = weeklyData.prefix(4).reduce(0, +) / 4.0 // Previous 4 days
        
        if previousWeek > 0 {
            return ((currentWeek - previousWeek) / previousWeek) * 100
        }
        
        return 0.0
    }
    
    // MARK: - Task Actions
    
    func completeTask(_ task: ContextualTask) async {
        // Implementation for task completion
        do {
            let evidence = ActionEvidence(
                description: "Task completed via dashboard",
                photoURLs: [],
                timestamp: Date()
            )
            
            try await taskService.completeTask(task.id, evidence: evidence)
            
            // Refresh data
            await loadTodaysTasks()
            
        } catch {
            print("❌ Error completing task: \(error)")
        }
    }
    
    func refreshData() async {
        await loadTodaysTasks()
    }
    
    // MARK: - Helper Methods
    
    func getTasksForCategory(_ category: TaskCategory) -> [ContextualTask] {
        return tasks.filter { $0.category == category }
    }
    
    func getUrgentTasks() -> [ContextualTask] {
        return tasks.filter { task in
            task.urgency == .high || task.urgency == .critical || task.urgency == .emergency
        }
    }
    
    func getTasksForBuilding(_ buildingId: String) -> [ContextualTask] {
        return tasks.filter { $0.buildingId == buildingId }
    }
    
    // MARK: - Analytics Getters
    
    var completionRate: Double {
        guard !tasks.isEmpty else { return 0.0 }
        return Double(completedTasks.count) / Double(tasks.count) * 100
    }
    
    var efficiencyScore: Double {
        return performanceMetrics?.efficiency ?? 0.0
    }
    
    var currentStreak: Int {
        return streakData?.currentStreak ?? 0
    }
}

// MARK: - Supporting Extensions

extension TodayTasksViewModel {
    
    /// Get formatted completion status
    var formattedCompletionStatus: String {
        let completed = completedTasks.count
        let total = tasks.count
        return "\(completed)/\(total) completed"
    }
    
    /// Get efficiency description
    var efficiencyDescription: String {
        let efficiency = efficiencyScore
        switch efficiency {
        case 90...100:
            return "Excellent"
        case 75..<90:
            return "Good"
        case 60..<75:
            return "Fair"
        default:
            return "Needs Improvement"
        }
    }
    
    /// Check if worker is on track for daily goals
    var isOnTrack: Bool {
        return completionRate >= 75.0
    }
}

// ✅ REMOVED: Duplicate TaskTrends and StreakData definitions
// These are now properly referenced from CoreTypes
