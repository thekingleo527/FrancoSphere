//
//  SignUpView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/1/25.
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .worker
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    // Matching styling from LoginView
    private let bgColor = Color(red: 0.20, green: 0.20, blue: 0.22)
    private let buttonColor = Color(red: 0.34, green: 0.34, blue: 0.8)
    
    var body: some View {
        ZStack {
            bgColor.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .imageScale(.large)
                        }
                        
                        Spacer()
                        
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Empty view for balance
                        Color.clear.frame(width: 24, height: 24)
                    }
                    .padding()
                    
                    // Logo
                    Image(systemName: "person.badge.plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Join FrancoSphere")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Create your account to access building maintenance tools")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    
                    // Form fields
                    VStack(spacing: 15) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            TextField("", text: $fullName)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                        }
                        
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            TextField("", text: $email)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            SecureField("", text: $password)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                        }
                        
                        // Confirm Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            SecureField("", text: $confirmPassword)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                        }
                        
                        // Role Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Account Type")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Picker("Select Role", selection: $selectedRole) {
                                Text("Worker").tag(UserRole.worker)
                                Text("Manager").tag(UserRole.manager)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .background(Color.white.opacity(0.2))
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .padding(.horizontal, 30)
                            .padding(.top, 5)
                    }
                    
                    // Sign Up button
                    Button(action: createAccount) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("CREATE ACCOUNT")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                        }
                    }
                    .background(buttonColor)
                    .cornerRadius(10)
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    .disabled(isLoading)
                    
                    // Return to login
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Already have an account? Login")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.vertical, 20)
                }
            }
        }
    }
    
    func createAccount() {
        // Validate inputs
        errorMessage = nil
        
        guard !fullName.isEmpty else {
            errorMessage = "Please enter your full name"
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        guard !password.isEmpty else {
            errorMessage = "Please enter a password"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }
        
        isLoading = true
        
        // Simulate account creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            // In a real app, you'd call AuthManager to create an account
            // After success, dismiss this view to return to login
            presentationMode.wrappedValue.dismiss()
            
            // In a production app:
            // AuthManager.shared.createAccount(name: fullName, email: email, password: password, role: selectedRole) { result in ... }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
    }
}
