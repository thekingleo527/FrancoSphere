#!/bin/bash
set -e

echo "🔧 Fixing AIAssistantManager.swift - Complete Rebuild"
echo "===================================================="

cd "/Volumes/FastSSD/Xcode" || exit 1

# =============================================================================
# 🔧 FIX 1: Completely rebuild AIAssistantManager.swift
# =============================================================================

echo ""
echo "🔧 Completely rebuilding AIAssistantManager.swift..."

cat > "Managers/AIAssistantManager.swift" << 'AI_MANAGER_EOF'
//
//  AIAssistantManager.swift
//  FrancoSphere
//
//  Complete AI Assistant Manager with proper class structure
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AIAssistantManager: ObservableObject {
    static let shared = AIAssistantManager()
    
    // MARK: - Published Properties
    @Published var activeScenarios: [AIScenario] = []
    @Published var hasActiveScenarios: Bool = false
    @Published var suggestions: [AISuggestion] = []
    @Published var currentScenario: AIScenario?
    @Published var currentScenarioData: AIScenarioData?
    @Published var isProcessing: Bool = false
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        $activeScenarios
            .map { !$0.isEmpty }
            .assign(to: \.hasActiveScenarios, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Scenario Management
    func addScenario(_ scenarioType: String) {
        let scenario = AIScenario(type: scenarioType)
        activeScenarios.append(scenario)
        hasActiveScenarios = !activeScenarios.isEmpty
        print("📱 Added AI scenario: \(scenarioType)")
    }
    
    func dismissScenario(_ scenarioId: String) {
        activeScenarios.removeAll { $0.id == scenarioId }
        hasActiveScenarios = !activeScenarios.isEmpty
    }
    
    func clearAllScenarios() {
        activeScenarios.removeAll()
        suggestions.removeAll()
        hasActiveScenarios = false
        currentScenario = nil
        currentScenarioData = nil
    }
    
    // MARK: - Suggestion Generation
    private func generateSuggestions(for scenarioType: String) -> [AISuggestion] {
        switch scenarioType {
        case "routineIncomplete":
            return [
                AISuggestion(text: "Review incomplete tasks", actionType: "review"),
                AISuggestion(text: "Update task status", actionType: "update")
            ]
        case "taskCompletion":
            return [
                AISuggestion(text: "Mark task as complete", actionType: "complete"),
                AISuggestion(text: "Add completion notes", actionType: "notes")
            ]
        case "pendingTasks":
            return [
                AISuggestion(text: "Prioritize pending tasks", actionType: "prioritize"),
                AISuggestion(text: "Reschedule if needed", actionType: "reschedule")
            ]
        case "buildingArrival":
            return [
                AISuggestion(text: "Clock in at building", actionType: "checkin"),
                AISuggestion(text: "Review today's schedule", actionType: "schedule")
            ]
        case "weatherAlert":
            return [
                AISuggestion(text: "Check weather impact", actionType: "weather"),
                AISuggestion(text: "Adjust outdoor tasks", actionType: "adjust")
            ]
        case "maintenanceRequired":
            return [
                AISuggestion(text: "Schedule maintenance", actionType: "schedule"),
                AISuggestion(text: "Order required parts", actionType: "order")
            ]
        case "scheduleConflict":
            return [
                AISuggestion(text: "Resolve conflict", actionType: "resolve"),
                AISuggestion(text: "Notify supervisor", actionType: "notify")
            ]
        case "emergencyResponse":
            return [
                AISuggestion(text: "Follow emergency protocol", actionType: "emergency"),
                AISuggestion(text: "Contact emergency services", actionType: "contact")
            ]
        default:
            return [
                AISuggestion(text: "Take appropriate action", actionType: "general")
            ]
        }
    }
    
    // MARK: - Scenario Processing
    func processScenario(_ scenario: AIScenario) {
        isProcessing = true
        currentScenario = scenario
        suggestions = generateSuggestions(for: scenario.type)
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isProcessing = false
        }
    }
    
    func processScenarioData(_ data: AIScenarioData) {
        currentScenarioData = data
        
        // Generate contextual suggestions based on scenario data
        if let context = currentScenarioData?.context {
            suggestions = generateContextualSuggestions(for: context)
        }
    }
    
    private func generateContextualSuggestions(for context: String) -> [AISuggestion] {
        // Simple context-based suggestion generation
        switch context.lowercased() {
        case let ctx where ctx.contains("weather"):
            return [
                AISuggestion(text: "Check weather conditions", actionType: "weather"),
                AISuggestion(text: "Reschedule outdoor tasks", actionType: "reschedule")
            ]
        case let ctx where ctx.contains("maintenance"):
            return [
                AISuggestion(text: "Review maintenance schedule", actionType: "review"),
                AISuggestion(text: "Check equipment status", actionType: "check")
            ]
        case let ctx where ctx.contains("task"):
            return [
                AISuggestion(text: "Update task progress", actionType: "update"),
                AISuggestion(text: "Mark task complete", actionType: "complete")
            ]
        default:
            return [
                AISuggestion(text: "Review current status", actionType: "review")
            ]
        }
    }
    
    // MARK: - Action Handling
    func performAction(_ actionType: String) {
        print("🤖 AI Assistant performing action: \(actionType)")
        
        switch actionType {
        case "review":
            print("📋 Reviewing current status...")
        case "update":
            print("🔄 Updating information...")
        case "complete":
            print("✅ Marking as complete...")
        case "schedule":
            print("📅 Scheduling task...")
        case "weather":
            print("🌤️ Checking weather conditions...")
        case "emergency":
            print("🚨 Following emergency protocol...")
        default:
            print("🔧 Performing general action...")
        }
    }
    
    // MARK: - Utility Methods
    func dismissCurrentScenario() {
        currentScenario = nil
        currentScenarioData = nil
        suggestions.removeAll()
    }
    
    func hasActiveScenario(ofType type: String) -> Bool {
        return activeScenarios.contains { $0.type == type }
    }
    
    func getActiveScenarios(ofType type: String) -> [AIScenario] {
        return activeScenarios.filter { $0.type == type }
    }
    
    // MARK: - Debug Methods
    func debugPrintStatus() {
        print("🤖 AI Assistant Status:")
        print("  Active scenarios: \(activeScenarios.count)")
        print("  Current scenario: \(currentScenario?.title ?? "None")")
        print("  Suggestions: \(suggestions.count)")
        print("  Processing: \(isProcessing)")
    }
}

