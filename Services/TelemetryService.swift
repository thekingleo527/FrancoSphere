//
//  TelemetryService.swift
//  FrancoSphere
//
//  🔧 COMPLETE PERFORMANCE MONITORING & TELEMETRY SYSTEM - FIXED
//  ✅ Dashboard load time monitoring (<2s target)
//  ✅ Memory usage tracking (<200MB budget)
//  ✅ Kevin workflow performance validation
//  ✅ Service operation profiling
//  ✅ Real-time performance alerts
//  ✅ Analytics for operational insights
//  ✅ ALL SYNTAX ERRORS RESOLVED
//

import Foundation
import OSLog
import UIKit
import CoreLocation

// MARK: - TelemetryService Actor

actor TelemetryService {
    static let shared = TelemetryService()
    
    // MARK: - Performance Budgets & Targets
    private let maxDashboardLoadTime: TimeInterval = 2.0      // 2 second target
    private let maxMemoryBudget: Int = 200 * 1024 * 1024     // 200MB budget
    private let maxCPUUsage: Double = 0.02                   // 2% CPU budget
    private let maxTaskCompletionTime: TimeInterval = 30.0   // 30 seconds
    
    // MARK: - Logging & Analytics
    private let logger = Logger(subsystem: "com.francosphere.app", category: "telemetry")
    private let performanceLogger = Logger(subsystem: "com.francosphere.app", category: "performance")
    private let memoryLogger = Logger(subsystem: "com.francosphere.app", category: "memory")
    
    // MARK: - Performance Tracking State
    private var operationMetrics: [String: OperationMetrics] = [:]
    private var sessionMetrics = SessionMetrics()
    private var kevinWorkflowMetrics = KevinWorkflowMetrics()
    private var dashboardMetrics = DashboardMetrics()
    
    // MARK: - Performance Monitoring
    private var isMonitoringActive = false
    private var memoryWarningCount = 0
    private var performanceAlerts: [PerformanceAlert] = []
    
    private init() {
        setupMemoryWarningMonitoring()
        startSessionTracking()
    }
    
    // MARK: - Core Operation Tracking
    
    /// Track any operation with performance metrics
    func trackOperation<T>(_ operation: String, category: TelemetryCategory = .general, body: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        let operationId = UUID().uuidString
        
        performanceLogger.info("🚀 Starting operation: \(operation) [ID: \(operationId)]")
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let endMemory = getCurrentMemoryUsage()
            let memoryDelta = endMemory - startMemory
            
            Task {
                await self.recordOperationCompletion(
                    operation: operation,
                    category: category,
                    duration: duration,
                    memoryDelta: memoryDelta,
                    operationId: operationId
                )
            }
        }
        
        return try await body()
    }
    
    /// Track dashboard load performance (critical for <2s target)
    func trackDashboardLoad<T>(_ phase: DashboardPhase, workerId: String, body: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let endMemory = getCurrentMemoryUsage()
            let memoryDelta = endMemory - startMemory
            
            Task {
                await self.recordDashboardPhase(
                    phase: phase,
                    workerId: workerId,
                    duration: duration,
                    memoryDelta: memoryDelta
                )
            }
        }
        
        return try await body()
    }
    
    /// Track Kevin's specific workflow performance
    func trackKevinWorkflow<T>(_ action: KevinWorkflowAction, body: () async throws -> T) async rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            let endMemory = getCurrentMemoryUsage()
            let memoryDelta = endMemory - startMemory
            
            Task {
                await self.recordKevinWorkflowAction(
                    action: action,
                    duration: duration,
                    memoryDelta: memoryDelta
                )
            }
        }
        
        return try await body()
    }
    
    // MARK: - Performance Recording & Analysis
    
    private func recordOperationCompletion(
        operation: String,
        category: TelemetryCategory,
        duration: TimeInterval,
        memoryDelta: Int,
        operationId: String
    ) {
        // Update operation metrics
        if var metrics = operationMetrics[operation] {
            metrics.totalCalls += 1
            metrics.totalDuration += duration
            metrics.averageDuration = metrics.totalDuration / Double(metrics.totalCalls)
            metrics.maxDuration = max(metrics.maxDuration, duration)
            metrics.minDuration = min(metrics.minDuration, duration)
            metrics.totalMemoryDelta += memoryDelta
            metrics.lastExecuted = Date()
            operationMetrics[operation] = metrics
        } else {
            operationMetrics[operation] = OperationMetrics(
                operation: operation,
                category: category,
                totalCalls: 1,
                totalDuration: duration,
                averageDuration: duration,
                minDuration: duration,
                maxDuration: duration,
                totalMemoryDelta: memoryDelta,
                lastExecuted: Date()
            )
        }
        
        // Log performance details
        let memoryMB = Double(abs(memoryDelta)) / (1024 * 1024)
        
        performanceLogger.info("""
        ✅ Operation completed: \(operation)
           Duration: \(String(format: "%.3f", duration))s
           Memory: \(memoryDelta > 0 ? "+" : "")\(String(format: "%.2f", memoryMB))MB
           Category: \(category.rawValue)
           ID: \(operationId)
        """)
        
        // Check performance budgets
        checkPerformanceBudgets(operation: operation, duration: duration, memoryDelta: memoryDelta)
        
        // Update session metrics
        sessionMetrics.totalOperations += 1
        sessionMetrics.totalOperationTime += duration
        sessionMetrics.peakMemoryUsage = max(sessionMetrics.peakMemoryUsage, getCurrentMemoryUsage())
    }
    
    private func recordDashboardPhase(
        phase: DashboardPhase,
        workerId: String,
        duration: TimeInterval,
        memoryDelta: Int
    ) {
        // Update dashboard metrics
        dashboardMetrics.phaseMetrics[phase, default: PhaseMetrics()].addMeasurement(duration: duration, memoryDelta: memoryDelta)
        
        // Calculate total dashboard load time
        let totalLoadTime = dashboardMetrics.getTotalLoadTime()
        
        performanceLogger.info("""
        📊 Dashboard Phase: \(phase.rawValue)
           Worker: \(workerId)
           Duration: \(String(format: "%.3f", duration))s
           Memory: \(String(format: "%.2f", Double(abs(memoryDelta)) / (1024 * 1024)))MB
           Total Load Time: \(String(format: "%.3f", totalLoadTime))s
        """)
        
        // Critical: Check 2-second dashboard target
        if totalLoadTime > maxDashboardLoadTime {
            let alert = PerformanceAlert(
                type: .dashboardLoadSlow,
                message: "Dashboard load exceeded \(maxDashboardLoadTime)s target: \(String(format: "%.3f", totalLoadTime))s",
                severity: totalLoadTime > maxDashboardLoadTime * 1.5 ? .critical : .warning,
                context: ["workerId": workerId, "totalTime": "\(totalLoadTime)s"]
            )
            performanceAlerts.append(alert)
            
            logger.error("🚨 DASHBOARD PERFORMANCE ALERT: Load time \(String(format: "%.3f", totalLoadTime))s exceeds \(maxDashboardLoadTime)s target for worker \(workerId)")
        }
        
        // Kevin-specific dashboard tracking
        if workerId == "4" {
            dashboardMetrics.kevinLoadTimes.append(totalLoadTime)
            let avgKevinLoad = dashboardMetrics.kevinLoadTimes.reduce(0, +) / Double(dashboardMetrics.kevinLoadTimes.count)
            
            performanceLogger.info("🎯 Kevin Dashboard: Current \(String(format: "%.3f", totalLoadTime))s, Average \(String(format: "%.3f", avgKevinLoad))s")
        }
    }
    
    private func recordKevinWorkflowAction(
        action: KevinWorkflowAction,
        duration: TimeInterval,
        memoryDelta: Int
    ) {
        // Update Kevin workflow metrics
        kevinWorkflowMetrics.actionMetrics[action, default: ActionMetrics()].addMeasurement(duration: duration, memoryDelta: memoryDelta)
        kevinWorkflowMetrics.totalActions += 1
        kevinWorkflowMetrics.totalWorkflowTime += duration
        
        performanceLogger.info("""
        🎯 Kevin Workflow: \(action.rawValue)
           Duration: \(String(format: "%.3f", duration))s
           Memory: \(String(format: "%.2f", Double(abs(memoryDelta)) / (1024 * 1024)))MB
           Total Actions: \(kevinWorkflowMetrics.totalActions)
        """)
        
        // Track Kevin's building assignments validation
        if action == .loadAssignments {
            if duration > 1.0 {
                let alert = PerformanceAlert(
                    type: .kevinWorkflowSlow,
                    message: "Kevin building assignment load took \(String(format: "%.3f", duration))s",
                    severity: .warning,
                    context: ["action": action.rawValue, "duration": "\(duration)s"]
                )
                performanceAlerts.append(alert)
            }
        }
    }
    
    // MARK: - Performance Budget Monitoring
    
    private func checkPerformanceBudgets(operation: String, duration: TimeInterval, memoryDelta: Int) {
        // Check duration budgets
        let isDashboardOperation = operation.lowercased().contains("dashboard") || operation.lowercased().contains("load")
        let isSlowOperation = isDashboardOperation ? duration > maxDashboardLoadTime : duration > 1.0
        
        if isSlowOperation {
            let alert = PerformanceAlert(
                type: .operationSlow,
                message: "Operation '\(operation)' took \(String(format: "%.3f", duration))s",
                severity: duration > (isDashboardOperation ? maxDashboardLoadTime * 2 : 5.0) ? .critical : .warning,
                context: ["operation": operation, "duration": "\(duration)s"]
            )
            performanceAlerts.append(alert)
            
            logger.warning("⚠️ Slow operation: \(operation) took \(String(format: "%.3f", duration))s")
        }
        
        // Check memory budgets
        if memoryDelta > maxMemoryBudget / 10 { // Alert on 10% of budget spike
            let memoryMB = Double(memoryDelta) / (1024 * 1024)
            let alert = PerformanceAlert(
                type: .memorySpike,
                message: "Operation '\(operation)' used \(String(format: "%.2f", memoryMB))MB",
                severity: memoryDelta > maxMemoryBudget / 5 ? .critical : .warning,
                context: ["operation": operation, "memoryMB": "\(memoryMB)MB"]
            )
            performanceAlerts.append(alert)
            
            memoryLogger.warning("⚠️ Memory spike: \(operation) used \(String(format: "%.2f", memoryMB))MB")
        }
        
        // Check total memory usage
        let currentMemory = getCurrentMemoryUsage()
        if currentMemory > maxMemoryBudget {
            let memoryMB = Double(currentMemory) / (1024 * 1024)
            let alert = PerformanceAlert(
                type: .memoryBudgetExceeded,
                message: "App memory usage \(String(format: "%.2f", memoryMB))MB exceeds budget",
                severity: .critical,
                context: ["currentMemoryMB": "\(memoryMB)MB", "budgetMB": "\(maxMemoryBudget / (1024 * 1024))MB"]
            )
            performanceAlerts.append(alert)
            
            memoryLogger.error("🚨 MEMORY BUDGET EXCEEDED: \(String(format: "%.2f", memoryMB))MB > \(maxMemoryBudget / (1024 * 1024))MB budget")
        }
    }
    
    // MARK: - Memory Monitoring
    
    func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    func getCurrentMemoryUsageFormatted() -> String {
        let memoryBytes = getCurrentMemoryUsage()
        let memoryMB = Double(memoryBytes) / (1024 * 1024)
        return String(format: "%.2f MB", memoryMB)
    }
    
    private func setupMemoryWarningMonitoring() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.handleMemoryWarning()
            }
        }
    }
    
    private func handleMemoryWarning() {
        memoryWarningCount += 1
        let currentMemory = getCurrentMemoryUsage()
        let memoryMB = Double(currentMemory) / (1024 * 1024)
        
        let alert = PerformanceAlert(
            type: .memoryWarning,
            message: "Memory warning #\(memoryWarningCount) - Current usage: \(String(format: "%.2f", memoryMB))MB",
            severity: memoryWarningCount > 3 ? .critical : .warning,
            context: ["warningCount": "\(memoryWarningCount)", "memoryMB": "\(memoryMB)MB"]
        )
        performanceAlerts.append(alert)
        
        memoryLogger.error("🚨 MEMORY WARNING #\(memoryWarningCount): Current usage \(String(format: "%.2f", memoryMB))MB")
        
        // Trigger cleanup if too many warnings
        if memoryWarningCount > 2 {
            performMemoryCleanup()
        }
    }
    
    private func performMemoryCleanup() {
        // Clear old metrics to free memory
        let cutoffDate = Date().addingTimeInterval(-3600) // 1 hour ago
        performanceAlerts.removeAll { $0.timestamp < cutoffDate }
        
        // Clear old operation metrics
        operationMetrics = operationMetrics.filter { $0.value.lastExecuted > cutoffDate }
        
        memoryLogger.info("🧹 Performed memory cleanup due to repeated warnings")
    }
    
    // MARK: - Session Tracking
    
    private func startSessionTracking() {
        sessionMetrics.sessionStart = Date()
        sessionMetrics.initialMemoryUsage = getCurrentMemoryUsage()
        
        logger.info("📊 Telemetry session started - Initial memory: \(getCurrentMemoryUsageFormatted())")
    }
    
    // MARK: - Analytics & Reporting
    
    func getPerformanceReport() -> PerformanceReport {
        let currentMemory = getCurrentMemoryUsage()
        let sessionDuration = Date().timeIntervalSince(sessionMetrics.sessionStart)
        
        return PerformanceReport(
            sessionMetrics: sessionMetrics,
            dashboardMetrics: dashboardMetrics,
            kevinWorkflowMetrics: kevinWorkflowMetrics,
            topOperations: getTopOperations(),
            recentAlerts: getRecentAlerts(),
            currentMemoryMB: Double(currentMemory) / (1024 * 1024),
            memoryBudgetMB: Double(maxMemoryBudget) / (1024 * 1024),
            sessionDurationMinutes: sessionDuration / 60,
            memoryWarningCount: memoryWarningCount
        )
    }
    
    func getDashboardPerformanceMetrics() -> DashboardPerformanceMetrics {
        let totalLoadTime = dashboardMetrics.getTotalLoadTime()
        let meetsTarget = totalLoadTime <= maxDashboardLoadTime
        
        return DashboardPerformanceMetrics(
            averageLoadTime: totalLoadTime,
            targetLoadTime: maxDashboardLoadTime,
            meetsTarget: meetsTarget,
            kevinAverageLoadTime: dashboardMetrics.kevinLoadTimes.isEmpty ? 0 :
                dashboardMetrics.kevinLoadTimes.reduce(0, +) / Double(dashboardMetrics.kevinLoadTimes.count),
            phaseBreakdown: dashboardMetrics.phaseMetrics.mapValues { $0.averageDuration }
        )
    }
    
    func getKevinWorkflowReport() -> KevinWorkflowReport {
        return KevinWorkflowReport(
            totalActions: kevinWorkflowMetrics.totalActions,
            totalWorkflowTime: kevinWorkflowMetrics.totalWorkflowTime,
            averageActionTime: kevinWorkflowMetrics.totalActions > 0 ?
                kevinWorkflowMetrics.totalWorkflowTime / Double(kevinWorkflowMetrics.totalActions) : 0,
            actionBreakdown: kevinWorkflowMetrics.actionMetrics.mapValues { $0.averageDuration },
            rubinMuseumTasksCompleted: kevinWorkflowMetrics.rubinMuseumTasksCompleted,
            buildingAssignmentValidations: kevinWorkflowMetrics.buildingAssignmentValidations
        )
    }
    
    private func getTopOperations(limit: Int = 10) -> [OperationMetrics] {
        return Array(operationMetrics.values)
            .sorted { $0.totalDuration > $1.totalDuration }
            .prefix(limit)
            .map { $0 }
    }
    
    private func getRecentAlerts(limit: Int = 20) -> [PerformanceAlert] {
        return Array(performanceAlerts.suffix(limit))
    }
    
    // MARK: - Validation & Testing Support
    
    func validatePerformanceTargets() -> PerformanceValidationResult {
        let dashboardPerf = getDashboardPerformanceMetrics()
        let currentMemory = getCurrentMemoryUsage()
        let memoryWithinBudget = currentMemory <= maxMemoryBudget
        
        var issues: [String] = []
        var successes: [String] = []
        
        // Dashboard load time validation
        if dashboardPerf.meetsTarget {
            successes.append("✅ Dashboard loads within \(maxDashboardLoadTime)s target (\(String(format: "%.3f", dashboardPerf.averageLoadTime))s)")
        } else {
            issues.append("❌ Dashboard load time \(String(format: "%.3f", dashboardPerf.averageLoadTime))s exceeds \(maxDashboardLoadTime)s target")
        }
        
        // Memory budget validation
        if memoryWithinBudget {
            successes.append("✅ Memory usage within budget: \(getCurrentMemoryUsageFormatted()) / \(maxMemoryBudget / (1024 * 1024))MB")
        } else {
            issues.append("❌ Memory usage exceeds budget: \(getCurrentMemoryUsageFormatted()) > \(maxMemoryBudget / (1024 * 1024))MB")
        }
        
        // Kevin workflow validation
        if kevinWorkflowMetrics.totalActions > 0 {
            let avgKevinAction = kevinWorkflowMetrics.totalWorkflowTime / Double(kevinWorkflowMetrics.totalActions)
            if avgKevinAction <= 2.0 {
                successes.append("✅ Kevin workflow actions average \(String(format: "%.3f", avgKevinAction))s")
            } else {
                issues.append("❌ Kevin workflow actions too slow: \(String(format: "%.3f", avgKevinAction))s average")
            }
        }
        
        // Memory warnings validation
        if memoryWarningCount == 0 {
            successes.append("✅ No memory warnings during session")
        } else {
            issues.append("❌ \(memoryWarningCount) memory warnings occurred")
        }
        
        return PerformanceValidationResult(
            overallPass: issues.isEmpty,
            issues: issues,
            successes: successes,
            score: issues.isEmpty ? 100 : max(0, 100 - (issues.count * 25))
        )
    }
    
    // MARK: - Kevin-Specific Tracking Methods
    
    func recordKevinRubinMuseumTask() {
        kevinWorkflowMetrics.rubinMuseumTasksCompleted += 1
        performanceLogger.info("🎯 Kevin completed Rubin Museum task #\(kevinWorkflowMetrics.rubinMuseumTasksCompleted)")
    }
    
    func recordKevinBuildingAssignmentValidation(success: Bool) {
        kevinWorkflowMetrics.buildingAssignmentValidations += 1
        if success {
            performanceLogger.info("✅ Kevin building assignment validation #\(kevinWorkflowMetrics.buildingAssignmentValidations) succeeded")
        } else {
            logger.warning("⚠️ Kevin building assignment validation #\(kevinWorkflowMetrics.buildingAssignmentValidations) failed")
        }
    }
    
    // MARK: - Debug & Development Support
    
    func enableDebugLogging() {
        isMonitoringActive = true
        logger.info("🔧 Debug telemetry logging enabled")
    }
    
    func disableDebugLogging() {
        isMonitoringActive = false
        logger.info("🔧 Debug telemetry logging disabled")
    }
    
    func clearMetrics() {
        operationMetrics.removeAll()
        performanceAlerts.removeAll()
        sessionMetrics = SessionMetrics()
        kevinWorkflowMetrics = KevinWorkflowMetrics()
        dashboardMetrics = DashboardMetrics()
        memoryWarningCount = 0
        
        logger.info("🧹 All telemetry metrics cleared")
    }
    
    func exportMetricsForTesting() -> [String: Any] {
        return [
            "sessionMetrics": [
                "totalOperations": sessionMetrics.totalOperations,
                "totalOperationTime": sessionMetrics.totalOperationTime,
                "peakMemoryUsage": sessionMetrics.peakMemoryUsage
            ],
            "dashboardMetrics": [
                "totalLoadTime": dashboardMetrics.getTotalLoadTime(),
                "meetsTarget": dashboardMetrics.getTotalLoadTime() <= maxDashboardLoadTime,
                "kevinLoadTimes": dashboardMetrics.kevinLoadTimes
            ],
            "performanceAlerts": performanceAlerts.count,
            "memoryWarnings": memoryWarningCount,
            "currentMemoryMB": Double(getCurrentMemoryUsage()) / (1024 * 1024)
        ]
    }
}

