//
//  GlassTransitions.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: All animation syntax errors resolved
//  ✅ ALIGNED: Updated for v6.0 architecture with modern SwiftUI patterns
//  ✅ OPTIMIZED: Clean glass animation system for three-dashboard experience
//

import SwiftUI

// MARK: - Glass Transitions System
struct GlassTransitions {
    
    // MARK: - Standard Animations
    static let spring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let gentle = Animation.easeInOut(duration: 0.4)
    static let quick = Animation.easeOut(duration: 0.2)
    static let smooth = Animation.interpolatingSpring(stiffness: 300, damping: 30)
    
    // MARK: - Card Animations
    static let cardAppear = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let cardDismiss = Animation.easeIn(duration: 0.3)
    static let cardHover = Animation.spring(response: 0.3, dampingFraction: 0.6)
    
    // MARK: - Page Transitions
    static let pageSlide = Animation.spring(response: 0.5, dampingFraction: 0.75)
    static let modalPresent = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let modalDismiss = Animation.spring(response: 0.4, dampingFraction: 0.9)
    
    // MARK: - Micro-interactions
    static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.8)
    static let toggle = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    static let heartbeat = Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)
    
    // MARK: - Dashboard Transitions (v6.0 Three-Dashboard Support)
    static let dashboardSwitch = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let propertyCardUpdate = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let metricsRefresh = Animation.easeInOut(duration: 0.6)
}

// MARK: - Custom Transition Effects
extension AnyTransition {
    static var glassSlideUp: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity.combined(with: .scale(scale: 0.9))),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }
    
    static var glassSlideDown: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity.combined(with: .scale(scale: 0.9))),
            removal: .move(edge: .top).combined(with: .opacity)
        )
    }
    
    static var glassScale: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
    
    static var glassFade: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity.combined(with: .scale(scale: 1.05))
        )
    }
    
    static var glassSlideFromLeading: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        )
    }
    
    static var glassSlideFromTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: - Dashboard-Specific Transitions
    static var dashboardTransition: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    static var propertyCardTransition: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        )
    }
}

// MARK: - Animated Glass Card
struct AnimatedGlassCard<Content: View>: View {
    let content: Content
    let intensity: GlassIntensity
    let animateOnAppear: Bool
    
    @State private var isVisible = false
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0
    
    init(
        intensity: GlassIntensity = .regular,
        animateOnAppear: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.intensity = intensity
        self.animateOnAppear = animateOnAppear
    }
    
    var body: some View {
        GlassCard(intensity: intensity) {
            content
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            if animateOnAppear {
                withAnimation(GlassTransitions.cardAppear.delay(0.1)) {
                    scale = 1.0
                    opacity = 1.0
                    isVisible = true
                }
            } else {
                scale = 1.0
                opacity = 1.0
                isVisible = true
            }
        }
    }
}

// MARK: - Staggered Animation Container
struct StaggeredGlassContainer<Content: View>: View {
    let content: Content
    let staggerDelay: Double
    
    @State private var isVisible = false
    
    init(staggerDelay: Double = 0.1, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.staggerDelay = staggerDelay
    }
    
    var body: some View {
        VStack(spacing: 20) {
            content
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Parallax Effect
struct ParallaxView<Content: View>: View {
    let content: Content
    let speed: CGFloat
    
    @State private var offset: CGFloat = 0
    
    init(speed: CGFloat = 0.5, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.speed = speed
    }
    
    var body: some View {
        GeometryReader { geometry in
            content
                .offset(y: offset)
                .onAppear {
                    // Simple parallax simulation
                    offset = geometry.frame(in: .global).minY * speed
                }
        }
    }
}

// MARK: - Floating Animation
struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    let amplitude: CGFloat
    let duration: Double
    
    init(amplitude: CGFloat = 10, duration: Double = 3.0) {
        self.amplitude = amplitude
        self.duration = duration
    }
    
    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? amplitude : 0)
            .animation(
                Animation.easeInOut(duration: duration).repeatForever(autoreverses: true),
                value: isFloating
            )
            .onAppear {
                isFloating = true
            }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var isShimmering = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isShimmering ? 300 : -300)
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isShimmering
                    )
                    .mask(content)
            )
            .onAppear {
                isShimmering = true
            }
    }
}

