//
//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ OPTIMIZED: Thin orchestration layer over ClientContextEngine
//  ✅ NO REDUNDANCY: Single source of truth via ClientContextEngine
//  ✅ PERFORMANCE: Debounced updates and smart caching
//  ✅ LOCALIZED: Comprehensive error handling with user-friendly messages
//

import Foundation
import SwiftUI
import Combine

@MainActor
public final class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - UI State Only (No Data Duplication)
    @Published public var selectedBuildingId: String?
    @Published public var selectedDateRange: DateRange = .thisMonth
    @Published public var isLoading = false
    @Published public var isRefreshing = false
    @Published public var errorMessage: String?
    @Published public var successMessage: String?
    @Published public var lastUpdateTime: Date?
    
    // MARK: - Filter & View Options
    @Published public var filterOptions = ClientFilterOptions()
    @Published public var sortOption: SortOption = .performanceDesc
    @Published public var viewMode: ViewMode = .grid
    
    // MARK: - Sheet Management
    @Published public var activeSheet: SheetType?
    @Published public var selectedInsightId: String?
    @Published public var selectedComplianceIssueId: String?
    
    // MARK: - Search & Selection
    @Published public var searchQuery = ""
    @Published public var selectedBuildingIds = Set<String>()
    
    // MARK: - Single Source of Truth
    private let contextEngine = ClientContextEngine.shared
    private let dashboardSync = DashboardSyncService.shared
    private let analyticsService = AnalyticsService.shared
    private let reportService = ReportService.shared
    
    // MARK: - Performance Optimization
    private let updateDebouncer = Debouncer(delay: 0.3)
    private let searchDebouncer = Debouncer(delay: 0.5)
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    
    // MARK: - Computed Properties (Read from ContextEngine)
    
    public var portfolioHealth: CoreTypes.PortfolioHealth {
        contextEngine.portfolioHealth
    }
    
    public var buildings: [CoreTypes.NamedCoordinate] {
        contextEngine.clientBuildings
    }
    
    public var filteredBuildings: [CoreTypes.NamedCoordinate] {
        let searchFiltered = searchQuery.isEmpty ? buildings : buildings.filter { building in
            building.name.localizedCaseInsensitiveContains(searchQuery)
        }
        
        return searchFiltered.sorted { lhs, rhs in
            switch sortOption {
            case .nameAsc:
                return lhs.name < rhs.name
            case .nameDesc:
                return lhs.name > rhs.name
            case .performanceAsc:
                let lhsPerf = contextEngine.buildingPerformanceMap[lhs.id] ?? 0
                let rhsPerf = contextEngine.buildingPerformanceMap[rhs.id] ?? 0
                return lhsPerf < rhsPerf
            case .performanceDesc:
                let lhsPerf = contextEngine.buildingPerformanceMap[lhs.id] ?? 0
                let rhsPerf = contextEngine.buildingPerformanceMap[rhs.id] ?? 0
                return lhsPerf > rhsPerf
            }
        }
    }
    
    public var hasActiveAlerts: Bool {
        !contextEngine.criticalAlerts.isEmpty
    }
    
    public var totalActiveWorkers: Int {
        contextEngine.activeWorkerStatus.totalActive
    }
    
    public var overallComplianceScore: Double {
        contextEngine.complianceOverview.overallScore
    }
    
    public var hasCriticalSituation: Bool {
        contextEngine.portfolioHealth.criticalIssues > 0 ||
        contextEngine.complianceOverview.criticalViolations > 0
    }
    
    // MARK: - Initialization
    
    public init() {
        setupSubscriptions()
        setupSearchDebouncing()
        
        // Track initialization
        analyticsService.track(.dashboardOpened, properties: ["type": "client"])
    }
    
    deinit {
        refreshTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Primary refresh method - delegates to ContextEngine
    public func refreshDashboard() async {
        guard !isRefreshing else { return }
        
        await MainActor.run {
            isRefreshing = true
            errorMessage = nil
        }
        
        // Cancel any existing refresh
        refreshTask?.cancel()
        
        refreshTask = Task {
            do {
                // Haptic feedback
                await provideHapticFeedback(.medium)
                
                // Refresh via ContextEngine (single source of truth)
                await contextEngine.refreshAllData()
                
                await MainActor.run {
                    lastUpdateTime = Date()
                    isRefreshing = false
                    
                    // Show success briefly
                    successMessage = NSLocalizedString(
                        "dashboard_refreshed",
                        value: "Dashboard updated",
                        comment: "Success message after refresh"
                    )
                }
                
                // Clear success message after delay
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                    await MainActor.run {
                        successMessage = nil
                    }
                }
                
                // Track successful refresh
                analyticsService.track(.dashboardRefreshed)
                
            } catch {
                await handleError(error, context: "refresh")
            }
        }
    }
    
    /// Quick refresh for specific building
    public func refreshBuilding(_ buildingId: String) async {
        do {
            await contextEngine.updateBuildingPerformance(for: buildingId)
            
            // Broadcast focused update
            let update = CoreTypes.DashboardUpdate(
                source: .client,
                type: .buildingUpdate,
                buildingId: buildingId,
                workerId: "",
                data: ["action": "buildingRefreshed"]
            )
            dashboardSync.broadcastUpdate(update)
            
        } catch {
            await handleError(error, context: "building_refresh")
        }
    }
    
    /// Export current view as report
    public func exportReport() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let reportData = ClientPortfolioReport(
            generatedAt: Date(),
            dateRange: selectedDateRange,
            portfolioHealth: contextEngine.portfolioHealth,
            buildings: filteredBuildings,
            buildingMetrics: contextEngine.buildingMetrics,
            complianceOverview: contextEngine.complianceOverview,
            insights: contextEngine.executiveIntelligence?.keyInsights ?? []
        )
        
        let url = try await reportService.generateClientReport(reportData)
        
        // Track export
        analyticsService.track(.reportExported, properties: [
            "type": "portfolio",
            "format": "pdf",
            "buildingCount": reportData.buildings.count
        ])
        
        // Show share sheet
        await showShareSheet(for: url)
    }
    
    /// Handle building selection
    public func selectBuilding(_ building: CoreTypes.NamedCoordinate) {
        selectedBuildingId = building.id
        activeSheet = .buildingDetail
        
        analyticsService.track(.buildingSelected, properties: [
            "buildingId": building.id,
            "source": "dashboard"
        ])
    }
    
    /// Handle compliance issue selection
    public func selectComplianceIssue(_ issueId: String) {
        selectedComplianceIssueId = issueId
        activeSheet = .complianceDetail
    }
    
    /// Toggle building in multi-selection
    public func toggleBuildingSelection(_ buildingId: String) {
        if selectedBuildingIds.contains(buildingId) {
            selectedBuildingIds.remove(buildingId)
        } else {
            selectedBuildingIds.insert(buildingId)
        }
    }
    
    /// Batch operations on selected buildings
    public func performBatchAction(_ action: BatchAction) async {
        guard !selectedBuildingIds.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        switch action {
        case .generateReports:
            await generateBatchReports()
        case .scheduleInspections:
            await scheduleBatchInspections()
        case .exportData:
            await exportBatchData()
        }
        
        // Clear selection after action
        selectedBuildingIds.removeAll()
    }
    
    // MARK: - Private Setup Methods
    
    private func setupSubscriptions() {
        // Subscribe to context engine updates (already debounced there)
        contextEngine.$portfolioHealth
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // Subscribe to sync updates
        dashboardSync.clientDashboardUpdates
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        // Monitor error states
        contextEngine.$syncProgress
            .filter { $0 == 0 && self.isRefreshing }
            .sink { [weak self] _ in
                Task {
                    await self?.handleError(
                        ClientError.syncFailed,
                        context: "sync"
                    )
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupSearchDebouncing() {
        $searchQuery
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query)
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(_ query: String) {
        // Filtering is handled by computed property
        // Track search usage
        if !query.isEmpty {
            analyticsService.track(.searchPerformed, properties: [
                "context": "buildings",
                "resultCount": filteredBuildings.count
            ])
        }
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        // Only handle client-relevant updates
        guard update.source == .client || update.source == .admin else { return }
        
        updateDebouncer.debounce { [weak self] in
            Task {
                // Light refresh for specific update types
                switch update.type {
                case .complianceUpdate:
                    await self?.contextEngine.monitorComplianceChanges()
                case .buildingUpdate where !update.buildingId.isEmpty:
                    await self?.contextEngine.updateBuildingPerformance(for: update.buildingId)
                default:
                    break
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error, context: String) async {
        await MainActor.run {
            isLoading = false
            isRefreshing = false
            
            // Localized error messages
            let errorKey = "error_\(context)"
            let fallbackMessage = NSLocalizedString(
                "error_generic",
                value: "Something went wrong. Please try again.",
                comment: "Generic error message"
            )
            
            let localizedMessage = NSLocalizedString(
                errorKey,
                value: fallbackMessage,
                comment: "Error for \(context)"
            )
            
            errorMessage = "\(localizedMessage) \(error.localizedDescription)"
            
            // Track error
            analyticsService.track(.errorOccurred, properties: [
                "context": context,
                "error": String(describing: error)
            ])
        }
        
        // Haptic feedback for error
        await provideHapticFeedback(.error)
    }
    
    // MARK: - Batch Operations
    
    private func generateBatchReports() async {
        // Implementation for batch report generation
        for buildingId in selectedBuildingIds {
            if let building = buildings.first(where: { $0.id == buildingId }) {
                // Generate individual report
                await generateBuildingReport(building)
            }
        }
    }
    
    private func scheduleBatchInspections() async {
        // Implementation for batch inspection scheduling
    }
    
    private func exportBatchData() async {
        // Implementation for batch data export
    }
    
    private func generateBuildingReport(_ building: CoreTypes.NamedCoordinate) async {
        // Implementation for single building report
    }
    
    // MARK: - UI Helpers
    
    private func provideHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) async {
        await MainActor.run {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    private func showShareSheet(for url: URL) async {
        await MainActor.run {
            // Implementation depends on your app's share sheet handling
            activeSheet = .share(url)
        }
    }
    
    // MARK: - Supporting Types
    
    public enum DateRange: String, CaseIterable {
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        case thisQuarter = "This Quarter"
        case thisYear = "This Year"
        case custom = "Custom"
    }
    
    public enum SortOption {
        case nameAsc
        case nameDesc
        case performanceAsc
        case performanceDesc
    }
    
    public enum ViewMode {
        case grid
        case list
        case map
    }
    
    public enum BatchAction {
        case generateReports
        case scheduleInspections
        case exportData
    }
    
    public enum SheetType: Identifiable {
        case buildingDetail
        case complianceDetail
        case workerOverview
        case costAnalysis
        case reports
        case settings
        case share(URL)
        
        public var id: String {
            switch self {
            case .buildingDetail: return "building"
            case .complianceDetail: return "compliance"
            case .workerOverview: return "workers"
            case .costAnalysis: return "costs"
            case .reports: return "reports"
            case .settings: return "settings"
            case .share: return "share"
            }
        }
    }
    
    public struct ClientFilterOptions {
        var showOnlyActiveBuildings = true
        var showOnlyBuildingsWithIssues = false
        var minimumPerformanceThreshold: Double = 0.0
        var selectedBuildingTypes: Set<CoreTypes.BuildingType> = []
    }
    
    enum ClientError: LocalizedError {
        case syncFailed
        case reportGenerationFailed
        case dataExportFailed
        
        var errorDescription: String? {
            switch self {
            case .syncFailed:
                return NSLocalizedString("error_sync_failed", value: "Failed to sync data", comment: "")
            case .reportGenerationFailed:
                return NSLocalizedString("error_report_failed", value: "Failed to generate report", comment: "")
            case .dataExportFailed:
                return NSLocalizedString("error_export_failed", value: "Failed to export data", comment: "")
            }
        }
    }
}

// MARK: - Performance Utilities

private final class Debouncer {
    private let delay: TimeInterval
    private var workItem: DispatchWorkItem?
    private let queue: DispatchQueue
    
    init(delay: TimeInterval, queue: DispatchQueue = .main) {
        self.delay = delay
        self.queue = queue
    }
    
    func debounce(action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        queue.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
    
    func cancel() {
        workItem?.cancel()
    }
}

// MARK: - Report Data Structure

struct ClientPortfolioReport {
    let generatedAt: Date
    let dateRange: ClientDashboardViewModel.DateRange
    let portfolioHealth: CoreTypes.PortfolioHealth
    let buildings: [CoreTypes.NamedCoordinate]
    let buildingMetrics: [String: CoreTypes.BuildingMetrics]
    let complianceOverview: CoreTypes.ComplianceOverview
    let insights: [String]
}te func loadBuildingMetrics() async {
        for building in buildingsList {
            do {
                let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                buildingMetrics[building.id] = metrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        // Create and broadcast update
        let update = CoreTypes.DashboardUpdate(
            source: CoreTypes.DashboardUpdate.Source.client,
            type: CoreTypes.DashboardUpdate.UpdateType.buildingMetricsChanged,
            buildingId: "",  // Empty string for portfolio-wide update
            workerId: "",    // Empty string when not worker-specific
            data: [
                "buildingCount": String(buildingMetrics.count),
                "averageCompletion": String(calculateAverageCompletion())
            ]
        )
        broadcastDashboardUpdate(update)
    }
    
    /// Generate compliance issues from task data
    private func generateComplianceIssues() async {
        do {
            // Get all tasks
            let allTasks = try await taskService.getAllTasks()
            
            // Generate compliance issues from overdue and critical tasks
            var issues: [CoreTypes.ComplianceIssue] = []
            
            // Check for overdue tasks
            let overdueTasks = allTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            // Create compliance issues for overdue tasks grouped by building
            let overdueByBuilding = Dictionary(grouping: overdueTasks) { $0.buildingId ?? "unknown" }
            
            for (buildingId, tasks) in overdueByBuilding {
                if tasks.count > 2 {
                    let buildingName = buildingsList.first { $0.id == buildingId }?.name ?? "Building \(buildingId)"
                    
                    issues.append(CoreTypes.ComplianceIssue(
                        title: "Multiple Overdue Tasks",
                        description: "\(tasks.count) overdue tasks at \(buildingName) require immediate attention",
                        severity: tasks.count > 5 ? .critical : .high,
                        buildingId: buildingId,
                        status: .open,
                        createdAt: Date()
                    ))
                }
            }
            
            // Check for inspection tasks
            let inspectionTasks = allTasks.filter { $0.category == .inspection }
            let overdueInspections = inspectionTasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
            
            if overdueInspections.count > 0 {
                issues.append(CoreTypes.ComplianceIssue(
                    title: "Overdue Inspections",
                    description: "\(overdueInspections.count) inspection tasks are overdue across the portfolio",
                    severity: .critical,
                    buildingId: nil,
                    status: .open,
                    createdAt: Date()
                ))
            }
            
            // Check for safety-related tasks
            let safetyTasks = allTasks.filter { task in
                let title = task.title.lowercased()
                return title.contains("safety") || title.contains("hazard") || title.contains("emergency")
            }
            
            let incompleteSafetyTasks = safetyTasks.filter { !$0.isCompleted }
            
            if incompleteSafetyTasks.count > 3 {
                issues.append(CoreTypes.ComplianceIssue(
                    title: "Safety Tasks Pending",
                    description: "\(incompleteSafetyTasks.count) safety-related tasks need completion",
                    severity: .high,
                    buildingId: nil,
                    status: .open,
                    createdAt: Date()
                ))
            }
            
            self.complianceIssues = issues
            
            // Count critical issues
            criticalIssues = issues.filter { $0.severity == .critical }.count
            
            print("✅ Generated \(issues.count) compliance issues (\(criticalIssues) critical)")
            
        } catch {
            print("⚠️ Failed to generate compliance issues: \(error)")
            self.complianceIssues = []
        }
    }
    
    /// Load AI-generated intelligence insights using the actual service method
    private func loadIntelligenceInsights() async {
        isLoadingInsights = true
        
        do {
            // Use the actual method that exists in IntelligenceService
            let insights = try await intelligenceService.generatePortfolioInsights()
            self.intelligenceInsights = insights
            isLoadingInsights = false
            
            print("✅ Loaded \(insights.count) intelligence insights")
            
        } catch {
            self.intelligenceInsights = []
            isLoadingInsights = false
            print("⚠️ Failed to load intelligence insights: \(error)")
        }
    }
    
    /// Generate executive summary from available data
    private func generateExecutiveSummary() async {
        // Generate summary from existing data
        self.executiveSummary = CoreTypes.ExecutiveSummary(
            totalBuildings: totalBuildings,
            totalWorkers: activeWorkers,
            portfolioHealth: completionRate,
            monthlyPerformance: monthlyTrend.rawValue,
            generatedAt: Date()
        )
        
        print("✅ Executive summary generated")
    }
    
    /// Generate strategic recommendations from insights
    private func loadStrategicRecommendations() async {
        // Generate recommendations from insights and metrics
        var recommendations: [CoreTypes.StrategicRecommendation] = []
        
        // Analyze completion rate
        if completionRate < 0.7 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Improve Task Completion Rate",
                description: "Current completion rate of \(Int(completionRate * 100))% is below target. Consider adding resources or reviewing task assignments.",
                category: .operations,
                priority: .high,
                timeframe: "Next 30 days",
                estimatedImpact: "15-20% improvement in efficiency"
            ))
        }
        
        // Analyze critical issues
        if criticalIssues > 5 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Address Critical Compliance Issues",
                description: "\(criticalIssues) critical issues require immediate attention to avoid penalties and ensure safety.",
                category: .compliance,
                priority: .critical,
                timeframe: "Immediate",
                estimatedImpact: "Risk mitigation and compliance restoration"
            ))
        }
        
        // Analyze worker efficiency
        if activeWorkers > 0 && totalBuildings > 0 {
            let buildingsPerWorker = Double(totalBuildings) / Double(activeWorkers)
            if buildingsPerWorker > 3 {
                recommendations.append(CoreTypes.StrategicRecommendation(
                    title: "Optimize Worker Distribution",
                    description: "Each worker is covering \(String(format: "%.1f", buildingsPerWorker)) buildings on average. Consider hiring additional staff.",
                    category: .operations,
                    priority: .medium,
                    timeframe: "Next quarter",
                    estimatedImpact: "Improved coverage and response times"
                ))
            }
        }
        
        // Analyze from insights
        let highPriorityInsights = intelligenceInsights.filter { $0.priority == .high || $0.priority == .critical }
        if highPriorityInsights.count > 3 {
            recommendations.append(CoreTypes.StrategicRecommendation(
                title: "Focus on High-Priority Issues",
                description: "\(highPriorityInsights.count) high-priority insights require strategic attention for portfolio optimization.",
                category: .operations,
                priority: .high,
                timeframe: "Next 60 days",
                estimatedImpact: "Significant operational improvements"
            ))
        }
        
        self.strategicRecommendations = recommendations
        
        print("✅ Generated \(recommendations.count) strategic recommendations")
    }
    
    /// Generate portfolio benchmarks from metrics
    private func loadPortfolioBenchmarks() async {
        var benchmarks: [CoreTypes.PortfolioBenchmark] = []
        
        // Task completion benchmark
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Task Completion",
            value: completionRate,
            benchmark: 0.90,
            trend: monthlyTrend.rawValue,
            period: "This Month"
        ))
        
        // Compliance benchmark
        let complianceRate = Double(complianceScore) / 100.0
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Compliance Score",
            value: complianceRate,
            benchmark: 0.95,
            trend: complianceRate >= 0.90 ? "Stable" : "Declining",
            period: "This Month"
        ))
        
        // Worker efficiency benchmark
        if activeWorkers > 0 && totalBuildings > 0 {
            let buildingsPerWorker = Double(totalBuildings) / Double(activeWorkers)
            let efficiency = min(3.0 / buildingsPerWorker, 1.0) // Optimal is 3 buildings per worker
            
            benchmarks.append(CoreTypes.PortfolioBenchmark(
                metric: "Worker Efficiency",
                value: efficiency,
                benchmark: 1.0,
                trend: efficiency >= 0.8 ? "Stable" : "Declining",
                period: "This Month"
            ))
        }
        
        // Response time benchmark (simulated from metrics)
        let avgResponseTime = buildingMetrics.values.compactMap { $0.averageTaskTime }.reduce(0, +) / Double(max(buildingMetrics.count, 1))
        let responseEfficiency = avgResponseTime > 0 ? min(120.0 / avgResponseTime, 1.0) : 0.85 // 120 minutes is target
        
        benchmarks.append(CoreTypes.PortfolioBenchmark(
            metric: "Response Time",
            value: responseEfficiency,
            benchmark: 1.0,
            trend: "Stable",
            period: "This Month"
        ))
        
        self.portfolioBenchmarks = benchmarks
        
        print("✅ Generated \(benchmarks.count) portfolio benchmarks")
    }
    
    // MARK: - Helper Methods
    
    private func calculateAverageCompletion() -> Double {
        guard !buildingMetrics.isEmpty else { return 0.0 }
        
        let totalCompletion = buildingMetrics.values.reduce(0) { $0 + $1.completionRate }
        return totalCompletion / Double(buildingMetrics.count)
    }
    
    /// Load fallback data when services fail
    private func loadFallbackData() async {
        print("📱 Loading fallback data for client dashboard")
        
        // Create minimal portfolio intelligence
        portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 0,
            activeWorkers: 0,
            completionRate: 0.0,
            criticalIssues: 0,
            monthlyTrend: .unknown,
            complianceScore: 0.0,
            generatedAt: Date()
        )
        
        // Create fallback executive summary
        executiveSummary = CoreTypes.ExecutiveSummary(
            totalBuildings: 0,
            totalWorkers: 0,
            portfolioHealth: 0.0,
            monthlyPerformance: "Unknown",
            generatedAt: Date()
        )
        
        portfolioBenchmarks = []
        
        // Create fallback strategic recommendation
        strategicRecommendations = [
            CoreTypes.StrategicRecommendation(
                title: "System Recovery",
                description: "Portfolio data is temporarily unavailable. Attempting to restore connection...",
                category: .operations,
                priority: .medium,
                timeframe: "Immediate",
                estimatedImpact: "Service restoration"
            )
        ]
    }
    
    // MARK: - Public Interface
    
    public func refreshData() async {
        await loadPortfolioIntelligence()
    }
    
    public func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        dashboardSyncStatus = .synced
    }
    
    public func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    public func getComplianceIssues(for buildingId: String? = nil) -> [CoreTypes.ComplianceIssue] {
        if let buildingId = buildingId {
            return complianceIssues.filter { $0.buildingId == buildingId }
        }
        return complianceIssues
    }
    
    public func getInsights(filteredBy priority: CoreTypes.AIPriority? = nil) -> [CoreTypes.IntelligenceInsight] {
        if let priority = priority {
            return intelligenceInsights.filter { $0.priority == priority }
        }
        return intelligenceInsights
    }
    
    // MARK: - Cross-Dashboard Integration
    
    private func setupSubscriptions() {
        dashboardSyncService.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
    }
    
    private func schedulePeriodicRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.refreshData()
            }
        }
    }
    
    /// Broadcast client dashboard update
    private func broadcastDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        dashboardUpdates.append(update)
        
        // Keep only recent updates
        if dashboardUpdates.count > 50 {
            dashboardUpdates = Array(dashboardUpdates.suffix(50))
        }
        
        dashboardSyncService.broadcastClientUpdate(update)
    }
    
    private func handleDashboardUpdate(_ update: CoreTypes.DashboardUpdate) {
        switch update.type {
        case .taskCompleted:
            if let taskId = update.data["taskId"],
               !update.workerId.isEmpty,
               !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Task \(taskId) completed by worker \(update.workerId) at building \(update.buildingId)")
                // Use existing BuildingMetricsService to get updated metrics
                Task { @MainActor in
                    if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: update.buildingId) {
                        buildingMetrics[update.buildingId] = updatedMetrics
                    }
                    // Recalculate completion rate
                    completionRate = calculateAverageCompletion()
                }
            }
            
        case .workerClockedIn:
            if !update.workerId.isEmpty,
               !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Worker \(update.workerId) clocked in at building \(update.buildingId)")
                activeWorkers += 1
            }
            
        case .workerClockedOut:
            if !update.workerId.isEmpty,
               !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Worker \(update.workerId) clocked out from building \(update.buildingId)")
                activeWorkers = max(0, activeWorkers - 1)
            }
            
        case .buildingMetricsChanged:
            if !update.buildingId.isEmpty {
                print("📱 Client Dashboard: Metrics updated for building \(update.buildingId)")
                // Use service to get updated metrics
                Task { @MainActor in
                    if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: update.buildingId) {
                        buildingMetrics[update.buildingId] = updatedMetrics
                        // Recalculate completion rate
                        completionRate = calculateAverageCompletion()
                    }
                }
            }
            
        case .complianceStatusChanged:
            if !update.buildingId.isEmpty,
               let severity = update.data["severity"],
               let title = update.data["title"],
               let description = update.data["description"] {
                
                // Map severity string to enum
                let severityEnum: CoreTypes.ComplianceSeverity = {
                    switch severity.lowercased() {
                    case "critical": return .critical
                    case "high": return .high
                    case "medium": return .medium
                    default: return .low
                    }
                }()
                
                let newIssue = CoreTypes.ComplianceIssue(
                    title: title,
                    description: description,
                    severity: severityEnum,
                    buildingId: update.buildingId,
                    status: .open,
                    createdAt: Date()
                )
                
                complianceIssues.append(newIssue)
                
                // Update critical issues count
                criticalIssues = complianceIssues.filter { $0.severity == .critical }.count
                
                print("📱 Client Dashboard: New compliance issue - \(title)")
            }
            
        default:
            print("📱 Client Dashboard: Received update type \(update.type)")
        }
    }

