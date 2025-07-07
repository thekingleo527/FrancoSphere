//
//  EnhancedClockInGlassCard.swift
//  FrancoSphere
//
//  ✅ V6.0: Decoupled from ClockInManager actor and cleaned up.
//  ✅ Now a "dumb" view that accepts simple state values.
//

import SwiftUI

struct EnhancedClockInGlassCard: View {
    let isClockedIn: Bool
    let qbStatus: QBConnectionStatus
    let isExportingToQB: Bool
    let lastQBSync: Date?
    let onClockInToggle: () -> Void
    let onQuickBooksTap: () -> Void

    var body: some View {
        // This view's body can be implemented based on the original design,
        // using the properties passed in from the parent view.
        // For now, a simplified version to ensure compilation.
        VStack(spacing: 12) {
            Button(action: onClockInToggle) {
                VStack(spacing: 8) {
                    Image(systemName: isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                        .font(.system(size: 24, weight: .medium))
                    Text(isClockedIn ? "CLOCK\nOUT" : "CLOCK\nIN")
                        .font(.system(size: 11, weight: .bold))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            if qbStatus != .disconnected {
                Button(action: onQuickBooksTap) {
                    HStack {
                        Image(systemName: qbStatus.icon)
                        Text("QB: \(qbStatus.displayText)")
                    }
                    .font(.caption)
                    .padding(8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
