//
//  GlassLoadingView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


// GlassLoadingView.swift
// Glass-styled loading indicator

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct GlassLoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        GlassCard(intensity: .regular) {
            VStack(spacing: 20) {
                // Loading indicator
                ZStack {
                    // Orbiting dots
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 10, height: 10)
                            .offset(y: -25)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                            .rotationEffect(.degrees(Double(index) * 120))
                    }
                    
                    // Center icon
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.8))
                        .scaleEffect(isAnimating ? 1.1 : 0.9)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                .frame(width: 60, height: 60)
                
                // Loading message
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
        .frame(width: 280)
        .onAppear {
            isAnimating = true
        }
    }
}