//
//  StubFactory.swift
//  FrancoSphere
//
//  ✅ FIXED: Corrected all initializer calls and parameter lists
//  ✅ ALIGNED: With current CoreTypes structure
//

import Foundation

public struct StubFactory {
    
    // ✅ FIXED: Correct IntelligenceInsight initializer
    public static func createSampleInsights() -> [CoreTypes.IntelligenceInsight] {
        return [
            CoreTypes.IntelligenceInsight(
                title: "High Efficiency Building",
                description: "Building shows 95% task completion rate",
                type: .performance,
                priority: .high,
                actionRequired: false,
                affectedBuildings: ["1", "2"]
            ),
            CoreTypes.IntelligenceInsight(
                title: "Maintenance Alert", 
                description: "HVAC system requires attention",
                type: .maintenance,
                priority: .medium,
                actionRequired: true,
                affectedBuildings: ["3"]
            ),
            CoreTypes.IntelligenceInsight(
                title: "Compliance Review",
                description: "Safety inspection due next week", 
                type: .compliance,
                priority: .low,
                actionRequired: false,
                affectedBuildings: ["4", "5"]
            )
        ]
    }
    
    // ✅ FIXED: Correct PortfolioIntelligence initializer (removed workerSatisfaction)
    public static func createSamplePortfolioIntelligence() -> CoreTypes.PortfolioIntelligence {
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: 12,
            activeWorkers: 24,
            completionRate: 0.87,
            criticalIssues: 3,
            monthlyTrend: .up,
            completedTasks: 132,
            complianceScore: 92,
            weeklyTrend: 0.05
        )
    }
    
    public static func createSampleBuildingMetrics() -> [String: CoreTypes.BuildingMetrics] {
        return [
            "1": CoreTypes.BuildingMetrics(
                buildingId: "1",
                completionRate: 0.95,
                pendingTasks: 2,
                overdueTasks: 0,
                activeWorkers: 3,
                urgentTasksCount: 1,
                overallScore: 95,
                isCompliant: true,
                hasWorkerOnSite: true,
                maintenanceEfficiency: 0.92,
                weeklyCompletionTrend: 0.03
            ),
            "2": CoreTypes.BuildingMetrics(
                buildingId: "2", 
                completionRate: 0.78,
                pendingTasks: 5,
                overdueTasks: 1,
                activeWorkers: 2,
                urgentTasksCount: 2,
                overallScore: 78,
                isCompliant: false,
                hasWorkerOnSite: true,
                maintenanceEfficiency: 0.75,
                weeklyCompletionTrend: -0.05
            )
        ]
    }
}
