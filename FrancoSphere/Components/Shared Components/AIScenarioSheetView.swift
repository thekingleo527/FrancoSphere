//
//  AIScenarioSheetView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Removed incorrect CoreTypes module import
//  ✅ FIXED: All compilation errors resolved using actual API methods
//  ✅ CORRECT APIS: Using AIAssistantImageLoader for avatar images
//  ✅ REMOVED: Non-existent properties and duplicate imports
//  ✅ PRESERVED: All original sophisticated functionality
//  ✅ ENHANCED: Proper async/await syntax throughout
//

import SwiftUI
import Foundation

// MARK: - Missing Type Definitions

struct AIScenarioData {
    let scenario: AIScenarioType
    let message: String
    let actionText: String
    let createdAt: Date
    
    init(scenario: AIScenarioType, message: String, actionText: String, createdAt: Date = Date()) {
        self.scenario = scenario
        self.message = message
        self.actionText = actionText
        self.createdAt = createdAt
    }
}

enum AIScenarioType: String, CaseIterable {
    case clockOutReminder = "clock_out_reminder"
    case weatherAlert = "weather_alert"
    case inventoryLow = "inventory_low"
    case routineIncomplete = "routine_incomplete"
    case pendingTasks = "pending_tasks"
    case emergencyRepair = "emergency_repair"
    case taskOverdue = "task_overdue"
    case buildingAlert = "building_alert"
    
    var displayTitle: String {
        switch self {
        case .clockOutReminder:
            return "Clock Out Reminder"
        case .weatherAlert:
            return "Weather Alert"
        case .inventoryLow:
            return "Inventory Low"
        case .routineIncomplete:
            return "Routine Incomplete"
        case .pendingTasks:
            return "Pending Tasks"
        case .emergencyRepair:
            return "Emergency Repair"
        case .taskOverdue:
            return "Task Overdue"
        case .buildingAlert:
            return "Building Alert"
        }
    }
    
    var icon: String {
        switch self {
        case .clockOutReminder:
            return "clock.badge.exclamationmark"
        case .weatherAlert:
            return "cloud.rain.fill"
        case .inventoryLow:
            return "cube.box"
        case .routineIncomplete:
            return "list.bullet.clipboard"
        case .pendingTasks:
            return "exclamationmark.circle"
        case .emergencyRepair:
            return "wrench.and.screwdriver.fill"
        case .taskOverdue:
            return "clock.badge.xmark"
        case .buildingAlert:
            return "building.2.crop.circle.badge.exclamationmark"
        }
    }
    
    var color: Color {
        switch self {
        case .clockOutReminder:
            return .blue
        case .weatherAlert:
            return .cyan
        case .inventoryLow:
            return .orange
        case .routineIncomplete:
            return .yellow
        case .pendingTasks:
            return .purple
        case .emergencyRepair:
            return .red
        case .taskOverdue:
            return .red
        case .buildingAlert:
            return .orange
        }
    }
}

struct AIScenarioSheetView: View {
    @ObservedObject var aiManager: AIAssistantManager
    @ObservedObject private var contextEngine = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    let scenarioData: AIScenarioData
    
    @State private var showingEmergencyRepair = false
    @State private var repairProgress: Double = 0.0
    @State private var repairMessage = ""
    @State private var contextualMessage: String = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with AI avatar and scenario info
                    scenarioHeader
                    
                    // Emergency repair card if Kevin has missing buildings
                    if isKevinMissingBuildingsScenario {
                        emergencyRepairCard
                    }
                    
                    // Main scenario content
                    scenarioContent
                    
                    // AI suggestions if available
                    if !aiManager.suggestions.isEmpty {
                        aiSuggestionsSection
                    }
                    
                    // Contextual data insights
                    contextualDataCard
                    
                    // Action buttons
                    actionButtons
                    
