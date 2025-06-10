//
//  AIAvatarOverlayView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//

import SwiftUI

struct AIAvatarOverlayView: View {
    @ObservedObject private var aiManager = AIAssistantManager.shared
    @State private var isExpanded = false
    @State private var isPulsing = false
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    // Glass speech bubble when expanded
                    if isExpanded, let scenario = aiManager.currentScenario {
                        glassAssistantBubble(for: scenario)
                            .offset(y: -140)
                            .offset(dragOffset)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 0.8, anchor: .bottomTrailing)
                                        .combined(with: .opacity),
                                    removal: .scale(scale: 0.8, anchor: .bottomTrailing)
                                        .combined(with: .opacity)
                                )
                            )
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation
                                    }
                                    .onEnded { value in
                                        if abs(value.translation.width) > 100 ||
                                           abs(value.translation.height) > 100 {
                                            withAnimation(.spring()) {
                                                isExpanded = false
                                                aiManager.dismissCurrentScenario()
                                            }
                                        } else {
                                            withAnimation(.spring()) {
                                                dragOffset = .zero
                                            }
                                        }
                                    }
                            )
                    }
                    
                    // Glass avatar button
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            // Pulsing glass ring for notifications
                            if aiManager.currentScenario != nil, !isExpanded {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.blue.opacity(0.3),
                                                Color.blue.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(
                                        width: isPulsing ? 75 : 65,
                                        height: isPulsing ? 75 : 65
                                    )
                                    .blur(radius: isPulsing ? 2 : 0)
                                    .animation(
                                        Animation
                                            .easeInOut(duration: 1.5)
                                            .repeatForever(autoreverses: true),
                                        value: isPulsing
                                    )
                            }
                            
                            // Glass avatar circle
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.3),
                                                    Color.blue.opacity(0.1)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                                .overlay(
                                    Image(systemName: "bubble.left.and.bubble.right.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .shadow(radius: 2)
                                )
                        }
                        .scaleEffect(isExpanded ? 0.9 : 1.0)
                    }
                    .onAppear {
                        isPulsing = true
                    }
                }
                .padding(.bottom, 100) // Account for tab bar
                .padding(.trailing, 20)
            }
        }
        .animation(.spring(), value: isExpanded)
        .zIndex(100)
    }
    
    // Glass-styled speech bubble
    @ViewBuilder
    private func glassAssistantBubble(for scenario: AIScenario) -> some View {
        GlassCard(intensity: .regular, cornerRadius: 20, hasGlow: true, glowColor: .blue) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    // Avatar icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("FrancoSphere Assistant")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(scenario.title)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Dismiss button
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded = false
                            aiManager.dismissCurrentScenario()
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Message with icon
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: scenario.icon)
                        .font(.title2)
                        .foregroundColor(iconColor(for: scenario))
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(iconColor(for: scenario).opacity(0.15))
                        )
                    
                    Text(scenario.message)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Action button
                GlassButton(
                    actionText(for: scenario),
                    style: .primary,
                    size: .medium,
                    isFullWidth: true,
                    icon: actionIcon(for: scenario)
                ) {
                    aiManager.performAction()
                    withAnimation(.spring()) {
                        isExpanded = false
                    }
                }
            }
        }
        .frame(width: min(UIScreen.main.bounds.width - 40, 340))
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
    
    // Helper functions
    private func iconColor(for scenario: AIScenario) -> Color {
        switch scenario {
        case .routineIncomplete: return .orange
        case .pendingTasks: return .blue
        case .missingPhoto: return .purple
        case .clockOutReminder: return .red
        case .weatherAlert: return .yellow
        default: return .blue // Handle any additional cases
        }
    }
    
    private func actionIcon(for scenario: AIScenario) -> String {
        switch scenario {
        case .routineIncomplete: return "checklist"
        case .pendingTasks: return "list.bullet.rectangle"
        case .missingPhoto: return "camera.fill"
        case .clockOutReminder: return "clock.badge.checkmark.fill"
        case .weatherAlert: return "cloud.sun.fill"
        default: return "checkmark.circle.fill" // Handle any additional cases
        }
    }
    
    private func actionText(for scenario: AIScenario) -> String {
        switch scenario {
        case .routineIncomplete: return "View Tasks"
        case .pendingTasks: return "Check Tasks"
        case .missingPhoto: return "Take Photo"
        case .clockOutReminder: return "Clock Out"
        case .weatherAlert: return "View Weather"
        default: return "Continue" // Handle any additional cases
        }
    }
}

// MARK: - Preview Provider
struct AIAvatarOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            AIAvatarOverlayView()
        }
        .preferredColorScheme(.dark)
    }
}
