//
//  ProfileBadge.swift
//  FrancoSphere v6.0
//
//  ✅ INTEGRATED: With DashboardSyncService for real-time updates
//  ✅ ALIGNED: With three-dashboard architecture
//  ✅ CONNECTED: To worker status and Nova AI
//  ✅ SIMPLIFIED: Focused on essential features
//

import SwiftUI
import Combine

// MARK: - ProfileBadge Component

public struct ProfileBadge: View {
    // Core properties
    let worker: CoreTypes.WorkerProfile
    let size: BadgeSize
    let context: DashboardContext
    let onTap: () -> Void
    
    // Real-time status from services
    @State private var clockInStatus: CoreTypes.WorkerStatus = .offline
    @State private var activeTaskCount: Int = 0
    @State private var hasNovaAlert: Bool = false
    
    // Animation state
    @State private var isPressed = false
    @State private var pulseAnimation = false
    
    // Service connections
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    @StateObject private var statusMonitor = WorkerStatusMonitor()
    
    // MARK: - Initialization
    
    public init(
        worker: CoreTypes.WorkerProfile,
        size: BadgeSize = .standard,
        context: DashboardContext = .worker,
        onTap: @escaping () -> Void = {}
    ) {
        self.worker = worker
        self.size = size
        self.context = context
        self.onTap = onTap
    }
    
    // MARK: - Computed Properties
    
    private var displaySize: CGFloat {
        switch size {
        case .compact: return 32
        case .standard: return 44
        case .large: return 56
        }
    }
    
    private var initials: String {
        let components = worker.name.components(separatedBy: " ")
        let first = components.first?.first ?? "?"
        let last = components.count > 1 ? components.last?.first : nil
        return "\(first)\(last ?? "")".uppercased()
    }
    
    private var gradientColors: [Color] {
        // Use dashboard context colors
        switch context {
        case .worker:
            return [FrancoSphereDesign.DashboardColors.workerPrimary,
                    FrancoSphereDesign.DashboardColors.workerSecondary]
        case .admin:
            return [FrancoSphereDesign.DashboardColors.adminPrimary,
                    FrancoSphereDesign.DashboardColors.adminSecondary]
        case .client:
            return [FrancoSphereDesign.DashboardColors.clientPrimary,
                    FrancoSphereDesign.DashboardColors.clientSecondary]
        case .building(let id):
            // Building-specific color based on ID hash
            let hash = id.hashValue
            let hue = Double(abs(hash) % 360) / 360.0
            return [Color(hue: hue, saturation: 0.6, brightness: 0.8),
                    Color(hue: hue, saturation: 0.4, brightness: 0.6)]
        }
    }
    
    private var showStatusDot: Bool {
        switch context {
        case .admin, .building:
            return true
        case .worker:
            return size != .compact
        case .client:
            return false
        }
    }
    
    // MARK: - Body
    
    public var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Background
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(glassOverlay)
                
                // Profile content
                profileContent
                
                // Status indicators
                if showStatusDot {
                    statusIndicator
                }
                
                // Nova alert indicator
                if hasNovaAlert && context == .worker {
                    novaIndicator
                }
                
                // Task count badge (admin view only)
                if context == .admin && activeTaskCount > 0 {
                    taskCountBadge
                }
            }
            .frame(width: displaySize, height: displaySize)
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onAppear {
            setupStatusMonitoring()
        }
        .onChange(of: clockInStatus) { _, newStatus in
            if newStatus == .clockedIn {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
            } else {
                pulseAnimation = false
            }
        }
    }
    
    // MARK: - View Components
    
    private var glassOverlay: some View {
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
    }
    
    @ViewBuilder
    private var profileContent: some View {
        if let imageUrl = worker.profileImageUrl {
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(Circle())
            } placeholder: {
                initialsView
            }
        } else {
            initialsView
        }
    }
    
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
            
            // Pulse effect for active workers
            if pulseAnimation && clockInStatus == .clockedIn {
                Circle()
                    .stroke(gradientColors[0], lineWidth: 2)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                    .opacity(pulseAnimation ? 0 : 0.6)
                    .animation(
                        .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: pulseAnimation
                    )
            }
            
            // Initials
            Text(initials)
                .font(.system(
                    size: displaySize * 0.4,
                    weight: .bold,
                    design: .rounded
                ))
                .foregroundColor(.white)
        }
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(FrancoSphereDesign.EnumColors.workerStatus(clockInStatus))
            .frame(width: displaySize * 0.25, height: displaySize * 0.25)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.3), lineWidth: 1)
            )
            .offset(
                x: displaySize * 0.35,
                y: displaySize * 0.35
            )
    }
    
    private var novaIndicator: some View {
        Image(systemName: "sparkle")
            .font(.system(size: displaySize * 0.3))
            .foregroundColor(.yellow)
            .background(
                Circle()
                    .fill(Color.black.opacity(0.6))
                    .padding(-2)
            )
            .offset(
                x: -displaySize * 0.3,
                y: -displaySize * 0.3
            )
            .transition(.scale.combined(with: .opacity))
    }
    
    private var taskCountBadge: some View {
        Text("\(activeTaskCount)")
            .font(.system(size: displaySize * 0.25, weight: .bold))
            .foregroundColor(.white)
            .padding(displaySize * 0.1)
            .background(
                Circle()
                    .fill(Color.red)
            )
            .offset(
                x: displaySize * 0.3,
                y: -displaySize * 0.3
            )
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        HapticManager.impact(.light)
        onTap()
    }
    
    // MARK: - Service Integration
    
    private func setupStatusMonitoring() {
        // Monitor worker status
        statusMonitor.startMonitoring(workerId: worker.id)
        
        // Subscribe to dashboard updates
        dashboardSync.workerDashboardUpdates
            .filter { $0.workerId == worker.id }
            .receive(on: DispatchQueue.main)
            .sink { [weak statusMonitor] update in
                if let statusString = update.data["status"],
                   let status = CoreTypes.WorkerStatus(rawValue: statusString) {
                    statusMonitor?.updateStatus(status)
                }
                
                if let taskCountString = update.data["activeTaskCount"],
                   let count = Int(taskCountString) {
                    self.activeTaskCount = count
                }
            }
            .store(in: &statusMonitor.cancellables)
        
        // Subscribe to Nova alerts
        NotificationCenter.default.publisher(for: .novaAlertForWorker)
            .compactMap { $0.userInfo?["workerId"] as? String }
            .filter { $0 == worker.id }
            .receive(on: DispatchQueue.main)
            .sink { _ in
                withAnimation {
                    hasNovaAlert = true
                }
                
                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    withAnimation {
                        hasNovaAlert = false
                    }
                }
            }
            .store(in: &statusMonitor.cancellables)
        
        // Bind status updates
        statusMonitor.$currentStatus
            .receive(on: DispatchQueue.main)
            .assign(to: &$clockInStatus)
        
        statusMonitor.$activeTaskCount
            .receive(on: DispatchQueue.main)
            .assign(to: &$activeTaskCount)
    }
}

