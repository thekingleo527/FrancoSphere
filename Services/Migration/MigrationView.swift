//  MigrationView.swift
//  CyntientOps v6.0
//
//  ✅ PRODUCTION READY: One-time migration UI with progress tracking
//  ✅ VISUAL: Glass morphism design matching CyntientOps aesthetic
//  ✅ SAFE: Error handling and retry capabilities
//

import SwiftUI

struct MigrationView: View {
    @StateObject private var migrationManager = DailyOpsReset.shared
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showRetry = false
    @State private var animateProgress = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient
            backgroundGradient
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                if migrationManager.isMigrating {
                    migrationInProgress
                } else if showError {
                    migrationError
                } else {
                    migrationStart
                }
            }
            .padding()
        }
        .onAppear {
            checkMigrationStatus()
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.07, green: 0.07, blue: 0.12),
                Color(red: 0.05, green: 0.05, blue: 0.08),
                Color(red: 0.03, green: 0.03, blue: 0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            // Animated mesh gradient effect
            GeometryReader { geometry in
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.1),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: 60)
                        .opacity(0.5)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 10...20))
                                .repeatForever(autoreverses: true),
                            value: UUID()
                        )
                }
            }
        )
    }
    
    // MARK: - Migration Start View
    
    private var migrationStart: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Logo
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.5), radius: 20)
            
            VStack(spacing: 16) {
                Text("Database Migration Required")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("We need to upgrade your database to enable new features")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Info cards
            VStack(spacing: 16) {
                MigrationInfoCard(
                    icon: "clock.fill",
                    title: "Estimated Time",
                    value: "2-3 minutes",
                    color: .blue
                )
                
                MigrationInfoCard(
                    icon: "checkmark.shield.fill",
                    title: "Data Safety",
                    value: "Automatic backup created",
                    color: .green
                )
                
                MigrationInfoCard(
                    icon: "arrow.up.circle.fill",
                    title: "What's New",
                    value: "Photo evidence, offline sync, and more",
                    color: .purple
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Start button
            Button(action: startMigration) {
                HStack {
                    Text("Start Migration")
                        .font(.system(size: 18, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Migration In Progress View
    
    private var migrationInProgress: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Animated logo
            ZStack {
                // Rotating rings
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    .blue.opacity(0.3),
                                    .cyan.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(
                            width: 100 + CGFloat(index * 30),
                            height: 100 + CGFloat(index * 30)
                        )
                        .rotationEffect(.degrees(animateProgress ? 360 : 0))
                        .animation(
                            Animation.linear(duration: 3 + Double(index))
                                .repeatForever(autoreverses: false),
                            value: animateProgress
                        )
                }
                
                // Center icon
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(animateProgress ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: animateProgress
                    )
            }
            .onAppear {
                animateProgress = true
            }
            
            // Progress info
            VStack(spacing: 24) {
                Text(migrationManager.migrationStatus)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut, value: migrationManager.migrationStatus)
                
                // Progress bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Step \(migrationManager.currentStep) of \(migrationManager.totalSteps)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Spacer()
                        
                        Text("\(Int(migrationManager.migrationProgress * 100))%")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(0, CGFloat(migrationManager.migrationProgress) * (UIScreen.main.bounds.width - 64)),
                                height: 12
                            )
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: migrationManager.migrationProgress)
                        
                        // Shimmer effect
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0),
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 60, height: 12)
                            .offset(x: animateProgress ? UIScreen.main.bounds.width : -60)
                            .animation(
                                Animation.linear(duration: 2)
                                    .repeatForever(autoreverses: false),
                                value: animateProgress
                            )
                            .mask(
                                RoundedRectangle(cornerRadius: 8)
                                    .frame(
                                        width: max(0, CGFloat(migrationManager.migrationProgress) * (UIScreen.main.bounds.width - 64)),
                                        height: 12
                                    )
                            )
                    }
                }
                .padding(.horizontal)
                
                // Step details
                VStack(spacing: 12) {
                    MigrationStepRow(
                        step: 1,
                        title: "Creating backup",
                        isActive: migrationManager.currentStep == 1,
                        isComplete: migrationManager.currentStep > 1
                    )
                    
                    MigrationStepRow(
                        step: 2,
                        title: "Verifying data integrity",
                        isActive: migrationManager.currentStep == 2,
                        isComplete: migrationManager.currentStep > 2
                    )
                    
                    MigrationStepRow(
                        step: 3,
                        title: "Importing workers",
                        isActive: migrationManager.currentStep == 3,
                        isComplete: migrationManager.currentStep > 3
                    )
                    
                    MigrationStepRow(
                        step: 4,
                        title: "Importing buildings",
                        isActive: migrationManager.currentStep == 4,
                        isComplete: migrationManager.currentStep > 4
                    )
                    
                    MigrationStepRow(
                        step: 5,
                        title: "Creating task templates",
                        isActive: migrationManager.currentStep == 5,
                        isComplete: migrationManager.currentStep > 5
                    )
                    
                    MigrationStepRow(
                        step: 6,
                        title: "Setting up assignments",
                        isActive: migrationManager.currentStep == 6,
                        isComplete: migrationManager.currentStep > 6
                    )
                    
                    MigrationStepRow(
                        step: 7,
                        title: "Configuring capabilities",
                        isActive: migrationManager.currentStep == 7,
                        isComplete: migrationManager.currentStep > 7
                    )
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Migration Error View
    
    private var migrationError: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Error icon
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
            }
            
            VStack(spacing: 16) {
                Text("Migration Failed")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(errorMessage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Error details card
            VStack(alignment: .leading, spacing: 16) {
                Label("What you can do:", systemImage: "lightbulb.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 12) {
                    BulletPoint(text: "Check your internet connection")
                    BulletPoint(text: "Ensure you have enough storage space")
                    BulletPoint(text: "Try restarting the app")
                    BulletPoint(text: "Contact support if the issue persists")
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: retryMigration) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Retry Migration")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Button(action: contactSupport) {
                    Text("Contact Support")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)
        }
    }
    
    // MARK: - Actions
    
    private func checkMigrationStatus() {
        if migrationManager.migrationError != nil {
            errorMessage = migrationManager.migrationError?.localizedDescription ?? "An unknown error occurred"
            showError = true
        }
    }
    
    private func startMigration() {
        Task {
            do {
                try await migrationManager.performOneTimeMigration()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
    
    private func retryMigration() {
        showError = false
        errorMessage = ""
        startMigration()
    }
    
    private func contactSupport() {
        if let url = URL(string: "mailto:support@cyntientops.com?subject=Migration%20Error") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct MigrationInfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct MigrationStepRow: View {
    let step: Int
    let title: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Step indicator
            ZStack {
                Circle()
                    .fill(
                        isComplete ? Color.green.opacity(0.2) :
                        isActive ? Color.blue.opacity(0.2) :
                        Color.white.opacity(0.05)
                    )
                    .frame(width: 32, height: 32)
                
                if isComplete {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                } else {
                    Text("\(step)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(
                            isActive ? .blue : .white.opacity(0.3)
                        )
                }
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(
                    isComplete ? .white :
                    isActive ? .white :
                    .white.opacity(0.5)
                )
            
            Spacer()
            
            if isActive {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    .scaleEffect(0.8)
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 4, height: 4)
                .offset(y: 8)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Preview

struct MigrationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Start state
            MigrationView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Start")
            
            // In progress
            MigrationView()
                .preferredColorScheme(.dark)
                .previewDisplayName("In Progress")
                .onAppear {
                    DailyOpsReset.shared.isMigrating = true
                    DailyOpsReset.shared.currentStep = 3
                    DailyOpsReset.shared.migrationProgress = 0.4
                    DailyOpsReset.shared.migrationStatus = "Importing workers..."
                }
            
            // Error state
            MigrationView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Error")
                .onAppear {
                    // Option 1: Use the error type from DailyOpsReset
                    // DailyOpsReset.shared.migrationError = DailyOpsReset.DailyOpsError.importFailed("Network connection lost")
                    
                    // Option 2: Just set a simple error for preview
                    DailyOpsReset.shared.migrationError = NSError(
                        domain: "MigrationPreview",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Network connection lost"]
                    )
                }
        }
    }
}
