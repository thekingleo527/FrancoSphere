//
//  ProfileBadge.swift
//  FrancoSphere
//
//  ✅ Fixed Character/String type mismatches
//  ✅ Fixed closure parameter issues
//  ✅ Enhanced Phase-2 ProfileBadge implementation
//

import SwiftUI

struct ProfileBadge: View {
    let workerName: String
    let imageUrl: String?
    let isCompact: Bool
    let onTap: () -> Void
    
    // MARK: - Private Properties
    
    private var displaySize: CGFloat {
        isCompact ? 36 : 44
    }
    
    private var fontSize: CGFloat {
        isCompact ? 12 : 16
    }
    
    // ✅ FIXED: Character/String type consistency
    private var initials: String {
        let components = workerName.components(separatedBy: " ")
        let firstInitial = components.first?.first ?? Character("?")
        let lastInitial = components.count > 1 ? components.last?.first ?? Character("") : Character("")
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    private var gradientColors: [Color] {
        // Generate gradient based on worker name hash for consistent colors
        let hash = workerName.hashValue
        let colorIndex = abs(hash) % gradientOptions.count
        return gradientOptions[colorIndex]
    }
    
    private let gradientOptions: [[Color]] = [
        [.blue, .cyan],
        [.purple, .pink],
        [.orange, .yellow],
        [.green, .mint],
        [.red, .orange],
        [.indigo, .blue],
        [.teal, .green],
        [.pink, .purple]
    ]
    
    // MARK: - State
    
    @State private var isPressed = false
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Profile content
                if let imageUrl = imageUrl, !imageUrl.isEmpty {
                    profileImage
                } else {
                    initialsView
                }
            }
            .frame(width: displaySize, height: displaySize)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        // ✅ FIXED: Correct onLongPressGesture syntax
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            isPressed = pressing
        }, perform: {
            // Optional: Add haptic feedback or additional action on long press completion
        })
    }
    
    // MARK: - Profile Image
    
    private var profileImage: some View {
        AsyncImage(url: URL(string: imageUrl ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
        } placeholder: {
            // Show initials while loading
            initialsView
        }
        .clipShape(Circle())
    }
    
    // MARK: - Initials View
    
    private var initialsView: some View {
        ZStack {
            // Gradient background
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Initials text
            Text(initials)
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
        }
        .clipShape(Circle())
    }
}

// MARK: - Preview Provider

struct ProfileBadge_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 32) {
            // Real workers from production
            HStack(spacing: 16) {
                ProfileBadge(
                    workerName: "Edwin Lema",
                    imageUrl: nil,
                    isCompact: false,
                    onTap: { print("Edwin tapped") }
                )
                
                ProfileBadge(
                    workerName: "Greg Hutson",
                    imageUrl: nil,
                    isCompact: false,
                    onTap: { print("Greg tapped") }
                )
                
                ProfileBadge(
                    workerName: "Kevin Dutan",
                    imageUrl: nil,
                    isCompact: false,
                    onTap: { print("Kevin tapped") }
                )
            }
            
            Text("Real Workers - Default Size (44x44)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            // Compact size with real workers
            HStack(spacing: 12) {
                ProfileBadge(
                    workerName: "Mercedes Inamagua",
                    imageUrl: nil,
                    isCompact: true,
                    onTap: { print("Mercedes compact tapped") }
                )
                
                ProfileBadge(
                    workerName: "Luis Lopez",
                    imageUrl: nil,
                    isCompact: true,
                    onTap: { print("Luis compact tapped") }
                )
                
                ProfileBadge(
                    workerName: "Angel Guirachocha",
                    imageUrl: nil,
                    isCompact: true,
                    onTap: { print("Angel compact tapped") }
                )
                
                ProfileBadge(
                    workerName: "Shawn Magloire",
                    imageUrl: nil,
                    isCompact: true,
                    onTap: { print("Shawn compact tapped") }
                )
            }
            
            Text("Real Workers - Compact Size (36x36)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .preferredColorScheme(.dark)
    }
}
