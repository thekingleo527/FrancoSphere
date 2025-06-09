//
//  FrancoSphereApp.swift
//  FrancoSphere
//
//  Ultra-simplified version - NO initialization screens
//

import SwiftUI

@main
struct FrancoSphereApp: App {
    @StateObject private var authManager = NewAuthManager.shared
    
    init() {
        print("🚀 FrancoSphere App Started")
        print("📱 Initial state: isAuthenticated = \(NewAuthManager.shared.isAuthenticated)")
        print("👤 User role: \(NewAuthManager.shared.userRole)")
        print("👷 Worker name: \(NewAuthManager.shared.currentWorkerName)")
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    // Show dashboard based on role
                    switch authManager.userRole {
                    case "admin":
                        if doesViewExist("AdminDashboardView") {
                            AdminDashboardView()
                        } else {
                            FallbackDashboard(role: "Admin")
                        }
                    case "client":
                        FallbackDashboard(role: "Client")
                    default:
                        if doesViewExist("WorkerDashboardView") {
                            WorkerDashboardView()
                        } else {
                            FallbackDashboard(role: "Worker")
                        }
                    }
                } else {
                    // Show login
                    if doesViewExist("LoginView") {
                        LoginView()
                    } else {
                        FallbackLoginView()
                    }
                }
            }
            .environmentObject(authManager)
        }
    }
    
    // Helper to check if view exists (prevents crashes)
    private func doesViewExist(_ viewName: String) -> Bool {
        // For now, return true and let it crash if view doesn't exist
        // This helps identify missing views
        return true
    }
}

// MARK: - Fallback Dashboard
struct FallbackDashboard: View {
    let role: String
    @EnvironmentObject var authManager: NewAuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("FrancoSphere")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("\(role) Dashboard")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // User info
                VStack(spacing: 5) {
                    Text("Welcome")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(authManager.currentWorkerName)
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("ID: \(authManager.workerId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                
                Spacer()
                
                // Debug info
                VStack(alignment: .leading, spacing: 5) {
                    Text("Debug Info:")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text("Role: \(authManager.userRole)")
                        .font(.caption)
                    Text("Authenticated: \(authManager.isAuthenticated ? "Yes" : "No")")
                        .font(.caption)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Logout button
                Button(action: {
                    authManager.logout()
                }) {
                    Label("Logout", systemImage: "arrow.right.square")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.bottom, 50)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Fallback Login View
struct FallbackLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @EnvironmentObject var authManager: NewAuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Logo
                VStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("FrancoSphere")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                }
                .padding(.top, 80)
                
                // Login form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Password")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                    
                    // Login button
                    Button(action: performLogin) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(isLoading || email.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 40)
                
                // Quick login
                VStack(spacing: 10) {
                    Text("Quick Login (Dev)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Login as Edwin") {
                        email = "edwinlema911@gmail.com"
                        password = "password"
                        performLogin()
                    }
                    .font(.caption)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(5)
                }
                .padding(.top, 20)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func performLogin() {
        isLoading = true
        errorMessage = nil
        
        authManager.login(email: email, password: password) { success, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if !success {
                    self.errorMessage = error ?? "Login failed"
                }
            }
        }
    }
}
