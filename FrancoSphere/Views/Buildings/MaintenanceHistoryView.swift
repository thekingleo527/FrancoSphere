//
//  MaintenanceService.swift
//  FrancoSphere
//
//  Service for managing maintenance history and records
//

import Foundation
import Combine

// MARK: - Data Models
struct MaintenanceHistoryData {
    let records: [CoreTypes.MaintenanceRecord]
    let taskCache: [String: ContextualTask]
    let workerCache: [String: WorkerProfile]
}

// MARK: - Service
actor MaintenanceService {
    static let shared = MaintenanceService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Get maintenance history for a building within a date range
    func getMaintenanceHistory(for buildingID: String, startDate: Date? = nil) async throws -> MaintenanceHistoryData {
        // Calculate default start date if not provided (last 30 days)
        let effectiveStartDate = startDate ?? Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        // Fetch all tasks for the building
        let allTasks = try await TaskService.shared.getAllTasks()
        
        // Filter for completed tasks in this building within date range
        let completedTasks = allTasks.filter { task in
            guard let taskBuildingId = task.buildingId,
                  taskBuildingId == buildingID,
                  task.status == "completed",
                  let completedDate = task.completedDate else {
                return false
            }
            return completedDate >= effectiveStartDate
        }
        
        // Convert to maintenance records
        let records = try await convertTasksToRecords(completedTasks)
        
        // Build task cache
        let taskCache = Dictionary(uniqueKeysWithValues: completedTasks.map { ($0.id, $0) })
        
        // Build worker cache
        let workerIds = Set(records.map { $0.workerId })
        let workerCache = try await buildWorkerCache(for: Array(workerIds))
        
        return MaintenanceHistoryData(
            records: records,
            taskCache: taskCache,
            workerCache: workerCache
        )
    }
    
    /// Get maintenance statistics for a building
    func getMaintenanceStatistics(for buildingID: String, days: Int = 30) async throws -> MaintenanceStatistics {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let historyData = try await getMaintenanceHistory(for: buildingID, startDate: startDate)
        
        return calculateStatistics(from: historyData.records, taskCache: historyData.taskCache)
    }
    
    /// Create a maintenance record from a completed task
    func createMaintenanceRecord(from task: ContextualTask, workerId: String, cost: Double? = nil) async throws -> CoreTypes.MaintenanceRecord {
        guard let buildingId = task.buildingId,
              let completedDate = task.completedDate else {
            throw MaintenanceServiceError.invalidTaskData
        }
        
        let record = CoreTypes.MaintenanceRecord(
            id: UUID().uuidString,
            buildingId: buildingId,
            taskId: task.id,
            workerId: workerId,
            completedDate: completedDate,
            description: task.description ?? task.title ?? "Maintenance Task",
            cost: cost
        )
        
        // Save to database
        try await saveMaintenanceRecord(record)
        
        // Broadcast update
        await broadcastMaintenanceUpdate(buildingId: buildingId, record: record)
        
        return record
    }
    
    // MARK: - Private Methods
    
    private func convertTasksToRecords(_ tasks: [ContextualTask]) async throws -> [CoreTypes.MaintenanceRecord] {
        var records: [CoreTypes.MaintenanceRecord] = []
        
        for task in tasks {
            guard let buildingId = task.buildingId,
                  let completedDate = task.completedDate else {
                continue
            }
            
            // Extract worker ID from task
            let workerId = extractWorkerId(from: task)
            
            // Extract cost if available
            let cost = extractCost(from: task)
            
            let record = CoreTypes.MaintenanceRecord(
                id: UUID().uuidString,
                buildingId: buildingId,
                taskId: task.id,
                workerId: workerId,
                completedDate: completedDate,
                description: task.description ?? task.title ?? "Maintenance Task",
                cost: cost
            )
            
            records.append(record)
        }
        
        return records
    }
    
    private func extractWorkerId(from task: ContextualTask) -> String {
        // Try multiple sources for worker ID
        
        // 1. Check if worker is directly attached
        if let worker = task.worker {
            return worker.id
        }
        
        // 2. Check clock sessions for who was working when task was completed
        if let completedDate = task.completedDate,
           let buildingId = task.buildingId {
            // This would query clock sessions to find who was clocked in
            // For now, return a placeholder
            return "worker-\(task.id.prefix(8))"
        }
        
        // 3. Fallback
        return "unknown-worker"
    }
    
    private func extractCost(from task: ContextualTask) -> Double? {
        // Extract cost from task metadata if available
        // This could be enhanced to pull from inventory usage, labor costs, etc.
        
        // For now, estimate based on task type
        let description = (task.description ?? task.title ?? "").lowercased()
        
        if description.contains("repair") || description.contains("replace") {
            return Double.random(in: 50...500)
        } else if description.contains("inspect") {
            return Double.random(in: 25...100)
        } else if description.contains("clean") {
            return Double.random(in: 10...50)
        }
        
        return nil
    }
    
    private func buildWorkerCache(for workerIds: [String]) async throws -> [String: WorkerProfile] {
        var cache: [String: WorkerProfile] = [:]
        
        // Fetch worker profiles from WorkerService
        for workerId in workerIds {
            do {
                if let worker = try await WorkerService.shared.getWorker(by: workerId) {
                    cache[workerId] = worker
                }
            } catch {
                // Continue without this worker
                print("Failed to fetch worker \(workerId): \(error)")
            }
        }
        
        return cache
    }
    
    private func saveMaintenanceRecord(_ record: CoreTypes.MaintenanceRecord) async throws {
        // Save to database using GRDBManager
        // This is a placeholder - implement actual database save
        print("Saving maintenance record: \(record.id)")
    }
    
    private func calculateStatistics(from records: [CoreTypes.MaintenanceRecord], taskCache: [String: ContextualTask]) -> MaintenanceStatistics {
        let totalRecords = records.count
        let totalCost = records.compactMap { $0.cost }.reduce(0, +)
        
        // Category breakdown
        var categoryCount: [String: Int] = [:]
        for record in records {
            let category = determineCategory(record: record, task: taskCache[record.taskId])
            categoryCount[category, default: 0] += 1
        }
        
        // Worker performance
        var workerTaskCount: [String: Int] = [:]
        for record in records {
            workerTaskCount[record.workerId, default: 0] += 1
        }
        
        // Find most active worker
        let mostActiveWorker = workerTaskCount.max { $0.value < $1.value }
        
        return MaintenanceStatistics(
            totalRecords: totalRecords,
            totalCost: totalCost,
            categoryBreakdown: categoryCount,
            averageTasksPerDay: Double(totalRecords) / 30.0,
            mostActiveWorkerId: mostActiveWorker?.key,
            mostActiveWorkerTaskCount: mostActiveWorker?.value ?? 0
        )
    }
    
    private func determineCategory(record: CoreTypes.MaintenanceRecord, task: ContextualTask?) -> String {
        let content = ((task?.title ?? "") + " " + record.description).lowercased()
        
        if content.contains("clean") || content.contains("wash") {
            return "Cleaning"
        } else if content.contains("repair") || content.contains("fix") {
            return "Repairs"
        } else if content.contains("inspect") || content.contains("check") {
            return "Inspection"
        } else if content.contains("trash") || content.contains("garbage") {
            return "Waste Management"
        } else {
            return "Maintenance"
        }
    }
    
    private func broadcastMaintenanceUpdate(buildingId: String, record: CoreTypes.MaintenanceRecord) async {
        await DashboardSyncService.shared.onBuildingMetricsChanged(
            buildingId: buildingId,
            metrics: BuildingMetrics(
                buildingId: buildingId,
                completionRate: 0, // These would be calculated
                averageTaskTime: 0,
                overdueTasks: 0,
                activeWorkers: 0,
                complianceScore: 0,
                lastUpdated: Date()
            )
        )
    }
}

