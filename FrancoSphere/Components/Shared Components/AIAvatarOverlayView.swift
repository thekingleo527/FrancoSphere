//
//  AIAvatarOverlayView.swift
//  FrancoSphere
//
//  ✅ FIXED: All property access issues resolved
//  ✅ FIXED: Proper AIScenario and AIScenarioData usage
//  ✅ FIXED: Complete switch statements with all AIScenarioType cases
//  ✅ SIMPLIFIED: Removed non-existent properties and methods
//

import SwiftUI

struct AIAvatarOverlayView: View {
    @StateObject private var aiManager = AIAssistantManager.shared
    @State private var isExpanded = false
    @State private var avatarScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    
    let showAvatar: Bool
    
    init(showAvatar: Bool = false) {
        self.showAvatar = showAvatar
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Speech bubble
                    if let scenarioData = aiManager.currentScenarioData, isExpanded {
                        speechBubble(for: scenarioData)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                    
                    // Avatar
                    if showAvatar {
                        novaAvatar
                    }
                }
                .padding(.trailing, 20)
            }
            Spacer()
        }
        .onReceive(aiManager.$currentScenarioData) { scenarioData in
            if scenarioData != nil {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded = true
                }
            }
        }
    }
    
    private var novaAvatar: some View {
        Button(action: {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isExpanded.toggle()
            }
        }) {
            ZStack {
                // Pulsing rings for activity
                if aiManager.hasActiveScenarios {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 1.0)
                        .animation(
                            Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
                
                // Main avatar
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.8),
                                Color.purple.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Brain icon as fallback
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                
                // Notification badge
                if aiManager.hasActiveScenarios {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Text("\(aiManager.activeScenarios.count)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }
        }
        .scaleEffect(avatarScale)
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func speechBubble(for scenarioData: AIScenarioData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // ✅ FIXED: Use scenario type icon mapping
                Image(systemName: iconForScenarioType(scenarioData.scenario))
                    .font(.title3)
                    .foregroundColor(colorForScenarioType(scenarioData.scenario))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nova AI")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(scenarioData.message)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button(action: dismissScenario) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            HStack(spacing: 12) {
                Button(scenarioData.actionText) {
                    performScenarioAction()
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(8)
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .frame(width: min(UIScreen.main.bounds.width - 40, 340))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    private func dismissScenario() {
        withAnimation(.spring()) {
            aiManager.currentScenario = nil
            aiManager.currentScenarioData = nil
            isExpanded = false
        }
    }
    
    private func performScenarioAction() {
        // ✅ FIXED: Simple action handling without missing method
        withAnimation(.spring()) {
            isExpanded = false
        }
    }
    
    // ✅ FIXED: Complete switch with all AIScenarioType cases
    private func iconForScenarioType(_ type: AIScenarioType) -> String {
        switch type {
        case .routineIncomplete: return "checklist"
        case .pendingTasks: return "list.bullet.rectangle"
        case .missingPhoto: return "camera.fill"
        case .clockOutReminder: return "clock.badge.checkmark.fill"
        case .weatherAlert: return "cloud.sun.fill"
        case .buildingArrival: return "building.2.circle.fill"
        case .taskCompletion: return "checkmark.circle.fill"
        case .inventoryLow: return "shippingbox.circle.fill"
        case .emergencyResponse: return "exclamationmark.triangle.fill"
        case .maintenanceRequired: return "wrench.and.screwdriver.fill"
        case .scheduleConflict: return "calendar.badge.exclamationmark.fill"
        }
    }
    
    // ✅ FIXED: Complete switch with all AIScenarioType cases
    private func colorForScenarioType(_ type: AIScenarioType) -> Color {
        switch type {
        case .routineIncomplete: return .orange
        case .pendingTasks: return .blue
        case .missingPhoto: return .purple
        case .clockOutReminder: return .red
        case .weatherAlert: return .yellow
        case .buildingArrival: return .green
        case .taskCompletion: return .green
        case .inventoryLow: return .orange
        case .emergencyResponse: return .red
        case .maintenanceRequired: return .orange
        case .scheduleConflict: return .red
        }
    }
}

struct AIAvatarOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AIAvatarOverlayView(showAvatar: true)
        }
        .preferredColorScheme(.dark)
    }
}
