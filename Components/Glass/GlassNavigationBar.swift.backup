//
//  GlassNavigationBar.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/7/25.
//


// GlassNavigationBar.swift
// Enhanced glass navigation bar with clock state integration

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct GlassNavigationBar<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let actions: () -> Content
    
    // Map reveal button (simulator-friendly)
    var showMapButton: Bool = false
    var onMapReveal: (() -> Void)? = nil
    
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
            // Safe area top
            Color.clear
                .frame(height: safeAreaInsets.top)
            
            // Navigation content
            GlassCard(
                intensity: GlassIntensity.regular,
                cornerRadius: 0,
                padding: 0,
                shadowRadius: 5
            ) {
                HStack(spacing: 16) {
                    // Map reveal button (simulator-friendly)
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
                    
                    // Title section
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
                    
                    // Actions
                    actions()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
        }
    }
}

// Safe area environment key implementation
private struct SafeAreaInsetsKey: EnvironmentKey {
    static let defaultValue: EdgeInsets = EdgeInsets()
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}