// MARK: - Supporting Types & Enums

enum TelemetryCategory: String, CaseIterable {
    case general = "General"
    case dashboard = "Dashboard"
    case dataLoading = "DataLoading"
    case userInterface = "UserInterface"
    case database = "Database"
    case networking = "Networking"
    case security = "Security"
    case kevinWorkflow = "KevinWorkflow"
}

enum DashboardPhase: String, CaseIterable {
    case initialization = "Initialization"
    case workerAuth = "WorkerAuth"
    case buildingLoad = "BuildingLoad"
    case taskLoad = "TaskLoad"
    case uiRender = "UIRender"
    case complete = "Complete"
}

enum KevinWorkflowAction: String, CaseIterable {
    case login = "Login"
    case loadAssignments = "LoadAssignments"
    case validateRubinMuseum = "ValidateRubinMuseum"
    case loadTasks = "LoadTasks"
    case completeTask = "CompleteTask"
    case clockIn = "ClockIn"
    case clockOut = "ClockOut"
}

enum PerformanceAlertType: String {
    case dashboardLoadSlow = "DashboardLoadSlow"
    case operationSlow = "OperationSlow"
    case memorySpike = "MemorySpike"
    case memoryBudgetExceeded = "MemoryBudgetExceeded"
    case memoryWarning = "MemoryWarning"
    case kevinWorkflowSlow = "KevinWorkflowSlow"
}

