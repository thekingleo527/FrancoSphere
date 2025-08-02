//
//
//  StatCard.swift
//  FrancoSphere v6.0
//
//  ✅ UPDATED: Dark Elegance theme applied
//  ✅ ENHANCED: Glass morphism effects
//  ✅ ALIGNED: With FrancoSphereDesign system
//  ✅ IMPROVED: Trend indicators and animations
//  ✅ FIXED: Renamed to avoid redeclaration conflicts
//

import SwiftUI

// MARK: - Enhanced Stat Card (Renamed to avoid conflict)

struct EnhancedStatCard: View {
    let title: String
    let value: String
    let trend: String?
    let icon: String
    var color: Color = FrancoSphereDesign.DashboardColors.primaryAction
    var trendDirection: CoreTypes.TrendDirection? = nil
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.sm) {
            // Header row
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.25), lineWidth: 1)
                            )
                    )
                
                Spacer()
                
                if let trend = trend {
                    trendIndicator(trend)
                } else if let direction = trendDirection {
                    advancedTrendIndicator(direction)
                }
            }
            
            // Value
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.largeTitle)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            // Title
            Text(title)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                .lineLimit(2)
        }
        .francoCardPadding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.lg)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
        .francoShadow(FrancoSphereDesign.Shadow.sm)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(FrancoSphereDesign.Animations.quick, value: isPressed)
    }
    
    // Basic trend indicator (legacy support)
    private func trendIndicator(_ trend: String) -> some View {
        HStack(spacing: 4) {
            if trend.contains("↑") || trend.contains("up") {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.success)
            } else if trend.contains("↓") || trend.contains("down") {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
            } else {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            }
            
            Text(trend.replacingOccurrences(of: "↑", with: "")
                    .replacingOccurrences(of: "↓", with: "")
                    .trimmingCharacters(in: .whitespaces))
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
        .font(.caption)
    }
    
    // Advanced trend indicator using CoreTypes
    private func advancedTrendIndicator(_ direction: CoreTypes.TrendDirection) -> some View {
        HStack(spacing: 4) {
            Image(systemName: trendIcon(for: direction))
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.EnumColors.trendDirection(direction))
            
            Text(direction.rawValue.capitalized)
                .francoTypography(FrancoSphereDesign.Typography.caption2)
                .foregroundColor(FrancoSphereDesign.EnumColors.trendDirection(direction))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(FrancoSphereDesign.EnumColors.trendDirection(direction).opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(FrancoSphereDesign.EnumColors.trendDirection(direction).opacity(0.25), lineWidth: 1)
                )
        )
    }
    
    private func trendIcon(for direction: CoreTypes.TrendDirection) -> String {
        switch direction {
        case .up: return "arrow.up.circle.fill"
        case .down: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        case .improving: return "arrow.up.right.circle.fill"
        case .declining: return "arrow.down.right.circle.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Pressable Version

struct PressableStatCard: View {
    let title: String
    let value: String
    let trend: String?
    let icon: String
    var color: Color = FrancoSphereDesign.DashboardColors.primaryAction
    var trendDirection: CoreTypes.TrendDirection? = nil
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        EnhancedStatCard(
            title: title,
            value: value,
            trend: trend,
            icon: icon,
            color: color,
            trendDirection: trendDirection
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(FrancoSphereDesign.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(FrancoSphereDesign.Animations.quick) {
                    isPressed = false
                }
                onTap()
            }
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Compact Version for Dashboards

struct CompactStatCard: View {
    let title: String
    let value: String
    let icon: String
    var color: Color = FrancoSphereDesign.DashboardColors.primaryAction
    
    var body: some View {
        HStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(title)
                    .francoTypography(FrancoSphereDesign.Typography.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
        }
        .padding(FrancoSphereDesign.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.sm)
                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
        )
    }
}

// MARK: - Type Alias for Backward Compatibility
// If you have existing code using StatCard, you can uncomment this:
// typealias StatCard = EnhancedStatCard

// MARK: - Preview

struct StatCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Standard cards
            HStack(spacing: 16) {
                EnhancedStatCard(
                    title: "Total Buildings",
                    value: "24",
                    trend: "↑ 2",
                    icon: "building.2",
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                EnhancedStatCard(
                    title: "Completion Rate",
                    value: "87%",
                    trend: nil,
                    icon: "checkmark.circle",
                    color: FrancoSphereDesign.DashboardColors.success,
                    trendDirection: .up
                )
            }
            
            // Pressable version
            PressableStatCard(
                title: "Active Workers",
                value: "142",
                trend: "↓ 3",
                icon: "person.2",
                color: FrancoSphereDesign.DashboardColors.tertiaryAction
            ) {
                print("Tapped!")
            }
            
            // Compact versions
            VStack(spacing: 8) {
                CompactStatCard(
                    title: "Tasks Today",
                    value: "32",
                    icon: "checklist",
                    color: FrancoSphereDesign.DashboardColors.primaryAction
                )
                
                CompactStatCard(
                    title: "On Schedule",
                    value: "94%",
                    icon: "clock",
                    color: FrancoSphereDesign.DashboardColors.warning
                )
            }
        }
        .padding()
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
        .preferredColorScheme(.dark)
    }
}
