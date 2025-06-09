// BuildingMapMarker.swift
// Map markers for buildings

import SwiftUI

struct BuildingMapMarker: View {
    let building: NamedCoordinate
    let isClockedIn: Bool
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.3),
                            Color.blue.opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 5,
                        endRadius: 15
                    )
                )
                .frame(width: 40, height: 40)
            
            // Inner circle
            Circle()
                .fill(isClockedIn ? Color.green : Color.blue)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // Clock-in indicator
            if isClockedIn {
                Image(systemName: "checkmark")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
        }
        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}
