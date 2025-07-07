//
//  ClockInGlassCard.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: Updated to work with the new ClockInManager actor.
//  ✅ FIXED: Removed @ObservedObject and now accepts simple bindings for state.
//

import SwiftUI

struct ClockInGlassCard: View {
    // This view is now "dumb" - it just displays the state it's given.
    let isClockedIn: Bool
    let onClockInToggle: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            onClockInToggle()
        }) {
            ZStack {
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
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
    }
}
