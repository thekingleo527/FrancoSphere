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
    private let dataAggregator = NovaDataService.shared
    private let intelligenceService = IntelligenceService.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    
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
            // 1. Aggregate current data into a dictionary
            let aggregatedData = try await dataAggregator.getPortfolioSummary()
            
            // 2. Generate context-aware prompt
            let prompt = generatePrompt(
                query: query,
                portfolioData: aggregatedData,
                context: context
            )
            
            processingState = .generating
            
            // 3. Generate insight based on CoreTypes structure
            let insight = CoreTypes.IntelligenceInsight(
                title: extractTitle(from: query),
                description: await generateResponse(for: prompt),
                type: determineCategory(from: query),
                priority: priority,
                actionRequired: determineIfActionRequired(from: query),
                affectedBuildings: extractAffectedBuildings(from: context)
            )
            
            // 4. Update state
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
    
    // MARK: - Private Helpers
    
    private func generatePrompt(query: String, portfolioData: [String: Any], context: [String: Any]?) -> String {
        // Extract key metrics from portfolio data
        let buildingCount = portfolioData["buildingCount"] as? Int ?? 0
        let workerCount = portfolioData["workerCount"] as? Int ?? 0
        let taskCount = portfolioData["taskCount"] as? Int ?? 0
        let completionRate = portfolioData["completionRate"] as? Double ?? 0.0
        let urgentTasks = portfolioData["urgentTaskCount"] as? Int ?? 0
        
        return """
        Query: \(query)
        Buildings: \(buildingCount)
        Active Workers: \(workerCount)
        Tasks Today: \(taskCount)
        Completion Rate: \(String(format: "%.1f%%", completionRate * 100))
        Urgent Tasks: \(urgentTasks)
        Context: \(context?.description ?? "None")
        """
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
            
            for building in buildings.prefix(3) { // Process first 3 for performance
                let insight = try await generateInsight(for: building)
                insights.append(insight)
            }
            
            return insights
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
        let buildingData = try await dataAggregator.getBuildingSummary(for: buildingId)
        
        return try await process(
            query: "Analyze building performance and suggest improvements",
            context: [
                "buildingId": buildingId,
                "taskCount": buildingData["taskCount"] ?? 0,
                "completionRate": buildingData["completionRate"] ?? 0.0
            ],
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
}

// MARK: - NovaDataService Extension
// Temporary methods until NovaDataService is properly defined
extension NovaDataService {
    func getPortfolioSummary() async throws -> [String: Any] {
        // Placeholder implementation
        return [
            "buildingCount": 20,
            "workerCount": 45,
            "taskCount": 125,
            "completionRate": 0.78,
            "urgentTaskCount": 8
        ]
    }
    
    func getBuildingSummary(for buildingId: String) async throws -> [String: Any] {
        // Placeholder implementation
        return [
            "buildingId": buildingId,
            "taskCount": 15,
            "completionRate": 0.82,
            "activeWorkers": 3
        ]
    }
}
