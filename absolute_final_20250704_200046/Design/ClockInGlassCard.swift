//
//  ClockInGlassCard.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct ClockInGlassCard: View {
    @ObservedObject var clockInManager = ClockInManager.shared // Use singleton
    @State private var isPressed = false
    
    var body: some View {
        Button(action: handleClockIn) {
            ZStack {
                // Vertical glass capsule background
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: clockInManager.isClockedIn ?
                                        [.green, .green.opacity(0.6)] :
                                        [.blue, .blue.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(
                        color: clockInManager.isClockedIn ? .green.opacity(0.3) : .blue.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                // Properly oriented content (rotated 90° counter-clockwise)
                VStack(spacing: 8) {
                    Image(systemName: clockInManager.isClockedIn ? "clock.badge.checkmark.fill" : "clock.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(clockInManager.isClockedIn ? .green : .blue)
                    
                    Text(clockInManager.isClockedIn ? "CLOCK\nOUT" : "CLOCK\nIN")
                        .font(.system(size: 11, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(clockInManager.isClockedIn ? .green : .blue)
                }
                .rotationEffect(.degrees(-90)) // Rotate content 90° counter-clockwise
                .fixedSize() // Prevent text truncation
            }
            .frame(width: 44, height: 160) // Vertical capsule dimensions
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
        .accessibilityLabel(clockInManager.isClockedIn ? "Clock out button" : "Clock in button")
        .accessibilityHint("Double tap to \(clockInManager.isClockedIn ? "clock out" : "clock in")")
    }
    
    private func handleClockIn() {
        HapticManager.impact(.medium)
        Task {
            await clockInManager.toggleClockIn()
        }
    }
}

// MARK: - Horizontal variant for different contexts (updated to not use PressableGlassCard)
struct ClockInGlassCardHorizontal: View {
    let onClockIn: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onClockIn) {
            HStack {
                Image(systemName: "clock.badge.checkmark")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("CLOCK IN")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            maximumDistance: .infinity,
            pressing: { pressing in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = pressing
                }
            },
            perform: {}
        )
    }
}

// MARK: - Preview
struct ClockInGlassCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Vertical clock-in button
                HStack(spacing: 20) {
                    // Normal state
                    ClockInGlassCard()
                    
                    // Clocked in state (for preview)
                    ClockInGlassCard()
                        .onAppear {
                            // For preview purposes only
                            ClockInManager.shared.isClockedIn = true
                        }
                }
                
                // Horizontal variant
                ClockInGlassCardHorizontal {
                    print("Clock In tapped!")
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
