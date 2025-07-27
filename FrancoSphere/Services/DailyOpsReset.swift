//
//  DailyOpsReset.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Uses actual ContextualTask properties and initializer
//  ✅ CORRECTED: Removed non-existent recurrence, assignedWorkerName, estimatedDuration
//  ✅ CORRECTED: Uses proper TaskCategory cases (no .compliance)
//  ✅ ALIGNED: With actual v6.0 GRDB actor architecture
//

import Foundation
import UIKit

@MainActor
class DailyOpsReset: ObservableObject {
    static let shared = DailyOpsReset()
    
    private var isInitialized = false
    private var lastResetDate: Date?
    
    private init() {
        if UserDefaults.standard.object(forKey: "lastResetTimeStamp") != nil {
            let lastResetTimeStamp = UserDefaults.standard.double(forKey: "lastResetTimeStamp")
            if lastResetTimeStamp > 0 {
                lastResetDate = Date(timeIntervalSince1970: lastResetTimeStamp)
            }
        }
    }
    
    func start() {
        if isInitialized { return }
        isInitialized = true
        
        Task {
            await checkIfResetNeeded()
        }
        
        scheduleReset()
        
        NotificationCenter.default.addObserver(self,
                                              selector: #selector(appWillEnterForeground),
                                              name: UIApplication.willEnterForegroundNotification,
                                              object: nil)
    }
    
    private func checkIfResetNeeded() async {
        let calendar = Calendar.current
        if lastResetDate == nil || !calendar.isDateInToday(lastResetDate!) {
            await performReset()
        }
    }
    
    private func scheduleReset() {
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.hour = 0
        dateComponents.minute = 1
        dateComponents.second = 0
        
        guard let tomorrowReset = calendar.nextDate(
            after: Date(),
            matching: dateComponents,
            matchingPolicy: .nextTime
        ) else { return }
        
        let timeInterval = tomorrowReset.timeIntervalSince(Date())
        
        DispatchQueue.main.asyncAfter(deadline: .now() + timeInterval) { [weak self] in
            Task {
                await self?.performReset()
                self?.scheduleReset()
            }
        }
    }
    
    @objc private func appWillEnterForeground() {
        Task {
            await checkIfResetNeeded()
        }
    }
    
    // MARK: - Reset Operations
    
