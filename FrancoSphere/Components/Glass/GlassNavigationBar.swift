//
//  GlassNavigationBar.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//
//  ✅ FIXED: Removed invalid @Environment property wrapper.
//

import SwiftUI

struct GlassNavigationBar<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let actions: () -> Content
    
    var showMapButton: Bool = false
    var onMapReveal: (() -> Void)? = nil
    
    // Access safe area insets through the environment
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    init(
        title: String,
        subtitle: String? = nil,
        showMapButton: Bool = false,
        onMapReveal: (() -> Void)? = nil,
        @ViewBuilder actions: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showMapButton = showMapButton
        self.onMapReveal = onMapReveal
        self.actions = actions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Spacer for the top safe area
            Color.clear
                .frame(height: safeAreaInsets.top)
            
            // The actual navigation bar content
            HStack(spacing: 16) {
                if showMapButton {
                    Button(action: {
                        onMapReveal?()
                    }) {
                        Image(systemName: "map.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                            )
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                actions()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            // Using a standard thin material for the glass effect
            .background(.thinMaterial)
        }
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Safe Area Environment Key (If not already defined elsewhere)
// This part is correct and is a standard way to get safe area values.
private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero).insets
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

private extension UIEdgeInsets {
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
