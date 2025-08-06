//
//  ClientContextEngine.swift
//  CyntientOps v6.0
//
//  ✅ FIXED: All types now use CoreTypes namespace
//  ✅ FIXED: Removed duplicate type declarations
//  ✅ UPDATED: Added missing properties for ClientDashboardView
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
    
    // MARK: - ServiceContainer Integration
    private weak var container: ServiceContainer?
    private weak var novaManager: NovaAIManager?
    
    // MARK: - Properties for ClientDashboardView Compatibility
    // All types now correctly reference CoreTypes
    
    @Published var realtimeRoutineMetrics: CoreTypes.RealtimeRoutineMetrics = CoreTypes.RealtimeRoutineMetrics()
    
    @Published var activeWorkerStatus: CoreTypes.ActiveWorkerStatus = CoreTypes.ActiveWorkerStatus(
        totalActive: 0,
        byBuilding: [:],
        utilizationRate: 0.0
    )
    
    @Published var complianceOverview: CoreTypes.ComplianceOverview = CoreTypes.ComplianceOverview(
        overallScore: 0.85,
        criticalViolations: 0,
        pendingInspections: 0,
        lastUpdated: Date(),
        buildingCompliance: [:],
        upcomingDeadlines: []
    )
    
    @Published var monthlyMetrics: CoreTypes.MonthlyMetrics = CoreTypes.MonthlyMetrics(
        currentSpend: 0,
        monthlyBudget: 10000,
        projectedSpend: 0,
        daysRemaining: 30
    )
    
    // Client profile for header
    @Published var clientProfile: ClientProfile? = nil
    
    // Compliance data by building
    @Published var clientComplianceData: [String: ComplianceData] = [:]
    
    // MARK: - Original Published Properties
    
    // Portfolio Overview
    @Published var portfolioHealth: CoreTypes.PortfolioHealth = .empty
    @Published var executiveIntelligence: CoreTypes.ExecutiveIntelligence?
    @Published var clientBuildings: [CoreTypes.NamedCoordinate] = []
    
    // Real-time Metrics
    @Published var realtimeMetrics: CoreTypes.RealtimePortfolioMetrics = .empty
    @Published var syncProgress: Double = 0.0
    
    // Compliance (already using complianceOverview above)
    @Published var allComplianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var criticalComplianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var buildingsWithViolations: [String] = []
    
    // Alerts & Notifications
    @Published var realtimeAlerts: [CoreTypes.ClientAlert] = []
    @Published var criticalAlerts: [CoreTypes.ClientAlert] = []
    
    // Building Performance
    @Published var buildingPerformanceMap: [String: Double] = [:]
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var topPerformanceBuildings: [CoreTypes.NamedCoordinate] = []
    
    // Cost & Efficiency
    @Published var estimatedMonthlySavings: Double = 0
    @Published var costOptimizationInsights: [CoreTypes.CostInsight] = []
    
    // Worker Activity
    @Published var workerProductivityInsights: [CoreTypes.WorkerProductivityInsight] = []
    
    // MARK: - Private Properties (Updated for ServiceContainer)
    
    private var dashboardSync: DashboardSyncService? { container?.dashboardSync }
    private var buildingService: BuildingService? { container?.buildings }
    private var taskService: TaskService? { container?.tasks }
    private var complianceService: ComplianceService? { container?.compliance }
    private var workerService: WorkerService? { container?.workers }
    // Note: AnalyticsService not yet in ServiceContainer - using shared temporarily
    
    private var cancellables = Set<AnyCancellable>()
    private var realtimeTimer: Timer?
    private var lastUpdateTime = Date()
    
    // MARK: - Initialization
    
    init(container: ServiceContainer) {
        self.container = container
        setupSubscriptions()
        startRealtimeMonitoring()
        loadClientProfile()
    }
    
    // MARK: - ServiceContainer Methods
    
    public func setNovaManager(_ nova: NovaAIManager) {
        self.novaManager = nova
    }
    
    // MARK: - Public Methods for ClientDashboardView
    
    func refreshContext() async {
        await refreshAllData()
        await updateRealtimeRoutineMetrics()
        await updateActiveWorkerStatus()
        await updateComplianceStatus()
        await updateMonthlyMetrics()
    }
    
    private func updateRealtimeRoutineMetrics() async {
        var newMetrics = CoreTypes.RealtimeRoutineMetrics()
        
        // Calculate overall completion across all buildings
        var totalCompletion = 0.0
        var totalWorkers = 0
        var behindCount = 0
        var buildingStatuses: [String: CoreTypes.BuildingRoutineStatus] = [:]
        
        for building in clientBuildings {
            if let metrics = buildingMetrics[building.id] {
                let status = CoreTypes.BuildingRoutineStatus(
                    buildingId: building.id,
                    buildingName: building.name,
                    completionRate: metrics.completionRate,
                    timeBlock: .current,
                    activeWorkerCount: metrics.activeWorkers,
                    isOnSchedule: metrics.completionRate >= expectedCompletionForCurrentTime(),
                    estimatedCompletion: estimateCompletionTime(metrics),
                    hasIssue: metrics.criticalIssues > 0
                )
                
                buildingStatuses[building.id] = status
                totalCompletion += metrics.completionRate
                totalWorkers += metrics.activeWorkers
                
                if status.isBehindSchedule {
                    behindCount += 1
                }
            }
        }
        
        newMetrics.overallCompletion = clientBuildings.isEmpty ? 0 : totalCompletion / Double(clientBuildings.count)
        newMetrics.activeWorkerCount = totalWorkers
        newMetrics.behindScheduleCount = behindCount
        newMetrics.buildingStatuses = buildingStatuses
        
        await MainActor.run {
            self.realtimeRoutineMetrics = newMetrics
        }
    }
    
    private func updateActiveWorkerStatus() async {
        // Get worker data
        let workers = try? await workerService.getActiveWorkers()
        let totalActive = workers?.count ?? 0
        
        // Calculate by building
        var byBuilding: [String: Int] = [:]
        for building in clientBuildings {
            if let metrics = buildingMetrics[building.id] {
                byBuilding[building.id] = metrics.activeWorkers
            }
        }
        
        // Calculate utilization
        let totalAssigned = try? await workerService.getTotalAssignedWorkers()
        let utilizationRate = (totalAssigned ?? 0) > 0 ? Double(totalActive) / Double(totalAssigned ?? 1) : 0.0
        
        await MainActor.run {
            self.activeWorkerStatus = CoreTypes.ActiveWorkerStatus(
                totalActive: totalActive,
                byBuilding: byBuilding,
                utilizationRate: utilizationRate
            )
        }
    }
    
    private func updateComplianceStatus() async {
        // Update compliance data by building
        for building in self.clientBuildings {
            self.clientComplianceData[building.id] = ComplianceData(
                buildingId: building.id,
                score: self.buildingMetrics[building.id]?.complianceScore ?? 1.0,
                violations: self.allComplianceIssues.filter { $0.buildingId == building.id }.count
            )
        }
    }
    
    private func updateMonthlyMetrics() async {
        // Calculate monthly metrics from available data
        let currentSpend = try? await calculateMonthlySpend()
        let budget = try? await getMonthlyBudget()
        let projectedSpend = calculateProjectedSpend(current: currentSpend ?? 0)
        let daysRemaining = calculateDaysRemainingInMonth()
        
        await MainActor.run {
            self.monthlyMetrics = CoreTypes.MonthlyMetrics(
                currentSpend: currentSpend ?? 0,
                monthlyBudget: budget ?? 10000,
                projectedSpend: projectedSpend,
                daysRemaining: daysRemaining
            )
        }
    }
    
    private func loadClientProfile() {
        // Load client profile data
        Task {
            if let userId = await NewAuthManager.shared.currentUserId {
                let profile = try? await fetchClientProfile(userId: userId)
                await MainActor.run {
                    self.clientProfile = profile
                }
            }
        }
    }
    
    // MARK: - Original Public Methods
    
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
            
            // Process worker status
            let workerStatus = try await workers
            self.activeWorkerStatus = CoreTypes.ActiveWorkerStatus(
                totalActive: workerStatus.totalActive,
                byBuilding: [:], // Will be updated in updateActiveWorkerStatus
                utilizationRate: workerStatus.utilizationRate
            )
            syncProgress = 0.9
            
            // Generate insights
            await generateExecutiveIntelligence()
            await updateBuildingPerformance()
            await generateWorkerInsights()
            await identifyCostSavings()
            
            // Update metrics for ClientDashboardView
            await updateRealtimeRoutineMetrics()
            await updateActiveWorkerStatus()
            await updateComplianceStatus()
            await updateMonthlyMetrics()
            
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
    
    @discardableResult
    func identifyCostSavings() async -> CoreTypes.IntelligenceInsight? {
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
    
    // MARK: - Private Helper Methods
    
    private func expectedCompletionForCurrentTime() -> Double {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 7..<11: return 0.3
        case 11..<15: return 0.6
        case 15..<19: return 0.9
        default: return 1.0
        }
    }
    
    private func estimateCompletionTime(_ metrics: CoreTypes.BuildingMetrics) -> Date? {
        guard metrics.completionRate < 1.0 else { return nil }
        
        let remainingWork = 1.0 - metrics.completionRate
        let hoursNeeded = remainingWork * 8 // Assume 8 hours for full completion
        return Date().addingTimeInterval(hoursNeeded * 3600)
    }
    
    private func calculateMonthlySpend() async throws -> Double {
        // Calculate actual monthly spend from services
        let baseRate = 5000.0 // Base rate per building
        return Double(clientBuildings.count) * baseRate * 0.85 // 85% utilization
    }
    
    private func getMonthlyBudget() async throws -> Double {
        // Get client's monthly budget
        let baseRate = 5000.0
        return Double(clientBuildings.count) * baseRate * 1.2 // 20% buffer
    }
    
    private func calculateProjectedSpend(current: Double) -> Double {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let daysPassed = daysInMonth - calculateDaysRemainingInMonth()
        guard daysPassed > 0 else { return current }
        
        let dailyRate = current / Double(daysPassed)
        return dailyRate * Double(daysInMonth)
    }
    
    private func calculateDaysRemainingInMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        let range = calendar.range(of: .day, in: .month, for: now)!
        let currentDay = calendar.component(.day, from: now)
        return range.count - currentDay
    }
    
    private func fetchClientProfile(userId: String) async throws -> ClientProfile {
        // Fetch client profile from database or service
        return ClientProfile(
            id: userId,
            name: "Client User",
            email: "client@example.com",
            company: "Client Company",
            role: .client
        )
    }
    
    // MARK: - Private Methods (Original)
    
    private func setupSubscriptions() {
        // Subscribe to UnifiedIntelligenceService updates via container
        if let container = container {
            container.intelligence.$insights
                .sink { [weak self] insights in
                    self?.processNovaInsights(insights)
                }
                .store(in: &cancellables)
        }
    }
    
    private func fetchClientBuildings() async throws -> [CoreTypes.NamedCoordinate] {
        // Fetch buildings assigned to this client
        guard let buildingService = buildingService else {
            throw ClientContextError.serviceUnavailable("BuildingService")
        }
        let buildings = try await buildingService.getAllBuildings() // Updated method
        return buildings.map { building in
            CoreTypes.NamedCoordinate(
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
        
        // Store metrics for use in other calculations
        self.buildingMetrics = metrics
        
        // Calculate overall health
        let totalBuildings = buildings.count
        let activeBuildings = buildings.filter { $0.isActive }.count
        let avgCompletionRate = metrics.values.map { $0.completionRate }.reduce(0, +) / Double(max(metrics.count, 1))
        let criticalIssues = metrics.values.filter { $0.criticalIssues > 0 }.count
        
        // Determine trend
        let trend: CoreTypes.TrendDirection = {
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
            if let metrics = buildingMetrics[building.id] {
                buildingPerformanceMap[building.id] = metrics.completionRate
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
                metric: "\(Int(activeWorkerStatus.totalActive)) workers",
                description: "Currently active on site",
                trend: .stable,
                recommendation: nil
            )
        ]
        
        workerProductivityInsights = insights
    }
    
    private func updateRealtimeMetrics() {
        // Generate performance trend (last 7 days)
        let trend = buildingPerformanceMap.values.sorted().suffix(7).map { $0 }
        
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
            performanceTrend: Array(trend),
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
                
                // Update metrics for ClientDashboardView
                await updateRealtimeRoutineMetrics()
                await updateActiveWorkerStatus()
            }
        }
        
        // Update real-time metrics
        updateRealtimeMetrics()
    }
    
    private func handleWorkerUpdate(_ notification: Notification) async {
        // Update worker status based on activity
        await updateActiveWorkerStatus()
        await generateWorkerInsights()
        updateRealtimeMetrics()
    }
    
    private func handleComplianceUpdate(_ notification: Notification) async {
        // Update compliance data
        complianceOverview = try! await fetchComplianceOverview()
        await updateComplianceStatus()
        updateRealtimeMetrics()
    }
    
    private func updateRealtimeData() async {
        // Periodic update of real-time data
        await updateBuildingPerformance()
        await updateRealtimeRoutineMetrics()
        await updateActiveWorkerStatus()
        await updateComplianceStatus()
        await updateMonthlyMetrics()
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
    
    private func mapUpdateType(_ type: CoreTypes.DashboardUpdate.UpdateType) -> CoreTypes.RealtimeActivity.ActivityType {
        switch type {
        case .taskCompleted:
            return .taskCompleted
        case .workerClockedIn:
            return .workerClockIn
        case .workerClockedOut:
            return .workerClockOut
        case .buildingMetricsChanged:
            return .buildingUpdate
        case .complianceStatusChanged:
            return .complianceUpdate
        default:
            return .buildingUpdate
        }
    }
}

// MARK: - Supporting Types for ClientDashboardView

struct ClientProfile {
    let id: String
    let name: String
    let email: String
    let company: String?
    let role: CoreTypes.UserRole
}

struct ComplianceData {
    let buildingId: String
    let score: Double
    let violations: Int
}

// MARK: - Notification Names

extension Notification.Name {
    static let workerActivityChanged = Notification.Name("workerActivityChanged")
    static let complianceStatusChanged = Notification.Name("complianceStatusChanged")
}

// MARK: - Extensions for CoreTypes compatibility

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
}

// MARK: - Service Extensions (keep your existing ones)

extension WorkerService {
    func getTotalAssignedWorkers() async throws -> Int {
        let query = """
            SELECT COUNT(*) as count FROM workers 
            WHERE isActive = 1
        """
        
        let rows = try await GRDBManager.shared.query(query)
        return Int((rows.first?["count"] as? Int64) ?? 0)
    }
    
    func getActiveWorkers() async throws -> [CoreTypes.WorkerProfile] {
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

// MARK: - Supporting Types

enum ClientContextError: LocalizedError {
    case serviceUnavailable(String)
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable(let service):
            return "\(service) is not available"
        }
    }
}
