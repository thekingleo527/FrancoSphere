//
//  ClientDashboardViewModel.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All compilation errors resolved - uses correct ExecutiveSummary signature
//  ✅ ALIGNED: With forensic developer's punchlist requirements
//  ✅ ENHANCED: Cross-dashboard integration ready
//  ✅ PREPARED: For ClientDashboardView creation (Phase 1.1)
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    
    // MARK: - Published Properties (Using Correct CoreTypes)
    @Published var portfolioIntelligence: CoreTypes.PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingMetrics: [String: CoreTypes.BuildingMetrics] = [:]
    @Published var complianceIssues: [CoreTypes.ComplianceIssue] = []
    @Published var intelligenceInsights: [CoreTypes.IntelligenceInsight] = []
    
    // MARK: - Loading States
    @Published var isLoading = false
    @Published var isLoadingInsights = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?
    
    // MARK: - Cross-Dashboard Integration (Per Forensic Punchlist)
    @Published var dashboardSyncStatus: CoreTypes.DashboardSyncStatus = .synced
    @Published var crossDashboardUpdates: [CoreTypes.CrossDashboardUpdate] = []
    
    // MARK: - Executive Summary Data
    @Published var executiveSummary: ExecutiveSummary?
    @Published var portfolioBenchmarks: [PortfolioBenchmark] = []
    @Published var strategicRecommendations: [StrategicRecommendation] = []
    
    // MARK: - Services (Using Existing Shared Instances)
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let workerService = WorkerService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    private let intelligenceService = IntelligenceService.shared
    
    // MARK: - Real-time Subscriptions
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    
    // MARK: - Initialization
    
    init() {
        setupAutoRefresh()
        setupCrossDashboardSync()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Data Loading Methods
    
    /// Loads all client dashboard data
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load core data concurrently
            async let buildingsLoad = buildingService.getAllBuildings()
            async let portfolioLoad = loadPortfolioIntelligence()
            async let metricsLoad = loadBuildingMetrics()
            async let complianceLoad = loadComplianceIssues()
            
            // Wait for all loads
            let buildings = try await buildingsLoad
            await portfolioLoad
            await metricsLoad
            await complianceLoad
            
            // Update UI
            self.buildingsList = buildings
            self.lastUpdateTime = Date()
            
            // Generate executive summary
            await generateExecutiveSummary()
            
            print("✅ Client dashboard data loaded: \(buildings.count) buildings")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Failed to load client dashboard data: \(error)")
        }
        
        isLoading = false
    }
    
    /// Loads portfolio intelligence data
    func loadPortfolioIntelligence() async {
        isLoadingInsights = true
        
        do {
            let intelligence = try await intelligenceService.generatePortfolioIntelligence()
            let insights = try await intelligenceService.generatePortfolioInsights()
            
            self.portfolioIntelligence = intelligence
            self.intelligenceInsights = insights
            self.isLoadingInsights = false
            
            print("✅ Portfolio intelligence loaded")
            broadcastCrossDashboardUpdate(.insightsUpdated(count: insights.count))
            
        } catch {
            self.isLoadingInsights = false
            print("⚠️ Failed to load portfolio intelligence: \(error)")
        }
    }
    
    /// Loads building metrics for all buildings
    private func loadBuildingMetrics() async {
        var metrics: [String: CoreTypes.BuildingMetrics] = [:]
        
        for building in buildingsList {
            do {
                let buildingMetrics = try await buildingMetricsService.calculateMetrics(for: building.id)
                metrics[building.id] = buildingMetrics
            } catch {
                print("⚠️ Failed to load metrics for building \(building.id): \(error)")
            }
        }
        
        self.buildingMetrics = metrics
        broadcastCrossDashboardUpdate(.metricsUpdated(buildingIds: Array(metrics.keys)))
    }
    
    /// Loads compliance issues
    private func loadComplianceIssues() async {
        do {
            // Generate compliance insights and convert to issues format
            let insights = try await intelligenceService.generatePortfolioInsights()
            let complianceInsights = insights.filter { $0.type == .compliance }
            
            // Convert insights to compliance issues
            self.complianceIssues = complianceInsights.compactMap { insight in
                guard let buildingId = insight.affectedBuildings.first else { return nil }
                
                return CoreTypes.ComplianceIssue(
                    type: .inspectionRequired, // Default type, could be enhanced to parse from description
                    severity: mapPriorityToSeverity(insight.priority),
                    description: insight.description,
                    buildingId: buildingId,
                    dueDate: insight.actionRequired ? Calendar.current.date(byAdding: .day, value: 7, to: Date()) : nil
                )
            }
            
            print("✅ Compliance issues loaded: \(complianceIssues.count) issues")
            
        } catch {
            print("⚠️ Failed to load compliance issues: \(error)")
        }
    }
    
    /// Helper method to map insight priority to compliance severity
    private func mapPriorityToSeverity(_ priority: CoreTypes.InsightPriority) -> CoreTypes.ComplianceSeverity {
        switch priority {
        case .critical: return .critical
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
    
    /// Generates executive summary based on current data (FIXED)
    private func generateExecutiveSummary() async {
        let totalBuildings = buildingsList.count
        let averageEfficiency = calculateAverageEfficiency()
        let complianceRate = calculateComplianceRate()
        let criticalIssues = complianceIssues.filter { $0.severity == .critical }.count
        let actionableInsights = intelligenceInsights.filter { $0.actionRequired }.count
        let monthlyTrend = calculateComplianceTrend()
        
        // Get active workers count
        let activeWorkers = portfolioIntelligence?.activeWorkers ?? 0
        
        // Convert values to match expected ExecutiveSummary initializer
        let portfolioHealth = Int(averageEfficiency * 100)  // Convert Double to Int percentage
        let complianceScore = Int(complianceRate * 100)     // Convert Double to Int percentage
        let monthlyTrendString = monthlyTrend.rawValue       // Convert TrendDirection to String
        
        // Create ExecutiveSummary with correct parameter types
        executiveSummary = ExecutiveSummary(
            totalBuildings: totalBuildings,
            activeWorkers: activeWorkers,           // Added missing parameter
            portfolioHealth: portfolioHealth,       // Changed from portfolioEfficiency (Double) to portfolioHealth (Int)
            complianceScore: complianceScore,       // Changed from complianceRate (Double) to complianceScore (Int)
            criticalIssues: criticalIssues,         // This stays as Int
            averageCompletion: averageEfficiency,   // Added missing averageCompletion parameter
            monthlyTrend: monthlyTrendString        // Changed from CoreTypes.TrendDirection to String
            // Removed lastUpdated parameter as it's not expected
        )
        
        print("✅ Executive summary generated")
    }
    
    // MARK: - Portfolio Analytics
    
    /// Get client portfolio summary
    func getClientPortfolioSummary() -> ClientPortfolioSummary {
        let totalBuildings = buildingsList.count
        let averageEfficiency = calculateAverageEfficiency()
        let complianceRate = calculateComplianceRate()
        
        return ClientPortfolioSummary(
            totalBuildings: totalBuildings,
            efficiency: String(format: "%.1f%%", averageEfficiency * 100),
            compliance: String(format: "%.1f%%", complianceRate * 100),
            criticalIssues: complianceIssues.filter { $0.severity == .critical }.count,
            actionableInsights: intelligenceInsights.filter { $0.actionRequired }.count,
            monthlyTrend: calculateComplianceTrend()
        )
    }
    
    // MARK: - Real-time Update Methods
    
    /// Force refresh of all data
    func forceRefresh() async {
        guard !isLoading else { return }
        
        print("🔄 Force refreshing client dashboard data...")
        dashboardSyncStatus = .syncing
        await loadDashboardData()
        dashboardSyncStatus = .synced
    }
    
    /// Refresh portfolio intelligence only
    func refreshIntelligence() async {
        await loadPortfolioIntelligence()
        await generateExecutiveSummary()
    }
    
    // MARK: - Analytics Calculations
    
    private func calculateAverageEfficiency() -> Double {
        guard !buildingMetrics.isEmpty else { return 0.0 }
        
        let totalEfficiency = buildingMetrics.values.reduce(0.0) { $0 + $1.completionRate }
        return totalEfficiency / Double(buildingMetrics.count)
    }
    
    private func calculateComplianceRate() -> Double {
        guard !buildingMetrics.isEmpty else { return 1.0 }
        
        let compliantBuildings = buildingMetrics.values.filter { $0.isCompliant }.count
        return Double(compliantBuildings) / Double(buildingMetrics.count)
    }
    
    private func calculateComplianceTrend() -> CoreTypes.TrendDirection {
        let complianceRate = Double(buildingMetrics.values.filter { $0.isCompliant }.count) / Double(buildingMetrics.count)
        
        switch complianceRate {
        case 0.9...: return .improving
        case 0.8..<0.9: return .stable
        default: return .declining
        }
    }
    
    private func calculateCostEfficiency() -> Double {
        // Real cost calculation based on actual operational data
        guard !buildingMetrics.isEmpty else { return 0.0 }
        
        let totalBuildings = buildingMetrics.count
        let efficientBuildings = buildingMetrics.values.filter { $0.maintenanceEfficiency > 0.8 }.count
        let complianceRate = Double(buildingMetrics.values.filter { $0.isCompliant }.count) / Double(totalBuildings)
        let averageCompletionRate = buildingMetrics.values.reduce(0.0) { $0 + $1.completionRate } / Double(totalBuildings)
        
        // Cost efficiency = (efficiency + compliance + completion) / 3
        let efficiency = Double(efficientBuildings) / Double(totalBuildings)
        return (efficiency + complianceRate + averageCompletionRate) / 3.0
    }
    
    // MARK: - Cross-Dashboard Integration (Per Forensic Punchlist)
    
    /// Setup cross-dashboard synchronization
    private func setupCrossDashboardSync() {
        // Real cross-dashboard synchronization using DashboardSyncService
        DashboardSyncService.shared.clientDashboardUpdates
            .receive(on: DispatchQueue.main)
            .sink { [weak self] update in
                self?.handleDashboardUpdate(update)
            }
            .store(in: &cancellables)
        
        dashboardSyncStatus = .synced
        print("🔗 Client dashboard cross-sync initialized")
    }
    
    /// Handle dashboard update from DashboardSyncService
    private func handleDashboardUpdate(_ update: DashboardUpdate) {
        switch update.type {
        case .taskCompleted, .workerClockedIn, .buildingMetricsChanged:
            Task {
                await loadBuildingMetrics()
                await generateExecutiveSummary()
            }
        case .intelligenceGenerated:
            Task {
                await loadPortfolioIntelligence()
            }
        default:
            break
        }
    }
    
    /// Broadcast update to other dashboards
    private func broadcastCrossDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) {
        crossDashboardUpdates.append(update)
        
        // Convert CoreTypes.CrossDashboardUpdate to DashboardUpdate for service
        let dashboardUpdate = convertToDashboardUpdate(update)
        
        // Broadcast to real sync service
        DashboardSyncService.shared.broadcastClientUpdate(dashboardUpdate)
        
        // Update sync status
        dashboardSyncStatus = .syncing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dashboardSyncStatus = .synced
        }
    }
    
    /// Convert CoreTypes.CrossDashboardUpdate to DashboardUpdate
    private func convertToDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) -> DashboardUpdate {
        switch update {
        case .taskCompleted(let buildingId):
            return DashboardUpdate(
                source: .client,
                type: .taskCompleted,
                buildingId: buildingId,
                workerId: nil,
                data: [:]
            )
        case .workerClockedIn(let buildingId):
            return DashboardUpdate(
                source: .client,
                type: .workerClockedIn,
                buildingId: buildingId,
                workerId: nil,
                data: [:]
            )
        case .metricsUpdated(let buildingIds):
            return DashboardUpdate(
                source: .client,
                type: .buildingMetricsChanged,
                buildingId: buildingIds.first,
                workerId: nil,
                data: ["buildingIds": buildingIds]
            )
        case .insightsUpdated(let count):
            return DashboardUpdate(
                source: .client,
                type: .intelligenceGenerated,
                buildingId: nil,
                workerId: nil,
                data: ["count": count]
            )
        case .buildingIntelligenceUpdated(let buildingId):
            return DashboardUpdate(
                source: .client,
                type: .intelligenceGenerated,
                buildingId: buildingId,
                workerId: nil,
                data: [:]
            )
        case .complianceUpdated(let buildingIds):
            return DashboardUpdate(
                source: .client,
                type: .complianceChanged,
                buildingId: buildingIds.first,
                workerId: nil,
                data: ["buildingIds": buildingIds]
            )
        }
    }
    
    /// Setup auto-refresh timer
    private func setupAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task {
                await self.forceRefresh()
            }
        }
    }
    
    /// Handle cross-dashboard update received from other dashboards
    func handleCrossDashboardUpdate(_ update: CoreTypes.CrossDashboardUpdate) {
        switch update {
        case .taskCompleted, .workerClockedIn, .metricsUpdated, .complianceUpdated:
            Task {
                await loadBuildingMetrics()
                await generateExecutiveSummary()
            }
        case .insightsUpdated:
            Task {
                await loadPortfolioIntelligence()
            }
        default:
            break
        }
    }
}

