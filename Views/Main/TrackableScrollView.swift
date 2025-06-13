//
//  TrackableScrollView.swift
//  FrancoSphere
//
//  A ScrollView that tracks scroll offset for glassmorphism effects
//  Created by Shawn Magloire on 6/9/25.
//

import SwiftUI

// MARK: - TrackableScrollView Component
struct TrackableScrollView<Content: View>: View {
    let offsetChanged: (CGFloat) -> Void
    let content: Content
    
    init(offsetChanged: @escaping (CGFloat) -> Void, @ViewBuilder content: () -> Content) {
        self.offsetChanged = offsetChanged
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
            .frame(height: 0)
            
            content
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            offsetChanged(value)
        }
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Enhanced ScrollView with Refresh Control
struct RefreshableTrackableScrollView<Content: View>: View {
    let offsetChanged: (CGFloat) -> Void
    let onRefresh: () async -> Void
    let content: Content
    
    @State private var isRefreshing = false
    
    init(
        offsetChanged: @escaping (CGFloat) -> Void,
        onRefresh: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.offsetChanged = offsetChanged
        self.onRefresh = onRefresh
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
            .frame(height: 0)
            
            content
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            offsetChanged(value)
        }
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - Parallax ScrollView
struct ParallaxTrackableScrollView<Content: View>: View {
    let offsetChanged: (CGFloat) -> Void
    let parallaxRatio: CGFloat
    let content: Content
    
    @State private var scrollOffset: CGFloat = 0
    
    init(
        offsetChanged: @escaping (CGFloat) -> Void,
        parallaxRatio: CGFloat = 0.5,
        @ViewBuilder content: () -> Content
    ) {
        self.offsetChanged = offsetChanged
        self.parallaxRatio = parallaxRatio
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).minY
                )
            }
            .frame(height: 0)
            
            content
                .offset(y: scrollOffset * parallaxRatio)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
            offsetChanged(value)
        }
    }
}

// MARK: - Preview Provider
struct TrackableScrollView_Previews: PreviewProvider {
    static var previews: some View {
        TrackableScrollView(offsetChanged: { offset in
            print("Scroll offset: \(offset)")
        }) {
            VStack(spacing: 20) {
                ForEach(0..<20) { index in
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(height: 100)
                        .cornerRadius(16)
                        .overlay(
                            Text("Item \(index)")
                                .foregroundColor(.white)
                        )
                }
            }
            .padding()
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
    }
}
