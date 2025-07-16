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
//  Nova AI Chat Interface - Uses existing AIAssistant.png
//

import SwiftUI

struct NovaInteractionView: View {
    @StateObject private var novaCore = NovaCore.shared
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @StateObject private var operationalData = OperationalDataManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var userQuery = ""
    @State private var messages: [NovaMessage] = []
    @State private var isProcessing = false
    @State private var showingTypingIndicator = false
    
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
                
                // Input area
                novaInputBar
            }
            .background(Color.black)
            .navigationTitle("Nova AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.blue)
                }
            }
        }
        .task {
            await loadInitialContext()
        }
    }
    
    private var novaHeader: some View {
        VStack(spacing: 12) {
            // Use AIAssistantImageLoader for consistent loading
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
    
    private var welcomeMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                AIAssistantImageLoader.circularAIAssistantView(diameter: 32)
                Text("Nova AI")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.purple)
                Spacer()
            }
            
            Text("Hello! I'm Nova, your intelligent portfolio assistant. I can help you with:")
                .font(.body)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Building intelligence and insights")
                Text("• Task optimization and scheduling")
                Text("• Worker assignments and coverage")
                Text("• Performance analytics and trends")
                Text("• Emergency procedures and contacts")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding(.leading, 16)
            
            Text("What would you like to know?")
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var typingIndicator: some View {
        HStack {
            AIAssistantImageLoader.circularAIAssistantView(diameter: 32)
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.purple)
                        .frame(width: 8, height: 8)
                        .scaleEffect(showingTypingIndicator ? 1.2 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: showingTypingIndicator
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(16)
            
            Spacer()
        }
        .padding(.horizontal)
    }
    
    private var novaInputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask Nova anything...", text: $userQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .disabled(isProcessing)
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
        messages.append(userMessage)
        
        // Process with Nova
        Task {
            await processNovaResponse(for: query)
        }
    }
    
    private func processNovaResponse(for query: String) async {
        isProcessing = true
        showingTypingIndicator = true
        
        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Generate Nova response
        let response = await generateNovaResponse(for: query)
        
        showingTypingIndicator = false
        
        let novaMessage = NovaMessage(
            role: .assistant,
            content: response,
            timestamp: Date()
        )
        
        await MainActor.run {
            messages.append(novaMessage)
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
                    
                    if message.role == .user {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text(message.role == .user ? "You" : "AI")
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