enum AlertSeverity: String {
    case info = "Info"
    case warning = "Warning"
    case critical = "Critical"
}

// MARK: - Data Structures

struct OperationMetrics {
    let operation: String
    let category: TelemetryCategory
    var totalCalls: Int
    var totalDuration: TimeInterval
    var averageDuration: TimeInterval
    var minDuration: TimeInterval
    var maxDuration: TimeInterval
    var totalMemoryDelta: Int
    var lastExecuted: Date
}

struct SessionMetrics {
    var sessionStart = Date()
    var totalOperations = 0
    var totalOperationTime: TimeInterval = 0
    var peakMemoryUsage = 0
    var initialMemoryUsage = 0
}

struct DashboardMetrics {
    var phaseMetrics: [DashboardPhase: PhaseMetrics] = [:]
    var kevinLoadTimes: [TimeInterval] = []
    
    func getTotalLoadTime() -> TimeInterval {
        return phaseMetrics.values.reduce(0) { $0 + $1.averageDuration }
    }
}

struct KevinWorkflowMetrics {
    var actionMetrics: [KevinWorkflowAction: ActionMetrics] = [:]
    var totalActions = 0
    var totalWorkflowTime: TimeInterval = 0
    var rubinMuseumTasksCompleted = 0
    var buildingAssignmentValidations = 0
}

