//
//  BuildingDetailView.swift
//  FrancoSphere v6.0
//
//  🏢 REFACTORED: Consolidated maintenance, tasks, and inventory into tabs
//  🎨 DARK ELEGANCE: Full FrancoSphereDesign implementation
//  🔄 REAL-TIME: Live updates via DashboardSync
//  ✨ UNIFIED: Consistent with BuildingIntelligencePanel patterns
//
//  Dependencies:
//  - Uses FrancoBuildingPhoto and FrancoBuildingPhotoMetadata from ImagePicker.swift
//  - Uses existing MaintenanceTaskView from MaintenanceTaskView.swift
//  - Uses existing InventoryView components
//

import SwiftUI
import MapKit
import MessageUI
import CoreLocation

struct BuildingDetailView: View {
    // MARK: - Properties
    let buildingId: String
    let buildingName: String
    let buildingAddress: String
    @StateObject private var viewModel: BuildingDetailVM
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State
    @State private var selectedTab = BuildingDetailTab.overview
    @State private var showingPhotoCapture = false
    @State private var showingMessageComposer = false
    @State private var showingCallMenu = false
    @State private var selectedContact: BuildingContact?
    @State private var capturedImage: UIImage?
    @State private var photoCategory: CoreTypes.FrancoPhotoCategory = .utilities
    @State private var photoNotes: String = ""
    @State private var isHeaderExpanded = false
    @State private var animateCards = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(buildingId: String, buildingName: String, buildingAddress: String) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.buildingAddress = buildingAddress
        self._viewModel = StateObject(wrappedValue: BuildingDetailVM(
            buildingId: buildingId,
            buildingName: buildingName,
            buildingAddress: buildingAddress
        ))
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Dark elegant background
            FrancoSphereDesign.DashboardGradients.backgroundGradient
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation header
                navigationHeader
                
                // Building hero section
                buildingHeroSection
                    .animatedGlassAppear(delay: 0.1)
                
                // Streamlined tab bar
                tabBar
                    .animatedGlassAppear(delay: 0.2)
                
                // Tab content with animations
                tabContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
            
