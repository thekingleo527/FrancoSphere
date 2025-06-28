//
//  HeaderV3B.swift - ENHANCED WITH REAL DATA INTEGRATION
//  FrancoSphere
//
//  🔴 P0-c: Fixed Nova centering for narrow screens (<340pt) - PRESERVED
//  ✅ Reduced center width from 0.30 to 0.28 (per mobile team guidance) - PRESERVED
//  ✅ Increased side widths to 0.36 each for better balance - PRESERVED
//  🎯 HF-31: ENHANCED with real data integration for AI scenarios
//  ✅ Uses WorkerContextEngine for real building names and task counts
//  ✅ Smart scenario generation based on actual worker context
//  ✅ Preserves all existing advanced features
//

import SwiftUI

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
        showClockPill: Bool = false
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
        VStack(spacing: 6) {
            // Row 1: Brand + Worker + Profile (18pt)
            GeometryReader { geometry in
                // 🔴 P0-c: Nova Centering Fix (from guidance) - PRESERVED
                // OLD: centerWidth = 0.30, sideWidth = 0.35
                // NEW: centerWidth = 0.28, sideWidth = 0.36 (better balance at narrow widths)
                let centerWidth = geometry.size.width * 0.28
                let sideWidth = geometry.size.width * 0.36
                
                HStack(spacing: 0) {
                    // Left: Brand + Optional Clock Pill (36%)
                    HStack(spacing: 12) {
                        Text("FrancoSphere")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 80, alignment: .leading)
                        
                        if showClockPill {
                            clockPillButton
                        }
                        
                        Spacer()
                    }
                    .frame(width: sideWidth, alignment: .leading)
                    
                    // Center: Worker Name (28% - REDUCED for better Nova fit)
                    Text(workerName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(width: centerWidth)
                        .multilineTextAlignment(.center)
                    
                    // Right: Profile + Nova (36% - INCREASED for more space)
                    HStack(spacing: 8) {
                        Spacer()
                        
                        ProfileBadge(
                            workerName: workerName,
                            isCompact: true,
                            onTap: onProfilePress,
                            accentColor: .teal
                        )
                        
                        // 🎯 ENHANCED: Context-based Nova Avatar with real data
                        ContextualNovaAvatar(
                            size: 24,
                            hasUrgentInsight: hasUrgentWork,
                            isBusy: isNovaProcessing,
                            hasPendingScenario: hasPendingScenario,
                            onTap: handleEnhancedNovaPress,
                            onLongPress: handleEnhancedNovaLongPress
                        )
                    }
                    .frame(width: sideWidth, alignment: .trailing)
                }
            }
            .frame(height: 28)
            
            // Row 3: Next Task Banner (16pt)
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
    
    // MARK: - 🎯 ENHANCED: AI Integration Methods with Real Data
    
    private func handleEnhancedNovaPress() {
        HapticManager.impact(.medium)
        print("🤖 Nova tapped in header with REAL data integration")
        
        // Call the provided handler (maintains existing integration)
        onNovaPress()
        
        // 🎯 CRITICAL FIX: Generate scenario with real data from WorkerContextEngine
        generateSmartScenarioWithRealData()
    }
    
    private func handleEnhancedNovaLongPress() {
        HapticManager.impact(.heavy)
        print("🎤 Nova long press with REAL data integration")
        
        // Call the provided handler
        onNovaLongPress()
        
        // 🎯 CRITICAL FIX: Generate task-focused scenario with real data
        generateTaskFocusedScenarioWithRealData()
    }
    
    /// 🎯 NEW: Smart scenario generation using real WorkerContextEngine data
    private func generateSmartScenarioWithRealData() {
        let buildings = contextEngine.getAssignedBuildings()
        let tasks = contextEngine.getTodaysTasks()
        let incompleteTasks = tasks.filter { $0.status != "completed" }
        
        // Determine the most relevant building and task count
        let primaryBuilding = buildings.first?.name ?? getCurrentBuildingForWorker()
        let routineTaskCount = incompleteTasks.filter { task in
            task.recurrence.contains("Daily") || task.name.lowercased().contains("routine")
        }.count
        
        print("🤖 Smart scenario: \(routineTaskCount) routine tasks at \(primaryBuilding)")
        
        if routineTaskCount > 0 {
            AIAssistantManager.shared.addScenario(.routineIncomplete,
                                                buildingName: primaryBuilding,
                                                taskCount: routineTaskCount)
        } else {
            // Generate completion scenario
            AIAssistantManager.shared.addScenario(.taskCompletion,
                                                buildingName: primaryBuilding,
                                                taskCount: tasks.filter { $0.status == "completed" }.count)
        }
    }
    
    /// 🎯 NEW: Task-focused scenario generation with real data
    private func generateTaskFocusedScenarioWithRealData() {
        let tasks = contextEngine.getTodaysTasks()
        let pendingTasks = tasks.filter { $0.status != "completed" }
        
        // Find building with most pending tasks
        let tasksByBuilding = Dictionary(grouping: pendingTasks) { $0.buildingName }
        let busiestBuilding = tasksByBuilding.max { $0.value.count < $1.value.count }
        
        let buildingName = busiestBuilding?.key ?? getCurrentBuildingForWorker()
        let taskCount = busiestBuilding?.value.count ?? pendingTasks.count
        
        print("🎤 Voice scenario: \(taskCount) pending tasks at \(buildingName)")
        
        AIAssistantManager.shared.addScenario(.pendingTasks,
                                            buildingName: buildingName,
                                            taskCount: taskCount)
    }
    
    /// 🎯 NEW: Get current building for worker based on their role
    private func getCurrentBuildingForWorker() -> String {
        let workerId = contextEngine.getWorkerId()
        
        // Worker-specific primary buildings
        switch workerId {
        case "1": return "12 West 18th Street"      // Greg Hutson
        case "2": return "Stuyvesant Cove Park"     // Edwin Lema
        case "4": return "131 Perry Street"         // Kevin Dutan (primary)
        case "5": return "112 West 18th Street"     // Mercedes Inamagua
        case "6": return "117 West 17th Street"     // Luis Lopez
        case "7": return "136 West 17th Street"     // Angel Guirachocha
        case "8": return "Rubin Museum"             // Shawn Magloire
        default: return "your assigned building"
        }
    }
    
    // MARK: - UI Components (PRESERVED from original)
    
    private var clockPillButton: some View {
        Button(action: onClockToggle) {
            HStack(spacing: 6) {
                Image(systemName: clockedInStatus ? "location.fill" : "location")
                    .font(.system(size: 10))
                
                Text(clockedInStatus ? "Clock Out" : "Clock In")
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(clockedInStatus ? .white : .blue)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(clockedInStatus ? Color.green : Color.white.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(clockedInStatus ? Color.green : Color.blue, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func nextTaskBanner(_ taskName: String) -> some View {
        HStack {
            Image(systemName: hasUrgentWork ? "exclamationmark.triangle.fill" : "clock")
                .font(.system(size: 12))
                .foregroundColor(hasUrgentWork ? .orange : .blue)
            
            Text("Next: \(taskName)")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
        }
        .frame(height: 16)
    }
}

// MARK: - Context-Based Nova Avatar Component (PRESERVED but enhanced)

struct ContextualNovaAvatar: View {
    let size: CGFloat
    let hasUrgentInsight: Bool
    let isBusy: Bool
    let hasPendingScenario: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    @State private var breathe: Bool = false
    @State private var rotationAngle: Double = 0
    
    // 🟡 P2-a: Context-based glow colors (from guidance) - PRESERVED
    private var contextColor: Color {
        if hasUrgentInsight { return .red }      // Urgent work = red
        if hasPendingScenario { return .orange } // Pending scenarios = orange
        if isBusy { return .purple }             // Processing = purple
        return .blue                             // Default = blue
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Context-based glow effect
                if isBusy || hasUrgentInsight || hasPendingScenario {
                    Circle()
                        .stroke(contextColor.opacity(0.6), lineWidth: 2)
                        .frame(width: size + 6, height: size + 6)
                        .scaleEffect(breathe ? 1.1 : 1.0)
                        .opacity(breathe ? 0.3 : 0.8)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: breathe)
                }
                
                // Main avatar
                avatarView
                    .frame(width: size, height: size)
                    .scaleEffect(breathe ? 1.02 : 1.0)
                    .rotationEffect(.degrees(isBusy ? rotationAngle : 0))
                    .onAppear {
                        startAnimations()
                    }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onLongPress()
        }
    }
    
    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [contextColor.opacity(0.8), contextColor.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            
            statusIndicator
        }
    }
    
    private var statusIndicator: some View {
        ZStack {
            Circle()
                .fill(contextColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 1)
                )
            
            Image(systemName: iconForState)
                .font(.system(size: 6, weight: .bold))
                .foregroundColor(.white)
        }
        .scaleEffect(breathe ? 1.1 : 0.9)
    }
    
    private var iconForState: String {
        if hasUrgentInsight { return "exclamationmark" }
        if hasPendingScenario { return "bell.fill" }
        if isBusy { return "gearshape.fill" }
        return "brain"
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breathe = true
        }
        
        if isBusy {
            withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
        }
    }
}

