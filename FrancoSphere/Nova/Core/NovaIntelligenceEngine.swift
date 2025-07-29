//
//  NovaIntelligenceEngine.swift
//  FrancoSphere v6.0
//
//  Single entry point for all Nova AI operations
//  Uses CoreTypes for all data structures
//

import SwiftUI
import Combine
import CoreLocation  // For NamedCoordinate support

// Type alias for clarity
typealias Building = CoreTypes.NamedCoordinate

@MainActor
public class NovaIntelligenceEngine: ObservableObject {
    public static let shared = NovaIntelligenceEngine()
    
    // MARK: - Published Properties
    @Published public var currentContext: String = ""
    @Published public var insights: [CoreTypes.IntelligenceInsight] = []
    @Published public var suggestions: [CoreTypes.AISuggestion] = []
    @Published public var processingState: ProcessingState = .idle
    @Published public var lastError: Error?
    
    // MARK: - Dependencies
    private let dataService = NovaDataService.shared
    private let intelligenceService = IntelligenceService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let buildingMetricsService = BuildingMetricsService.shared
    
    // MARK: - State
    public enum ProcessingState {
        case idle
        case processing
        case generating
        case error(String)
    }
    
    private init() {}
    
    // MARK: - Main Processing Method
    public func process(
        query: String,
        context: [String: Any]? = nil,
        priority: CoreTypes.AIPriority = .medium
    ) async throws -> CoreTypes.IntelligenceInsight {
        
        processingState = .processing
        
        do {
            // 1. Generate context-aware prompt using internal data aggregation
            let prompt = try await generatePromptWithData(
                query: query,
                context: context
            )
            
            processingState = .generating
            
            // 2. Generate insight based on CoreTypes structure
            let insight = CoreTypes.IntelligenceInsight(
                title: extractTitle(from: query),
                description: await generateResponse(for: prompt),
                type: determineCategory(from: query),
                priority: priority,
                actionRequired: determineIfActionRequired(from: query),
                affectedBuildings: extractAffectedBuildings(from: context)
            )
            
            // 3. Update state
            insights.append(insight)
            processingState = .idle
            
            return insight
            
        } catch {
            processingState = .error(error.localizedDescription)
            lastError = error
            throw error
        }
    }
    
    // MARK: - Convenience Methods (replaces multiple services)
    
    public func generateInsight(for building: Building) async throws -> CoreTypes.IntelligenceInsight {
        return try await process(
            query: "Generate insight for building \(building.name)",
            context: ["buildingId": building.id, "building": building],
            priority: .medium
        )
    }
    
    public func generateTaskRecommendations(for worker: CoreTypes.WorkerProfile) async throws -> [CoreTypes.AISuggestion] {
        let insight = try await process(
            query: "Recommend tasks for worker \(worker.name)",
            context: ["workerId": worker.id],
            priority: .high
        )
        
        // Convert to suggestions
        return [
            CoreTypes.AISuggestion(
                title: insight.title,
                description: insight.description,
                priority: insight.priority,
                category: insight.type,
                actionRequired: insight.actionRequired,
                estimatedImpact: "Medium"
            )
        ]
    }
    
    // MARK: - Private Helpers (internal data handling)
    
    private func generatePromptWithData(query: String, context: [String: Any]?) async throws -> String {
        // Use NovaDataService internally to get aggregated data
        let portfolioData = try await dataService.aggregatePortfolioData()
        
        // Convert internal data to prompt string
        var promptParts = [String]()
        promptParts.append("Query: \(query)")
        promptParts.append("Buildings: \(portfolioData.buildingCount)")
        promptParts.append("Active Workers: \(portfolioData.workerCount)")
        promptParts.append("Tasks Today: \(portfolioData.taskCount)")
        promptParts.append("Completion Rate: \(String(format: "%.1f%%", portfolioData.averageCompletionRate * 100))")
        promptParts.append("Urgent Tasks: \(portfolioData.urgentTaskCount)")
        
        // Add context if provided
        if let context = context {
            promptParts.append("Context: \(context.description)")
        }
        
        return promptParts.joined(separator: "\n")
    }
    
    private func generateResponse(for prompt: String) async -> String {
        // Placeholder - will integrate with actual AI API
        return "Based on current data patterns, recommendation is to focus on urgent tasks and optimize worker allocation for better efficiency."
    }
    
    private func extractTitle(from query: String) -> String {
        let title = query.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "AI Insight" : String(title)
    }
    
    private func determineCategory(from query: String) -> CoreTypes.InsightCategory {
        let lowercased = query.lowercased()
        
        if lowercased.contains("efficiency") || lowercased.contains("optimize") {
            return .efficiency
        } else if lowercased.contains("cost") || lowercased.contains("expense") {
            return .cost
        } else if lowercased.contains("safety") || lowercased.contains("hazard") {
            return .safety
        } else if lowercased.contains("compliance") || lowercased.contains("regulation") {
            return .compliance
        } else if lowercased.contains("maintenance") || lowercased.contains("repair") {
            return .maintenance
        } else {
            return .operations
        }
    }
    
    private func determineIfActionRequired(from query: String) -> Bool {
        let lowercased = query.lowercased()
        return lowercased.contains("urgent") ||
               lowercased.contains("critical") ||
               lowercased.contains("immediate") ||
               lowercased.contains("required")
    }
    
    private func extractAffectedBuildings(from context: [String: Any]?) -> [String] {
        guard let context = context else { return [] }
        
        if let buildingId = context["buildingId"] as? String {
            return [buildingId]
        }
        
        if let building = context["building"] as? Building {
            return [building.id]
        }
        
        return []
    }
}

// MARK: - Public API Extensions
extension NovaIntelligenceEngine {
    