            // Floating action button
            floatingActionButton
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadBuildingData()
            withAnimation(.spring(response: 0.4)) {
                animateCards = true
            }
        }
        .onReceive(dashboardSync.$lastUpdate) { update in
            if update?.buildingId == buildingId {
                Task { await viewModel.refreshData() }
            }
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureSheet(
                buildingId: buildingId,
                buildingName: buildingName,
                category: photoCategory,
                onCapture: { image, category, notes in
                    Task {
                        await viewModel.savePhoto(
                            image,
                            category: category,
                            notes: notes
                        )
                    }
                }
            )
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposerView(
                recipients: getMessageRecipients(),
                subject: "Re: \(buildingName)",
                prefilledBody: getBuildingContext()
            )
        }
        .confirmationDialog("Call Contact", isPresented: $showingCallMenu) {
            callMenuOptions
        }
    }
    
    // MARK: - Navigation Header
    private var navigationHeader: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.caption)
                    Text("Back")
                        .font(.subheadline)
                }
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(buildingName)
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .lineLimit(1)
                
                Text(buildingAddress)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Menu {
                Button(action: { viewModel.exportBuildingReport() }) {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { viewModel.toggleFavorite() }) {
                    Label(
                        viewModel.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                        systemImage: viewModel.isFavorite ? "star.fill" : "star"
                    )
                }
                
                if viewModel.userRole == .admin {
                    Divider()
                    
                    Button(action: { viewModel.editBuildingInfo() }) {
                        Label("Edit Building Info", systemImage: "pencil")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            FrancoSphereDesign.glassMorphism()
                .overlay(
                    Rectangle()
                        .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Building Hero Section
    private var buildingHeroSection: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        FrancoSphereDesign.DashboardColors.accent.opacity(0.3),
                        FrancoSphereDesign.DashboardColors.accent.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: isHeaderExpanded ? 180 : 100)
                
                // Building icon overlay
                HStack {
                    Spacer()
                    Image(systemName: viewModel.buildingIcon)
                        .font(.system(size: 50))
                        .foregroundColor(FrancoSphereDesign.DashboardColors.accent.opacity(0.2))
                        .padding()
                }
                
                // Status information
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Building type badge
                        HStack(spacing: 6) {
                            Image(systemName: "building.2")
                                .font(.caption)
                            Text(viewModel.buildingType)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            FrancoSphereDesign.glassMorphism()
                                .overlay(FrancoSphereDesign.glassBorder())
                        )
                        .cornerRadius(20)
                        
                        // Status badges
                        HStack(spacing: 12) {
                            BuildingStatusBadge(
                                label: "\(viewModel.completionPercentage)%",
                                icon: "checkmark.circle.fill",
                                color: completionColor
                            )
                            
                            if viewModel.workersOnSite > 0 {
                                BuildingStatusBadge(
                                    label: "\(viewModel.workersOnSite) On-Site",
                                    icon: "person.fill",
                                    color: FrancoSphereDesign.DashboardColors.info
                                )
                            }
                            
                            if let status = viewModel.complianceStatus {
                                BuildingStatusBadge(
                                    label: status.rawValue.capitalized,
                                    icon: complianceIcon(status),
                                    color: complianceColor(status)
                                )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse button
                    Button(action: {
                        withAnimation(.spring()) {
                            isHeaderExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isHeaderExpanded ? "chevron.up" : "info.circle")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(FrancoSphereDesign.glassMorphism())
                            )
                    }
                }
                .padding()
            }
            .clipped()
            
            // Expandable details
            if isHeaderExpanded {
                expandedBuildingInfo
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            FrancoSphereDesign.glassMorphism()
                .overlay(
                    Rectangle()
                        .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Expanded Building Info
    private var expandedBuildingInfo: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(icon: "square", label: "Size", value: "\(viewModel.buildingSize.formatted()) sq ft")
                    InfoRow(icon: "building.columns", label: "Floors", value: "\(viewModel.floors)")
                    InfoRow(icon: "door.left.hand.open", label: "Units", value: "\(viewModel.units)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    InfoRow(icon: "calendar", label: "Built", value: "\(viewModel.yearBuilt)")
                    InfoRow(icon: "doc.text", label: "Contract", value: viewModel.contractType ?? "Standard")
                    InfoRow(icon: "star", label: "Rating", value: viewModel.buildingRating)
                }
            }
            
            // Quick stats
            HStack(spacing: 16) {
                BuildingQuickStatCard(
                    title: "Efficiency",
                    value: "\(viewModel.efficiencyScore)%",
                    trend: .up,
                    color: FrancoSphereDesign.DashboardColors.success
                )
                
                BuildingQuickStatCard(
                    title: "Compliance",
                    value: viewModel.complianceScore,
                    trend: .stable,
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                BuildingQuickStatCard(
                    title: "Issues",
                    value: "\(viewModel.openIssues)",
                    trend: viewModel.openIssues > 0 ? .down : .stable,
                    color: viewModel.openIssues > 0 ? FrancoSphereDesign.DashboardColors.warning : FrancoSphereDesign.DashboardColors.inactive
                )
            }
        }
        .padding()
        .background(FrancoSphereDesign.glassMorphism())
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(BuildingTab.allCases, id: \.self) { tab in
                    if shouldShowTab(tab) {
                        TabButton(
                            tab: tab,
                            isSelected: selectedTab == tab,
                            action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTab = tab
                                }
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(
            FrancoSphereDesign.glassMorphism()
                .overlay(FrancoSphereDesign.glassBorder())
        )
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedTab {
                case .overview:
                    BuildingOverviewTab(viewModel: viewModel)
                    
                case .tasks:
                    BuildingTasksTab(
                        buildingId: buildingId,
                        buildingName: buildingName,
                        viewModel: viewModel
                    )
                    
                case .workers:
                    BuildingWorkersTab(viewModel: viewModel)
                    
                case .maintenance:
                    BuildingMaintenanceTab(
                        buildingId: buildingId,
                        viewModel: viewModel
                    )
                    
                case .inventory:
                    BuildingInventoryTab(
                        buildingId: buildingId,
                        buildingName: buildingName,
                        viewModel: viewModel
                    )
                    
                case .spaces:
                    BuildingSpacesTab(
                        buildingId: buildingId,
                        buildingName: buildingName,
                        viewModel: viewModel,
                        onPhotoCapture: {
                            photoCategory = .utilities
                            showingPhotoCapture = true
                        }
                    )
                    
                case .emergency:
                    BuildingEmergencyTab(
                        viewModel: viewModel,
                        onCall: { showingCallMenu = true },
                        onMessage: { showingMessageComposer = true }
                    )
                }
            }
            .padding()
            .padding(.bottom, 60) // Space for floating action button
        }
        .background(FrancoSphereDesign.DashboardColors.baseBackground)
    }
    
    // MARK: - Floating Action Button
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Menu {
                    Button(action: {
                        photoCategory = .general
                        showingPhotoCapture = true
                    }) {
                        Label("Take Photo", systemImage: "camera.fill")
                    }
                    
                    Button(action: { showingCallMenu = true }) {
                        Label("Call Contact", systemImage: "phone.fill")
                    }
                    
                    Button(action: { openInMaps() }) {
                        Label("Navigate", systemImage: "map.fill")
                    }
                    
                    Button(action: { viewModel.reportIssue() }) {
                        Label("Report Issue", systemImage: "exclamationmark.triangle")
                    }
                    
                    Button(action: { viewModel.requestSupplies() }) {
                        Label("Request Supplies", systemImage: "shippingbox")
                    }
                    
                    Button(action: { showingMessageComposer = true }) {
                        Label("Send Message", systemImage: "message")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(FrancoSphereDesign.DashboardGradients.accentGradient)
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .shadow(
                        color: FrancoSphereDesign.DashboardColors.accent.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .padding()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func shouldShowTab(_ tab: BuildingDetailTab) -> Bool {
        switch tab {
        case .inventory, .spaces:
            return viewModel.userRole != .client
        default:
            return true
        }
    }
    
    private var completionColor: Color {
        let percentage = viewModel.completionPercentage
        switch percentage {
        case 90...100: return FrancoSphereDesign.DashboardColors.success
        case 70..<90: return FrancoSphereDesign.DashboardColors.warning
        case 50..<70: return FrancoSphereDesign.DashboardColors.warning
        default: return FrancoSphereDesign.DashboardColors.critical
        }
    }
    
    private func complianceIcon(_ status: CoreTypes.ComplianceStatus) -> String {
        switch status {
        case .compliant: return "checkmark.seal.fill"
        case .nonCompliant: return "exclamationmark.triangle.fill"
        case .pending: return "clock.fill"
        default: return "questionmark.circle.fill"
        }
    }
    
    private func complianceColor(_ status: CoreTypes.ComplianceStatus) -> Color {
        FrancoSphereDesign.EnumColors.complianceStatus(status)
    }
    
    private func getMessageRecipients() -> [String] {
        var recipients: [String] = []
        
        if let contact = selectedContact, let email = contact.email {
            recipients.append(email)
        } else {
            recipients = ["david@francosphere.com", "jerry@francosphere.com"]
        }
        
        return recipients
    }
    
    private func getBuildingContext() -> String {
        """
        Building: \(buildingName)
        Address: \(buildingAddress)
        Current Status: \(viewModel.completionPercentage)% complete
        Workers on site: \(viewModel.workersOnSite)
        
        ---
        """
    }
    
    private var callMenuOptions: some View {
        Group {
            if let contact = selectedContact {
                if let phone = contact.phone {
                    Button(action: { callNumber(phone) }) {
                        Text("Call \(contact.name)")
                    }
                }
            }
            
            Button(action: { callEmergency() }) {
                Text("Call Emergency Line")
            }
            
            if let primaryContact = viewModel.primaryContact,
               let phone = primaryContact.phone {
                Button(action: { callNumber(phone) }) {
                    Text("Call Building Contact")
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func callNumber(_ number: String) {
        let cleanNumber = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard let url = URL(string: "tel://\(cleanNumber)") else { return }
        UIApplication.shared.open(url)
    }
    
    private func callEmergency() {
        callNumber("2125550911")
    }
    
    private func openInMaps() {
        let address = buildingAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "maps://?address=\(address)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Tab Enum
enum BuildingDetailTab: String, CaseIterable {
    case overview = "Overview"
    case tasks = "Tasks"
    case workers = "Workers"
    case maintenance = "Maintenance"
    case inventory = "Inventory"
    case spaces = "Spaces"
    case emergency = "Emergency"
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .tasks: return "checkmark.circle.fill"
        case .workers: return "person.3.fill"
        case .maintenance: return "wrench.and.screwdriver.fill"
        case .inventory: return "shippingbox.fill"
        case .spaces: return "key.fill"
        case .emergency: return "phone.arrow.up.right"
        }
    }
}

// MARK: - Tab Button Component
struct TabButton: View {
    let tab: BuildingDetailTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.hierarchical)
                
                Text(tab.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(
                isSelected ?
                FrancoSphereDesign.DashboardColors.accent :
                FrancoSphereDesign.DashboardColors.secondaryText
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                FrancoSphereDesign.DashboardColors.accent.opacity(0.15) :
                Color.clear
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ?
                        FrancoSphereDesign.DashboardColors.accent.opacity(0.3) :
                        Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Status Badge Component
struct BuildingStatusBadge: View {
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                .frame(width: 16)
            
            Text(label + ":")
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
        }
    }
}

// MARK: - Quick Stat Card
struct BuildingQuickStatCard: View {
    let title: String
    let value: String
    let trend: CoreTypes.TrendDirection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .font(.caption2)
                    .foregroundColor(trendColor)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(FrancoSphereDesign.glassMorphism())
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        default: return "questionmark"
        }
    }
    
    private var trendColor: Color {
        FrancoSphereDesign.EnumColors.trendDirection(trend)
    }
}

// MARK: - Tab Content Views

// Overview Tab
struct BuildingOverviewTab: View {
    @ObservedObject var viewModel: BuildingDetailVM
    
    var body: some View {
        VStack(spacing: 20) {
            // Today's snapshot
            todaysSnapshotCard
                .animatedGlassAppear(delay: 0.1)
            
            // Key metrics
            keyMetricsSection
                .animatedGlassAppear(delay: 0.2)
            
            // Recent activity
            recentActivityCard
                .animatedGlassAppear(delay: 0.3)
            
            // Key contacts
            keyContactsCard
                .animatedGlassAppear(delay: 0.4)
        }
    }
    
    private var todaysSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Today's Snapshot", systemImage: "calendar.circle.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                if let activeTasks = viewModel.todaysTasks {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                        Text("Active Tasks")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text("\(activeTasks.completed) of \(activeTasks.total)")
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    }
                    .font(.subheadline)
                    
                    ProgressView(value: Double(activeTasks.completed) / Double(activeTasks.total))
                        .progressViewStyle(
                            LinearProgressViewStyle(tint: FrancoSphereDesign.DashboardColors.success)
                        )
                        .frame(height: 6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(3)
                }
                
                if !viewModel.workersPresent.isEmpty {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                        Text("Workers Present")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        Spacer()
                        Text(viewModel.workersPresent.joined(separator: ", "))
                            .fontWeight(.medium)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                            .lineLimit(1)
                    }
                    .font(.subheadline)
                }
                
                if let nextCritical = viewModel.nextCriticalTask {
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Next Critical Task")
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                            Text(nextCritical)
                                .fontWeight(.medium)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        }
                        Spacer()
                    }
                    .font(.subheadline)
                }
            }
            
            if let specialNote = viewModel.todaysSpecialNote {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
                        .font(.caption)
                    Text(specialNote)
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(FrancoSphereDesign.DashboardColors.accent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(FrancoSphereDesign.DashboardColors.accent.opacity(0.2), lineWidth: 1)
                        )
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var keyMetricsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            BuildingMetricCard(
                title: "Efficiency",
                value: "\(viewModel.efficiencyScore)%",
                icon: "speedometer",
                color: FrancoSphereDesign.DashboardColors.success,
                trend: .up
            )
            
            BuildingMetricCard(
                title: "Compliance",
                value: viewModel.complianceScore,
                icon: "checkmark.seal",
                color: FrancoSphereDesign.DashboardColors.info,
                trend: .stable
            )
            
            BuildingMetricCard(
                title: "Open Issues",
                value: "\(viewModel.openIssues)",
                icon: "exclamationmark.circle",
                color: viewModel.openIssues > 0 ? FrancoSphereDesign.DashboardColors.warning : FrancoSphereDesign.DashboardColors.inactive,
                trend: viewModel.openIssues > 0 ? .down : .stable
            )
            
            BuildingMetricCard(
                title: "Inventory",
                value: "\(viewModel.inventorySummary.cleaningLow) Low",
                icon: "shippingbox",
                color: viewModel.inventorySummary.cleaningLow > 0 ? FrancoSphereDesign.DashboardColors.warning : FrancoSphereDesign.DashboardColors.success,
                trend: .stable
            )
        }
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("Last 24h")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            if viewModel.recentActivities.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recentActivities.prefix(5)) { activity in
                        BuildingActivityRow(activity: activity)
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var keyContactsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Key Contacts", systemImage: "phone.circle.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                if let primaryContact = viewModel.primaryContact {
                    BuildingContactRow(
                        name: primaryContact.name,
                        role: primaryContact.role ?? "Building Contact",
                        phone: primaryContact.phone,
                        isEmergency: primaryContact.isEmergencyContact
                    )
                }
                
                BuildingContactRow(
                    name: "24/7 Emergency",
                    role: "Franco Response",
                    phone: "(212) 555-0911",
                    isEmergency: true
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// Tasks Tab
struct BuildingTasksTab: View {
    let buildingId: String
    let buildingName: String
    @ObservedObject var viewModel: BuildingDetailVM
    @State private var selectedTaskFilter: TaskFilter = .today
    @State private var selectedTask: CoreTypes.MaintenanceTask?
    
    enum TaskFilter: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case overdue = "Overdue"
        case upcoming = "Upcoming"
        
        var icon: String {
            switch self {
            case .today: return "calendar.badge.clock"
            case .week: return "calendar"
            case .overdue: return "exclamationmark.triangle"
            case .upcoming: return "clock.arrow.circlepath"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Filter pills
            filterSection
                .animatedGlassAppear(delay: 0.1)
            
            // Daily routines
            dailyRoutinesCard
                .animatedGlassAppear(delay: 0.2)
            
            // Maintenance tasks
            maintenanceTasksCard
                .animatedGlassAppear(delay: 0.3)
            
            // Compliance tasks
            complianceTasksCard
                .animatedGlassAppear(delay: 0.4)
        }
        .sheet(item: $selectedTask) { task in
            MaintenanceTaskDetailSheet(task: task, buildingName: buildingName)
        }
    }
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    BuildingFilterPill(
                        title: filter.rawValue,
                        icon: filter.icon,
                        isSelected: selectedTaskFilter == filter,
                        action: { selectedTaskFilter = filter }
                    )
                }
            }
        }
    }
    
    private var dailyRoutinesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Daily Routines", systemImage: "calendar.circle.fill")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Text("\(viewModel.completedRoutines)/\(viewModel.totalRoutines)")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
            }
            
            if viewModel.dailyRoutines.isEmpty {
                EmptyStateMessage(message: "No routines scheduled today")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.dailyRoutines) { routine in
                        DailyRoutineRow(
                            routine: routine,
                            onToggle: { viewModel.toggleRoutineCompletion(routine) }
                        )
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var maintenanceTasksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Maintenance Tasks", systemImage: "wrench.and.screwdriver")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if viewModel.maintenanceTasks.isEmpty {
                EmptyStateMessage(message: "No maintenance tasks scheduled")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.maintenanceTasks) { task in
                        MaintenanceTaskRow(task: task) {
                            selectedTask = task
                        }
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var complianceTasksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Compliance", systemImage: "checkmark.seal")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                if viewModel.hasComplianceIssues {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                }
            }
            
            VStack(spacing: 8) {
                ComplianceRow(
                    title: "DSNY Requirements",
                    status: viewModel.dsnyCompliance,
                    nextAction: viewModel.nextDSNYAction
                )
                
                ComplianceRow(
                    title: "Fire Safety",
                    status: viewModel.fireSafetyCompliance,
                    nextAction: viewModel.nextFireSafetyAction
                )
                
                ComplianceRow(
                    title: "Health Inspections",
                    status: viewModel.healthCompliance,
                    nextAction: viewModel.nextHealthAction
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// Workers Tab
struct BuildingWorkersTab: View {
    @ObservedObject var viewModel: BuildingDetailVM
    
    var body: some View {
        VStack(spacing: 20) {
            // Workers summary
            workersSummaryCard
                .animatedGlassAppear(delay: 0.1)
            
            // On-site workers
            onSiteWorkersCard
                .animatedGlassAppear(delay: 0.2)
            
            // All assigned workers
            allAssignedWorkersCard
                .animatedGlassAppear(delay: 0.3)
        }
    }
    
    private var workersSummaryCard: some View {
        HStack(spacing: 16) {
            SummaryStatCard(
                title: "Total Assigned",
                value: "\(viewModel.assignedWorkers.count)",
                icon: "person.3",
                color: FrancoSphereDesign.DashboardColors.info
            )
            
            SummaryStatCard(
                title: "On-Site Now",
                value: "\(viewModel.workersOnSite)",
                icon: "location.fill",
                color: FrancoSphereDesign.DashboardColors.success
            )
            
            SummaryStatCard(
                title: "Avg Hours",
                value: "\(viewModel.averageWorkerHours)h",
                icon: "clock",
                color: FrancoSphereDesign.DashboardColors.accent
            )
        }
    }
    
    private var onSiteWorkersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Currently On-Site", systemImage: "location.circle.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if viewModel.onSiteWorkers.isEmpty {
                EmptyStateMessage(message: "No workers currently on-site")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.onSiteWorkers) { worker in
                        OnSiteWorkerRow(worker: worker)
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var allAssignedWorkersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("All Assigned Workers", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                ForEach(viewModel.assignedWorkers) { worker in
                    AssignedWorkerRow(worker: worker)
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
}

// Maintenance Tab (Consolidated from MaintenanceHistoryView)
struct BuildingMaintenanceTab: View {
    let buildingId: String
    @ObservedObject var viewModel: BuildingDetailVM
    @State private var filterOption: MaintenanceFilter = .all
    @State private var dateRange: DateRange = .lastMonth
    
    enum MaintenanceFilter: String, CaseIterable {
        case all = "All"
        case cleaning = "Cleaning"
        case repairs = "Repairs"
        case inspection = "Inspection"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .cleaning: return "sparkles"
            case .repairs: return "hammer"
            case .inspection: return "magnifyingglass"
            }
        }
    }
    
    enum DateRange: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastThreeMonths = "Last 3 Months"
        
        var days: Int {
            switch self {
            case .lastWeek: return 7
            case .lastMonth: return 30
            case .lastThreeMonths: return 90
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Stats overview
            maintenanceStatsSection
                .animatedGlassAppear(delay: 0.1)
            
            // Filters
            maintenanceFiltersSection
                .animatedGlassAppear(delay: 0.2)
            
            // History list
            maintenanceHistoryList
                .animatedGlassAppear(delay: 0.3)
        }
    }
    
    private var maintenanceStatsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Tasks",
                    value: "\(viewModel.maintenanceHistory.count)",
                    icon: "checkmark.circle.fill",
                    color: FrancoSphereDesign.DashboardColors.success
                )
                
                StatCard(
                    title: "This Week",
                    value: "\(viewModel.maintenanceThisWeek)",
                    icon: "calendar.badge.clock",
                    color: FrancoSphereDesign.DashboardColors.info
                )
                
                StatCard(
                    title: "Repairs",
                    value: "\(viewModel.repairCount)",
                    icon: "hammer.fill",
                    color: FrancoSphereDesign.DashboardColors.warning
                )
                
                StatCard(
                    title: "Total Cost",
                    value: viewModel.totalMaintenanceCost.formatted(.currency(code: "USD")),
                    icon: "dollarsign.circle.fill",
                    color: FrancoSphereDesign.DashboardColors.accent
                )
            }
        }
    }
    
    private var maintenanceFiltersSection: some View {
        VStack(spacing: 12) {
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MaintenanceFilter.allCases, id: \.self) { filter in
                        BuildingFilterPill(
                            title: filter.rawValue,
                            icon: filter.icon,
                            isSelected: filterOption == filter,
                            action: { filterOption = filter }
                        )
                    }
                }
            }
            
            // Date range selector
            HStack {
                Text("Date Range:")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Spacer()
                
                Menu {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        Button(action: { dateRange = range }) {
                            Label(range.rawValue, systemImage: "calendar")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(dateRange.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FrancoSphereDesign.DashboardColors.accent.opacity(0.1))
            )
        }
    }
    
    private var maintenanceHistoryList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Maintenance History", systemImage: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            if filteredMaintenanceRecords.isEmpty {
                EmptyStateMessage(message: "No maintenance records found")
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredMaintenanceRecords) { record in
                        MaintenanceHistoryRow(record: record)
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var filteredMaintenanceRecords: [CoreTypes.MaintenanceRecord] {
        viewModel.maintenanceHistory.filter { record in
            // Filter by category
            if filterOption != .all {
                // Implement category filtering logic
            }
            
            // Filter by date range
            let calendar = Calendar.current
            if let daysAgo = calendar.date(byAdding: .day, value: -dateRange.days, to: Date()) {
                return record.date >= daysAgo
            }
            
            return true
        }
    }
}