// MARK: - Client-Specific Supporting Types

/// Client-specific portfolio summary to avoid type conflicts
struct ClientPortfolioSummary {
    let totalBuildings: Int
    let efficiency: String
    let compliance: String
    let criticalIssues: Int
    let actionableInsights: Int
    let monthlyTrend: CoreTypes.TrendDirection
}

/// Executive summary for client dashboard (FIXED to match expected signature)
struct ExecutiveSummary {
    let totalBuildings: Int
    let activeWorkers: Int          // Added missing property
    let portfolioHealth: Int        // Changed from portfolioEfficiency (Double) to portfolioHealth (Int)
    let complianceScore: Int        // Changed from complianceRate (Double) to complianceScore (Int)
    let criticalIssues: Int         // This stays as Int
    let averageCompletion: Double   // Added missing averageCompletion parameter
    let monthlyTrend: String        // Changed from CoreTypes.TrendDirection to String
    // Removed lastUpdated property as it's not expected
    
    // Updated computed properties to work with new types
    var efficiencyGrade: String {
        switch portfolioHealth {
        case 90...: return "A"
        case 80..<90: return "B"
        case 70..<80: return "C"
        default: return "D"
        }
    }
    
    var complianceGrade: String {
        switch complianceScore {
        case 95...: return "A+"
        case 90..<95: return "A"
        case 80..<90: return "B"
        default: return "C"
        }
    }
    
    // Helper computed properties for UI
    var portfolioHealthPercentage: Double {
        return Double(portfolioHealth) / 100.0
    }
    
    var complianceRatePercentage: Double {
        return Double(complianceScore) / 100.0
    }
    
    var averageCompletionPercentage: Double {
        return averageCompletion // Already a percentage (0.0-1.0)
    }
    
    var monthlyTrendDirection: CoreTypes.TrendDirection {
        switch monthlyTrend.lowercased() {
        case "improving", "up": return .improving
        case "declining", "down": return .declining
        default: return .stable
        }
    }
}

/// Portfolio benchmark for client dashboard
struct PortfolioBenchmark {
    let category: String
    let currentValue: Double
    let industryAverage: Double
    let targetValue: Double
    let trend: CoreTypes.TrendDirection
}

/// Strategic recommendation for client dashboard
struct StrategicRecommendation {
    let title: String
    let description: String
    let priority: CoreTypes.InsightPriority
    let estimatedImpact: String
    let timeframe: String
}
