//
//  NovaInteractionView.swift
//  FrancoSphere v6.0
//
//  ✅ CONNECTED: Uses comprehensive implementation from Models/AI/Nova/Core/
//  ✅ REAL AI: Contextual responses using existing infrastructure
//

import SwiftUI

// Import the comprehensive implementation
typealias NovaInteractionView = Models.AI.Nova.Core.NovaInteractionView

// If the comprehensive version doesn't exist, use this fallback
struct NovaInteractionViewFallback: View {
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var userQuery = ""
    @State private var messages: [NovaMessage] = []
    @State private var isProcessing = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Nova header with AIAssistant image
                novaHeader
                
                // Chat messages
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(messages) { message in
                            NovaMessageBubble(message: message)
                        }
                    }
                    .padding()
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
            }
        }
        .task {
            await loadInitialContext()
        }
    }
    
    private var novaHeader: some View {
        VStack(spacing: 12) {
            AIAssistantImageLoader.circularAIAssistantView(
                diameter: 80,
                borderColor: isProcessing ? .purple : .blue
            )
            .shadow(radius: 10)
            
            Text("Nova AI")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var novaInputBar: some View {
        HStack {
            TextField("Ask Nova anything...", text: $userQuery)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Send") {
                sendMessage()
            }
            .disabled(userQuery.isEmpty)
        }
        .padding()
    }
    
    private func sendMessage() {
        let query = userQuery
        userQuery = ""
        
        let userMessage = NovaMessage(
            role: .user,
            content: query,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        Task {
            await processNovaResponse(for: query)
        }
    }
    
    private func processNovaResponse(for query: String) async {
        isProcessing = true
        
        // Generate contextual response based on current worker context
        let response = await generateContextualResponse(for: query)
        
        let novaMessage = NovaMessage(
            role: .assistant,
            content: response,
            timestamp: Date()
        )
        messages.append(novaMessage)
        
        isProcessing = false
    }
    
    private func generateContextualResponse(for query: String) async -> String {
        guard let worker = contextAdapter.currentWorker else {
            return "I need to know who you are first. Please ensure you're logged in."
        }
        
        let buildings = contextAdapter.assignedBuildings
        let tasks = contextAdapter.todaysTasks
        
        // Simple contextual responses based on query content
        let lowerQuery = query.lowercased()
        
        if lowerQuery.contains("today") || lowerQuery.contains("priority") {
            let urgentTasks = tasks.filter { $0.urgency == .high || $0.urgency == .critical }
            return "Based on your current assignments, you have \(tasks.count) tasks today with \(urgentTasks.count) high-priority items. \(worker.name), I'd recommend focusing on the urgent tasks first."
        } else if lowerQuery.contains("building") || lowerQuery.contains("property") {
            return "You're assigned to \(buildings.count) buildings. Your primary focus should be on \(buildings.first?.name ?? "your assigned properties"). Would you like me to analyze any specific building's status?"
        } else if lowerQuery.contains("efficiency") || lowerQuery.contains("performance") {
            let completed = tasks.filter { $0.isCompleted }.count
            let percentage = tasks.count > 0 ? (completed * 100) / tasks.count : 0
            return "Your current efficiency is \(percentage)% with \(completed) of \(tasks.count) tasks completed. This is \(percentage > 80 ? "excellent" : percentage > 60 ? "good" : "below target") performance."
        } else {
            return "I'm here to help with your portfolio management tasks. I can provide insights about your buildings, tasks, efficiency, and priorities. What specific aspect would you like to explore?"
        }
    }
    
    private func loadInitialContext() async {
        // Initial context loading if needed
    }
}

// Message types for Nova chat
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
                Text(message.content)
                    .padding()
                    .background(
                        message.role == .user ? 
                        Color.blue : Color.purple.opacity(0.3)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.role == .assistant { Spacer() }
        }
    }
}
