//
//  HeaderV3B.swift - ENHANCED WITH REAL DATA INTEGRATION
//  FrancoSphere
//

import SwiftUI
import CoreLocation

struct HeaderV3B: View {
    let workerName: String
    let clockedInStatus: Bool
    let onClockToggle: () -> Void
    let onProfilePress: () -> Void
    let nextTaskName: String?
    let hasUrgentWork: Bool
    let onNovaPress: () -> Void
    let onNovaLongPress: () -> Void
    let isNovaProcessing: Bool
    let hasPendingScenario: Bool
    let showClockPill: Bool
    
    // 🎯 ENHANCED: Real data integration
    @ObservedObject private var contextEngine = WorkerContextEngine.shared
    
    // Default initializer maintains backward compatibility
    init(
        workerName: String,
        clockedInStatus: Bool,
        onClockToggle: @escaping () -> Void,
        onProfilePress: @escaping () -> Void,
        nextTaskName: String? = nil,
        hasUrgentWork: Bool = false,
        onNovaPress: @escaping () -> Void,
        onNovaLongPress: @escaping () -> Void,
        isNovaProcessing: Bool = false,
        hasPendingScenario: Bool = false,
        showClockPill: Bool = true
    ) {
        self.workerName = workerName
        self.clockedInStatus = clockedInStatus
        self.onClockToggle = onClockToggle
        self.onProfilePress = onProfilePress
        self.nextTaskName = nextTaskName
        self.hasUrgentWork = hasUrgentWork
        self.onNovaPress = onNovaPress
        self.onNovaLongPress = onNovaLongPress
        self.isNovaProcessing = isNovaProcessing
        self.hasPendingScenario = hasPendingScenario
        self.showClockPill = showClockPill
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Row 1: Main header with three sections
            HStack(alignment: .center, spacing: 0) {
                // Left section (36% width) - Worker info
                HStack(alignment: .center, spacing: 8) {
                    Button(action: onProfilePress) {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text(String(workerName.prefix(1)))
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(workerName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if showClockPill {
                            clockStatusPill
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(width: UIScreen.main.bounds.width * 0.36)
                
                // Center section (28% width) - Nova AI
                novaButton
                    .frame(maxWidth: .infinity)
                    .frame(width: UIScreen.main.bounds.width * 0.28)
                
                // Right section (36% width) - Status
                HStack(alignment: .center, spacing: 8) {
                    if hasUrgentWork {
                        urgentWorkIndicator
                    }
                    
                    Spacer()
                    
                    Button(action: onClockToggle) {
                        HStack(spacing: 4) {
                            Image(systemName: clockedInStatus ? "clock.fill" : "clock")
                                .font(.system(size: 12, weight: TaskUrgency.medium))
                            Text(clockedInStatus ? "OUT" : "IN")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(clockedInStatus ? .orange : .green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((clockedInStatus ? Color.orange : .green).opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(width: UIScreen.main.bounds.width * 0.36)
            }
            .frame(height: 28)
            
            // Row 2: Next Task Banner
            if let taskName = nextTaskName {
                nextTaskBanner(taskName)
            } else {
                Spacer()
                    .frame(height: 16)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 0))
        .frame(maxHeight: 80)
    }
    
    // MARK: - Component Views
    
    private var clockStatusPill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(clockedInStatus ? .green : .gray)
                .frame(width: 6, height: 6)
            
            Text(clockedInStatus ? "Clocked In" : "Clocked Out")
                .font(.system(size: 10, weight: TaskUrgency.medium))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(.gray.opacity(0.1))
        )
    }
    
    private var novaButton: some View {
        Button(action: handleEnhancedNovaPress) {
            NovaAvatar(
                size: 32,
                isBusy: isNovaProcessing,
                hasUrgentInsight: hasUrgentWork,
                hasPendingScenario: hasPendingScenario,
                onLongPress: handleEnhancedNovaLongPress
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var urgentWorkIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12, weight: TaskUrgency.medium))
                .foregroundColor(.orange)
            
            Text("Urgent")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
        )
    }
    
    private func nextTaskBanner(_ taskName: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 12, weight: TaskUrgency.medium))
                .foregroundColor(.blue)
            
            Text("Next: \(taskName)")
                .font(.system(size: 11, weight: TaskUrgency.medium))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.1))
        )
        .frame(height: 16)
    }
    
    // MARK: - Enhanced Actions
    
    private func handleEnhancedNovaPress() {
        HapticManager.impact(TaskUrgency.medium)
        onNovaPress()
        generateSmartScenarioWithRealData()
    }
    
    private func handleEnhancedNovaLongPress() {
        HapticManager.impact(.heavy)
        onNovaLongPress()
        generateTaskFocusedScenarioWithRealData()
    }
    
    private func generateSmartScenarioWithRealData() {
        let buildings = contextEngine.getAssignedBuildings()
        let tasks = contextEngine.getTodaysTasks()
        let incompleteTasks = tasks.filter { $0.status != "completed" }
        
        let primaryBuilding = buildings.first?.name ?? "Rubin Museum"
        let taskCount = incompleteTasks.count
        
        print("🤖 Smart scenario: \(taskCount) tasks at \(primaryBuilding)")
    }
    
    private func generateTaskFocusedScenarioWithRealData() {
        let urgentTasks = contextEngine.getUrgentTasks()
        let nextTask = contextEngine.getNextScheduledTask()
        
        print("🎯 Task focus: \(urgentTasks.count) urgent, next: \(nextTask?.title ?? "None")")
    }
}




// MARK: - Preview

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: false,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "HVAC Filter Replacement",
                hasUrgentWork: false,
                onNovaPress: { print("Nova tapped") },
                onNovaLongPress: { print("Nova long pressed") },
                isNovaProcessing: false,
                hasPendingScenario: false
            )
            
            HeaderV3B(
                workerName: "Kevin Dutan",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Sidewalk Sweep at 131 Perry St",
                hasUrgentWork: true,
                onNovaPress: { print("Nova tapped") },
                onNovaLongPress: { print("Nova long pressed") },
                isNovaProcessing: true,
                hasPendingScenario: true
            )
            
            Spacer()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}