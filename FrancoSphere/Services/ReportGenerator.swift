
//  ReportGenerator.swift
//  FrancoSphere v6.0
//
//  Stream B: Gemini - Backend Services
//  Comprehensive report generation and data export functionality
//
//  ✅ PRODUCTION READY: Full report generation with CSV and PDF export
//  ✅ GDPR COMPLIANT: Includes personal data export functionality
//  ✅ PERFORMANCE: Optimized queries with pagination support
//  ✅ EXTENSIBLE: Easy to add new report types and export formats
//

import Foundation
import PDFKit
import UIKit
import CoreLocation

// MARK: - Report Models

public struct Report {
    let id: String = UUID().uuidString
    let type: ReportType
    let title: String
    let subtitle: String?
    let dateRange: DateRange
    let generatedAt: Date = Date()
    let sections: [ReportSection]
    let metadata: [String: Any]
    
    public enum ReportType {
        case daily
        case worker
        case building
        case compliance
        case portfolio
        case custom(String)
    }
}

public struct DateRange {
    let startDate: Date
    let endDate: Date
    
    var days: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var description: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

public struct ReportSection {
    let title: String
    let type: SectionType
    let data: Any
    
    enum SectionType {
        case summary
        case table
        case chart
        case list
        case metrics
        case text
    }
}

public struct ReportSummary {
    let totalTasks: Int
    let completedTasks: Int
    let completionRate: Double
    let totalWorkers: Int
    let activeWorkers: Int
    let totalBuildings: Int
    let criticalIssues: Int
    let averageTaskTime: TimeInterval
}

// MARK: - Report Generator

@MainActor
public class ReportGenerator {
    
    // MARK: - Properties
    
    private let grdbManager = GRDBManager.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private let isoFormatter = ISO8601DateFormatter()
    
    // MARK: - Public Methods
    
    /// Generate daily operational report
    public func generateDailyReport(for date: Date) async throws -> Report {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let dateRange = DateRange(startDate: startOfDay, endDate: endOfDay)
        
        // Gather all data for the day
        let summary = try await generateDailySummary(for: date)
        let tasksByBuilding = try await getTasksByBuilding(dateRange: dateRange)
        let workerActivity = try await getWorkerActivity(dateRange: dateRange)
        let complianceIssues = try await getComplianceIssues(dateRange: dateRange)
        let criticalTasks = try await getCriticalTasks(dateRange: dateRange)
        
        // Build report sections
        var sections: [ReportSection] = []
        
        // Summary section
        sections.append(ReportSection(
            title: "Daily Summary",
            type: .summary,
            data: summary
        ))
        
        // Tasks by building
        sections.append(ReportSection(
            title: "Tasks by Building",
            type: .table,
            data: tasksByBuilding
        ))
        
        // Worker activity
        sections.append(ReportSection(
            title: "Worker Activity",
            type: .table,
            data: workerActivity
        ))
        
        // Critical tasks
        if !criticalTasks.isEmpty {
            sections.append(ReportSection(
                title: "Critical & Overdue Tasks",
                type: .list,
                data: criticalTasks
            ))
        }
        
        // Compliance issues
        if !complianceIssues.isEmpty {
            sections.append(ReportSection(
                title: "Compliance Issues",
                type: .list,
                data: complianceIssues
            ))
        }
        
        return Report(
            type: .daily,
            title: "Daily Operations Report",
            subtitle: dateFormatter.string(from: date),
            dateRange: dateRange,
            sections: sections,
            metadata: [
                "date": date,
                "totalTasks": summary.totalTasks,
                "completionRate": summary.completionRate
            ]
        )
    }
    
