//
//  ProfileView.swift
//  FrancoSphere
//
//  ✅ PHASE 2: All compilation errors fixed
//  ✅ Actor-compatible async patterns
//  ✅ Correct method signatures and property access
//  ✅ Real data integration with operational continuity
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var contextEngine = WorkerContextEngineAdapter.shared
    
    @State private var showImagePicker = false
    @State private var showLogoutConfirmation = false
    @State private var profileImage: UIImage?
    
    // ✅ FIXED: Proper UserRole enum handling
    private var currentWorkerRole: String {
        return contextEngine.currentWorker?.role.rawValue.capitalized ?? "Worker"
    }
    
    private var currentWorkerEmail: String? {
        return contextEngine.currentWorker?.email
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
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
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color.black.ignoresSafeArea())
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
                        .foregroundColor(.blue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        HapticManager.impact(.light)
                        dismiss()
                    }
                    .foregroundColor(.blue)
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
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            Button(action: {
                HapticManager.impact(.light)
                showImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
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
                                .fill(Color.blue)
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
            VStack(spacing: 4) {
                Text(authManager.currentWorkerName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(currentWorkerRole)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                
                if let email = currentWorkerEmail {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    // MARK: - Worker Information
    
    private var workerInfoSection: some View {
        GlassProfileCard(title: "Worker Information") {
            VStack(spacing: 16) {
                ProfileInfoRow(
                    icon: "person.badge.key.fill",
                    label: "Worker ID",
                    // ✅ FIXED: Safe unwrapping of optional workerId
                    value: authManager.workerId ?? "Unknown"
                )
                
                ProfileInfoRow(
                    icon: "building.2.fill",
                    label: "Assigned Buildings",
                    value: "\(contextEngine.assignedBuildings.count)"
                )
                
                ProfileInfoRow(
                    icon: "clock.fill",
                    label: "Employment Status",
                    value: "Active"
                )
                
                ProfileInfoRow(
                    icon: "calendar.badge.clock",
                    label: "Member Since",
                    value: "March 2024"
                )
            }
        }
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        GlassProfileCard(title: "Performance Stats") {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    ProfileStatCard(
                        title: "Tasks Today",
                        value: "\(contextEngine.todaysTasks.count)",
                        color: .blue
                    )
                    
                    ProfileStatCard(
                        title: "Completed",
                        value: "\(getCompletedTasksCount())",
                        color: .green
                    )
                }
                
                HStack(spacing: 16) {
                    ProfileStatCard(
                        title: "Pending",
                        value: "\(getPendingTasksCount())",
                        color: .orange
                    )
                    
                    ProfileStatCard(
                        title: "Urgent",
                        value: "\(getUrgentTasksCount())",
                        color: .red
                    )
                }
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        GlassProfileCard(title: "Settings") {
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Push notifications and alerts",
                    hasChevron: true
                ) {
                    // Handle notifications settings
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 8)
                
                SettingsRow(
                    icon: "moon.fill",
                    title: "Dark Mode",
                    subtitle: "Always enabled for better visibility",
                    hasChevron: false
                ) {
                    // Dark mode is always on
                }
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.vertical, 8)
                
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help & Support",
                    subtitle: "FAQs and contact information",
                    hasChevron: true
                ) {
                    // Handle help & support
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                HapticManager.impact(.medium)
                Task { @MainActor in
                    // ✅ FIXED: Proper async refresh using underlying actor
                    await refreshContextData()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                    Text("Refresh Data")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: {
                HapticManager.impact(.medium)
                showLogoutConfirmation = true
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Text("Sign Out")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLogout() {
        HapticManager.impact(.heavy)
        Task {
            // ✅ FIXED: Use proper logout method instead of setting isAuthenticated
            await authManager.logout()
            dismiss()
        }
    }
    
    // ✅ FIXED: Proper async refresh method
    private func refreshContextData() async {
        guard let workerId = authManager.workerId else { return }
        await contextEngine.loadContext(for: workerId)
    }
    
    // ✅ FIXED: Helper methods using correct property access
    private func getPendingTasksCount() -> Int {
        return contextEngine.todaysTasks.filter { task in
            task.status == "pending" || !task.isCompleted
        }.count
    }
    
    private func getCompletedTasksCount() -> Int {
        return contextEngine.todaysTasks.filter { task in
            task.status == "completed" || task.isCompleted
        }.count
    }
    
    // ✅ FIXED: Proper urgency calculation with nil handling
    private func getUrgentTasksCount() -> Int {
        return contextEngine.todaysTasks.filter { task in
            guard let urgency = task.urgency else { return false }
            return urgency == .high || urgency == .critical
        }.count
    }
}

// MARK: - Supporting Components

struct GlassProfileCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            content
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if hasChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Local ImagePicker Component

struct FrancoSphereImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage?
    
    // ✅ FIXED: Explicit init to avoid ambiguity
    init(isPresented: Binding<Bool>, selectedImage: Binding<UIImage?>) {
        self._isPresented = isPresented
        self._selectedImage = selectedImage
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
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
