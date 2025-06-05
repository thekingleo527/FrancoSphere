// AIAvatarOverlayView.swift
// ––––––––––––––––––––––––––––––––––––––––––––––––––––––––
// Displays the little avatar “bubble” in bottom-right corner.

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
                    // If expanded and there’s a scenario, show the bubble:
                    if isExpanded, let scenario = aiManager.currentScenario {
                        assistantMessageView(for: scenario)
                            .offset(y: -120)
                            .transition(
                                AnyTransition
                                    .scale
                                    .combined(with: .opacity)
                            )
                    }

                    // Always-visible avatar button:
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    }) {
                        ZStack {
                            // Pulsing ring when there’s an active scenario (and not expanded):
                            if aiManager.currentScenario != nil, !isExpanded {
                                Circle()
                                    .fill(Color.blue.opacity(0.4))
                                    .frame(
                                        width: isPulsing ? 70 : 60,
                                        height: isPulsing ? 70 : 60
                                    )
                                    .animation(
                                        Animation
                                            .easeInOut(duration: 1.0)
                                            .repeatForever(autoreverses: true),
                                        value: isPulsing
                                    )
                            }

                            // Main avatar circle:
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.black.opacity(0.3), radius: 5)
                                .overlay(
                                    Image("AIAssistant")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 56, height: 56)
                                        .clipShape(Circle())
                                )
                        }
                    }
                    .onAppear {
                        isPulsing = true
                    }
                }
                .padding(.bottom, 40)
                .padding(.trailing, 20)
            }
        }
        .animation(.spring(), value: isExpanded)
        .zIndex(100)
        .onAppear {
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                AIAssistantManager.trigger(for: .pendingTasks)
            }
            #endif
        }
    }

    /// Renders the “speech bubble” for a given scenario.
    @ViewBuilder
    private func assistantMessageView(for scenario: AIScenario) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image("AIAssistant")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    .padding(.trailing, 4)

                Text(scenario.title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    withAnimation {
                        isExpanded = false
                        aiManager.dismissCurrentScenario()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Text(scenario.message)
                .font(.body)
                .foregroundColor(.white)
                .padding(.vertical, 8)

            Button(action: {
                aiManager.performAction()
                withAnimation {
                    isExpanded = false
                }
            }) {
                Text(actionText(for: scenario))
                    .fontWeight(.medium)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .shadow(radius: 5)
        .frame(width: UIScreen.main.bounds.width - 60)
    }

    /// Maps each `AIScenario` case to a button label.
    private func actionText(for scenario: AIScenario) -> String {
        switch scenario {
        case .routineIncomplete:
            return "Complete Routine"
        case .pendingTasks:
            return "View Tasks"
        case .missingPhoto:
            return "Upload Photo"
        case .clockOutReminder:
            return "Clock Out"
        case .weatherAlert:
            return "Check Weather"
        }
    }
}

#if DEBUG
struct AIAvatarOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.gray.edgesIgnoringSafeArea(.all)
            AIAvatarOverlayView()
        }
    }
}
#endif