// Inventory Tab (Consolidated from InventoryView)
struct BuildingInventoryTab: View {
    let buildingId: String
    let buildingName: String
    @ObservedObject var viewModel: BuildingDetailVM
    @State private var selectedCategory: InventoryCategory = .supplies
    @State private var showingAddItem = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Inventory stats
            inventoryStatsSection
                .animatedGlassAppear(delay: 0.1)
            
            // Category filter
            inventoryCategoryFilter
                .animatedGlassAppear(delay: 0.2)
            
            // Low stock alert
            if viewModel.hasLowStockItems {
                lowStockAlert
                    .animatedGlassAppear(delay: 0.3)
            }
            
            // Inventory items
            inventoryItemsList
                .animatedGlassAppear(delay: 0.4)
        }
        .sheet(isPresented: $showingAddItem) {
            BuildingAddInventoryItemSheet(buildingId: buildingId) { success in
                if success {
                    Task { await viewModel.loadInventoryData() }
                }
            }
        }
    }
    
    private var inventoryStatsSection: some View {
        HStack(spacing: 16) {
            InventoryStatCard(
                title: "Total Items",
                value: "\(viewModel.totalInventoryItems)",
                icon: "cube.box.fill",
                color: FrancoSphereDesign.DashboardColors.info
            )
            
            InventoryStatCard(
                title: "Low Stock",
                value: "\(viewModel.lowStockCount)",
                icon: "exclamationmark.triangle.fill",
                color: FrancoSphereDesign.DashboardColors.warning
            )
            
            InventoryStatCard(
                title: "Total Value",
                value: viewModel.totalInventoryValue.formatted(.currency(code: "USD")),
                icon: "dollarsign.circle.fill",
                color: FrancoSphereDesign.DashboardColors.success
            )
        }
    }
    
    private var inventoryCategoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InventoryCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }
    
    private var lowStockAlert: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
            
            Text("\(viewModel.lowStockCount) items are running low")
                .font(.subheadline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Spacer()
            
            Button("Reorder") {
                viewModel.initiateReorder()
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(FrancoSphereDesign.DashboardColors.warning)
            .cornerRadius(8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FrancoSphereDesign.DashboardColors.warning.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var inventoryItemsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Inventory Items", systemImage: "shippingbox.fill")
                    .font(.headline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Spacer()
                
                Button(action: { showingAddItem = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
                }
            }
            
            if filteredInventoryItems.isEmpty {
                EmptyStateMessage(message: "No items in this category")
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredInventoryItems) { item in
                        InventoryItemRow(item: item) { updatedItem in
                            viewModel.updateInventoryItem(updatedItem)
                        }
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var filteredInventoryItems: [InventoryItem] {
        viewModel.inventoryItems.filter { item in
            selectedCategory == .other || item.category == selectedCategory
        }
    }
}

// Spaces Tab
struct BuildingSpacesTab: View {
    let buildingId: String
    let buildingName: String
    @ObservedObject var viewModel: BuildingDetailVM
    let onPhotoCapture: () -> Void
    @State private var searchText = ""
    @State private var selectedSpace: SpaceAccess?
    
    var body: some View {
        VStack(spacing: 20) {
            // Search bar
            searchBar
                .animatedGlassAppear(delay: 0.1)
            
            // Access codes summary
            if !viewModel.accessCodes.isEmpty {
                accessCodesCard
                    .animatedGlassAppear(delay: 0.2)
            }
            
            // Spaces grid
            spacesGrid
                .animatedGlassAppear(delay: 0.3)
        }
        .sheet(item: $selectedSpace) { space in
            SpaceDetailSheet(
                space: space,
                buildingName: buildingName,
                onUpdate: { updatedSpace in
                    viewModel.updateSpace(updatedSpace)
                }
            )
        }
    }
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                TextField("Search spaces...", text: $searchText)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(FrancoSphereDesign.glassMorphism())
            )
            
            Button(action: onPhotoCapture) {
                Image(systemName: "camera.fill")
                    .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(FrancoSphereDesign.glassMorphism())
                    )
            }
        }
    }
    
    private var accessCodesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Quick Access Codes", systemImage: "lock.circle.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.accessCodes.prefix(3)) { code in
                        AccessCodeChip(code: code)
                    }
                    
                    if viewModel.accessCodes.count > 3 {
                        Text("+\(viewModel.accessCodes.count - 3) more")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(FrancoSphereDesign.glassMorphism())
                            )
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var spacesGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Utility Spaces", systemImage: "key.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredSpaces) { space in
                    SpaceCard(space: space) {
                        selectedSpace = space
                    }
                }
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var filteredSpaces: [SpaceAccess] {
        if searchText.isEmpty {
            return viewModel.spaces
        } else {
            return viewModel.spaces.filter { space in
                space.name.localizedCaseInsensitiveContains(searchText) ||
                space.notes?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }
}

// Emergency Tab
struct BuildingEmergencyTab: View {
    @ObservedObject var viewModel: BuildingDetailVM
    let onCall: () -> Void
    let onMessage: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Emergency contacts
            emergencyContactsCard
                .animatedGlassAppear(delay: 0.1)
            
            // Quick actions
            emergencyActionsCard
                .animatedGlassAppear(delay: 0.2)
            
            // Emergency procedures
            emergencyProceduresCard
                .animatedGlassAppear(delay: 0.3)
        }
    }
    
    private var emergencyContactsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Emergency Contacts", systemImage: "phone.arrow.up.right")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                BuildingEmergencyContactRow(
                    name: "24/7 Emergency Line",
                    role: "Franco Response Team",
                    phone: "(212) 555-0911",
                    isPrimary: true,
                    onCall: onCall
                )
                
                if let buildingEmergency = viewModel.emergencyContact {
                    BuildingEmergencyContactRow(
                        name: buildingEmergency.name,
                        role: buildingEmergency.role ?? "Building Emergency",
                        phone: buildingEmergency.phone ?? "N/A",
                        isPrimary: false,
                        onCall: onCall
                    )
                }
                
                BuildingEmergencyContactRow(
                    name: "Operations Manager",
                    role: "David Rodriguez",
                    phone: "(212) 555-0123",
                    isPrimary: false,
                    onCall: onCall
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private var emergencyActionsCard: some View {
        HStack(spacing: 16) {
            EmergencyActionButton(
                title: "Call 911",
                icon: "phone.fill",
                color: FrancoSphereDesign.DashboardColors.critical,
                action: { callNumber("911") }
            )
            
            EmergencyActionButton(
                title: "Report Issue",
                icon: "exclamationmark.triangle.fill",
                color: FrancoSphereDesign.DashboardColors.warning,
                action: { viewModel.reportEmergencyIssue() }
            )
            
            EmergencyActionButton(
                title: "Alert Team",
                icon: "bell.badge.fill",
                color: FrancoSphereDesign.DashboardColors.info,
                action: { viewModel.alertEmergencyTeam() }
            )
        }
    }
    
    private var emergencyProceduresCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Emergency Procedures", systemImage: "doc.text.fill")
                .font(.headline)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            VStack(spacing: 12) {
                BuildingProcedureRow(
                    title: "Fire Emergency",
                    icon: "flame.fill",
                    color: .red,
                    steps: [
                        "Pull fire alarm",
                        "Evacuate via nearest exit",
                        "Call 911",
                        "Alert Franco Emergency Line"
                    ]
                )
                
                BuildingProcedureRow(
                    title: "Medical Emergency",
                    icon: "cross.circle.fill",
                    color: .red,
                    steps: [
                        "Call 911 immediately",
                        "Do not move injured person",
                        "Alert building management",
                        "Contact Franco Emergency"
                    ]
                )
                
                BuildingProcedureRow(
                    title: "Building Security",
                    icon: "lock.shield.fill",
                    color: .orange,
                    steps: [
                        "Report suspicious activity",
                        "Contact building security",
                        "Alert Franco Operations",
                        "Document incident"
                    ]
                )
            }
        }
        .padding()
        .francoDarkCardBackground()
    }
    
    private func callNumber(_ number: String) {
        let cleanNumber = number.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard let url = URL(string: "tel://\(cleanNumber)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Supporting Components

struct BuildingMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: CoreTypes.TrendDirection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Spacer()
                
                Image(systemName: trendIcon)
                    .font(.caption2)
                    .foregroundColor(trendColor)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .francoDarkCardBackground()
    }
    
    private var trendIcon: String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        default: return "questionmark"
        }
    }
    
    private var trendColor: Color {
        FrancoSphereDesign.EnumColors.trendDirection(trend)
    }
}

