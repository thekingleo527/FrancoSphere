//
//  MySitesCard.swift
//  FrancoSphere
//
//  ✅ PHASE-2 MYSITES CARD ENHANCED
//  ✅ Emergency Kevin assignment fixes
//  ✅ Real-world data integration
//  ✅ Enhanced debugging and recovery
//  ✅ Production-ready error handling
//  ✅ HF-06 HOTFIX: Auto-fallback and graceful recovery
//  ✅ FIXED: Removed all shimmerGradient references
//  ✅ HF-06B: Enhanced coordination with WorkerAssignmentManager
//  ✅ HF-10-B: Direct observation of WorkerContextEngine for reactive buildings
//

import SwiftUI

struct MySitesCard: View {
    let workerId: String
    let workerName: String
    // ✅ HF-10: REMOVED assignedBuildings parameter
    let buildingWeatherMap: [String: FrancoSphere.WeatherData]
    let clockedInBuildingId: String?
    let forceShow: Bool
    let onRefresh: () async -> Void
    let onFixBuildings: () async -> Void
    let onBrowseAll: () -> Void
    let onBuildingTap: (FrancoSphere.NamedCoordinate) -> Void
    
    // ✅ HF-10: Direct observation of WorkerContextEngine
    @StateObject private var contextEngine = WorkerContextEngine.shared
    
    @State private var isRefreshing = false
    @State private var isFixing = false
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var showDebugInfo = false
    
    // ✅ HF-10: Use contextEngine.assignedBuildings directly
    private var assignedBuildings: [FrancoSphere.NamedCoordinate] {
        contextEngine.assignedBuildings
    }
    
    // ✅ HF-10: Use contextEngine.isLoading directly
    private var isLoading: Bool {
        contextEngine.isLoading
    }
    
    // ✅ HF-10: Use contextEngine.error directly
    private var error: Error? {
        contextEngine.error
    }
    
    // BEGIN PATCH(HF-06): Auto-recovery state
    @State private var hasTriedAutoRecovery = false
    @State private var autoRecoveryInProgress = false
    @State private var showRecoverySuccess = false
    // END PATCH(HF-06)
    
    // BEGIN PATCH(HF-06B): Enhanced recovery coordination
    @State private var recoveryAttempts = 0
    @State private var lastRecoveryTime: Date = Date.distantPast
    private let maxRecoveryAttempts = 3
    private let recoveryInterval: TimeInterval = 30 // 30 seconds between attempts
    // END PATCH(HF-06B)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerSection
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Content
            if isLoading || autoRecoveryInProgress {
                loadingShimmerView
            } else if assignedBuildings.isEmpty {
                enhancedEmptyStateView
            } else {
                buildingsGridView
            }
            
            // BEGIN PATCH(HF-06): Recovery success banner
            if showRecoverySuccess {
                recoverySuccessBanner
            }
            // END PATCH(HF-06)
            
