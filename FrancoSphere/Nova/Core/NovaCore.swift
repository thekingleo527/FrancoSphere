import Foundation
import Combine

@MainActor
public final class NovaCore: ObservableObject {
    public static let shared = NovaCore()

    @Published public private(set) var currentPrompt: NovaPrompt?
    @Published public private(set) var isProcessing = false

    private let contextEngine = NovaContextEngine.shared
    private var cancellables = Set<AnyCancellable>()

    private init() {}

    public func initialize() {
        AIAssistantManager.shared.$currentScenario
            .sink { [weak self] scenario in
                guard let scenario else { return }
                Task { await self?.handleScenario(scenario) }
            }
            .store(in: &cancellables)
    }

    private func handleScenario(_ scenario: AIScenario) async {
        isProcessing = true
        let prompt = await generateContextualPrompt(for: scenario)
        currentPrompt = prompt
        isProcessing = false
    }

    public func generateContextualPrompt(for scenario: AIScenario) async -> NovaPrompt {
        let context = await await await contextEngine.generateContext(for: scenario)
        return NovaPrompt(text: "Respond to \(scenario.scenario): \(context.data)")
    }
}