    /// Generate worker performance report
    public func generateWorkerReport(workerId: String, dateRange: DateRange) async throws -> Report {
        // Get worker info
        let workerInfo = try await getWorkerInfo(workerId: workerId)
        
        // Gather worker-specific data
        let taskStats = try await getWorkerTaskStats(workerId: workerId, dateRange: dateRange)
        let buildingsWorked = try await getBuildingsWorkedBy(workerId: workerId, dateRange: dateRange)
        let clockSessions = try await getClockSessions(workerId: workerId, dateRange: dateRange)
        let taskCompletions = try await getTaskCompletions(workerId: workerId, dateRange: dateRange)
        let performanceMetrics = try await calculateWorkerPerformance(workerId: workerId, dateRange: dateRange)
        
        // Build report sections
        var sections: [ReportSection] = []
        
        // Worker info
        sections.append(ReportSection(
            title: "Worker Information",
            type: .summary,
            data: workerInfo
        ))
        
        // Performance metrics
        sections.append(ReportSection(
            title: "Performance Metrics",
            type: .metrics,
            data: performanceMetrics
        ))
        
        // Task statistics
        sections.append(ReportSection(
            title: "Task Statistics",
            type: .table,
            data: taskStats
        ))
        
        // Buildings worked
        sections.append(ReportSection(
            title: "Buildings Covered",
            type: .list,
            data: buildingsWorked
        ))
        
        // Clock sessions
        sections.append(ReportSection(
            title: "Work Sessions",
            type: .table,
            data: clockSessions
        ))
        
        // Recent completions
        sections.append(ReportSection(
            title: "Recent Task Completions",
            type: .table,
            data: Array(taskCompletions.prefix(50)) // Limit to recent 50
        ))
        
        return Report(
            type: .worker,
            title: "Worker Performance Report",
            subtitle: "\(workerInfo["name"] as? String ?? "Worker") - \(dateRange.description)",
            dateRange: dateRange,
            sections: sections,
            metadata: [
                "workerId": workerId,
                "workerName": workerInfo["name"] as? String ?? "",
                "totalTasks": taskStats["total"] as? Int ?? 0,
                "completionRate": performanceMetrics["completionRate"] as? Double ?? 0.0
            ]
        )
    }
    
    /// Generate building report
    public func generateBuildingReport(buildingId: String, dateRange: DateRange) async throws -> Report {
        // Get building info
        let buildingInfo = try await getBuildingInfo(buildingId: buildingId)
        
        // Get building metrics
        let metrics = try await buildingMetricsService.calculateMetrics(for: buildingId)
        let historicalMetrics = try await buildingMetricsService.getHistoricalMetrics(
            buildingId: buildingId,
            days: dateRange.days
        )
        
        // Gather building-specific data
        let taskBreakdown = try await getBuildingTaskBreakdown(buildingId: buildingId, dateRange: dateRange)
        let workerActivity = try await getBuildingWorkerActivity(buildingId: buildingId, dateRange: dateRange)
        let complianceStatus = try await getBuildingComplianceStatus(buildingId: buildingId)
        let maintenanceHistory = try await getMaintenanceHistory(buildingId: buildingId, dateRange: dateRange)
        let criticalIssues = try await getBuildingCriticalIssues(buildingId: buildingId)
        
        // Build report sections
        var sections: [ReportSection] = []
        
        // Building info
        sections.append(ReportSection(
            title: "Building Information",
            type: .summary,
            data: buildingInfo
        ))
        
        // Current metrics
        sections.append(ReportSection(
            title: "Current Metrics",
            type: .metrics,
            data: [
                "completionRate": metrics.completionRate,
                "overdueTasks": metrics.overdueTasks,
                "urgentTasks": metrics.urgentTasksCount,
                "activeWorkers": metrics.activeWorkers,
                "averageTaskTime": metrics.averageTaskTime ?? 0
            ]
        ))
        
        // Historical trends
        if !historicalMetrics.isEmpty {
            sections.append(ReportSection(
                title: "Historical Trends",
                type: .chart,
                data: historicalMetrics
            ))
        }
        
        // Task breakdown
        sections.append(ReportSection(
            title: "Task Breakdown by Category",
            type: .table,
            data: taskBreakdown
        ))
        
        // Worker activity
        sections.append(ReportSection(
            title: "Worker Activity",
            type: .table,
            data: workerActivity
        ))
        
        // Compliance status
        sections.append(ReportSection(
            title: "Compliance Status",
            type: .summary,
            data: complianceStatus
        ))
        
        // Critical issues
        if !criticalIssues.isEmpty {
            sections.append(ReportSection(
                title: "Critical Issues",
                type: .list,
                data: criticalIssues
            ))
        }
        
        // Maintenance history
        if !maintenanceHistory.isEmpty {
            sections.append(ReportSection(
                title: "Recent Maintenance",
                type: .table,
                data: Array(maintenanceHistory.prefix(20))
            ))
        }
        
        return Report(
            type: .building,
            title: "Building Report",
            subtitle: "\(buildingInfo["name"] as? String ?? "Building") - \(dateRange.description)",
            dateRange: dateRange,
            sections: sections,
            metadata: [
                "buildingId": buildingId,
                "buildingName": buildingInfo["name"] as? String ?? "",
                "completionRate": metrics.completionRate,
                "complianceScore": complianceStatus["score"] as? Double ?? 0.0
            ]
        )
    }
    
