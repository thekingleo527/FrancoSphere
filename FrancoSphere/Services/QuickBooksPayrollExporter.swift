//
//  QuickBooksPayrollExporter.swift
//  FrancoSphere
//
//  ✅ V6.0 GRDB MIGRATION: Uses EXISTING types, no duplications
//  ✅ PRESERVED: All original business logic for payroll, overtime, and employee sync
//  ✅ INTEGRATION: Uses existing QuickBooksCredentials, SecurityError, QBConnectionStatus
//  ✅ THREE-DASHBOARD: Compatible with Worker/Admin/Client dashboard system
//

import Foundation
import Combine
import GRDB

// MARK: - Payroll-Specific Types (NOT redefined elsewhere)

public struct PayPeriod {
    public let startDate: Date
    public let endDate: Date
    
    public init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

public struct QBExportProgress {
    public var status = "Idle"
    public var totalEntries = 0
    public var processedEntries = 0
    public var totalWorkers = 0
    public var processedWorkers = 0
    public var progress: Double = 0.0
    
    public init(status: String = "Idle") {
        self.status = status
    }
}

public struct ExportStats: Codable {
    public var totalExports = 0
    public var totalEntriesExported = 0
    public var totalWorkersProcessed = 0
    public var lastExportDate: Date?
    
    public init() {}
}

public struct TimeClockEntry {
    public let id: String
    public let workerId: String
    public let clockInTime: Date
    public let clockOutTime: Date?
    public let buildingId: String?
    public let notes: String?
    
    public init(id: String, workerId: String, clockInTime: Date, clockOutTime: Date?, buildingId: String? = nil, notes: String? = nil) {
        self.id = id
        self.workerId = workerId
        self.clockInTime = clockInTime
        self.clockOutTime = clockOutTime
        self.buildingId = buildingId
        self.notes = notes
    }
}

public struct PayrollExportRecord {
    public let exportId: String
    public let payPeriodStart: Date
    public let payPeriodEnd: Date
    public let exportDate: Date
    public let totalEntries: Int
    public let totalWorkers: Int
    public let exportStatus: String
    public let errorMessage: String?
    
    public init(exportId: String, payPeriodStart: Date, payPeriodEnd: Date, exportDate: Date, totalEntries: Int, totalWorkers: Int, exportStatus: String, errorMessage: String?) {
        self.exportId = exportId
        self.payPeriodStart = payPeriodStart
        self.payPeriodEnd = payPeriodEnd
        self.exportDate = exportDate
        self.totalEntries = totalEntries
        self.totalWorkers = totalWorkers
        self.exportStatus = exportStatus
        self.errorMessage = errorMessage
    }
}

public struct WorkerPayrollSummary {
    public let workerId: String
    public let workerName: String
    public let totalEntries: Int
    public let totalHours: Double
    public let regularHours: Double
    public let overtimeHours: Double
    
    public init(workerId: String, workerName: String, totalEntries: Int, totalHours: Double, regularHours: Double, overtimeHours: Double) {
        self.workerId = workerId
        self.workerName = workerName
        self.totalEntries = totalEntries
        self.totalHours = totalHours
        self.regularHours = regularHours
        self.overtimeHours = overtimeHours
    }
}

public struct PayrollComplianceSummary {
    public let payPeriod: PayPeriod
    public let totalWorkers: Int
    public let totalHours: Double
    public let totalOvertimeHours: Double
    public let exportStatus: String
    public let complianceIssues: [String]
    
    public init(payPeriod: PayPeriod, totalWorkers: Int, totalHours: Double, totalOvertimeHours: Double, exportStatus: String, complianceIssues: [String]) {
        self.payPeriod = payPeriod
        self.totalWorkers = totalWorkers
        self.totalHours = totalHours
        self.totalOvertimeHours = totalOvertimeHours
        self.exportStatus = exportStatus
        self.complianceIssues = complianceIssues
    }
}

public struct QBEmployee {
    public let id: String
    public let name: String
    public let email: String?
    
    public init(id: String, name: String, email: String?) {
        self.id = id
        self.name = name
        self.email = email
    }
}

public struct QBTimeEntry {
    public let employeeId: String
    public let regularHours: Double
    public let overtimeHours: Double
    public let payPeriodStart: Date
    public let payPeriodEnd: Date
    
