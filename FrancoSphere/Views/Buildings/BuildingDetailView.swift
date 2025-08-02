//
//  BuildingDetailView.swift
//  FrancoSphere v6.0
//
//  🏢 STREAMLINED: Consolidated tab structure for better mobile UX
//  🎨 DARK ELEGANCE: Integrated with v6.0 dark theme system
//  🔄 REAL-TIME: Live updates via DashboardSync
//  🔐 SPACES & ACCESS: Enhanced for utility rooms, access codes, and evidence photos
//  ✅ ENHANCED: Worker assignment for routines
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
    @State private var selectedRoutine: DailyRoutine?
    @State private var showWorkerAssignment = false
    @State private var capturedImage: UIImage?
    @State private var photoCategory: FrancoPhotoCategory = .utilities
    @State private var photoNotes: String = ""
    @State private var isHeaderExpanded = false
    @State private var selectedSpace: SpaceAccess?
    @State private var showingSpaceDetail = false
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
            // Dark base background
            FrancoSphereDesign.DashboardColors.baseBackground
                .ignoresSafeArea()
            
            // Subtle gradient overlay
            LinearGradient(
                colors: [
                    FrancoSphereDesign.DashboardColors.baseBackground,
                    FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                headerView
                
                // Hero section with collapsible info
                heroSection
                
                // Streamlined tab bar (4 tabs instead of 5)
                tabBar
                
                // Tab content
                tabContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
                // Quick actions bar
                quickActionsBar
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.loadBuildingData()
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
        .sheet(isPresented: $showingSpaceDetail) {
            if let space = selectedSpace {
                SpaceDetailSheet(
                    space: space,
                    buildingName: buildingName,
                    onUpdate: { updatedSpace in
                        viewModel.updateSpace(updatedSpace)
                    }
                )
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposerView(
                recipients: getMessageRecipients(),
                subject: "Re: \(buildingName)",
                prefilledBody: getBuildingContext()
            )
        }
        .sheet(isPresented: $showWorkerAssignment) {
            if let routine = selectedRoutine {
                WorkerAssignmentSheet(
                    buildingId: buildingId,
                    routine: routine,
                    onAssign: { workerId in
                        viewModel.assignWorkerToRoutine(routine, workerId: workerId)
                    }
                )
            }
        }
        .confirmationDialog("Call Contact", isPresented: $showingCallMenu) {
            callMenuOptions
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Text(buildingName)
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
            
            Spacer()
            
            // Settings/More button
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
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            FrancoSphereDesign.DashboardColors.cardBackground
                .opacity(0.95)
                .overlay(
                    Rectangle()
                        .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Hero Section (Streamlined)
    private var heroSection: some View {
        VStack(spacing: 0) {
            // Compact hero with status badges
            ZStack(alignment: .bottomLeading) {
                // Dark gradient background
                LinearGradient(
                    colors: FrancoSphereDesign.DashboardColors.workerHeroGradient.map { $0.opacity(0.9) },
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: isHeaderExpanded ? 200 : 120)
                
                // Building icon overlay
                HStack {
                    Spacer()
                    Image(systemName: viewModel.buildingIcon)
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.1))
                        .padding()
                }
                
                // Status overlay
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.buildingType)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        HStack(spacing: 12) {
                            statusBadge(
                                "\(viewModel.completionPercentage)%",
                                icon: "checkmark.circle.fill",
                                color: completionColor
                            )
                            
                            if viewModel.workersOnSite > 0 {
                                statusBadge(
                                    "\(viewModel.workersOnSite) On-Site",
                                    icon: "person.fill",
                                    color: FrancoSphereDesign.DashboardColors.secondaryAction
                                )
                            }
                            
                            if let status = viewModel.complianceStatus {
                                statusBadge(
                                    status.rawValue.capitalized,
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
                        Image(systemName: isHeaderExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                            )
                    }
                }
                .padding()
            }
            .clipped()
            
            // Expandable building info
            if isHeaderExpanded {
                buildingInfoExpanded
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            FrancoSphereDesign.DashboardColors.cardBackground
                .overlay(
                    Rectangle()
                        .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
    
    // MARK: - Expandable Building Info
    private var buildingInfoExpanded: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow("Address", value: buildingAddress)
                    InfoRow("Size", value: "\(viewModel.buildingSize.formatted()) sq ft")
                    InfoRow("Floors", value: "\(viewModel.floors)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    InfoRow("Units", value: "\(viewModel.units)")
                    InfoRow("Built", value: "\(viewModel.yearBuilt)")
                    InfoRow("Contract", value: viewModel.contractType ?? "Standard")
                }
            }
        }
        .padding()
        .background(FrancoSphereDesign.DashboardColors.glassOverlay)
    }
    
    // MARK: - Tab Bar (Consolidated)
    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(BuildingDetailTab.allCases, id: \.self) { tab in
                    if shouldShowTab(tab) {
                        tabButton(tab)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 44)
        .background(FrancoSphereDesign.DashboardColors.cardBackground.opacity(0.5))
    }
    
    private func tabButton(_ tab: BuildingDetailTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }
        }) {
            VStack(spacing: 4) {
                Text(tab.title)
                    .font(.subheadline)
                    .fontWeight(selectedTab == tab ? .semibold : .regular)
                    .foregroundColor(selectedTab == tab ? .white.opacity(0.9) : .white.opacity(0.5))
                
                // Selection indicator
                Rectangle()
                    .fill(selectedTab == tab ? FrancoSphereDesign.DashboardColors.primaryAction : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                switch selectedTab {
                case .overview:
                    overviewContent
                case .operations:
                    operationsContent
                case .spacesAccess:
                    spacesAccessContent
                case .activity:
                    activityContent
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
            .padding(.bottom, 80) // Space for quick actions
        }
    }
    
    // MARK: - Overview Tab (Streamlined)
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Today's snapshot (prominent)
            todaysSnapshotCard
            
            // Key contacts (essential)
            keyContactsCard
            
            // Quick metrics
            if viewModel.userRole != .client {
                quickMetricsCard
            }
        }
    }
    
    private var todaysSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Today's Snapshot", systemImage: "calendar.circle.fill")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(alignment: .leading, spacing: 12) {
                if let activeTasks = viewModel.todaysTasks {
                    MetricRow(
                        icon: "checkmark.circle",
                        label: "Active Tasks",
                        value: "\(activeTasks.completed) of \(activeTasks.total)",
                        color: FrancoSphereDesign.DashboardColors.secondaryAction,
                        progress: Double(activeTasks.completed) / Double(activeTasks.total)
                    )
                }
                
                if !viewModel.workersPresent.isEmpty {
                    MetricRow(
                        icon: "person.2.fill",
                        label: "Workers Present",
                        value: viewModel.workersPresent.joined(separator: ", "),
                        color: FrancoSphereDesign.DashboardColors.primaryAction
                    )
                }
                
                if let nextCritical = viewModel.nextCriticalTask {
                    MetricRow(
                        icon: "exclamationmark.triangle.fill",
                        label: "Next Critical",
                        value: nextCritical,
                        color: FrancoSphereDesign.DashboardColors.warning
                    )
                }
                
                if let specialNote = viewModel.todaysSpecialNote {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                            .font(.caption)
                        Text(specialNote)
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FrancoSphereDesign.DashboardColors.warning.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(FrancoSphereDesign.DashboardColors.warning.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Operations Tab (Routines + Inventory)
    private var operationsContent: some View {
        VStack(spacing: 20) {
            // Daily routines
            dailyRoutinesCard
            
            // Inventory summary
            if viewModel.userRole != .client {
                inventorySummaryCard
            }
            
            // Compliance checklist
            complianceChecklistCard
        }
    }
    
    // MARK: - Spaces & Access Tab (Enhanced)
    private var spacesAccessContent: some View {
        VStack(spacing: 20) {
            // Search/Filter
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))
                    TextField("Search spaces...", text: $viewModel.spaceSearchQuery)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                )
                
                // Add space button (admin)
                if viewModel.userRole == .admin {
                    Button(action: {
                        photoCategory = .utilities
                        showingPhotoCapture = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                    }
                }
            }
            
            // Space categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(SpaceCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            title: category.displayName,
                            icon: category.icon,
                            isSelected: viewModel.selectedSpaceCategory == category,
                            action: { viewModel.selectedSpaceCategory = category }
                        )
                    }
                }
            }
            
            // Spaces grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.filteredSpaces) { space in
                    SpaceAccessCard(space: space) {
                        selectedSpace = space
                        showingSpaceDetail = true
                    }
                }
                
                // Add new space card
                Button(action: {
                    photoCategory = .utilities
                    showingPhotoCapture = true
                }) {
                    VStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                            .frame(height: 140)
                            .overlay(
                                VStack(spacing: 8) {
                                    Image(systemName: "camera.fill")
                                        .font(.title)
                                    Text("Add Space")
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.5))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundColor(.white.opacity(0.2))
                            )
                    }
                }
            }
            
            // Access codes section
            if !viewModel.accessCodes.isEmpty {
                accessCodesCard
            }
        }
    }
    
    // MARK: - Activity Tab (History + Team)
    private var activityContent: some View {
        VStack(spacing: 20) {
            // Active workers
            activeWorkersCard
            
            // Recent activity feed
            recentActivityCard
            
            // Maintenance history
            maintenanceHistoryCard
        }
    }
    
    // MARK: - Supporting Cards
    
    private var quickMetricsCard: some View {
        HStack(spacing: 16) {
            MetricCard(
                title: "Efficiency",
                value: "\(viewModel.efficiencyScore)%",
                trend: .up,
                color: FrancoSphereDesign.DashboardColors.primaryAction
            )
            
            MetricCard(
                title: "Compliance",
                value: viewModel.complianceScore,
                trend: .stable,
                color: FrancoSphereDesign.DashboardColors.secondaryAction
            )
            
            MetricCard(
                title: "Issues",
                value: "\(viewModel.openIssues)",
                trend: viewModel.openIssues > 0 ? .down : .stable,
                color: viewModel.openIssues > 0 ? FrancoSphereDesign.DashboardColors.warning : FrancoSphereDesign.DashboardColors.inactive
            )
        }
    }
    
    private var keyContactsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Contacts", systemImage: "phone.circle.fill")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(spacing: 12) {
                // Building contacts from database
                if let primaryContact = viewModel.primaryContact {
                    ContactRowView(
                        contact: primaryContact,
                        icon: "building.2",
                        onCall: { selectedContact = primaryContact; showingCallMenu = true },
                        onMessage: { selectedContact = primaryContact; showingMessageComposer = true }
                    )
                }
                
                // Franco HQ contacts
                ContactRowView(
                    contact: BuildingContact(
                        name: "24/7 Emergency",
                        role: "Franco Response",
                        email: nil,
                        phone: "(212) 555-0911",
                        isEmergencyContact: true
                    ),
                    icon: "exclamationmark.shield.fill",
                    iconColor: FrancoSphereDesign.DashboardColors.critical,
                    onCall: { callEmergency() },
                    onMessage: nil
                )
                
                // Collapsible additional contacts
                DisclosureGroup {
                    VStack(spacing: 12) {
                        ContactRowView(
                            contact: BuildingContact(
                                name: "David Rodriguez",
                                role: "Operations Manager",
                                email: "david@francosphere.com",
                                phone: "(212) 555-0123",
                                isEmergencyContact: false
                            ),
                            icon: "person.fill",
                            onCall: { callNumber("2125550123") },
                            onMessage: { messageContact("david@francosphere.com") }
                        )
                        
                        ContactRowView(
                            contact: BuildingContact(
                                name: "Jerry Martinez",
                                role: "Regional Manager",
                                email: "jerry@francosphere.com",
                                phone: "(212) 555-0124",
                                isEmergencyContact: false
                            ),
                            icon: "person.fill",
                            onCall: { callNumber("2125550124") },
                            onMessage: { messageContact("jerry@francosphere.com") }
                        )
                    }
                } label: {
                    HStack {
                        Text("More Contacts")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var accessCodesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Access Codes", systemImage: "lock.circle.fill")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(spacing: 8) {
                ForEach(viewModel.accessCodes) { code in
                    AccessCodeRow(code: code)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var dailyRoutinesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Daily Routines", systemImage: "calendar.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("\(viewModel.completedRoutines)/\(viewModel.totalRoutines)")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
            }
            
            if viewModel.dailyRoutines.isEmpty {
                Text("No routines scheduled today")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.dailyRoutines) { routine in
                    RoutineRowView(
                        routine: routine,
                        onToggle: { viewModel.toggleRoutineCompletion(routine) },
                        onAssign: {
                            selectedRoutine = routine
                            showWorkerAssignment = true
                        },
                        canAssign: viewModel.userRole == .admin
                    )
                    
                    if routine.id != viewModel.dailyRoutines.last?.id {
                        Divider()
                            .background(FrancoSphereDesign.DashboardColors.borderSubtle)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var inventorySummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Inventory Status", systemImage: "shippingbox.fill")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                NavigationLink {
                    BuildingInventoryDetailView(buildingId: buildingId)
                } label: {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                }
            }
            
            // Summary grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                InventorySummaryItem(
                    category: "Cleaning",
                    icon: "sparkles",
                    itemsLow: viewModel.inventorySummary.cleaningLow,
                    total: viewModel.inventorySummary.cleaningTotal
                )
                
                InventorySummaryItem(
                    category: "Equipment",
                    icon: "wrench.fill",
                    itemsLow: viewModel.inventorySummary.equipmentLow,
                    total: viewModel.inventorySummary.equipmentTotal
                )
                
                InventorySummaryItem(
                    category: "Maintenance",
                    icon: "hammer.fill",
                    itemsLow: viewModel.inventorySummary.maintenanceLow,
                    total: viewModel.inventorySummary.maintenanceTotal
                )
                
                InventorySummaryItem(
                    category: "Safety",
                    icon: "shield.fill",
                    itemsLow: viewModel.inventorySummary.safetyLow,
                    total: viewModel.inventorySummary.safetyTotal
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var complianceChecklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Compliance Checklist", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            VStack(spacing: 8) {
                ComplianceCheckItem(
                    title: "DSNY Requirements",
                    status: viewModel.dsnyCompliance,
                    nextAction: viewModel.nextDSNYAction
                )
                
                ComplianceCheckItem(
                    title: "Fire Safety",
                    status: viewModel.fireSafetyCompliance,
                    nextAction: viewModel.nextFireSafetyAction
                )
                
                ComplianceCheckItem(
                    title: "Health Inspections",
                    status: viewModel.healthCompliance,
                    nextAction: viewModel.nextHealthAction
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var activeWorkersCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Workers", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
            
            if viewModel.assignedWorkers.isEmpty {
                Text("No workers currently assigned")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.assignedWorkers) { worker in
                    WorkerStatusRow(worker: worker)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Recent Activity", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("Last 24h")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            if viewModel.recentActivities.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentActivities.prefix(5)) { activity in
                    ActivityRow(activity: activity)
                    
                    if activity.id != viewModel.recentActivities.prefix(5).last?.id {
                        Divider()
                            .background(FrancoSphereDesign.DashboardColors.borderSubtle)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    private var maintenanceHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Maintenance History", systemImage: "wrench.and.screwdriver.fill")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                NavigationLink {
                    BuildingMaintenanceHistoryView(buildingId: buildingId)
                } label: {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                }
            }
            
            if viewModel.maintenanceHistory.isEmpty {
                Text("No recent maintenance")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.maintenanceHistory.prefix(3)) { record in
                    MaintenanceRecordRow(record: record)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Actions Bar
    private var quickActionsBar: some View {
        HStack(spacing: 0) {
            QuickActionButton(
                icon: "camera.fill",
                title: "Photo",
                color: FrancoSphereDesign.DashboardColors.primaryAction,
                action: {
                    photoCategory = .general
                    showingPhotoCapture = true
                }
            )
            
            QuickActionButton(
                icon: "phone.fill",
                title: "Call",
                color: FrancoSphereDesign.DashboardColors.secondaryAction,
                action: { showingCallMenu = true }
            )
            
            QuickActionButton(
                icon: "map.fill",
                title: "Navigate",
                color: FrancoSphereDesign.DashboardColors.info,
                action: { openInMaps() }
            )
            
            Menu {
                Button(action: { viewModel.reportIssue() }) {
                    Label("Report Issue", systemImage: "exclamationmark.triangle")
                }
                
                Button(action: { viewModel.requestSupplies() }) {
                    Label("Request Supplies", systemImage: "shippingbox")
                }
                
                Button(action: { showingMessageComposer = true }) {
                    Label("Send Message", systemImage: "message")
                }
                
                Button(action: { viewModel.addNote() }) {
                    Label("Add Note", systemImage: "note.text.badge.plus")
                }
                
                if viewModel.userRole == .worker {
                    Button(action: { viewModel.logVendorVisit() }) {
                        Label("Log Vendor Visit", systemImage: "person.badge.plus")
                    }
                }
            } label: {
                QuickActionButton(
                    icon: "plus.circle.fill",
                    title: "More",
                    color: FrancoSphereDesign.DashboardColors.inactive,
                    action: { }
                )
            }
        }
        .frame(height: 60)
        .background(
            FrancoSphereDesign.DashboardColors.cardBackground
                .opacity(0.98)
                .overlay(
                    Rectangle()
                        .fill(FrancoSphereDesign.DashboardColors.borderSubtle)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func shouldShowTab(_ tab: BuildingDetailTab) -> Bool {
        switch tab {
        case .spacesAccess:
            return viewModel.userRole != .client // Clients can't see utility access
        default:
            return true
        }
    }
    
    private var completionColor: Color {
        let percentage = viewModel.completionPercentage
        switch percentage {
        case 90...100: return FrancoSphereDesign.DashboardColors.success
        case 70..<90: return FrancoSphereDesign.DashboardColors.warning
        case 50..<70: return Color.orange
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
    
    private func statusBadge(_ text: String, icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
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
    
    private func getMessageRecipients() -> [String] {
        var recipients: [String] = []
        
        if let contact = selectedContact, let email = contact.email {
            recipients.append(email)
        } else {
            // Default to ops team
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
    
    private func messageContact(_ email: String) {
        selectedContact = BuildingContact(
            name: email.components(separatedBy: "@").first?.capitalized ?? "Contact",
            role: nil,
            email: email,
            phone: nil,
            isEmergencyContact: false
        )
        showingMessageComposer = true
    }
    
    private func openInMaps() {
        let address = buildingAddress.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "maps://?address=\(address)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Supporting Types

enum BuildingDetailTab: String, CaseIterable {
    case overview = "Overview"
    case operations = "Operations"
    case spacesAccess = "Spaces"
    case activity = "Activity"
    
    var title: String { rawValue }
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

// MARK: - Data Models

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

struct BuildingActivity: Identifiable {
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

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .foregroundColor(.white.opacity(0.9))
                .fontWeight(.medium)
        }
        .font(.caption)
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    var progress: Double? = nil
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                    
                    Text(value)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(color)
                }
                
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .frame(height: 4)
                        .background(color.opacity(0.2))
                        .cornerRadius(2)
                }
            }
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let trend: CoreTypes.TrendDirection
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                TrendIndicator(direction: trend)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct TrendIndicator: View {
    let direction: CoreTypes.TrendDirection
    
    var body: some View {
        Image(systemName: icon)
            .font(.caption)
            .foregroundColor(color)
    }
    
    private var icon: String {
        switch direction {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "minus"
        default: return "questionmark"
        }
    }
    
    private var color: Color {
        FrancoSphereDesign.EnumColors.trendDirection(direction)
    }
}

struct ContactRowView: View {
    let contact: BuildingContact
    let icon: String
    var iconColor: Color = FrancoSphereDesign.DashboardColors.secondaryAction
    var onCall: (() -> Void)?
    var onMessage: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .overlay(
                            Circle()
                                .stroke(iconColor.opacity(0.25), lineWidth: 1)
                        )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                if let role = contact.role {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if let phone = contact.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let onCall = onCall, contact.phone != nil {
                    Button(action: onCall) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(FrancoSphereDesign.DashboardColors.primaryAction.opacity(0.15))
                                    .overlay(
                                        Circle()
                                            .stroke(FrancoSphereDesign.DashboardColors.primaryAction.opacity(0.25), lineWidth: 1)
                                    )
                            )
                    }
                }
                
                if let onMessage = onMessage, contact.email != nil {
                    Button(action: onMessage) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(FrancoSphereDesign.DashboardColors.secondaryAction.opacity(0.15))
                                    .overlay(
                                        Circle()
                                            .stroke(FrancoSphereDesign.DashboardColors.secondaryAction.opacity(0.25), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SpaceAccessCard: View {
    let space: SpaceAccess
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Photo or icon
                if let photo = space.thumbnail {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: FrancoSphereDesign.DashboardColors.workerHeroGradient.map { $0.opacity(0.5) },
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)
                        .overlay(
                            Image(systemName: space.category.icon)
                                .font(.title)
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(space.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if space.requiresKey {
                            Label("Key", systemImage: "key.fill")
                                .font(.caption2)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                        }
                        
                        if space.accessCode != nil {
                            Label("Code", systemImage: "lock.fill")
                                .font(.caption2)
                                .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                        }
                        
                        Spacer()
                        
                        Text(space.lastUpdated, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(FrancoSphereDesign.DashboardColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AccessCodeRow: View {
    let code: AccessCode
    @State private var isRevealed = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(code.location)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(code.type.capitalized)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(isRevealed ? code.code : "••••••")
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                
                Button(action: { isRevealed.toggle() }) {
                    Image(systemName: isRevealed ? "eye.slash.fill" : "eye.fill")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
            )
        }
    }
}

struct CategoryPill: View {
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
            .foregroundColor(isSelected ? .white.opacity(0.9) : .white.opacity(0.6))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? FrancoSphereDesign.DashboardColors.primaryAction : FrancoSphereDesign.DashboardColors.glassOverlay)
                    .overlay(
                        Capsule()
                            .stroke(
                                isSelected ? FrancoSphereDesign.DashboardColors.primaryAction.opacity(0.5) : FrancoSphereDesign.DashboardColors.borderSubtle,
                                lineWidth: 1
                            )
                    )
            )
        }
    }
}

struct RoutineRowView: View {
    let routine: DailyRoutine
    let onToggle: () -> Void
    let onAssign: () -> Void
    let canAssign: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: routine.isCompleted ? "checkmark.square.fill" : "square")
                    .foregroundColor(routine.isCompleted ? FrancoSphereDesign.DashboardColors.primaryAction : .white.opacity(0.5))
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .strikethrough(routine.isCompleted)
                
                HStack(spacing: 12) {
                    if let time = routine.scheduledTime {
                        Label(time, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    if let assignedWorker = routine.assignedWorker {
                        Label(assignedWorker, systemImage: "person.fill")
                            .font(.caption)
                            .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                    }
                    
                    if !routine.requiredInventory.isEmpty {
                        Label("\(routine.requiredInventory.count) items", systemImage: "shippingbox")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            Spacer()
            
            if canAssign && !routine.isCompleted && routine.assignedWorker == nil {
                Button(action: onAssign) {
                    Image(systemName: "person.badge.plus")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(FrancoSphereDesign.DashboardColors.secondaryAction.opacity(0.15))
                        )
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct InventorySummaryItem: View {
    let category: String
    let icon: String
    let itemsLow: Int
    let total: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(category)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            HStack {
                if itemsLow > 0 {
                    Text("\(itemsLow) low")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                } else {
                    Text("Stocked")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                }
                
                Spacer()
                
                Text("/ \(total)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            itemsLow > 0 ? FrancoSphereDesign.DashboardColors.warning.opacity(0.3) : FrancoSphereDesign.DashboardColors.borderSubtle,
                            lineWidth: 1
                        )
                )
        )
    }
}

struct ComplianceCheckItem: View {
    let title: String
    let status: CoreTypes.ComplianceStatus
    let nextAction: String?
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: status == .compliant ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(FrancoSphereDesign.EnumColors.complianceStatus(status))
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                
                if let action = nextAction {
                    Text(action)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct WorkerStatusRow: View {
    let worker: AssignedWorker
    
    var body: some View {
        HStack {
            Circle()
                .fill(worker.isOnSite ? FrancoSphereDesign.DashboardColors.primaryAction : FrancoSphereDesign.DashboardColors.inactive)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(worker.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                
                Text(worker.schedule)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
            
            if worker.isOnSite {
                Text("On-site")
                    .font(.caption)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(FrancoSphereDesign.DashboardColors.primaryAction.opacity(0.15))
                    )
            }
        }
        .padding(.vertical, 4)
    }
}

struct ActivityRow: View {
    let activity: BuildingActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
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
                    .foregroundColor(.white.opacity(0.9))
                
                HStack(spacing: 8) {
                    if let worker = activity.workerName {
                        Text(worker)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Text(activity.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func iconForActivity(_ type: BuildingActivity.ActivityType) -> String {
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
    
    private func colorForActivity(_ type: BuildingActivity.ActivityType) -> Color {
        switch type {
        case .taskCompleted, .routineCompleted, .workerArrived:
            return FrancoSphereDesign.DashboardColors.primaryAction
        case .photoAdded:
            return FrancoSphereDesign.DashboardColors.secondaryAction
        case .issueReported:
            return FrancoSphereDesign.DashboardColors.warning
        case .workerDeparted, .inventoryUsed:
            return FrancoSphereDesign.DashboardColors.inactive
        }
    }
}

struct MaintenanceRecordRow: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(record.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
            
            HStack {
                Text(record.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
                
                if let cost = record.cost {
                    Spacer()
                    Text("$\(cost, specifier: "%.2f")")
                        .font(.caption)
                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                }
            }
            
            if let description = record.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 8)
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(color)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Space Detail Sheet
struct SpaceDetailSheet: View {
    let space: SpaceAccess
    let buildingName: String
    let onUpdate: (SpaceAccess) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingPhotoCapture = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Photos section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Photos", systemImage: "photo.on.rectangle")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { showingPhotoCapture = true }) {
                                Label("Add Photo", systemImage: "plus.circle")
                                    .font(.caption)
                                    .foregroundColor(FrancoSphereDesign.DashboardColors.primaryAction)
                            }
                        }
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(space.photos) { photo in
                                    if let image = photo.thumbnail {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 120, height: 120)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Access information
                    if space.accessCode != nil || space.requiresKey {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Access Information", systemImage: "key.fill")
                                .font(.headline)
                            
                            if let code = space.accessCode {
                                HStack {
                                    Text("Access Code:")
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Text(code)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(FrancoSphereDesign.DashboardColors.secondaryAction)
                                }
                            }
                            
                            if space.requiresKey {
                                HStack {
                                    Text("Physical Key Required")
                                        .foregroundColor(.white.opacity(0.7))
                                    Spacer()
                                    Image(systemName: "key.fill")
                                        .foregroundColor(FrancoSphereDesign.DashboardColors.warning)
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                        )
                    }
                    
                    // Notes
                    if let notes = space.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Notes", systemImage: "note.text")
                                .font(.headline)
                            
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    // Last updated
                    HStack {
                        Text("Last updated")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        Text(space.lastUpdated, style: .relative)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding()
            }
            .background(FrancoSphereDesign.DashboardColors.baseBackground)
            .navigationTitle(space.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .sheet(isPresented: $showingPhotoCapture) {
            PhotoCaptureSheet(
                buildingId: space.id,
                buildingName: buildingName,
                category: .utilities,
                onCapture: { image, _, notes in
                    // Handle photo capture
                    dismiss()
                }
            )
        }
    }
}

// MARK: - Photo Capture Sheet (Updated for Dark Theme)
struct PhotoCaptureSheet: View {
    let buildingId: String
    let buildingName: String
    let category: FrancoPhotoCategory
    let onCapture: (UIImage, FrancoPhotoCategory, String) -> Void

    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedCategory: FrancoPhotoCategory
    @State private var notes: String = ""
    @State private var isProcessing = false
    @Environment(\.dismiss) private var dismiss
    
    init(buildingId: String, buildingName: String, category: FrancoPhotoCategory, onCapture: @escaping (UIImage, FrancoPhotoCategory, String) -> Void) {
        self.buildingId = buildingId
        self.buildingName = buildingName
        self.category = category
        self.onCapture = onCapture
        self._selectedCategory = State(initialValue: category)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Photo preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 8)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white.opacity(0.3))
                                Text("Tap to add photo")
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(FrancoSphereDesign.DashboardColors.borderSubtle, lineWidth: 1)
                        )
                        .onTapGesture {
                            showPhotoOptions()
                        }
                }
                
                // Category picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(FrancoPhotoCategory.allCases, id: \.self) { cat in
                                CategoryPill(
                                    title: cat.displayName,
                                    icon: iconForCategory(cat),
                                    isSelected: selectedCategory == cat,
                                    action: { selectedCategory = cat }
                                )
                            }
                        }
                    }
                }
                
                // Notes field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes (Optional)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    TextField("Add notes about this photo...", text: $notes, axis: .vertical)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(FrancoSphereDesign.DashboardColors.glassOverlay)
                        )
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3...6)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(FrancoSphereDesign.DashboardColors.critical)
                    
                    Spacer()
                    
                    if selectedImage == nil {
                        Button(action: showPhotoOptions) {
                            Label("Add Photo", systemImage: "camera.fill")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(FrancoSphereDesign.DashboardColors.primaryAction)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: savePhoto) {
                            if isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(FrancoSphereDesign.DashboardColors.primaryAction)
                                    .cornerRadius(12)
                            } else {
                                Label("Save Photo", systemImage: "checkmark.circle.fill")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(FrancoSphereDesign.DashboardColors.primaryAction)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(isProcessing)
                    }
                }
            }
            .padding()
            .background(FrancoSphereDesign.DashboardColors.baseBackground)
            .navigationTitle("Add Building Photo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(image: $selectedImage)
        }
    }
    
    private func showPhotoOptions() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showingCamera = true
        } else {
            showingImagePicker = true
        }
    }
    
    private func savePhoto() {
        guard let image = selectedImage else { return }
        
        isProcessing = true
        onCapture(image, selectedCategory, notes)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
    
    private func iconForCategory(_ category: FrancoPhotoCategory) -> String {
        switch category {
        case .entrance: return "door.left.hand.open"
        case .lobby: return "building"
        case .utilities: return "wrench.fill"
        case .basement: return "arrow.down.to.line"
        case .roof: return "arrow.up.to.line"
        case .mechanical: return "gear"
        case .storage: return "shippingbox.fill"
        case .general: return "photo"
        }
    }
}

// MARK: - View Model (Enhanced for Real Data)

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
    
    // Activity data
    @Published var assignedWorkers: [AssignedWorker] = []
    @Published var recentActivities: [BuildingActivity] = []
    @Published var maintenanceHistory: [MaintenanceRecord] = []
    
    // Computed properties
    var buildingIcon: String {
        if buildingName.lowercased().contains("museum") {
            return "building.columns.fill"
        } else if buildingName.lowercased().contains("park") {
            return "leaf.fill"
        } else {
            return "building.2.fill"
        }
    }
    
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
                let photos = try await photoStorageService.loadPhotosForSpace(spaceId: space.id, limit: 1)
                if let firstPhoto = photos.first, let thumbnail = firstPhoto.thumbnail {
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
                            photos: photos
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
                    BuildingActivity(
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
    
    private func mapActivityType(_ type: String) -> BuildingActivity.ActivityType {
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

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
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
            picker.dismiss(animated: true)
        }
    }
}
