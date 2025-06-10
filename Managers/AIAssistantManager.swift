//
// AIAssistantManager.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// Manages helper AI "scenarios." No need to re‐declare AIScenario here.

import Foundation

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
                self?.enqueue(scenario)
            }
        }
    }

    private func enqueue(_ scenario: AIScenario) {
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
        case .routineIncomplete:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTasks"), object: nil)
        case .pendingTasks:
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToTasks"), object: nil)
        case .missingPhoto:
            NotificationCenter.default.post(name: NSNotification.Name("OpenCamera"), object: nil)
        case .clockOutReminder:
            NotificationCenter.default.post(name: NSNotification.Name("TriggerClockOut"), object: nil)
        case .weatherAlert:
            NotificationCenter.default.post(name: NSNotification.Name("ShowWeatherDetails"), object: nil)
        default:
            // Handle any additional AIScenario cases
            print("Unhandled AI scenario: \(scenario)")
            NotificationCenter.default.post(name: NSNotification.Name("DefaultAIAction"), object: nil)
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
