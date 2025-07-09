//
//  ClientDashboardViewModel.swift
//  FrancoSphere
//
//  ✅ FIXED: CoreTypes references corrected
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ClientDashboardViewModel: ObservableObject {
    @Published var portfolioIntelligence: PortfolioIntelligence?
    @Published var buildingsList: [NamedCoordinate] = []
    @Published var buildingAnalytics: [String: BuildingAnalytics] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdateTime: Date?

    private let buildingService = BuildingService.shared
    private let taskService     = TaskService.shared
    private let workerService   = WorkerService.shared
    private var cancellables    = Set<AnyCancellable>()

    init() { setupAutoRefresh() }

    func loadPortfolioData() async {
        isLoading = true; errorMessage = nil
        do {
            buildingsList = try await buildingService.getAllBuildings()
            var analytics: [String: BuildingAnalytics] = [:]
            var totalTasks = 0, totalCompleted = 0, totalWorkers = 0
            for b in buildingsList {
                let a = try await buildingService.getBuildingAnalytics(b.id)
                analytics[b.id] = a
                totalTasks    += a.totalTasks
                totalCompleted+= a.completedTasks
                totalWorkers  += a.uniqueWorkers
            }
            let portfolio = PortfolioIntelligence(
                totalBuildings: buildingsList.count,
                totalCompletedTasks: totalCompleted,
                averageComplianceScore: calculateOverallCompliance(analytics),
                totalActiveWorkers: totalWorkers,
                overallEfficiency: totalTasks > 0 ? Double(totalCompleted)/Double(totalTasks) : 0.0,
                trendDirection: calculatePortfolioTrend(analytics)
            )
            self.buildingAnalytics = analytics
            self.portfolioIntelligence = portfolio
            self.lastUpdateTime = Date()
        } catch {
            errorMessage = "Failed to load portfolio data: \(error)"
        }
        isLoading = false
    }

    // …calculateOverallCompliance, calculateOverallEfficiency, calculatePortfolioTrend, setupAutoRefresh…
}
