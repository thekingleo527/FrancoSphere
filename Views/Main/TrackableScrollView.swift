//
//  TrackableScrollView.swift
//  FrancoSphere
//
//  📋 Phase-2 Implementation - Supporting Component for WorkerDashboardView Refactor
//  ✅ Tracks scroll offset for header and Nova transformations
//  ✅ Supports custom content insets
//  ✅ Real-time scroll position binding
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


struct TrackableScrollView<Content: View>: View {
    @Binding var contentOffset: CGFloat
    let contentInset: UIEdgeInsets
    let content: () -> Content
    
    init(
        contentOffset: Binding<CGFloat>,
        contentInset: UIEdgeInsets = UIEdgeInsets(),
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._contentOffset = contentOffset
        self.contentInset = contentInset
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            ZStack {
                // Invisible tracking view
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY
                    )
                }
                .frame(height: 0)
                
                // Content with insets
                VStack(spacing: 0) {
                    Color.clear.frame(height: contentInset.top)
                    content()
                    Color.clear.frame(height: contentInset.bottom)
                }
                .padding(.leading, contentInset.left)
                .padding(.trailing, contentInset.right)
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            contentOffset = value
        }
    }
}

// MARK: - Scroll Offset Preference Key

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview Provider

struct TrackableScrollView_Previews: PreviewProvider {
    @State static var scrollOffset: CGFloat = 0
    
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Text("Scroll Offset: \(scrollOffset, specifier: "%.1f")")
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(8)
                
                TrackableScrollView(
                    contentOffset: $scrollOffset,
                    contentInset: UIEdgeInsets(top: 100, left: 0, bottom: 100, right: 0)
                ) {
                    VStack(spacing: 20) {
                        ForEach(0..<20) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.3))
                                .frame(height: 80)
                                .overlay(
                                    Text("Item \(index + 1)")
                                        .foregroundColor(.white)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
