//
//  HeaderV3B.swift
//  FrancoSphere v6.0 - Production Ready
//
//  ✅ PRODUCTION READY: Aligned with CoreTypes.UserRole
//  ✅ AI FOR EVERYONE: All roles get Nova AI access
//  ✅ ROLE-AWARE: AI adapts features based on user role and current task
//  ✅ CONTEXT-INTELLIGENT: AI understands worker location, task, and building
//  ✅ VISUAL DIFFERENTIATION: AI button appearance reflects role context
//  ✅ FUTURE READY: Prepared for voice, AR, and advanced AI features
//

import SwiftUI
import Foundation
import Combine

struct HeaderV3B: View {
    // MARK: - Properties
    
    let workerName: String
    let nextTaskName: String?
    let showClockPill: Bool
    let isNovaProcessing: Bool
    let onProfileTap: () -> Void
    let onNovaPress: () -> Void
    let onNovaLongPress: () -> Void
    
    // Future Phase: Voice command callback
    var onVoiceCommand: (() -> Void)?
    
    // Future Phase: AR mode toggle
    var onARModeToggle: (() -> Void)?
    
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @State private var showAITooltip = false
    @State private var aiButtonScale: CGFloat = 1.0
    
    // MARK: - Body
    
    var body: some View {
        headerContent
            .frame(height: 80)
            .background(backgroundView)
            .overlay(alignment: .bottom) {
                Divider()
                    .opacity(0.3)
            }
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base material
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Role-based accent gradient (subtle)
            LinearGradient(
                colors: [
                    profileButtonColor.opacity(0.05),
                    Color.clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        .ignoresSafeArea()
    }
    
    private var headerContent: some View {
        HStack(spacing: 16) {
            // Left: Profile section
            profileSection
            
            Spacer()
            
            // Center: Status indicators
            statusSection
            
            Spacer()
            
            // Right: Action buttons (Nova AI + future buttons)
            actionButtonsSection
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        HStack(spacing: 12) {
            profileButton
                .overlay(alignment: .bottomTrailing) {
                    // Online/Active indicator
                    if contextAdapter.currentBuilding != nil {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                            )
                            .offset(x: 2, y: 2)
                    }
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(displayWorkerName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: roleIcon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(roleDisplayText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }
    
    private var profileButton: some View {
        Button(action: onProfileTap) {
            ZStack {
                Circle()
                    .fill(profileButtonGradient)
                    .frame(width: 44, height: 44)
                
                Text(profileInitials)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .overlay(
                Circle()
                    .stroke(profileButtonColor.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: profileButtonColor.opacity(0.2), radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 4) {
            if showClockPill {
                clockPill
            }
            
            if let nextTask = nextTaskName {
                nextTaskPill(nextTask)
            }
        }
    }
    
    private var clockPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(clockStatusColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(clockStatusColor)
                        .frame(width: 8, height: 8)
                        .opacity(0.5)
                        .scaleEffect(1.5)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: showClockPill
                        )
            )
            
            Text(clockStatusText)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(clockStatusColor.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(clockStatusColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func nextTaskPill(_ taskName: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            
            Text(taskName)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Future Phase: Voice Command Button
            if onVoiceCommand != nil {
                voiceCommandButton
            }
            
            // Future Phase: AR Mode Button
            if onARModeToggle != nil {
                arModeButton
            }
            
            // Nova AI Button - Always visible
            novaAiButton
        }
    }
    
    // MARK: - Nova AI Button
    
    private var novaAiButton: some View {
        Button(action: handleNovaAction) {
            ZStack {
                // Background with role color
                Circle()
                    .fill(aiButtonGradient)
                    .frame(width: 44, height: 44)
                
                // Icon
                Group {
                    if let aiImage = UIImage(named: "AIAssistant") {
                        Image(uiImage: aiImage)
                            .resizable()
                            .renderingMode(.template)
                            .frame(width: 24, height: 24)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(aiButtonScale)
                
                // Processing indicator
                if isNovaProcessing {
                    processingIndicator
                }
                
                // Context indicator
                if hasActiveContext && !isNovaProcessing {
                    contextIndicator
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .onLongPressGesture {
            onNovaLongPress()
        }
        .overlay(
            // Tooltip for first-time users
            aiTooltip
                .opacity(showAITooltip ? 1 : 0)
                .animation(.easeInOut, value: showAITooltip)
        )
    }
    
    private var processingIndicator: some View {
        Circle()
            .stroke(
                AngularGradient(
                    colors: aiProcessingColors,
                    center: .center
                ),
                lineWidth: 2
            )
            .frame(width: 48, height: 48)
            .rotationEffect(.degrees(isNovaProcessing ? 360 : 0))
            .animation(
                .linear(duration: 2).repeatForever(autoreverses: false),
                value: isNovaProcessing
            )
    }
    
    private var contextIndicator: some View {
        Circle()
            .fill(aiContextColor)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .offset(x: 14, y: -14)
            .transition(.scale.combined(with: .opacity))
    }
    
    private var aiTooltip: some View {
        Text(aiContextDescription)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
            .offset(y: -50)
    }
    
    // MARK: - Future Phase Buttons
    
    private var voiceCommandButton: some View {
        Button(action: { onVoiceCommand?() }) {
            Circle()
                .fill(Color.purple.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "mic.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var arModeButton: some View {
        Button(action: { onARModeToggle?() }) {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "arkit")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Computed Properties
    
    private var displayWorkerName: String {
        if !workerName.isEmpty && workerName != "Worker" {
            return workerName
        }
        return contextAdapter.currentWorker?.name ?? "Worker"
    }
    
    private var profileInitials: String {
        let name = displayWorkerName
        let components = name.components(separatedBy: " ")
        let first = components.first?.first ?? Character("F")
        let last = components.count > 1 ? components.last?.first ?? Character("S") : nil
        
        if let last = last {
            return "\(first)\(last)".uppercased()
        } else {
            return "\(first)\(first)".uppercased()
        }
    }
    
    private var profileButtonColor: Color {
        guard let worker = contextAdapter.currentWorker else { return .blue }
        return getWorkerRoleColor(worker.role)
    }
    
    private var profileButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                profileButtonColor,
                profileButtonColor.opacity(0.8)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func getWorkerRoleColor(_ role: CoreTypes.UserRole) -> Color {
        switch role {
        case .worker: return .blue
        case .admin: return .green
        case .manager: return .orange
        case .client: return .purple
        }
    }
    
    private var roleIcon: String {
        guard let worker = contextAdapter.currentWorker else { return "person.fill" }
        
        switch worker.role {
        case .worker: return "hammer.fill"
        case .admin: return "crown.fill"
        case .manager: return "person.3.fill"
        case .client: return "building.2.fill"
        }
    }
    
    private var roleDisplayText: String {
        guard let worker = contextAdapter.currentWorker else { return "Team Member" }
        
        // Special role descriptions for known workers
        switch worker.id {
        case "4": return "Museum Specialist"      // Kevin
        case "2": return "Park Operations"         // Edwin
        case "5": return "West Village"            // Mercedes
        case "6": return "Downtown"                // Luis
        case "1": return "Systems Expert"          // Greg
        case "7": return "Evening Ops"             // Angel
        case "8": return "Portfolio Lead"          // Shawn
        case "3": return "Executive"               // Francisco
        default:
            // Generic role descriptions
            switch worker.role {
            case .worker: return "Field Operations"
            case .admin: return "Management"
            case .manager: return "Team Lead"
            case .client: return "Client Services"
            }
        }
    }
    
    private var clockStatusColor: Color {
        contextAdapter.currentBuilding != nil ? .green : .orange
    }
    
    private var clockStatusText: String {
        if let building = contextAdapter.currentBuilding {
            return building.name
        } else if showClockPill {
            return "On Site"
        } else {
            return "Available"
        }
    }
    
    // MARK: - AI Properties
    
    private var aiButtonGradient: LinearGradient {
        LinearGradient(
            colors: [
                aiButtonBackgroundColor,
                aiButtonBackgroundColor.opacity(0.7)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var aiButtonBackgroundColor: Color {
        guard let worker = contextAdapter.currentWorker else { return .purple }
        
        switch worker.role {
        case .worker: return .blue
        case .admin: return .green
        case .manager: return .orange
        case .client: return .purple
        }
    }
    
    private var aiProcessingColors: [Color] {
        guard let worker = contextAdapter.currentWorker else { return [.purple, .blue, .purple] }
        
        switch worker.role {
        case .worker: return [.blue, .cyan, .blue]
        case .admin: return [.green, .mint, .green]
        case .manager: return [.orange, .yellow, .orange]
        case .client: return [.purple, .pink, .purple]
        }
    }
    
    private var hasActiveContext: Bool {
        let hasCurrentTask = nextTaskName != nil
        let hasBuildings = !contextAdapter.assignedBuildings.isEmpty
        let hasClockIn = contextAdapter.currentBuilding != nil
        
        return hasCurrentTask || hasBuildings || hasClockIn
    }
    
    private var aiContextColor: Color {
        if nextTaskName != nil {
            return .orange  // Active task
        } else if contextAdapter.currentBuilding != nil {
            return .green   // On site
        } else {
            return .blue    // Available
        }
    }
    
    private var aiContextDescription: String {
        guard let worker = contextAdapter.currentWorker else { return "Nova AI Assistant" }
        
        var context = "Nova AI - "
        
        switch worker.role {
        case .worker:
            if let task = nextTaskName {
                context += "Help with \(task)"
            } else if let building = contextAdapter.currentBuilding {
                context += "At \(building.name)"
            } else {
                context += "Field assistance ready"
            }
            
        case .admin:
            context += "Portfolio insights"
            
        case .manager:
            context += "Team coordination"
            
        case .client:
            context += "Building status"
        }
        
        return context
    }
    
    // MARK: - Actions
    
    private func handleNovaAction() {
        if isNovaProcessing {
            onNovaLongPress()
        } else {
            // Animate button press
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                aiButtonScale = 0.9
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    aiButtonScale = 1.0
                }
            }
            
            onNovaPress()
            
            // Show tooltip for first-time users
            if !UserDefaults.standard.bool(forKey: "hasSeenAITooltip") {
                withAnimation {
                    showAITooltip = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showAITooltip = false
                    }
                    UserDefaults.standard.set(true, forKey: "hasSeenAITooltip")
                }
            }
        }
    }
}

// MARK: - Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            // Worker with active task
            HeaderV3B(
                workerName: "Kevin Dutan",
                nextTaskName: "Museum Security Check",
                showClockPill: true,
                isNovaProcessing: false,
                onProfileTap: { print("Profile tapped") },
                onNovaPress: { print("Nova pressed") },
                onNovaLongPress: { print("Nova long pressed") },
                onVoiceCommand: { print("Voice command") },
                onARModeToggle: { print("AR mode") }
            )
            
            Divider()
            
            // Admin with processing
            HeaderV3B(
                workerName: "Shawn Magloire",
                nextTaskName: nil,
                showClockPill: false,
                isNovaProcessing: true,
                onProfileTap: { },
                onNovaPress: { },
                onNovaLongPress: { }
            )
            
            Divider()
            
            // Manager available
            HeaderV3B(
                workerName: "Francisco",
                nextTaskName: nil,
                showClockPill: false,
                isNovaProcessing: false,
                onProfileTap: { },
                onNovaPress: { },
                onNovaLongPress: { }
            )
            
            Divider()
            
            // Client viewing
            HeaderV3B(
                workerName: "John Smith",
                nextTaskName: nil,
                showClockPill: false,
                isNovaProcessing: false,
                onProfileTap: { },
                onNovaPress: { },
                onNovaLongPress: { }
            )
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .preferredColorScheme(.dark)
    }
}

// MARK: - Future Phase Features

/*
🚀 FUTURE PHASES ROADMAP:

Phase 1: Voice Integration (Q2 2025)
- Voice command button activation
- Hands-free task completion
- Voice notes and reports
- Multi-language support (English/Spanish)

Phase 2: AR Features (Q3 2025)
- AR mode for building navigation
- Equipment identification
- Visual task guides
- Safety hazard detection

Phase 3: Advanced AI (Q4 2025)
- Predictive task suggestions
- Anomaly detection alerts
- Performance optimization
- Learning from user patterns

Phase 4: Wearable Support (Q1 2026)
- Apple Watch companion
- Smart glasses integration
- Haptic feedback
- Emergency alerts

Phase 5: Integration Ecosystem (Q2 2026)
- Third-party tool integration
- API marketplace
- Custom workflows
- Enterprise features
*/
