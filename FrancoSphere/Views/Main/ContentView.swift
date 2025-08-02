//
//  ContentView.swift
//  FrancoSphere v6.0
//
//  ✅ FIXED: Now delegates ViewModel creation to role-specific container views.
//  ✅ CLEAN: Only handles top-level routing based on user role.
//  ✅ ROBUST: Aligned with a consistent ViewModel injection pattern.
//  ✅ DARK ELEGANCE: Updated with new theme colors and transitions
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var previousRole: CoreTypes.UserRole?
    
    var body: some View {
        ZStack {
            // Dark Elegance Background
            FrancoSphereDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            // Main content with role-based routing
            Group {
                switch authManager.userRole {
                case .admin, .manager:
                    // Admin and Manager share the same dashboard experience
                    AdminDashboardContainerView()
                        .transition(roleTransition)
                        .id("admin-\(authManager.userId ?? "")")
                    
                case .client:
                    ClientDashboardContainerView()
                        .transition(roleTransition)
                        .id("client-\(authManager.userId ?? "")")
                    
                case .worker:
                    WorkerDashboardContainerView()
                        .transition(roleTransition)
                        .id("worker-\(authManager.userId ?? "")")
                    
                case nil:
                    // Fallback with loading state for undefined role
                    UndefinedRoleView()
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .animation(FrancoSphereDesign.Animations.dashboardTransition, value: authManager.userRole)
            
            // Optional role indicator overlay (for debugging in dev mode)
            #if DEBUG
            if let role = authManager.userRole {
                VStack {
                    HStack {
                        RoleIndicatorPill(role: role)
                            .padding()
                        Spacer()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            }
            #endif
        }
        // Pass the authManager down so the container views can use it
        .environmentObject(authManager)
        .preferredColorScheme(.dark)
        .onChange(of: authManager.userRole) { newRole in
            handleRoleChange(from: previousRole, to: newRole)
            previousRole = newRole
        }
        .onAppear {
            previousRole = authManager.userRole
        }
    }
    
    // MARK: - Computed Properties
    
    private var roleTransition: AnyTransition {
        // Custom transition based on role hierarchy
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
    
    // MARK: - Helper Methods
    
    private func handleRoleChange(from oldRole: CoreTypes.UserRole?, to newRole: CoreTypes.UserRole?) {
        // Log role changes for analytics
        #if DEBUG
        print("🔄 Role transition: \(oldRole?.rawValue ?? "none") → \(newRole?.rawValue ?? "none")")
        #endif
        
        // Clear any role-specific caches if needed
        if oldRole != newRole {
            // Trigger any necessary cleanup or preparation
            NotificationCenter.default.post(
                name: Notification.Name("UserRoleChanged"),
                object: nil,
                userInfo: ["oldRole": oldRole as Any, "newRole": newRole as Any]
            )
        }
    }
}

// MARK: - Undefined Role View

struct UndefinedRoleView: View {
    @EnvironmentObject private var authManager: NewAuthManager
    @State private var isRetrying = false
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.xl) {
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: FrancoSphereDesign.DashboardColors.primaryText))
                .scaleEffect(1.5)
            
            VStack(spacing: FrancoSphereDesign.Spacing.md) {
                Text("Setting up your dashboard...")
                    .francoTypography(FrancoSphereDesign.Typography.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("We're preparing your personalized experience")
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Retry button after delay
            if !isRetrying {
                Button(action: retryRoleAssignment) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(FrancoSphereDesign.DashboardColors.primaryAction)
                    .cornerRadius(8)
                }
                .opacity(0)
                .animation(.easeIn(duration: 0.3).delay(3), value: isRetrying)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            isRetrying = false
                        }
                    }
                }
            }
        }
        .francoCardPadding()
        .frame(maxWidth: 400)
    }
    
    private func retryRoleAssignment() {
        isRetrying = true
        
        Task {
            // Attempt to refresh the user's role
            if let userId = authManager.userId {
                try? await authManager.refreshUserRole(userId: userId)
            }
            
            await MainActor.run {
                isRetrying = false
            }
        }
    }
}

// MARK: - Role Indicator Pill (Debug Only)

#if DEBUG
struct RoleIndicatorPill: View {
    let role: CoreTypes.UserRole
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: roleIcon)
                .font(.caption)
            
            Text(role.rawValue.capitalized)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(roleColor.opacity(0.9))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(radius: 4, x: 0, y: 2)
    }
    
    private var roleIcon: String {
        switch role {
        case .admin, .manager: return "crown.fill"
        case .client: return "building.2.fill"
        case .worker: return "person.fill"
        }
    }
    
    private var roleColor: Color {
        switch role {
        case .admin, .manager: return FrancoSphereDesign.DashboardColors.adminPrimary
        case .client: return FrancoSphereDesign.DashboardColors.clientPrimary
        case .worker: return FrancoSphereDesign.DashboardColors.workerPrimary
        }
    }
}
#endif

// MARK: - Preview Provider

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Worker role preview
            ContentView()
                .environmentObject({
                    let auth = NewAuthManager.shared
                    auth.userRole = .worker
                    return auth
                }())
                .previewDisplayName("Worker Dashboard")
            
            // Admin role preview
            ContentView()
                .environmentObject({
                    let auth = NewAuthManager.shared
                    auth.userRole = .admin
                    return auth
                }())
                .previewDisplayName("Admin Dashboard")
            
            // Client role preview
            ContentView()
                .environmentObject({
                    let auth = NewAuthManager.shared
                    auth.userRole = .client
                    return auth
                }())
                .previewDisplayName("Client Dashboard")
            
            // Undefined role preview
            ContentView()
                .environmentObject({
                    let auth = NewAuthManager.shared
                    auth.userRole = nil
                    return auth
                }())
                .previewDisplayName("Undefined Role")
        }
        .preferredColorScheme(.dark)
    }
}
