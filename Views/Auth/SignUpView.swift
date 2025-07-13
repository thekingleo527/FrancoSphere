//
//  SignUpView.swift
//  FrancoSphere
//
//  Glassmorphism-enhanced sign up with multi-step flow
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    
    // Form data
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: UserRole = .worker
    @State private var phoneNumber = ""
    @State private var selectedBuildings: Set<String> = []
    
    // UI state
    @State private var currentStep = 1
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showSuccess = false
    
    // Animation states
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    @State private var contentOpacity: Double = 0
    @State private var progressOpacity: Double = 0
    
    // Available buildings for selection
    private let availableBuildings = [
        "12 West 18th Street",
        "29-31 East 20th Street",
        "36 Walker Street",
        "41 Elizabeth Street",
        "68 Perry Street",
        "104 Franklin Street"
    ]
    
    private let totalSteps = 3
    
    var body: some View {
        ZStack {
            // Background gradient (matching LoginView)
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.25),
                        Color(red: 0.15, green: 0.2, blue: 0.35)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.29, green: 0.56, blue: 0.89).opacity(0.3),
                        Color(red: 0.48, green: 0.73, blue: 1.0).opacity(0.2)
                    ]),
                    startPoint: .topTrailing,
                    endPoint: .bottomLeading
                )
                .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: 0) {
                // Glass navigation header
                GlassCard(intensity: .ultraThin, cornerRadius: 0, padding: 0) {
                    HStack {
                        Button(action: {
                            if currentStep > 1 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentStep -= 1
                                }
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text(currentStep > 1 ? "Back" : "Cancel")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text("Create Account")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Balance spacer
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .opacity(0)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .edgesIgnoringSafeArea(.top)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo section
                        VStack(spacing: 20) {
                            ZStack {
                                // Glass backing
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 100, height: 100)
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
                                    .shadow(color: Color.black.opacity(0.3), radius: 15, y: 8)
                                
                                AbstractFrancoSphereLogo(size: 70)
                            }
                            .scaleEffect(logoScale)
                            .opacity(logoOpacity)
                            
                            VStack(spacing: 8) {
                                Text("Join FrancoSphere")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                
                                Text("Create your account to get started")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.top, 20)
                        .onAppear {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                                logoScale = 1.0
                                logoOpacity = 1.0
                            }
                        }
                        
                        // Progress indicator
                        StepProgressIndicator(
                            currentStep: currentStep,
                            totalSteps: totalSteps
                        )
                        .padding(.horizontal, 40)
                        .opacity(progressOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.4).delay(0.4)) {
                                progressOpacity = 1.0
                            }
                        }
                        
                        // Step content
                        Group {
                            switch currentStep {
                            case 1:
                                Step1AccountInfo
                            case 2:
                                Step2PersonalInfo
                            case 3:
                                Step3RoleSelection
                            default:
                                Step1AccountInfo
                            }
                        }
                        .padding(.horizontal, 24)
                        .offset(y: contentOffset)
                        .opacity(contentOpacity)
                        .onAppear {
                            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.3)) {
                                contentOffset = 0
                                contentOpacity = 1
                            }
                        }
                        .onChange(of: currentStep) { _ in
                            // Reset animation for step changes
                            contentOffset = 30
                            contentOpacity = 0
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                contentOffset = 0
                                contentOpacity = 1
                            }
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
                            .padding(.horizontal, 24)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
            
            // Success overlay
            if showSuccess {
                SuccessOverlay()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Step 1: Account Information
    
    private var Step1AccountInfo: some View {
        GlassCard(intensity: .regular, cornerRadius: 24) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Step 1 of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Account Information")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Email field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    GlassTextField(
                        icon: "envelope.fill",
                        placeholder: "Enter your email",
                        text: $email,
                        keyboardType: .emailAddress
                    )
                }
                
                // Password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    GlassTextField(
                        icon: "lock.fill",
                        placeholder: "Create a password",
                        text: $password,
                        isSecure: true
                    )
                    
                    PasswordStrengthIndicator(password: password)
                        .padding(.top, 4)
                }
                
                // Confirm password field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm Password")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    GlassTextField(
                        icon: "lock.fill",
                        placeholder: "Confirm your password",
                        text: $confirmPassword,
                        isSecure: true
                    )
                    
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                            Text("Passwords don't match")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .padding(.top, 4)
                    }
                }
                
                // Next button
                GlassButton(
                    "Continue",
                    style: .primary,
                    size: .large,
                    isFullWidth: true,
                    isDisabled: !isStep1Valid,
                    icon: "arrow.right"
                ) {
                    validateAndProceed()
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Step 2: Personal Information
    
    private var Step2PersonalInfo: some View {
        GlassCard(intensity: .regular, cornerRadius: 24) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Step 2 of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Personal Information")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Full name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Name")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    GlassTextField(
                        icon: "person.fill",
                        placeholder: "Enter your full name",
                        text: $fullName
                    )
                }
                
                // Phone number field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone Number")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    GlassTextField(
                        icon: "phone.fill",
                        placeholder: "Enter your phone number",
                        text: $phoneNumber,
                        keyboardType: .phonePad
                    )
                }
                
                // Building assignment
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assigned Buildings")
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Select the buildings you'll be working at")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(availableBuildings, id: \.self) { building in
                            BuildingSelectionChip(
                                building: building,
                                isSelected: selectedBuildings.contains(building)
                            ) {
                                toggleBuilding(building)
                            }
                        }
                    }
                }
                
                // Next button
                GlassButton(
                    "Continue",
                    style: .primary,
                    size: .large,
                    isFullWidth: true,
                    isDisabled: !isStep2Valid,
                    icon: "arrow.right"
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = 3
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Step 3: Role Selection
    
    private var Step3RoleSelection: some View {
        GlassCard(intensity: .regular, cornerRadius: 24) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Step 3 of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Select Your Role")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                Text("Choose the role that best describes your position")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // Role options
                VStack(spacing: 12) {
                    RoleSelectionCard(
                        role: .worker,
                        title: "Maintenance Worker",
                        description: "Perform daily maintenance tasks and building upkeep",
                        icon: "wrench.and.screwdriver",
                        isSelected: selectedRole == .worker
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRole = .worker
                        }
                    }
                    
                    RoleSelectionCard(
                        role: .manager,
                        title: "Building Manager",
                        description: "Oversee operations and manage maintenance teams",
                        icon: "person.2.badge.gearshape",
                        isSelected: selectedRole == .manager
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedRole = .manager
                        }
                    }
                }
                
                // Create account button
                GlassButton(
                    isLoading ? "Creating Account..." : "Create Account",
                    style: .primary,
                    size: .large,
                    isFullWidth: true,
                    isLoading: isLoading,
                    icon: "checkmark"
                ) {
                    createAccount()
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isStep1Valid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private var isStep2Valid: Bool {
        !fullName.isEmpty &&
        !phoneNumber.isEmpty &&
        !selectedBuildings.isEmpty
    }
    
    private func validateAndProceed() {
        errorMessage = nil
        
        // Validate email format
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email address"
            return
        }
        
        // Validate password
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords don't match"
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep = 2
        }
    }
    
    private func toggleBuilding(_ building: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedBuildings.contains(building) {
                selectedBuildings.remove(building)
            } else {
                selectedBuildings.insert(building)
            }
        }
    }
    
    private func createAccount() {
        errorMessage = nil
        isLoading = true
        
        // Simulate account creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                isLoading = false
                showSuccess = true
            }
            
            // Dismiss after showing success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Supporting Components

