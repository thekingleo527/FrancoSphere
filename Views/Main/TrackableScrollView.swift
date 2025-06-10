//
//  TrackableScrollView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/9/25.
//


// WorkerDashboardView - Header Section Update
// Replace the existing header and aiAvatarOverlay sections with this code

// MARK: - Add these @State properties to WorkerDashboardView
@State private var showQuickActions = false
@State private var scrollOffset: CGFloat = 0

// MARK: - Replace the entire header computed property
private var header: some View {
    ZStack(alignment: .top) {
        // Background gradient
        LinearGradient(
            colors: [
                Color.blue.opacity(0.6),
                Color.blue.opacity(0.3),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 220)
        .ignoresSafeArea(edges: .top)
        
        // Header content
        VStack(spacing: 16) {
            // Top row with greeting and Nova
            HStack(alignment: .top) {
                // Greeting and info
                VStack(alignment: .leading, spacing: 8) {
                    Text(greeting)
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    
                    if let location = locationInfo {
                        Label(location, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                // Nova Avatar
                NovaAvatar(
                    size: 60,
                    showStatus: AIAssistantManager.shared.hasActiveNotifications,
                    hasUrgentInsight: AIAssistantManager.shared.hasUrgentScenario,
                    isBusy: AIAssistantManager.shared.isProcessing,
                    onTap: {
                        // Show AI insights
                        if let scenario = AIAssistantManager.shared.currentScenario {
                            AIAssistantManager.shared.showScenario(scenario)
                        }
                    },
                    onLongPress: {
                        showQuickActions = true
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 60) // Account for safe area
            
            // Clock in/out status card
            clockInStatusCard
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Replace clockInStatusCard with glass-styled version
private var clockInStatusCard: some View {
    HStack(spacing: 16) {
        // Status icon
        ZStack {
            Circle()
                .fill(currentShift != nil ? 
                     Color.green.opacity(0.2) : 
                     Color.orange.opacity(0.2))
                .frame(width: 44, height: 44)
            
            Image(systemName: currentShift != nil ? 
                  "checkmark.circle.fill" : 
                  "clock.fill")
                .font(.system(size: 22))
                .foregroundColor(currentShift != nil ? .green : .orange)
        }
        
        // Status text
        VStack(alignment: .leading, spacing: 4) {
            Text(currentShift != nil ? "Clocked In" : "Not Clocked In")
                .font(.headline)
                .foregroundColor(.white)
            
            if let shift = currentShift,
               let building = buildingManager.getBuilding(withId: shift.buildingID) {
                Text(building.name)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            } else {
                Text("Tap to clock in at your building")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        
        Spacer()
        
        // Clock button
        Button(action: {
            if currentShift != nil {
                showClockOutConfirmation = true
            } else {
                selectedTab = 1 // Go to Map tab
            }
        }) {
            Text(currentShift != nil ? "Clock Out" : "Clock In")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(currentShift != nil ? 
                             Color.red.opacity(0.8) : 
                             Color.green.opacity(0.8))
                )
        }
    }
    .padding(16)
    .adaptiveGlass(
        intensity: .prominent,
        cornerRadius: 16,
        scrollOffset: scrollOffset
    )
}

// MARK: - Update the main body ScrollView to track offset
var body: some View {
    ZStack {
        // Background
        LinearGradient(
            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        // Main content with scroll tracking
        TrackableScrollView(offsetChanged: { offset in
            scrollOffset = offset
        }) {
            VStack(spacing: 24) {
                header
                
                // Stats cards with adaptive glass
                statsSection
                    .padding(.horizontal, 20)
                
                // Today's tasks with adaptive glass
                todaysTasksSection
                    .padding(.horizontal, 20)
                
                // Recent activity with adaptive glass
                recentActivitySection
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100) // Tab bar space
            }
        }
        
        // Quick Action Menu overlay
        if showQuickActions {
            QuickActionMenu(isPresented: $showQuickActions) { action in
                handleQuickAction(action)
            }
            .zIndex(200)
            .transition(.opacity)
        }
    }
    .animation(.spring(), value: showQuickActions)
}

// MARK: - Add Quick Action Handler
private func handleQuickAction(_ action: QuickActionType) {
    switch action {
    case .scanQR:
        // Navigate to QR scanner
        print("Opening QR scanner...")
        
    case .reportIssue:
        // Show issue reporting
        print("Opening issue reporter...")
        
    case .showMap:
        // Switch to map tab
        selectedTab = 1
        
    case .askNova:
        // Open Nova chat interface
        print("Opening Nova chat...")
        
    case .viewInsights:
        // Show AI insights dashboard
        print("Opening AI insights...")
    }
}

// MARK: - Update task cards to use adaptive glass
private func taskCard(for task: MaintenanceTask) -> some View {
    HStack(spacing: 16) {
        // Priority indicator
        Circle()
            .fill(task.priorityColor.opacity(0.3))
            .frame(width: 8, height: 8)
        
        // Task details
        VStack(alignment: .leading, spacing: 4) {
            Text(task.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
            
            HStack(spacing: 12) {
                Label(task.building.name, systemImage: "building.2.fill")
                Label(task.estimatedDuration, systemImage: "clock")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        
        Spacer()
        
        // Status badge
        Text(task.status.rawValue.capitalized)
            .font(.caption.bold())
            .foregroundColor(task.statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(task.statusColor.opacity(0.15))
            )
    }
    .padding(16)
    .adaptiveGlass(
        intensity: .regular,
        cornerRadius: 12,
        scrollOffset: scrollOffset
    )
}

// MARK: - TrackableScrollView Helper
struct TrackableScrollView<Content: View>: View {
    let offsetChanged: (CGFloat) -> Void
    let content: Content
    
    init(offsetChanged: @escaping (CGFloat) -> Void, @ViewBuilder content: () -> Content) {
        self.offsetChanged = offsetChanged
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
            .frame(height: 0)
            
            content
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            offsetChanged(value)
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}