    /// Replaces NovaCore.generateInsights()
    public func generateInsights() async -> [CoreTypes.IntelligenceInsight] {
        do {
            // BuildingService returns [NamedCoordinate] which is Building via typealias
            let buildings = try await buildingService.getAllBuildings()
            
            var newInsights: [CoreTypes.IntelligenceInsight] = []
            
            for building in buildings.prefix(3) { // Process first 3 for performance
                let insight = try await generateInsight(for: building)
                newInsights.append(insight)
            }
            
            // Update published insights
            insights.append(contentsOf: newInsights)
            
            return newInsights
        } catch {
            print("Failed to generate insights: \(error)")
            return []
        }
    }
    
    /// Replaces NovaPredictionEngine.predictPortfolioTrends()
    public func predictPortfolioTrends() async throws -> [CoreTypes.AISuggestion] {
        let insight = try await process(
            query: "Predict portfolio trends based on current metrics",
            priority: .high
        )
        
        return [
            CoreTypes.AISuggestion(
                title: "Portfolio Trend Analysis",
                description: insight.description,
                priority: insight.priority,
                category: .operations,
                actionRequired: true,
                estimatedImpact: "High"
            )
        ]
    }
    
    /// Replaces NovaAIIntegrationService methods
    public func analyzeBuilding(_ buildingId: String) async throws -> CoreTypes.IntelligenceInsight {
        // Use NovaDataService to get building-specific data
        let buildingData = try await dataService.aggregateBuildingData(for: buildingId)
        
        // Create context from aggregated data
        let buildingContext: [String: Any] = [
            "buildingId": buildingId,
            "taskCount": buildingData.taskCount,
            "completionRate": buildingData.averageCompletionRate,
            "activeWorkers": buildingData.workerCount
        ]
        
        return try await process(
            query: "Analyze building performance and suggest improvements",
            context: buildingContext,
            priority: .medium
        )
    }
    
    /// Generate context-aware suggestions for current user
    public func generateContextualSuggestions(role: CoreTypes.UserRole) async throws -> [CoreTypes.AISuggestion] {
        let query: String
        let priority: CoreTypes.AIPriority
        
        switch role {
        case .worker:
            query = "What tasks should I focus on today?"
            priority = .high
        case .manager, .admin:
            query = "What operational improvements can be made?"
            priority = .medium
        case .client:
            query = "How is my portfolio performing?"
            priority = .medium
        }
        
        let insight = try await process(query: query, priority: priority)
        
        return [
            CoreTypes.AISuggestion(
                title: insight.title,
                description: insight.description,
                priority: insight.priority,
                category: insight.type,
                actionRequired: insight.actionRequired,
                estimatedImpact: role == .worker ? "High" : "Medium"
            )
        ]
    }
    
    /// Generate portfolio intelligence for AdminDashboardView
    public func generatePortfolioIntelligence() async throws -> CoreTypes.PortfolioIntelligence {
        // Use NovaDataService to get portfolio data
        let portfolioData = try await dataService.aggregatePortfolioData()
        
        // Get compliance data separately
        let complianceData = try await dataService.aggregateComplianceData()
        
        // Calculate critical issues from current insights
        let criticalIssues = insights.filter { $0.priority == .critical }.count
        
        // Determine trend based on completion rate
        // Since we don't have weekly data in NovaAggregatedData, we'll estimate
        let trend: CoreTypes.TrendDirection = {
            if portfolioData.averageCompletionRate > 0.8 {
                return .up
            } else if portfolioData.averageCompletionRate < 0.5 {
                return .down
            } else {
                return .stable
            }
        }()
        
        return CoreTypes.PortfolioIntelligence(
            totalBuildings: portfolioData.buildingCount,
            activeWorkers: portfolioData.workerCount,
            completionRate: portfolioData.averageCompletionRate,
            criticalIssues: criticalIssues,
            monthlyTrend: trend,
            complianceScore: complianceData.averageCompletionRate // Use compliance rate as score
        )
    }
}

// MARK: - Migration Helpers
extension NovaIntelligenceEngine {
    
    /// Helper for views still using NovaCore pattern
    @available(*, deprecated, message: "Use NovaIntelligenceEngine.process() instead")
    public func generateInsights(for context: String) async -> [CoreTypes.IntelligenceInsight] {
        do {
            let insight = try await process(query: context)
            return [insight]
        } catch {
            return []
        }
    }
    
    /// Helper for building-specific recommendations
    public func getRecommendations(for buildingId: String) async throws -> [CoreTypes.AISuggestion] {
        let insight = try await analyzeBuilding(buildingId)
        
        return [
            CoreTypes.AISuggestion(
                title: "Building Optimization",
                description: insight.description,
                priority: insight.priority,
                category: insight.type,
                actionRequired: insight.actionRequired,
                estimatedImpact: "Medium"
            )
        ]
    }
    
    /// Generate portfolio summary for real-time updates
    public func getPortfolioSummary() async throws -> [String: Any] {
        let data = try await dataService.aggregatePortfolioData()
        
        return [
            "buildingCount": data.buildingCount,
            "workerCount": data.workerCount,
            "taskCount": data.taskCount,
            "completionRate": data.averageCompletionRate,
            "urgentTaskCount": data.urgentTaskCount
        ]
    }
    
    /// Generate building summary for specific building
    public func getBuildingSummary(for buildingId: String) async throws -> [String: Any] {
        let data = try await dataService.aggregateBuildingData(for: buildingId)
        
        return [
            "buildingId": buildingId,
            "taskCount": data.taskCount,
            "completionRate": data.averageCompletionRate,
            "activeWorkers": data.workerCount
        ]
    }
}