struct GlassTextField: View {
    let icon: String
    let placeholder: String
    @State var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @State private var showSecureText = false
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure && !showSecureText {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.5))
                    }
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder)
                            .foregroundColor(.white.opacity(0.5))
                    }
            }
            
            if isSecure {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSecureText.toggle()
                    }
                }) {
                    Image(systemName: showSecureText ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 20)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StepProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step < currentStep {
                    // Completed step
                    Circle()
                        .fill(Color.green)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                } else if step == currentStep {
                    // Current step
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.blue.opacity(0.5), lineWidth: 3)
                                .frame(width: 40, height: 40)
                                .scaleEffect(1.2)
                                .opacity(0.5)
                                .animation(
                                    Animation.easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true),
                                    value: currentStep
                                )
                        )
                } else {
                    // Future step
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(step)")
                                .font(.caption.bold())
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? Color.green : Color.white.opacity(0.2))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: Int {
        var score = 0
        if password.count >= 6 { score += 1 }
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters) != nil { score += 1 }
        return min(score, 4)
    }
    
    private var strengthText: String {
        switch strength {
        case 0: return "Very Weak"
        case 1: return "Weak"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Strong"
        default: return "Very Weak"
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .blue
        case 4: return .green
        default: return .red
        }
    }
    
    var body: some View {
        if !password.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(index < strength ? strengthColor : Color.white.opacity(0.2))
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                
                Text("Password strength: \(strengthText)")
                    .font(.caption2)
                    .foregroundColor(strengthColor)
            }
        }
    }
}

struct BuildingSelectionChip: View {
    let building: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(building)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue.opacity(0.3) : Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoleSelectionCard: View {
    let role: UserRole
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(isSelected ? .blue : .white.opacity(0.7))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SuccessOverlay: View {
    @State private var checkmarkScale: CGFloat = 0
    @State private var checkmarkOpacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(.green)
                        .scaleEffect(checkmarkScale)
                        .opacity(checkmarkOpacity)
                }
                
                VStack(spacing: 8) {
                    Text("Account Created!")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Text("Welcome to FrancoSphere")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    checkmarkScale = 1.0
                    checkmarkOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - Preview

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .preferredColorScheme(.dark)
    }
}
