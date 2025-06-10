//
//  WorkerDashboardIntegration.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//


//
//  CSVToTaskIntegration.swift
//  FrancoSphere
//
//  Integrates CSVDataImporter with existing TaskManager and WorkerContextEngine
//

import Foundation

// MARK: - TaskManager Extension for CSV Import
extension TaskManager {
    
    /// Replace hardcoded tasks with real CSV data
    private func loadTasksFromCSVData() async {
        // Check if already imported
        let hasImported = await checkIfCSVImported()
        if hasImported {
            print("✅ CSV tasks already imported")
            return
        }
        
        // Use CSVDataImporter to load real tasks
        let importer = CSVDataImporter.shared
        importer.sqliteManager = self.sqliteManager
        
        do {
            let (imported, errors) = try await importer.importRealWorldTasks()
            print("✅ Imported \(imported) real tasks from CSV")
            
            if !errors.isEmpty {
                print("⚠️ Import errors: \(errors)")
            }
            
            // Mark as imported
            await markCSVAsImported()
            
        } catch {
            print("❌ Failed to import CSV tasks: \(error)")
        }
    }
    
    /// Check if CSV has been imported
    private func checkIfCSVImported() async -> Bool {
        guard let sqliteManager = sqliteManager else { return false }
        
        do {
            // Check for a specific external_id pattern from CSVDataImporter
            let results = try await sqliteManager.query("""
                SELECT COUNT(*) as count FROM tasks 
                WHERE external_id LIKE 'CSV-%'
            """, [])
            
            if let row = results.first,
               let count = row["count"] as? Int64 {
                return count > 100 // We expect 120+ tasks
            }
        } catch {
            print("Error checking CSV import status: \(error)")
        }
        
        return false
    }
    
    /// Mark CSV as imported to prevent duplicates
    private func markCSVAsImported() async {
        // This is handled by CSVDataImporter's external_id system
        // No additional action needed
    }
}

// MARK: - WorkerDashboard Integration Helper
struct WorkerDashboardIntegration {
    
    /// Complete setup for WorkerDashboardView
    static func setupDashboard(for workerId: String) async {
        // 1. Ensure CSV data is loaded into TaskManager
        await ensureCSVDataLoaded()
        
        // 2. Load worker context (this pulls from tasks table)
        await WorkerContextEngine.shared.loadWorkerContext(workerId: workerId)
        
        // 3. Start auto-refresh
        WorkerContextEngine.shared.startAutoRefresh()
    }
    
    /// Ensure CSV data is loaded
    private static func ensureCSVDataLoaded() async {
        // TaskManager will check and load if needed
        let _ = await TaskManager.shared.fetchTasksAsync(
            forWorker: "1", // Dummy call to trigger initialization
            date: Date()
        )
    }
}

// MARK: - Updated WorkerDashboardView Integration
// Add this to WorkerDashboardView.swift

/*
struct WorkerDashboardView: View {
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @StateObject private var taskStateManager = TaskStateManager() // From TaskStatusExtension
    
    var body: some View {
        ZStack {
            // Your existing dashboard layout
            
            // Today's Tasks Section using existing component
            TodaysTasksGlassCard(
                tasks: mapContextualTasksToMaintenanceTasks(contextEngine.todaysTasks),
                onTaskTap: { task in
                    // Handle task tap
                }
            )
        }
        .onAppear {
            Task {
                // Setup dashboard with CSV data
                await WorkerDashboardIntegration.setupDashboard(
                    for: currentWorker.id
                )
            }
        }
    }
    
    // Helper to map ContextualTask to MaintenanceTask for UI
    private func mapContextualTasksToMaintenanceTasks(_ contextualTasks: [ContextualTask]) -> [MaintenanceTask] {
        contextualTasks.map { task in
            MaintenanceTask(
                id: task.id,
                name: task.name,
                buildingID: task.buildingId,
                description: "", // Not in ContextualTask
                dueDate: Date(), // Today
                startTime: parseTimeString(task.startTime),
                endTime: parseTimeString(task.endTime),
                category: TaskCategory(rawValue: task.category) ?? .maintenance,
                urgency: TaskUrgency(rawValue: task.urgencyLevel) ?? .medium,
                recurrence: TaskRecurrence(rawValue: task.recurrence) ?? .oneTime,
                isComplete: task.status == "completed",
                assignedWorkers: [contextEngine.currentWorker?.workerId ?? ""]
            )
        }
    }
    
    private func parseTimeString(_ timeStr: String?) -> Date? {
        guard let timeStr = timeStr else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: timeStr) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: components.hour ?? 0,
                               minute: components.minute ?? 0,
                               second: 0,
                               of: Date())
        }
        
        return nil
    }
}
*/

// MARK: - Time Status Extension for ContextualTask
extension ContextualTask {
    
    var timeStatus: TaskTimeStatus {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // Parse task start time
        guard let startTime = startTime else {
            return .allDay
        }
        
        let components = startTime.split(separator: ":")
        guard components.count == 2,
              let taskHour = Int(components[0]),
              let taskMinute = Int(components[1]) else {
            return .allDay
        }
        
        let taskTotalMinutes = taskHour * 60 + taskMinute
        
        // Check status
        if status == "completed" {
            return .completed
        }
        
        let difference = taskTotalMinutes - currentTotalMinutes
        
        if difference < -30 {
            // More than 30 minutes late
            return .overdue(minutesLate: abs(difference))
        } else if difference >= -30 && difference <= 30 {
            // Within 30 minute window (in progress)
            let progress = Double(30 + difference) / 60.0
            return .inProgress(percentComplete: max(0, min(1, progress)))
        } else {
            // Upcoming
            return .upcoming(minutesUntil: difference)
        }
    }
}

enum TaskTimeStatus {
    case upcoming(minutesUntil: Int)
    case inProgress(percentComplete: Double)
    case overdue(minutesLate: Int)
    case completed
    case allDay
    
    var displayColor: Color {
        switch self {
        case .upcoming(let minutes):
            return minutes <= 30 ? .orange : .blue
        case .inProgress:
            return .green
        case .overdue:
            return .red
        case .completed:
            return .gray
        case .allDay:
            return .blue
        }
    }
}