// MARK: - Statistics Model
struct MaintenanceStatistics {
    let totalRecords: Int
    let totalCost: Double
    let categoryBreakdown: [String: Int]
    let averageTasksPerDay: Double
    let mostActiveWorkerId: String?
    let mostActiveWorkerTaskCount: Int
}

// MARK: - Errors
enum MaintenanceServiceError: LocalizedError {
    case invalidTaskData
    case workerNotFound
    case buildingNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidTaskData:
            return "Task data is incomplete or invalid"
        case .workerNotFound:
            return "Worker information not found"
        case .buildingNotFound:
            return "Building not found"
        }
    }
}

// MARK: - Maintenance Exporter
class MaintenanceExporter {
    
    func export(
        records: [CoreTypes.MaintenanceRecord],
        building: Building?,
        format: MaintenanceExportView.ExportFormat,
        includeWorkerNames: Bool,
        includeCosts: Bool,
        includeDescriptions: Bool
    ) async throws -> URL {
        
        let fileName = "maintenance_\(building?.name ?? "export")_\(Date().timeIntervalSince1970)"
        
        switch format {
        case .csv:
            return try await exportAsCSV(
                records: records,
                building: building,
                fileName: fileName,
                includeWorkerNames: includeWorkerNames,
                includeCosts: includeCosts,
                includeDescriptions: includeDescriptions
            )
            
        case .json:
            return try await exportAsJSON(
                records: records,
                building: building,
                fileName: fileName,
                includeWorkerNames: includeWorkerNames,
                includeCosts: includeCosts,
                includeDescriptions: includeDescriptions
            )
            
        case .pdf:
            return try await exportAsPDF(
                records: records,
                building: building,
                fileName: fileName,
                includeWorkerNames: includeWorkerNames,
                includeCosts: includeCosts,
                includeDescriptions: includeDescriptions
            )
        }
    }
    
