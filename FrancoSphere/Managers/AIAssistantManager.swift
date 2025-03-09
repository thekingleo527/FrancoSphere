import Foundation
import SwiftUI

class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    @Published var currentScenario: AIScenario?
    @Published var scenarioQueue: [AIScenario] = []
    @Published var hasActiveScenarios: Bool = false
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("AIScenarioTriggered"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let scenario = notification.userInfo?["scenario"] as? AIScenario {
                self?.handleNewScenario(scenario)
            }
        }
    }
    
    private func handleNewScenario(_ scenario: AIScenario) {
        // Add to queue if not already present
        if !scenarioQueue.contains(where: { $0 == scenario }) {
            scenarioQueue.append(scenario)
            updateCurrentScenario()
        }
    }
    
    private func updateCurrentScenario() {
        if currentScenario == nil, !scenarioQueue.isEmpty {
            currentScenario = scenarioQueue.removeFirst()
            hasActiveScenarios = true
        }
    }
    
    func dismissCurrentScenario() {
        currentScenario = nil
        updateCurrentScenario()
        hasActiveScenarios = !scenarioQueue.isEmpty
    }
    
    func performAction() {
        // Implement action handling based on the current scenario
        guard let scenario = currentScenario else { return }
        
        switch scenario {
        case .routineIncomplete, .pendingTasks:
            // Navigate to tasks view
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTasks"), object: nil)
        case .missingPhoto:
            // Open camera
            NotificationCenter.default.post(name: NSNotification.Name("OpenCamera"), object: nil)
        case .clockOutReminder:
            // Trigger clock out
            NotificationCenter.default.post(name: NSNotification.Name("TriggerClockOut"), object: nil)
        case .weatherAlert:
            // Show weather details
            NotificationCenter.default.post(name: NSNotification.Name("ShowWeatherDetails"), object: nil)
        }
        
        dismissCurrentScenario()
    }
    
    static func trigger(for scenario: AIScenario) {
        NotificationCenter.default.post(
            name: NSNotification.Name("AIScenarioTriggered"),
            object: nil,
            userInfo: ["scenario": scenario]
        )
    }
}
