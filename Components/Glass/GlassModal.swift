//
//  GlassModal.swift
//  FrancoSphere
//
//  ✅ CLEAN VERSION: Based on working ClockInGlassModal.swift patterns
//  ✅ NO GRDB: Only SwiftUI imports like other working components
//  ✅ USES EXISTING: GlassModalSize and GlassModalStyle from GlassTypes.swift
//

import SwiftUI

// MARK: - Glass Modal
struct GlassModal<Content: View>: View {
    @Binding var isPresented: Bool
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
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if dismissOnBackgroundTap {
                            dismiss()
                        }
                    }
                
                // Modal content
                modalContent
                    .offset(y: style == .bottom ? max(0, dragOffset.height) : dragOffset.height)
                    .gesture(style == .bottom ? dragGesture : nil)
                    .transition(modalTransition)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
        .onChange(of: isPresented) { newValue in
            withAnimation {
                showContent = newValue
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
        .background(GlassBackground())
        .clipShape(RoundedRectangle(cornerRadius: modalCornerRadius))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .scaleEffect(showContent ? 1 : 0.9)
        .opacity(showContent ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showContent)
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
    
    // MARK: - Modal Corner Radius
    private var modalCornerRadius: CGFloat {
        switch style {
        case .bottom: return 24
        case .centered: return 24
        case .fullScreen: return 0
        }
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

// MARK: - Glass Background (Following ClockInGlassModal pattern)
struct GlassBackground: View {
    var body: some View {
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
            RoundedRectangle(cornerRadius: 20)
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
}

// MARK: - Glass Action Sheet
struct GlassActionSheet: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let actions: [GlassActionButton]
    
    @State private var showContent = false
    @Environment(\.actionSheetDismiss) private var dismiss
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        actions: [GlassActionButton]
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.actions = actions
    }
    
    var body: some View {
        ZStack {
            if isPresented {
                // Background
                Color.black.opacity(0.4)
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
                .background(GlassBackground())
                .clipShape(RoundedRectangle(cornerRadius: 16))
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
    
    @Environment(\.actionSheetDismiss) private var dismiss
    
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

// MARK: - Enhanced Modal Configurations (v6.0 Features)
extension GlassModal {
    // PropertyCard Modal Configuration
    static func propertyCardModal<Content: View>(
        isPresented: Binding<Bool>,
        buildingName: String,
        @ViewBuilder content: () -> Content
    ) -> GlassModal<Content> {
        GlassModal(
            isPresented: isPresented,
            title: buildingName,
            subtitle: "Property Details",
            size: .large,
            style: .centered,
            showCloseButton: true,
            dismissOnBackgroundTap: true,
            content: content
        )
    }
    
    // Dashboard Modal Configuration
    static func dashboardModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> GlassModal<Content> {
        GlassModal(
            isPresented: isPresented,
            title: title,
            size: .medium,
            style: .bottom,
            showCloseButton: true,
            dismissOnBackgroundTap: true,
            content: content
        )
    }
    
    // Full Screen Modal Configuration
    static func fullScreenModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> GlassModal<Content> {
        GlassModal(
            isPresented: isPresented,
            title: title,
            size: .fullScreen,
            style: .fullScreen,
            showCloseButton: title != nil,
            dismissOnBackgroundTap: false,
            content: content
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

// MARK: - View Extensions
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
    
    // MARK: - v6.0 Dashboard Modal Extensions
    func propertyCardModal<Content: View>(
        isPresented: Binding<Bool>,
        buildingName: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay(
            GlassModal.propertyCardModal(
                isPresented: isPresented,
                buildingName: buildingName,
                content: content
            )
        )
    }
    
    func dashboardModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay(
            GlassModal.dashboardModal(
                isPresented: isPresented,
                title: title,
                content: content
            )
        )
    }
    
    func fullScreenModal<Content: View>(
        isPresented: Binding<Bool>,
        title: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay(
            GlassModal.fullScreenModal(
                isPresented: isPresented,
                title: title,
                content: content
            )
        )
    }
    
    func glassActionSheet(
        isPresented: Binding<Bool>,
        title: String,
        message: String? = nil,
        actions: [GlassActionButton]
    ) -> some View {
        self.overlay(
            GlassActionSheet(
                isPresented: isPresented,
                title: title,
                message: message,
                actions: actions
            )
        )
    }
}

// MARK: - Convenience Initializers
extension GlassActionButton {
    static func normal(_ title: String, action: @escaping () -> Void) -> GlassActionButton {
        GlassActionButton(title, role: nil, action: action)
    }
    
    static func destructive(_ title: String, action: @escaping () -> Void) -> GlassActionButton {
        GlassActionButton(title, role: .destructive, action: action)
    }
    
    static func cancel(_ action: @escaping () -> Void = {}) -> GlassActionButton {
        GlassActionButton("Cancel", role: .cancel, action: action)
    }
}

// MARK: - Preview
struct GlassModal_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Text("FrancoSphere v6.0")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Glass Modal System")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .glassModal(
            isPresented: .constant(true),
            title: "Property Details",
            size: .medium,
            style: .centered
        ) {
            VStack(spacing: 20) {
                Text("Modal Content")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("This is an example of the enhanced glass modal system for FrancoSphere v6.0")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button("Action") {
                    // Action
                }
                .foregroundColor(.blue)
            }
            .padding()
        }
    }
}
