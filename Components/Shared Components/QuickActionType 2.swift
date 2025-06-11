
//
//  QuickActionMenu.swift
//  FrancoSphere
//
//  Quick action radial menu for Nova AI assistant
//

import SwiftUI

enum QuickActionType {
    case scanQR
    case reportIssue
    case showMap
    case askNova
    case viewInsights
}

struct QuickActionMenu: View {
    @Binding var isPresented: Bool
    let onActionSelected: (QuickActionType) -> Void
    
    @State private var showActions = false
    
    var body: some View {
        ZStack {
            // Background dismiss area
            Color.black.opacity(showActions ? 0.3 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        showActions = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isPresented = false
                    }
                }
            
            // Action buttons
            VStack(spacing: 16) {
                ForEach(actions, id: \.type) { action in
                    QuickActionButton(
                        icon: action.icon,
                        title: action.title,
                        color: action.color
                    ) {
                        onActionSelected(action.type)
                        withAnimation(.spring()) {
                            showActions = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            isPresented = false
                        }
                    }
                    .scaleEffect(showActions ? 1 : 0.5)
                    .opacity(showActions ? 1 : 0)
                    .animation(
                        .spring(response: 0.3, dampingFraction: 0.7)
                            .delay(Double(actions.firstIndex(where: { $0.type == action.type })!) * 0.05),
                        value: showActions
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(radius: 20)
            )
            .padding(.horizontal, 40)
            .offset(y: -100)
        }
        .onAppear {
            withAnimation(.spring()) {
                showActions = true
            }
        }
    }
    
    private var actions: [(type: QuickActionType, icon: String, title: String, color: Color)] {
        [
            (.scanQR, "qrcode.viewfinder", "Scan QR", .blue),
            (.reportIssue, "exclamationmark.bubble", "Report Issue", .orange),
            (.showMap, "map", "Building Map", .green),
            (.askNova, "sparkles", "Ask Nova", .purple),
            (.viewInsights, "chart.line.uptrend.xyaxis", "AI Insights", .indigo)
        ]
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .opacity(0.5)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
