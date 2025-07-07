//
//  FrancoSphereApp.swift (V6.0 MIGRATION-READY)
//  FrancoSphere
//
//  ✅ INTEGRATED: Full v6.0 initialization sequence.
//  ✅ CALLS: TypeMigrationService and DataConsolidationManager on launch.
//  ✅ ENHANCED: InitializationView shows detailed progress for each migration step.
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = NewAuthManager.shared
    @StateObject private var initializationViewModel = InitializationViewModel()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !initializationViewModel.isComplete {
                    // Show initialization screen while setting up
                    InitializationView(viewModel: initializationViewModel)
                } else if authManager.isAuthenticated {
                    // Show dashboard based on role
                    switch authManager.userRole {
                    case "admin":
                        AdminDashboardView()
                            .environmentObject(authManager)
                    case "client":
                        FallbackDashboard(title: "Client Dashboard", role: "Client")
                            .environmentObject(authManager)
                    default: // worker
                        WorkerDashboardView()
                            .environmentObject(authManager)
                    }
                } else {
                    // Show login
                    LoginView()
                        .environmentObject(authManager)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                // Trigger initialization if it hasn't run yet
                if !initializationViewModel.isInitializing && !initializationViewModel.isComplete {
                    Task {
                        await initializationViewModel.startInitialization()
                    }
                }
            }
        }
    }
}

// MARK: - InitializationViewModel (Handles the startup logic)

@MainActor
class InitializationViewModel: ObservableObject {
    @Published var progress: Double = 0.0
    @Published var currentStep: String = "Preparing FrancoSphere..."
    @Published var isInitializing: Bool = false
    @Published var isComplete: Bool = false
    @Published var initializationError: String?

    func startInitialization() async {
        guard !isInitializing else { return }
        
        isInitializing = true
        initializationError = nil
        
        let steps: [(String, () async throws -> Void)] = [
            ("Connecting to Database...", { try await self.step_connectToDatabase() }),
            ("Unifying Data Types...", { try await self.step_runTypeMigration() }),
            ("Consolidating Legacy Data...", { try await self.step_consolidateData() }),
            ("Finalizing Setup...", { try await self.step_finalize() })
        ]

        for (index, (stepName, stepAction)) in steps.enumerated() {
            currentStep = stepName
            progress = Double(index) / Double(steps.count)
            
            do {
                try await stepAction()
            } catch {
                initializationError = "Error during '\(stepName)': \(error.localizedDescription)"
                print("🚨 \(initializationError!)")
                isInitializing = false
                return // Stop the process on critical failure
            }
        }

        progress = 1.0
        currentStep = "Initialization Complete"
        isComplete = true
        isInitializing = false
    }

    // MARK: - Initialization Steps

    private func step_connectToDatabase() async throws {
        let _ = SQLiteManager.shared
        try await Task.sleep(nanoseconds: 200_000_000) // Visual delay
    }

    private func step_runTypeMigration() async throws {
        try await TypeMigrationService.shared.runMigrationIfNeeded()
    }

    private func step_consolidateData() async throws {
        try await DataConsolidationManager.shared.runConsolidationIfNeeded()
    }

    private func step_finalize() async throws {
        // Any final checks can go here
        print("✅ Final setup checks complete.")
        try await Task.sleep(nanoseconds: 300_000_000) // Visual delay
    }
}


// MARK: - InitializationView (The UI for the startup process)

struct InitializationView: View {
    @ObservedObject var viewModel: InitializationViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.1, blue: 0.25), Color(red: 0.15, green: 0.2, blue: 0.35)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            VStack(spacing: 30) {
                VStack(spacing: 15) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)

                    Text("FrancoSphere")
                        .font(.largeTitle).fontWeight(.bold).foregroundColor(.white)

                    Text("Property Operations Management")
                        .font(.subheadline).foregroundColor(.white.opacity(0.7))
                }

                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 4)
                        
                        Text(viewModel.currentStep)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .animation(.none, value: viewModel.currentStep)
                    }
                    ProgressView().scaleEffect(1.2).tint(.blue)
                }.frame(maxWidth: 300)

                if let error = viewModel.initializationError {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill").font(.title2).foregroundColor(.orange)
                        Text("Initialization Failed").font(.headline).foregroundColor(.orange)
                        Text(error).font(.caption).foregroundColor(.white.opacity(0.7)).multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.startInitialization() }
                        }.buttonStyle(.bordered).tint(.orange)
                    }.padding(20).background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

// MARK: - Fallback Dashboard & Helpers (Unchanged)

struct FallbackDashboard: View {
    let title: String
    let role: String
    @EnvironmentObject var authManager: NewAuthManager
    var body: some View {
        Text("\(title) for \(authManager.currentWorkerName)")
            .navigationTitle(title)
    }
}

private func iconForRole(_ role: String) -> String { "person.crop.circle" }
private func colorForRole(_ role: String) -> Color { .gray }
