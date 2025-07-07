//
//  EnhancedClockInGlassCard.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
//  ✅ DECOUPLED: No longer observes ClockInManager or QB services directly.
//  ✅ PRESERVED: Original UI design, including QB status indicators and popover.
//

import SwiftUI

// This view is now "dumb" - it only displays the state it's given.
// The parent view (WorkerDashboardView) is responsible for providing the data
// and handling the actions.
struct EnhancedClockInGlassCard: View {
    // MARK: - State Properties (Passed from Parent)
    let isClockedIn: Bool
    let qbStatus: QBConnectionStatus
    let isExportingToQB: Bool
    let lastQBSync: Date?

    // MARK: - Action Closures (Handled by Parent)
    let onClockInToggle: () -> Void
    let onQuickBooksTap: () -> Void

    // MARK: - Private UI State
    @State private var isPressed = false
    @State private var syncAnimation = false

    var body: some View {
        VStack(spacing: 12) {
            mainClockButton
            
            // QuickBooks Integration Status
            if qbStatus != .disconnected {
                quickBooksStatusIndicator
            }
        }
        .onChange(of: isExportingToQB) { isExporting in
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                syncAnimation = isExporting
            }
        }
    }

    // MARK: - Main Clock Button
    private var mainClockButton: some View {
        Button(action: {
            HapticManager.impact(.medium)
            onClockInToggle()
        }) {
            ZStack {
                // Glass capsule background
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: isClockedIn ?
                                        [.green, .green.opacity(0.6)] :
                                        [.blue, .blue.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: isClockedIn ? .green.opacity(0.3) : .blue.opacity(0.3),
                        radius: 8, x: 0, y: 4
                    )

                // Content
                VStack(spacing: 8) {
                    Image(systemName: isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(isClockedIn ? .green : .blue)
                    
                    Text(isClockedIn ? "CLOCK\nOUT" : "CLOCK\nIN")
                        .font(.system(size: 11, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(isClockedIn ? .green : .blue)
                }
                .rotationEffect(.degrees(-90))
                .fixedSize()
            }
            .frame(width: 44, height: 160)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }

    // MARK: - QuickBooks Status Indicator
    private var quickBooksStatusIndicator: some View {
        Button(action: onQuickBooksTap) {
            VStack(spacing: 6) {
                // QB Connection Status
                HStack(spacing: 4) {
                    Image(systemName: qbStatus.icon)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(qbStatus.color)
                    
                    Text("QB")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(qbStatus.color)
                }
                
                // Last Sync Indicator
                if let lastSync = lastQBSync {
                    Text(lastSync, style: .relative)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.secondary)
                } else if isExportingToQB {
                    HStack(spacing: 3) {
                        ProgressView()
                            .scaleEffect(0.6)
                            .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                        
                        Text("Syncing...")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("Not Synced")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.orange)
                }
            }
            .padding(8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Types (for Previews)
enum QBConnectionStatus {
    case connected, disconnected, error
    
    var icon: String {
        switch self {
        case .connected: return "checkmark.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .gray
        case .error: return .red
        }
    }
    
    var displayText: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
}

// MARK: - Preview
struct EnhancedClockInGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            HStack(spacing: 30) {
                // Clocked Out State
                EnhancedClockInGlassCard(
                    isClockedIn: false,
                    qbStatus: .connected,
                    isExportingToQB: false,
                    lastQBSync: Date().addingTimeInterval(-3600),
                    onClockInToggle: { print("Clock In Toggled") },
                    onQuickBooksTap: { print("QB Tapped") }
                )
                
                // Clocked In State
                EnhancedClockInGlassCard(
                    isClockedIn: true,
                    qbStatus: .connected,
                    isExportingToQB: false,
                    lastQBSync: Date().addingTimeInterval(-3600),
                    onClockInToggle: { print("Clock Out Toggled") },
                    onQuickBooksTap: { print("QB Tapped") }
                )
                
                // Syncing State
                EnhancedClockInGlassCard(
                    isClockedIn: true,
                    qbStatus: .connected,
                    isExportingToQB: true,
                    lastQBSync: Date().addingTimeInterval(-3600),
                    onClockInToggle: {},
                    onQuickBooksTap: {}
                )
            }
        }
    }
}
