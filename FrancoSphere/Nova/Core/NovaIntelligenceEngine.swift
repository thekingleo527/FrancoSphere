//
//  NovaIntelligenceEngine.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/28/25.
//


//
//  NovaIntelligenceEngine.swift
//  FrancoSphere v6.0
//
//  Single entry point for all Nova AI operations
//  Uses CoreTypes for all data structures
//

import SwiftUI
import Combine

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
    private let dataAggregator = NovaDataAggregator.shared
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
            // 1. Aggregate current data
            let aggregatedData = await dataAggregator.aggregateAllData()
            
            // 2. Generate context-aware prompt
            let prompt = generatePrompt(
                query: query,
                data: aggregatedData,
                context: context
            )
            
            processingState = .generating
            
            // 3. Use existing IntelligenceService for now
            let insight = CoreTypes.IntelligenceInsight(
                title: extractTitle(from: query),
                description: await generateResponse(for: prompt),
                type: determineCategory(from: query),
                priority: priority
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
            context: ["buildingId": building.id],
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
                category: insight.type
            )
        ]
    }
    
    // MARK: - Private Helpers
    
    private func generatePrompt(query: String, data: NovaAggregatedData, context: [String: Any]?) -> String {
        // Use existing prompt generation logic
        return """
        Query: \(query)
        Buildings: \(data.totalBuildings)
        Active Workers: \(data.activeWorkers)
        Tasks Today: \(data.totalTasksToday)
        Context: \(context?.description ?? "None")
        """
    }
    
    private func generateResponse(for prompt: String) async -> String {
        // Placeholder - will integrate with actual AI API
        return "Based on current data patterns, recommendation is..."
    }
    
    private func extractTitle(from query: String) -> String {
        return query.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
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
}

// MARK: - Public API Extensions
extension NovaIntelligenceEngine {
    
    /// Replaces NovaCore.generateInsights()
    public func generateInsights() async -> [CoreTypes.IntelligenceInsight] {
        do {
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
        
        return [CoreTypes.AISuggestion(suggestion: insight.description)]
    }
}