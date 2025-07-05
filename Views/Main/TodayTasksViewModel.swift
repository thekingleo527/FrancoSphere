//
//  TodayTasksViewModel.swift
//  FrancoSphere
//
//  🔧 FIXED: Optional binding errors with NewAuthManager.workerId
//  ✅ Changed from guard let to direct String access and empty check
//  ✅ Uses proper error handling for empty workerId
//

import SwiftUI
import Combine

@MainActor
class TodayTasksViewModel: ObservableObject {
    @Published var tasks: [ContextualTask] = []
    @Published var completedTasks: [ContextualTask] = []
    @Published var pendingTasks: [ContextualTask] = []
    @Published var isLoading = false
    @Published var progress: FrancoSphere.TaskProgress = FrancoSphere.TaskProgress(
        completed: 0,
        total: 0,
        remaining: 0,
        percentage: 0,
        overdueTasks: 0
    )
    @Published var taskTrends: FrancoSphere.TaskTrends = FrancoSphere.TaskTrends(
        weeklyCompletion: [],
        categoryBreakdown: [],
        trend: .stable
    )
    @Published var performanceMetrics: FrancoSphere.PerformanceMetrics = FrancoSphere.PerformanceMetrics(
        efficiency: 0,
        quality: 0,
        speed: 0,
        consistency: 0
    )
    @Published var streakData: FrancoSphere.StreakData = FrancoSphere.StreakData(
        currentStreak: 0,
        longestStreak: 0
    )
    
    private let taskService = TaskService.shared
    private let contextEngine = WorkerContextEngine.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    func loadTodaysTasks() async {
        isLoading = true
        
        // FIXED: Use direct access to workerId (String) and check for empty
        let workerId = NewAuthManager.shared.workerId
        guard !workerId.isEmpty else {
            isLoading = false
            return
        }
        
        do {
            let todaysTasks = try await taskService.getTasks(for: workerId, date: Date())
            let taskProgress = try await taskService.getTaskProgress(for: workerId)
            
            await MainActor.run {
                self.tasks = todaysTasks
                self.completedTasks = todaysTasks.filter { $0.status == "completed" }
                self.pendingTasks = todaysTasks.filter { $0.status == "pending" }
                self.progress = taskProgress
            }
            
        } catch {
            print("Error loading tasks: \(error)")
        }
        
        isLoading = false
    }
    
    func completeTask(_ task: ContextualTask) async {
        // FIXED: Use direct access to workerId (String) and check for empty
        let workerId = NewAuthManager.shared.workerId
        guard !workerId.isEmpty else { return }
        
        do {
            try await taskService.completeTask(
                task.id,
                workerId: workerId,
                buildingId: task.buildingId,
                evidence: nil
            )
            
            await loadTodaysTasks()
            
        } catch {
            print("Error completing task: \(error)")
        }
    }
    
    private func setupBindings() {
        contextEngine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.loadTodaysTasks()
                }
            }
            .store(in: &cancellables)
    }
    
    private func calculateStreakData() -> FrancoSphere.StreakData {
        let currentStreak = calculateCurrentStreak()
        let longestStreak = calculateLongestStreak()
        
        return FrancoSphere.StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastCompletionDate: completedTasks.last?.completedAt
        )
    }
    
    private func calculateCurrentStreak() -> Int {
        return completedTasks.count
    }
    
    private func calculateLongestStreak() -> Int {
        return max(completedTasks.count, 0)
    }
    
    private func calculatePerformanceMetrics() -> FrancoSphere.PerformanceMetrics {
        let efficiency = Double(completedTasks.count) / max(Double(tasks.count), 1.0)
        
        return FrancoSphere.PerformanceMetrics(
            efficiency: efficiency * 100,
            quality: 85.0,
            speed: 75.0,
            consistency: 90.0
        )
    }
    
    private func calculateTaskTrends() -> FrancoSphere.TaskTrends {
        let weeklyProgress = (0..<7).map { dayOffset in
            FrancoSphere.DayProgress(
                date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: Date()) ?? Date(),
                completed: Int.random(in: 5...15),
                total: Int.random(in: 15...25),
                percentage: Double.random(in: 60...95)
            )
        }
        
        let categoryBreakdown = [
            FrancoSphere.CategoryProgress(category: "Cleaning", completed: 8, total: 10, percentage: 80),
            FrancoSphere.CategoryProgress(category: "Maintenance", completed: 5, total: 8, percentage: 62.5),
            FrancoSphere.CategoryProgress(category: "Inspection", completed: 3, total: 3, percentage: 100)
        ]
        
        return FrancoSphere.TaskTrends(
            weeklyCompletion: weeklyProgress,
            categoryBreakdown: categoryBreakdown,
            trend: .improving
        )
    }
}