struct PhaseMetrics {
    var totalDuration: TimeInterval = 0
    var callCount = 0
    var averageDuration: TimeInterval = 0
    var totalMemoryDelta = 0
    
    mutating func addMeasurement(duration: TimeInterval, memoryDelta: Int) {
        totalDuration += duration
        callCount += 1
        averageDuration = totalDuration / Double(callCount)
        totalMemoryDelta += memoryDelta
    }
}

struct ActionMetrics {
    var totalDuration: TimeInterval = 0
    var callCount = 0
    var averageDuration: TimeInterval = 0
    var totalMemoryDelta = 0
    
    mutating func addMeasurement(duration: TimeInterval, memoryDelta: Int) {
        totalDuration += duration
        callCount += 1
        averageDuration = totalDuration / Double(callCount)
        totalMemoryDelta += memoryDelta
    }
}

struct PerformanceAlert {
    let type: PerformanceAlertType
    let message: String
    let severity: AlertSeverity
    let timestamp = Date()
    let context: [String: String]
}

struct PerformanceReport {
    let sessionMetrics: SessionMetrics
    let dashboardMetrics: DashboardMetrics
    let kevinWorkflowMetrics: KevinWorkflowMetrics
    let topOperations: [OperationMetrics]
    let recentAlerts: [PerformanceAlert]
    let currentMemoryMB: Double
    let memoryBudgetMB: Double
    let sessionDurationMinutes: TimeInterval
    let memoryWarningCount: Int
}

struct DashboardPerformanceMetrics {
    let averageLoadTime: TimeInterval
    let targetLoadTime: TimeInterval
    let meetsTarget: Bool
    let kevinAverageLoadTime: TimeInterval
    let phaseBreakdown: [DashboardPhase: TimeInterval]
}

struct KevinWorkflowReport {
    let totalActions: Int
    let totalWorkflowTime: TimeInterval
    let averageActionTime: TimeInterval
    let actionBreakdown: [KevinWorkflowAction: TimeInterval]
    let rubinMuseumTasksCompleted: Int
    let buildingAssignmentValidations: Int
}

struct PerformanceValidationResult {
    let overallPass: Bool
    let issues: [String]
    let successes: [String]
    let score: Int
}