// MARK: - Pulsing Glow Effect
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    @State private var isPulsing = false
    
    init(color: Color = .blue) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(isPulsing ? 0.3 : 0.1))
                    .blur(radius: isPulsing ? 10 : 5)
                    .animation(GlassTransitions.pulse, value: isPulsing)
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - PropertyCard Live Update Animation (v6.0 Feature)
struct PropertyCardUpdateModifier: ViewModifier {
    @State private var isUpdating = false
    let updateTrigger: Bool
    
    init(updateTrigger: Bool) {
        self.updateTrigger = updateTrigger
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isUpdating ? 1.02 : 1.0)
            .animation(GlassTransitions.propertyCardUpdate, value: isUpdating)
            .onChange(of: updateTrigger) { _ in
                withAnimation(GlassTransitions.propertyCardUpdate) {
                    isUpdating = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(GlassTransitions.propertyCardUpdate) {
                        isUpdating = false
                    }
                }
            }
    }
}

// MARK: - Dashboard Switch Animation (v6.0 Feature)
struct DashboardSwitchModifier: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? 1.0 : 0.95)
            .opacity(isActive ? 1.0 : 0.7)
            .animation(GlassTransitions.dashboardSwitch, value: isActive)
    }
}

// MARK: - View Extensions
extension View {
    func animatedGlassAppear(delay: Double = 0) -> some View {
        self.modifier(AnimatedGlassAppearModifier(delay: delay))
    }
    
    func floating(amplitude: CGFloat = 10, duration: Double = 3.0) -> some View {
        self.modifier(FloatingModifier(amplitude: amplitude, duration: duration))
    }
    
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
    
    func pulsingGlow(color: Color = .blue) -> some View {
        self.modifier(PulsingGlowModifier(color: color))
    }
    
    func glassHover() -> some View {
        self.modifier(GlassHoverModifier())
    }
    
    // MARK: - v6.0 Dashboard Extensions
    func propertyCardUpdate(trigger: Bool) -> some View {
        self.modifier(PropertyCardUpdateModifier(updateTrigger: trigger))
    }
    
    func dashboardActive(_ isActive: Bool) -> some View {
        self.modifier(DashboardSwitchModifier(isActive: isActive))
    }
}

// MARK: - Animated Glass Appear Modifier
struct AnimatedGlassAppearModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false
    
    init(delay: Double) {
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isVisible ? 1.0 : 0.8)
            .opacity(isVisible ? 1.0 : 0)
            .blur(radius: isVisible ? 0 : 10)
            .onAppear {
                withAnimation(GlassTransitions.cardAppear.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

// MARK: - Glass Hover Modifier
struct GlassHoverModifier: ViewModifier {
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.3 : 0.2), radius: isHovered ? 15 : 8)
            .animation(GlassTransitions.cardHover, value: isHovered)
            .onTapGesture {
                // iOS doesn't have onHover, use tap for interaction
                withAnimation(GlassTransitions.buttonPress) {
                    isHovered.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(GlassTransitions.buttonPress) {
                        isHovered = false
                    }
                }
            }
    }
}

// MARK: - Loading States
struct GlassLoadingState: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Success Checkmark Animation
struct GlassSuccessCheckmark: View {
    @State private var isVisible = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(isVisible ? 1.0 : 0.1)
                .animation(GlassTransitions.spring.delay(0.1), value: isVisible)
            
            Image(systemName: "checkmark")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .scaleEffect(isVisible ? 1.0 : 0.1)
                .animation(GlassTransitions.spring.delay(0.3), value: isVisible)
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Live Metrics Update Animation (v6.0 Feature)
struct LiveMetricsUpdateView: View {
    @State private var isUpdating = false
    let metricsChanged: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.clockwise")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .rotationEffect(.degrees(isUpdating ? 360 : 0))
                .animation(
                    isUpdating ?
                    Animation.linear(duration: 1.0).repeatForever(autoreverses: false) :
                    .default,
                    value: isUpdating
                )
            
            Text("Live")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .onChange(of: metricsChanged) { _ in
            withAnimation {
                isUpdating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    isUpdating = false
                }
            }
        }
    }
}

// MARK: - Preview
struct GlassTransitions_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    AnimatedGlassCard {
                        VStack {
                            Text("v6.0 Glass System")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            GlassLoadingState()
                            
                            LiveMetricsUpdateView(metricsChanged: true)
                        }
                        .padding()
                    }
                    
                    GlassCard {
                        Text("PropertyCard Update")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .propertyCardUpdate(trigger: true)
                    
                    GlassCard {
                        Text("Dashboard Active")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                    }
                    .dashboardActive(true)
                    
                    GlassSuccessCheckmark()
                }
                .padding()
            }
        }
    }
}