struct BuildingActivityRow: View {
    let activity: BuildingDetailActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconForActivity(activity.type))
                .font(.caption)
                .foregroundColor(colorForActivity(activity.type))
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(colorForActivity(activity.type).opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                HStack(spacing: 8) {
                    if let worker = activity.workerName {
                        Text(worker)
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                    }
                    
                    Text(activity.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            
            Spacer()
        }
    }
    
    private func iconForActivity(_ type: BuildingDetailActivity.ActivityType) -> String {
        switch type {
        case .taskCompleted: return "checkmark.circle"
        case .photoAdded: return "camera"
        case .issueReported: return "exclamationmark.triangle"
        case .workerArrived: return "person.crop.circle.badge.checkmark"
        case .workerDeparted: return "person.crop.circle.badge.minus"
        case .routineCompleted: return "calendar.badge.checkmark"
        case .inventoryUsed: return "shippingbox"
        }
    }
    
    private func colorForActivity(_ type: BuildingDetailActivity.ActivityType) -> Color {
        switch type {
        case .taskCompleted, .routineCompleted, .workerArrived:
            return FrancoSphereDesign.DashboardColors.success
        case .photoAdded:
            return FrancoSphereDesign.DashboardColors.info
        case .issueReported:
            return FrancoSphereDesign.DashboardColors.warning
        case .workerDeparted, .inventoryUsed:
            return FrancoSphereDesign.DashboardColors.inactive
        }
    }
}

