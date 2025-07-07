//
//  EnhancedClockInGlassCard.swift
//  FrancoSphere
//
//  ✅ V6.0: Decoupled from ClockInManager actor.
//  ✅ Now a "dumb" view that accepts simple state values.
//

import SwiftUI

struct EnhancedClockInGlassCard: View {
    let isClockedIn: Bool
    let qbStatus: QBConnectionStatus
    let onClockInToggle: () -> Void
    let onQuickBooksTap: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Button(action: onClockInToggle) {
                VStack(spacing: 8) {
                    Image(systemName: isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                    Text(isClockedIn ? "CLOCK\nOUT" : "CLOCK\nIN")
                }
                .padding().background(.ultraThinMaterial).clipShape(Capsule())
            }.buttonStyle(.plain)

            if qbStatus != .disconnected {
                Button(action: onQuickBooksTap) {
                    HStack {
                        Image(systemName: qbStatus.icon)
                        Text("QB: \(qbStatus.displayText)")
                    }
                    .font(.caption).padding(8).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }.buttonStyle(.plain)
            }
        }
    }
}
