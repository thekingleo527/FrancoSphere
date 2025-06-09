//
//  WorkerAssignmentGlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


//
//  WorkerAssignmentGlassCard.swift
//  FrancoSphere
//
//  Glass card for displaying worker assignments and status
//

import SwiftUI

struct WorkerAssignmentGlassCard: View {
    let workers: [FrancoWorkerAssignment]
    let clockedInStatus: (isClockedIn: Bool, buildingId: Int64?)
    let currentWorkerId: Int64
    let onWorkerTap: (FrancoWorkerAssignment) -> Void
    
    var body: some View {
        GlassCard(intensity: .thin) {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                headerSection
                
                // Workers list
                if workers.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 12) {
                        ForEach(workers, id: \.workerId) { worker in
                            WorkerRowGlassView(
                                worker: worker,
                                isCurrentUser: worker.workerId == currentWorkerId,
                                isOnSite: isWorkerOnSite(worker),
                                onTap: { onWorkerTap(worker) }
                            )
                        }
                    }
                }
                
                // Summary footer
                if !workers.isEmpty {
                    summaryFooter
                }
            }
            .padding(20)
        }
    }
    
    // MARK: - Sub-components
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Assigned Workers")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(workers.count) worker\(workers.count == 1 ? "" : "s") assigned")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // Status indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(getOverallStatusColor())
                    .frame(width: 8, height: 8)
                
                Text(getOverallStatusText())
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(getOverallStatusColor().opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(getOverallStatusColor().opacity(0.4), lineWidth: 1)
            )
            .cornerRadius(16)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.badge.plus")
                .font(.system(size: 32))
                .foregroundColor(.white.opacity(0.5))
            
            Text("No Workers Assigned")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("This building currently has no assigned workers")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    private var summaryFooter: some View {
        VStack(spacing: 8) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            HStack {
                HStack(spacing: 12) {
                    footerStat(
                        icon: "person.circle.fill",
                        label: "On Site",
                        count: getOnSiteCount(),
                        color: .green
                    )
                    
                    footerStat(
                        icon: "person.circle",
                        label: "Off Site",
                        count: getOffSiteCount(),
                        color: .gray
                    )
                }
                
                Spacer()
                
                // Shift distribution
                if hasShiftData() {
                    HStack(spacing: 8) {
                        Text("Shifts:")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        ForEach(getShiftDistribution(), id: \.0) { shift, count in
                            HStack(spacing: 4) {
                                Text(shift)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("(\(count))")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func footerStat(icon: String, label: String, count: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
    
    // MARK: - Helper Methods
    
    private func isWorkerOnSite(_ worker: FrancoWorkerAssignment) -> Bool {
        return clockedInStatus.isClockedIn && 
               worker.workerId == currentWorkerId &&
               clockedInStatus.buildingId == Int64(worker.buildingId)
    }
    
    private func getOverallStatusColor() -> Color {
        let onSiteCount = getOnSiteCount()
        if onSiteCount == 0 {
            return .red
        } else if onSiteCount < workers.count {
            return .orange
        } else {
            return .green
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
        workers.contains { $0.shift != nil }
    }
    
    private func getShiftDistribution() -> [(String, Int)] {
        let shiftCounts = Dictionary(grouping: workers.compactMap { $0.shift }) { $0 }
            .mapValues { $0.count }
        
        return Array(shiftCounts).sorted { $0.0 < $1.0 }
    }
}

// MARK: - WorkerRowGlassView

struct WorkerRowGlassView: View {
    let worker: FrancoWorkerAssignment
    let isCurrentUser: Bool
    let isOnSite: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Worker avatar
                workerAvatar
                
                // Worker info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(worker.workerName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if isCurrentUser {
                            Text("YOU")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        if let shift = worker.shift {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(shift)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        if let role = worker.specialRole {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                
                                Text(role)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Status indicator
                statusIndicator
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCurrentUser ? Color.blue.opacity(0.1) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isCurrentUser ? Color.blue.opacity(0.3) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                onTap()
            }
        }
    }
    
    // MARK: - Sub-components
    
    private var workerAvatar: some View {
        ZStack {
            Circle()
                .fill(getAvatarColor().opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(isOnSite ? Color.green : Color.white.opacity(0.3), lineWidth: 2)
                )
            
            Text(getInitials())
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(getAvatarColor())
        }
    }
    
    private var statusIndicator: some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isOnSite ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text(isOnSite ? "On Site" : "Off Site")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background((isOnSite ? Color.green : Color.gray).opacity(0.2))
            .cornerRadius(12)
            
            if isOnSite {
                Text("Active")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getInitials() -> String {
        let components = worker.workerName.split(separator: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private func getAvatarColor() -> Color {
        // Generate consistent color based on worker name
        let hash = worker.workerName.hashValue
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .yellow]
        return colors[abs(hash) % colors.count]
    }
}

// MARK: - Preview

struct WorkerAssignmentGlassCard_Previews: PreviewProvider {
    static var sampleWorkers: [FrancoWorkerAssignment] {
        [
            FrancoWorkerAssignment(
                buildingId: "15",
                workerId: 1,
                workerName: "Greg Hutson",
                shift: "Day",
                specialRole: "Lead Maintenance"
            ),
            FrancoWorkerAssignment(
                buildingId: "15",
                workerId: 2,
                workerName: "Edwin Lema",
                shift: "Day",
                specialRole: nil
            ),
            FrancoWorkerAssignment(
                buildingId: "15",
                workerId: 3,
                workerName: "Jose Rodriguez",
                shift: "Evening",
                specialRole: "Cleaning Specialist"
            )
        ]
    }
    
    static var previews: some View {
        ZStack {
            FrancoSphereColors.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                WorkerAssignmentGlassCard(
                    workers: sampleWorkers,
                    clockedInStatus: (true, 15),
                    currentWorkerId: 2,
                    onWorkerTap: { _ in }
                )
                
                WorkerAssignmentGlassCard(
                    workers: [],
                    clockedInStatus: (false, nil),
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