//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved
//  ✅ FIXED: UpdateType references removed, using DashboardUpdate directly
//  ✅ FIXED: Timer syntax corrected
//  ✅ FIXED: Constructor calls aligned with CoreTypes
//  ✅ ALIGNED: With AdminDashboardViewModel patterns
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (Using Existing CoreTypes)
    @Published var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Dashboard Metrics (Derived from Portfolio)
    @Published var totalBuildings: Int = 0
    @Published var activeWorkers: Int = 0
    @Published var completionRate: Double = 0.0
    @Published var criticalIssues: Int = 0
    @Published var complianceScore: Int = 0
    @Published var monthlyTrend: CoreTypes.TrendDirection = .stable
    
    // MARK: - UI State
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration (Using DashboardUpdate from DashboardSyncService)
    @Published var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published var dashboardUpdates: [DashboardUpdate] = []
    
    // MARK: - Executive Summary Data (Using Existing CoreTypes)
    @Published var executiveSummary: CoreTypes.ExecutiveSummary?
    @Published var portfolioBenchmarks: [CoreTypes.PortfolioBenchmark] = []
    @Published var strategicRecommendations: [CoreTypes.StrategicRecommendation] = []
    
    // MARK: - Services (Using Existing .shared Pattern)
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    private let dashboardSyncService = DashboardSyncService.shared
    
    // MARK: - Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupSubscriptions()
        schedulePeriodicRefresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Primary Data Loading
    
    /// Load portfolio intelligence for executive client view
    func loadPortfolioIntelligence() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load building list first
            buildingsList = try await buildingService.getAllBuildings()
            totalBuildings = buildingsList.count
            
            // Generate portfolio intelligence (existing method)
            let intelligence = try await intelligenceService.generatePortfolioIntelligence()
            self.portfolioIntelligence = intelligence
            
            // Extract metrics from intelligence
            totalBuildings = intelligence.totalBuildings
            activeWorkers = intelligence.activeWorkers
            completionRate = intelligence.completionRate
            criticalIssues = intelligence.criticalIssues
            complianceScore = Int(intelligence.complianceScore * 100)
            monthlyTrend = intelligence.monthlyTrend
            
            // Load building metrics for all buildings
            await loadBuildingMetrics()
            
            // Load compliance issues
            await loadComplianceIssues()
            
            // Load intelligence insights
            await loadIntelligenceInsights()
            
            // Create and broadcast update
            let update = DashboardUpdate(
                source: .client,
                type: .portfolioUpdated,
                buildingId: nil,
                workerId: nil,
                data: [
                    "totalBuildings": totalBuildings,
                    "completionRate": completionRate,
                    "activeWorkers": activeWorkers
                ]
            )
            broadcastDashboardUpdate(update)
            
            lastUpdateTime = Date()
            isLoading = false
            
            print("✅ Client portfolio intelligence loaded: \(totalBuildings) buildings, \(activeWorkers) workers")
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Failed to load portfolio intelligence: \(error)")
            await loadFallbackData()
        }
    }
    
    /// Load building metrics for client portfolio view
    private func loadBuildingMetrics() async {
        for building in buildingsList {
            do {
                let metrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                buildingMetrics[building.id] = metrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        // Create and broadcast update
        let update = DashboardUpdate(
            source: .client,
            type: .buildingMetricsChanged,
            buildingId: nil,
            workerId: nil,
            data: [
                "buildingCount": buildingMetrics.count,
                "averageCompletion": calculateAverageCompletion()
            ]
        )
        broadcastDashboardUpdate(update)
    }
    
    /// Load compliance issues across portfolio
    private func loadComplianceIssues() async {
        do {
            // Using existing service method
            let allIssues = try await intelligenceService.getComplianceIssues()
            self.complianceIssues = allIssues
            
            // Count critical issues
            criticalIssues = allIssues.filter { $0.severity == .critical }.count
            
            print("✅ Loaded \(allIssues.count) compliance issues (\(criticalIssues) critical)")
            
        } catch {
            print("⚠️ Failed to load compliance issues: \(error)")
            self.complianceIssues = []
        }
    }
    
    /// Load AI-generated intelligence insights
    private func loadIntelligenceInsights() async {
        isLoadingInsights = true
        
        do {
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
    
    /// Create executive summary from portfolio data
    func generateExecutiveSummary() async {
        do {
            // Use actual service method
            let summary = try await intelligenceService.generateExecutiveSummary()
            self.executiveSummary = summary
            
            print("✅ Executive summary generated")
            
        } catch {
            print("⚠️ Failed to generate executive summary: \(error)")
            
            // Fallback summary
            self.executiveSummary = CoreTypes.ExecutiveSummary(
                totalBuildings: totalBuildings,
                totalWorkers: activeWorkers,
                portfolioHealth: completionRate,
                monthlyPerformance: monthlyTrend.rawValue,
                generatedAt: Date()
            )
        }
    }
    
    /// Load strategic recommendations
    func loadStrategicRecommendations() async {
        do {
            let recommendations = try await intelligenceService.generateStrategicRecommendations()
            self.strategicRecommendations = recommendations
            
            print("✅ Loaded \(recommendations.count) strategic recommendations")
            
        } catch {
            print("⚠️ Failed to load strategic recommendations: \(error)")
            self.strategicRecommendations = []
        }
    }
    
    /// Generate portfolio benchmarks
    func loadPortfolioBenchmarks() async {
        do {
            let benchmarks = try await intelligenceService.generatePortfolioBenchmarks()
            self.portfolioBenchmarks = benchmarks
            
            print("✅ Loaded \(benchmarks.count) portfolio benchmarks")
            
        } catch {
            print("⚠️ Failed to load portfolio benchmarks: \(error)")
            self.portfolioBenchmarks = []
        }
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
    func refreshData() async {
        await loadPortfolioIntelligence()
    }
    
    func forceRefresh() async {
        dashboardSyncStatus = .syncing
        await loadPortfolioIntelligence()
        dashboardSyncStatus = .synced
    }
    
    func getBuildingMetrics(for buildingId: String) -> CoreTypes.BuildingMetrics? {
        return buildingMetrics[buildingId]
    }
    
    func getComplianceIssues(for buildingId: String? = nil) -> [CoreTypes.ComplianceIssue] {
        if let buildingId = buildingId {
            return complianceIssues.filter { $0.buildingId == buildingId }
        }
        return complianceIssues
    }
    
    func getInsights(filteredBy priority: CoreTypes.AIPriority? = nil) -> [CoreTypes.IntelligenceInsight] {
        if let priority = priority {
            return intelligenceInsights.filter { $0.priority == priority }
        }
        return intelligenceInsights
    }
    
    // MARK: - Cross-Dashboard Integration (Using DashboardUpdate)
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
    
    /// Broadcast client dashboard update using DashboardUpdate directly
    private func broadcastDashboardUpdate(_ update: DashboardUpdate) {
        dashboardUpdates.append(update)
        
        // Keep only recent updates
        if dashboardUpdates.count > 50 {
            dashboardUpdates = Array(dashboardUpdates.suffix(50))
        }
        
        dashboardSyncService.broadcastClientUpdate(update)
    }
    
    private func handleDashboardUpdate(_ update: DashboardUpdate) {
        switch update.type {
        case .taskCompleted:
            if let taskId = update.data["taskId"] as? String,
               let workerId = update.workerId,
               let buildingId = update.buildingId {
                print("📱 Client Dashboard: Task \(taskId) completed by worker \(workerId) at building \(buildingId)")
                // Use existing BuildingMetricsService to get updated metrics
                Task { @MainActor in
                    if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: buildingId) {
                        buildingMetrics[buildingId] = updatedMetrics
                    }
                }
            }
            
        case .workerClockedIn:
            if let workerId = update.workerId,
               let buildingId = update.buildingId {
                print("📱 Client Dashboard: Worker \(workerId) clocked in at building \(buildingId)")
                activeWorkers += 1
            }
            
        case .buildingMetricsChanged:
            if let buildingId = update.buildingId {
                print("📱 Client Dashboard: Metrics updated for building \(buildingId)")
                // Use service to get updated metrics
                Task { @MainActor in
                    if let updatedMetrics = try? await buildingMetricsService.calculateMetrics(for: buildingId) {
                        buildingMetrics[buildingId] = updatedMetrics
                    }
                }
            }
            
        case .complianceChanged:
            if let buildingId = update.buildingId,
               let severityString = update.data["severity"] as? String,
               let title = update.data["title"] as? String,
               let description = update.data["description"] as? String {
                
                // Map severity string to enum
                let severity: CoreTypes.ComplianceSeverity = {
                    switch severityString.lowercased() {
                    case "critical": return .critical
                    case "high": return .high
                    case "medium": return .medium
                    default: return .low
                    }
                }()
                
                let newIssue = CoreTypes.ComplianceIssue(
                    title: title,
                    description: description,
                    severity: severity,
                    buildingId: buildingId,
                    status: .open,
                    createdAt: Date()
                )
                
                complianceIssues.append(newIssue)
                
                // Update critical issues count
                criticalIssues = complianceIssues.filter { $0.severity == .critical }.count
                
                print("📱 Client Dashboard: New compliance issue - \(title)")
            }
            
        case .intelligenceGenerated:
            print("📱 Client Dashboard: New intelligence insights available")
            // Refresh insights
            Task { @MainActor in
                await loadIntelligenceInsights()
            }
            
        case .portfolioUpdated:
            print("📱 Client Dashboard: Portfolio update received")
            // Refresh portfolio data
            Task { @MainActor in
                await loadPortfolioIntelligence()
            }
            
        default:
            print("📱 Client Dashboard: Received update type \(update.type)")
        }
    }
}

// MARK: - Supporting Types

extension ClientDashboardViewModel {
    /// Client-specific filter options
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case critical = "Critical"
        case highPriority = "High Priority"
        case compliance = "Compliance"
        case efficiency = "Efficiency"
        
        var icon: String {
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
    enum TimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case quarter = "This Quarter"
        case year = "This Year"
        
        var days: Int {
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
