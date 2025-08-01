//
//  FrancoSphereApp.swift
//  FrancoSphere v6.0
//
//  ✅ ENHANCED: Complete initialization flow with DatabaseInitializer
//  ✅ PRODUCTION READY: Handles database init, migration, and daily ops
//  ✅ WIRED: All initialization components properly connected
//  ✅ SENTRY INTEGRATED: Full crash reporting and performance monitoring
//  ✅ FIXED: Corrected Sentry integration and all compiler errors.
//

import SwiftUI
import Sentry

@main
struct FrancoSphereApp: App {
    // MARK: - State Management & Services
    @StateObject private var dailyOps = DailyOpsReset.shared
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var contextEngine = WorkerContextEngine.shared
    private let locationManager = LocationManager.shared
    @StateObject private var databaseInitializer = DatabaseInitializer.shared
    @StateObject private var initViewModel = InitializationViewModel()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingSplash = true
    
    init() {
        // Initialize Sentry as the very first step of the app's lifecycle.
        initializeSentry()
    }
    
    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            ZStack {
                // The main app flow is determined by a series of state checks,
                // ensuring the correct view is shown at each stage of the launch sequence.
                if showingSplash {
                    SplashView()
                        .onAppear {
                            // Show splash for a brief period then transition.
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    showingSplash = false
                                }
                            }
                        }
                } else if !databaseInitializer.isInitialized {
                    // Step 1: Handle the initial database creation and seeding.
                    InitializationView(viewModel: initViewModel)
                        .transition(.opacity)
                        .onAppear {
                            // Automatically start the initialization if it hasn't begun.
                            if !initViewModel.isInitializing && !initViewModel.isComplete {
                                Task {
                                    await initViewModel.startInitialization()
                                }
                            }
                        }
                } else if dailyOps.needsMigration() {
                    // Step 2: If the DB is initialized but legacy data needs migrating.
                    MigrationView()
                        .transition(.opacity)
                } else if !hasCompletedOnboarding {
                    // Step 3: Show the onboarding flow for first-time users.
                    // This now correctly refers to the OnboardingView in its own file.
                    OnboardingView(onComplete: {
                        hasCompletedOnboarding = true
                    })
                    .transition(.opacity)
                } else if authManager.isAuthenticated {
                    // Step 4: If the user is authenticated, show the main app content.
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(notificationManager)
                        .environmentObject(locationManager)
                        .environmentObject(contextEngine)
                        .environmentObject(databaseInitializer)
                        .transition(.opacity)
                } else {
                    // Step 5: If none of the above, show the login screen.
                    LoginView()
                        .environmentObject(authManager)
                        .transition(.opacity)
                }
            }
            // Animate transitions between the major app states for a smoother experience.
            .animation(.easeInOut(duration: 0.3), value: showingSplash)
            .animation(.easeInOut(duration: 0.3), value: databaseInitializer.isInitialized)
            .animation(.easeInOut(duration: 0.3), value: dailyOps.needsMigration())
            .animation(.easeInOut(duration: 0.3), value: hasCompletedOnboarding)
            .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
            .onAppear(perform: setupApp)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkDailyOperations()
            }
            // Use the correct `onChange` syntax for wide compatibility.
            .onChange(of: initViewModel.isComplete) { newValue in
                if newValue {
                    checkDailyOperations()
                }
            }
            .onChange(of: authManager.currentUser) { newValue in
                updateSentryUserContext(newValue)
            }
        }
    }
    
    // MARK: - Sentry Initialization
    
    private func initializeSentry() {
        SentrySDK.start { options in
            options.dsn = "https://c77b2dddf9eca868ead5142d23a438cf@o4509764891901952.ingest.us.sentry.io/4509764893081600"
            
            #if DEBUG
            options.debug = true
            options.environment = "debug"
            #else
            options.debug = false
            options.environment = "production"
            #endif
            
            options.tracesSampleRate = 0.2
            
            // ✅ FIXED: Replaced deprecated `profilesSampleRate` with `profilesSampler`.
            options.profilesSampler = { samplingContext in
                return 0.2 // Profile 20% of transactions.
            }
            
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                options.releaseName = "francosphere@\(version)+\(build)"
            }
            
            options.enableAutoBreadcrumbTracking = true
            options.maxBreadcrumbs = 100
            options.attachScreenshot = true
            options.attachViewHierarchy = true
            
            options.beforeSend = { event in
                return self.sanitizeEvent(event)
            }
            
            options.enableAutoSessionTracking = true
            options.sessionTrackingIntervalMillis = 30000
            
            options.enableNetworkTracking = true
            options.enableNetworkBreadcrumbs = true
            
            options.enableUIViewControllerTracing = true
            options.enableUserInteractionTracing = true
            options.enableSwizzling = true
            
            options.enableTimeToFullDisplayTracing = true
            options.enablePreWarmedAppStartTracing = true
        }
        
        SentrySDK.configureScope { scope in
            scope.setTag(value: UIDevice.current.model, key: "device.model")
            scope.setTag(value: UIDevice.current.systemVersion, key: "ios.version")
            scope.setContext(value: [
                "initialized": databaseInitializer.isInitialized,
                "migrationNeeded": dailyOps.needsMigration(),
                "onboardingCompleted": hasCompletedOnboarding
            ], key: "app_state")
        }
        
        print("✅ Sentry initialized successfully")
    }
    
    // MARK: - Sentry Helper Methods
    
    private func sanitizeEvent(_ event: Event) -> Event? {
        if let message = event.message {
            event.message = SentryMessage(
                formatted: message.formatted.replacingOccurrences(
                    of: #"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"#,
                    with: "[REDACTED_EMAIL]",
                    options: .regularExpression
                )
            )
        }
        
        event.breadcrumbs = event.breadcrumbs?.compactMap { breadcrumb in
            var sanitizedBreadcrumb = breadcrumb
            if var data = sanitizedBreadcrumb.data {
                data.removeValue(forKey: "password")
                data.removeValue(forKey: "token")
                sanitizedBreadcrumb.data = data
            }
            return sanitizedBreadcrumb
        }
        
        if let request = event.request, let url = request.url, url.contains("password") || url.contains("token") {
            event.request?.url = "[REDACTED_URL]"
        }
        
        return event
    }
    
    private func updateSentryUserContext(_ user: CoreTypes.User?) {
        SentrySDK.configureScope { scope in
            if let user = user {
                // ✅ FIXED: Using the correct Sentry.User initializer.
                let sentryUser = Sentry.User(userId: user.workerId)
                sentryUser.username = user.name
                
                scope.setUser(sentryUser)
                scope.setContext(value: ["role": user.role], key: "user_info")
                scope.setTag(value: user.role, key: "user.role")
            } else {
                scope.setUser(nil)
                scope.removeContext(key: "user_info")
                scope.removeTag(key: "user.role")
            }
        }
    }
    
    // MARK: - App Setup & Lifecycle
    
    private func setupApp() {
        configureAppearance()
        
        let breadcrumb = Breadcrumb(level: .info, category: "app.lifecycle")
        breadcrumb.message = "App setup started"
        SentrySDK.addBreadcrumb(breadcrumb)
        
        if authManager.isAuthenticated {
            locationManager.startUpdatingLocation()
        }
        
        if databaseInitializer.isInitialized {
            checkDailyOperations()
        }
    }
    
    private func checkDailyOperations() {
        let transaction = SentrySDK.startTransaction(name: "daily_operations", operation: "app.task")
        
        Task {
            do {
                guard databaseInitializer.isInitialized else {
                    transaction.finish(status: .cancelled)
                    return
                }
                
                let operationsSpan = transaction.startChild(operation: "perform_operations")
                try await dailyOps.performDailyOperations()
                operationsSpan.finish()
                
                let refreshSpan = transaction.startChild(operation: "refresh_data")
                await refreshAppData()
                refreshSpan.finish()
                
                transaction.finish(status: .ok)
            } catch {
                SentrySDK.capture(error: error) { scope in
                    scope.setTag(value: "daily_operations", key: "task_group")
                }
                transaction.finish(status: .internalError)
                await handleDailyOpsError(error)
            }
        }
    }
    
    private func refreshAppData() async {
        do {
            await BuildingMetricsService.shared.invalidateAllCaches()
            
            if let currentUser = authManager.currentUser {
                try await contextEngine.loadContext(for: currentUser.workerId)
            }
            
            let breadcrumb = Breadcrumb(level: .info, category: "app.data")
            breadcrumb.message = "App data refreshed"
            SentrySDK.addBreadcrumb(breadcrumb)
            print("✅ App data refreshed after daily operations.")
        } catch {
            SentrySDK.capture(error: error) { scope in
                scope.setLevel(.warning)
            }
            print("⚠️ Failed to refresh app data: \(error)")
        }
    }
    
    private func handleDailyOpsError(_ error: Error) async {
        print("📊 Daily ops error logged to Sentry: \(error)")
    }
    
    private func configureAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = .systemBackground
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        
        UITableView.appearance().backgroundColor = .systemBackground
    }
}

// MARK: - Sentry Crash Reporter Wrapper (for backward compatibility)

enum CrashReporter {
    static func captureError(_ error: Error, context: [String: Any]? = nil) {
        SentrySDK.capture(error: error) { scope in
            if let context = context {
                scope.setContext(value: context, key: "custom_error_context")
            }
        }
    }
}

// MARK: - Placeholder Views (These should live in their own files)

struct SplashView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
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
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.blue.opacity(0.3), .cyan.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 120, height: 120)
                        .blur(radius: 20)
                        .scaleEffect(animate ? 1.2 : 0.8)
                    
                    Image(systemName: "building.2.crop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
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
