// FrancoSphereDesign.swift
// Central design system configuration for FrancoSphere
// Defines spacing, typography, animations, and design tokens

import SwiftUI

// MARK: - Design System
enum FrancoSphereDesign {
    
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        
        // Card spacing
        static let cardPadding: CGFloat = 20
        static let cardSpacing: CGFloat = 24
        
        // Navigation
        static let navBarHeight: CGFloat = 60
        static let tabBarHeight: CGFloat = 80
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let round: CGFloat = 9999
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let sm = ShadowStyle(radius: 5, x: 0, y: 2)
        static let md = ShadowStyle(radius: 10, x: 0, y: 5)
        static let lg = ShadowStyle(radius: 20, x: 0, y: 10)
        static let xl = ShadowStyle(radius: 30, x: 0, y: 15)
        
        struct ShadowStyle {
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
            let color: Color = .black.opacity(0.2)
        }
    }
    
    // MARK: - Typography
    enum Typography {
        // Headings
        static let largeTitle = FontStyle(size: 34, weight: .bold, design: .rounded)
        static let title = FontStyle(size: 28, weight: .bold, design: .rounded)
        static let title2 = FontStyle(size: 22, weight: .semibold, design: .rounded)
        static let title3 = FontStyle(size: 20, weight: .semibold, design: .rounded)
        
        // Body
        static let headline = FontStyle(size: 17, weight: .semibold, design: .rounded)
        static let body = FontStyle(size: 17, weight: .regular, design: .rounded)
        static let callout = FontStyle(size: 16, weight: .regular, design: .rounded)
        static let subheadline = FontStyle(size: 15, weight: .regular, design: .rounded)
        static let footnote = FontStyle(size: 13, weight: .regular, design: .rounded)
        
        // Captions
        static let caption = FontStyle(size: 12, weight: .regular, design: .rounded)
        static let caption2 = FontStyle(size: 11, weight: .regular, design: .rounded)
        
        struct FontStyle {
            let size: CGFloat
            let weight: Font.Weight
            let design: Font.Design
            
            var font: Font {
                Font.system(size: size, weight: weight, design: design)
            }
        }
    }
    
    // MARK: - Animation
    enum Animation {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.4)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.7)
    }
    
    // MARK: - Blur
    enum Blur {
        static let ultraLight: CGFloat = 10
        static let light: CGFloat = 20
        static let medium: CGFloat = 30
        static let heavy: CGFloat = 40
        static let ultraHeavy: CGFloat = 50
    }
    
    // MARK: - Glass Properties
    enum Glass {
        static let backgroundOpacity: Double = 0.7
        static let borderOpacity: Double = 0.3
        static let gradientOpacity: Double = 0.15
        static let shadowOpacity: Double = 0.2
    }
}

// MARK: - View Extensions
extension View {
    // Typography
    func francoTypography(_ style: FrancoSphereDesign.Typography.FontStyle) -> some View {
        self.font(style.font)
    }
    
    // Spacing
    func francoPadding(_ spacing: CGFloat = FrancoSphereDesign.Spacing.md) -> some View {
        self.padding(spacing)
    }
    
    // Card padding
    func francoCardPadding() -> some View {
        self.padding(FrancoSphereDesign.Spacing.cardPadding)
    }
    
    // Shadow
    func francoShadow(_ shadow: FrancoSphereDesign.Shadow.ShadowStyle = FrancoSphereDesign.Shadow.md) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
    
    // Corner radius
    func francoCornerRadius(_ radius: CGFloat = FrancoSphereDesign.CornerRadius.lg) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
    
    // Glass background - Fixed without GlassIntensity parameter
    func francoGlassBackground(
        cornerRadius: CGFloat = FrancoSphereDesign.CornerRadius.xl
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(FrancoSphereDesign.Glass.gradientOpacity),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            Color.white.opacity(FrancoSphereDesign.Glass.borderOpacity),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Animation Modifiers
extension View {
    func francoAnimation<V: Equatable>(_ animation: SwiftUI.Animation = FrancoSphereDesign.Animation.standard, value: V) -> some View {
        self.animation(animation, value: value)
    }
}

// MARK: - Safe Area Helper
struct SafeAreaHelper: ViewModifier {
    let edges: Edge.Set
    
    func body(content: Content) -> some View {
        content
            .padding(.top, edges.contains(.top) ? safeAreaInsets.top : 0)
            .padding(.bottom, edges.contains(.bottom) ? safeAreaInsets.bottom : 0)
            .padding(.leading, edges.contains(.leading) ? safeAreaInsets.leading : 0)
            .padding(.trailing, edges.contains(.trailing) ? safeAreaInsets.trailing : 0)
    }
    
    private var safeAreaInsets: EdgeInsets {
        let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
        let window = windowScene?.windows.first(where: { $0.isKeyWindow })
        let insets = window?.safeAreaInsets ?? UIEdgeInsets()
        return insets.toEdgeInsets()
    }
}

extension UIEdgeInsets {
    func toEdgeInsets() -> EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}

extension View {
    func francoSafeArea(_ edges: Edge.Set = .all) -> some View {
        self.modifier(SafeAreaHelper(edges: edges))
    }
}

// MARK: - Loading State
struct FrancoLoadingView: View {
    let message: String
    
    init(message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)
            
            Text(message)
                .francoTypography(FrancoSphereDesign.Typography.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .francoCardPadding()
        .francoGlassBackground()
        .francoShadow()
    }
}

// MARK: - Empty State
struct FrancoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.6))
            
            VStack(spacing: FrancoSphereDesign.Spacing.sm) {
                Text(title)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(.white)
                
                Text(message)
                    .francoTypography(FrancoSphereDesign.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            
            if let action = action, let actionTitle = actionTitle {
                // Simple button without GlassButton dependency
                Button(actionTitle) {
                    action()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
                .padding(.top, FrancoSphereDesign.Spacing.sm)
            }
        }
        .francoCardPadding()
        .frame(maxWidth: 400)
    }
}
