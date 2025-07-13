//
//  GlassModal.swift
//  FrancoSphere
//
//  FIXED: Resolved AnyShape Sendable conformance error
//  Created by Shawn Magloire on 6/6/25.
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)


// MARK: - Glass Modal
struct GlassModal<Content: View>: View {
    @State var isPresented: Bool
    let content: Content
    
    // Customization
    var title: String?
    var subtitle: String?
    var size: GlassModalSize
    var style: GlassModalStyle
    var showCloseButton: Bool
    var dismissOnBackgroundTap: Bool
    
    // Animation states
    @State private var showContent = false
    @State private var dragOffset: CGSize = .zero
    
    init(
        isPresented: Binding<Bool>,
        title: String? = nil,
        subtitle: String? = nil,
        size: GlassModalSize = .medium,
        style: GlassModalStyle = .centered,
        showCloseButton: Bool = true,
        dismissOnBackgroundTap: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.subtitle = subtitle
        self.size = size
        self.style = style
        self.showCloseButton = showCloseButton
        self.dismissOnBackgroundTap = dismissOnBackgroundTap
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background overlay
                Color.black
                    .opacity(showContent ? 0.5 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if dismissOnBackgroundTap {
                            dismiss()
                        }
                    }
                
                // Modal content
                modalContent
                    .offset(y: style == .bottom ? max(0, dragOffset.height) : dragOffset.height)
                    .gesture(
                        style == .bottom ? dragGesture : nil
                    )
                    .transition(modalTransition)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showContent)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isPresented)
        .onChange(of: isPresented) { newValue in
            if newValue {
                withAnimation {
                    showContent = true
                }
            } else {
                showContent = false
            }
        }
    }
    
    // MARK: - Modal Content
    private var modalContent: some View {
        VStack(spacing: 0) {
            // Header
            if title != nil || showCloseButton {
                modalHeader
            }
            
            // Content
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: size.width, height: size.height)
        .frame(maxWidth: style == .fullScreen ? .infinity : size.width)
        .frame(maxHeight: style == .fullScreen ? .infinity : size.height)
        .background(modalBackground)
        .clipShape(RoundedRectangle(cornerRadius: modalCornerRadius)) // FIX: Use single shape type
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(showContent ? 1 : 0.9)
        .opacity(showContent ? 1 : 0)
    }
    
    // MARK: - Modal Header
    private var modalHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let title = title {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if showCloseButton {
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            VStack {
                Spacer()
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 1)
            }
        )
    }
    
    // MARK: - Modal Background
    private var modalBackground: some View {
        ZStack {
            // Base glass
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Gradient overlay
            LinearGradient(
                colors: [
                    Color.white.opacity(0.1),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Border
            RoundedRectangle(cornerRadius: modalCornerRadius)
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
        }
    }
    
    // MARK: - Modal Corner Radius (FIX: Single computed property)
    private var modalCornerRadius: CGFloat {
        style == .bottom ? 24 : 24
    }
    
    // MARK: - Modal Transition
    private var modalTransition: AnyTransition {
        switch style {
        case .centered:
            return .scale.combined(with: .opacity)
        case .bottom:
            return .move(edge: .bottom).combined(with: .opacity)
        case .fullScreen:
            return .opacity
        }
    }
    
    // MARK: - Drag Gesture
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                if value.translation.height > 100 {
                    dismiss()
                } else {
                    withAnimation(.spring()) {
                        dragOffset = .zero
                    }
                }
            }
    }
    
    // MARK: - Dismiss
    private func dismiss() {
        withAnimation {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            dragOffset = .zero
        }
    }
}

// MARK: - Glass Action Sheet
struct GlassActionSheet: View {
    @State var isPresented: Bool
    let title: String
    let message: String?
    let actions: [GlassActionButton]
    
    @State private var showContent = false
    @Environment(\.actionSheetDismiss) var dismiss
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background
                Color.black
                    .opacity(showContent ? 0.5 : 0)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissSheet()
                    }
                
                // Sheet content
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if let message = message {
                            Text(message)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding()
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    // Actions
                    VStack(spacing: 0) {
                        ForEach(actions) { action in
                            action
                                .environment(\.actionSheetDismiss, dismissSheet)
                            
                            if action.id != actions.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.1))
                            }
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .padding()
                .frame(maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .offset(y: showContent ? 0 : 300)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPresented)
        .onChange(of: isPresented) { newValue in
            withAnimation {
                showContent = newValue
            }
        }
    }
    
    private func dismissSheet() {
        withAnimation {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Glass Action Button
struct GlassActionButton: View, Identifiable {
    let id = UUID()
    let title: String
    let role: ButtonRole?
    let action: () -> Void
    
    @Environment(\.actionSheetDismiss) var dismiss
    
    init(_ title: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
        self.title = title
        self.role = role
        self.action = action
    }
    
    var body: some View {
        Button {
            dismiss?()
            action()
        } label: {
            Text(title)
                .font(.body)
                .foregroundColor(role == .destructive ? .red : .white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.001))
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .opacity(0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Environment Key
private struct ActionSheetDismissKey: EnvironmentKey {
    static let defaultValue: (() -> Void)? = nil
}

extension EnvironmentValues {
    var actionSheetDismiss: (() -> Void)? {
        get { self[ActionSheetDismissKey.self] }
        set { self[ActionSheetDismissKey.self] = newValue }
    }
}

// MARK: - View Extension
extension View {
    func glassModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        size: GlassModalSize = .medium,
        style: GlassModalStyle = .centered,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay(
            GlassModal(
                isPresented: isPresented,
                title: title,
                size: size,
                style: style,
                content: content
            )
        )
    }
}
