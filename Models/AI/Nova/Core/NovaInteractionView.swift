//
//  NovaInteractionView.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/16/25.
//


//
//  NovaInteractionView.swift
//  FrancoSphere v6.0
//
//  ✅ CLEAN: Nova AI Chat Interface
//  ✅ USES: Existing AIAssistantImageLoader from Assets.xcassets
//  ✅ INTEGRATES: With existing WorkerContextEngineAdapter
//  ✅ ALIGNS: With current FrancoSphere architecture
//

import SwiftUI
// COMPILATION FIX: Add missing imports
import Foundation


struct NovaInteractionView: View {
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var userQuery = ""
    @State private var messages: [NovaMessage] = []
    @State private var isProcessing = false
    @State private var showingTypingIndicator = false
    
    // Quick suggestions based on current context
    private let quickSuggestions = [
        "What should I prioritize today?",
        "Show me building efficiency insights",
        "Are there any urgent maintenance items?",
        "How is our portfolio performing?",
        "What patterns do you see in our data?"
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Nova header with AIAssistant image
                novaHeader
                
                // Chat messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if messages.isEmpty {
                                welcomeMessage
                            }
                            
                            ForEach(messages) { message in
                                NovaMessageBubble(message: message)
                            }
                            
                            // Typing indicator
                            if showingTypingIndicator {
                                typingIndicator
                            }
                        }
                        .padding()
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                    .overlay(alignment: .bottom) {
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                }
                
                // Quick suggestions (when no messages)
                if messages.isEmpty && !isProcessing {
                    quickSuggestionsView
                }
                
                // Input area
                novaInputBar
            }
            .background(Color.black)
            .navigationTitle("Nova AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        withAnimation {
                            messages.removeAll()
                        }
                    }
                    .foregroundColor(.white)
                    .disabled(messages.isEmpty)
                }
            }
        }
        .task {
            await loadInitialContext()
        }
    }
    
    // MARK: - Header with AIAssistant Image
    
    private var novaHeader: some View {
        VStack(spacing: 12) {
            // Use existing AIAssistantImageLoader
            AIAssistantImageLoader.circularAIAssistantView(
                diameter: 80,
                borderColor: isProcessing ? .purple : .blue
            )
            .overlay(
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.purple, .blue, .purple],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .rotationEffect(.degrees(isProcessing ? 360 : 0))
                    .animation(
                        .linear(duration: 2).repeatForever(autoreverses: false),
                        value: isProcessing
                    )
                    .opacity(isProcessing ? 1 : 0)
            )
            .shadow(color: .purple.opacity(0.5), radius: 10)
            
            Text("Nova AI")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Your Intelligent Portfolio Assistant")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Welcome Message
    
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AIAssistantImageLoader.circularAIAssistantView(diameter: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello! I'm Nova")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("I can help you with insights about your buildings, workers, and portfolio performance.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Try asking me about:")
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.top, 8)
            
            VStack(alignment: .leading, spacing: 8) {
                suggestionRow("📊", "Portfolio performance and efficiency")
                suggestionRow("🏢", "Building-specific insights")
                suggestionRow("⚡", "Priority tasks and recommendations")
                suggestionRow("🔧", "Maintenance patterns and predictions")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func suggestionRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    // MARK: - Quick Suggestions
    
    private var quickSuggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(quickSuggestions, id: \.self) { suggestion in
                    Button(action: {
                        userQuery = suggestion
                        sendMessage()
                    }) {
                        Text(suggestion)
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Typing Indicator
    
    private var typingIndicator: some View {
        HStack {
            AIAssistantImageLoader.circularAIAssistantView(diameter: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Nova is thinking...")
                    .font(.subheadline)
                    .foregroundColor(.purple)
                
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 6, height: 6)
                            .scaleEffect(showingTypingIndicator ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.2),
                                value: showingTypingIndicator
                            )
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Input Bar
    
    private var novaInputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Nova anything...", text: $userQuery, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isProcessing)
                .lineLimit(1...3)
                .onSubmit {
                    if !userQuery.isEmpty {
                        sendMessage()
                    }
                }
            
            Button(action: sendMessage) {
                Image(systemName: isProcessing ? "ellipsis" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(userQuery.isEmpty ? .gray : .blue)
                    .symbolEffect(.pulse, isActive: isProcessing)
            }
            .disabled(userQuery.isEmpty || isProcessing)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Actions
    
    private func sendMessage() {
        let query = userQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        userQuery = ""
        
        // Add user message
        let userMessage = NovaMessage(
            role: .user,
            content: query,
            timestamp: Date()
        )
        
        withAnimation {
            messages.append(userMessage)
        }
        
        // Process with Nova
        Task {
            await processNovaResponse(for: query)
        }
    }
    
    private func processNovaResponse(for query: String) async {
        isProcessing = true
        showingTypingIndicator = true
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Generate Nova response
        let response = await generateNovaResponse(for: query)
        
        showingTypingIndicator = false
        
        let novaMessage = NovaMessage(
            role: .assistant,
            content: response,
            timestamp: Date()
        )
        
        await MainActor.run {
            withAnimation {
                messages.append(novaMessage)
            }
            isProcessing = false
        }
    }
    
    private func generateNovaResponse(for query: String) async -> String {
        // Get current context
        guard let worker = contextAdapter.currentWorker else {
            return "I need to know who you are first. Please ensure you're logged in."
        }
        
        // Generate contextual response based on query
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("task") || lowercaseQuery.contains("assignment") {
            let taskCount = contextAdapter.todaysTasks.count
            let urgentCount = contextAdapter.getUrgentTaskCount()
            return "You have \(taskCount) tasks today, with \(urgentCount) marked as urgent. Your primary focus should be on the urgent tasks first. Would you like me to prioritize them for you?"
        }
        
        if lowercaseQuery.contains("building") {
            let buildingCount = contextAdapter.assignedBuildings.count
            let buildingNames = contextAdapter.assignedBuildings.map { $0.name }.joined(separator: ", ")
            return "You're assigned to \(buildingCount) buildings: \(buildingNames). Is there a specific building you'd like to know more about?"
        }
        
        if lowercaseQuery.contains("rubin") && worker.id == "4" {
            return "The Rubin Museum is one of your primary assignments. You handle specialized tasks there including climate control monitoring and artifact preservation protocols. Would you like me to check for any specific Rubin Museum tasks today?"
        }
        
        if lowercaseQuery.contains("coverage") || lowercaseQuery.contains("help") {
            return "I can help you with coverage information for any building in the portfolio. Just ask about a specific building and I'll provide complete intelligence including worker assignments, schedules, and emergency contacts."
        }
        
        if lowercaseQuery.contains("emergency") {
            return "For emergencies, contact building management immediately. I can provide emergency contacts and procedures for any building. Which building do you need emergency information for?"
        }
        
        if lowercaseQuery.contains("schedule") {
            return "Your typical schedule varies by building assignment. Would you like me to show you today's schedule or help you plan upcoming tasks?"
        }
        
        if lowercaseQuery.contains("priorit") || lowercaseQuery.contains("today") {
            let urgentTasks = contextAdapter.getUrgentTasks()
            let urgentCount = urgentTasks.count
            
            if urgentCount > 0 {
                return "I found \(urgentCount) urgent task\(urgentCount == 1 ? "" : "s") that need your attention today. These include maintenance items and priority inspections. Would you like me to break down the specific tasks by building?"
            } else {
                return "Great news! You don't have any urgent tasks today. Focus on your routine maintenance schedule and consider tackling some preventive maintenance items to stay ahead."
            }
        }
        
        // Default response with helpful suggestions
        return "I can help you with building intelligence, task management, worker assignments, and portfolio insights. Try asking about:\n\n• Your tasks for today\n• Building information\n• Coverage support\n• Emergency procedures\n• Schedule planning\n\nWhat specific information would you like?"
    }
    
    private func loadInitialContext() async {
        // Load any initial context if needed
        if let worker = contextAdapter.currentWorker {
            print("🧠 Nova initialized for worker: \(worker.name)")
        }
    }
}

// MARK: - Supporting Types

struct NovaMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole {
        case user
        case assistant
    }
}

struct NovaMessageBubble: View {
    let message: NovaMessage
    
    var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack {
                    if message.role == .assistant {
                        AIAssistantImageLoader.circularAIAssistantView(diameter: 24)
                    }
                    
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            message.role == .user ? 
                            Color.blue : Color.purple.opacity(0.3)
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .textSelection(.enabled)
                        .frame(maxWidth: 280, alignment: message.role == .user ? .trailing : .leading)
                    
                    if message.role == .user {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("U")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant { Spacer() }
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct NovaInteractionView_Previews: PreviewProvider {
    static var previews: some View {
        NovaInteractionView()
            .preferredColorScheme(.dark)
    }
}