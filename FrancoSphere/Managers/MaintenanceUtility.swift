import Foundation
import SwiftUI

// MARK: - Legacy Models (File Scope)

// Renamed from MaintenanceRecord to FSLegacyMaintenanceRecord to avoid conflicts
struct FSLegacyMaintenanceRecord: Identifiable, Codable, Hashable {
    let id: String
    let taskId: String
    let taskName: String
    let buildingID: String
    let completionDate: Date
    let workerName: String
    let notes: String?
    
    // Add conversion method to FrancoSphere.MaintenanceRecord
    func toFrancoSphereRecord() -> FrancoSphere.MaintenanceRecord {
        return FrancoSphere.MaintenanceRecord(
            id: id,
            taskId: taskId,
            buildingID: buildingID,
            workerId: "", // Need to determine worker ID from name if possible
            completionDate: completionDate,
            notes: notes,
            taskName: taskName,
            completedBy: workerName
        )
    }
    
    // Add conversion from FrancoSphere.MaintenanceRecord
    static func fromFrancoSphereRecord(_ record: FrancoSphere.MaintenanceRecord) -> FSLegacyMaintenanceRecord {
        return FSLegacyMaintenanceRecord(
            id: record.id,
            taskId: record.taskId,
            taskName: record.taskName,
            buildingID: record.buildingID,
            completionDate: record.completionDate,
            workerName: record.completedBy,
            notes: record.notes
        )
    }
}

// MARK: - TaskManager Extensions (File Scope)

extension TaskManager {
    // Convert and return legacy maintenance records
    func fetchMaintenanceHistory(forBuilding buildingId: String) -> [FSLegacyMaintenanceRecord] {
        // This would normally fetch from your database - for now using sample data
        let records = self.fetchFrancoSphereRecords(forBuilding: buildingId)
        return records.map { FSLegacyMaintenanceRecord.fromFrancoSphereRecord($0) }
    }
    
    // Helper method to fetch FrancoSphere records
    private func fetchFrancoSphereRecords(forBuilding buildingId: String) -> [FrancoSphere.MaintenanceRecord] {
        // This is a placeholder implementation
        return []
    }
}

// MARK: - Main Utility Class

class MaintenanceUtility {
    /// Generate a maintenance report for a building
    /// - Parameters:
    ///   - buildingId: The building ID
    ///   - startDate: Start date for the report
    ///   - endDate: End date for the report
    /// - Returns: A maintenance report
    static func generateMaintenanceReport(buildingId: String, startDate: Date, endDate: Date) -> MaintenanceReport {
        let taskManager = TaskManager.shared
        let maintenanceHistory = taskManager.fetchMaintenanceHistory(forBuilding: buildingId)
        let filteredHistory = maintenanceHistory.filter {
            $0.completionDate >= startDate && $0.completionDate <= endDate
        }
        
        // Count tasks by category
        var tasksByCategory: [FrancoSphere.TaskCategory: Int] = [:]
        for category in FrancoSphere.TaskCategory.allCases {
            tasksByCategory[category] = 0
        }
        
        // Calculate statistics
        let totalTasks = filteredHistory.count
        let averageCompletionTime: TimeInterval = 0 // Placeholder; add actual calculation if needed
        
        // Get upcoming tasks - using the existing fetchTasks method directly
        let upcomingTasks = taskManager.fetchTasks(forBuilding: buildingId)
        
        // Count pending tasks
        let pendingTaskCount = upcomingTasks.filter { !$0.isComplete }.count
        
        return MaintenanceReport(
            buildingId: buildingId,
            startDate: startDate,
            endDate: endDate,
            completedTasks: filteredHistory,
            taskCount: totalTasks,
            tasksByCategory: tasksByCategory,
            averageCompletionTime: averageCompletionTime,
            pendingTaskCount: pendingTaskCount
        )
    }
    
    /// Generate maintenance recommendations for a building
    /// - Parameter buildingId: The building ID
    /// - Returns: Recommended maintenance tasks
    static func generateMaintenanceRecommendations(buildingId: String) -> [MaintenanceRecommendation] {
        var recommendations: [MaintenanceRecommendation] = []
        
        // Get maintenance history
        let taskManager = TaskManager.shared
        let history = taskManager.fetchMaintenanceHistory(forBuilding: buildingId)
        
        // Check for HVAC maintenance
        let calendar = Calendar.current
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: Date())!
        let hvacMaintenance = history.first {
            $0.taskName.contains("HVAC") && $0.completionDate > threeMonthsAgo
        }
        
        if hvacMaintenance == nil {
            recommendations.append(
                MaintenanceRecommendation(
                    title: "HVAC System Maintenance",
                    description: "It's been over 3 months since the last HVAC maintenance.",
                    priority: FrancoSphere.TaskUrgency.medium,
                    category: FrancoSphere.TaskCategory.maintenance,
                    suggestedTimeframe: "Within 2 weeks"
                )
            )
        }
        
        // Check for regular inspections
        let oneMonthAgo = calendar.date(byAdding: .month, value: -1, to: Date())!
        let recentInspection = history.first {
            $0.taskName.contains("Inspection") && $0.completionDate > oneMonthAgo
        }
        