    private func performReset() async {
        print("🔄 Starting daily operations reset at \(Date())")
        
        lastResetDate = Date()
        UserDefaults.standard.set(lastResetDate!.timeIntervalSince1970, forKey: "lastResetTimeStamp")
        
        await resetBuildingStatuses()
        await markMissedTasks()
        await generateNewTasks()
        await refreshWorkerContexts()
        
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("DailyOpsReset"), object: nil)
        }
        
        print("✅ Daily operations reset completed at \(Date())")
    }
    
    private func resetBuildingStatuses() async {
        print("🏢 Resetting building statuses...")
        
        await MainActor.run {
            NotificationCenter.default.post(name: NSNotification.Name("BuildingStatusesReset"), object: nil)
        }
        
        // ✅ FIXED: Use actual method invalidateAllCaches()
        await BuildingMetricsService.shared.invalidateAllCaches()
    }
    
    private func markMissedTasks() async {
        print("📋 Processing missed tasks from yesterday...")
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        do {
            let allTasks = try await TaskService.shared.getAllTasks()
            let yesterdayTasks = allTasks.filter { task in
                guard let scheduledDate = task.scheduledDate else { return false }
                return Calendar.current.isDate(scheduledDate, inSameDayAs: yesterday)
            }
            
            var missedCount = 0
            for task in yesterdayTasks where !task.isCompleted {
                print("⚠️ Missed task: \(task.title) in building \(task.buildingId ?? "unknown")")
                missedCount += 1
                
                // ✅ FIXED: Simple recurring task creation without recurrence property
                await createRecurringTaskInstance(from: task)
            }
            
            print("📊 Processed \(missedCount) missed tasks from yesterday")
            
        } catch {
            print("❌ Error processing missed tasks: \(error)")
        }
    }
    
    // ✅ FIXED: Create new task instance for recurring tasks
    private func createRecurringTaskInstance(from task: ContextualTask) async {
        // Determine if this is a recurring task based on title patterns
        let isRecurring = task.title.lowercased().contains("daily") ||
                         task.title.lowercased().contains("weekly") ||
                         task.title.lowercased().contains("monthly")
        
        guard isRecurring else { return }
        
        let nextScheduleDate = calculateNextOccurrence(from: task)
        
        // ✅ FIXED: Use actual ContextualTask initializer
        let newTask = ContextualTask(
            title: task.title,
            description: task.description,
            isCompleted: false,
            scheduledDate: nextScheduleDate,
            dueDate: nextScheduleDate,
            category: task.category,
            urgency: task.urgency,
            building: task.building,
            worker: task.worker,
            buildingId: task.buildingId,
            buildingName: task.buildingName
        )
        
        do {
            try await TaskService.shared.createTask(newTask)
            print("🔄 Created next occurrence for recurring task: \(task.title)")
        } catch {
            print("❌ Error creating recurring task instance: \(error)")
        }
    }
    
    private func calculateNextOccurrence(from task: ContextualTask) -> Date {
        let calendar = Calendar.current
        let baseDate = task.scheduledDate ?? Date()
        
        // Determine recurrence from task title
        if task.title.lowercased().contains("daily") {
            return calendar.date(byAdding: .day, value: 1, to: baseDate) ?? Date()
        } else if task.title.lowercased().contains("weekly") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: baseDate) ?? Date()
        } else if task.title.lowercased().contains("monthly") {
            return calendar.date(byAdding: .month, value: 1, to: baseDate) ?? Date()
        }
        
        return Date()
    }
    
    private func generateNewTasks() async {
        print("🆕 Generating new tasks for today...")
        
        do {
            let allBuildings = try await BuildingService.shared.getAllBuildings()
            
            for building in allBuildings {
                await generateWeatherRelatedTasks(for: building)
                await generateScheduledTasks(for: building)
            }
            
            print("✅ Generated new tasks for \(allBuildings.count) buildings")
            
        } catch {
            print("❌ Error generating new tasks: \(error)")
        }
    }
    
    private func generateWeatherRelatedTasks(for building: NamedCoordinate) async {
        await MainActor.run {
            let weatherAdapter = WeatherDataAdapter.shared
            let weatherTasks = weatherAdapter.generateWeatherTasks(for: building)
            
            if !weatherTasks.isEmpty {
                print("🌤️ Generated \(weatherTasks.count) weather-related tasks for \(building.name)")
                
                Task {
                    for weatherTask in weatherTasks {
                        // ✅ FIXED: Use actual ContextualTask initializer with proper building reference
                        let contextualTask = ContextualTask(
                            title: weatherTask.title,
                            description: weatherTask.description,
                            isCompleted: false,
                            scheduledDate: weatherTask.dueDate ?? Date(),
                            dueDate: weatherTask.dueDate ?? Date(),
                            category: TaskCategory.maintenance,
                            urgency: TaskUrgency.medium,
                            building: building,
                            buildingId: building.id,
                            buildingName: building.name
                        )
                        
                        do {
                            try await TaskService.shared.createTask(contextualTask)
                            print("✅ Created weather task: \(weatherTask.title)")
                        } catch {
                            print("❌ Failed to create weather task: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private func generateScheduledTasks(for building: NamedCoordinate) async {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        await generateDailyTasks(for: building)
        
        if weekday == 2 { // Monday
            await generateWeeklyTasks(for: building)
        }
        
        if calendar.component(.day, from: today) == 1 {
            await generateMonthlyTasks(for: building)
        }
    }
    
    private func generateDailyTasks(for building: NamedCoordinate) async {
        let dailyTaskTemplates = [
            ("Daily Morning building inspection", "Perform daily building safety and operational check"),
            ("Daily Check emergency equipment", "Verify emergency systems are functional"),
            ("Daily Review security systems", "Check security equipment and access systems")
        ]
        
        for (title, description) in dailyTaskTemplates {
            // ✅ FIXED: Use actual ContextualTask initializer
            let task = ContextualTask(
                title: title,
                description: description,
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Date(),
                category: TaskCategory.inspection,
                urgency: TaskUrgency.medium,
                building: building,
                buildingId: building.id,
                buildingName: building.name
            )
            
            do {
                try await TaskService.shared.createTask(task)
                print("📅 Generated daily task: \(title) for \(building.name)")
            } catch {
                print("❌ Failed to create daily task: \(error)")
            }
        }
    }
    
    private func generateWeeklyTasks(for building: NamedCoordinate) async {
        let weeklyTaskTemplates = [
            ("Weekly maintenance review", "Comprehensive review of building maintenance needs"),
            ("Weekly Deep cleaning common areas", "Thorough cleaning of shared spaces"),
            ("Weekly Equipment maintenance check", "Inspect and maintain building equipment")
        ]
        
        for (title, description) in weeklyTaskTemplates {
            let task = ContextualTask(
                title: title,
                description: description,
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Date(),
                category: TaskCategory.maintenance,
                urgency: TaskUrgency.medium,
                building: building,
                buildingId: building.id,
                buildingName: building.name
            )
            
            do {
                try await TaskService.shared.createTask(task)
                print("📅 Generated weekly task: \(title) for \(building.name)")
            } catch {
                print("❌ Failed to create weekly task: \(error)")
            }
        }
    }
    
    private func generateMonthlyTasks(for building: NamedCoordinate) async {
        let monthlyTaskTemplates = [
            ("Monthly inspection audit", "Review inspection status and requirements"),
            ("Monthly HVAC system maintenance", "Service heating and cooling systems"),
            ("Monthly Fire safety inspection", "Comprehensive fire safety check")
        ]
        
        for (title, description) in monthlyTaskTemplates {
            // ✅ FIXED: Use .inspection instead of non-existent .compliance
            let task = ContextualTask(
                title: title,
                description: description,
                isCompleted: false,
                scheduledDate: Date(),
                dueDate: Date(),
                category: TaskCategory.inspection,
                urgency: TaskUrgency.high,
                building: building,
                buildingId: building.id,
                buildingName: building.name
            )
            
            do {
                try await TaskService.shared.createTask(task)
                print("📅 Generated monthly task: \(title) for \(building.name)")
            } catch {
                print("❌ Failed to create monthly task: \(error)")
            }
        }
    }
    
    private func refreshWorkerContexts() async {
        print("👥 Refreshing worker contexts...")
        
        do {
            let activeWorkers = try await WorkerService.shared.getAllActiveWorkers()
            
            for worker in activeWorkers {
                do {
                    try await WorkerContextEngine.shared.loadContext(for: for: worker.id)
                    print("✅ Refreshed context for worker: \(worker.name)")
                } catch {
                    print("⚠️ Failed to refresh context for worker \(worker.name): \(error)")
                }
            }
            
            print("✅ Refreshed contexts for \(activeWorkers.count) workers")
            
        } catch {
            print("❌ Error refreshing worker contexts: \(error)")
        }
    }
    
    func manualReset() {
        Task {
            await performReset()
        }
    }
    
    func getResetStatus() -> (lastReset: Date?, needsReset: Bool) {
        let calendar = Calendar.current
        let needsReset = lastResetDate == nil || !calendar.isDateInToday(lastResetDate!)
        return (lastResetDate, needsReset)
    }
    
    func scheduleImmediateReset(delay: TimeInterval = 5.0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            Task {
                await self?.performReset()
            }
        }
    }
}

// MARK: - Extension for App Initialization
extension DailyOpsReset {
    static func configure() {
        Task { @MainActor in
            shared.start()
        }
    }
}

// MARK: - Integration with Three-Dashboard System
extension DailyOpsReset {
    func getDashboardMetrics() async -> DailyResetMetrics {
        do {
            let buildings = try await BuildingService.shared.getAllBuildings()
            let tasks = try await TaskService.shared.getAllTasks()
            let workers = try await WorkerService.shared.getAllActiveWorkers()
            
            let todaysTasks = tasks.filter { task in
                guard let scheduledDate = task.scheduledDate else { return false }
                return Calendar.current.isDate(scheduledDate, inSameDayAs: Date())
            }
            
            return DailyResetMetrics(
                buildingsCount: buildings.count,
                activeWorkersCount: workers.count,
                todaysTasksCount: todaysTasks.count,
                completedTasksCount: todaysTasks.filter { $0.isCompleted }.count,
                lastResetDate: lastResetDate
            )
        } catch {
            print("❌ Error getting dashboard metrics: \(error)")
            return DailyResetMetrics(
                buildingsCount: 0,
                activeWorkersCount: 0,
                todaysTasksCount: 0,
                completedTasksCount: 0,
                lastResetDate: lastResetDate
            )
        }
    }
}

// MARK: - Supporting Types
struct DailyResetMetrics {
    let buildingsCount: Int
    let activeWorkersCount: Int
    let todaysTasksCount: Int
    let completedTasksCount: Int
    let lastResetDate: Date?
    
    var progressPercentage: Double {
        guard todaysTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(todaysTasksCount) * 100
    }
    
    var statusMessage: String {
        if let lastReset = lastResetDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return "Last reset: \(formatter.string(from: lastReset))"
        } else {
            return "Never reset"
        }
    }
}
