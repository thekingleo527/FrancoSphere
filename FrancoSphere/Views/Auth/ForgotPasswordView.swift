//
//  ForgotPasswordView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/1/25.
//


import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var message: String?
    @State private var isSuccess = false
    @State private var isLoading = false
    
    // Matching styling from LoginView
    private let bgColor = Color(red: 0.20, green: 0.20, blue: 0.22)
    private let buttonColor = Color(red: 0.34, green: 0.34, blue: 0.8)
    
    var body: some View {
        ZStack {
            bgColor.edgesIgnoringSafeArea(.all)
            
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
                    
                    Text("Reset Password")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty view for balance
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding()
                
                Spacer()
                
                // Logo
                Image(systemName: "lock.rotation")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(.white)
                    .padding(.bottom, 20)
                
                Text("Forgot Your Password?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                
                // Email input
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
                .padding(.horizontal, 30)
                
                // Status message
                if let message = message {
                    Text(message)
                        .foregroundColor(isSuccess ? .green : .red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                }
                
                // Submit button
                Button(action: sendResetLink) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("SEND RESET LINK")
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
                
                Spacer()
                
                // Return to login
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back to Login")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 30)
            }
        }
    }
    
    func sendResetLink() {
        guard !email.isEmpty else {
            message = "Please enter your email address"
            isSuccess = false
            return
        }
        
        isLoading = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isSuccess = true
            message = "Password reset link has been sent to your email"
            
            // In a real app, you'd call an API here
            // AuthManager.shared.sendPasswordReset(email: email) { result in ... }
        }
    }
}