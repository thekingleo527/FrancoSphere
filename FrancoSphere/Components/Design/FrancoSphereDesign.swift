//
//  FrancoSphereDesign.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Animation naming conflicts resolved
//  ✅ FIXED: Animation typo corrected
//  ✅ ENHANCED: Aligned with v6.0 three-dashboard system
//  ✅ INTEGRATED: Actor-compatible design patterns
//

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
        
        // Dashboard-specific spacing (NEW for v6.0)
        static let dashboardSectionSpacing: CGFloat = 32
        static let propertyCardSpacing: CGFloat = 16
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
        
        // PropertyCard specific (NEW for v6.0)
        static let propertyCard: CGFloat = 16
        static let glassCard: CGFloat = 20
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let sm = ShadowStyle(radius: 5, x: 0, y: 2)
        static let md = ShadowStyle(radius: 10, x: 0, y: 5)
        static let lg = ShadowStyle(radius: 20, x: 0, y: 10)
        static let xl = ShadowStyle(radius: 30, x: 0, y: 15)
        
        // PropertyCard shadows (NEW for v6.0)
        static let propertyCard = ShadowStyle(radius: 8, x: 0, y: 4)
        static let glassCard = ShadowStyle(radius: 12, x: 0, y: 6)
        
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
        
        // Dashboard-specific typography (NEW for v6.0)
        static let dashboardTitle = FontStyle(size: 24, weight: .bold, design: .rounded)
        static let propertyCardTitle = FontStyle(size: 16, weight: .semibold, design: .rounded)
        static let metricsValue = FontStyle(size: 20, weight: .bold, design: .rounded)
        static let metricsLabel = FontStyle(size: 12, weight: .medium, design: .rounded)
        
        struct FontStyle {
            let size: CGFloat
            let weight: Font.Weight
            let design: Font.Design
            
            var font: Font {
                Font.system(size: size, weight: weight, design: design)
            }
        }
    }
    
    // MARK: - Animations (FIXED naming conflict)
    enum Animations {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.2)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.3)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.4)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.8)
        static let bouncy: SwiftUI.Animation = .spring(response: 0.5, dampingFraction: 0.7)
        
        // PropertyCard animations (NEW for v6.0)
        static let propertyCardHover: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.6)
        static let dashboardTransition: SwiftUI.Animation = .spring(response: 0.6, dampingFraction: 0.8)
        static let metricsUpdate: SwiftUI.Animation = .easeInOut(duration: 0.5)
    }
    
    // MARK: - Blur
    enum Blur {
        static let ultraLight: CGFloat = 10
        static let light: CGFloat = 20
        static let medium: CGFloat = 30
        static let heavy: CGFloat = 40
        static let ultraHeavy: CGFloat = 50
        
        // Dashboard-specific blur (NEW for v6.0)
        static let dashboardBackground: CGFloat = 25
        static let propertyCard: CGFloat = 15
    }
    
    // MARK: - Glass Properties (ENHANCED for v6.0)
    enum Glass {
        static let backgroundOpacity: Double = 0.7
        static let borderOpacity: Double = 0.3
        static let gradientOpacity: Double = 0.15
        static let shadowOpacity: Double = 0.2
        
        // Dashboard-specific glass properties
        static let dashboardCardOpacity: Double = 0.8
        static let propertyCardOpacity: Double = 0.75
        static let headerOpacity: Double = 0.9
    }
    
    // MARK: - Dashboard Colors (NEW for v6.0)
    enum DashboardColors {
        // Worker Dashboard
        static let workerPrimary = Color.blue
        static let workerSecondary = Color.blue.opacity(0.7)
        static let workerAccent = Color.cyan
        
        // Admin Dashboard
        static let adminPrimary = Color.purple
        static let adminSecondary = Color.purple.opacity(0.7)
        static let adminAccent = Color.pink
        
        // Client Dashboard
        static let clientPrimary = Color.green
        static let clientSecondary = Color.green.opacity(0.7)
        static let clientAccent = Color.mint
        
        // Status Colors
        static let compliant = Color.green
        static let warning = Color.orange
        static let critical = Color.red
        static let inactive = Color.gray
    }
    
    // MARK: - Metrics Display (NEW for v6.0)
    enum MetricsDisplay {
        static let progressBarHeight: CGFloat = 6
        static let progressBarCornerRadius: CGFloat = 3
        static let statusIndicatorSize: CGFloat = 8
        static let trendArrowSize: CGFloat = 12
    }
}

// MARK: - View Extensions (ENHANCED)
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
    
    // Property card padding (NEW for v6.0)
    func francoPropertyCardPadding() -> some View {
        self.padding(FrancoSphereDesign.Spacing.propertyCardSpacing)
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
    
    // Glass background - Enhanced for v6.0
    func francoGlassBackground(
        cornerRadius: CGFloat = FrancoSphereDesign.CornerRadius.xl,
        opacity: Double = FrancoSphereDesign.Glass.backgroundOpacity
    ) -> some View {
        self.background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)
                .opacity(opacity)
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
    
    // PropertyCard glass background (NEW for v6.0)
    func francoPropertyCardBackground() -> some View {
        self.francoGlassBackground(
            cornerRadius: FrancoSphereDesign.CornerRadius.propertyCard,
            opacity: FrancoSphereDesign.Glass.propertyCardOpacity
        )
    }
    
    // Dashboard role-specific styling (NEW for v6.0)
    func francoDashboardStyle(for role: DashboardRole) -> some View {
        self.foregroundColor(role.primaryColor)
    }
}

