//
//  InitializationView.swift
//  CyntientOps v6.0
//
//  ✅ ENHANCED: Added error handling and retry functionality
//  ✅ VISUAL: Beautiful initialization screen with progress
//  ✅ INFORMATIVE: Shows current step to user
//  ✅ ANIMATED: Smooth transitions and effects
//

import SwiftUI

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var showRetryButton = false
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and title
                logoSection
                
                Spacer()
                
                // Progress or error section
                if viewModel.initializationError != nil {
                    errorSection
                } else {
                    progressSection
                }
            }
            .padding()
        }
        .onAppear {
            animateLogoAppearance()
            startInitialization()
        }
    }
    
    // MARK: - View Components
    
    private var backgroundGradient: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
        }
    }
    
    private var logoSection: some View {
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
                .rotationEffect(.degrees(viewModel.isInitializing ? 0 : 0))
                .animation(
                    viewModel.isInitializing ?
                    Animation.easeInOut(duration: 2).repeatForever(autoreverses: true) : .default,
                    value: viewModel.isInitializing
                )
            
            Text("CyntientOps")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .opacity(logoOpacity)
            
            Text("Property Management System")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .opacity(logoOpacity)
        }
    }
    
    private var progressSection: some View {
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
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Progress percentage
            Text("\(Int(viewModel.progress * 100))%")
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
                .monospacedDigit()
            
            #if DEBUG
            // Skip button for development
            Button("Skip (Debug)") {
                viewModel.skipInitialization()
            }
            .font(.caption)
            .foregroundColor(.orange)
            .padding(.top, 10)
            #endif
        }
        .padding(.bottom, 60)
    }
    
    private var errorSection: some View {
        VStack(spacing: 20) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .shadow(color: .orange.opacity(0.5), radius: 10)
            
            // Error message
            Text(viewModel.initializationError ?? "Unknown error")
                .font(.callout)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Retry button
            HStack(spacing: 20) {
                Button(action: {
                    Task {
                        await viewModel.retryInitialization()
                    }
                }) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.callout.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.8))
                        )
                }
                .opacity(showRetryButton ? 1 : 0)
                .scaleEffect(showRetryButton ? 1 : 0.8)
                
                #if DEBUG
                Button(action: {
                    viewModel.skipInitialization()
                }) {
                    Label("Continue Anyway", systemImage: "chevron.right")
                        .font(.callout)
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                #endif
            }
            .padding(.top, 10)
        }
        .padding(.bottom, 60)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.3)) {
                showRetryButton = true
            }
        }
        .onDisappear {
            showRetryButton = false
        }
    }
    
    // MARK: - Helper Methods
    
    private func animateLogoAppearance() {
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
    }
    
    private func startInitialization() {
        Task {
            // Small delay for UI to settle
            try? await Task.sleep(nanoseconds: 500_000_000)
            await viewModel.startInitialization()
        }
    }
}

// MARK: - Custom Progress View Style

struct CustomProgressViewStyle: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
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
                                colors: progressColors(for: progress),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * CGFloat(progress))
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                        .shadow(color: progressShadowColor(for: progress), radius: 4)
                }
            }
        }
    }
    
    private func progressColors(for progress: Double) -> [Color] {
        if progress < 0.3 {
            return [.blue, .cyan]
        } else if progress < 0.7 {
            return [.cyan, .green]
        } else if progress < 0.95 {
            return [.green, .mint]
        } else {
            return [.mint, .green]
        }
    }
    
    private func progressShadowColor(for progress: Double) -> Color {
        if progress < 0.3 {
            return .blue.opacity(0.5)
        } else if progress < 0.7 {
            return .cyan.opacity(0.5)
        } else {
            return .green.opacity(0.5)
        }
    }
}

// MARK: - Preview

struct InitializationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            InitializationView(viewModel: {
                let vm = InitializationViewModel()
                vm.progress = 0.45
                vm.currentStep = "Loading buildings..."
                return vm
            }())
            .previewDisplayName("Loading")
            
            // Error state
            InitializationView(viewModel: {
                let vm = InitializationViewModel()
                vm.initializationError = "Failed to connect to database.\n\nTap to retry (1/3)"
                return vm
            }())
            .previewDisplayName("Error")
        }
        .preferredColorScheme(.dark)
    }
}
