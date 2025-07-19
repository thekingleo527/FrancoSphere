//
//  ClientDashboardTypes.swift
//  FrancoSphere v6.0
//
//  ✅ EMERGENCY FIX: Removed CoreTypes redeclaration
//  ✅ CLEANED: All duplicate type definitions
//  ✅ ALIGNED: Uses only CoreTypes.* references
//

import Foundation
import SwiftUI

// ❌ DELETE THIS LINE: extension CoreTypes {
// ❌ DELETE ANY: struct CoreTypes definition

// MARK: - Client-Specific View Types (Non-conflicting)

public enum InsightFilterType: String, CaseIterable, Codable {
    case all = "All"
    case performance = "Performance"
    case maintenance = "Maintenance"
    case compliance = "Compliance"
    case efficiency = "Efficiency"
    case safety = "Safety"
    case cost = "Cost"
    
    public var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .performance: return "chart.line.uptrend.xyaxis"
        case .maintenance: return "wrench"
        case .compliance: return "checkmark.shield"
        case .efficiency: return "speedometer"
        case .safety: return "shield"
        case .cost: return "dollarsign.circle"
        }
    }
    
    public var color: Color {
        switch self {
        case .all: return .primary
        case .performance: return .blue
        case .maintenance: return .orange
        case .compliance: return .green
        case .efficiency: return .purple
        case .safety: return .red
        case .cost: return .yellow
        }
    }
}

// MARK: - Client Dashboard View Models (Use CoreTypes.* references)

public struct ClientPortfolioSummary: Codable {
    public let totalBuildings: Int
    public let efficiency: String
    public let compliance: String
    public let criticalIssues: Int
    public let actionableInsights: Int
    public let monthlyTrend: CoreTypes.TrendDirection
    
    public init(totalBuildings: Int, efficiency: String, compliance: String, criticalIssues: Int, actionableInsights: Int, monthlyTrend: CoreTypes.TrendDirection) {
        self.totalBuildings = totalBuildings
        self.efficiency = efficiency
        self.compliance = compliance
        self.criticalIssues = criticalIssues
        self.actionableInsights = actionableInsights
        self.monthlyTrend = monthlyTrend
    }
}

public struct ClientExecutiveSummary: Codable {
    public let totalBuildings: Int
    public let portfolioEfficiency: Double
    public let complianceRate: Double
    public let criticalIssues: Int
    public let actionableInsights: Int
    public let monthlyTrend: CoreTypes.TrendDirection
    public let lastUpdated: Date
    
    public var efficiencyGrade: String {
        switch portfolioEfficiency {
        case 0.9...: return "A"
        case 0.8..<0.9: return "B"
        case 0.7..<0.8: return "C"
        default: return "D"
        }
    }
    
    public var complianceGrade: String {
        switch complianceRate {
        case 0.95...: return "A+"
        case 0.9..<0.95: return "A"
        case 0.8..<0.9: return "B"
        default: return "C"
        }
    }
    
    public init(totalBuildings: Int, portfolioEfficiency: Double, complianceRate: Double, criticalIssues: Int, actionableInsights: Int, monthlyTrend: CoreTypes.TrendDirection, lastUpdated: Date) {
        self.totalBuildings = totalBuildings
        self.portfolioEfficiency = portfolioEfficiency
        self.complianceRate = complianceRate
        self.criticalIssues = criticalIssues
        self.actionableInsights = actionableInsights
        self.monthlyTrend = monthlyTrend
        self.lastUpdated = lastUpdated
    }
}

public struct ClientPortfolioBenchmark: Codable {
    public let category: String
    public let currentValue: Double
    public let industryAverage: Double
    public let targetValue: Double
    public let trend: CoreTypes.TrendDirection
    
    public init(category: String, currentValue: Double, industryAverage: Double, targetValue: Double, trend: CoreTypes.TrendDirection) {
        self.category = category
        self.currentValue = currentValue
        self.industryAverage = industryAverage
        self.targetValue = targetValue
        self.trend = trend
    }
}

public struct ClientStrategicRecommendation: Codable {
    public let title: String
    public let description: String
    public let priority: CoreTypes.InsightPriority
    public let estimatedImpact: String
    public let timeframe: String
    
    public init(title: String, description: String, priority: CoreTypes.InsightPriority, estimatedImpact: String, timeframe: String) {
        self.title = title
        self.description = description
        self.priority = priority
        self.estimatedImpact = estimatedImpact
        self.timeframe = timeframe
    }
}

// ❌ DO NOT ADD: Any CoreTypes extensions or duplicate type definitions
// ✅ USE ONLY: CoreTypes.TypeName references throughout
