import Foundation
// Import Nova Types
// All Nova types (NovaContext, NovaPrompt, etc.) come from NovaTypes.swift

//
//  NovaContextEngine.swift
//  FrancoSphere v6.0 - Nova AI Context Engine
//
//  ✅ FIXED: Uses authoritative NovaTypes for all type definitions
//  ✅ ACTOR: Thread-safe context generation and management
//  ✅ INTEGRATED: Works with existing FrancoSphere services
//

import Foundation

// Import the authoritative Nova types
// All NovaContext, NovaPrompt, etc. come from NovaTypes.swift

public actor NovaContextEngine {
    public static let shared = NovaContextEngine()
    
    // MARK: - Dependencies (using .shared pattern)
    private let aiManager = AIAssistantManager.shared
    private let intelligenceService = IntelligenceService.shared
    
    // MARK: - Internal State
    private var cachedContexts: [String: NovaContext] = [:]
    private var lastContextUpdate: Date = Date()
    private let cacheTimeout: TimeInterval = 300 // 5 minutes
    
    private init() {}
    
    // MARK: - Initialization
    public func initialize() async {
        print("🧠 NovaContextEngine initialized")
        await clearExpiredCache()
    }
    
    // MARK: - Context Generation
    public func generateContext(for scenario: AIScenario) async -> NovaContext {
        let cacheKey = "scenario_\(scenario.id)"
        
        // Check cache first
        if let cachedContext = cachedContexts[cacheKey],
           Date().timeIntervalSince(lastContextUpdate) < cacheTimeout {
            return cachedContext
        }
        
        // Generate new context
        let context = await createContextForScenario(scenario)
        
        // Cache the result
        cachedContexts[cacheKey] = context
        lastContextUpdate = Date()
        
        return context
    }
    
    public func generateContextForBuilding(_ buildingId: String) async -> NovaContext {
        let cacheKey = "building_\(buildingId)"
        
        if let cachedContext = cachedContexts[cacheKey],
           Date().timeIntervalSince(lastContextUpdate) < cacheTimeout {
            return cachedContext
        }
        
        let context = await createContextForBuilding(buildingId)
        cachedContexts[cacheKey] = context
        lastContextUpdate = Date()
        
        return context
    }
    
    public func generateContextForWorker(_ workerId: String) async -> NovaContext {
        let cacheKey = "worker_\(workerId)"
        
        if let cachedContext = cachedContexts[cacheKey],
           Date().timeIntervalSince(lastContextUpdate) < cacheTimeout {
            return cachedContext
        }
        
        let context = await createContextForWorker(workerId)
        cachedContexts[cacheKey] = context
        lastContextUpdate = Date()
        
        return context
    }
    
    // MARK: - Private Context Creation Methods
    private func createContextForScenario(_ scenario: AIScenario) async -> NovaContext {
        do {
            // Check if there are active scenarios of this type
            let hasActive = await aiManager.hasActiveScenario(ofType: scenario.scenario)
            
            // Get intelligence insights
            let insights = try await intelligenceService.generatePortfolioInsights()
            let insightDescriptions = insights.map { $0.description }
            
            let metadata = [
                "scenario_type": scenario.scenario,
                "has_active": String(hasActive),
                "insight_count": String(insights.count),
                "created_at": ISO8601DateFormatter().string(from: scenario.createdAt)
            ]
            
            return NovaContext(
                data: "Scenario: \(scenario.scenario)",
                insights: insightDescriptions,
                metadata: metadata
            )
            
        } catch {
            print("⚠️ Failed to create scenario context: \(error)")
            return NovaContext(
                data: "Scenario: \(scenario.scenario) (minimal context due to error)",
                insights: ["Error generating full context"],
                metadata: ["error": error.localizedDescription]
            )
        }
    }
    
    private func createContextForBuilding(_ buildingId: String) async -> NovaContext {
        do {
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            let insightDescriptions = insights.map { $0.description }
            
            let metadata = [
                "building_id": buildingId,
                "insight_count": String(insights.count),
                "context_type": "building"
            ]
            
            return NovaContext(
                data: "Building \(buildingId) operational context",
                insights: insightDescriptions,
                metadata: metadata
            )
            
        } catch {
            print("⚠️ Failed to create building context: \(error)")
            return NovaContext(
                data: "Building \(buildingId) (minimal context)",
                insights: ["Error generating building context"],
                metadata: ["building_id": buildingId, "error": error.localizedDescription]
            )
        }
    }
    
    private func createContextForWorker(_ workerId: String) async -> NovaContext {
        let metadata = [
            "worker_id": workerId,
            "context_type": "worker",
            "generated_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        return NovaContext(
            data: "Worker \(workerId) operational context",
            insights: ["Worker context generated", "Ready for task assignment"],
            metadata: metadata
        )
    }
    
    // MARK: - Cache Management
    private func clearExpiredCache() async {
        let now = Date()
        let cutoffTime = now.addingTimeInterval(-cacheTimeout)
        
        if lastContextUpdate < cutoffTime {
            cachedContexts.removeAll()
            print("🧹 NovaContextEngine cache cleared")
        }
    }
    
    public func invalidateCache() async {
        cachedContexts.removeAll()
        lastContextUpdate = Date.distantPast
        print("🔄 NovaContextEngine cache invalidated")
    }
    
    public func getCacheStats() async -> (count: Int, lastUpdate: Date) {
        return (cachedContexts.count, lastContextUpdate)
    }
}

// MARK: - Error Types
public enum NovaContextError: Error, LocalizedError {
    case serviceUnavailable(String)
    case dataInconsistent(String)
    case cacheCorrupted
    
    public var errorDescription: String? {
        switch self {
        case .serviceUnavailable(let service):
            return "Nova service unavailable: \(service)"
        case .dataInconsistent(let details):
            return "Nova data inconsistency: \(details)"
        case .cacheCorrupted:
            return "Nova context cache corrupted"
        }
    }
}
