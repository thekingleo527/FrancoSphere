//
//  AIAvatarOverlayView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Updated to use only existing AIScenarioType cases
//  ✅ ALIGNED: With canonical definition from AIScenarioSheetView.swift
//  ✅ REMOVED: References to non-existent enum cases
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
                        .opacity(pulseAnimation ? 0.3 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: pulseAnimation
                        )
                }
                
                // Main avatar circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(avatarScale)
                
                // AI icon or scenario indicator
                if let scenarioData = aiManager.currentScenarioData {
                    Image(systemName: iconForScenarioType(scenarioData.scenario))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }
    
    private func speechBubble(for scenarioData: AIScenarioData) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scenarioData.scenario.displayTitle)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(scenarioData.message)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Spacer()
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .frame(maxWidth: 200)
            
            // Small triangle pointer
            Triangle()
                .fill(.ultraThinMaterial)
                .frame(width: 12, height: 8)
                .offset(x: -8)
        }
    }
    
    // ✅ FIXED: Updated to use only existing AIScenarioType cases
    private func iconForScenarioType(_ type: AIScenarioType) -> String {
        switch type {
        case .routineIncomplete: return "checklist"
        case .pendingTasks: return "list.bullet.rectangle"
        case .clockOutReminder: return "clock.badge.checkmark.fill"
        case .weatherAlert: return "cloud.sun.fill"
        case .inventoryLow: return "shippingbox.circle.fill"
        case .emergencyRepair: return "exclamationmark.triangle.fill"
        case .taskOverdue: return "clock.badge.xmark.fill"
        case .buildingAlert: return "building.2.circle.fill"
        }
    }
    
    // ✅ FIXED: Updated to use only existing AIScenarioType cases
    private func colorForScenarioType(_ type: AIScenarioType) -> Color {
        switch type {
        case .routineIncomplete: return .orange
        case .pendingTasks: return .blue
        case .clockOutReminder: return .red
        case .weatherAlert: return .yellow
        case .inventoryLow: return .orange
        case .emergencyRepair: return .red
        case .taskOverdue: return .red
        case .buildingAlert: return .orange
        }
    }
}

// MARK: - Supporting Views

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
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
