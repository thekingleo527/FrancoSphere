//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ ENHANCED: Migration flow integration
//  ✅ PRODUCTION READY: Handles one-time migration gracefully
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var dailyOps = DailyOpsReset.shared
    @StateObject private var authManager = NewAuthManager()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var locationManager = LocationManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app flow
                if showingSplash {
                    SplashView()
                        .onAppear {
                            // Show splash for 2 seconds
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showingSplash = false
                                }
                            }
                        }
                } else if dailyOps.needsMigration() {
                    // Show migration UI if needed
                    MigrationView()
                        .transition(.opacity)
                } else if !hasCompletedOnboarding {
                    // Show onboarding for new users
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.opacity)
                } else if authManager.isAuthenticated {
                    // Main app content
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(notificationManager)
                        .environmentObject(locationManager)
                        .transition(.opacity)
                } else {
                    // Login screen
                    LoginView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingSplash)
            .animation(.easeInOut(duration: 0.3), value: dailyOps.needsMigration())
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .onAppear {
                setupApp()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkDailyOperations()
            }
        }
    }
    
    private func setupApp() {
        // Configure app appearance
        configureAppearance()
        
        // Request notification permissions
        Task {
            await notificationManager.requestPermission()
        }
        
        // Start location services if authenticated
        if authManager.isAuthenticated {
            locationManager.startUpdatingLocation()
        }
        
        // Check if we need to run daily operations
        checkDailyOperations()
    }
    
    private func checkDailyOperations() {
        Task {
            do {
                // This will trigger migration if needed, then daily ops
                try await dailyOps.performDailyOperations()
            } catch {
                print("❌ Daily operations failed: \(error)")
                // Handle error - maybe show an alert
            }
        }
    }
    
    private func configureAppearance() {
        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.systemBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Table view appearance
        UITableView.appearance().backgroundColor = UIColor.systemBackground
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.07, green: 0.07, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .scaleEffect(animate ? 1.2 : 0.8)
                    
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(animate ? 1.0 : 0.8)
                }
                
                Text("FrancoSphere")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .opacity(animate ? 1.0 : 0.0)
                
                Text("Property Management Excellence")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(animate ? 1.0 : 0.0)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    animate = true
                }
            }
        }
    }
}

// MARK: - Onboarding View (Placeholder)

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            OnboardingPageView(
                imageName: "building.2.crop.circle.fill",
                title: "Welcome to FrancoSphere",
                description: "Streamline your property management with our powerful tools",
                buttonTitle: "Next",
                buttonAction: { currentPage = 1 }
            )
            .tag(0)
            
            OnboardingPageView(
                imageName: "checklist",
                title: "Track Tasks Efficiently",
                description: "Manage maintenance, cleaning, and inspection tasks in real-time",
                buttonTitle: "Next",
                buttonAction: { currentPage = 2 }
            )
            .tag(1)
            
            OnboardingPageView(
                imageName: "camera.fill",
                title: "Document Everything",
                description: "Capture photos and notes to maintain complete records",
                buttonTitle: "Get Started",
                buttonAction: {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                }
            )
            .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    let buttonTitle: String
    let buttonAction: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
            
            Button(action: buttonAction) {
                Text(buttonTitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.blue)
                    .cornerRadius(16)
            }
            .padding(.horizontal)
            .padding(.bottom, 50)
        }
    }
}