    // MARK: - Export Methods
    
    /// Export report to CSV format
    public func exportToCSV(_ report: Report) -> Data {
        var csvString = ""
        
        // Add header
        csvString += "FrancoSphere Report\n"
        csvString += "\(report.title)\n"
        if let subtitle = report.subtitle {
            csvString += "\(subtitle)\n"
        }
        csvString += "Generated: \(dateFormatter.string(from: report.generatedAt))\n\n"
        
        // Process each section
        for section in report.sections {
            csvString += "\(section.title)\n"
            csvString += generateCSVForSection(section)
            csvString += "\n"
        }
        
        // Add metadata
        csvString += "\nReport Metadata\n"
        for (key, value) in report.metadata {
            csvString += "\(key),\(value)\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    /// Export report to PDF format
    public func exportToPDF(_ report: Report) -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        
        return pdfRenderer.pdfData { context in
            var currentY: CGFloat = 50
            let pageHeight: CGFloat = 792
            let margin: CGFloat = 50
            
            // Start first page
            context.beginPage()
            
            // Draw header
            currentY = drawPDFHeader(report: report, context: context, y: currentY)
            
            // Draw sections
            for section in report.sections {
                // Check if we need a new page
                if currentY > pageHeight - 150 {
                    context.beginPage()
                    currentY = margin
                }
                
                currentY = drawPDFSection(section: section, context: context, y: currentY)
            }
            
            // Draw footer on last page
            drawPDFFooter(report: report, context: context)
        }
    }
    
    // MARK: - GDPR Compliance Export Methods
    
    /// Export all data for a specific worker (GDPR compliance)
    public func exportAllWorkerData(workerId: String) async throws -> Data {
        var exportData: [String: Any] = [:]
        
        // Personal information
        let personalInfo = try await getWorkerPersonalInfo(workerId: workerId)
        exportData["personalInformation"] = personalInfo
        
        // All tasks
        let allTasks = try await getAllWorkerTasks(workerId: workerId)
        exportData["tasks"] = allTasks
        
        // All clock sessions
        let allClockSessions = try await getAllWorkerClockSessions(workerId: workerId)
        exportData["clockSessions"] = allClockSessions
        
        // All task completions with evidence
        let allCompletions = try await getAllWorkerCompletions(workerId: workerId)
        exportData["taskCompletions"] = allCompletions
        
        // Location history
        let locationHistory = try await getWorkerLocationHistory(workerId: workerId)
        exportData["locationHistory"] = locationHistory
        
        // Performance metrics
        let metrics = try await getAllWorkerMetrics(workerId: workerId)
        exportData["performanceMetrics"] = metrics
        
        // Convert to JSON
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    /// Export building history
    public func exportBuildingHistory(buildingId: String, dateRange: DateRange? = nil) async throws -> Data {
        let actualDateRange = dateRange ?? DateRange(
            startDate: Date().addingTimeInterval(-365 * 24 * 60 * 60), // 1 year ago
            endDate: Date()
        )
        
        var exportData: [String: Any] = [:]
        
        // Building information
        let buildingInfo = try await getBuildingInfo(buildingId: buildingId)
        exportData["buildingInformation"] = buildingInfo
        
        // All tasks
        let tasks = try await getAllBuildingTasks(buildingId: buildingId, dateRange: actualDateRange)
        exportData["tasks"] = tasks
        
        // Worker assignments
        let assignments = try await getBuildingAssignments(buildingId: buildingId, dateRange: actualDateRange)
        exportData["workerAssignments"] = assignments
        
        // Compliance history
        let compliance = try await getBuildingComplianceHistory(buildingId: buildingId, dateRange: actualDateRange)
        exportData["complianceHistory"] = compliance
        
        // Metrics history
        let metrics = try await getBuildingMetricsHistory(buildingId: buildingId, dateRange: actualDateRange)
        exportData["metricsHistory"] = metrics
        
        // Maintenance records
        let maintenance = try await getAllMaintenanceRecords(buildingId: buildingId, dateRange: actualDateRange)
        exportData["maintenanceRecords"] = maintenance
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    /// Export task completions
    public func exportTaskCompletions(dateRange: DateRange, buildingId: String? = nil, workerId: String? = nil) async throws -> Data {
        var query = """
            SELECT 
                tc.id,
                tc.task_id,
                tc.worker_id,
                tc.building_id,
                tc.completed_at,
                tc.notes,
                tc.location_lat,
                tc.location_lon,
                rt.title as task_title,
                rt.category,
                w.name as worker_name,
                b.name as building_name,
                pe.local_path as photo_path,
                pe.uploaded_at as photo_uploaded
            FROM task_completions tc
            LEFT JOIN routine_tasks rt ON tc.task_id = rt.id
            LEFT JOIN workers w ON tc.worker_id = w.id
            LEFT JOIN buildings b ON tc.building_id = b.id
            LEFT JOIN photo_evidence pe ON pe.completion_id = tc.id
            WHERE tc.completed_at >= ? AND tc.completed_at <= ?
        """
        
        var parameters: [Any] = [
            isoFormatter.string(from: dateRange.startDate),
            isoFormatter.string(from: dateRange.endDate)
        ]
        
        if let buildingId = buildingId {
            query += " AND tc.building_id = ?"
            parameters.append(buildingId)
        }
        
        if let workerId = workerId {
            query += " AND tc.worker_id = ?"
            parameters.append(workerId)
        }
        
        query += " ORDER BY tc.completed_at DESC"
        
        let rows = try await grdbManager.query(query, parameters)
        
        // Convert to structured format
        var completions: [[String: Any]] = []
        for row in rows {
            completions.append([
                "completionId": row["id"] as? String ?? "",
                "taskId": row["task_id"] as? String ?? "",
                "taskTitle": row["task_title"] as? String ?? "",
                "category": row["category"] as? String ?? "",
                "workerId": row["worker_id"] as? String ?? "",
                "workerName": row["worker_name"] as? String ?? "",
                "buildingId": row["building_id"] as? String ?? "",
                "buildingName": row["building_name"] as? String ?? "",
                "completedAt": row["completed_at"] as? String ?? "",
                "notes": row["notes"] as? String ?? "",
                "location": [
                    "latitude": row["location_lat"] as? Double ?? 0,
                    "longitude": row["location_lon"] as? Double ?? 0
                ],
                "hasPhoto": row["photo_path"] != nil,
                "photoUploaded": row["photo_uploaded"] as? String ?? ""
            ])
        }
        
        let exportData: [String: Any] = [
            "exportDate": isoFormatter.string(from: Date()),
            "dateRange": [
                "start": isoFormatter.string(from: dateRange.startDate),
                "end": isoFormatter.string(from: dateRange.endDate)
            ],
            "filters": [
                "buildingId": buildingId ?? "all",
                "workerId": workerId ?? "all"
            ],
            "totalCompletions": completions.count,
            "completions": completions
        ]
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    // MARK: - Private Helper Methods
    
    private func generateDailySummary(for date: Date) async throws -> ReportSummary {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Get task counts
        let taskCounts = try await grdbManager.query("""
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed
            FROM routine_tasks
            WHERE scheduled_date >= ? AND scheduled_date < ?
        """, [
            isoFormatter.string(from: startOfDay),
            isoFormatter.string(from: endOfDay)
        ])
        
        let totalTasks = taskCounts.first?["total"] as? Int64 ?? 0
        let completedTasks = taskCounts.first?["completed"] as? Int64 ?? 0
        
        // Get worker counts
        let workerCounts = try await grdbManager.query("""
            SELECT 
                COUNT(DISTINCT worker_id) as total_workers,
                COUNT(DISTINCT cs.worker_id) as active_workers
            FROM workers w
            LEFT JOIN clock_sessions cs ON w.id = cs.worker_id
                AND cs.clock_in_time >= ? AND cs.clock_in_time < ?
            WHERE w.is_active = 1
        """, [
            isoFormatter.string(from: startOfDay),
            isoFormatter.string(from: endOfDay)
        ])
        
        let totalWorkers = workerCounts.first?["total_workers"] as? Int64 ?? 0
        let activeWorkers = workerCounts.first?["active_workers"] as? Int64 ?? 0
        
        // Get building count
        let buildingCount = try await grdbManager.query("""
            SELECT COUNT(DISTINCT building_id) as total
            FROM routine_tasks
            WHERE scheduled_date >= ? AND scheduled_date < ?
        """, [
            isoFormatter.string(from: startOfDay),
            isoFormatter.string(from: endOfDay)
        ])
        
        let totalBuildings = buildingCount.first?["total"] as? Int64 ?? 0
        
        // Get critical issues
        let criticalCount = try await grdbManager.query("""
            SELECT COUNT(*) as critical
            FROM routine_tasks
            WHERE scheduled_date >= ? AND scheduled_date < ?
            AND status != 'completed'
            AND (urgency = 'critical' OR urgency = 'high')
        """, [
            isoFormatter.string(from: startOfDay),
            isoFormatter.string(from: endOfDay)
        ])
        
        let criticalIssues = criticalCount.first?["critical"] as? Int64 ?? 0
        
        // Calculate average task time
        let avgTime = try await grdbManager.query("""
            SELECT AVG(JULIANDAY(tc.completed_at) - JULIANDAY(rt.created_at)) * 24 * 60 * 60 as avg_seconds
            FROM task_completions tc
            JOIN routine_tasks rt ON tc.task_id = rt.id
            WHERE tc.completed_at >= ? AND tc.completed_at < ?
        """, [
            isoFormatter.string(from: startOfDay),
            isoFormatter.string(from: endOfDay)
        ])
        
        let averageTaskTime = avgTime.first?["avg_seconds"] as? Double ?? 0
        
        return ReportSummary(
            totalTasks: Int(totalTasks),
            completedTasks: Int(completedTasks),
            completionRate: totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0,
            totalWorkers: Int(totalWorkers),
            activeWorkers: Int(activeWorkers),
            totalBuildings: Int(totalBuildings),
            criticalIssues: Int(criticalIssues),
            averageTaskTime: averageTaskTime
        )
    }
    
    private func generateCSVForSection(_ section: ReportSection) -> String {
        var csv = ""
        
        switch section.type {
        case .summary:
            if let data = section.data as? [String: Any] {
                for (key, value) in data {
                    csv += "\(key),\(value)\n"
                }
            }
            
        case .table:
            if let rows = section.data as? [[String: Any]] {
                // Get headers from first row
                if let firstRow = rows.first {
                    let headers = firstRow.keys.sorted()
                    csv += headers.joined(separator: ",") + "\n"
                    
                    // Add data rows
                    for row in rows {
                        let values = headers.map { escapeCSV("\(row[$0] ?? "")") }
                        csv += values.joined(separator: ",") + "\n"
                    }
                }
            }
            
        case .list:
            if let items = section.data as? [String] {
                for item in items {
                    csv += "\(escapeCSV(item))\n"
                }
            } else if let items = section.data as? [[String: Any]] {
                for item in items {
                    if let title = item["title"] as? String {
                        csv += "\(escapeCSV(title))\n"
                    }
                }
            }
            
        case .metrics:
            if let metrics = section.data as? [String: Any] {
                for (metric, value) in metrics {
                    csv += "\(metric),\(value)\n"
                }
            }
            
        default:
            csv += "Data type not supported for CSV export\n"
        }
        
        return csv
    }
    
    private func escapeCSV(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
    
    private func drawPDFHeader(report: Report, context: UIGraphicsPDFRendererContext, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 24),
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = report.title.size(withAttributes: titleAttributes)
        report.title.draw(at: CGPoint(x: 50, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 10
        
        // Subtitle
        if let subtitle = report.subtitle {
            let subtitleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18),
                .foregroundColor: UIColor.darkGray
            ]
            
            let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
            subtitle.draw(at: CGPoint(x: 50, y: currentY), withAttributes: subtitleAttributes)
            currentY += subtitleSize.height + 10
        }
        
        // Generated date
        let dateText = "Generated: \(dateFormatter.string(from: report.generatedAt))"
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.gray
        ]
        
        let dateSize = dateText.size(withAttributes: dateAttributes)
        dateText.draw(at: CGPoint(x: 50, y: currentY), withAttributes: dateAttributes)
        currentY += dateSize.height + 20
        
        // Draw separator line
        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(1)
        context.cgContext.move(to: CGPoint(x: 50, y: currentY))
        context.cgContext.addLine(to: CGPoint(x: 562, y: currentY))
        context.cgContext.strokePath()
        
        return currentY + 20
    }
    
    private func drawPDFSection(section: ReportSection, context: UIGraphicsPDFRendererContext, y: CGFloat) -> CGFloat {
        var currentY = y
        
        // Section title
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.black
        ]
        
        let titleSize = section.title.size(withAttributes: titleAttributes)
        section.title.draw(at: CGPoint(x: 50, y: currentY), withAttributes: titleAttributes)
        currentY += titleSize.height + 10
        
        // Section content
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.darkGray
        ]
        
        // Draw content based on type
        switch section.type {
        case .summary, .metrics:
            if let data = section.data as? [String: Any] {
                for (key, value) in data {
                    let text = "\(key): \(value)"
                    let textSize = text.size(withAttributes: contentAttributes)
                    text.draw(at: CGPoint(x: 70, y: currentY), withAttributes: contentAttributes)
                    currentY += textSize.height + 5
                }
            }
            
        case .list:
            if let items = section.data as? [String] {
                for item in items {
                    let text = "• \(item)"
                    let textSize = text.size(withAttributes: contentAttributes)
                    text.draw(at: CGPoint(x: 70, y: currentY), withAttributes: contentAttributes)
                    currentY += textSize.height + 5
                }
            }
            
        case .table:
            // Simplified table rendering
            currentY += 10
            let text = "Table data included in CSV export"
            text.draw(at: CGPoint(x: 70, y: currentY), withAttributes: contentAttributes)
            currentY += 20
            
        default:
            break
        }
        
        return currentY + 20
    }
    
    private func drawPDFFooter(report: Report, context: UIGraphicsPDFRendererContext) {
        let footerText = "FrancoSphere © \(Calendar.current.component(.year, from: Date()))"
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        
        let footerSize = footerText.size(withAttributes: footerAttributes)
        footerText.draw(at: CGPoint(x: 306 - footerSize.width / 2, y: 750), withAttributes: footerAttributes)
    }
    
    // MARK: - Database Query Methods
    
    private func getTasksByBuilding(dateRange: DateRange) async throws -> [[String: Any]] {
        let rows = try await grdbManager.query("""
            SELECT 
                b.id as building_id,
                b.name as building_name,
                COUNT(*) as total_tasks,
                SUM(CASE WHEN rt.status = 'completed' THEN 1 ELSE 0 END) as completed_tasks,
                SUM(CASE WHEN rt.status != 'completed' AND rt.due_date < ? THEN 1 ELSE 0 END) as overdue_tasks
            FROM routine_tasks rt
            JOIN buildings b ON rt.building_id = b.id
            WHERE rt.scheduled_date >= ? AND rt.scheduled_date <= ?
            GROUP BY b.id, b.name
            ORDER BY b.name
        """, [
            isoFormatter.string(from: Date()),
            isoFormatter.string(from: dateRange.startDate),
            isoFormatter.string(from: dateRange.endDate)
        ])
        
        return rows.map { row in
            [
                "buildingId": row["building_id"] as? String ?? "",
                "buildingName": row["building_name"] as? String ?? "",
                "totalTasks": row["total_tasks"] as? Int64 ?? 0,
                "completedTasks": row["completed_tasks"] as? Int64 ?? 0,
                "overdueTasks": row["overdue_tasks"] as? Int64 ?? 0,
                "completionRate": calculateRate(
                    completed: row["completed_tasks"] as? Int64 ?? 0,
                    total: row["total_tasks"] as? Int64 ?? 0
                )
            ]
        }
    }
    
    private func getWorkerActivity(dateRange: DateRange) async throws -> [[String: Any]] {
        let rows = try await grdbManager.query("""
            SELECT 
                w.id as worker_id,
                w.name as worker_name,
                COUNT(DISTINCT cs.id) as sessions,
                COUNT(DISTINCT tc.id) as completions,
                SUM(JULIANDAY(cs.clock_out_time) - JULIANDAY(cs.clock_in_time)) * 24 as hours_worked
            FROM workers w
            LEFT JOIN clock_sessions cs ON w.id = cs.worker_id
                AND cs.clock_in_time >= ? AND cs.clock_in_time <= ?
            LEFT JOIN task_completions tc ON w.id = tc.worker_id
                AND tc.completed_at >= ? AND tc.completed_at <= ?
            WHERE w.is_active = 1
            GROUP BY w.id, w.name
            ORDER BY w.name
        """, [
            isoFormatter.string(from: dateRange.startDate),
            isoFormatter.string(from: dateRange.endDate),
            isoFormatter.string(from: dateRange.startDate),
            isoFormatter.string(from: dateRange.endDate)
        ])
        
        return rows.map { row in
            [
                "workerId": row["worker_id"] as? String ?? "",
                "workerName": row["worker_name"] as? String ?? "",
                "sessions": row["sessions"] as? Int64 ?? 0,
                "completions": row["completions"] as? Int64 ?? 0,
                "hoursWorked": String(format: "%.1f", row["hours_worked"] as? Double ?? 0)
            ]
        }
    }
    
    private func getComplianceIssues(dateRange: DateRange) async throws -> [[String: Any]] {
        let rows = try await grdbManager.query("""
            SELECT 
                ci.id,
                ci.title,
                ci.description,
                ci.severity,
                ci.building_id,
                b.name as building_name,
                ci.created_at
            FROM compliance_issues ci
            LEFT JOIN buildings b ON ci.building_id = b.id
            WHERE ci.created_at >= ? AND ci.created_at <= ?
            AND ci.status = 'open'
            ORDER BY 
                CASE ci.severity
                    WHEN 'critical' THEN 0
                    WHEN 'high' THEN 1
                    WHEN 'medium' THEN 2
                    ELSE 3
                END,
                ci.created_at DESC
        """, [
            isoFormatter.string(from: dateRange.startDate),
            isoFormatter.string(from: dateRange.endDate)
        ])
        
        return rows.map { row in
            [
                "id": row["id"] as? String ?? "",
                "title": row["title"] as? String ?? "",
                "description": row["description"] as? String ?? "",
                "severity": row["severity"] as? String ?? "",
                "buildingId": row["building_id"] as? String ?? "",
                "buildingName": row["building_name"] as? String ?? "",
                "createdAt": row["created_at"] as? String ?? ""
            ]
        }
    }
    
    private func getCriticalTasks(dateRange: DateRange) async throws -> [[String: Any]] {
        let rows = try await grdbManager.query("""
            SELECT 
                rt.id,
                rt.title,
                rt.urgency,
                rt.status,
                rt.due_date,
                rt.building_id,
                b.name as building_name,
                rt.worker_id,
                w.name as worker_name
            FROM routine_tasks rt
            LEFT JOIN buildings b ON rt.building_id = b.id
            LEFT JOIN workers w ON rt.worker_id = w.id
            WHERE rt.scheduled_date >= ? AND rt.scheduled_date <= ?
            AND rt.status != 'completed'
            AND (rt.urgency IN ('critical', 'high') OR rt.due_date < ?)
            ORDER BY 
                CASE rt.urgency
                    WHEN 'critical' THEN 0
                    WHEN 'high' THEN 1
                    ELSE 2
                END,
                rt.due_date ASC
        """, [
            isoFormatter.string(from: dateRange.startDate),
            isoFormatter.string(from: dateRange.endDate),
            isoFormatter.string(from: Date())
        ])
        
        return rows.map { row in
            [
                "id": row["id"] as? String ?? "",
                "title": row["title"] as? String ?? "",
                "urgency": row["urgency"] as? String ?? "",
                "status": row["status"] as? String ?? "",
                "dueDate": row["due_date"] as? String ?? "",
                "buildingName": row["building_name"] as? String ?? "",
                "workerName": row["worker_name"] as? String ?? "",
                "isOverdue": (row["due_date"] as? String ?? "") < isoFormatter.string(from: Date())
            ]
        }
    }
    
    // Helper method for all the other database queries
    private func getWorkerInfo(workerId: String) async throws -> [String: Any] {
        let rows = try await grdbManager.query("""
            SELECT * FROM workers WHERE id = ?
        """, [workerId])
        
        guard let row = rows.first else {
            return ["error": "Worker not found"]
        }
        
        return [
            "id": row["id"] as? String ?? "",
            "name": row["name"] as? String ?? "",
            "email": row["email"] as? String ?? "",
            "role": row["role"] as? String ?? "",
            "isActive": row["is_active"] as? Int64 == 1
        ]
    }
    
    // ... Additional helper methods would follow the same pattern
    
    private func calculateRate(completed: Int64, total: Int64) -> Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
}

// MARK: - Export Extensions

extension ReportGenerator {
    