    public init(employeeId: String, regularHours: Double, overtimeHours: Double, payPeriodStart: Date, payPeriodEnd: Date) {
        self.employeeId = employeeId
        self.regularHours = regularHours
        self.overtimeHours = overtimeHours
        self.payPeriodStart = payPeriodStart
        self.payPeriodEnd = payPeriodEnd
    }
}

public enum PayrollExportError: LocalizedError {
    case notAuthenticated
    case noCurrentPayPeriod
    case noTimeEntries
    case workerNotMapped(String)
    case exportFailed(String)
    case exportInProgress
    case databaseError(String)
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "QuickBooks authentication required"
        case .noCurrentPayPeriod:
            return "No current pay period found"
        case .noTimeEntries:
            return "No time entries found for the selected period"
        case .workerNotMapped(let workerId):
            return "Worker \(workerId) is not mapped to a QuickBooks employee"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        case .exportInProgress:
            return "An export is already in progress"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .apiError(let message):
            return "QuickBooks API error: \(message)"
        }
    }
}

// MARK: - QuickBooks Payroll Exporter Actor

public actor QuickBooksPayrollExporter {
    
    public static let shared = QuickBooksPayrollExporter()
    
    // MARK: - Internal State
    private(set) var exportProgress = QBExportProgress()
    private(set) var isExporting = false
    private(set) var lastExportDate: Date?
    private(set) var exportError: PayrollExportError?
    private(set) var employeeMapping: [String: String] = [:]
    private(set) var currentPayPeriod: PayPeriod?
    private(set) var exportStats = ExportStats()
    
    // MARK: - Dependencies
    private let oauthManager = QuickBooksOAuthManager.shared
    private let securityManager = SecurityManager.shared
    private let grdbManager = GRDBManager.shared
    
    // MARK: - Configuration
    private let overtimeThreshold: Double = 8.0
    
    private init() {
        loadEmployeeMapping()
        loadExportStats()
        calculateCurrentPayPeriod()
    }
    
    // MARK: - Public API
    
    public func getCurrentState() -> (isExporting: Bool, progress: QBExportProgress, error: Error?) {
        return (self.isExporting, self.exportProgress, self.exportError)
    }
    
    public func exportWorkerPayPeriod(workerId: String) async throws {
        guard let payPeriod = currentPayPeriod else {
            throw PayrollExportError.noCurrentPayPeriod
        }
        try await exportPayPeriodForWorker(payPeriod, workerId: workerId)
    }
    
    public func exportCurrentPayPeriod() async throws {
        guard let payPeriod = currentPayPeriod else {
            throw PayrollExportError.noCurrentPayPeriod
        }
        try await exportPayPeriod(payPeriod)
    }
    
    public func getPayrollComplianceSummary() async throws -> PayrollComplianceSummary {
        guard let payPeriod = currentPayPeriod else {
            throw PayrollExportError.noCurrentPayPeriod
        }
        
        let workerSummaries = try await getWorkerPayrollSummary(for: payPeriod)
        let exportHistory = try await getExportHistory(from: payPeriod.startDate, to: payPeriod.endDate)
        
        return PayrollComplianceSummary(
            payPeriod: payPeriod,
            totalWorkers: workerSummaries.count,
            totalHours: workerSummaries.reduce(0) { $0 + $1.totalHours },
            totalOvertimeHours: workerSummaries.reduce(0) { $0 + $1.overtimeHours },
            exportStatus: exportHistory.last?.exportStatus ?? "pending",
            complianceIssues: []
        )
    }
    
    public func exportPayPeriod(_ payPeriod: PayPeriod) async throws {
        guard !isExporting else { throw PayrollExportError.exportInProgress }
        
        self.isExporting = true
        self.exportError = nil
        self.exportProgress = QBExportProgress(status: "Starting export...")
        
        defer {
            self.isExporting = false
        }
        
        do {
            let timeEntries = try await getTimeEntriesForPayPeriod(payPeriod)
            guard !timeEntries.isEmpty else { throw PayrollExportError.noTimeEntries }
            self.exportProgress.totalEntries = timeEntries.count
            
            try await syncEmployeesIfNeeded()
            
            let groupedEntries = Dictionary(grouping: timeEntries) { $0.workerId }
            self.exportProgress.totalWorkers = groupedEntries.count
            
            for (workerId, entries) in groupedEntries {
                try await exportWorkerTimeEntries(workerId: workerId, entries: entries, payPeriod: payPeriod)
                self.exportProgress.processedWorkers += 1
                self.exportProgress.progress = Double(self.exportProgress.processedWorkers) / Double(self.exportProgress.totalWorkers)
            }
            
            try await markPayPeriodAsExported(payPeriod)
            updateExportStats(entriesExported: timeEntries.count, workersProcessed: groupedEntries.count)
            self.lastExportDate = Date()
            self.exportProgress.status = "Export complete!"
            
        } catch {
            self.exportError = error as? PayrollExportError ?? .exportFailed(error.localizedDescription)
            self.exportProgress.status = "Export failed!"
            throw error
        }
    }
    
    public func exportPayPeriodForWorker(_ payPeriod: PayPeriod, workerId: String) async throws {
        guard !isExporting else { throw PayrollExportError.exportInProgress }
        
        self.isExporting = true
        self.exportError = nil
        self.exportProgress = QBExportProgress(status: "Starting worker export...")
        
        defer {
            self.isExporting = false
        }
        
        do {
            let timeEntries = try await getTimeEntriesForWorker(workerId, payPeriod: payPeriod)
            guard !timeEntries.isEmpty else { throw PayrollExportError.noTimeEntries }
            
            try await syncEmployeesIfNeeded()
            try await exportWorkerTimeEntries(workerId: workerId, entries: timeEntries, payPeriod: payPeriod)
            
            self.exportProgress.status = "Worker export complete!"
            
        } catch {
            self.exportError = error as? PayrollExportError ?? .exportFailed(error.localizedDescription)
            self.exportProgress.status = "Worker export failed!"
            throw error
        }
    }
    
    public func getExportHistory(from startDate: Date, to endDate: Date) async throws -> [PayrollExportRecord] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: startDate)
        let endDateString = dateFormatter.string(from: endDate)
        
        let rows = try await grdbManager.query("""
            SELECT 
                export_id, pay_period_start, pay_period_end, export_date,
                total_entries, total_workers, export_status, error_message
            FROM payroll_export_history 
            WHERE pay_period_start >= ? AND pay_period_end <= ?
            ORDER BY export_date DESC
        """, [startDateString, endDateString])
        
        return rows.compactMap { row in
            PayrollExportRecord(
                exportId: row["export_id"] as? String ?? "",
                payPeriodStart: parseDate(row["pay_period_start"] as? String) ?? Date(),
                payPeriodEnd: parseDate(row["pay_period_end"] as? String) ?? Date(),
                exportDate: parseDate(row["export_date"] as? String) ?? Date(),
                totalEntries: Int(row["total_entries"] as? Int64 ?? 0),
                totalWorkers: Int(row["total_workers"] as? Int64 ?? 0),
                exportStatus: row["export_status"] as? String ?? "unknown",
                errorMessage: row["error_message"] as? String
            )
        }
    }
    
    public func getWorkerPayrollSummary(for payPeriod: PayPeriod) async throws -> [WorkerPayrollSummary] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: payPeriod.startDate)
        let endDateString = dateFormatter.string(from: payPeriod.endDate)
        
        let rows = try await grdbManager.query("""
            SELECT 
                tce.workerId, w.name as worker_name, COUNT(tce.id) as total_entries,
                SUM(CASE WHEN tce.clockOutTime IS NOT NULL 
                    THEN (julianday(tce.clockOutTime) - julianday(tce.clockInTime)) * 24 ELSE 0 END) as total_hours,
                SUM(CASE WHEN tce.clockOutTime IS NOT NULL 
                    AND (julianday(tce.clockOutTime) - julianday(tce.clockInTime)) * 24 > ?
                    THEN ((julianday(tce.clockOutTime) - julianday(tce.clockInTime)) * 24) - ? ELSE 0 END) as overtime_hours
            FROM time_clock_entries tce
            JOIN workers w ON tce.workerId = w.id
            WHERE date(tce.clockInTime) >= date(?) AND date(tce.clockInTime) <= date(?)
            AND tce.clockOutTime IS NOT NULL
            GROUP BY tce.workerId, w.name
            ORDER BY w.name
        """, [overtimeThreshold, overtimeThreshold, startDateString, endDateString])
        
        return rows.compactMap { row in
            let totalHours = row["total_hours"] as? Double ?? 0.0
            let overtimeHours = row["overtime_hours"] as? Double ?? 0.0
            
            return WorkerPayrollSummary(
                workerId: row["workerId"] as? String ?? "",
                workerName: row["worker_name"] as? String ?? "",
                totalEntries: Int(row["total_entries"] as? Int64 ?? 0),
                totalHours: totalHours,
                regularHours: max(0, totalHours - overtimeHours),
                overtimeHours: overtimeHours
            )
        }
    }
    
    // MARK: - Private Implementation
    
    private func exportWorkerTimeEntries(workerId: String, entries: [TimeClockEntry], payPeriod: PayPeriod) async throws {
        guard let employeeId = employeeMapping[workerId] else {
            throw PayrollExportError.workerNotMapped(workerId)
        }
        
        var totalHours: Double = 0.0
        var overtimeHours: Double = 0.0
        var regularHours: Double = 0.0
        
        for entry in entries {
            guard let clockOut = entry.clockOutTime else { continue }
            
            let hoursWorked = clockOut.timeIntervalSince(entry.clockInTime) / 3600.0
            totalHours += hoursWorked
            
            if hoursWorked > overtimeThreshold {
                overtimeHours += hoursWorked - overtimeThreshold
                regularHours += overtimeThreshold
            } else {
                regularHours += hoursWorked
            }
        }
        
        let qbTimeEntry = QBTimeEntry(
            employeeId: employeeId,
            regularHours: regularHours,
            overtimeHours: overtimeHours,
            payPeriodStart: payPeriod.startDate,
            payPeriodEnd: payPeriod.endDate
        )
        
        try await submitTimeEntryToQuickBooks(qbTimeEntry)
        try await recordTimeEntryExport(workerId: workerId, entries: entries, qbTimeEntry: qbTimeEntry)
        
        self.exportProgress.processedEntries += entries.count
    }

    private func syncEmployeesIfNeeded() async throws {
        if employeeMapping.isEmpty {
            let workers = try await grdbManager.query("SELECT id, name, email FROM workers WHERE isActive = 1")
            let qbEmployees = try await fetchQuickBooksEmployees()
            
            var newMapping: [String: String] = [:]
            
            for worker in workers {
                guard let workerId = worker["id"] as? String,
                      let workerName = worker["name"] as? String,
                      let workerEmail = worker["email"] as? String else { continue }
                
                if let qbEmployee = qbEmployees.first(where: { $0.email?.lowercased() == workerEmail.lowercased() }) {
                    newMapping[workerId] = qbEmployee.id
                } else if let qbEmployee = qbEmployees.first(where: { $0.name.lowercased().contains(workerName.lowercased()) }) {
                    newMapping[workerId] = qbEmployee.id
                }
            }
            
            self.employeeMapping = newMapping
            saveEmployeeMapping()
        }
    }
    
    private func getTimeEntriesForPayPeriod(_ payPeriod: PayPeriod) async throws -> [TimeClockEntry] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: payPeriod.startDate)
        let endDateString = dateFormatter.string(from: payPeriod.endDate)
        
        let rows = try await grdbManager.query("""
            SELECT id, workerId, clockInTime, clockOutTime, buildingId, notes
            FROM time_clock_entries 
            WHERE date(clockInTime) >= date(?) AND date(clockInTime) <= date(?)
            AND clockOutTime IS NOT NULL
            ORDER BY workerId, clockInTime
        """, [startDateString, endDateString])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let workerId = row["workerId"] as? String,
                  let clockInString = row["clockInTime"] as? String,
                  let clockOutString = row["clockOutTime"] as? String,
                  let clockInTime = parseDate(clockInString),
                  let clockOutTime = parseDate(clockOutString) else {
                return nil
            }
            
            return TimeClockEntry(
                id: id, workerId: workerId, clockInTime: clockInTime, clockOutTime: clockOutTime,
                buildingId: row["buildingId"] as? String, notes: row["notes"] as? String
            )
        }
    }
    
    private func getTimeEntriesForWorker(_ workerId: String, payPeriod: PayPeriod) async throws -> [TimeClockEntry] {
        let dateFormatter = ISO8601DateFormatter()
        let startDateString = dateFormatter.string(from: payPeriod.startDate)
        let endDateString = dateFormatter.string(from: payPeriod.endDate)
        
        let rows = try await grdbManager.query("""
            SELECT id, workerId, clockInTime, clockOutTime, buildingId, notes
            FROM time_clock_entries 
            WHERE workerId = ? AND date(clockInTime) >= date(?) AND date(clockInTime) <= date(?)
            AND clockOutTime IS NOT NULL
            ORDER BY clockInTime
        """, [workerId, startDateString, endDateString])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let workerId = row["workerId"] as? String,
                  let clockInString = row["clockInTime"] as? String,
                  let clockOutString = row["clockOutTime"] as? String,
                  let clockInTime = parseDate(clockInString),
                  let clockOutTime = parseDate(clockOutString) else {
                return nil
            }
            
            return TimeClockEntry(
                id: id, workerId: workerId, clockInTime: clockInTime, clockOutTime: clockOutTime,
                buildingId: row["buildingId"] as? String, notes: row["notes"] as? String
            )
        }
    }
    
    private func markPayPeriodAsExported(_ payPeriod: PayPeriod) async throws {
        let dateFormatter = ISO8601DateFormatter()
        let exportId = UUID().uuidString
        
        try await grdbManager.execute("""
            INSERT OR REPLACE INTO payroll_export_history 
            (export_id, pay_period_start, pay_period_end, export_date, total_entries, total_workers, export_status, error_message)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            exportId,
            dateFormatter.string(from: payPeriod.startDate),
            dateFormatter.string(from: payPeriod.endDate),
            dateFormatter.string(from: Date()),
            exportProgress.totalEntries,
            exportProgress.totalWorkers,
            "completed",
            nil
        ])
    }
    
    private func recordTimeEntryExport(workerId: String, entries: [TimeClockEntry], qbTimeEntry: QBTimeEntry) async throws {
        for entry in entries {
            try await grdbManager.execute("""
                INSERT OR REPLACE INTO payroll_export_entries 
                (time_entry_id, worker_id, qb_employee_id, export_date, regular_hours, overtime_hours, export_status)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, [
                entry.id, workerId, qbTimeEntry.employeeId,
                ISO8601DateFormatter().string(from: Date()),
                qbTimeEntry.regularHours, qbTimeEntry.overtimeHours, "exported"
            ])
        }
    }
    
    private func updateExportStats(entriesExported: Int, workersProcessed: Int) {
        self.exportStats.totalExports += 1
        self.exportStats.totalEntriesExported += entriesExported
        self.exportStats.totalWorkersProcessed += workersProcessed
        self.exportStats.lastExportDate = Date()
        saveExportStats()
    }
    
    private func loadEmployeeMapping() {
        if let data = UserDefaults.standard.data(forKey: "QBEmployeeMapping") {
            do {
                self.employeeMapping = try JSONDecoder().decode([String: String].self, from: data)
            } catch {
                self.employeeMapping = [:]
            }
        }
    }
    
    private func saveEmployeeMapping() {
        do {
            let data = try JSONEncoder().encode(employeeMapping)
            UserDefaults.standard.set(data, forKey: "QBEmployeeMapping")
        } catch {
            print("Failed to save employee mapping")
        }
    }
    
    private func loadExportStats() {
        if let data = UserDefaults.standard.data(forKey: "QBExportStats") {
            do {
                self.exportStats = try JSONDecoder().decode(ExportStats.self, from: data)
            } catch {
                self.exportStats = ExportStats()
            }
        }
    }
    
    private func saveExportStats() {
        do {
            let data = try JSONEncoder().encode(exportStats)
            UserDefaults.standard.set(data, forKey: "QBExportStats")
        } catch {
            print("Failed to save export stats")
        }
    }
    
    private func calculateCurrentPayPeriod() {
        let now = Date()
        let calendar = Calendar.current
        let dayOfWeek = calendar.component(.weekday, from: now)
        let daysToSubtract = (dayOfWeek + 5) % 7
        
        let payPeriodStartDate = calendar.date(byAdding: .day, value: -daysToSubtract, to: now) ?? now
        let payPeriodEndDate = calendar.date(byAdding: .day, value: 13, to: payPeriodStartDate) ?? now
        
        self.currentPayPeriod = PayPeriod(startDate: payPeriodStartDate, endDate: payPeriodEndDate)
    }
    
    private func fetchQuickBooksEmployees() async throws -> [QBEmployee] {
        guard let token = await oauthManager.getValidAccessToken() else {
            throw PayrollExportError.notAuthenticated
        }
        
        return [
            QBEmployee(id: "1", name: "Greg Hutson", email: "greg.hutson@francosphere.com"),
            QBEmployee(id: "2", name: "Edwin Lema", email: "edwin.lema@francosphere.com"),
            QBEmployee(id: "4", name: "Kevin Dutan", email: "kevin.dutan@francosphere.com"),
            QBEmployee(id: "5", name: "Mercedes Inamagua", email: "mercedes.inamagua@francosphere.com"),
            QBEmployee(id: "6", name: "Luis Lopez", email: "luis.lopez@francosphere.com"),
            QBEmployee(id: "7", name: "Angel Guirachocha", email: "angel.guirachocha@francosphere.com"),
            QBEmployee(id: "8", name: "Shawn Magloire", email: "shawn.magloire@francosphere.com")
        ]
    }
    
    private func submitTimeEntryToQuickBooks(_ timeEntry: QBTimeEntry) async throws {
        guard let token = await oauthManager.getValidAccessToken() else {
            throw PayrollExportError.notAuthenticated
        }
        
        // Simulate API submission
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Actor Isolation Fix
extension QuickBooksPayrollExporter {
    nonisolated init() {
        self.init()
        Task {
            await self.loadEmployeeMapping()
            await self.loadExportStats()
            await self.calculateCurrentPayPeriod()
        }
    }
}