        if recentInspection == nil {
            recommendations.append(
                MaintenanceRecommendation(
                    title: "General Building Inspection",
                    description: "Monthly building inspection recommended.",
                    priority: FrancoSphere.TaskUrgency.medium,
                    category: FrancoSphere.TaskCategory.inspection,
                    suggestedTimeframe: "Within 1 week"
                )
            )
        }
        
        // Check for preventive maintenance
        let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: Date())!
        let plumbingCheck = history.first {
            $0.taskName.contains("Plumbing") && $0.completionDate > sixMonthsAgo
        }
        
        if plumbingCheck == nil {
            recommendations.append(
                MaintenanceRecommendation(
                    title: "Plumbing System Check",
                    description: "Preventive plumbing system inspection recommended.",
                    priority: FrancoSphere.TaskUrgency.low,
                    category: FrancoSphere.TaskCategory.maintenance,
                    suggestedTimeframe: "Within 1 month"
                )
            )
        }
        
        // Add seasonal recommendations
        let currentMonth = calendar.component(.month, from: Date())
        if currentMonth >= 9 && currentMonth <= 11 { // Fall
            recommendations.append(
                MaintenanceRecommendation(
                    title: "Fall Weather Preparation",
                    description: "Check gutters, downspouts, and inspect roof before winter.",
                    priority: FrancoSphere.TaskUrgency.medium,
                    category: FrancoSphere.TaskCategory.maintenance,
                    suggestedTimeframe: "Within 3 weeks"
                )
            )
        } else if currentMonth >= 3 && currentMonth <= 5 { // Spring
            recommendations.append(
                MaintenanceRecommendation(
                    title: "Spring Maintenance",
                    description: "Inspect exterior after winter, check for water damage.",
                    priority: FrancoSphere.TaskUrgency.medium,
                    category: FrancoSphere.TaskCategory.inspection,
                    suggestedTimeframe: "Within 3 weeks"
                )
            )
        }
        
        return recommendations
    }
    
    /// Calculate maintenance efficiency for a building
    /// - Parameter buildingId: The building ID
    /// - Returns: Efficiency metrics
    static func calculateMaintenanceEfficiency(buildingId: String) -> MaintenanceEfficiency {
        let taskManager = TaskManager.shared
        
        // Get all tasks - using the existing fetchTasks method directly
        let allTasks = taskManager.fetchTasks(forBuilding: buildingId, includePastTasks: true)
        let completedTasks = allTasks.filter { $0.isComplete }
        
        // Calculate completion rate
        let completionRate = completedTasks.count > 0 ?
            Double(completedTasks.count) / Double(allTasks.count) : 0
        
        // Calculate on-time completion rate
        var onTimeCount = 0
        for task in completedTasks {
            if let endTime = task.endTime, endTime <= task.dueDate {
                onTimeCount += 1
            }
        }
        let onTimeRate = completedTasks.count > 0 ?
            Double(onTimeCount) / Double(completedTasks.count) : 0
        
        return MaintenanceEfficiency(
            completionRate: completionRate,
            onTimeCompletionRate: onTimeRate,
            averageDaysToComplete: 3.2, // Placeholder
            costEfficiency: 0.85, // Placeholder
            workerProductivity: 0.78 // Placeholder
        )
    }
    
    // MARK: - Maintenance Report Models
    
    /// Represents a maintenance report for a building
    struct MaintenanceReport {
        let buildingId: String
        let startDate: Date
        let endDate: Date
        let completedTasks: [FSLegacyMaintenanceRecord]
        let taskCount: Int
        let tasksByCategory: [FrancoSphere.TaskCategory: Int]
        let averageCompletionTime: TimeInterval
        let pendingTaskCount: Int
        
        var dateRange: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: startDate)) to \(formatter.string(from: endDate))"
        }
    }
    
    /// Represents a maintenance recommendation
    struct MaintenanceRecommendation {
        let id = UUID().uuidString
        let title: String
        let description: String
        let priority: FrancoSphere.TaskUrgency
        let category: FrancoSphere.TaskCategory
        let suggestedTimeframe: String
        
        var priorityLabel: String {
            switch priority {
            case .low: return "Low Priority"
            case .medium: return "Medium Priority"
            case .high: return "High Priority"
            case .urgent: return "Urgent"
            }
        }
    }
    
    /// Represents maintenance efficiency metrics
    struct MaintenanceEfficiency {
        let completionRate: Double
        let onTimeCompletionRate: Double
        let averageDaysToComplete: Double
        let costEfficiency: Double
        let workerProductivity: Double
        
        var completionPercentage: String {
            return "\(Int(completionRate * 100))%"
        }
        
        var onTimePercentage: String {
            return "\(Int(onTimeCompletionRate * 100))%"
        }
        
        var costEfficiencyPercentage: String {
            return "\(Int(costEfficiency * 100))%"
        }
        
        var productivityPercentage: String {
            return "\(Int(workerProductivity * 100))%"
        }
    }
}
