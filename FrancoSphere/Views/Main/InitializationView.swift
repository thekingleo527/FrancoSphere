//
//  InitializationView.swift
//  FrancoSphere v6.0
//
//  ✅ VISUAL: Beautiful initialization screen with progress
//  ✅ INFORMATIVE: Shows current step to user
//  ✅ ANIMATED: Smooth transitions and effects
//  ✅ GLASS: Consistent with app design system
//

import SwiftUI

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 50)
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        .shadow(color: .blue.opacity(0.5), radius: 20)
                    
                    Text("FrancoSphere")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(logoOpacity)
                    
                    Text("Property Management System")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(logoOpacity)
                }
                
                Spacer()
                
                // Progress section
                VStack(spacing: 16) {
                    // Progress bar
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(CustomProgressViewStyle())
                        .frame(height: 8)
                        .padding(.horizontal, 40)
                    
                    // Current step
                    Text(viewModel.currentStep)
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.8))
                        .animation(.easeInOut, value: viewModel.currentStep)
                    
                    // Progress percentage
                    Text("\(Int(viewModel.progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                        .monospacedDigit()
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .onAppear {
            // Animate logo appearance
            withAnimation(.easeOut(duration: 0.8)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Custom Progress View Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                
                // Progress fill
                if let progress = configuration.fractionCompleted {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                        .shadow(color: .blue.opacity(0.5), radius: 4)
                }
            }
        }
    }
}

// MARK: - Preview

struct InitializationView_Previews: PreviewProvider {
    static var previews: some View {
        InitializationView(viewModel: InitializationViewModel())
            .preferredColorScheme(.dark)
    }
}
