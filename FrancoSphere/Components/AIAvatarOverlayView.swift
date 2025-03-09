import SwiftUI

struct AIAvatarOverlayView: View {
    @ObservedObject private var aiManager = AIAssistantManager.shared
    @State private var isExpanded = false
    @State private var isPulsing = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                ZStack {
                    // Message bubble (when expanded)
                    if isExpanded && aiManager.currentScenario != nil {
                        assistantMessageView
                            .offset(y: -120)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Avatar button (always visible)
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            // Pulsing background for attention
                            if aiManager.currentScenario != nil && !isExpanded {
                                Circle()
                                    .fill(FrancoSphereColors.deepNavy.opacity(0.4))
                                    .frame(width: isPulsing ? 70 : 60, height: isPulsing ? 70 : 60)
                                    .animation(
                                        Animation.easeInOut(duration: 1.0)
                                            .repeatForever(autoreverses: true),
                                        value: isPulsing
                                    )
                            }
                            
                            // Main avatar image
                            Circle()
                                .fill(FrancoSphereColors.deepNavy)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.3), radius: 5)
                                .overlay(
                                    // The assistant image - using the human image provided
                                    Image("AIAssistant") // Make sure the image is added to Assets
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                )
                        }
                    }
                    .onAppear {
                        // Start pulsing animation
                        isPulsing = true
                    }
                }
                .padding(.bottom, 40)
                .padding(.trailing, 20)
            }
        }
        .animation(.spring(), value: isExpanded)
        .zIndex(100) // Ensure it stays on top
        // Debug trigger to test the AI assistant (comment out for production)
        .onAppear {
            #if DEBUG
            let debugMode = true // Set to false to disable debug trigger
            if debugMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    AIAssistantManager.trigger(for: .pendingTasks)
                }
            }
            #endif
        }
    }
    
    private var assistantMessageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Small avatar image in message bubble
                Image("AIAssistant")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding(.trailing, 4)
                
                Text(aiManager.currentScenario?.title ?? "Assistant")
                    .font(.headline)
                    .foregroundColor(FrancoSphereColors.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded = false
                        aiManager.dismissCurrentScenario()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(FrancoSphereColors.textSecondary)
                }
            }
            
            Text(aiManager.currentScenario?.message ?? "")
                .font(.body)
                .foregroundColor(FrancoSphereColors.textPrimary)
                .padding(.vertical, 8)
            
            if let scenario = aiManager.currentScenario {
                Button(action: {
                    aiManager.performAction()
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Text(scenario.actionText)
                        .fontWeight(.medium)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(FrancoSphereColors.accentBlue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding()
        .background(FrancoSphereColors.cardBackground)
        .cornerRadius(16)
        .shadow(radius: 5)
        .frame(width: UIScreen.main.bounds.width - 60)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all) // Dark background for preview
        AIAvatarOverlayView()
    }
}
