//
//  ProfileView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/1/25.
//  Updated for Glassmorphism Design - 6/7/25
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @StateObject private var authManager = NewAuthManager.shared
    
    // Sample data - in a real app, this would be fetched from a database
    let assignedBuildingCount = 4
    let hoursThisWeek = 32
    let tasksCompleted = 12
    
    // Navigation state
    @State private var showingAssignedBuildings = false
    @State private var showingHoursBreakdown = false
    @State private var showingTaskHistory = false
    @State private var showingPersonalInfo = false
    @State private var showingNotifications = false
    @State private var showingChangePassword = false
    @State private var showingHelpSupport = false
    
    // Animation states
    @State private var isLoaded = false
    @State private var cardAnimationOffset: CGFloat = 50
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header Glass Card
                    profileHeaderCard
                        .offset(y: isLoaded ? 0 : cardAnimationOffset)
                        .opacity(isLoaded ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: isLoaded)
                    
                    // Stats Cards
                    statsCardsSection
                        .offset(y: isLoaded ? 0 : cardAnimationOffset)
                        .opacity(isLoaded ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.3), value: isLoaded)
                    
                    // Account Settings Glass Card
                    accountSettingsCard
                        .offset(y: isLoaded ? 0 : cardAnimationOffset)
                        .opacity(isLoaded ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.5), value: isLoaded)
                    
                    // Logout Button
                    logoutButton
                        .offset(y: isLoaded ? 0 : cardAnimationOffset)
                        .opacity(isLoaded ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.7), value: isLoaded)
                    
                    // Footer
                    FrancoSphereGlassFooter()
                        .offset(y: isLoaded ? 0 : cardAnimationOffset)
                        .opacity(isLoaded ? 1 : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.9), value: isLoaded)
                    
                    // Bottom padding for safe area
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
        }
        .navigationBarHidden(true)
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation {
                isLoaded = true
            }
        }
        // Sheets
        .sheet(isPresented: $showingAssignedBuildings) {
            MyAssignedBuildingsGlassView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingHoursBreakdown) {
            HoursBreakdownGlassView(hoursThisWeek: hoursThisWeek)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingTaskHistory) {
            TaskHistoryGlassView(completedCount: tasksCompleted)
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingPersonalInfo) {
            PersonalInfoGlassView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationSettingsGlassView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingChangePassword) {
            ChangePasswordGlassView()
                .preferredColorScheme(.dark)
        }
        .sheet(isPresented: $showingHelpSupport) {
            HelpSupportGlassView()
                .preferredColorScheme(.dark)
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Primary gradient background
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25),
                    Color(red: 0.15, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle overlay patterns
            GeometryReader { geometry in
                ZStack {
                    // Floating orbs for depth
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.purple.opacity(0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.7)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Profile Header Card
    private var profileHeaderCard: some View {
        GlassCard(intensity: .regular, cornerRadius: 24, padding: 32) {
            VStack(spacing: 20) {
                // Profile Avatar with Glass Effect
                ZStack {
                    // Glow background
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.blue.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    // Avatar circle with glass border
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .frame(width: 120, height: 120)
                    
                    // Avatar icon
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                // Name and role
                VStack(spacing: 8) {
                    Text(authManager.currentWorkerName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    ProfileGlassStatusBadge(
                        text: "Maintenance Worker",
                        color: .blue,
                        size: .medium
                    )
                }
                
                // Quick status indicator
                HStack(spacing: 16) {
                    StatusIndicatorView(
                        icon: "checkmark.circle.fill",
                        text: "Active",
                        color: .green
                    )
                    
                    Divider()
                        .frame(height: 20)
                        .background(Color.white.opacity(0.3))
                    
                    StatusIndicatorView(
                        icon: "clock.fill",
                        text: "On Duty",
                        color: .blue
                    )
                }
            }
        }
    }
    
    // MARK: - Stats Cards Section
    private var statsCardsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Performance Overview")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Stats grid
            VStack(spacing: 12) {
                // Assigned Buildings Card
                PressableGlassCard(
                    intensity: .thin,
                    cornerRadius: 16,
                    padding: 20
                ) {
                    showingAssignedBuildings = true
                } content: {
                    GlassStatCardContent(
                        iconName: "building.2.fill",
                        title: "Assigned Buildings",
                        value: "\(assignedBuildingCount)",
                        subtitle: "Active assignments",
                        color: .blue,
                        showChevron: true
                    )
                }
                
                // Hours this Week Card
                PressableGlassCard(
                    intensity: .thin,
                    cornerRadius: 16,
                    padding: 20
                ) {
                    showingHoursBreakdown = true
                } content: {
                    GlassStatCardContent(
                        iconName: "clock.fill",
                        title: "Hours this Week",
                        value: "\(hoursThisWeek)h",
                        subtitle: "4 days logged",
                        color: .orange,
                        showChevron: true
                    )
                }
                
                // Tasks Completed Card
                PressableGlassCard(
                    intensity: .thin,
                    cornerRadius: 16,
                    padding: 20
                ) {
                    showingTaskHistory = true
                } content: {
                    GlassStatCardContent(
                        iconName: "checkmark.circle.fill",
                        title: "Tasks Completed",
                        value: "\(tasksCompleted)",
                        subtitle: "This week",
                        color: .green,
                        showChevron: true
                    )
                }
            }
        }
    }
    
    // MARK: - Account Settings Card
    private var accountSettingsCard: some View {
        GlassCard(intensity: .thin, cornerRadius: 20, padding: 24) {
            VStack(spacing: 20) {
                // Section header
                HStack {
                    Text("Account Settings")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                
                // Settings rows
                VStack(spacing: 0) {
                    GlassSettingsRow(
                        iconName: "person.fill",
                        title: "Personal Information",
                        color: .blue
                    ) {
                        showingPersonalInfo = true
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 8)
                    
                    GlassSettingsRow(
                        iconName: "bell.fill",
                        title: "Notifications",
                        color: .orange
                    ) {
                        showingNotifications = true
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 8)
                    
                    GlassSettingsRow(
                        iconName: "lock.fill",
                        title: "Change Password",
                        color: .red
                    ) {
                        showingChangePassword = true
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 8)
                    
                    GlassSettingsRow(
                        iconName: "questionmark.circle.fill",
                        title: "Help & Support",
                        color: .purple
                    ) {
                        showingHelpSupport = true
                    }
                }
            }
        }
    }
    
    // MARK: - Logout Button
    private var logoutButton: some View {
        PressableGlassCard(
            intensity: .regular,
            cornerRadius: 16,
            padding: 20
        ) {
            authManager.logout()
        } content: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title3)
                    .foregroundColor(.red)
                
                Text("LOG OUT")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
        }
    }
}

// MARK: - Supporting Components

struct GlassStatCardContent: View {
    let iconName: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let showChevron: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon with glass background
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconName)
                    .font(.title3)
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            // Chevron
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

struct GlassSettingsRow: View {
    let iconName: String
    let title: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct StatusIndicatorView: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Local Profile Badge (renamed to avoid conflicts)
struct ProfileGlassStatusBadge: View {
    let text: String
    let color: Color
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .large: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption2
            case .medium: return .caption
            case .large: return .subheadline
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(size.font)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(size.padding)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        color.opacity(0.6),
                                        color.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

struct FrancoSphereGlassFooter: View {
    var body: some View {
        GlassCard(intensity: .ultraThin, cornerRadius: 12, padding: 16) {
            HStack {
                Image(systemName: "building.2.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue.opacity(0.8))
                
                Text("Powered by FrancoSphere")
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("v1.1")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

// MARK: - Sheet Views (Glassmorphism)

struct MyAssignedBuildingsGlassView: View {
    @State private var assignedBuildings: [FrancoSphere.NamedCoordinate] = []
    @State private var isLoading = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                GlassCard(intensity: .regular, cornerRadius: 0, padding: 20) {
                    HStack {
                        Text("My Assigned Buildings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    }
                }
                
                // Content
                if isLoading {
                    Spacer()
                    GlassCard(intensity: .thin) {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(.blue)
                            
                            Text("Loading buildings...")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.vertical, 20)
                    }
                    .padding()
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(assignedBuildings) { building in
                                BuildingGlassRow(building: building)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .task {
            await loadAssignedBuildings()
        }
    }
    
    private func loadAssignedBuildings() async {
        do {
            let buildings = await BuildingRepository.shared.getFirstNBuildings(4)
            await MainActor.run {
                self.assignedBuildings = buildings
                self.isLoading = false
            }
        } catch {
            print("Error loading buildings: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}

struct BuildingGlassRow: View {
    let building: FrancoSphere.NamedCoordinate
    
    var body: some View {
        PressableGlassCard(intensity: .thin, cornerRadius: 16, padding: 16) {
            // Navigate to building detail
        } content: {
            HStack(spacing: 16) {
                // Building image
                if let uiImage = UIImage(named: building.imageAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                
                // Building info
                VStack(alignment: .leading, spacing: 6) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        StatusIndicatorView(
                            icon: "checkmark.circle.fill",
                            text: "Operational",
                            color: .green
                        )
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Text("3 tasks")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Text("Location: \(String(format: "%.4f, %.4f", building.latitude, building.longitude))")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }
}

// Placeholder views for other sheets
struct HoursBreakdownGlassView: View {
    let hoursThisWeek: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassCard(intensity: .regular) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Hours Breakdown")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("This feature will show detailed hours breakdown")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Total: \(hoursThisWeek) hours")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }
            .padding()
        }
    }
}

struct TaskHistoryGlassView: View {
    let completedCount: Int
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassCard(intensity: .regular) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Task History")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("This feature will show completed tasks history")
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Completed: \(completedCount) tasks")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
        }
    }
}

struct PersonalInfoGlassView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassCard(intensity: .regular) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Personal Information")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("Personal information settings will be available here")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
        }
    }
}

struct NotificationSettingsGlassView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassCard(intensity: .regular) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Notification Settings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("Notification preferences will be available here")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
        }
    }
}

struct ChangePasswordGlassView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassCard(intensity: .regular) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Change Password")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("Password change form will be available here")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
        }
    }
}

struct HelpSupportGlassView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FrancoSphereColors.primaryBackground,
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GlassCard(intensity: .regular) {
                VStack(spacing: 20) {
                    HStack {
                        Text("Help & Support")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Text("Help and support resources will be available here")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
        }
    }
}

// MARK: - Preview
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
    }
}