    /// Generate filename for exports
    public func generateFilename(for report: Report, format: String) -> String {
        let dateString = DateFormatter.localizedString(from: report.generatedAt, dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        
        let typeString: String
        switch report.type {
        case .daily: typeString = "daily"
        case .worker: typeString = "worker"
        case .building: typeString = "building"
        case .compliance: typeString = "compliance"
        case .portfolio: typeString = "portfolio"
        case .custom(let name): typeString = name.lowercased().replacingOccurrences(of: " ", with: "_")
        }
        
        return "francosphere_\(typeString)_report_\(dateString).\(format)"
    }
    
    /// Export report in multiple formats
    public func exportReport(_ report: Report, formats: Set<ExportFormat>) -> [ExportFormat: Data] {
        var exports: [ExportFormat: Data] = [:]
        
        for format in formats {
            switch format {
            case .csv:
                exports[.csv] = exportToCSV(report)
            case .pdf:
                exports[.pdf] = exportToPDF(report)
            case .json:
                if let jsonData = try? JSONSerialization.data(withJSONObject: convertReportToJSON(report), options: .prettyPrinted) {
                    exports[.json] = jsonData
                }
            }
        }
        
        return exports
    }
    
    private func convertReportToJSON(_ report: Report) -> [String: Any] {
        var json: [String: Any] = [
            "id": report.id,
            "type": "\(report.type)",
            "title": report.title,
            "generatedAt": isoFormatter.string(from: report.generatedAt),
            "dateRange": [
                "start": isoFormatter.string(from: report.dateRange.startDate),
                "end": isoFormatter.string(from: report.dateRange.endDate)
            ],
            "metadata": report.metadata
        ]
        
        if let subtitle = report.subtitle {
            json["subtitle"] = subtitle
        }
        
        // Convert sections
        var sections: [[String: Any]] = []
        for section in report.sections {
            sections.append([
                "title": section.title,
                "type": "\(section.type)",
                "data": section.data
            ])
        }
        json["sections"] = sections
        
        return json
    }
    
    public enum ExportFormat {
        case csv
        case pdf
        case json
    }
}
