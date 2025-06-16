//
//  MapInteractionHint.swift
//  FrancoSphere
//
//  ✅ SINGLE MapInteractionHint implementation
//  ✅ No duplicates or conflicts
//  ✅ Phase-2 compliant with swipe-up gesture hint
//

import SwiftUI

struct MapInteractionHint: View {
    @Binding var showHint: Bool
    let hasSeenHint: Bool
    
    // MARK: - State
    @State private var opacity: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var autoHideTimer: Timer?
    
    // MARK: - Animation Constants
    private let animationDuration: Double = 0.5
    private let autoHideDuration: Double = 5.0
    private let pulseDuration: Double = 2.0
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            // Hint content
            VStack(spacing: 12) {
                // Drag handle with pulse animation
                dragHandle
                
                // Hint text with icon
                hintContent
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.bottom, 40) // Safe area padding
        }
        .opacity(opacity)
        .scaleEffect(pulseScale)
        .animation(.easeOut(duration: animationDuration), value: opacity)
        .animation(
            hasSeenHint ? .none : .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true),
            value: pulseScale
        )
        .onAppear {
            startHintSequence()
        }
        .onDisappear {
            stopAutoHideTimer()
        }
    }
    
    // MARK: - Drag Handle
    
    private var dragHandle: some View {
        VStack(spacing: 8) {
            // Swipe up chevron
            Image(systemName: "chevron.up")
                .font(.title2)
                .foregroundColor(.white.opacity(0.6))
                .scaleEffect(hasSeenHint ? 1.0 : pulseScale)
            
            // Handle bar
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
    
    // MARK: - Hint Content
    
    private var hintContent: some View {
        VStack(spacing: 8) {
            Text("Swipe up to view map")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Text("See all buildings and navigate")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Animation Methods
    
    private func startHintSequence() {
        // Fade in
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 1.0
        }
        
        // Start pulse animation for first-time users
        if !hasSeenHint {
            withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                pulseScale = 1.05
            }
        }
        
        // Auto-hide after delay
        startAutoHideTimer()
    }
    
    private func startAutoHideTimer() {
        stopAutoHideTimer() // Clear any existing timer
        
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: autoHideDuration, repeats: false) { _ in
            hideHint()
        }
    }
    
    private func stopAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }
    
    private func hideHint() {
        stopAutoHideTimer()
        
        withAnimation(.easeOut(duration: animationDuration)) {
            opacity = 0.0
            pulseScale = 1.0
        }
        
        // Delay hiding the binding to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            showHint = false
            
            // Mark as seen in UserDefaults
            UserDefaults.standard.set(true, forKey: "hasSeenMapHint")
        }
    }
}

// MARK: - Convenience Extensions

extension MapInteractionHint {
    /// Create a MapInteractionHint with automatic UserDefaults handling
    static func withUserDefaults(showHint: Binding<Bool>) -> some View {
        let hasSeenHint = UserDefaults.standard.bool(forKey: "hasSeenMapHint")
        return MapInteractionHint(showHint: showHint, hasSeenHint: hasSeenHint)
    }
    
    /// Force show hint (useful for testing or tutorials)
    static func forceShow(showHint: Binding<Bool>) -> some View {
        return MapInteractionHint(showHint: showHint, hasSeenHint: false)
    }
}

// MARK: - User Defaults Helper

extension UserDefaults {
    /// Check if the user has seen the map interaction hint
    var hasSeenMapHint: Bool {
        get { bool(forKey: "hasSeenMapHint") }
        set { set(newValue, forKey: "hasSeenMapHint") }
    }
    
    /// Reset the map hint for testing purposes
    func resetMapHint() {
        removeObject(forKey: "hasSeenMapHint")
    }
    
    /// Reset all map-related hints
    func resetAllMapHints() {
        removeObject(forKey: "hasSeenMapHint")
        // Add other map-related hint keys here as needed
    }
}

// MARK: - Preview Provider

struct MapInteractionHint_Previews: PreviewProvider {
    @State static var showFirstTimeHint = true
    @State static var showReturningUserHint = true
    
    static var previews: some View {
        // First-time user preview (with pulse animation)
        ZStack {
            // Mock map background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            // Mock map content
            VStack {
                HStack {
                    Spacer()
                    Text("Map View")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                }
                Spacer()
            }
            .padding()
            
            // First-time user hint (with pulse)
            if showFirstTimeHint {
                MapInteractionHint(
                    showHint: $showFirstTimeHint,
                    hasSeenHint: false
                )
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("First Time User")
        
        // Returning user preview (no pulse)
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.8), Color.blue.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
            
            if showReturningUserHint {
                MapInteractionHint(
                    showHint: $showReturningUserHint,
                    hasSeenHint: true
                )
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Returning User")
        
        // Interactive demo
        ZStack {
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Map Interaction Hint Demo")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Button("Show First-Time Hint") {
                    UserDefaults.standard.resetMapHint()
                    showFirstTimeHint = true
                }
                .foregroundColor(.blue)
                
                Button("Show Returning User Hint") {
                    UserDefaults.standard.hasSeenMapHint = true
                    showReturningUserHint = true
                }
                .foregroundColor(.green)
                
                Button("Reset UserDefaults") {
                    UserDefaults.standard.resetMapHint()
                }
                .foregroundColor(.orange)
                
                Text("Hint will auto-hide after 5 seconds")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            
            // Demo hints
            if showFirstTimeHint {
                MapInteractionHint(
                    showHint: $showFirstTimeHint,
                    hasSeenHint: false
                )
            }
            
            if showReturningUserHint {
                MapInteractionHint(
                    showHint: $showReturningUserHint,
                    hasSeenHint: true
                )
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Interactive Demo")
    }
}