// MARK: - Animation Modifiers (FIXED)
extension View {
    func francoAnimation<V: Equatable>(_ animation: SwiftUI.Animation = FrancoSphereDesign.Animations.standard, value: V) -> some View {
        self.animation(animation, value: value)
    }
    
    // Property card hover animation (NEW for v6.0)
    func francoPropertyCardAnimation<V: Equatable>(value: V) -> some View {
        self.animation(FrancoSphereDesign.Animations.propertyCardHover, value: value)
    }
    
    // Dashboard transition animation (NEW for v6.0)
    func francoDashboardTransition<V: Equatable>(value: V) -> some View {
        self.animation(FrancoSphereDesign.Animations.dashboardTransition, value: value)
    }
}

// MARK: - Dashboard Role Support (NEW for v6.0)
enum DashboardRole: String, CaseIterable {
    case worker = "worker"
    case admin = "admin"
    case client = "client"
    
    var displayName: String {
        switch self {
        case .worker: return "Worker"
        case .admin: return "Admin"
        case .client: return "Client"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .worker: return FrancoSphereDesign.DashboardColors.workerPrimary
        case .admin: return FrancoSphereDesign.DashboardColors.adminPrimary
        case .client: return FrancoSphereDesign.DashboardColors.clientPrimary
        }
    }
    
    var secondaryColor: Color {
        switch self {
        case .worker: return FrancoSphereDesign.DashboardColors.workerSecondary
        case .admin: return FrancoSphereDesign.DashboardColors.adminSecondary
        case .client: return FrancoSphereDesign.DashboardColors.clientSecondary
        }
    }
    
    var accentColor: Color {
        switch self {
        case .worker: return FrancoSphereDesign.DashboardColors.workerAccent
        case .admin: return FrancoSphereDesign.DashboardColors.adminAccent
        case .client: return FrancoSphereDesign.DashboardColors.clientAccent
        }
    }
}

// MARK: - Safe Area Helper (UNCHANGED)
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

// MARK: - Loading State (ENHANCED for v6.0)
struct FrancoLoadingView: View {
    let message: String
    let role: DashboardRole?
    
    init(message: String = "Loading...", role: DashboardRole? = nil) {
        self.message = message
        self.role = role
    }
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: role?.primaryColor ?? .white))
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

// MARK: - Empty State (ENHANCED for v6.0)
struct FrancoEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    let role: DashboardRole?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil,
        role: DashboardRole? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
        self.role = role
    }
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor((role?.primaryColor ?? .white).opacity(0.6))
            
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
                        colors: [
                            role?.primaryColor ?? .blue,
                            (role?.primaryColor ?? .blue).opacity(0.8)
                        ],
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

// MARK: - Metrics Display Components (NEW for v6.0)
struct FrancoMetricsProgress: View {
    let value: Double
    let role: DashboardRole?
    
    var body: some View {
        ProgressView(value: value)
            .progressViewStyle(LinearProgressViewStyle(tint: role?.primaryColor ?? .blue))
            .frame(height: FrancoSphereDesign.MetricsDisplay.progressBarHeight)
            .cornerRadius(FrancoSphereDesign.MetricsDisplay.progressBarCornerRadius)
    }
}

struct FrancoStatusIndicator: View {
    let isActive: Bool
    let role: DashboardRole?
    
    var body: some View {
        Circle()
            .fill(isActive ? (role?.primaryColor ?? .green) : FrancoSphereDesign.DashboardColors.inactive)
            .frame(
                width: FrancoSphereDesign.MetricsDisplay.statusIndicatorSize,
                height: FrancoSphereDesign.MetricsDisplay.statusIndicatorSize
            )
    }
}

// MARK: - Preview Helpers (NEW for v6.0)
#Preview("Loading States") {
    VStack(spacing: 20) {
        FrancoLoadingView(message: "Loading worker data...", role: .worker)
        FrancoLoadingView(message: "Loading admin panel...", role: .admin)
        FrancoLoadingView(message: "Loading client reports...", role: .client)
    }
    .padding()
    .background(Color.black)
}

#Preview("Empty States") {
    VStack(spacing: 20) {
        FrancoEmptyState(
            icon: "building.2",
            title: "No Buildings Assigned",
            message: "You don't have any buildings assigned yet.",
            action: { print("Refresh tapped") },
            actionTitle: "Refresh",
            role: .worker
        )
    }
    .padding()
    .background(Color.black)
}

#Preview("Metrics Components") {
    VStack(spacing: 20) {
        FrancoMetricsProgress(value: 0.75, role: .worker)
        FrancoMetricsProgress(value: 0.45, role: .admin)
        FrancoMetricsProgress(value: 0.92, role: .client)
        
        HStack(spacing: 16) {
            FrancoStatusIndicator(isActive: true, role: .worker)
            FrancoStatusIndicator(isActive: false, role: .admin)
            FrancoStatusIndicator(isActive: true, role: .client)
        }
    }
    .padding()
    .background(Color.black)
}