// MARK: - Supporting Types

extension ClientDashboardViewModel {
    /// Client-specific filter options
    public enum FilterOption: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case highPriority = "High Priority"
        case compliance = "Compliance"
        case efficiency = "Efficiency"
        
        public var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .critical: return "exclamationmark.triangle.fill"
            case .highPriority: return "flag.fill"
            case .compliance: return "shield.fill"
            case .efficiency: return "speedometer"
            }
        }
    }
    
    /// Executive dashboard time range
    public enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case quarter = "This Quarter"
        case year = "This Year"
        
        public var days: Int {
            switch self {
            case .today: return 1
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            case .year: return 365
            }
        }
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension ClientDashboardViewModel {
    static func preview() -> ClientDashboardViewModel {
        let viewModel = ClientDashboardViewModel()
        
        // Mock portfolio intelligence
        viewModel.portfolioIntelligence = CoreTypes.PortfolioIntelligence(
            totalBuildings: 12,
            activeWorkers: 8,
            completionRate: 0.85,
            criticalIssues: 2,
            monthlyTrend: .improving,
            complianceScore: 92.5,
            generatedAt: Date()
        )
        
        // Mock buildings
        viewModel.buildingsList = [
            CoreTypes.NamedCoordinate(
                id: "14",
                name: "Rubin Museum",
                address: "150 W 17th St, New York, NY 10011",
                latitude: 40.7397,
                longitude: -73.9978
            ),
            CoreTypes.NamedCoordinate(
                id: "4",
                name: "131 Perry Street",
                address: "131 Perry St, New York, NY 10014",
                latitude: 40.7350,
                longitude: -74.0045
            )
        ]
        
        // Mock metrics
        viewModel.totalBuildings = 12
        viewModel.activeWorkers = 8
        viewModel.completionRate = 0.85
        viewModel.criticalIssues = 2
        viewModel.complianceScore = 92
        
        return viewModel
    }
}
#endif
