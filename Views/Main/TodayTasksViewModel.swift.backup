//
//  TodayTasksViewModel.swift
//  FrancoSphere v6.0
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
    
    @Published var progress: TaskProgress?
    @Published var taskTrends: TaskTrends?
    @Published var performanceMetrics: PerformanceMetrics?
    @Published var streakData: StreakData?
    
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
        
        // Fix TaskProgress constructor
        self.progress = TaskProgress(
            completedTasks: completed,
            totalTasks: totalTasks,
            progressPercentage: percentage
        )
        
        // Fix PerformanceMetrics constructor
        self.performanceMetrics = PerformanceMetrics(
            completionRate: percentage,
            averageTime: 3600, // 1 hour default
            qualityScore: 85.0
        )
        
        // Fix StreakData constructor
        self.streakData = StreakData(
            currentStreak: 5,
            longestStreak: 12,
            lastCompletionDate: Date()
        )
        
        // Fix TaskTrends constructor
        self.taskTrends = TaskTrends(
            direction: .up,
            changePercent: 15.0,
            period: "week"
        )
    }
    
    func refreshTasks() async {
        await loadTodaysTasks()
    }
}
