//
//  ClientDashboardTypes.swift
//  FrancoSphere v6.0
//
//  ✅ GENERATED: By comprehensive fix script
//  ✅ CLIENT: Executive dashboard specific types
//  ✅ SEPARATE: From CoreTypes to avoid conflicts
//

import Foundation
import SwiftUI

// MARK: - Client Dashboard Executive Types

public struct ClientExecutiveSummary: Codable, Identifiable {
    public let id: String
    public let totalBuildings: Int
    public let portfolioEfficiency: Double
    public let complianceRate: Double
    public let criticalIssues: Int
    public let actionableInsights: Int
    public let monthlyTrend: CoreTypes.TrendDirection
    public let lastUpdated: Date
    
    public init(
        id: String = UUID().uuidString,
        totalBuildings: Int,
        portfolioEfficiency: Double,
        complianceRate: Double,
        criticalIssues: Int,
        actionableInsights: Int,
        monthlyTrend: CoreTypes.TrendDirection,
        lastUpdated: Date
    ) {
        self.id = id
        self.totalBuildings = totalBuildings
        self.portfolioEfficiency = portfolioEfficiency
        self.complianceRate = complianceRate
        self.criticalIssues = criticalIssues
        self.actionableInsights = actionableInsights
        self.monthlyTrend = monthlyTrend
        self.lastUpdated = lastUpdated
    }
}

public struct ClientPortfolioBenchmark: Codable, Identifiable {
    public let id: String
    public let category: String
    public let currentValue: Double
    public let industryAverage: Double
    public let targetValue: Double
    public let trend: CoreTypes.TrendDirection
    
    public init(
        id: String = UUID().uuidString,
        category: String,
        currentValue: Double,
        industryAverage: Double,
        targetValue: Double,
        trend: CoreTypes.TrendDirection
    ) {
        self.id = id
        self.category = category
        self.currentValue = currentValue
        self.industryAverage = industryAverage
        self.targetValue = targetValue
        self.trend = trend
    }
}

public struct ClientStrategicRecommendation: Codable, Identifiable {
    public let id: String
    public let title: String
    public let description: String
    public let priority: Priority
    public let estimatedImpact: String
    public let timeframe: String
    
    public init(
        id: String = UUID().uuidString,
        title: String,
        description: String,
        priority: Priority,
        estimatedImpact: String,
        timeframe: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.estimatedImpact = estimatedImpact
        self.timeframe = timeframe
    }
    
    public enum Priority: String, Codable, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        public var color: Color {
            switch self {
            case .low: return .green
            case .medium: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
    }
}

// Type aliases for compatibility
public typealias ExecutiveSummary = ClientExecutiveSummary
public typealias PortfolioBenchmark = ClientPortfolioBenchmark
public typealias StrategicRecommendation = ClientStrategicRecommendation
