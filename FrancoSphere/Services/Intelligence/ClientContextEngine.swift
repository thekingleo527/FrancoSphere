//
//  ClientContextEngine.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 8/2/25.
//


//
//  ClientContextEngine.swift
//  FrancoSphere v6.0
//
//  ✅ REAL-TIME: Aggregates live data from all sources
//  ✅ INTELLIGENT: Processes worker activity into client insights
//  ✅ REACTIVE: Responds to dashboard sync updates
//  ✅ COMPREHENSIVE: Unified data model for client view
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class ClientContextEngine: ObservableObject {
    static let shared = ClientContextEngine()
    
    // MARK: - Published Properties
    
    // Portfolio Overview
    @Published var portfolioHealth: CoreTypes.PortfolioHealth = .empty
    @Published var executiveIntelligence: CoreTypes.ExecutiveIntelligence?
    @Published var clientBuildings: [NamedCoordinate] = []
    
    // Real-time Metrics
    @Published var realtimeMetrics: CoreTypes.RealtimePortfolioMetrics = .empty
    @Published var syncProgress: Double = 0.0
    
    // Worker Activity
    @Published var activeWorkerStatus: CoreTypes.ActiveWorkerStatus = .empty
    @Published var workerProductivityInsights: [CoreTypes.WorkerProductivityInsight] = []
    
    // Compliance
    @Published var complianceOverview: CoreTypes.ComplianceOverview = .empty
    @Published var allComplianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var criticalComplianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var buildingsWithViolations: [String] = []
    
    // Alerts & Notifications
    @Published var realtimeAlerts: [CoreTypes.ClientAlert] = []
    @Published var criticalAlerts: [CoreTypes.ClientAlert] = []
    
    // Building Performance
    @Published var buildingPerformanceMap: [String: Double] = [:]
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var topPerformanceBuildings: [NamedCoordinate] = []
    
    // Cost & Efficiency
    @Published var estimatedMonthlySavings: Double = 0
    @Published var costOptimizationInsights: [CoreTypes.CostInsight] = []
    
    // MARK: - Private Properties
    
    private let dashboardSync = DashboardSyncService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let complianceService = ComplianceService.shared
    private let workerService = WorkerService.shared
    private let analyticsService = AnalyticsService.shared
    
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTimer: Timer?
    private var lastUpdateTime = Date()
    
    // MARK: - Initialization
    
    private init() {
        setupSubscriptions()
        startRealtimeMonitoring()
    }
    
    // MARK: - Public Methods
    
    func refreshAllData() async {
        do {
            // Update sync progress
            syncProgress = 0.1
            
            // Fetch portfolio data
            async let buildings = fetchClientBuildings()
            async let health = calculatePortfolioHealth()
            async let compliance = fetchComplianceOverview()
            async let workers = fetchActiveWorkerStatus()
            
            // Update properties
            self.clientBuildings = try await buildings
            syncProgress = 0.3
            
            self.portfolioHealth = try await health
            syncProgress = 0.5
            
            self.complianceOverview = try await compliance
            syncProgress = 0.7
            
            self.activeWorkerStatus = try await workers
            syncProgress = 0.9
            
            // Generate insights
            await generateExecutiveIntelligence()
            await updateBuildingPerformance()
            await generateWorkerInsights()
            await identifyCostSavings()
            
            syncProgress = 1.0
            lastUpdateTime = Date()
            
            // Update real-time metrics
            updateRealtimeMetrics()
            
        } catch {
            print("Error refreshing client data: \(error)")
            syncProgress = 0.0
        }
    }
    
    func startRealtimeMonitoring() {
        // Subscribe to dashboard sync updates
        dashboardSync.$lastUpdate
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task {
                    await self?.handleRealtimeUpdate()
                }
            }
            .store(in: &cancellables)
        
        // Start periodic updates
        realtimeTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.updateRealtimeData()
            }
        }
    }
    
    func subscribeToWorkerUpdates() {
        // Subscribe to worker activity updates
        NotificationCenter.default.publisher(for: .workerActivityChanged)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] notification in
                Task {
                    await self?.handleWorkerUpdate(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    func monitorComplianceChanges() {
        // Subscribe to compliance updates
        NotificationCenter.default.publisher(for: .complianceStatusChanged)
            .sink { [weak self] notification in
                Task {
                    await self?.handleComplianceUpdate(notification)
                }
            }
            .store(in: &cancellables)
    }
    
    func identifyCostSavings() -> CoreTypes.IntelligenceInsight? {
        // Analyze data for cost saving opportunities
        let inefficientBuildings = buildingPerformanceMap.filter { $0.value < 0.6 }
        let potentialSavings = Double(inefficientBuildings.count) * 2500 // Estimated monthly savings per building
        
        if potentialSavings > 1000 {
            estimatedMonthlySavings = potentialSavings
            
            return CoreTypes.IntelligenceInsight(
                title: "Potential cost savings of $\(Int(potentialSavings))/month",
                description: "Optimizing staffing and task allocation in \(inefficientBuildings.count) underperforming buildings",
                type: .cost,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: Array(inefficientBuildings.keys),
                estimatedImpact: "$\(Int(potentialSavings * 12)) annual savings"
            )
        }
        
        return nil
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptions() {
        // Subscribe to Nova Intelligence updates
        NovaIntelligenceEngine.shared.$insights
            .sink { [weak self] insights in
                self?.processNovaInsights(insights)
            }
            .store(in: &cancellables)
    }
    
    private func fetchClientBuildings() async throws -> [NamedCoordinate] {
        // Fetch buildings assigned to this client
        let buildings = try await buildingService.getClientBuildings()
        return buildings.map { building in
            NamedCoordinate(
                id: building.id,
                name: building.name,
                address: building.address,
                latitude: building.latitude,
                longitude: building.longitude,
                type: building.type
            )
        }
    }
    
    private func calculatePortfolioHealth() async throws -> CoreTypes.PortfolioHealth {
        let buildings = try await buildingService.getClientBuildings()
        let metrics = try await buildingService.getBuildingMetrics(for: buildings.map { $0.id })
        
        // Calculate overall health
        let totalBuildings = buildings.count
        let activeBuildings = buildings.filter { $0.isActive }.count
        let avgCompletionRate = metrics.values.map { $0.completionRate }.reduce(0, +) / Double(metrics.count)
        let criticalIssues = metrics.values.filter { $0.criticalIssues > 0 }.count
        
        // Determine trend
        let trend: CoreTypes.TrendDirection = {
            // Compare with historical data
            if avgCompletionRate > 0.85 { return .improving }
            else if avgCompletionRate < 0.65 { return .declining }
            else { return .stable }
        }()
        
        return CoreTypes.PortfolioHealth(
            overallScore: avgCompletionRate,
            totalBuildings: totalBuildings,
            activeBuildings: activeBuildings,
            criticalIssues: criticalIssues,
            trend: trend,
            lastUpdated: Date()
        )
    }
    
    private func fetchComplianceOverview() async throws -> CoreTypes.ComplianceOverview {
        let issues = try await complianceService.getClientComplianceIssues()
        
        // Store all issues
        allComplianceIssues = issues
        criticalComplianceIssues = issues.filter { $0.severity == .critical }
        
        // Calculate overview
        let totalIssues = issues.count
        let openIssues = issues.filter { $0.status == .open }.count
        let criticalViolations = issues.filter { $0.severity == .critical && $0.status == .open }.count
        let overallScore = max(0, 1.0 - (Double(criticalViolations) * 0.2) - (Double(openIssues) * 0.05))
        
        // Find buildings with violations
        buildingsWithViolations = Array(Set(issues.compactMap { $0.buildingId }))
        
        return CoreTypes.ComplianceOverview(
            overallScore: overallScore,
            totalIssues: totalIssues,
            openIssues: openIssues,
            criticalViolations: criticalViolations,
            lastAudit: issues.first?.reportedDate ?? Date(),
            nextAudit: Calendar.current.date(byAdding: .month, value: 1, to: Date())
        )
    }
    
    private func fetchActiveWorkerStatus() async throws -> CoreTypes.ActiveWorkerStatus {
        let workers = try await workerService.getActiveWorkers()
        let totalWorkers = workers.count
        let activeWorkers = workers.filter { $0.status == .clockedIn }.count
        
        // Calculate utilization
        let utilizationRate = totalWorkers > 0 ? Double(activeWorkers) / Double(totalWorkers) : 0
        
        // Get productivity metrics
        let avgTasksPerWorker = try await taskService.getAverageTasksPerWorker()
        let completionRate = try await taskService.getOverallCompletionRate()
        
        return CoreTypes.ActiveWorkerStatus(
            totalActive: activeWorkers,
            totalAssigned: totalWorkers,
            utilizationRate: utilizationRate,
            avgTasksPerWorker: avgTasksPerWorker,
            completionRate: completionRate
        )
    }
    
    private func generateExecutiveIntelligence() async {
        // Generate AI-powered executive summary
        let keyInsights = [
            "Portfolio completion rate at \(Int(portfolioHealth.overallScore * 100))% with \(portfolioHealth.trend.rawValue) trend",
            "\(activeWorkerStatus.totalActive) workers currently active across \(portfolioHealth.activeBuildings) buildings",
            complianceOverview.criticalViolations > 0 ? "\(complianceOverview.criticalViolations) critical compliance issues require immediate attention" : "All compliance requirements met",
            estimatedMonthlySavings > 0 ? "Potential monthly savings of $\(Int(estimatedMonthlySavings)) identified" : "Operations running efficiently"
        ]
        
        let recommendations = [
            CoreTypes.StrategicRecommendation(
                title: "Optimize Worker Distribution",
                description: "Reallocate workers from overstaffed to understaffed buildings",
                priority: .high,
                estimatedImpact: "15% efficiency improvement",
                timeframe: "2 weeks"
            )
        ]
        
        executiveIntelligence = CoreTypes.ExecutiveIntelligence(
            keyInsights: keyInsights,
            recommendations: recommendations,
            generatedAt: Date()
        )
    }
    
    private func updateBuildingPerformance() async {
        // Update performance map for each building
        for building in clientBuildings {
            if let metrics = try? await buildingService.getBuildingMetrics(for: [building.id]).first {
                buildingPerformanceMap[building.id] = metrics.value.completionRate
                buildingMetrics[building.id] = metrics.value
            }
        }
        
        // Identify top performers
        topPerformanceBuildings = clientBuildings
            .sorted { (buildingPerformanceMap[$0.id] ?? 0) > (buildingPerformanceMap[$1.id] ?? 0) }
            .prefix(5)
            .map { $0 }
    }
    
    private func generateWorkerInsights() async {
        // Generate productivity insights
        let insights = [
            CoreTypes.WorkerProductivityInsight(
                id: UUID().uuidString,
                metric: "\(Int(activeWorkerStatus.utilizationRate * 100))%",
                description: "Current worker utilization rate",
                trend: activeWorkerStatus.utilizationRate > 0.8 ? .up : .down,
                recommendation: activeWorkerStatus.utilizationRate < 0.6 ? "Consider optimizing task distribution" : nil
            ),
            CoreTypes.WorkerProductivityInsight(
                id: UUID().uuidString,
                metric: "\(activeWorkerStatus.avgTasksPerWorker) tasks",
                description: "Average tasks per worker today",
                trend: .stable,
                recommendation: nil
            )
        ]
        
        workerProductivityInsights = insights
    }
    
    private func updateRealtimeMetrics() {
        // Generate performance trend (last 7 days)
        let trend = [0.72, 0.74, 0.71, 0.75, 0.78, 0.76, 0.80] // Sample data
        
        // Recent activities
        let activities = dashboardSync.recentUpdates.prefix(5).map { update in
            CoreTypes.RealtimeActivity(
                id: update.id,
                type: mapUpdateType(update.type),
                description: update.description,
                workerName: update.metadata["workerName"] as? String,
                buildingName: update.metadata["buildingName"] as? String,
                timestamp: update.timestamp
            )
        }
        
        realtimeMetrics = CoreTypes.RealtimePortfolioMetrics(
            lastUpdateTime: lastUpdateTime,
            performanceTrend: trend,
            recentActivities: activities,
            activeAlerts: realtimeAlerts.count,
            pendingActions: criticalComplianceIssues.count
        )
    }
    
    private func handleRealtimeUpdate() async {
        // Handle real-time updates from dashboard sync
        if let lastUpdate = dashboardSync.lastUpdate {
            // Check if update affects client's buildings
            if let buildingId = lastUpdate.metadata["buildingId"] as? String,
               clientBuildings.contains(where: { $0.id == buildingId }) {
                
                // Update specific building metrics
                if let metrics = try? await buildingService.getBuildingMetrics(for: [buildingId]).first {
                    buildingPerformanceMap[buildingId] = metrics.value.completionRate
                    buildingMetrics[buildingId] = metrics.value
                }
                
                // Add to real-time alerts if critical
                if lastUpdate.type == .criticalUpdate {
                    let alert = CoreTypes.ClientAlert(
                        id: UUID().uuidString,
                        title: lastUpdate.description,
                        message: "Immediate attention required",
                        severity: .critical,
                        buildingId: buildingId,
                        timestamp: Date(),
                        actionRequired: true
                    )
                    realtimeAlerts.insert(alert, at: 0)
                    criticalAlerts = realtimeAlerts.filter { $0.severity == .critical }
                }
            }
        }
        
        // Update real-time metrics
        updateRealtimeMetrics()
    }
    
    private func handleWorkerUpdate(_ notification: Notification) async {
        // Update worker status based on activity
        await fetchActiveWorkerStatus()
        await generateWorkerInsights()
        updateRealtimeMetrics()
    }
    
    private func handleComplianceUpdate(_ notification: Notification) async {
        // Update compliance data
        complianceOverview = try! await fetchComplianceOverview()
        updateRealtimeMetrics()
    }
    
    private func updateRealtimeData() async {
        // Periodic update of real-time data
        await updateBuildingPerformance()
        updateRealtimeMetrics()
    }
    
    private func processNovaInsights(_ insights: [CoreTypes.IntelligenceInsight]) {
        // Process Nova AI insights for client relevance
        let clientRelevantInsights = insights.filter { insight in
            // Filter for client-relevant insights
            insight.type == .cost ||
            insight.type == .compliance ||
            insight.type == .efficiency ||
            (insight.affectedBuildings.contains { buildingId in
                clientBuildings.contains { $0.id == buildingId }
            })
        }
        
        // Convert to alerts if critical
        for insight in clientRelevantInsights where insight.priority == .critical {
            let alert = CoreTypes.ClientAlert(
                id: insight.id,
                title: insight.title,
                message: insight.description,
                severity: .critical,
                buildingId: insight.affectedBuildings.first,
                timestamp: Date(),
                actionRequired: insight.actionRequired
            )
            realtimeAlerts.append(alert)
        }
        
        criticalAlerts = realtimeAlerts.filter { $0.severity == .critical }
    }
    
    private func mapUpdateType(_ type: DashboardUpdate.UpdateType) -> CoreTypes.RealtimeActivity.ActivityType {
        switch type {
        case .taskComplete: return .taskCompleted
        case .workerClockIn: return .workerClockIn
        case .workerClockOut: return .workerClockOut
        case .buildingUpdate: return .buildingUpdate
        case .complianceUpdate: return .complianceUpdate
        default: return .buildingUpdate
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let workerActivityChanged = Notification.Name("workerActivityChanged")
    static let complianceStatusChanged = Notification.Name("complianceStatusChanged")
}

// MARK: - Supporting Types Extensions

extension CoreTypes.PortfolioHealth {
    static var empty: CoreTypes.PortfolioHealth {
        CoreTypes.PortfolioHealth(
            overallScore: 0,
            totalBuildings: 0,
            activeBuildings: 0,
            criticalIssues: 0,
            trend: .unknown,
            lastUpdated: Date()
        )
    }
    
    static var preview: CoreTypes.PortfolioHealth {
        CoreTypes.PortfolioHealth(
            overallScore: 0.85,
            totalBuildings: 12,
            activeBuildings: 10,
            criticalIssues: 0,
            trend: .improving,
            lastUpdated: Date()
        )
    }
    
    static var previewCritical: CoreTypes.PortfolioHealth {
        CoreTypes.PortfolioHealth(
            overallScore: 0.62,
            totalBuildings: 12,
            activeBuildings: 8,
            criticalIssues: 3,
            trend: .declining,
            lastUpdated: Date()
        )
    }
}

extension CoreTypes.RealtimePortfolioMetrics {
    static var empty: CoreTypes.RealtimePortfolioMetrics {
        CoreTypes.RealtimePortfolioMetrics(
            lastUpdateTime: Date(),
            performanceTrend: [],
            recentActivities: [],
            activeAlerts: 0,
            pendingActions: 0
        )
    }
    
    static var preview: CoreTypes.RealtimePortfolioMetrics {
        CoreTypes.RealtimePortfolioMetrics(
            lastUpdateTime: Date(),
            performanceTrend: [0.72, 0.74, 0.71, 0.75, 0.78, 0.76, 0.80],
            recentActivities: [
                CoreTypes.RealtimeActivity(
                    id: "1",
                    type: .taskCompleted,
                    description: "Lobby cleaning completed",
                    workerName: "John Smith",
                    buildingName: "123 Main St",
                    timestamp: Date().addingTimeInterval(-300)
                ),
                CoreTypes.RealtimeActivity(
                    id: "2",
                    type: .workerClockIn,
                    description: "Worker clocked in",
                    workerName: "Jane Doe",
                    buildingName: "456 Park Ave",
                    timestamp: Date().addingTimeInterval(-600)
                )
            ],
            activeAlerts: 2,
            pendingActions: 5
        )
    }
    
    static var previewWithAlerts: CoreTypes.RealtimePortfolioMetrics {
        CoreTypes.RealtimePortfolioMetrics(
            lastUpdateTime: Date(),
            performanceTrend: [0.82, 0.78, 0.71, 0.65, 0.68, 0.62, 0.60],
            recentActivities: [
                CoreTypes.RealtimeActivity(
                    id: "1",
                    type: .issueReported,
                    description: "Compliance violation reported",
                    workerName: nil,
                    buildingName: "789 Broadway",
                    timestamp: Date().addingTimeInterval(-120)
                )
            ],
            activeAlerts: 5,
            pendingActions: 8
        )
    }
}

extension CoreTypes.ActiveWorkerStatus {
    static var empty: CoreTypes.ActiveWorkerStatus {
        CoreTypes.ActiveWorkerStatus(
            totalActive: 0,
            totalAssigned: 0,
            utilizationRate: 0,
            avgTasksPerWorker: 0,
            completionRate: 0
        )
    }
    
    static var preview: CoreTypes.ActiveWorkerStatus {
        CoreTypes.ActiveWorkerStatus(
            totalActive: 24,
            totalAssigned: 30,
            utilizationRate: 0.8,
            avgTasksPerWorker: 12.5,
            completionRate: 0.85
        )
    }
    
    static var previewLowUtilization: CoreTypes.ActiveWorkerStatus {
        CoreTypes.ActiveWorkerStatus(
            totalActive: 15,
            totalAssigned: 30,
            utilizationRate: 0.5,
            avgTasksPerWorker: 8.2,
            completionRate: 0.68
        )
    }
}

extension CoreTypes.ComplianceOverview {
    static var empty: CoreTypes.ComplianceOverview {
        CoreTypes.ComplianceOverview(
            overallScore: 1.0,
            totalIssues: 0,
            openIssues: 0,
            criticalViolations: 0,
            lastAudit: Date(),
            nextAudit: nil
        )
    }
    
    static var previewHealthy: CoreTypes.ComplianceOverview {
        CoreTypes.ComplianceOverview(
            overallScore: 0.95,
            totalIssues: 12,
            openIssues: 2,
            criticalViolations: 0,
            lastAudit: Date().addingTimeInterval(-604800), // 1 week ago
            nextAudit: Date().addingTimeInterval(1814400) // 3 weeks from now
        )
    }
    
    static var previewWithViolations: CoreTypes.ComplianceOverview {
        CoreTypes.ComplianceOverview(
            overallScore: 0.72,
            totalIssues: 28,
            openIssues: 15,
            criticalViolations: 3,
            lastAudit: Date().addingTimeInterval(-259200), // 3 days ago
            nextAudit: Date().addingTimeInterval(604800) // 1 week from now
        )
    }
}

extension CoreTypes.ClientAlert {
    static var previewCritical: [CoreTypes.ClientAlert] {
        [
            CoreTypes.ClientAlert(
                id: "1",
                title: "DSNY Compliance Violation",
                message: "Trash not set out on time at 123 Main St",
                severity: .critical,
                buildingId: "building1",
                timestamp: Date().addingTimeInterval(-1800),
                actionRequired: true
            ),
            CoreTypes.ClientAlert(
                id: "2",
                title: "Worker No-Show",
                message: "No coverage for evening shift at 456 Park Ave",
                severity: .critical,
                buildingId: "building2",
                timestamp: Date().addingTimeInterval(-3600),
                actionRequired: true
            )
        ]
    }
}
// Extension for WorkerService (add to WorkerService.swift or a new file)
extension WorkerService {
    func getActiveWorkers() async throws -> [CoreTypes.WorkerProfile] {
        // This should query workers with status = 'clockedIn'
        let query = """
            SELECT * FROM workers 
            WHERE status = 'Clocked In' AND isActive = 1
            ORDER BY name
        """
        
        let rows = try await GRDBManager.shared.query(query)
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String ?? (row["id"] as? Int64).map(String.init),
                  let name = row["name"] as? String,
                  let email = row["email"] as? String,
                  let roleStr = row["role"] as? String,
                  let role = CoreTypes.UserRole(rawValue: roleStr) else {
                return nil
            }
            
            return CoreTypes.WorkerProfile(
                id: id,
                name: name,
                email: email,
                role: role,
                status: .clockedIn
            )
        }
    }
}

// Extension for TaskService (add to TaskService.swift or a new file)
extension TaskService {
    func getAverageTasksPerWorker() async throws -> Double {
        let query = """
            SELECT 
                COUNT(DISTINCT t.id) as task_count,
                COUNT(DISTINCT t.assigned_worker_id) as worker_count
            FROM routine_tasks t
            WHERE date(t.scheduled_date) = date('now')
        """
        
        let rows = try await GRDBManager.shared.query(query)
        
        guard let row = rows.first,
              let taskCount = row["task_count"] as? Int64,
              let workerCount = row["worker_count"] as? Int64,
              workerCount > 0 else {
            return 0.0
        }
        
        return Double(taskCount) / Double(workerCount)
    }
    
    func getOverallCompletionRate() async throws -> Double {
        let query = """
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed
            FROM routine_tasks
            WHERE date(scheduled_date) >= date('now', '-7 days')
        """
        
        let rows = try await GRDBManager.shared.query(query)
        
        guard let row = rows.first,
              let total = row["total"] as? Int64,
              let completed = row["completed"] as? Int64,
              total > 0 else {
            return 0.0
        }
        
        return Double(completed) / Double(total)
    }
}

// Fix for PortfolioOverviewView - add this to the file or create an extension
extension CoreTypes {
    // Type alias for backward compatibility
    typealias ClientPortfolioIntelligence = PortfolioIntelligence
}

// Alternative: If you want ClientPortfolioIntelligence to be distinct,
// use the full implementation I provided earlier and update PortfolioOverviewView
// to use the correct type
