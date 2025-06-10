/// AIAssistantManager.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// Manages helper AI "scenarios." No need to re‐declare AIScenario here.

import Foundation

class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()

    @Published var currentScenario: FrancoSphere.AIScenario?
    @Published var scenarioQueue: [FrancoSphere.AIScenario] = []
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
            if let scenario = notification.userInfo?["scenario"] as? FrancoSphere.AIScenario {
                self?.enqueue(scenario)
            }
        }
    }

    private func enqueue(_ scenario: FrancoSphere.AIScenario) {
        if !scenarioQueue.contains(where: { $0 == scenario }) {
            scenarioQueue.append(scenario)
            advanceIfNeeded()
        }
    }

    private func advanceIfNeeded() {
        if currentScenario == nil, !scenarioQueue.isEmpty {
            currentScenario = scenarioQueue.removeFirst()
            hasActiveScenarios = true
        }
    }

    func dismissCurrentScenario() {
        currentScenario = nil
        advanceIfNeeded()
        hasActiveScenarios = !scenarioQueue.isEmpty
    }

    func performAction() {
        guard let scenario = currentScenario else { return }

        switch scenario {
        case .routineIncomplete, .pendingTasks:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTasks"), object: nil)
        case .missingPhoto:
            NotificationCenter.default.post(name: NSNotification.Name("OpenCamera"), object: nil)
        case .clockOutReminder:
            NotificationCenter.default.post(name: NSNotification.Name("TriggerClockOut"), object: nil)
        case .weatherAlert:
            NotificationCenter.default.post(name: NSNotification.Name("ShowWeatherDetails"), object: nil)
        case .buildingArrival:
            NotificationCenter.default.post(name: NSNotification.Name("ShowBuildingDetails"), object: nil)
        case .taskCompletion:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTasks"), object: nil)
        case .inventoryLow:
            NotificationCenter.default.post(name: NSNotification.Name("ShowInventory"), object: nil)
        }

        dismissCurrentScenario()
    }

    static func trigger(for scenario: FrancoSphere.AIScenario) {
        NotificationCenter.default.post(
            name: NSNotification.Name("AIScenarioTriggered"),
            object: nil,
            userInfo: ["scenario": scenario]
        )
    }
}
