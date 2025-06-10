//
//  TrackableScrollView.swift
//  FrancoSphere
//
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
