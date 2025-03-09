import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @StateObject private var authManager = AuthManager.shared
    
    // Real worker emails
    private let workerEmails = [
        "g.hutson1989@gmail.com",        // Greg Hutson
        "edwinlema911@gmail.com",        // Edwin Lema
        "josesantos14891989@gmail.com",  // Jose Santos
        "dutankevin1@gmail.com",         // Kevin Dutan
        "Jneola@gmail.com",              // Mercedes Inamagua
        "luislopez030@yahoo.com",        // Luis Lopez
        "lio.angel71@gmail.com",         // Angel Guirachocha
        "shawn@francomanagementgroup.com" // Shawn Magloire (worker)
    ]
    
    // Admin and client emails
    private let specialEmails = [
        "FrancoSphere@francomanagementgroup.com", // Shawn Magloire (client)
        "Shawn@fme-llc.com"                       // Shawn Magloire (admin)
    ]
    
    // All available emails for quick login
    private var allEmails: [String] {
        return workerEmails + specialEmails
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.3, green: 0.4, blue: 0.7)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Content
            VStack(spacing: 20) {
                Spacer()
                
                // Logo and app name
                VStack(spacing: 10) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                    
                    Text("FrancoSphere")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Building Maintenance Management")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 40)
                
                // Login form
                VStack(spacing: 20) {
                    // Email field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.white.opacity(0.8))
                            
                            TextField("", text: $email)
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .placeholder(when: email.isEmpty) {
                                    Text("Enter your email")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        
                        Menu {
                            Section("Workers") {
                                ForEach(workerEmails, id: \.self) { workerEmail in
                                    Button(action: {
                                        email = workerEmail
                                        password = "password" // Default password for testing
                                    }) {
                                        Text(workerEmail)
                                    }
                                }
                            }
                            
                            Section("Admin/Client") {
                                ForEach(specialEmails, id: \.self) { specialEmail in
                                    Button(action: {
                                        email = specialEmail
                                        password = "password" // Default password for testing
                                    }) {
                                        Text(specialEmail)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text("Quick Login")
                                    .font(.caption)
                                Image(systemName: "person.fill")
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 4)
                    }
                    
                    // Password field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.white.opacity(0.8))
                            
                            if showPassword {
                                TextField("", text: $password)
                                    .foregroundColor(.white)
                                    .disableAutocorrection(true)
                                    .autocapitalization(.none)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Enter your password")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                            } else {
                                SecureField("", text: $password)
                                    .foregroundColor(.white)
                                    .placeholder(when: password.isEmpty) {
                                        Text("Enter your password")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                            }
                            
                            Button(action: {
                                showPassword.toggle()
                            }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(10)
                        
                        Text("For testing: use 'password'")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.top, 4)
                    }
                    
                    // Error message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                    
                    // Login button
                    Button(action: {
                        login()
                    }) {
                        HStack {
                            Text("LOG IN")
                                .fontWeight(.bold)
                            
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.leading, 10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isValidForm
                                ? Color.blue
                                : Color.blue.opacity(0.5)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isValidForm || isLoading)
                    .padding(.top, 10)
                    
                    // User type selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Access:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Group {
                            quickAccessButton(email: "shawn@francomanagementgroup.com", label: "Worker Access", icon: "wrench.and.screwdriver")
                            quickAccessButton(email: "FrancoSphere@francomanagementgroup.com", label: "Client Access", icon: "person.text.rectangle")
                            quickAccessButton(email: "Shawn@fme-llc.com", label: "Admin Access", icon: "shield.checkerboard")
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.top, 20)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Footer
                Text("© 2025 Franco Management Enterprises")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 40)
        }
    }
    
    // Quick access button helper
    private func quickAccessButton(email: String, label: String, icon: String) -> some View {
        Button(action: {
            self.email = email
            self.password = "password"
            login()
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(12)
            .background(Color.white.opacity(0.15))
            .cornerRadius(8)
        }
    }
    
    // Form validation
    private var isValidForm: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    // Login function
    private func login() {
        isLoading = true
        errorMessage = nil
        
        authManager.login(email: email, password: password) { success, error in
            isLoading = false
            if !success {
                errorMessage = error ?? "Login failed"
            }
        }
    }
}

// Helper extension for placeholder text
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

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
