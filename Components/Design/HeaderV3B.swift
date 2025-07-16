//
//  HeaderV3B.swift
//  FrancoSphere v6.0 - WORKER ROLE FIXES
//
//  ✅ FIXED: Hide AI icon for worker roles
//  ✅ FIXED: Enhanced role descriptions
//  ✅ FIXED: Proper header layout and spacing
//

import SwiftUI

struct HeaderV3B: View {
    let workerName: String
    let nextTaskName: String?
    let showClockPill: Bool
    let isNovaProcessing: Bool
    let onProfileTap: () -> Void
    let onNovaPress: () -> Void
    let onNovaLongPress: () -> Void
    
    // NEW: Determine if this is a worker role
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    
    var body: some View {
        headerContent
            .frame(height: 80)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea()
            )
    }
    
    private var headerContent: some View {
        HStack(spacing: 16) {
            // Left: Profile section
            HStack(spacing: 12) {
                profileButton
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workerName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if let nextTask = nextTaskName {
                        Text("Next: \(nextTask)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    } else {
                        Text(getEnhancedWorkerRole())
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Center: Clock pill
            if showClockPill {
                clockPill
            }
            
            Spacer()
            
            // Right: AI button (ONLY for admin/client, NOT workers)
            if !isWorkerRole {
                aiAssistantButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var profileButton: some View {
        Button(action: onProfileTap) {
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(workerName.prefix(2).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var clockPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("On Site")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.2))
        .overlay(
            Capsule()
                .stroke(Color.green.opacity(0.4), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
    
    private var aiAssistantButton: some View {
        Button(action: {
            if isNovaProcessing {
                onNovaLongPress()
            } else {
                onNovaPress()
            }
        }) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                
                if isNovaProcessing {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [.purple, .blue, .purple],
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
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Properties
    
    private var isWorkerRole: Bool {
        // Check if current user is a worker (not admin/client)
        guard let worker = contextAdapter.currentWorker else { return true }
        return worker.role == .worker
    }
    
    private func getEnhancedWorkerRole() -> String {
        guard let worker = contextAdapter.currentWorker else { return "Building Operations" }
        
        switch worker.id {
        case "4": return "Museum & Property Specialist"  // Kevin - Rubin Museum
        case "2": return "Park Operations & Maintenance"  // Edwin - Stuyvesant Park
        case "5": return "West Village Buildings"         // Mercedes - Perry Street area
        case "6": return "Downtown Maintenance"           // Luis - Elizabeth Street
        case "1": return "Building Systems Specialist"   // Greg - 12 West 18th
        case "7": return "Evening Operations"             // Angel - Night shift
        case "8": return "Portfolio Management"           // Shawn - Management
        default: return worker.role.rawValue.capitalized
        }
    }
}