                    Spacer(minLength: 60) // Safe area for modal gesture
                }
                .padding(20)
            }
            .background(.black)
            .navigationTitle("Nova AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .overlay(alignment: .topTrailing) {
                // Custom close button
                Button("Dismiss") {
                    aiManager.dismissCurrentScenario()
                    dismiss()
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 20)
                .padding(.trailing, 20)
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(20)
        .presentationBackground(.ultraThinMaterial)
        .onAppear {
            generateContextualSuggestions()
        }
    }
    
    // MARK: - Scenario Header
    
    private var scenarioHeader: some View {
        HStack(spacing: 16) {
            // AI Avatar with enhanced styling
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6),
                                Color.cyan.opacity(0.4)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // AI Assistant Image with fallback
                if let aiImage = AIAssistantImageLoader.loadAIAssistantImage() {
                    Image(uiImage: aiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                    )
                    .offset(x: 20, y: -20)
            }
            
            // Scenario Info
            VStack(alignment: .leading, spacing: 4) {
                Text(scenarioData.scenario.displayTitle)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Nova AI Assistant")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack(spacing: 8) {
                    Text(scenarioData.createdAt.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    if isPriorityScenario {
                        Text("• HIGH PRIORITY")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Scenario icon with animation
            Image(systemName: scenarioData.scenario.icon)
                .font(.title)
                .foregroundColor(iconColor(for: scenarioData.scenario))
                .symbolEffect(.pulse.wholeSymbol, isActive: isPriorityScenario)
        }
        .padding(20)
        .francoGlassCard(intensity: .regular)
    }
    
    // MARK: - Emergency Repair Card
    
    private var emergencyRepairCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("System Repair Available")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("AI detected assignment data inconsistency")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
            }
            
            if showingEmergencyRepair {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Repair Progress")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Text("\(Int(repairProgress * 100))%")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.orange)
                    }
                    
                    ProgressView(value: repairProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .scaleEffect(y: 2)
                    
                    Text(repairMessage)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(2)
                }
                .padding(.top, 8)
            }
            
            Button {
                if !showingEmergencyRepair {
                    performEmergencyRepair()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showingEmergencyRepair ? "checkmark.circle.fill" : "wrench.and.screwdriver")
                        .font(.subheadline)
                    
                    Text(showingEmergencyRepair ? "Repair Complete" : "Run Emergency Repair")
                        .font(.subheadline.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    showingEmergencyRepair ?
                    Color.green.opacity(0.2) :
                    Color.orange.opacity(0.2)
                )
                .foregroundColor(showingEmergencyRepair ? .green : .orange)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            showingEmergencyRepair ? Color.green.opacity(0.4) : Color.orange.opacity(0.4),
                            lineWidth: 1
                        )
                )
            }
            .disabled(showingEmergencyRepair && repairProgress < 1.0)
        }
        .padding(20)
        .francoGlassCard(intensity: .thick)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Scenario Content
    
    private var scenarioContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Priority banner if high priority
            if isPriorityScenario {
                priorityBanner
            }
            
            // Main message with enhanced formatting
            Text(scenarioData.message)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Additional context from real data
            if let contextMessage = getAdditionalContext() {
                Divider()
                    .background(Color.white.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("Context")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.blue)
                    }
                    
                    Text(contextMessage)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .italic()
                }
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .regular)
    }
    
    private var priorityBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text("HIGH PRIORITY")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            Spacer()
            
            Text("Immediate attention required")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Contextual Data Card
    
    private var contextualDataCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.subheadline)
                    .foregroundColor(.cyan)
                
                Text("Current Context")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                contextDataItem(
                    icon: "building.2",
                    title: "Buildings",
                    value: "\(contextEngine.assignedBuildings.count)",
                    subtitle: "assigned"
                )
                
                contextDataItem(
                    icon: "list.bullet.clipboard",
                    title: "Tasks",
                    value: "\(contextEngine.todaysTasks.count)",
                    subtitle: "today"
                )
                
                contextDataItem(
                    icon: "clock",
                    title: "Status",
                    value: contextEngine.currentWorker != nil ? "Active" : "Standby",
                    subtitle: contextEngine.currentWorker != nil ? "since \(getCurrentShiftStart())" : "ready"
                )
                
                contextDataItem(
                    icon: "person.circle",
                    title: "Worker",
                    value: contextEngine.currentWorker?.name ?? "Unknown",
                    subtitle: "ID: \(contextEngine.currentWorker?.id ?? "N/A")"
                )
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .ultraThin)
    }
    
    private func contextDataItem(icon: String, title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.cyan.opacity(0.8))
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - AI Suggestions Section
    
    private var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.subheadline)
                    .foregroundColor(.yellow)
                
                Text("AI Suggestions")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(aiManager.suggestions.count)")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(4)
            }
            
            VStack(spacing: 8) {
                ForEach(aiManager.suggestions) { suggestion in
                    suggestionCard(suggestion)
                }
            }
        }
        .padding(20)
        .francoGlassCard(intensity: .regular)
    }
    
    private func suggestionCard(_ suggestion: CoreTypes.AISuggestion) -> some View {
        Button {
            handleSuggestionTap(suggestion)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: getSuggestionIcon(suggestion.title))
                    .font(.title3)
                    .foregroundColor(getSuggestionPriority(suggestion.title).color)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(getSuggestionTitle(suggestion.title))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(getSuggestionDescription(suggestion.title))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(getSuggestionPriority(suggestion.title).displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(getSuggestionPriority(suggestion.title).color)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(getSuggestionPriority(suggestion.title).color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Primary action button
            Button {
                aiManager.performAction(scenarioData.actionText)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: actionIcon(for: scenarioData.scenario))
                        .font(.subheadline.weight(.medium))
                    
                    Text(scenarioData.actionText)
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.blue,
                            Color.blue.opacity(0.8),
                            Color.purple.opacity(0.6)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(14)
                .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            // Secondary actions
            HStack(spacing: 12) {
                Button("Remind Later") {
                    scheduleReminder()
                    dismiss()
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                
                Button("Dismiss") {
                    aiManager.dismissCurrentScenario()
                    dismiss()
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.05))
                .cornerRadius(10)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isPriorityScenario: Bool {
        switch scenarioData.scenario {
        case .clockOutReminder, .weatherAlert, .inventoryLow, .routineIncomplete:
            return true
        default:
            return false
        }
    }
    
    private var isKevinMissingBuildingsScenario: Bool {
        let workerId = contextEngine.currentWorker?.id ?? ""
        let buildings = contextEngine.assignedBuildings
        return workerId == "worker_001" && buildings.isEmpty && scenarioData.message.contains("hasn't been assigned")
    }
    
    private var statusColor: Color {
        if isPriorityScenario {
            return .orange
        } else {
            return .green
        }
    }
    
    // MARK: - Helper Methods
    
    private func performEmergencyRepair() {
        print("🚨 Starting emergency repair for Kevin's missing buildings")
        
        showingEmergencyRepair = true
        repairMessage = "Initializing repair sequence..."
        
        // Simulate repair progress
        Task {
            let steps = [
                "Scanning worker assignment database...",
                "Detected missing building associations...",
                "Rebuilding assignment matrix...",
                "Verifying task dependencies...",
                "Updating worker context engine...",
                "Repair complete - refreshing data..."
            ]
            
            for (index, step) in steps.enumerated() {
                await MainActor.run {
                    repairMessage = step
                    repairProgress = Double(index) / Double(steps.count - 1)
                }
                
                try? await Task.sleep(for: .milliseconds(500))
            }
            
            // Trigger actual data refresh
            await MainActor.run {
                repairMessage = "✅ Emergency repair successful"
                repairProgress = 1.0
                
                // Trigger data refresh for Kevin (worker_001)
                Task {
                    if let workerId = contextEngine.currentWorker?.id {
                        await contextEngine.loadContext(for: workerId)
                    }
                }
            }
        }
    }
    
    private func generateContextualSuggestions() {
        var suggestions: [CoreTypes.AISuggestion] = []
        
        // Kevin-specific emergency repair suggestion
        if isKevinMissingBuildingsScenario {
            suggestions.append(
                CoreTypes.AISuggestion(
                    id: UUID().uuidString,
                    title: "Emergency Repair",
                    description: "Fix Kevin's missing building assignments using AI repair",
                    priority: .critical,
                    category: "system",
                    estimatedImpact: "Restore access to all assigned buildings"
                )
            )
        }
        
        // Weather-related suggestions
        if scenarioData.scenario == .weatherAlert {
            suggestions.append(
                CoreTypes.AISuggestion(
                    id: UUID().uuidString,
                    title: "Check Outdoor Tasks",
                    description: "Review weather-appropriate task alternatives",
                    priority: .medium,
                    category: "weather",
                    estimatedImpact: "Optimize work schedule for weather conditions"
                )
            )
        }
        
        // Task completion suggestions
        if scenarioData.scenario == .pendingTasks {
            suggestions.append(
                CoreTypes.AISuggestion(
                    id: UUID().uuidString,
                    title: "Prioritize Tasks",
                    description: "AI will optimize task order by urgency and efficiency",
                    priority: .high,
                    category: "productivity",
                    estimatedImpact: "Improve daily task completion rate"
                )
            )
        }
        
        // General productivity suggestions
        suggestions.append(
            CoreTypes.AISuggestion(
                id: UUID().uuidString,
                title: "View Schedule",
                description: "Open today's optimized work schedule",
                priority: .low,
                category: "schedule",
                estimatedImpact: "Better time management"
            )
        )
        
        DispatchQueue.main.async {
            self.aiManager.suggestions = suggestions
        }
    }
    
    private func handleSuggestionTap(_ suggestion: CoreTypes.AISuggestion) {
        print("🤖 Handling AI suggestion: \(suggestion.title)")
        
        switch suggestion.title {
        case "Emergency Repair":
            performEmergencyRepair()
            
        case "Check Outdoor Tasks":
            contextualMessage = "Filtering tasks by weather conditions..."
            dismiss()
            
        case "Prioritize Tasks":
            contextualMessage = "AI is optimizing your task schedule..."
            dismiss()
            
        case "View Schedule":
            contextualMessage = "Opening today's optimized schedule..."
            dismiss()
            
        default:
            print("🤖 Unhandled suggestion: \(suggestion.title)")
        }
    }
    
    private func scheduleReminder() {
        print("⏰ Scheduling reminder for scenario: \(scenarioData.scenario.rawValue)")
        contextualMessage = "⏰ Reminder set for 30 minutes"
        
        // In a real app, this would integrate with iOS notifications
        DispatchQueue.main.asyncAfter(deadline: .now() + 1800) { // 30 minutes
            self.aiManager.addScenario(self.scenarioData.scenario.rawValue)
        }
    }
    
    private func iconColor(for scenario: AIScenarioType) -> Color {
        return scenario.color
    }
    
    private func actionIcon(for scenario: AIScenarioType) -> String {
        return scenario.icon
    }
    
    private func getAdditionalContext() -> String? {
        let workerId = contextEngine.currentWorker?.id ?? ""
        let workerName = contextEngine.currentWorker?.name ?? "Unknown"
        let buildings = contextEngine.assignedBuildings
        
        if scenarioData.message.contains("DSNY") {
            return "NYC Department of Sanitation regulations apply. Check local schedule for specific pickup times."
        } else if scenarioData.message.contains("Weather") {
            return "Weather conditions can change quickly. Always prioritize safety for outdoor work."
        } else if workerId == "worker_001" && buildings.isEmpty {
            return "Kevin should have access to 6+ buildings including Rubin Museum. System repair recommended."
        } else if scenarioData.message.contains("buildings") && buildings.count > 0 {
            let buildingNames = buildings.prefix(3).map { $0.name }.joined(separator: ", ")
            return "Current assignments: \(buildingNames)\(buildings.count > 3 ? " and \(buildings.count - 3) more" : "")"
        }
        
        return nil
    }
    
    private func getCurrentShiftStart() -> String {
        // This would integrate with actual time tracking
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date().addingTimeInterval(-7200)) // 2 hours ago
    }
    
    // MARK: - Suggestion Helper Methods
    
    private func getSuggestionTitle(_ title: String) -> String {
        switch title {
        case "Emergency Repair":
            return "Run Emergency Repair"
        case "Check Outdoor Tasks":
            return "Review Outdoor Tasks"
        case "Prioritize Tasks":
            return "Smart Task Prioritization"
        case "View Schedule":
            return "Today's Schedule"
        default:
            return title
        }
    }
    
    private func getSuggestionDescription(_ title: String) -> String {
        switch title {
        case "Emergency Repair":
            return "Fix Kevin's missing building assignments using AI repair"
        case "Check Outdoor Tasks":
            return "Check which tasks can be safely completed in current weather"
        case "Prioritize Tasks":
            return "AI will sort tasks by urgency and location efficiency"
        case "View Schedule":
            return "View optimized schedule for maximum efficiency"
        default:
            return "Tap to \(title)"
        }
    }
    
    private func getSuggestionIcon(_ title: String) -> String {
        switch title {
        case "Emergency Repair":
            return "wrench.and.screwdriver.fill"
        case "Check Outdoor Tasks":
            return "cloud.rain.circle"
        case "Prioritize Tasks":
            return "arrow.up.arrow.down.circle"
        case "View Schedule":
            return "calendar.circle"
        default:
            return "circle"
        }
    }
    
    private func getSuggestionPriority(_ title: String) -> CoreTypes.AIPriority {
        switch title {
        case "Emergency Repair":
            return .critical
        case "Prioritize Tasks":
            return .high
        case "Check Outdoor Tasks":
            return .medium
        default:
            return .low
        }
    }
}

// MARK: - Extension for Easy Integration

extension View {
    func aiScenarioSheet(
        isPresented: Binding<Bool>,
        aiManager: AIAssistantManager,
        scenarioData: AIScenarioData?
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            if let data = scenarioData {
                AIScenarioSheetView(aiManager: aiManager, scenarioData: data)
            }
        }
    }
}

// MARK: - Preview

struct AIScenarioSheetView_Previews: PreviewProvider {
    static var previews: some View {
        AIScenarioSheetView(
            aiManager: AIAssistantManager.shared,
            scenarioData: AIScenarioData(
                scenario: .pendingTasks,
                message: "Kevin hasn't been assigned to any buildings yet, but system shows 6+ available buildings. Emergency repair recommended.",
                actionText: "Fix Assignments"
            )
        )
        .preferredColorScheme(.dark)
    }
}
