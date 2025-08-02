//
//  ProfileView.swift
//  FrancoSphere v6.0
//
//  ✅ ALL COMPILATION ERRORS FIXED
//  ✅ No async operations in computed properties or view builders
//  ✅ Proper ViewBuilder usage
//  ✅ Cross-dashboard integration ready
//  ✅ FIXED: Proper error handling for logout
//  ✅ DARK ELEGANCE: Updated with new theme system
//

import SwiftUI
import Foundation

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
    
    @State private var showImagePicker = false
    @State private var showLogoutConfirmation = false
    @State private var profileImage: UIImage?
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Determine user's dashboard role for theming
    private var dashboardRole: DashboardRole {
        switch authManager.userRole {
        case .admin, .manager: return .admin
        case .client: return .client
        case .worker, .none: return .worker
        }
    }
    
    private var currentWorkerRole: String {
        contextEngine.currentWorker?.role.rawValue.capitalized ?? "Worker"
    }
    
    private var currentWorkerEmail: String? {
        contextEngine.currentWorker?.email
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: FrancoSphereDesign.Spacing.lg) {
                    // Profile header
                    profileHeader
                    
                    // Worker information
                    workerInfoSection
                    
                    // Statistics section
                    statisticsSection
                    
                    // Settings section
                    settingsSection
                    
                    // Actions section
                    actionsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, FrancoSphereDesign.Spacing.md)
                .padding(.top, FrancoSphereDesign.Spacing.md)
            }
            .background(FrancoSphereDesign.DashboardColors.baseBackground.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticManager.impact(.medium)
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.subheadline.weight(.semibold))
                            Text("Back")
                                .font(.subheadline)
                        }
                        .foregroundColor(dashboardRole.primaryColor)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.impact(.light)
                        dismiss()
                    }
                    .foregroundColor(dashboardRole.primaryColor)
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showImagePicker) {
            FrancoSphereImagePicker(
                isPresented: $showImagePicker,
                selectedImage: $profileImage
            )
        }
        .alert("Sign Out", isPresented: $showLogoutConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                handleLogout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.md) {
            // Profile image
            Button(action: {
                HapticManager.impact(.light)
                showImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: dashboardRole.heroGradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    
                    // Edit overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Circle()
                                .fill(dashboardRole.primaryColor)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                                .offset(x: -8, y: -8)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Worker name and role
            VStack(spacing: FrancoSphereDesign.Spacing.xs) {
                Text(authManager.currentWorkerName)
                    .francoTypography(FrancoSphereDesign.Typography.title2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(currentWorkerRole)
                    .francoTypography(FrancoSphereDesign.Typography.subheadline)
                    .foregroundColor(dashboardRole.primaryColor)
                
                if let email = currentWorkerEmail {
                    Text(email)
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
        }
    }
    
    // MARK: - Worker Information
    
    private var workerInfoSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            Text("Worker Information")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: FrancoSphereDesign.Spacing.md) {
                ProfileInfoRow(
                    icon: "person.badge.key.fill",
                    label: "Worker ID",
                    value: authManager.workerId ?? "Unknown",
                    role: dashboardRole
                )
                
                ProfileInfoRow(
                    icon: "building.2.fill",
                    label: "Assigned Buildings",
                    value: "\(contextEngine.assignedBuildings.count)",
                    role: dashboardRole
                )
                
                ProfileInfoRow(
                    icon: "clock.fill",
                    label: "Employment Status",
                    value: "Active",
                    role: dashboardRole
                )
                
                ProfileInfoRow(
                    icon: "calendar.badge.clock",
                    label: "Member Since",
                    value: "March 2024",
                    role: dashboardRole
                )
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            Text("Performance Stats")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: FrancoSphereDesign.Spacing.md) {
                HStack(spacing: FrancoSphereDesign.Spacing.md) {
                    ProfileStatCard(
                        title: "Tasks Today",
                        value: "\(contextEngine.todaysTasks.count)",
                        color: FrancoSphereDesign.DashboardColors.info
                    )
                    
                    ProfileStatCard(
                        title: "Completed",
                        value: "\(getCompletedTasksCount())",
                        color: FrancoSphereDesign.DashboardColors.success
                    )
                }
                
                HStack(spacing: FrancoSphereDesign.Spacing.md) {
                    ProfileStatCard(
                        title: "Pending",
                        value: "\(getPendingTasksCount())",
                        color: FrancoSphereDesign.DashboardColors.warning
                    )
                    
                    ProfileStatCard(
                        title: "Urgent",
                        value: "\(getUrgentTasksCount())",
                        color: FrancoSphereDesign.DashboardColors.critical
                    )
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.md) {
            Text("Settings")
                .francoTypography(FrancoSphereDesign.Typography.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Push notifications and alerts",
                    hasChevron: true,
                    role: dashboardRole
                ) {
                    // Handle notifications settings
                }
                
                Divider()
                    .background(FrancoSphereDesign.DashboardColors.borderSubtle)
                    .padding(.vertical, FrancoSphereDesign.Spacing.sm)
                
                SettingsRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: "Always enabled for better visibility",
                    hasChevron: false,
                    role: dashboardRole
                ) {
                    // Dark mode is always on
                }
                
                Divider()
                    .background(FrancoSphereDesign.DashboardColors.borderSubtle)
                    .padding(.vertical, FrancoSphereDesign.Spacing.sm)
                
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "FAQs and contact information",
                    hasChevron: true,
                    role: dashboardRole
                ) {
                    // Handle help & support
                }
            }
        }
        .francoCardPadding()
        .francoDarkCardBackground()
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Button {
                HapticManager.impact(.medium)
                Task {
                    await refreshContextData()
                }
            } label: {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                    Text("Refresh Data")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(dashboardRole.primaryColor)
                .francoCornerRadius(FrancoSphereDesign.CornerRadius.md)
            }
            
            Button {
                HapticManager.impact(.medium)
                showLogoutConfirmation = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                        .fill(FrancoSphereDesign.DashboardColors.critical.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                                .stroke(FrancoSphereDesign.DashboardColors.critical.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLogout() {
        HapticManager.impact(.heavy)
        Task {
            do {
                try await authManager.logout()
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to sign out: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
    
    private func refreshContextData() async {
        guard let workerId = authManager.workerId else { return }
        do {
            try await contextEngine.loadContext(for: workerId)
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh data: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func getPendingTasksCount() -> Int {
        contextEngine.todaysTasks.filter { task in
            !task.isCompleted
        }.count
    }
    
    private func getCompletedTasksCount() -> Int {
        contextEngine.todaysTasks.filter { task in
            task.isCompleted
        }.count
    }
    
    private func getUrgentTasksCount() -> Int {
        contextEngine.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            let urgencyValue = urgency.rawValue.lowercased()
            return urgencyValue == "high" || urgencyValue == "critical" || urgencyValue == "urgent"
        }.count
    }
}

// MARK: - Supporting Components

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    let role: DashboardRole
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(role.primaryColor)
                .frame(width: 20)
            
            Text(label)
                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: FrancoSphereDesign.Spacing.sm) {
            Text(value)
                .francoTypography(FrancoSphereDesign.Typography.title)
                .foregroundColor(color)
            
            Text(title)
                .francoTypography(FrancoSphereDesign.Typography.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, FrancoSphereDesign.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: FrancoSphereDesign.CornerRadius.md)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let hasChevron: Bool
    let role: DashboardRole
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: FrancoSphereDesign.Spacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(role.primaryColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: FrancoSphereDesign.Spacing.xs / 2) {
                    Text(title)
                        .francoTypography(FrancoSphereDesign.Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Text(subtitle)
                        .francoTypography(FrancoSphereDesign.Typography.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
                
                Spacer()
                
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            .padding(.vertical, FrancoSphereDesign.Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Image Picker

struct FrancoSphereImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: FrancoSphereImagePicker
        
        init(_ parent: FrancoSphereImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            parent.isPresented = false
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

// MARK: - Preview Provider

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(NewAuthManager.shared)
            .preferredColorScheme(.dark)
    }
}
