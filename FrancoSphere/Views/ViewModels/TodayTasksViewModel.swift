//
//  TodayTasksViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Using correct types from SharedTypes.swift and CoreTypes
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
    
    // Using correct types - TaskProgress from CoreTypes, others from SharedTypes
    @Published var progress: TaskProgress?  // This is CoreTypes.TaskProgress (via TypeAlias)
    @Published var taskTrends: TaskTrends?  // This is from SharedTypes.swift
    @Published var performanceMetrics: PerformanceMetrics?  // This is from SharedTypes.swift
    @Published var streakData: StreakData?  // This is from SharedTypes.swift
    
    private let taskService = TaskService.shared
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        print("🔗 TodayTasksViewModel bindings set up")
    }
    
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
                self.completedTasks = todaysTasks.filter { $0.isCompleted }
                self.pendingTasks = todaysTasks.filter { !$0.isCompleted }
                self.overdueTasks = todaysTasks.filter { task in
                    guard let dueDate = task.dueDate else { return false }
                    return !task.isCompleted && dueDate < Date()
                }
                self.updateAnalytics()
            }
        } catch {
            print("❌ Error loading tasks: \(error)")
        }
        
        isLoading = false
    }
    
    private func updateAnalytics() {
        let totalTasks = tasks.count
        let completed = completedTasks.count
        let percentage = totalTasks > 0 ? Double(completed) / Double(totalTasks) * 100 : 0
        
        // ✅ FIXED: Use TaskProgress from CoreTypes (via TypeAlias)
        self.progress = TaskProgress(
            totalTasks: totalTasks,
            completedTasks: completed
        )
        
        // ✅ FIXED: Use PerformanceMetrics from SharedTypes.swift
        self.performanceMetrics = PerformanceMetrics(
            efficiency: percentage / 100.0,  // Convert percentage to decimal
            tasksCompleted: completed,
            averageTime: 3600, // 1 hour default
            qualityScore: 0.85, // 85% quality score
            lastUpdate: Date()
        )
        
        // ✅ FIXED: Use StreakData from SharedTypes.swift
        self.streakData = StreakData(
            currentStreak: calculateCurrentStreak(),
            longestStreak: calculateLongestStreak(),
            lastUpdate: Date()
        )
        
        // ✅ FIXED: Use TaskTrends from SharedTypes.swift
        self.taskTrends = TaskTrends(
            weeklyCompletion: calculateWeeklyCompletionArray(),
            categoryBreakdown: getCategoryBreakdown(),
            changePercentage: calculateChangePercentage(),
            comparisonPeriod: "week",
            trend: determineTrend()  // This uses TrendDirection from CoreTypes
        )
    }
    
    func refreshTasks() async {
        await loadTodaysTasks()
    }
    
    // MARK: - Helper Methods for Analytics
    
    private func calculateCurrentStreak() -> Int {
        // Calculate consecutive days with 100% completion
        // For now, return a placeholder value
        return completedTasks.count == tasks.count && tasks.count > 0 ? 1 : 0
    }
    
    private func calculateLongestStreak() -> Int {
        // Would calculate from historical data
        // For now, return a placeholder value
        return 12
    }
    
    private func calculateWeeklyCompletionArray() -> [Double] {
        // Return array of daily completion rates for the week
        // For now, return placeholder data for 7 days
        let currentRate = Double(completedTasks.count) / Double(max(tasks.count, 1))
        return [0.85, 0.90, 0.88, 0.92, 0.87, 0.91, currentRate]
    }
    
    private func calculateChangePercentage() -> Double {
        // Calculate percentage change from last week
        // For now, return a placeholder value
        let currentRate = Double(completedTasks.count) / Double(max(tasks.count, 1))
        let previousRate = 0.85 // Placeholder for last week's rate
        return ((currentRate - previousRate) / previousRate) * 100
    }
    
    private func getCategoryBreakdown() -> [String: Int] {
        // Group tasks by category
        var breakdown: [String: Int] = [:]
        
        for task in tasks {
            let categoryKey = task.category?.rawValue ?? "other"
            breakdown[categoryKey, default: 0] += 1
        }
        
        return breakdown
    }
    
    private func determineTrend() -> TrendDirection {
        // Determine trend based on completion rate using CoreTypes.TrendDirection
        let completionRate = Double(completedTasks.count) / Double(max(tasks.count, 1))
        
        if completionRate >= 0.9 {
            return .up
        } else if completionRate >= 0.7 {
            return .stable
        } else {
            return .down
        }
    }
}
