//
//  LoginView.swift
//  FrancoSphere
//
//  Glassmorphism-enhanced login with AbstractFrancoSphereLogo - FIXED
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @StateObject private var authManager = NewAuthManager.shared
    
    // Animation states
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -90
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    @State private var quickAccessOffset: CGFloat = 30
    @State private var quickAccessOpacity: Double = 0
    @State private var backgroundOpacity: Double = 0
    
    // Real worker emails from NewAuthManager
    private let workerEmails = [
        "g.hutson1989@gmail.com",        // Greg Hutson
        "edwinlema911@gmail.com",        // Edwin Lema
        "dutankevin1@gmail.com",         // Kevin Dutan
        "jneola@gmail.com",              // Mercedes Inamagua
        "luislopez030@yahoo.com",        // Luis Lopez
        "lio.angel71@gmail.com",         // Angel Guirachocha
        "shawn@francomanagementgroup.com" // Shawn Magloire (worker)
    ]
    
    // Admin and client emails
    private let specialEmails = [
        "francosphere@francomanagementgroup.com", // Shawn Magloire (client)
        "shawn@fme-llc.com"                       // Shawn Magloire (admin)
    ]

    var body: some View {
        ZStack {
            // Enhanced gradient background
            ZStack {
                // Base gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.25),
                        Color(red: 0.15, green: 0.2, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Animated gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                        Color(red: 0.48, green: 0.73, blue: 1.0).opacity(0.2)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
                .opacity(backgroundOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 1.5)) {
                        backgroundOpacity = 1.0
                    }
                }
            }
            
            // Main content
            ScrollView {
                VStack(spacing: 30) {
                    // Logo section with glass enhancement
                    VStack(spacing: 24) {
                        // Glass-backed logo
                        ZStack {
                            // Animated glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .blur(radius: 20)
                                .scaleEffect(logoScale * 1.5)
                            
                            // Glass backing
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 140, height: 140)
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
                                            lineWidth: 1
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 20, y: 10)
                            
                            // Logo
                            AbstractFrancoSphereLogo(size: 100)
                                .rotationEffect(.degrees(logoRotation))
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                        
                        // App name
                        VStack(spacing: 8) {
                            Text("FrancoSphere")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            Color.white,
                                            Color.white.opacity(0.9)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 2, y: 2)
                            
                            Text("Building Maintenance Management")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.8))
                                .tracking(0.5)
                        }
                        .opacity(logoOpacity)
                    }
                    .padding(.top, 60)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                            logoRotation = 0
                        }
                    }
                    
                    // Login form in glass card
                    GlassCard(intensity: .regular, cornerRadius: 24) {
                        VStack(spacing: 20) {
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    TextField("Enter your email", text: $email)
                                        .foregroundColor(.white)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .placeholder(when: email.isEmpty) {
                                            Text("Enter your email")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                
                                // Quick select menu
                                Menu {
                                    Section("Workers") {
                                        ForEach(workerEmails, id: \.self) { workerEmail in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    email = workerEmail
                                                    password = "password"
                                                }
                                            }) {
                                                Text(workerEmail)
                                            }
                                        }
                                    }
                                    
                                    Section("Admin/Client") {
                                        ForEach(specialEmails, id: \.self) { specialEmail in
                                            Button(action: {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    email = specialEmail
                                                    password = "password"
                                                }
                                            }) {
                                                Text(specialEmail)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("Quick Login")
                                            .font(.caption)
                                        Image(systemName: "person.crop.circle")
                                            .font(.caption)
                                    }
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.2))
                                    .cornerRadius(8)
                                }
                                .padding(.top, 4)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.white.opacity(0.9))
                                
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    if showPassword {
                                        TextField("Enter your password", text: $password)
                                            .foregroundColor(.white)
                                            .disableAutocorrection(true)
                                            .autocapitalization(.none)
                                            .placeholder(when: password.isEmpty) {
                                                Text("Enter your password")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                    } else {
                                        SecureField("Enter your password", text: $password)
                                            .foregroundColor(.white)
                                            .placeholder(when: password.isEmpty) {
                                                Text("Enter your password")
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                    }
                                    
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            showPassword.toggle()
                                        }
                                    }) {
                                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.7))
                                            .frame(width: 20)
                                    }
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                                
                                Text("For testing: use 'password'")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.top, 4)
                            }
                            
                            // Error message
                            if let errorMessage = errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                    
                                    Text(errorMessage)
                                        .font(.caption)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(8)
                                .transition(.scale.combined(with: .opacity))
                            }
                            
                            // Login button - FIXED: action closure at the end
                            GlassButton(
                                "LOG IN",
                                style: .primary,
                                size: .large,
                                isFullWidth: true,
                                isDisabled: !isValidForm,
                                isLoading: isLoading
                            ) {
                                performLogin()
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: formOffset)
                    .opacity(formOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.4)) {
                            formOffset = 0
                            formOpacity = 1
                        }
                    }
                    
                    // Quick access section
                    GlassCard(intensity: .thin, cornerRadius: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Quick Access")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 12) {
                                quickAccessButton(
                                    email: "shawn@francomanagementgroup.com",
                                    label: "Worker Access",
                                    icon: "wrench.and.screwdriver",
                                    color: .blue
                                )
                                
                                quickAccessButton(
                                    email: "francosphere@francomanagementgroup.com",
                                    label: "Client Access",
                                    icon: "person.text.rectangle",
                                    color: .green
                                )
                                
                                quickAccessButton(
                                    email: "shawn@fme-llc.com",
                                    label: "Admin Access",
                                    icon: "shield.checkmark",
                                    color: .purple
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .offset(y: quickAccessOffset)
                    .opacity(quickAccessOpacity)
                    .onAppear {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6)) {
                            quickAccessOffset = 0
                            quickAccessOpacity = 1
                        }
                    }
                    
                    // Footer
                    Text("© 2025 Franco Management Enterprises")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func quickAccessButton(email: String, label: String, icon: String, color: Color) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.email = email
                self.password = "password"
            }
            performLogin()
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    private func performLogin() {
        guard !isLoading else { return }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isLoading = true
            errorMessage = nil
        }
        
        authManager.login(email: email, password: password) { success, error in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.isLoading = false
                    
                    if !success {
                        self.errorMessage = error ?? "Login failed. Please try again."
                    } else {
                        print("✅ Login successful for: \(self.authManager.currentWorkerName)")
                        print("   Role: \(self.authManager.userRole)")
                        print("   Worker ID: \(self.authManager.workerId)")
                    }
                }
            }
        }
    }
}

// MARK: - Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .preferredColorScheme(.dark)
    }
}
