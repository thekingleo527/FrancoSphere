//
//  GlassStatusBadge.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/6/25.
//

// GlassStatusBadge.swift
// Glassmorphism status badge component for FrancoSphere
// Used for task status, weather alerts, and various indicators

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

// MARK: - Badge Style
enum GlassBadgeStyle {
    case success
    case warning
    case danger
    case info
    case neutral
    case custom(color: Color)
    
    var color: Color {
        switch self {
        case .success:
            return .green
        case .warning:
            return .orange
        case .danger:
            return .red
        case .info:
            return .blue
        case .neutral:
            return .gray
        case .custom(let color):
            return color
        }
    }
}

// MARK: - Badge Size
enum GlassBadgeSize {
    case small
    case medium
    case large
    
    var padding: EdgeInsets {
        switch self {
        case .small:
            return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        case .medium:
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .large:
            return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        }
    }
    
    var fontSize: Font {
        switch self {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .footnote
        }
    }
    
    var iconSize: Font {
        switch self {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .body
        }
    }
}

// MARK: - Glass Status Badge
struct GlassStatusBadge: View {
    let text: String
    var icon: String?
    var style: GlassBadgeStyle
    var size: GlassBadgeSize
    var isPulsing: Bool
    
    @State private var pulseAnimation = false
    
    init(
        text: String,
        icon: String? = nil,
        style: GlassBadgeStyle = .info,
        size: GlassBadgeSize = .medium,
        isPulsing: Bool = false
    ) {
        self.text = text
        self.icon = icon
        self.style = style
        self.size = size
        self.isPulsing = isPulsing
    }
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(size.iconSize)
                    .fontWeight(.medium)
            }
            
            Text(text)
                .font(size.fontSize)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(size.padding)
        .background(badgeBackground)
        .clipShape(Capsule())
        .overlay(badgeOverlay)
        .scaleEffect(isPulsing && pulseAnimation ? 1.05 : 1.0)
        .animation(
            isPulsing ?
            Animation.easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true) :
            .default,
            value: pulseAnimation
        )
        .onAppear {
            if isPulsing {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Badge Background
    private var badgeBackground: some View {
        ZStack {
            // Color base
            Capsule()
                .fill(style.color.opacity(0.3))
            
            // Glass effect
            Capsule()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
            
            // Gradient overlay
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            style.color.opacity(0.2),
                            style.color.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Glow effect for pulsing
            if isPulsing {
                Capsule()
                    .stroke(style.color, lineWidth: 2)
                    .blur(radius: 4)
                    .opacity(pulseAnimation ? 0.6 : 0.3)
            }
        }
    }
    
    // MARK: - Badge Overlay
    private var badgeOverlay: some View {
        Capsule()
            .stroke(
                LinearGradient(
                    colors: [
                        style.color.opacity(0.5),
                        style.color.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - Glass Notification Badge
struct GlassNotificationBadge: View {
    let count: Int
    var style: GlassBadgeStyle
    var size: GlassBadgeSize
    
    init(
        count: Int,
        style: GlassBadgeStyle = .danger,
        size: GlassBadgeSize = .small
    ) {
        self.count = count
        self.style = style
        self.size = size
    }
    
    var body: some View {
        if count > 0 {
            Text(count > 99 ? "99+" : "\(count)")
                .font(size.fontSize)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(minWidth: 20)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(style.color)
                        .overlay(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .opacity(0.2)
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Glass Progress Badge
struct GlassProgressBadge: View {
    let progress: Double
    let total: Double
    var style: GlassBadgeStyle
    var size: GlassBadgeSize
    var showPercentage: Bool
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return (progress / total) * 100
    }
    
    private var progressColor: Color {
        if percentage >= 75 {
            return .green
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }
    
    init(
        progress: Double,
        total: Double,
        style: GlassBadgeStyle = .info,
        size: GlassBadgeSize = .medium,
        showPercentage: Bool = true
    ) {
        self.progress = progress
        self.total = total
        self.style = style
        self.size = size
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(percentage / 100, 1.0)))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
            }
            
            // Text
            if showPercentage {
                Text("\(Int(percentage))%")
                    .font(size.fontSize)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            } else {
                Text("\(Int(progress))/\(Int(total))")
                    .font(size.fontSize)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .padding(size.padding)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(progressColor.opacity(0.2))
                )
        )
        .overlay(
            Capsule()
                .stroke(progressColor.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Glass Loading Badge
struct GlassLoadingBadge: View {
    let text: String
    var size: GlassBadgeSize
    
    @State private var isAnimating = false
    
    init(
        text: String = "Loading",
        size: GlassBadgeSize = .medium
    ) {
        self.text = text
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.7)
            
            Text(text)
                .font(size.fontSize)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(size.padding)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(Color.blue.opacity(0.2))
                )
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(isAnimating ? 0.6 : 0.2),
                            Color.blue.opacity(isAnimating ? 0.2 : 0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func glassBadge(
        _ text: String,
        icon: String? = nil,
        style: GlassBadgeStyle = .info,
        size: GlassBadgeSize = .small
    ) -> some View {
        self.overlay(
            GlassStatusBadge(
                text: text,
                icon: icon,
                style: style,
                size: size
            ),
            alignment: .topTrailing
        )
    }
    
    func glassNotificationBadge(
        count: Int,
        style: GlassBadgeStyle = .danger
    ) -> some View {
        self.overlay(
            GlassNotificationBadge(
                count: count,
                style: style
            )
            .offset(x: 8, y: -8),
            alignment: .topTrailing
        )
    }
}

// MARK: - Preview Provider
struct GlassStatusBadge_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.1, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Status badges
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Status Badges")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            GlassStatusBadge(text: "Active", style: .success, size: .small)
                            GlassStatusBadge(text: "Pending", style: .warning, size: .small)
                            GlassStatusBadge(text: "Offline", style: .danger, size: .small)
                        }
                        
                        HStack(spacing: 12) {
                            GlassStatusBadge(text: "Onsite", icon: "location.fill", style: .success)
                            GlassStatusBadge(text: "5 Tasks", icon: "checklist", style: .info)
                            GlassStatusBadge(text: "High Priority", icon: "exclamationmark.triangle", style: .danger)
                        }
                        
                        HStack(spacing: 12) {
                            GlassStatusBadge(text: "Weather Alert", icon: "cloud.rain.fill", style: .warning, size: .large, isPulsing: true)
                            GlassStatusBadge(text: "Maintenance", style: .custom(color: .purple), size: .large)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Progress badges
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Progress Badges")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 12) {
                            GlassProgressBadge(progress: 8, total: 10)
                            GlassProgressBadge(progress: 5, total: 10)
                            GlassProgressBadge(progress: 2, total: 10)
                        }
                        
                        HStack(spacing: 12) {
                            GlassProgressBadge(progress: 15, total: 20, size: .large, showPercentage: false)
                            GlassLoadingBadge(text: "Syncing")
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Notification badges
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notification Badges")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack(spacing: 40) {
                            Image(systemName: "bell.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .glassNotificationBadge(count: 3)
                            
                            Image(systemName: "envelope.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .glassNotificationBadge(count: 12, style: .info)
                            
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .glassNotificationBadge(count: 1, style: .warning)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.3))
                    
                    // Badge on cards
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Badges on Cards")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        GlassCard(intensity: .regular) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("12 West 18th Street")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("5 active tasks")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                        }
                        .glassBadge("Onsite", icon: "location.fill", style: .success)
                        
                        GlassCard(intensity: .thin) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("HVAC Maintenance")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text("Due in 2 hours")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                            }
                        }
                        .glassBadge("Urgent", style: .danger, size: .large)
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
