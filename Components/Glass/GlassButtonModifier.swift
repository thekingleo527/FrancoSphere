//
//  GlassButtonModifier.swift
//  FrancoSphere
//
//  Glass button view modifier for quick button styling
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Glass Button View Modifier
struct GlassButtonModifier: ViewModifier {
    var style: ButtonGlassStyle
    var size: ButtonGlassSize
    
    init(style: ButtonGlassStyle = .secondary, size: ButtonGlassSize = .medium) {
        self.style = style
        self.size = size
    }
    
    func body(content: Content) -> some View {
        content
            .font(size.font)
            .foregroundColor(style.textColor)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                ZStack {
                    // Glass background
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(.ultraThinMaterial)
                        .opacity(style.backgroundOpacity)
                    
                    // Color overlay
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .fill(style.backgroundColor)
                        .opacity(style.colorOpacity)
                    
                    // Border
                    RoundedRectangle(cornerRadius: size.cornerRadius)
                        .stroke(style.borderColor, lineWidth: 1)
                        .opacity(style.borderOpacity)
                }
            )
            .scaleEffect(1.0)
            .animation(AnimationAnimation.easeInOut(duration: 0.15), value: UUID())
    }
}

// MARK: - Button Style Enums
enum ButtonGlassStyle {
    case primary
    case secondary
    case ghost
    case danger
    case success
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .white
        case .ghost: return .clear
        case .danger: return .red
        case .success: return .green
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .white
        case .ghost: return .white
        case .danger: return .white
        case .success: return .white
        }
    }
    
    var backgroundOpacity: Double {
        switch self {
        case .primary: return 0.3
        case .secondary: return 0.2
        case .ghost: return 0.1
        case .danger: return 0.3
        case .success: return 0.3
        }
    }
    
    var colorOpacity: Double {
        switch self {
        case .primary: return 0.3
        case .secondary: return 0.1
        case .ghost: return 0
        case .danger: return 0.3
        case .success: return 0.3
        }
    }
    
    var borderColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return .white
        case .ghost: return .white
        case .danger: return .red
        case .success: return .green
        }
    }
    
    var borderOpacity: Double {
        switch self {
        case .primary: return 0.5
        case .secondary: return 0.3
        case .ghost: return 0.2
        case .danger: return 0.5
        case .success: return 0.5
        }
    }
}

enum ButtonGlassSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small: return .caption
        case .medium: return .subheadline
        case .large: return .headline
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 12
        case .medium: return 16
        case .large: return 20
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 12
        }
    }
}

// MARK: - View Extension
extension View {
    /// Apply glass button styling to any view
    func glassButton(
        style: ButtonGlassStyle = .secondary,
        size: ButtonGlassSize = .medium
    ) -> some View {
        modifier(GlassButtonModifier(style: style, size: size))
    }
}

// MARK: - Fix for foregroundColor on Button
extension Button {
    func glassButtonWithColor() -> some View {
        self.buttonStyle(PlainButtonStyle())
            .glassButton()
    }
}

// MARK: - Convenience Button Extensions
extension Button where Label == Text {
    /// Create a glass-styled button with text
    static func glass(
        _ title: String,
        style: ButtonGlassStyle = .primary,
        size: ButtonGlassSize = .medium,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, action: action)
            .glassButton(style: style, size: size)
    }
}

// MARK: - Preview
struct GlassButtonModifier_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Dark background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Different styles
                Text("Glass Button Styles")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.bottom)
                
                Button("Primary Style") { }
                    .glassButton(style: .primary)
                
                Button("Secondary Style") { }
                    .glassButton(style: .secondary)
                
                Button("Ghost Style") { }
                    .glassButton(style: .ghost)
                
                Button("Danger Style") { }
                    .glassButton(style: .danger)
                
                Button("Success Style") { }
                    .glassButton(style: .success)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical)
                
                // Different sizes
                Text("Glass Button Sizes")
                    .font(.title3)
                    .foregroundColor(.white)
                
                HStack(spacing: 16) {
                    Button("Small") { }
                        .glassButton(size: .small)
                    
                    Button("Medium") { }
                        .glassButton(size: .medium)
                    
                    Button("Large") { }
                        .glassButton(size: .large)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical)
                
                // Custom combinations
                Text("Custom Combinations")
                    .font(.title3)
                    .foregroundColor(.white)
                
                Button("View Map") { }
                    .glassButton(style: .ghost, size: .small)
                
                Button("Optimize Route") { }
                    .glassButton(style: .primary, size: .large)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
