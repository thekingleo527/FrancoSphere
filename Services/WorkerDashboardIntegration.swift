//
//  WorkerDashboardIntegration.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//

import SwiftUI
import Foundation

// MARK: - TaskManager Extension for CSV Import
extension TaskManager {
    
    /// Replace hardcoded tasks with real CSV data
    func loadTasksFromCSVData() async {
        // Check if already imported
        let hasImported = await checkIfCSVImported()
        if hasImported {
            print("✅ CSV tasks already imported")
            return
        }
        
        // Use CSVDataImporter to load real tasks
        let importer = CSVDataImporter.shared
        // Remove direct access to sqliteManager - use TaskManager's public interface
        
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
        // Use TaskManager's public methods instead of direct SQLite access
        do {
            // Get all tasks and check for CSV pattern
            let allTasks = await fetchTasksAsync(forWorker: "1", date: Date())
            let csvTasks = allTasks.filter { $0.id.hasPrefix("CSV-") }
            return csvTasks.count > 100 // We expect 120+ tasks
        } catch {
            print("Error checking CSV import status: \(error)")
            return false
        }
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
        await WorkerContextEngine.shared.startAutoRefresh()
    }
    
    /// Ensure CSV data is loaded
    private static func ensureCSVDataLoaded() async {
        // TaskManager will check and load if needed
        await TaskManager.shared.loadTasksFromCSVData() // Added await
    }
}

// MARK: - Time Status Extension for ContextualTask
extension ContextualTask {
    
    var timeStatus: String {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotalMinutes = currentHour * 60 + currentMinute
        
        // Parse task start time
        guard let startTime = startTime else {
            return "upcoming"
        }
        
        let components = startTime.split(separator: ":")
        guard components.count == 2,
              let taskHour = Int(components[0]),
              let taskMinute = Int(components[1]) else {
            return "upcoming"
        }
        
        let taskTotalMinutes = taskHour * 60 + taskMinute
        
        // Check status
        if status == "completed" {
            return "completed"
        }
        
        let difference = taskTotalMinutes - currentTotalMinutes
        
        if difference < -30 {
            // More than 30 minutes late
            return "overdue"
        } else if difference >= -30 && difference <= 30 {
            // Within 30 minute window (in progress)
            return "current"
        } else {
            // Upcoming
            return "upcoming"
        }
    }
}

// MARK: - Helper Functions for WorkerDashboardView Integration

/// Helper to map ContextualTask to MaintenanceTask for UI compatibility
func mapContextualTasksToMaintenanceTasks(_ contextualTasks: [ContextualTask]) -> [MaintenanceTask] {
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
            assignedWorkers: [], // Initialize as empty array
            requiredSkillLevel: task.skillLevel
        )
    }
}

/// Parse time string to Date
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
