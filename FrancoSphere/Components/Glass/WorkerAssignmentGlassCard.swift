//
//  WorkerAssignmentGlassCard.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme fully applied
//  ✅ ENHANCED: Complete FrancoSphereDesign integration
//  ✅ IMPROVED: Glass effects optimized for dark theme
//  ✅ ALIGNED: With CoreTypes.FrancoWorkerAssignment definition
//

import SwiftUI

struct WorkerAssignmentGlassCard: View {
    let workers: [CoreTypes.FrancoWorkerAssignment]
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let currentWorkerId: Int64
    let onWorkerTap: (CoreTypes.FrancoWorkerAssignment) -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            headerSection
            
            // Workers list
            if workers.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 12) {
                    ForEach(workers, id: \.id) { worker in
                        WorkerRowGlassView(
                            worker: worker,
                            isCurrentUser: worker.workerId == currentWorkerId,
                            isOnSite: isWorkerOnSite(worker),
                            onTap: { onWorkerTap(worker) }
                        )
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
            }
            
            // Summary footer
            if !workers.isEmpty {
                summaryFooter
            }
        }
        .padding(20)
        .background(darkGlassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(glassOverlayBorder)
        .shadow(
            color: FrancoSphereDesign.DashboardColors.baseBackground.opacity(0.3),
            radius: 15,
            x: 0,
            y: 8
        )
        .onAppear {
            withAnimation(FrancoSphereDesign.Animations.spring.delay(0.2)) {
                isAnimating = true
            }
        }
        .animation(FrancoSphereDesign.Animations.spring, value: workers.count)
    }
    
    // MARK: - Sub-components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Assigned Workers")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("\(workers.count) worker\(workers.count == 1 ? "" : "s") assigned")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(getOverallStatusColor())
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(getOverallStatusColor().opacity(0.3), lineWidth: 8)
                            .scaleEffect(1.5)
                            .opacity(isAnimating ? 0.6 : 0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    )
                
                Text(getOverallStatusText())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(getOverallStatusColor().opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(getOverallStatusColor().opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(FrancoSphereDesign.DashboardColors.inactive)
            
            Text("No Workers Assigned")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text("This building currently has no assigned workers")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var summaryFooter: some View {
        VStack(spacing: 8) {
            Divider()
                .background(FrancoSphereDesign.DashboardColors.glassOverlay)
            
            HStack {
                HStack(spacing: 12) {
                    FooterStat(
                        icon: "person.circle.fill",
                        label: "On Site",
                        count: getOnSiteCount(),
                        color: FrancoSphereDesign.DashboardColors.success
                    )
                    
                    FooterStat(
                        icon: "person.circle",
                        label: "Off Site",
                        count: getOffSiteCount(),
                        color: FrancoSphereDesign.DashboardColors.inactive
                    )
                }
                
                Spacer()
                
                // Shift distribution
                if hasShiftData() {
                    shiftDistributionView
                }
            }
        }
    }
    
    private var shiftDistributionView: some View {
        HStack(spacing: 8) {
            Text("Shifts:")
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            
            ForEach(getShiftDistribution(), id: \.0) { shift, count in
                HStack(spacing: 4) {
                    Text(shift)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text("(\(count))")
                        .font(.caption2)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Background Components
    
    private var darkGlassBackground: some View {
        ZStack {
            // Dark base
            RoundedRectangle(cornerRadius: 20)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.9))
            
            // Glass material
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial.opacity(0.3))
            
            // Gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            FrancoSphereDesign.DashboardColors.glassOverlay.opacity(0.2),
                            FrancoSphereDesign.DashboardColors.glassOverlay.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }
    
    private var glassOverlayBorder: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Helper Methods
    
    private func isWorkerOnSite(_ worker: CoreTypes.FrancoWorkerAssignment) -> Bool {
        guard clockedInStatus.isClockedIn else { return false }
        guard worker.workerId == currentWorkerId else { return false }
        guard let buildingId = clockedInStatus.buildingId else { return false }
        
        return buildingId == worker.buildingId
    }
    
    private func getOverallStatusColor() -> Color {
        let onSiteCount = getOnSiteCount()
        if onSiteCount == 0 {
            return FrancoSphereDesign.DashboardColors.critical
        } else if onSiteCount < workers.count {
            return FrancoSphereDesign.DashboardColors.warning
        } else {
            return FrancoSphereDesign.DashboardColors.success
        }
    }
    
    private func getOverallStatusText() -> String {
        let onSiteCount = getOnSiteCount()
        if onSiteCount == 0 {
            return "No Coverage"
        } else if onSiteCount < workers.count {
            return "Partial Coverage"
        } else {
            return "Full Coverage"
        }
    }
    
    private func getOnSiteCount() -> Int {
        workers.filter { isWorkerOnSite($0) }.count
    }
    
    private func getOffSiteCount() -> Int {
        workers.count - getOnSiteCount()
    }
    
    private func hasShiftData() -> Bool {
        workers.contains { !$0.shift.isEmpty }
    }
    
    private func getShiftDistribution() -> [(String, Int)] {
        let shifts = workers.map { $0.shift }.filter { !$0.isEmpty }
        let shiftCounts = Dictionary(grouping: shifts) { $0 }
            .mapValues { $0.count }
        
        return Array(shiftCounts).sorted { $0.0 < $1.0 }
    }
}

// MARK: - WorkerRowGlassView

struct WorkerRowGlassView: View {
    let worker: CoreTypes.FrancoWorkerAssignment
    let isCurrentUser: Bool
    let isOnSite: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }) {
            HStack(spacing: 12) {
                // Worker avatar
                workerAvatar
                
                // Worker info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(worker.workerName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        
                        if isCurrentUser {
                            Text("YOU")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FrancoSphereDesign.DashboardColors.info.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if !worker.shift.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                                
                                Text(worker.shift)
                                    .font(.caption)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                            }
                        }
                        
                        if let role = worker.specialRole {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                                
                                Text(role)
                                    .font(.caption)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            .padding(16)
            .background(workerRowBackground)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Sub-components
    
    private var workerAvatar: some View {
        ZStack {
            Circle()
                .fill(getAvatarGradient())
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(
                            isOnSite ? FrancoSphereDesign.DashboardColors.success :
                            Color.white.opacity(0.2),
                            lineWidth: 2
                        )
                )
            
            Text(getInitials())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Online indicator
            if isOnSite {
                Circle()
                    .fill(FrancoSphereDesign.DashboardColors.success)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(FrancoSphereDesign.DashboardColors.cardBackground, lineWidth: 2)
                    )
                    .offset(x: 14, y: 14)
            }
        }
    }
    
    private var statusIndicator: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isOnSite ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.inactive)
                    .frame(width: 8, height: 8)
                
                Text(isOnSite ? "On Site" : "Off Site")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                (isOnSite ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.inactive)
                    .opacity(0.15)
            )
            .cornerRadius(12)
            
            if isOnSite {
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
            }
        }
    }
    
    private var workerRowBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                isCurrentUser ?
                FrancoSphereDesign.DashboardColors.info.opacity(0.1) :
                FrancoSphereDesign.DashboardColors.glassOverlay
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCurrentUser ?
                        FrancoSphereDesign.DashboardColors.info.opacity(0.3) :
                        Color.white.opacity(0.1),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Helper Methods
    
    private func getInitials() -> String {
        let components = worker.workerName.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private func getAvatarGradient() -> LinearGradient {
        // Generate consistent color based on worker name
        let hash = worker.workerName.hashValue
        let colors: [(Color, Color)] = [
            (FrancoSphereDesign.DashboardColors.info, FrancoSphereDesign.DashboardColors.info.opacity(0.5)),
            (FrancoSphereDesign.DashboardColors.success, FrancoSphereDesign.DashboardColors.success.opacity(0.5)),
            (FrancoSphereDesign.DashboardColors.warning, FrancoSphereDesign.DashboardColors.warning.opacity(0.5)),
            (Color(hex: "9333ea"), Color(hex: "9333ea").opacity(0.5)), // Purple
            (Color(hex: "ec4899"), Color(hex: "ec4899").opacity(0.5)), // Pink
            (Color(hex: "fbbf24"), Color(hex: "fbbf24").opacity(0.5))  // Amber
        ]
        
        let colorPair = colors[abs(hash) % colors.count]
        
        return LinearGradient(
            colors: [colorPair.0, colorPair.1],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - FooterStat Component

struct FooterStat: View {
    let icon: String
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
    }
}

// MARK: - Preview

struct WorkerAssignmentGlassCard_Previews: PreviewProvider {
    static var sampleWorkers: [CoreTypes.FrancoWorkerAssignment] {
        [
            CoreTypes.FrancoWorkerAssignment(
                id: "1",
                workerId: 1,
                workerName: "Greg Hutson",
                buildingId: 15,
                buildingName: "Rubin Museum",
                startDate: Date(),
                shift: "Day",
                specialRole: "Lead Maintenance",
                isActive: true
            ),
            CoreTypes.FrancoWorkerAssignment(
                id: "2",
                workerId: 2,
                workerName: "Edwin Lema",
                buildingId: 15,
                buildingName: "Rubin Museum",
                startDate: Date(),
                shift: "Day",
                specialRole: nil,
                isActive: true
            ),
            CoreTypes.FrancoWorkerAssignment(
                id: "3",
                workerId: 3,
                workerName: "Jose Rodriguez",
                buildingId: 15,
                buildingName: "Rubin Museum",
                startDate: Date(),
                shift: "Evening",
                specialRole: "Cleaning Specialist",
                isActive: true
            )
        ]
    }
    
    static var previews: some View {
        ZStack {
            FrancoSphereDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                WorkerAssignmentGlassCard(
                    workers: sampleWorkers,
                    clockedInStatus: (true, 15),
                    currentWorkerId: 2,
                    onWorkerTap: { worker in
                        print("Tapped: \(worker.workerName)")
                    }
                )
                
                WorkerAssignmentGlassCard(
                    workers: [],
                    clockedInStatus: (false, nil),
                    currentWorkerId: 1,
                    onWorkerTap: { _ in }
                )
                
                WorkerAssignmentGlassCard(
                    workers: Array(sampleWorkers.prefix(1)),
                    clockedInStatus: (true, 15),
                    currentWorkerId: 1,
                    onWorkerTap: { _ in }
                )
                
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