            // ✅ NEW: Debug info for troubleshooting
            if showDebugInfo {
                debugInfoSection
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            startShimmerAnimation()
            // BEGIN PATCH(HF-06B): Enhanced auto-recovery trigger
            if shouldTriggerAutoRecovery() {
                triggerEnhancedAutoRecovery()
            }
            // END PATCH(HF-06B)
        }
        .onChange(of: assignedBuildings) { newBuildings in
            // BEGIN PATCH(HF-06B): Monitor building changes for recovery validation
            if !newBuildings.isEmpty && autoRecoveryInProgress {
                print("✅ HF-06B: Buildings recovered during auto-recovery - success!")
                autoRecoveryInProgress = false
                showRecoverySuccess = true
                
                // Auto-hide success banner
                Task {
                    try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds
                    await MainActor.run {
                        showRecoverySuccess = false
                    }
                }
            }
            // END PATCH(HF-06B)
        }
    }
    
    // BEGIN PATCH(HF-06B): Enhanced auto-recovery logic
    private func shouldTriggerAutoRecovery() -> Bool {
        guard workerId == "4" else { return false } // Only for Kevin
        guard assignedBuildings.isEmpty else { return false } // Only if no buildings
        guard !hasTriedAutoRecovery else { return false } // Only if not already tried
        guard recoveryAttempts < maxRecoveryAttempts else { return false } // Max attempts limit
        
        let timeSinceLastRecovery = Date().timeIntervalSince(lastRecoveryTime)
        guard timeSinceLastRecovery > recoveryInterval else { return false } // Respect interval
        
        return true
    }
    
    private func triggerEnhancedAutoRecovery() {
        guard !autoRecoveryInProgress else { return }
        
        print("🔄 HF-06B: Triggering enhanced auto-recovery for \(workerName) (attempt \(recoveryAttempts + 1))")
        
        Task {
            await MainActor.run {
                autoRecoveryInProgress = true
                hasTriedAutoRecovery = true
                recoveryAttempts += 1
                lastRecoveryTime = Date()
            }
            
            // Step 1: Try WorkerAssignmentManager emergency trigger first
            await WorkerAssignmentManager.shared.triggerEmergencyResponse(for: workerId)
            
            // Step 2: Wait a moment for emergency response
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // Step 3: Trigger context refresh
            await onRefresh()
            
            // Step 4: If still empty, try the fix buildings method
            await MainActor.run {
                if assignedBuildings.isEmpty {
                    print("🆘 HF-06B: Still no buildings after emergency response, trying fix buildings")
                }
            }
            
            if assignedBuildings.isEmpty {
                await onFixBuildings()
            }
            
            // Step 5: Final validation
            await MainActor.run {
                if !assignedBuildings.isEmpty {
                    print("✅ HF-06B: Enhanced auto-recovery successful - \(assignedBuildings.count) buildings recovered")
                    showRecoverySuccess = true
                } else {
                    print("❌ HF-06B: Enhanced auto-recovery failed - escalating to manual intervention")
                }
                autoRecoveryInProgress = false
            }
        }
    }
    // END PATCH(HF-06B)
    
    // BEGIN PATCH(HF-06): Auto-recovery implementation (legacy - kept for compatibility)
    private func triggerAutoRecovery() {
        guard !autoRecoveryInProgress && !hasTriedAutoRecovery else { return }
        
        print("🔄 HF-06: Triggering auto-recovery for \(workerName)")
        
        Task {
            await MainActor.run {
                autoRecoveryInProgress = true
                hasTriedAutoRecovery = true
            }
            
            // Wait a brief moment to show loading state
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Trigger the fix process
            await onFixBuildings()
            
            await MainActor.run {
                autoRecoveryInProgress = false
                showRecoverySuccess = true
            }
            
            // Auto-hide success banner after 3 seconds
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                showRecoverySuccess = false
            }
        }
    }
    
    private var recoverySuccessBanner: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Buildings Recovered")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Your assigned buildings have been restored")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button("Dismiss") {
                showRecoverySuccess = false
            }
            .font(.caption2)
            .foregroundColor(.blue)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    // END PATCH(HF-06)
    
    // MARK: - Header Section Enhanced
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "building.2.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("My Sites")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // ✅ NEW: Worker-specific subtitle
                if !workerName.isEmpty {
                    Text(workerName)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Enhanced header controls with debug toggle
            Menu {
                Button("Refresh Data") {
                    handleRefresh()
                }
                
                Button("Browse All Buildings") {
                    onBrowseAll()
                }
                
                // BEGIN PATCH(HF-06B): Enhanced recovery menu options
                if workerId == "4" && assignedBuildings.isEmpty {
                    Divider()
                    
                    Button("🆘 Force Emergency Recovery") {
                        Task {
                            await WorkerAssignmentManager.shared.triggerEmergencyResponse(for: workerId)
                            await onRefresh()
                        }
                    }
                    
                    Button("🔧 Manual Fix Buildings") {
                        handleFixBuildings()
                    }
                }
                // END PATCH(HF-06B)
                
                Divider()
                
                Button(showDebugInfo ? "Hide Debug" : "Show Debug") {
                    showDebugInfo.toggle()
                }
            } label: {
                Image(systemName: isRefreshing ? "arrow.circlepath" : "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isRefreshing)
            }
        }
    }
    
    // MARK: - Loading Shimmer View (FIXED: No shimmerGradient references)
    
    private var loadingShimmerView: some View {
        VStack(spacing: 12) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 12) {
                    // Building image placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        // Building name placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 16)
                        
                        // Address placeholder
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 120, height: 12)
                    }
                    
                    Spacer()
                    
                    // Status indicator placeholder
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 12, height: 12)
                }
                .padding(.vertical, 8)
            }
        }
        .opacity(0.7 + 0.3 * shimmerOffset)
    }
    
    // MARK: - Enhanced Empty State View with Better Recovery
    
    private var enhancedEmptyStateView: some View {
        VStack(spacing: 16) {
            // BEGIN PATCH(HF-06B): Enhanced icon based on recovery state
            Image(systemName: autoRecoveryInProgress ? "arrow.triangle.2.circlepath" : "building.2.cropped.circle")
                .font(.system(size: 48))
                .foregroundColor(autoRecoveryInProgress ? .blue : .orange.opacity(0.8))
                .symbolEffect(.pulse, isActive: autoRecoveryInProgress)
            // END PATCH(HF-06B)
            
            VStack(spacing: 8) {
                Text(autoRecoveryInProgress ? "Recovering Buildings..." : "No Buildings Assigned")
                    .font(.headline)
                    .foregroundColor(.white)
                
                // BEGIN PATCH(HF-06B): Enhanced messaging for auto-recovery
                Group {
                    if autoRecoveryInProgress {
                        Text("Running enhanced recovery process...")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .multilineTextAlignment(.center)
                    } else if workerId == "4" && recoveryAttempts > 0 {
                        Text("Auto-recovery attempted (\(recoveryAttempts)/\(maxRecoveryAttempts)). Use the manual options below if needed.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    } else if workerId == "4" {
                        Text("Expected 6 buildings for Kevin Dutan. Enhanced recovery will start automatically.")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Your account doesn't have any assigned buildings yet.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                }
                // END PATCH(HF-06B)
            }
            
            // Enhanced action buttons
            HStack(spacing: 12) {
                Button("Fix Buildings") {
                    handleFixBuildings()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .disabled(isFixing || autoRecoveryInProgress)
                
                Button("Browse All") {
                    onBrowseAll()
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Worker-specific help text
            if !workerId.isEmpty {
                Text("Worker ID: \(workerId)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(20)
    }
    
    // MARK: - Buildings Grid View
    
    private var buildingsGridView: some View {
        VStack(spacing: 12) {
            // Summary header
            HStack {
                Text("\(assignedBuildings.count) Assigned Buildings")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                if let clockedInId = clockedInBuildingId {
                    Text("Clocked in: \(clockedInId)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            // Buildings list
            ForEach(assignedBuildings, id: \.id) { building in
                buildingRow(building)
            }
        }
    }
    
    private func buildingRow(_ building: FrancoSphere.NamedCoordinate) -> some View {
        Button(action: {
            onBuildingTap(building)
        }) {
            HStack(spacing: 12) {
                // Building image or placeholder
                if !building.imageAssetName.isEmpty {
                    Image(building.imageAssetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "building.2.fill")
                                .foregroundColor(.white.opacity(0.7))
                        )
                }
                
                // Building info
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        Text("ID: \(building.id)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        
                        if let weather = buildingWeatherMap[building.id] {
                            Text(weather.formattedTemperature)
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // Status indicators
                VStack(spacing: 4) {
                    // Clock-in status
                    Circle()
                        .fill(building.id == clockedInBuildingId ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(building.id == clockedInBuildingId ? Color.green.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(building.id == clockedInBuildingId ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Debug Info Section
    
    private var debugInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Information")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading, spacing: 4) {
                debugInfoRow("Worker ID", workerId)
                debugInfoRow("Worker Name", workerName)
                debugInfoRow("Buildings Count", "\(assignedBuildings.count)")
                debugInfoRow("Is Loading", "\(isLoading)")
                debugInfoRow("Has Error", error != nil ? "Yes" : "No")
                debugInfoRow("Clocked In Building", clockedInBuildingId ?? "None")
                // BEGIN PATCH(HF-06): Auto-recovery debug info
                debugInfoRow("Auto Recovery Tried", "\(hasTriedAutoRecovery)")
                debugInfoRow("Recovery In Progress", "\(autoRecoveryInProgress)")
                // BEGIN PATCH(HF-06B): Enhanced recovery debug info
                debugInfoRow("Recovery Attempts", "\(recoveryAttempts)/\(maxRecoveryAttempts)")
                debugInfoRow("Last Recovery", formatDate(lastRecoveryTime))
                
                // WorkerAssignmentManager status
                let emergencyStatus = WorkerAssignmentManager.shared.getEmergencyStatus()
                debugInfoRow("Emergency Active", "\(emergencyStatus.isActive)")
                debugInfoRow("Emergency Cache", "\(emergencyStatus.cacheCount) entries")
                // END PATCH(HF-06B)
                // END PATCH(HF-06)
            }
            
            if let error = error {
                Text("Error: \(error.localizedDescription)")
                    .font(.caption2)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func debugInfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text("\(label):")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    // BEGIN PATCH(HF-06B): Helper methods
    private func formatDate(_ date: Date) -> String {
        if date == Date.distantPast {
            return "Never"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    // END PATCH(HF-06B)
    
    // MARK: - Action Methods
    
    private func handleRefresh() {
        Task {
            await MainActor.run {
                isRefreshing = true
            }
            
            await onRefresh()
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
    
    private func handleFixBuildings() {
        Task {
            await MainActor.run {
                isFixing = true
            }
            
            await onFixBuildings()
            
            await MainActor.run {
                isFixing = false
            }
        }
    }
    
    private func startShimmerAnimation() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            shimmerOffset = 1.0
        }
    }
}
