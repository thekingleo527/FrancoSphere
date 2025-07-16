//
//  BuildingService+Intelligence.swift
//  FrancoSphere v6.0
//
//  ✅ SIMPLIFIED: Uses existing BuildingMetricsService instead of reinventing
//  ✅ FIXED: Uses correct CoreTypes.BuildingAnalytics properties
//  ✅ ALIGNED: With current actor BuildingService implementation
//  ✅ REAL DATA: Leverages existing GRDB integration
//

import Foundation

extension BuildingService {
    
    // MARK: - Building Intelligence Methods (Using Existing Services)
    
    /// Generate intelligence insights for a specific building using BuildingMetricsService
    func generateBuildingInsights(for buildingId: String) async throws -> [CoreTypes.IntelligenceInsight] {
        
        // Use existing BuildingMetricsService to get metrics
        let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        
        var insights: [CoreTypes.IntelligenceInsight] = []
        
        // Generate performance insights
        if metrics.completionRate < 0.7 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Low Task Completion Rate",
                description: "Building completion rate is \(Int(metrics.completionRate * 100))%, below target of 70%",
                type: .performance,
                priority: metrics.completionRate < 0.5 ? .critical : .high,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Generate maintenance insights
        if metrics.overdueTasks > 3 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "Multiple Overdue Tasks",
                description: "\(metrics.overdueTasks) tasks are overdue and require immediate attention",
                type: .maintenance,
                priority: metrics.overdueTasks > 10 ? .critical : .high,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Generate efficiency insights
        if metrics.completionRate > 0.9 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Efficiency Building",
                description: "Excellent completion rate of \(Int(metrics.completionRate * 100))% with \(metrics.activeWorkers) active workers",
                type: .efficiency,
                priority: .low,
                actionRequired: false,
                affectedBuildings: [buildingId]
            ))
        }
        
        // Generate compliance insights
        if metrics.urgentTasksCount > 5 {
            insights.append(CoreTypes.IntelligenceInsight(
                title: "High Urgent Task Count",
                description: "\(metrics.urgentTasksCount) urgent tasks require immediate attention",
                type: .compliance,
                priority: .high,
                actionRequired: true,
                affectedBuildings: [buildingId]
            ))
        }
        
        return insights.sorted { $0.priority.priorityValue > $1.priority.priorityValue }
    }
    
    /// Generate portfolio-wide intelligence using existing service methods
    func generatePortfolioIntelligence() async throws -> CoreTypes.PortfolioIntelligence {
        
        // Use existing getAllBuildings() method
        let allBuildings = try await getAllBuildings()
        
        // Use existing getAllActiveWorkers() method
        let allWorkers = try await WorkerService.shared.getAllActiveWorkers()
        
        // Use BuildingMetricsService to get all building metrics
        let buildingIds = allBuildings.map { $0.id }
        let allMetrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingIds)
        
        // Calculate portfolio metrics
        let totalBuildings = allBuildings.count
        let activeWorkers = allWorkers.count
        
        // Calculate overall completion rate
        let totalCompletionRate = allMetrics.values.reduce(0.0) { sum, metrics in
            sum + metrics.completionRate
        }
        let completionRate = totalBuildings > 0 ? totalCompletionRate / Double(totalBuildings) : 1.0
        
        // Count critical issues (overdue + urgent tasks)
        let criticalIssues = allMetrics.values.reduce(0) { sum, metrics in
            sum + metrics.overdueTasks + metrics.urgentTasksCount
        }
        
        // Determine trend based on completion rate
        let monthlyTrend: CoreTypes.TrendDirection = {
            if completionRate > 0.85 {
                return .improving
            } else if completionRate < 0.6 {
                return .declining
            } else {
                return .stable
            }
        }()
        
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: totalBuildings,
            activeWorkers: activeWorkers,
            completionRate: completionRate,
            criticalIssues: criticalIssues,
            monthlyTrend: monthlyTrend
        )
    }
    
    /// Get building efficiency trend using BuildingMetricsService
    func getBuildingEfficiencyTrend(for buildingId: String) async throws -> CoreTypes.TrendDirection {
        
        let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        
        // Simple trend analysis based on completion rate
        if metrics.completionRate > 0.85 {
            return .improving
        } else if metrics.completionRate < 0.6 {
            return .declining
        } else {
            return .stable
        }
    }
    
    /// Get risk assessment for a building using BuildingMetricsService
    func getBuildingRiskAssessment(for buildingId: String) async throws -> Double {
        
        let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        
        // Calculate risk score (0.0 = low risk, 1.0 = high risk)
        var riskScore = 0.0
        
        // Factor in completion rate (40% weight)
        riskScore += (1.0 - metrics.completionRate) * 0.4
        
        // Factor in overdue tasks (30% weight)
        if metrics.overdueTasks > 0 {
            riskScore += min(Double(metrics.overdueTasks) / 20.0, 0.3)
        }
        
        // Factor in urgent tasks (20% weight)
        if metrics.urgentTasksCount > 0 {
            riskScore += min(Double(metrics.urgentTasksCount) / 15.0, 0.2)
        }
        
        // Factor in worker availability (10% weight)
        if !metrics.hasWorkerOnSite {
            riskScore += 0.1
        }
        
        return min(riskScore, 1.0)
    }
    
    /// Get building compliance status using BuildingMetricsService
    func getBuildingComplianceStatus(for buildingId: String) async throws -> CoreTypes.ComplianceStatus {
        
        let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        
        // Use the existing isCompliant flag from BuildingMetrics
        if metrics.isCompliant && metrics.completionRate > 0.9 {
            return .compliant
        } else if metrics.overdueTasks > 0 {
            return .nonCompliant
        } else if metrics.completionRate < 0.7 {
            return .atRisk
        } else {
            return .needsReview
        }
    }
    
    /// Get building worker performance summary using BuildingMetricsService
    func getBuildingWorkerSummary(for buildingId: String) async throws -> [String: Any] {
        
        let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        
        return [
            "activeWorkers": metrics.activeWorkers,
            "hasWorkerOnSite": metrics.hasWorkerOnSite,
            "maintenanceEfficiency": metrics.maintenanceEfficiency,
            "overallScore": metrics.overallScore,
            "completionRate": metrics.completionRate
        ]
    }
    
    /// Get simplified building analytics using BuildingMetricsService
    func getBuildingAnalyticsSimplified(for buildingId: String) async throws -> CoreTypes.BuildingAnalytics {
        
        let metrics = try await BuildingMetricsService.shared.calculateMetrics(for: buildingId)
        
        // Convert BuildingMetrics to BuildingAnalytics format
        return CoreTypes.BuildingAnalytics(
            buildingId: buildingId,
            totalTasks: metrics.pendingTasks + (metrics.overdueTasks > 0 ? metrics.overdueTasks : 0),
            completedTasks: Int(Double(metrics.pendingTasks) * metrics.completionRate),
            overdueTasks: metrics.overdueTasks,
            completionRate: metrics.completionRate,
            uniqueWorkers: metrics.activeWorkers,
            averageCompletionTime: 3600.0, // 1 hour default
            efficiency: metrics.maintenanceEfficiency,
            lastUpdated: Date()
        )
    }
}

