//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ ENHANCED: Complete initialization flow with DatabaseInitializer
//  ✅ PRODUCTION READY: Handles database init, migration, and daily ops
//  ✅ WIRED: All initialization components properly connected
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var dailyOps = DailyOpsReset.shared
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
    @StateObject private var locationManager = LocationManager()
    @StateObject private var databaseInitializer = DatabaseInitializer.shared
    @StateObject private var initViewModel = InitializationViewModel()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main app flow with proper initialization order
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
                } else if !databaseInitializer.isInitialized {
                    // Database initialization (includes seeding)
                    InitializationView(viewModel: initViewModel)
                        .transition(.opacity)
                        .onAppear {
                            // Auto-start initialization if not already running
                            if !initViewModel.isInitializing && !initViewModel.isComplete {
                                Task {
                                    await initViewModel.startInitialization()
                                }
                            }
                        }
                } else if dailyOps.needsMigration() {
                    // Show migration UI if needed (operational data migration)
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
                        .environmentObject(contextEngine)
                        .environmentObject(databaseInitializer)
                        .transition(.opacity)
                } else {
                    // Login screen
                    LoginView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showingSplash)
            .animation(.easeInOut(duration: 0.3), value: databaseInitializer.isInitialized)
            .animation(.easeInOut(duration: 0.3), value: dailyOps.needsMigration())
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .onAppear {
                setupApp()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkDailyOperations()
            }
            .onChange(of: initViewModel.isComplete) { isComplete in
                if isComplete {
                    // After initialization completes, check daily operations
                    checkDailyOperations()
                }
            }
        }
    }
    
    private func setupApp() {
        // Configure app appearance
        configureAppearance()
        
        // NotificationManager already requests permissions in its init()
        
        // Start location services if authenticated
        if authManager.isAuthenticated {
            locationManager.startUpdatingLocation()
        }
        
        // Check if we need to initialize database or run daily operations
        if databaseInitializer.isInitialized {
            checkDailyOperations()
        }
        // Otherwise, InitializationView will handle it
    }
    
    private func checkDailyOperations() {
        Task {
            do {
                // Ensure database is initialized first
                if !databaseInitializer.isInitialized {
                    print("⚠️ Database not initialized, waiting for initialization...")
                    return
                }
                
                // This will trigger migration if needed, then daily ops
                try await dailyOps.performDailyOperations()
                
                // After successful daily ops, refresh any cached data
                await refreshAppData()
                
            } catch {
                print("❌ Daily operations failed: \(error)")
                // In production, you might want to show an alert or retry
                await handleDailyOpsError(error)
            }
        }
    }
    
    private func refreshAppData() async {
        // Refresh any cached data after daily operations
        do {
            // Refresh building metrics
            await BuildingMetricsService.shared.invalidateAllCaches()
            
            // Refresh worker context if authenticated
            if let currentUser = await authManager.getCurrentUser() {
                try await contextEngine.loadContext(for: currentUser.workerId)
            }
            
            print("✅ App data refreshed after daily operations")
        } catch {
            print("⚠️ Failed to refresh app data: \(error)")
        }
    }
    
    private func handleDailyOpsError(_ error: Error) async {
        // Log error for analytics
        print("📊 Daily ops error logged: \(error)")
        
        // In production, you might want to:
        // 1. Send error to crash reporting service
        // 2. Show user-friendly error message
        // 3. Offer retry option
        // 4. Fall back to cached data
        
        // For now, just ensure the app can continue
        if databaseInitializer.isInitialized {
            print("✅ Database is initialized, app can continue with cached data")
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

// MARK: - Onboarding View

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

// MARK: - App Launch Sequence Documentation
/*
 FrancoSphere v6.0 Launch Sequence:
 
 1. Splash Screen (2 seconds)
 2. Database Initialization Check
    - If not initialized → InitializationView
    - Creates tables, seeds auth data, imports operational data
 3. Migration Check (DailyOpsReset)
    - If needs migration → MigrationView
    - Imports templates, creates assignments, sets capabilities
 4. Onboarding Check
    - If first time user → OnboardingView
 5. Authentication Check
    - If not authenticated → LoginView
    - If authenticated → ContentView
 
 Daily Operations (runs after initialization):
 - Generate tasks from templates
 - Clean old data
 - Update metrics
 
 The flow ensures:
 ✅ Database is always initialized before use
 ✅ Migration runs only once when needed
 ✅ Daily operations run after all setup
 ✅ User sees appropriate UI at each stage
 */
