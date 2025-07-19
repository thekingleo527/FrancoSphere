//
//  AbstractFrancoSphereLogo.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//

// Components/AbstractFrancoSphereLogo.swift
import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

struct AbstractFrancoSphereLogo: View {
    let size: CGFloat
    
    init(size: CGFloat = 120) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size * 0.2,
                        endRadius: size * 0.6
                    )
                )
                .frame(width: size * 1.2, height: size * 1.2)
                .blur(radius: 20)
            
            // Main globe shape
            ZStack {
                // Base gradient circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.29, green: 0.56, blue: 0.89),
                                Color(red: 0.48, green: 0.73, blue: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)
                
                // Glass overlay
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .frame(width: size, height: size)
                
                // Globe grid pattern (abstract)
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    
                    // Vertical meridian lines
                    ForEach(0..<3) { index in
                        Path { path in
                            let angle = Double(index) * 60.0 - 60.0
                            let startAngle = angle - 90
                            let endAngle = angle + 90
                            
                            path.addArc(
                                center: center,
                                radius: size * 0.45,
                                startAngle: .degrees(startAngle),
                                endAngle: .degrees(endAngle),
                                clockwise: false
                            )
                        }
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .rotationEffect(.degrees(Double(index) * 30))
                    }
                    
                    // Horizontal latitude lines
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                Color.white.opacity(0.2 - Double(index) * 0.05),
                                lineWidth: 1.0
                            )
                            .frame(
                                width: size * (0.8 - CGFloat(index) * 0.2),
                                height: size * 0.3
                            )
                            .offset(y: CGFloat(index - 1) * size * 0.2)
                    }
                }
                .frame(width: size, height: size)
                .mask(Circle())
                
                // Highlight effect
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            center: .init(x: 0.3, y: 0.3),
                            startRadius: 0,
                            endRadius: size * 0.3
                        )
                    )
                    .frame(width: size * 0.6, height: size * 0.6)
                    .offset(x: -size * 0.15, y: -size * 0.15)
                
                // Small accent dot
                Circle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: size * 0.05, height: size * 0.05)
                    .offset(x: size * 0.25, y: -size * 0.3)
            }
            .shadow(color: Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3), radius: 20, y: 10)
        }
        .frame(width: size * 1.2, height: size * 1.2)
    }
}
