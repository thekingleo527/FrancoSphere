import Foundation

// MARK: - NovaContext (Define the missing type)
public struct NovaContext {
    public let data: String
    public let timestamp: Date
    public let insights: [String]
    
    public init(data: String, timestamp: Date = Date(), insights: [String] = []) {
        self.data = data
        self.timestamp = timestamp
        self.insights = insights
    }
}

public actor NovaContextEngine {
    public static let shared = NovaContextEngine()

    private let aiManager = AIAssistantManager.shared
    private let intelligenceService = IntelligenceService.shared

    private init() {}

    public func initialize() async {
        // Placeholder for future setup
        print("🧠 NovaContextEngine initialized")
    }

    public func generateContext(for scenario: AIScenario) async -> NovaContext {
        // ✅ FIXED: Use await for @MainActor access and correct property name
        let hasActive = await aiManager.hasActiveScenario(ofType: scenario.scenario)
        print("📊 Checking active scenarios: \(hasActive)")
        
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            if let first = insights.first {
                return NovaContext(
                    data: first.title,
                    insights: insights.map { $0.description }
                )
            }
        } catch {
            print("⚠️ Failed to fetch intelligence: \(error)")
        }
        
        // ✅ FIXED: Use correct property name 'scenario' from AIScenario
        return NovaContext(data: scenario.scenario)
    }
    
    // MARK: - Additional Context Generation Methods
    
    public func generateContextForBuilding(_ buildingId: String) async -> NovaContext {
        do {
            let insights = try await intelligenceService.generateBuildingInsights(for: buildingId)
            return NovaContext(
                data: "Building \(buildingId) context",
                insights: insights.map { $0.description }
            )
        } catch {
            print("⚠️ Failed to generate building context: \(error)")
            return NovaContext(data: "Default building context")
        }
    }
    
    public func generateContextForWorker(_ workerId: String) async -> NovaContext {
        // Get worker-specific context
        return NovaContext(
            data: "Worker \(workerId) context",
            insights: ["Worker context generated"]
        )
    }
}
