//
//  GlassModal.swift
//  FrancoSphere
//
//  Glassmorphism modal and sheet components for FrancoSphere
//  Created by Shawn Magloire on 6/6/25.
//

import SwiftUI

// MARK: - Modal Style
enum GlassModalStyle {
    case centered
    case bottom
    case fullScreen
}

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
        .onChange(of: isPresented) { oldValue, newValue in
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
        .clipShape(modalShape)
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
                        .font(.title3)
                        .fontWeight(.bold)
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
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
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
            modalShape
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
    
    // MARK: - Modal Shape
    private var modalShape: some Shape {
        switch style {
        case .centered, .fullScreen:
            return AnyShape(RoundedRectangle(cornerRadius: 24))
        case .bottom:
            return AnyShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
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

// MARK: - AnyShape Helper
private struct AnyShape: Shape, @unchecked Sendable {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape>(_ wrapped: S) {
        _path = { rect in wrapped.path(in: rect) }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// MARK: - Glass Action Sheet
struct GlassActionSheet: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let actions: [GlassActionSheetButton]
    
    var body: some View {
        GlassModal(
            isPresented: $isPresented,
            title: title,
            subtitle: message,
            size: .medium,
            style: .bottom,
            showCloseButton: false
        ) {
            VStack(spacing: 8) {
                ForEach(actions) { action in
                    action
                        .environment(\.actionSheetDismiss, {
                            isPresented = false
                        })
                }
                
                GlassActionSheetButton(
                    title: "Cancel",
                    style: .cancel
                ) {
                    isPresented = false
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Glass Action Sheet Button
struct GlassActionSheetButton: View, Identifiable {
    let id = UUID()
    let title: String
    let style: ButtonStyle
    let icon: String?
    let action: () -> Void
    
    @Environment(\.actionSheetDismiss) var dismiss
    
    enum ButtonStyle {
        case `default`
        case destructive
        case cancel
        
        var textColor: Color {
            switch self {
            case .default:
                return .white
            case .destructive:
                return .red
            case .cancel:
                return .white.opacity(0.8)
            }
        }
    }
    
    init(
        title: String,
        style: ButtonStyle = .default,
        icon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
            dismiss?()
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.body)
                }
                
                Text(title)
                    .font(style == .cancel ? .body : .body.weight(.medium))
                
                Spacer()
            }
            .foregroundColor(style.textColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .opacity(style == .cancel ? 0.5 : 0.8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
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

// MARK: - Preview Provider
struct GlassModal_Previews: PreviewProvider {
    struct PreviewContainer: View {
        @State var showCenteredModal = false
        @State var showBottomModal = false
        @State var showActionSheet = false
        @State var showFullScreenModal = false
        
        var body: some View {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.2, green: 0.1, blue: 0.4)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Glass Modal Examples")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    VStack(spacing: 16) {
                        GlassButton("Show Centered Modal", icon: "square.stack") {
                            showCenteredModal = true
                        }
                        
                        GlassButton("Show Bottom Sheet", icon: "rectangle.bottomthird.inset.filled") {
                            showBottomModal = true
                        }
                        
                        GlassButton("Show Action Sheet", icon: "ellipsis.circle") {
                            showActionSheet = true
                        }
                        
                        GlassButton("Show Full Screen", icon: "arrow.up.left.and.arrow.down.right") {
                            showFullScreenModal = true
                        }
                    }
                }
                .padding()
            }
            .glassModal(
                isPresented: $showCenteredModal,
                title: "Clock In",
                size: .small,
                style: .centered
            ) {
                VStack(spacing: 20) {
                    Text("Select your building to clock in")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top)
                    
                    GlassButton("12 West 18th Street", style: .primary, isFullWidth: true) {
                        showCenteredModal = false
                    }
                    
                    GlassButton("Cancel", style: .secondary, isFullWidth: true) {
                        showCenteredModal = false
                    }
                }
                .padding()
            }
            .overlay(
                GlassModal(
                    isPresented: $showBottomModal,
                    title: "Task Details",
                    subtitle: "HVAC Filter Replacement",
                    size: .medium,
                    style: .bottom
                ) {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Due in 2 hours", systemImage: "clock")
                            .foregroundColor(.orange)
                        
                        Label("Building 12", systemImage: "building.2")
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Replace all air filters in the HVAC system on floors 3-5.")
                            .foregroundColor(.white.opacity(0.8))
                        
                        GlassButton("Mark Complete", style: .primary, isFullWidth: true) {
                            showBottomModal = false
                        }
                    }
                    .padding()
                }
            )
            .overlay(
                GlassActionSheet(
                    isPresented: $showActionSheet,
                    title: "Task Actions",
                    message: "What would you like to do?",
                    actions: [
                        GlassActionSheetButton(title: "Edit Task", icon: "pencil") {
                            print("Edit")
                        },
                        GlassActionSheetButton(title: "Assign Worker", icon: "person.badge.plus") {
                            print("Assign")
                        },
                        GlassActionSheetButton(title: "Delete", style: .destructive, icon: "trash") {
                            print("Delete")
                        }
                    ]
                )
            )
            .overlay(
                GlassModal(
                    isPresented: $showFullScreenModal,
                    title: "Building Overview",
                    size: .fullScreen,
                    style: .fullScreen
                ) {
                    ScrollView {
                        VStack(spacing: 20) {
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Full screen modal content")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            Text("This modal takes up the entire screen")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding()
                    }
                }
            )
            .preferredColorScheme(.dark)
        }
    }
    
    static var previews: some View {
        PreviewContainer()
    }
}
