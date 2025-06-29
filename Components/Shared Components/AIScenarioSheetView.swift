//
//  AIScenarioSheetView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/29/25.
//


//
//  AIScenarioSheet.swift
//  FrancoSphere
//
//  ✅ AI Scenario Sheet View for displaying AI assistant scenarios
//  ✅ Compatible with existing AIAssistantManager framework
//  ✅ Supports scenario actions and dismissal
//

import SwiftUI

struct AIScenarioSheetView: View {
    @StateObject private var aiManager = AIAssistantManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let scenarioData = aiManager.currentScenarioData {
                    // Active scenario content
                    activeScenarioContent(scenarioData)
                } else {
                    // Default AI assistant content
                    defaultAIContent
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("Nova AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .overlay(
                // Custom close button
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(8)
                                .background(.ultraThinMaterial, in: Circle())
                        }
                    }
                    .padding()
                    Spacer()
                }
            )
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Active Scenario Content
    
    @ViewBuilder
    private func activeScenarioContent(_ scenarioData: AIScenarioData) -> some View {
        VStack(spacing: 24) {
            // AI Avatar
            aiAvatarView
            
            // Scenario icon and title
            VStack(spacing: 16) {
                Image(systemName: scenarioData.icon)
                    .font(.system(size: 48))
                    .foregroundColor(iconColor(for: scenarioData.scenario))
                
                Text(scenarioData.title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            
            // Scenario message
            Text(scenarioData.message)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // AI suggestions if available
            if !aiManager.aiSuggestions.isEmpty {
                aiSuggestionsView
            }
            
            // Action buttons
            HStack(spacing: 16) {
                Button("Dismiss") {
                    aiManager.dismissCurrentScenario()
                    dismiss()
                }
                .buttonStyle(SecondaryGlassButtonStyle())
                
                Button(scenarioData.actionText) {
                    aiManager.performAction()
                    dismiss()
                }
                .buttonStyle(PrimaryGlassButtonStyle())
            }
            .padding(.top)
        }
    }
    
    // MARK: - Default AI Content
    
    private var defaultAIContent: some View {
        VStack(spacing: 24) {
            // AI Avatar
            aiAvatarView
            
            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Nova AI Assistant")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            Text("I'm here to help with your tasks and building management.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Quick actions
            VStack(spacing: 12) {
                quickActionButton(
                    icon: "list.bullet.clipboard",
                    title: "View Today's Tasks",
                    action: {
                        // Handle action
                        dismiss()
                    }
                )
                
                quickActionButton(
                    icon: "building.2",
                    title: "Check Buildings",
                    action: {
                        // Handle action
                        dismiss()
                    }
                )
                
                quickActionButton(
                    icon: "cloud.sun",
                    title: "Weather Update",
                    action: {
                        // Handle action
                        dismiss()
                    }
                )
            }
            .padding(.top)
        }
    }
    
    // MARK: - AI Avatar View
    
    private var aiAvatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
            
            if let avatarImage = aiManager.avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
            } else {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - AI Suggestions View
    
    private var aiSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggestions")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(aiManager.aiSuggestions.prefix(3)) { suggestion in
                HStack(spacing: 12) {
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 16))
                        .foregroundColor(suggestion.priority.color)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.white)
                        
                        Text(suggestion.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func iconColor(for scenario: FrancoSphere.AIScenario) -> Color {
        switch scenario {
        case .weatherAlert: return .orange
        case .routineIncomplete: return .yellow
        case .pendingTasks: return .blue
        case .taskCompletion: return .green
        case .buildingArrival: return .purple
        case .clockOutReminder: return .red
        case .missingPhoto: return .pink
        case .inventoryLow: return .brown
        }
    }
    
    private func quickActionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Button Styles

struct PrimaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}