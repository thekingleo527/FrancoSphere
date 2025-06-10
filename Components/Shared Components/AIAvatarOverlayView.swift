//
//  AIAvatarOverlayView.swift
//  FrancoSphere
//
//  Fixed version - removed duplicate AIScenario and GlassButton references
//

import SwiftUI

struct AIAvatarOverlayView: View {
    @StateObject private var aiManager = AIAssistantManager.shared
    @State private var isExpanded = false
    @State private var avatarScale: CGFloat = 1.0
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Speech bubble (if scenario exists)
                    if let scenario = aiManager.currentScenario, isExpanded {
                        speechBubble(for: scenario)
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                    }
                    
                    // AI Avatar
                    novaAvatar
                }
                .padding(.trailing, 20)
            }
            Spacer()
        }
        .onReceive(aiManager.$currentScenario) { scenario in
            if scenario != nil {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isExpanded = true
                    avatarScale = 1.1
                }
                
                // Auto-collapse after 10 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    withAnimation(.spring()) {
                        isExpanded = false
                        avatarScale = 1.0
                    }
                }
            }
        }
    }
    
    private var novaAvatar: some View {
        Button(action: {
            if aiManager.currentScenario != nil {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
        }) {
            ZStack {
                // Outer glow ring (when active)
                if aiManager.hasActiveScenarios {
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                        .frame(width: 75, height: 75)
                        .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                        .opacity(pulseAnimation ? 0.0 : 1.0)
                        .animation(
                            .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                            value: pulseAnimation
                        )
                }
                
                // Main avatar circle
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
                
                // Nova icon
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
                                    Text("\(aiManager.scenarioQueue.count + (aiManager.currentScenario != nil ? 1 : 0))")
                                        .font(.caption2)
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
    
    private func speechBubble(for scenario: FrancoSphere.AIScenario) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: scenario.icon)
                    .font(.title2)
                    .foregroundColor(iconColor(for: scenario))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(scenario.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text("Nova AI Assistant")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        aiManager.dismissCurrentScenario()
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            // Message
            Text(scenario.message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // Action button - Using standard Button instead of GlassButton
            Button(action: {
                aiManager.performAction()
                withAnimation(.spring()) {
                    isExpanded = false
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: actionIcon(for: scenario))
                        .font(.subheadline)
                    Text(scenario.actionText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
        }
        .padding(20)
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
    
    // Helper functions
    private func iconColor(for scenario: FrancoSphere.AIScenario) -> Color {
        switch scenario {
        case .routineIncomplete: return .orange
        case .pendingTasks: return .blue
        case .missingPhoto: return .purple
        case .clockOutReminder: return .red
        case .weatherAlert: return .yellow
        case .buildingArrival: return .green
        case .taskCompletion: return .green
        case .inventoryLow: return .orange
        }
    }
    
    private func actionIcon(for scenario: FrancoSphere.AIScenario) -> String {
        switch scenario {
        case .routineIncomplete: return "checklist"
        case .pendingTasks: return "list.bullet.rectangle"
        case .missingPhoto: return "camera.fill"
        case .clockOutReminder: return "clock.badge.checkmark.fill"
        case .weatherAlert: return "cloud.sun.fill"
        case .buildingArrival: return "building.2.circle.fill"
        case .taskCompletion: return "checkmark.circle.fill"
        case .inventoryLow: return "shippingbox.circle.fill"
        }
    }
}

// MARK: - Preview
struct AIAvatarOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AIAvatarOverlayView()
        }
    }
}
