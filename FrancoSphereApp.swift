//
//  FrancoSphereApp.swift
//  FrancoSphere
//
//  ✅ UNIFIED: Single initialization path using UnifiedDataInitializer
//  ✅ SIMPLIFIED: Removed all old system references
//  ✅ GRDB: Exclusively uses GRDB architecture
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    // UNIFIED: Single initializer reference
    @StateObject private var unifiedInitializer = UnifiedDataInitializer.shared
    @StateObject private var authManager = NewAuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if unifiedInitializer.isInitialized {
                    // App is ready - show main content
                    ContentView()
                        .environmentObject(authManager)
                } else {
                    // Show initialization screen
                    InitializationProgressView()
                        .environmentObject(unifiedInitializer)
                }
            }
            .task {
                await initializeApp()
            }
        }
    }
    
    private func initializeApp() async {
        do {
            print("🚀 Starting FrancoSphere v6.0 initialization...")
            
            // UNIFIED: Single initialization call
            try await unifiedInitializer.initializeIfNeeded()
            
            print("✅ FrancoSphere v6.0 initialization complete")
            
        } catch {
            print("❌ FrancoSphere initialization failed: \(error)")
            // The error is already stored in unifiedInitializer.error
        }
    }
}

// MARK: - Initialization Progress View

struct InitializationProgressView: View {
    @EnvironmentObject var initializer: UnifiedDataInitializer
    
    var body: some View {
        VStack(spacing: 20) {
            // App logo/branding
            Image(systemName: "building.2.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("FrancoSphere v6.0")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Initializing Portfolio Management System...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Progress indicator
            VStack(spacing: 10) {
                ProgressView(value: initializer.initializationProgress)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 200)
                
                Text(initializer.currentStep)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.3), value: initializer.currentStep)
            }
            
            // Error handling
            if let error = initializer.error {
                VStack(spacing: 10) {
                    Text("Initialization Error")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    
                    Button("Retry") {
                        Task {
                            await retryInitialization()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
    
    private func retryInitialization() async {
        do {
            #if DEBUG
            try await initializer.resetAndReinitialize()
            #else
            try await initializer.initializeIfNeeded()
            #endif
        } catch {
            print("❌ Retry initialization failed: \(error)")
        }
    }
}

// MARK: - Legacy System Removal Notes
/*
 ✅ REMOVED REFERENCES TO:
 - DataBootstrapper.runIfNeeded() → Now handled by UnifiedDataInitializer
 - Multiple initialization managers → Single UnifiedDataInitializer
 - Complex initialization flows → Simple .initializeIfNeeded()
 
 ✅ UNIFIED APPROACH:
 - Single @StateObject for UnifiedDataInitializer
 - Clear initialization → app ready flow
 - Proper error handling with retry capability
 - Development-friendly reset functionality
 
 ✅ BENEFITS:
 - Zero duplication
 - Single source of truth
 - Clear state management
 - Professional initialization experience
 */
