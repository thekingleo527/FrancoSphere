//
//  GlassDeckContainer 2.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//  GlassDeckContainer.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//  Updated: Added tap-to-reveal, return chevron, and first-use hint

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct GlassDeckContainer<Content: View, MapContent: View>: View {
    @State private var deckState: DeckState = .stacked
    @State private var dragOffset: CGSize = .zero
    @GestureState private var isLongPressing: Bool = false
    @State private var showFirstUseHint = false
    @State private var hasRevealedOnce = false
    @State private var isVerticalScrollDisabled = false
    
    let content: () -> Content
    let mapContent: () -> MapContent
    let onStateChange: ((DeckState) -> Void)?
    
    private let screenWidth = UIScreen.main.bounds.width
    private let hapticImpact = UIImpactFeedbackGenerator(style: .medium)
    
    enum DeckState: Equatable {
        case stacked
        case revealing(progress: Double)
        case revealed
        
        var mapBlur: Double {
            switch self {
            case .stacked: return 8
            case .revealing(let progress): return 8 * (1 - progress)
            case .revealed: return 0
            }
        }
        
        var deckScale: Double {
            switch self {
            case .stacked: return 1.0
            case .revealing(let progress): return 1.0 - (progress * 0.05)
            case .revealed: return 0.95
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background map with tap gesture (P0-1a)
            mapContent()
                .blur(radius: deckState.mapBlur)
                .scaleEffect(deckState == .revealed ? 1.05 : 1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: deckState)
                .allowsHitTesting(true) // Always allow hit testing for tap
                .contentShape(Rectangle()) // Ensure full area is tappable
                .onTapGesture {
                    if deckState == .stacked {
                        revealMap()
                    }
                }
                .accessibilityIdentifier("blurred-map-background") // For UI tests (P0-1e)
            
            // Glass card deck
            content()
                .offset(x: currentOffset)
                .scaleEffect(deckState.deckScale)
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.5
                )
                .shadow(
                    color: .black.opacity(shadowOpacity),
                    radius: 20,
                    x: -10,
                    y: 0
                )
                .allowsHitTesting(deckState != .revealed)
                .simultaneousGesture(twoFingerTapGesture) // P0-1a: Two-finger tap
                .gesture(mapRevealGesture)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
                .disabled(isVerticalScrollDisabled) // P0-1b: Prevent conflicts
            
            // Visual hint overlay when long pressing
            if isLongPressing && deckState == .stacked {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Swipe to reveal map")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                        Spacer()
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut, value: isLongPressing)
            }
            
            // Return chevron (P0-1c)
            if deckState == .revealed {
                returnChevronOverlay
                    .transition(.opacity.combined(with: .move(edge: .leading)))
                    .animation(.spring(response: 0.4), value: deckState)
            }
            
            // First-use hint (P0-1d)
            if showFirstUseHint && !hasRevealedOnce && deckState == .stacked {
                firstUseHintOverlay
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.5), value: showFirstUseHint)
            }
        }
        .onChange(of: deckState) { _, newState in
            onStateChange?(newState)
            if case .revealed = newState {
                hapticImpact.impactOccurred()
                hasRevealedOnce = true
                showFirstUseHint = false
            }
        }
        .onAppear {
            // Show hint after 3 seconds (P0-1d)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                if !hasRevealedOnce {
                    withAnimation {
                        showFirstUseHint = true
                    }
                }
            }
        }
    }
    
    // MARK: - P0-1a: Two-finger tap gesture
    private var twoFingerTapGesture: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                if deckState == .stacked {
                    revealMap()
                }
            }
    }
    
    // MARK: - P0-1c: Return chevron
    private var returnChevronOverlay: some View {
        VStack {
            HStack {
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        deckState = .stacked
                        dragOffset = .zero
                    }
                    hapticImpact.impactOccurred(intensity: 0.7)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.3),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .accessibilityIdentifier("return-chevron") // For UI tests
                .padding(.leading, 20)
                .padding(.top, 60) // Below status bar
                
                Spacer()
            }
            Spacer()
        }
    }
    
    // MARK: - P0-1d: First-use hint
    private var firstUseHintOverlay: some View {
        VStack {
            Spacer()
                .frame(height: 180)
            
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // Tap icon
                        VStack(spacing: 4) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Tap")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("or")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                        
                        // Swipe icon
                        VStack(spacing: 4) {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                            Text("Swipe")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    Text("to view map")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.8))
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                                .opacity(0.3)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                .scaleEffect(showFirstUseHint ? 1 : 0.9)
                .opacity(showFirstUseHint ? 1 : 0)
                
                Spacer()
            }
            .padding(.trailing, 30)
            
            Spacer()
        }
        .allowsHitTesting(false) // Don't block interactions
    }
    
    private func revealMap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            deckState = .revealed
            dragOffset = CGSize(width: screenWidth * 1.1, height: 0)
        }
        hapticImpact.impactOccurred()
        hasRevealedOnce = true
        showFirstUseHint = false
    }
    
    private var currentOffset: CGFloat {
        switch deckState {
        case .stacked:
            return dragOffset.width
        case .revealing:
            return dragOffset.width
        case .revealed:
            return screenWidth * 1.1
        }
    }
    
    private var rotationAngle: Double {
        let progress = min(max(dragOffset.width / screenWidth, 0), 1)
        return Double(progress * 10)
    }
    
    private var shadowOpacity: Double {
        let progress = min(max(dragOffset.width / screenWidth, 0), 1)
        return 0.3 * (1 - progress)
    }
    
    // P0-1b: Enhanced gesture with drag conflict guard
    private var mapRevealGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .updating($isLongPressing) { currentState, gestureState, _ in
                gestureState = currentState
            }
            .sequenced(before: DragGesture())
            .onChanged { value in
                switch value {
                case .second(true, let drag?):
                    // P0-1b: Disable vertical scroll if horizontal drag > 8pt
                    if abs(drag.translation.width) > 8 {
                        isVerticalScrollDisabled = true
                    }
                    
                    // Only respond to rightward drags
                    if drag.translation.width > 0 {
                        dragOffset = drag.translation
                        
                        // Update revealing state
                        let progress = min(max(drag.translation.width / screenWidth, 0), 1)
                        if progress > 0.05 && progress < 0.95 {
                            deckState = .revealing(progress: Double(progress))
                        }
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                isVerticalScrollDisabled = false // Re-enable scrolling
                
                switch value {
                case .second(true, let drag?):
                    handleSwipeEnd(drag)
                default:
                    withAnimation(.spring()) {
                        dragOffset = .zero
                        deckState = .stacked
                    }
                }
            }
    }
    
    private func handleSwipeEnd(_ drag: DragGesture.Value) {
        let threshold = screenWidth * 0.3
        let velocity = drag.predictedEndLocation.x - drag.location.x
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if drag.translation.width > threshold || velocity > 100 {
                // Reveal map
                revealMap()
            } else {
                // Return to stacked
                deckState = .stacked
                dragOffset = .zero
            }
        }
    }
}