// MARK: - Supporting Types

public enum BadgeSize {
    case compact   // 32pt - for lists and compact views
    case standard  // 44pt - default size
    case large     // 56pt - for hero sections
}

public enum DashboardContext {
    case worker
    case admin
    case client
    case building(String) // Building ID for context-specific styling
}

// MARK: - Worker Status Monitor

class WorkerStatusMonitor: ObservableObject {
    @Published var currentStatus: CoreTypes.WorkerStatus = .offline
    @Published var activeTaskCount: Int = 0
    
    var cancellables = Set<AnyCancellable>()
    private var workerId: String?
    
    func startMonitoring(workerId: String) {
        self.workerId = workerId
        
        // Initial status check
        Task {
            await checkWorkerStatus()
        }
        
        // Periodic refresh
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                Task {
                    await self.checkWorkerStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    func updateStatus(_ status: CoreTypes.WorkerStatus) {
        currentStatus = status
    }
    
    @MainActor
    private func checkWorkerStatus() async {
        guard let workerId = workerId else { return }
        
        // Check clock-in status
        do {
            let sessions = try await GRDBManager.shared.query("""
                SELECT * FROM clock_sessions
                WHERE worker_id = ? AND clock_out_time IS NULL
                AND DATE(clock_in_time) = DATE('now')
                ORDER BY clock_in_time DESC
                LIMIT 1
            """, [workerId])
            
            if !sessions.isEmpty {
                currentStatus = .clockedIn
                
                // Get active task count
                let tasks = try await GRDBManager.shared.query("""
                    SELECT COUNT(*) as count FROM routine_tasks
                    WHERE workerId = ? AND isCompleted = 0
                    AND DATE(scheduledDate) = DATE('now')
                """, [workerId])
                
                if let count = tasks.first?["count"] as? Int64 {
                    activeTaskCount = Int(count)
                }
            } else {
                currentStatus = .available
                activeTaskCount = 0
            }
        } catch {
            print("❌ Error checking worker status: \(error)")
            currentStatus = .offline
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let novaAlertForWorker = Notification.Name("novaAlertForWorker")
}

// MARK: - Header Integration Examples

extension ProfileBadge {
    // Worker Dashboard Header
    static func workerHeader(
        worker: CoreTypes.WorkerProfile,
        onTap: @escaping () -> Void
    ) -> some View {
        ProfileBadge(
            worker: worker,
            size: .standard,
            context: .worker,
            onTap: onTap
        )
    }
    
    // Admin Dashboard - Worker List
    static func adminWorkerBadge(
        worker: CoreTypes.WorkerProfile,
        onTap: @escaping () -> Void
    ) -> some View {
        ProfileBadge(
            worker: worker,
            size: .compact,
            context: .admin,
            onTap: onTap
        )
    }
    
    // Building Assignment Badge
    static func buildingWorkerBadge(
        worker: CoreTypes.WorkerProfile,
        buildingId: String,
        onTap: @escaping () -> Void
    ) -> some View {
        ProfileBadge(
            worker: worker,
            size: .compact,
            context: .building(buildingId),
            onTap: onTap
        )
    }
}

// MARK: - Preview

struct ProfileBadge_Previews: PreviewProvider {
    static let sampleWorker = CoreTypes.WorkerProfile(
        id: "4",
        name: "Kevin Dutan",
        email: "kevin@francosphere.com",
        role: .worker
    )
    
    static var previews: some View {
        VStack(spacing: 32) {
            // Header examples
            HStack(spacing: 16) {
                ProfileBadge.workerHeader(worker: sampleWorker) {
                    print("Worker header tapped")
                }
                
                VStack(alignment: .leading) {
                    Text("Good morning,")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Kevin")
                        .font(.headline)
                }
                
                Spacer()
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            // Admin list example
            VStack(spacing: 12) {
                ForEach(["Edwin Lema", "Greg Hutson", "Mercedes Inamagua"], id: \.self) { name in
                    HStack {
                        ProfileBadge.adminWorkerBadge(
                            worker: CoreTypes.WorkerProfile(
                                id: UUID().uuidString,
                                name: name,
                                email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@francosphere.com",
                                role: .worker
                            )
                        ) {
                            print("\(name) tapped")
                        }
                        
                        Text(name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("3 tasks")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.black)
        .preferredColorScheme(.dark)
        .environmentObject(DashboardSyncService.shared)
    }
}
