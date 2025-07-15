import Foundation

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
        // Placeholder integration using existing services
        _ = aiManager.hasActiveScenario(ofType: scenario.scenario)
        do {
            let insights = try await intelligenceService.generatePortfolioInsights()
            if let first = insights.first {
                return NovaContext(data: first.title)
            }
        } catch {
            print("⚠️ Failed to fetch intelligence: \(error)")
        }
        return NovaContext(data: scenario.scenario)
    }
}