struct BuildingContactRow: View {
    let name: String
    let role: String
    let phone: String?
    let isEmergency: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isEmergency ? FrancoSphereDesign.DashboardColors.critical.opacity(0.2) : FrancoSphereDesign.DashboardColors.info.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: isEmergency ? "phone.arrow.up.right" : "phone.fill")
                        .foregroundColor(isEmergency ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.info)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(role)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
            }
            
            Spacer()
            
            if let phone = phone {
                Text(phone)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
        }
    }
}

struct BuildingFilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? .white : FrancoSphereDesign.DashboardColors.secondaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? FrancoSphereDesign.DashboardColors.accent : FrancoSphereDesign.glassMorphism())
            )
        }
    }
}

struct EmptyStateMessage: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}

struct DailyRoutineRow: View {
    let routine: DailyRoutine
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: routine.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(routine.isCompleted ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.title)
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    .strikethrough(routine.isCompleted)
                
                HStack(spacing: 8) {
                    if let time = routine.scheduledTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                    }
                    
                    if let worker = routine.assignedWorker {
                        Label(worker, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct MaintenanceTaskRow: View {
    let task: CoreTypes.MaintenanceTask
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Circle()
                    .fill(urgencyColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: categoryIcon)
                            .foregroundColor(urgencyColor)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    HStack(spacing: 8) {
                        if let dueDate = task.dueDate {
                            Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                                .font(.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                        }
                        
                        Text(task.urgency.rawValue.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(urgencyColor)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var urgencyColor: Color {
        switch task.urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .urgent: return .purple
        case .critical, .emergency: return .red
        }
    }
    
    private var categoryIcon: String {
        switch task.category {
        case .cleaning: return "sparkles"
        case .maintenance: return "wrench"
        case .repair: return "hammer"
        case .inspection: return "magnifyingglass"
        default: return "wrench.and.screwdriver"
        }
    }
}

struct ComplianceRow: View {
    let title: String
    let status: CoreTypes.ComplianceStatus
    let nextAction: String?
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: status == .compliant ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(FrancoSphereDesign.EnumColors.complianceStatus(status))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                if let action = nextAction {
                    Text(action)
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                }
            }
            
            Spacer()
        }
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .francoDarkCardBackground()
    }
}

struct OnSiteWorkerRow: View {
    let worker: AssignedWorker
    
    var body: some View {
        HStack {
            Circle()
                .fill(FrancoSphereDesign.DashboardColors.success)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text("Arrived \(Date().addingTimeInterval(-3600), style: .relative)")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
            
            Text("On-site")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(FrancoSphereDesign.DashboardColors.success)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(FrancoSphereDesign.DashboardColors.success.opacity(0.15))
                )
        }
    }
}

struct AssignedWorkerRow: View {
    let worker: AssignedWorker
    
    var body: some View {
        HStack {
            Circle()
                .fill(worker.isOnSite ? FrancoSphereDesign.DashboardColors.success : FrancoSphereDesign.DashboardColors.inactive)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(worker.schedule)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
        }
    }
}

struct MaintenanceHistoryRow: View {
    @Published var maintenanceHistory: [CoreTypes.MaintenanceRecord] = []
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
            
            if let cost = record.cost {
                Text(cost.formatted(.currency(code: "USD")))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
            }
        }
    }
}

struct InventoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .francoDarkCardBackground()
    }
}

struct AccessCodeChip: View {
    let code: AccessCode
    @State private var isRevealed = false
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(code.location)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(isRevealed ? code.code : "••••")
                    .font(.caption)
                    .fontFamily(.monospaced)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
            }
            
            Button(action: { isRevealed.toggle() }) {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(FrancoSphereDesign.glassMorphism())
        )
    }
}

struct SpaceCard: View {
    let space: SpaceAccess
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                if let photo = space.thumbnail {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 100)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    FrancoSphereDesign.DashboardColors.accent.opacity(0.3),
                                    FrancoSphereDesign.DashboardColors.accent.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: space.category.icon)
                                .font(.title)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.accent.opacity(0.5))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(space.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        if space.requiresKey {
                            Label("Key", systemImage: "key.fill")
                                .font(.caption2)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        }
                        
                        if space.accessCode != nil {
                            Label("Code", systemImage: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.info)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FrancoSphereDesign.glassMorphism())
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct BuildingEmergencyContactRow: View {
    let name: String
    let role: String
    let phone: String
    let isPrimary: Bool
    let onCall: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(isPrimary ? FrancoSphereDesign.DashboardColors.critical.opacity(0.2) : FrancoSphereDesign.DashboardColors.info.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "phone.fill")
                        .foregroundColor(isPrimary ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.info)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                
                Text(role)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                
                Text(phone)
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
            }
            
            Spacer()
            
            Button(action: onCall) {
                Image(systemName: "phone.arrow.up.right")
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isPrimary ? FrancoSphereDesign.DashboardColors.critical : FrancoSphereDesign.DashboardColors.info)
                    )
            }
        }
    }
}