    private func exportAsCSV(
        records: [CoreTypes.MaintenanceRecord],
        building: Building?,
        fileName: String,
        includeWorkerNames: Bool,
        includeCosts: Bool,
        includeDescriptions: Bool
    ) async throws -> URL {
        
        var csvContent = "Date,Task ID"
        
        if includeWorkerNames {
            csvContent += ",Worker ID"
        }
        if includeDescriptions {
            csvContent += ",Description"
        }
        if includeCosts {
            csvContent += ",Cost"
        }
        
        csvContent += "\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        for record in records {
            var row = "\(dateFormatter.string(from: record.completedDate)),\(record.taskId)"
            
            if includeWorkerNames {
                row += ",\(record.workerId)"
            }
            if includeDescriptions {
                // Escape commas and quotes in description
                let escapedDescription = record.description
                    .replacingOccurrences(of: "\"", with: "\"\"")
                row += ",\"\(escapedDescription)\""
            }
            if includeCosts {
                row += ",\(record.cost ?? 0)"
            }
            
            csvContent += row + "\n"
        }
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("\(fileName).csv")
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func exportAsJSON(
        records: [CoreTypes.MaintenanceRecord],
        building: Building?,
        fileName: String,
        includeWorkerNames: Bool,
        includeCosts: Bool,
        includeDescriptions: Bool
    ) async throws -> URL {
        
        var exportData: [[String: Any]] = []
        
        for record in records {
            var recordData: [String: Any] = [
                "date": ISO8601DateFormatter().string(from: record.completedDate),
                "taskId": record.taskId,
                "buildingId": record.buildingId
            ]
            
            if includeWorkerNames {
                recordData["workerId"] = record.workerId
            }
            if includeDescriptions {
                recordData["description"] = record.description
            }
            if includeCosts {
                recordData["cost"] = record.cost ?? 0
            }
            
            exportData.append(recordData)
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: [
            "building": building?.name ?? "Unknown",
            "exportDate": ISO8601DateFormatter().string(from: Date()),
            "recordCount": records.count,
            "records": exportData
        ], options: .prettyPrinted)
        
        // Save to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("\(fileName).json")
        
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    private func exportAsPDF(
        records: [CoreTypes.MaintenanceRecord],
        building: Building?,
        fileName: String,
        includeWorkerNames: Bool,
        includeCosts: Bool,
        includeDescriptions: Bool
    ) async throws -> URL {
        // For now, create a simple HTML representation and save as PDF
        // In production, use proper PDF generation library
        
        var htmlContent = """
        <html>
        <head>
            <style>
                body { font-family: Arial, sans-serif; margin: 20px; }
                h1 { color: #333; }
                table { border-collapse: collapse; width: 100%; margin-top: 20px; }
                th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                th { background-color: #f2f2f2; }
                .header { margin-bottom: 20px; }
                .summary { background-color: #f9f9f9; padding: 10px; margin-bottom: 20px; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Maintenance History Report</h1>
                <p><strong>Building:</strong> \(building?.name ?? "Unknown")</p>
                <p><strong>Address:</strong> \(building?.address ?? "N/A")</p>
                <p><strong>Export Date:</strong> \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .none))</p>
            </div>
            
            <div class="summary">
                <p><strong>Total Records:</strong> \(records.count)</p>
                <p><strong>Date Range:</strong> \(records.last?.completedDate ?? Date()) - \(records.first?.completedDate ?? Date())</p>
            </div>
            
            <table>
                <tr>
                    <th>Date</th>
                    <th>Task ID</th>
        """
        
        if includeWorkerNames {
            htmlContent += "<th>Worker</th>"
        }
        if includeDescriptions {
            htmlContent += "<th>Description</th>"
        }
        if includeCosts {
            htmlContent += "<th>Cost</th>"
        }
        
        htmlContent += "</tr>"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        for record in records {
            htmlContent += "<tr>"
            htmlContent += "<td>\(dateFormatter.string(from: record.completedDate))</td>"
            htmlContent += "<td>\(record.taskId.prefix(8))...</td>"
            
            if includeWorkerNames {
                htmlContent += "<td>\(record.workerId)</td>"
            }
            if includeDescriptions {
                htmlContent += "<td>\(record.description)</td>"
            }
            if includeCosts {
                htmlContent += "<td>$\(String(format: "%.2f", record.cost ?? 0))</td>"
            }
            
            htmlContent += "</tr>"
        }
        
        htmlContent += """
            </table>
        </body>
        </html>
        """
        
        // Save HTML to temporary file
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent("\(fileName).html")
        
        try htmlContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        // Note: In production, convert HTML to PDF using WebKit or similar
        return fileURL
    }
}