// MARK: - Scenario Types Extension
extension AIAssistantManager {
    enum ScenarioType {
        static let routineIncomplete = "routineIncomplete"
        static let taskCompletion = "taskCompletion"
        static let pendingTasks = "pendingTasks"
        static let buildingArrival = "buildingArrival"
        static let weatherAlert = "weatherAlert"
        static let maintenanceRequired = "maintenanceRequired"
        static let scheduleConflict = "scheduleConflict"
        static let emergencyResponse = "emergencyResponse"
    }
}
AI_MANAGER_EOF

echo "✅ Completely rebuilt AIAssistantManager.swift"

# =============================================================================
# 🔧 BUILD TEST
# =============================================================================

echo ""
echo "🔨 Testing build after AIAssistantManager rebuild..."

BUILD_OUTPUT=$(xcodebuild -project FrancoSphere.xcodeproj -scheme FrancoSphere build -destination "platform=iOS Simulator,name=iPhone 15 Pro" 2>&1)

ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c " error:" || echo "0")
AI_MANAGER_ERRORS=$(echo "$BUILD_OUTPUT" | grep -c "AIAssistantManager\|Cannot find.*in scope" || echo "0")

echo ""
echo "📊 Build Results:"
echo "• Total errors: $ERROR_COUNT"
echo "• AIAssistantManager errors: $AI_MANAGER_ERRORS"

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo ""
    echo "🟢 ✅ BUILD SUCCESS"
    echo "=================="
    echo "🎉 AIAssistantManager completely fixed!"
    echo "✅ FrancoSphere compiles successfully"
elif [ "$AI_MANAGER_ERRORS" -eq 0 ]; then
    echo ""
    echo "🟡 ✅ AI MANAGER FIXED"
    echo "====================="
    echo "✅ No more AIAssistantManager errors"
    echo "⚠️  $ERROR_COUNT other errors remain"
    echo ""
    echo "📋 Remaining errors:"
    echo "$BUILD_OUTPUT" | grep " error:" | head -10
else
    echo ""
    echo "🔴 ❌ AI MANAGER ERRORS PERSIST"
    echo "=============================="
    echo "❌ $AI_MANAGER_ERRORS AIAssistantManager errors remain"
    echo ""
    echo "📋 AIAssistantManager errors:"
    echo "$BUILD_OUTPUT" | grep -E "(AIAssistantManager|Cannot find.*in scope)" | head -10
fi

echo ""
echo "🔧 AIAssistantManager Rebuild Complete"
echo "====================================="