struct EmergencyActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color)
            .cornerRadius(12)
        }
    }
}

struct BuildingProcedureRow: View {
    let title: String
    let icon: String
    let color: Color
    let steps: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(color)
                            
                            Text(step)
                                .font(.caption)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryText)
                        }
                    }
                }
                .padding(.leading, 28)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Sheet Views

struct MaintenanceTaskDetailSheet: View {
    let task: CoreTypes.MaintenanceTask
    let buildingName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            MaintenanceTaskView(
                task: task,
                buildingName: buildingName
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(FrancoSphereDesign.DashboardColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct BuildingAddInventoryItemSheet: View {
    let buildingId: String
    let onComplete: (Bool) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        AddInventoryItemView(
            buildingId: buildingId,
            onComplete: { success in
                onComplete(success)
                dismiss()
            }
        )
    }
}

// MARK: - View Model Extension

extension BuildingDetailVM {
    // Additional computed properties for the refactored view
    var onSiteWorkers: [AssignedWorker] {
        assignedWorkers.filter { $0.isOnSite }
    }
    
    var maintenanceTasks: [CoreTypes.MaintenanceTask] {
        // This would fetch actual maintenance tasks from the database
        []
    }
    
    var hasComplianceIssues: Bool {
        dsnyCompliance != .compliant ||
        fireSafetyCompliance != .compliant ||
        healthCompliance != .compliant
    }
    
    var hasLowStockItems: Bool {
        lowStockCount > 0
    }
    
    var lowStockCount: Int {
        inventorySummary.cleaningLow +
        inventorySummary.equipmentLow +
        inventorySummary.maintenanceLow +
        inventorySummary.safetyLow
    }
    
    var totalInventoryItems: Int {
        inventorySummary.cleaningTotal +
        inventorySummary.equipmentTotal +
        inventorySummary.maintenanceTotal +
        inventorySummary.safetyTotal
    }
    
    var totalInventoryValue: Double {
        // Calculate from actual inventory items
        1250.50
    }
    
    var maintenanceThisWeek: Int {
        // Calculate from maintenance history
        8
    }
    
    var repairCount: Int {
        // Count repairs from maintenance history
        3
    }
    
    var totalMaintenanceCost: Double {
        // Sum from maintenance history
        487.50
    }
    
    var averageWorkerHours: Int {
        // Calculate average from worker data
        8
    }
    
    var buildingRating: String {
        // Calculate based on metrics
        "A+"
    }
    
    var inventoryItems: [InventoryItem] {
        // Fetch from database
        []
    }
    
    // Additional action methods
    func loadInventoryData() async {
        // Load inventory data
    }
    
    func updateInventoryItem(_ item: InventoryItem) {
        // Update inventory item
    }
    
    func initiateReorder() {
        // Initiate reorder process
    }
    
    func reportEmergencyIssue() {
        // Report emergency issue
    }
    
    func alertEmergencyTeam() {
        // Alert emergency team
    }
}

// MARK: - Data Types

struct BuildingContact: Identifiable {
    let id = UUID()
    let name: String
    let role: String?
    let email: String?
    let phone: String?
    let isEmergencyContact: Bool
}

struct BuildingDetailActivity: Identifiable {
    let id: String
    let type: ActivityType
    let description: String
    let timestamp: Date
    let workerName: String?
    let photoId: String?
    
    enum ActivityType {
        case taskCompleted
        case photoAdded
        case issueReported
        case workerArrived
        case workerDeparted
        case routineCompleted
        case inventoryUsed
    }
}

struct DailyRoutine: Identifiable {
    let id: String
    let title: String
    let scheduledTime: String?
    var isCompleted: Bool = false
    var assignedWorker: String? = nil
    var requiredInventory: [String] = []
}

struct AssignedWorker: Identifiable {
    let id: String
    let name: String
    let schedule: String
    let isOnSite: Bool
}

struct SpaceAccess: Identifiable {
    let id: String
    let name: String
    let category: SpaceCategory
    let thumbnail: UIImage?
    let lastUpdated: Date
    let accessCode: String?
    let notes: String?
    let requiresKey: Bool
    let photos: [FrancoBuildingPhoto]
}

struct AccessCode: Identifiable {
    let id: String
    let location: String
    let code: String
    let type: String // "keypad", "lock box", "alarm"
    let updatedDate: Date
}

enum SpaceCategory: String, CaseIterable {
    case all = "All"
    case utility = "Utility"
    case mechanical = "Mechanical"
    case storage = "Storage"
    case electrical = "Electrical"
    case access = "Access Points"
    
    var displayName: String {
        switch self {
        case .all: return "All Spaces"
        default: return rawValue
        }
    }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .utility: return "wrench.fill"
        case .mechanical: return "gear"
        case .storage: return "shippingbox"
        case .electrical: return "bolt.fill"
        case .access: return "key.fill"
        }
    }
}

// MARK: - View Model

@MainActor
class BuildingDetailVM: ObservableObject {
    let buildingId: String
    let buildingName: String
    let buildingAddress: String
    
    // Services
    private let photoStorageService = FrancoPhotoStorageService.shared
    private let locationManager = LocationManager.shared
    private let buildingService = BuildingService.shared
    private let taskService = TaskService.shared
    private let inventoryService = InventoryService.shared
    private let workerService = WorkerService.shared
    
    // User context
    @Published var userRole: CoreTypes.UserRole = .worker
    
    // Overview data
    @Published var buildingImage: UIImage?
    @Published var completionPercentage: Int = 0
    @Published var workersOnSite: Int = 0
    @Published var workersPresent: [String] = []
    @Published var todaysTasks: (total: Int, completed: Int)?
    @Published var nextCriticalTask: String?
    @Published var todaysSpecialNote: String?
    @Published var isFavorite: Bool = false
    @Published var complianceStatus: CoreTypes.ComplianceStatus?
    @Published var primaryContact: BuildingContact?
    @Published var emergencyContact: BuildingContact?
    
    // Building details
    @Published var buildingType: String = "Commercial"
    @Published var buildingSize: Int = 0
    @Published var floors: Int = 0
    @Published var units: Int = 0
    @Published var yearBuilt: Int = 1900
    @Published var contractType: String?
    
    // Metrics
    @Published var efficiencyScore: Int = 0
    @Published var complianceScore: String = "A"
    @Published var openIssues: Int = 0
    
    // Spaces & Access
    @Published var spaceSearchQuery: String = ""
    @Published var selectedSpaceCategory: SpaceCategory = .all
    @Published var spaces: [SpaceAccess] = []
    @Published var accessCodes: [AccessCode] = []
    