// MARK: - Preview (ENHANCED with real data scenarios)

struct HeaderV3B_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal state (no clock pill)
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: false,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "HVAC Filter Replacement",
                hasUrgentWork: false,
                onNovaPress: { print("Nova tapped with real data") },
                onNovaLongPress: { print("Nova long pressed with real data") },
                isNovaProcessing: false,
                hasPendingScenario: false
            )
            
            // 🔴 P0-c Test: Narrow width simulation - PRESERVED
            HeaderV3B(
                workerName: "Kevin Dutan",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Sidewalk Sweep at 131 Perry St",
                hasUrgentWork: false,
                onNovaPress: { print("Narrow Nova with Kevin's real data") },
                onNovaLongPress: { print("Narrow Nova long press with real tasks") },
                isNovaProcessing: false,
                hasPendingScenario: true
            )
            .frame(width: 320) // Simulate narrow iPhone
            
            // Urgent state with real scenario
            HeaderV3B(
                workerName: "Mercedes Inamagua",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: "Glass Cleaning at 112 W 18th",
                hasUrgentWork: true,
                onNovaPress: { print("Urgent Nova with Mercedes data") },
                onNovaLongPress: { print("Urgent Nova long press") },
                isNovaProcessing: false,
                hasPendingScenario: false
            )
            
            // Processing state
            HeaderV3B(
                workerName: "Edwin Lema",
                clockedInStatus: true,
                onClockToggle: {},
                onProfilePress: {},
                nextTaskName: nil,
                hasUrgentWork: false,
                onNovaPress: { print("Processing Nova") },
                onNovaLongPress: { print("Processing Nova long press") },
                isNovaProcessing: true,
                hasPendingScenario: false
            )
            
            Spacer()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
