//
//  NovaInteractionView.swift
//  FrancoSphere v6.0 - MINIMAL FALLBACK VERSION
//

import SwiftUI

struct NovaInteractionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userQuery = ""
    @State private var response = "Hello! I'm Nova AI, your portfolio assistant. The full chat interface will be available once the existing comprehensive version is properly connected."
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    AIAssistantImageLoader.circularAIAssistantView(diameter: 80)
                        .shadow(radius: 10)
                    
                    Text("Nova AI")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                Spacer()
                
                // Response area
                ScrollView {
                    Text(response)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Input
                HStack {
                    TextField("Ask Nova anything...", text: $userQuery)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Send") {
                        if !userQuery.isEmpty {
                            response = "Thanks for asking: '\(userQuery)'. The full Nova AI chat interface with contextual responses is ready to be connected."
                            userQuery = ""
                        }
                    }
                    .disabled(userQuery.isEmpty)
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Nova AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    NovaInteractionView()
}