// MARK: - BuildingMetrics Helper Extensions

extension CoreTypes.BuildingMetrics {
    
    /// Check if building has performance issues
    var hasPerformanceIssues: Bool {
        return completionRate < 0.7 || overdueTasks > 3
    }
    
    /// Get risk level as string
    var riskLevel: String {
        if overdueTasks > 10 || completionRate < 0.5 {
            return "High"
        } else if overdueTasks > 3 || completionRate < 0.8 {
            return "Medium"
        } else {
            return "Low"
        }
    }
    
    /// Get performance grade
    var performanceGrade: String {
        switch completionRate {
        case 0.9...1.0:
            return "A"
        case 0.8..<0.9:
            return "B"
        case 0.7..<0.8:
            return "C"
        case 0.6..<0.7:
            return "D"
        default:
            return "F"
        }
    }
    
    /// Check if building needs immediate attention
    var needsImmediateAttention: Bool {
        return overdueTasks > 5 || urgentTasksCount > 3 || completionRate < 0.5
    }
    
    /// Get priority level for admin attention
    var adminPriority: CoreTypes.InsightPriority {
        if needsImmediateAttention {
            return .critical
        } else if hasPerformanceIssues {
            return .high
        } else if completionRate < 0.9 {
            return .medium
        } else {
            return .low
        }
    }
}
