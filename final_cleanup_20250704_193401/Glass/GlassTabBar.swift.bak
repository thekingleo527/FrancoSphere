//
//  GlassTabBar.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  GlassTabBar.swift
//  FrancoSphere
//
//  Clean implementation using GlassTabItem from GlassTypes.swift
//  Created by Shawn Magloire on 6/6/25.

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Glass Tab Bar (Uses GlassTabItem from GlassTypes.swift)
struct GlassTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [GlassTabItem]
    
    var body: some View {
        GlassCard(intensity: .regular, cornerRadius: 24, padding: 8) {
            HStack(spacing: 0) {
                ForEach(tabs.indices, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                                .font(.system(size: 22))
                                .foregroundColor(selectedTab == index ? .blue : .white.opacity(0.6))
                            
                            Text(tabs[index].title)
                                .font(.caption)
                                .foregroundColor(selectedTab == index ? .blue : .white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedTab == index ?
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .padding(.horizontal, 8)
                            : nil
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
}

// MARK: - Preview
struct GlassTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.1, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                GlassTabBar(
                    selectedTab: .constant(0),
                    tabs: [
                        GlassTabItem(title: "Dashboard", icon: "house", selectedIcon: "house.fill"),
                        GlassTabItem(title: "Tasks", icon: "list.bullet", selectedIcon: "list.bullet"),
                        GlassTabItem(title: "Buildings", icon: "building", selectedIcon: "building.fill"),
                        GlassTabItem(title: "Profile", icon: "person", selectedIcon: "person.fill")
                    ]
                )
            }
        }
        .preferredColorScheme(.dark)
    }
}