    var filteredSpaces: [SpaceAccess] {
        var filtered = spaces
        
        // Category filter
        if selectedSpaceCategory != .all {
            filtered = filtered.filter { $0.category == selectedSpaceCategory }
        }
        
        // Search filter
        if !spaceSearchQuery.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(spaceSearchQuery) ||
                $0.notes?.localizedCaseInsensitiveContains(spaceSearchQuery) ?? false
            }
        }
        
        return filtered
    }
    
    // Routines data
    @Published var dailyRoutines: [DailyRoutine] = []
    @Published var completedRoutines: Int = 0
    @Published var totalRoutines: Int = 0
    
    // Inventory summary
    @Published var inventorySummary = InventorySummary()
    
    // Compliance
    @Published var dsnyCompliance: CoreTypes.ComplianceStatus = .compliant
    @Published var nextDSNYAction: String?
    @Published var fireSafetyCompliance: CoreTypes.ComplianceStatus = .compliant
    @Published var nextFireSafetyAction: String?
    @Published var healthCompliance: CoreTypes.ComplianceStatus = .compliant
    @Published var nextHealthAction: String?
    
    init(buildingId: String, buildingName: String, buildingAddress: String) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.buildingAddress = buildingAddress
        loadUserRole()
    }
    
    func loadBuildingData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadBuildingDetails() }
            group.addTask { await self.loadTodaysMetrics() }
            group.addTask { await self.loadRoutines() }
            group.addTask { await self.loadSpacesAndAccess() }
            group.addTask { await self.loadInventorySummary() }
            group.addTask { await self.loadComplianceStatus() }
            group.addTask { await self.loadActivityData() }
        }
    }
    
    func refreshData() async {
        await loadTodaysMetrics()
        await loadActivityData()
    }
    
    private func loadUserRole() {
        if let roleString = NewAuthManager.shared.currentUser?.role,
           let role = CoreTypes.UserRole(rawValue: roleString) {
            userRole = role
        }
    }
    
    private func loadBuildingDetails() async {
        do {
            let building = try await buildingService.getBuildingDetails(buildingId)
            
            await MainActor.run {
                self.buildingType = building.type.rawValue.capitalized
                self.buildingSize = building.squareFootage
                self.floors = building.floors
                self.units = building.units ?? 1
                self.yearBuilt = building.yearBuilt ?? 1900
                self.contractType = building.contractType
                
                // Load primary contact
                if let contact = building.primaryContact {
                    self.primaryContact = BuildingContact(
                        name: contact.name,
                        role: contact.role,
                        email: contact.email,
                        phone: contact.phone,
                        isEmergencyContact: contact.isEmergency
                    )
                }
            }
        } catch {
            print("❌ Error loading building details: \(error)")
        }
    }
    
    private func loadTodaysMetrics() async {
        do {
            let metrics = try await buildingService.getTodaysMetrics(buildingId)
            
            await MainActor.run {
                self.completionPercentage = metrics.completionPercentage
                self.workersOnSite = metrics.workersOnSite
                self.workersPresent = metrics.workersPresent
                self.todaysTasks = (metrics.totalTasks, metrics.completedTasks)
                self.nextCriticalTask = metrics.nextCriticalTask
                self.todaysSpecialNote = metrics.specialNote
                self.efficiencyScore = metrics.efficiencyScore
                self.openIssues = metrics.openIssues
            }
        } catch {
            print("❌ Error loading metrics: \(error)")
        }
    }
    
    private func loadRoutines() async {
        do {
            let routines = try await taskService.getDailyRoutines(buildingId: buildingId)
            
            await MainActor.run {
                self.dailyRoutines = routines.map { routine in
                    DailyRoutine(
                        id: routine.id,
                        title: routine.title,
                        scheduledTime: routine.scheduledTime?.formatted(date: .omitted, time: .shortened),
                        isCompleted: routine.status == .completed,
                        assignedWorker: routine.assignedWorkerName,
                        requiredInventory: routine.requiredInventory ?? []
                    )
                }
                
                self.completedRoutines = dailyRoutines.filter { $0.isCompleted }.count
                self.totalRoutines = dailyRoutines.count
            }
        } catch {
            print("❌ Error loading routines: \(error)")
        }
    }
    
    private func loadSpacesAndAccess() async {
        do {
            // Load spaces with photos
            let buildingSpaces = try await buildingService.getSpaces(buildingId: buildingId)
            
            await MainActor.run {
                self.spaces = buildingSpaces.map { space in
                    SpaceAccess(
                        id: space.id,
                        name: space.name,
                        category: mapToSpaceCategory(space.type),
                        thumbnail: nil, // Load async
                        lastUpdated: space.lastPhotoDate ?? Date(),
                        accessCode: space.accessCode,
                        notes: space.notes,
                        requiresKey: space.requiresPhysicalKey,
                        photos: []
                    )
                }
                
                // Load access codes
                self.accessCodes = buildingSpaces.compactMap { space in
                    guard let code = space.accessCode else { return nil }
                    return AccessCode(
                        id: space.id,
                        location: space.name,
                        code: code,
                        type: space.accessType ?? "keypad",
                        updatedDate: space.lastUpdated
                    )
                }
            }
            
            // Load thumbnails
            await loadSpaceThumbnails()
            
        } catch {
            print("❌ Error loading spaces: \(error)")
        }
    }
    
    private func loadSpaceThumbnails() async {
        for (index, space) in spaces.enumerated() {
            do {
                // Load photos for the building and filter by space
                let photos = try await photoStorageService.loadPhotos(for: buildingId)
                let spacePhotos = photos.filter { photo in
                    // Filter photos that might belong to this space based on category or notes
                    if space.category == .utilities && photo.category == .utilities {
                        return true
                    }
                    // Additional filtering logic could be added here
                    return false
                }
                
                if let firstPhoto = spacePhotos.first, let thumbnail = firstPhoto.thumbnail {
                    await MainActor.run {
                        self.spaces[index] = SpaceAccess(
                            id: space.id,
                            name: space.name,
                            category: space.category,
                            thumbnail: thumbnail,
                            lastUpdated: space.lastUpdated,
                            accessCode: space.accessCode,
                            notes: space.notes,
                            requiresKey: space.requiresKey,
                            photos: spacePhotos
                        )
                    }
                }
            } catch {
                print("❌ Error loading thumbnail for space \(space.id): \(error)")
            }
        }
    }
    
    private func loadInventorySummary() async {
        do {
            let summary = try await inventoryService.getBuildingInventorySummary(buildingId: buildingId)
            
            await MainActor.run {
                self.inventorySummary = InventorySummary(
                    cleaningLow: summary.categorySummaries[.cleaning]?.lowStockCount ?? 0,
                    cleaningTotal: summary.categorySummaries[.cleaning]?.totalItems ?? 0,
                    equipmentLow: summary.categorySummaries[.equipment]?.lowStockCount ?? 0,
                    equipmentTotal: summary.categorySummaries[.equipment]?.totalItems ?? 0,
                    maintenanceLow: summary.categorySummaries[.maintenance]?.lowStockCount ?? 0,
                    maintenanceTotal: summary.categorySummaries[.maintenance]?.totalItems ?? 0,
                    safetyLow: summary.categorySummaries[.safety]?.lowStockCount ?? 0,
                    safetyTotal: summary.categorySummaries[.safety]?.totalItems ?? 0
                )
            }
        } catch {
            print("❌ Error loading inventory summary: \(error)")
        }
    }
    
    private func loadComplianceStatus() async {
        do {
            let compliance = try await buildingService.getComplianceStatus(buildingId: buildingId)
            
            await MainActor.run {
                self.complianceStatus = compliance.overallStatus
                
                // DSNY compliance
                if let dsny = compliance.categories.first(where: { $0.type == "DSNY" }) {
                    self.dsnyCompliance = dsny.status
                    self.nextDSNYAction = dsny.nextRequiredAction
                }
                
                // Fire safety
                if let fire = compliance.categories.first(where: { $0.type == "Fire Safety" }) {
                    self.fireSafetyCompliance = fire.status
                    self.nextFireSafetyAction = fire.nextRequiredAction
                }
                
                // Health
                if let health = compliance.categories.first(where: { $0.type == "Health" }) {
                    self.healthCompliance = health.status
                    self.nextHealthAction = health.nextRequiredAction
                }
            }
        } catch {
            print("❌ Error loading compliance: \(error)")
        }
    }
    
    private func loadActivityData() async {
        do {
            // Load assigned workers
            let workers = try await workerService.getAssignedWorkers(buildingId: buildingId)
            
            // Load recent activities
            let activities = try await buildingService.getRecentActivity(buildingId: buildingId, limit: 20)
            
            // Load maintenance history
            let maintenance = try await buildingService.getMaintenanceHistory(buildingId: buildingId, limit: 5)
            
            await MainActor.run {
                self.assignedWorkers = workers.map { worker in
                    AssignedWorker(
                        id: worker.id,
                        name: worker.displayName,
                        schedule: worker.schedule,
                        isOnSite: worker.clockStatus == .clockedIn && worker.currentBuildingId == buildingId
                    )
                }
                
                self.recentActivities = activities.map { activity in
                    BuildingDetailActivity(
                        id: activity.id,
                        type: mapActivityType(activity.type),
                        description: activity.description,
                        timestamp: activity.timestamp,
                        workerName: activity.workerName,
                        photoId: activity.relatedPhotoId
                    )
                }
                
                self.maintenanceHistory = maintenance.map { record in
                    MaintenanceRecord(
                        id: record.id,
                        title: record.title,
                        date: record.date,
                        description: record.description,
                        cost: record.cost
                    )
                }
            }
        } catch {
            print("❌ Error loading activity data: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func toggleRoutineCompletion(_ routine: DailyRoutine) {
        Task {
            do {
                let newStatus: CoreTypes.TaskStatus = routine.isCompleted ? .pending : .completed
                try await taskService.updateTaskStatus(routine.id, status: newStatus)
                
                // Update local state
                if let index = dailyRoutines.firstIndex(where: { $0.id == routine.id }) {
                    dailyRoutines[index].isCompleted.toggle()
                    completedRoutines = dailyRoutines.filter { $0.isCompleted }.count
                }
                
                // Broadcast update
                let update = CoreTypes.DashboardUpdate(
                    source: .worker,
                    type: .taskCompleted,
                    buildingId: buildingId,
                    workerId: NewAuthManager.shared.workerId ?? "",
                    data: [
                        "routineId": routine.id,
                        "routineTitle": routine.title,
                        "isCompleted": String(!routine.isCompleted)
                    ]
                )
                DashboardSyncService.shared.broadcastWorkerUpdate(update)
                
            } catch {
                print("❌ Error updating routine: \(error)")
            }
        }
    }
    
    func assignWorkerToRoutine(_ routine: DailyRoutine, workerId: String) {
        Task {
            do {
                try await taskService.assignWorker(taskId: routine.id, workerId: workerId)
                
                // Update local state
                if let index = dailyRoutines.firstIndex(where: { $0.id == routine.id }) {
                    let workerName = assignedWorkers.first(where: { $0.id == workerId })?.name ?? "Unknown"
                    dailyRoutines[index].assignedWorker = workerName
                }
                
                // Broadcast update
                let update = CoreTypes.DashboardUpdate(
                    source: .admin,
                    type: .taskUpdated,
                    buildingId: buildingId,
                    workerId: workerId,
                    data: [
                        "routineId": routine.id,
                        "action": "workerAssigned"
                    ]
                )
                DashboardSyncService.shared.broadcastAdminUpdate(update)
                
            } catch {
                print("❌ Error assigning worker: \(error)")
            }
        }
    }
    
    func savePhoto(_ photo: UIImage, category: FrancoPhotoCategory, notes: String) async {
        do {
            // Get current location
            let location = await locationManager.getCurrentLocation()
            
            // Create metadata
            let metadata = FrancoBuildingPhotoMetadata(
                buildingId: buildingId,
                category: category,
                notes: notes.isEmpty ? nil : notes,
                location: location,
                taskId: nil,
                workerId: NewAuthManager.shared.workerId,
                timestamp: Date()
            )
            
            let savedPhoto = try await photoStorageService.savePhoto(photo, metadata: metadata)
            print("✅ Photo saved: \(savedPhoto.id)")
            
            // Reload spaces if it was a space photo
            if category == .utilities || category == .mechanical || category == .storage {
                await loadSpacesAndAccess()
            }
            
            // Broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: .worker,
                type: .buildingMetricsChanged,
                buildingId: buildingId,
                workerId: NewAuthManager.shared.workerId ?? "",
                data: [
                    "action": "photoAdded",
                    "photoId": savedPhoto.id,
                    "category": category.rawValue
                ]
            )
            DashboardSyncService.shared.broadcastWorkerUpdate(update)
            
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    func updateSpace(_ space: SpaceAccess) {
        if let index = spaces.firstIndex(where: { $0.id == space.id }) {
            spaces[index] = space
        }
    }
    
    func loadInventoryData() async {
        // Load inventory data
    }
    
    func updateInventoryItem(_ item: InventoryItem) {
        // Update inventory item
    }
    
    func initiateReorder() {
        // Initiate reorder process
    }
    
    func exportBuildingReport() {
        // TODO: Implement report generation
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
        // TODO: Save to user preferences
    }
    
    func editBuildingInfo() {
        // TODO: Navigate to edit screen (admin only)
    }
    
    func reportIssue() {
        // TODO: Open issue reporting flow
    }
    
    func requestSupplies() {
        // TODO: Open supply request flow
    }
    
    func addNote() {
        // TODO: Add note to building
    }
    
    func logVendorVisit() {
        // TODO: Log vendor visit
    }
    
    func reportEmergencyIssue() {
        // Report emergency issue
    }
    
    func alertEmergencyTeam() {
        // Alert emergency team
    }
    
    // MARK: - Helper Methods
    
    private func mapToSpaceCategory(_ type: String) -> SpaceCategory {
        switch type.lowercased() {
        case "utility": return .utility
        case "mechanical": return .mechanical
        case "storage": return .storage
        case "electrical": return .electrical
        case "access": return .access
        default: return .utility
        }
    }
    
    private func mapActivityType(_ type: String) -> BuildingDetailActivity.ActivityType {
        switch type {
        case "task_completed": return .taskCompleted
        case "photo_added": return .photoAdded
        case "issue_reported": return .issueReported
        case "worker_arrived": return .workerArrived
        case "worker_departed": return .workerDeparted
        case "routine_completed": return .routineCompleted
        case "inventory_used": return .inventoryUsed
        default: return .taskCompleted
        }
    }
}

// MARK: - Supporting Models

struct InventorySummary {
    var cleaningLow: Int = 0
    var cleaningTotal: Int = 0
    var equipmentLow: Int = 0
    var equipmentTotal: Int = 0
    var maintenanceLow: Int = 0
    var maintenanceTotal: Int = 0
    var safetyLow: Int = 0
    var safetyTotal: Int = 0
}

// MARK: - Placeholder Views

struct BuildingInventoryDetailView: View {
    let buildingId: String
    
    var body: some View {
        Text("Inventory Detail View - Coming Soon")
            .navigationTitle("Inventory")
    }
}

struct BuildingMaintenanceHistoryView: View {
    let buildingId: String
    
    var body: some View {
        Text("Maintenance History - Coming Soon")
            .navigationTitle("Maintenance History")
    }
}

struct MessageComposerView: View {
    let recipients: [String]
    let subject: String
    let prefilledBody: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Message Composer")
                    .font(.largeTitle)
                Text("Email integration coming in Phase 2")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Camera View (Using existing ImagePicker)
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Worker Assignment Sheet
struct WorkerAssignmentSheet: View {
    let buildingId: String
    let routine: DailyRoutine
    let onAssign: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var availableWorkers: [AssignedWorker] = []
    @State private var selectedWorkerId: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assign Worker")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(routine.title)
                            .font(.headline)
                        
                        if let time = routine.scheduledTime {
                            Text(time)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                }
                .padding()
                
                // Worker list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(availableWorkers) { worker in
                            WorkerSelectionRow(
                                worker: worker,
                                isSelected: selectedWorkerId == worker.id,
                                onSelect: {
                                    selectedWorkerId = worker.id
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
                    
                    Button("Assign") {
                        if let workerId = selectedWorkerId {
                            onAssign(workerId)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        selectedWorkerId != nil ? Color.blue : Color.gray
                    )
                    .cornerRadius(12)
                    .disabled(selectedWorkerId == nil)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium])
        .task {
            loadAvailableWorkers()
        }
    }
    
    private func loadAvailableWorkers() {
        // Load real workers assigned to this building
        // For now, using sample data
        availableWorkers = [
            AssignedWorker(id: "4", name: "Kevin Dutan", schedule: "6 AM - 2 PM", isOnSite: true),
            AssignedWorker(id: "2", name: "Edwin Lema", schedule: "2 PM - 10 PM", isOnSite: false),
            AssignedWorker(id: "5", name: "Mercedes Inamagua", schedule: "6 AM - 2 PM", isOnSite: false)
        ]
    }
}

struct WorkerSelectionRow: View {
    let worker: AssignedWorker
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(worker.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Text(worker.schedule)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if worker.isOnSite {
                            Label("On-site", systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

struct BuildingDetailView_Previews: PreviewProvider {
    static var previews: some View {
        BuildingDetailView(
            buildingId: "14",
            buildingName: "Rubin Museum",
            buildingAddress: "150 W 17th St, New York, NY 10011"
        )
        .preferredColorScheme(.dark)
        .environmentObject(NewAuthManager.shared)
        .environmentObject(DashboardSyncService.shared)
    }
}
