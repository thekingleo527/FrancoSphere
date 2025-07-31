////
//  BuildingDetailView.swift
//  FrancoSphere v6.0
//
//  🏢 COMPREHENSIVE: Tab-based building management
//  📱 ADAPTIVE: Role-based content visibility
//  🔄 REAL-TIME: Live updates via DashboardSync
//  📸 PHOTO-READY: Integrated photo management
//  ✅ ENHANCED: Worker assignment for routines
//

import SwiftUI
import MapKit
import MessageUI

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
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom header
                headerView
                
                // Hero image with status
                heroSection
                
                // Tab bar
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
        .sheet(isPresented: $showingPhotoCapture) {
            // Use the Franco photo capture system
            FrancoBuildingPhotoCaptureView(
                buildingId: buildingId
            ) { image, category, notes in
                await viewModel.savePhoto(image)
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
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Text(buildingName)
                .font(.headline)
                .foregroundColor(.white)
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
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Building image
            if let image = viewModel.buildingImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipped()
            } else {
                // Placeholder
                LinearGradient(
                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .overlay(
                    Image(systemName: viewModel.buildingIcon)
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.7))
                )
            }
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .center,
                endPoint: .bottom
            )
            
            // Status overlay
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.buildingType)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
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
                                color: .blue
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
            }
            .padding()
        }
        .frame(height: 200)
    }
    
    // MARK: - Tab Bar
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
        .background(Color.black.opacity(0.3))
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
                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                
                // Selection indicator
                Rectangle()
                    .fill(selectedTab == tab ? Color.blue : Color.clear)
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
            VStack(spacing: 20) {
                switch selectedTab {
                case .overview:
                    overviewContent
                case .routines:
                    routinesContent
                case .history:
                    historyContent
                case .inventory:
                    inventoryContent
                case .team:
                    teamContent
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
    }
    
    // MARK: - Overview Tab
    private var overviewContent: some View {
        VStack(spacing: 20) {
            // Building info card
            buildingInfoCard
            
            // Today's snapshot
            todaysSnapshotCard
            
            // Key contacts
            keyContactsCard
            
            // Spaces & access
            spacesAccessCard
        }
    }
    
    private var buildingInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Building Information", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow("Address", value: buildingAddress)
                InfoRow("Type", value: viewModel.buildingType)
                InfoRow("Size", value: "\(viewModel.buildingSize.formatted()) sq ft")
                InfoRow("Floors", value: "\(viewModel.floors)")
                InfoRow("Units", value: "\(viewModel.units)")
                InfoRow("Built", value: "\(viewModel.yearBuilt)")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var todaysSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Today's Snapshot", systemImage: "calendar.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                if let activeTasks = viewModel.todaysTasks {
                    HStack {
                        Text("Active Tasks:")
                        Spacer()
                        Text("\(activeTasks.completed) of \(activeTasks.total)")
                            .foregroundColor(.blue)
                    }
                }
                
                if !viewModel.workersPresent.isEmpty {
                    HStack {
                        Text("Workers Present:")
                        Spacer()
                        Text(viewModel.workersPresent.joined(separator: ", "))
                            .foregroundColor(.green)
                            .lineLimit(1)
                    }
                }
                
                if let nextCritical = viewModel.nextCriticalTask {
                    HStack {
                        Text("Next Critical:")
                        Spacer()
                        Text(nextCritical)
                            .foregroundColor(.orange)
                            .lineLimit(1)
                    }
                }
                
                if let specialNote = viewModel.todaysSpecialNote {
                    HStack(alignment: .top) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Text(specialNote)
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var keyContactsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Key Contacts", systemImage: "phone.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                // Building contacts
                if let primaryContact = viewModel.primaryContact {
                    ContactRowView(
                        contact: primaryContact,
                        icon: "building.2",
                        onCall: { selectedContact = primaryContact; showingCallMenu = true },
                        onMessage: { selectedContact = primaryContact; showingMessageComposer = true }
                    )
                }
                
                // Franco contacts
                ContactRowView(
                    contact: BuildingContact(
                        name: "JM Office",
                        role: "Franco HQ",
                        email: nil,
                        phone: "(212) 555-XXXX",
                        isEmergencyContact: true
                    ),
                    icon: "briefcase.fill",
                    onCall: { callJMOffice() },
                    onMessage: nil
                )
                
                ContactRowView(
                    contact: BuildingContact(
                        name: "David",
                        role: "Operations",
                        email: "david@francosphere.com",
                        phone: nil,
                        isEmergencyContact: false
                    ),
                    icon: "person.fill",
                    onCall: nil,
                    onMessage: { messageContact("david@francosphere.com") }
                )
                
                ContactRowView(
                    contact: BuildingContact(
                        name: "Jerry",
                        role: "Management",
                        email: "jerry@francosphere.com",
                        phone: nil,
                        isEmergencyContact: false
                    ),
                    icon: "person.fill",
                    onCall: nil,
                    onMessage: { messageContact("jerry@francosphere.com") }
                )
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var spacesAccessCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Spaces & Access", systemImage: "key.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: { showingPhotoCapture = true }) {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Photo grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(viewModel.spacePhotos, id: \.id) { space in
                    SpacePhotoThumbnail(space: space) {
                        viewModel.viewSpaceDetails(space)
                    }
                }
                
                // Add photo button
                Button(action: { showingPhotoCapture = true }) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            VStack(spacing: 4) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Add")
                                    .font(.caption)
                            }
                            .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Routines Tab
    private var routinesContent: some View {
        VStack(spacing: 20) {
            // Filter pills
            routineFilterPills
            
            // Phase 1: Core functionality
            // TODO: Phase 4 will add worker capability adaptations
            Group {
                if viewModel.isLoadingRoutines {
                    ProgressView("Loading routines...")
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    // Daily routines
                    if viewModel.routineFilter == .all || viewModel.routineFilter == .daily {
                        dailyRoutinesCard
                    }
                    
                    // Weekly routines placeholder
                    if viewModel.routineFilter == .all || viewModel.routineFilter == .weekly {
                        placeholderCard(title: "Weekly Routines", message: "Coming in Phase 2")
                    }
                    
                    // Monthly routines placeholder
                    if viewModel.routineFilter == .all || viewModel.routineFilter == .monthly {
                        placeholderCard(title: "Monthly Routines", message: "Coming in Phase 2")
                    }
                }
            }
            
            // Add routine button (admin only) - Phase 4
            if viewModel.userRole == .admin {
                addRoutineButtonPlaceholder
            }
        }
    }
    
    private var routineFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RoutineFilterType.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: viewModel.routineFilter == filter,
                        action: { viewModel.routineFilter = filter }
                    )
                }
            }
        }
    }
    
    // ENHANCED: Daily Routines Card with worker assignment
    private var dailyRoutinesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Daily Routines", systemImage: "calendar.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.dailyRoutines.isEmpty {
                Text("No daily routines configured")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.dailyRoutines) { routine in
                    VStack(alignment: .leading, spacing: 8) {
                        // Existing routine display
                        HStack {
                            Button(action: { viewModel.toggleRoutineCompletion(routine) }) {
                                Image(systemName: routine.isCompleted ? "checkmark.square.fill" : "square")
                                    .foregroundColor(routine.isCompleted ? .green : .white.opacity(0.5))
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.title)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.9))
                                    .strikethrough(routine.isCompleted)
                                
                                if let time = routine.scheduledTime {
                                    Text(time)
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            // NEW: Worker assignment button
                            if viewModel.userRole == .admin && !routine.isCompleted {
                                Button(action: {
                                    selectedRoutine = routine
                                    showWorkerAssignment = true
                                }) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        
                        // NEW: Show assigned worker
                        if let assignedWorker = routine.assignedWorker {
                            HStack {
                                Image(systemName: "person.fill")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text(assignedWorker)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 24)
                        }
                        
                        // NEW: Show required inventory
                        if !routine.requiredInventory.isEmpty {
                            HStack {
                                Image(systemName: "shippingbox")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("\(routine.requiredInventory.count) items")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .padding(.leading, 24)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if routine.id != viewModel.dailyRoutines.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - History Tab
    private var historyContent: some View {
        VStack(spacing: 20) {
            if viewModel.userRole == .worker {
                // Phase 1: Basic maintenance log
                basicMaintenanceLog
            } else {
                // Phase 2: Full history with analytics
                placeholderCard(
                    title: "Complete History",
                    message: "Advanced analytics coming in Phase 2"
                )
            }
        }
    }
    
    private var basicMaintenanceLog: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Maintenance", systemImage: "wrench.and.screwdriver.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.maintenanceHistory.isEmpty {
                Text("No recent maintenance records")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.maintenanceHistory.prefix(5)) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text(record.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        
                        if let description = record.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if record.id != viewModel.maintenanceHistory.prefix(5).last?.id {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Inventory Tab
    private var inventoryContent: some View {
        VStack(spacing: 20) {
            // Phase 3: Basic inventory view
            if viewModel.userRole == .worker || viewModel.userRole == .admin {
                ForEach(CoreTypes.InventoryCategory.allCases, id: \.self) { category in
                    if let items = viewModel.inventory[category], !items.isEmpty {
                        inventoryCategorySection(category: category, items: items)
                    }
                }
                
                if viewModel.inventory.isEmpty {
                    placeholderCard(
                        title: "Inventory Management",
                        message: "Full inventory tracking coming in Phase 3"
                    )
                }
            }
        }
    }
    
    private func inventoryCategorySection(category: CoreTypes.InventoryCategory, items: [CoreTypes.InventoryItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(category.rawValue, systemImage: getCategoryIcon(category))
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(items) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.subheadline)
                            .foregroundColor(.white)
                        
                        Text("\(item.currentStock) \(item.unit)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // Stock level indicator
                    stockLevelIndicator(item: item)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Team Tab
    private var teamContent: some View {
        VStack(spacing: 20) {
            // Phase 1: Basic worker list
            assignedWorkersSection
            
            // Phase 2: Coverage calendar placeholder
            placeholderCard(
                title: "Coverage Calendar",
                message: "Schedule visualization coming in Phase 2"
            )
            
            // Emergency contacts
            emergencyContactsSection
        }
    }
    
    private var assignedWorkersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Assigned Workers", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            if viewModel.assignedWorkers.isEmpty {
                Text("No workers assigned")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.assignedWorkers) { worker in
                    HStack {
                        Circle()
                            .fill(worker.isOnSite ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(worker.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            
                            Text(worker.schedule)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        if worker.isOnSite {
                            Text("On-site")
                                .font(.caption)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var emergencyContactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Emergency Contacts", systemImage: "phone.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 8) {
                BuildingEmergencyRow(title: "Franco 24/7 Hotline", number: "(212) 555-XXXX")
                BuildingEmergencyRow(title: "Building Security", number: "(212) 555-XXXX")
                BuildingEmergencyRow(title: "Facilities Manager", number: "(212) 555-XXXX")
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    // MARK: - Quick Actions Bar
    private var quickActionsBar: some View {
        HStack(spacing: 0) {
            QuickActionButton(
                icon: "phone.fill",
                title: "Call",
                action: { showingCallMenu = true }
            )
            
            QuickActionButton(
                icon: "message.fill",
                title: "Message",
                action: { showingMessageComposer = true }
            )
            
            QuickActionButton(
                icon: "camera.fill",
                title: "Photo",
                action: { showingPhotoCapture = true }
            )
            
            QuickActionButton(
                icon: "map.fill",
                title: "Navigate",
                action: { openInMaps() }
            )
            
            Menu {
                Button(action: { viewModel.reportIssue() }) {
                    Label("Report Issue", systemImage: "exclamationmark.triangle")
                }
                
                Button(action: { viewModel.requestSupplies() }) {
                    Label("Request Supplies", systemImage: "shippingbox")
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
                    action: { }
                )
            }
        }
        .frame(height: 60)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Methods
    
    private func shouldShowTab(_ tab: BuildingDetailTab) -> Bool {
        switch tab {
        case .inventory:
            return viewModel.userRole != .client
        case .history:
            return true
        default:
            return true
        }
    }
    
    private var completionColor: Color {
        let percentage = viewModel.completionPercentage
        switch percentage {
        case 90...100: return .green
        case 70..<90: return .yellow
        case 50..<70: return .orange
        default: return .red
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
        switch status {
        case .compliant: return .green
        case .nonCompliant: return .red
        case .pending: return .orange
        default: return .gray
        }
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
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
    
    private func getMessageRecipients() -> [String] {
        var recipients: [String] = []
        
        if let contact = selectedContact, let email = contact.email {
            recipients.append(email)
        } else {
            // Default to David and Jerry
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
            
            Button(action: { callJMOffice() }) {
                Text("Call JM Office")
            }
            
            if let emergencyContact = viewModel.emergencyContact,
               let phone = emergencyContact.phone {
                Button(action: { callNumber(phone) }) {
                    Text("Call Emergency Contact")
                }
            }
            
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func callNumber(_ number: String) {
        guard let url = URL(string: "tel://\(number)") else { return }
        UIApplication.shared.open(url)
    }
    
    private func callJMOffice() {
        callNumber("2125551234") // Replace with actual number
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
    
    private func getCategoryIcon(_ category: CoreTypes.InventoryCategory) -> String {
        switch category {
        case .cleaning: return "sparkles"
        case .equipment: return "wrench.fill"
        case .maintenance: return "house.fill"
        default: return "shippingbox.fill"
        }
    }
    
    private func stockLevelIndicator(item: CoreTypes.InventoryItem) -> some View {
        let needsRestock = item.currentStock <= item.minimumStock
        
        return HStack(spacing: 4) {
            if needsRestock {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Low")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
                Text("OK")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
    }
    
    private func placeholderCard(title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.badge.checkmark")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.3))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
    
    private var addRoutineButtonPlaceholder: some View {
        Button(action: {
            // Phase 4: Implement add routine functionality
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Custom Routine")
            }
            .font(.subheadline)
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
        .disabled(true)
        .opacity(0.6)
    }
}

// MARK: - Supporting Types

enum BuildingDetailTab: String, CaseIterable {
    case overview = "Overview"
    case routines = "Routines"
    case history = "History"
    case inventory = "Inventory"
    case team = "Team"
    
    var title: String { rawValue }
}

enum RoutineFilterType: String, CaseIterable {
    case all = "All"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

// MARK: - Data Models

struct BuildingContact: Identifiable {
    let id = UUID()
    let name: String
    let role: String?
    let email: String?
    let phone: String?
    let isEmergencyContact: Bool
}

struct SpacePhoto: Identifiable {
    let id: String
    let name: String
    let icon: String
    let thumbnail: UIImage?
}

// ENHANCED: DailyRoutine with worker assignment and inventory
struct DailyRoutine: Identifiable {
    let id: String
    let title: String
    let scheduledTime: String?
    var isCompleted: Bool = false
    var assignedWorker: String? = nil  // Worker name
    var requiredInventory: [String] = [] // Inventory item names
}

struct MaintenanceRecord: Identifiable {
    let id: String
    let title: String
    let date: Date
    let description: String?
    let cost: Decimal?
}

struct AssignedWorker: Identifiable {
    let id: String
    let name: String
    let schedule: String
    let isOnSite: Bool
}

// MARK: - Supporting Views

struct InfoRow: View {
    let label: String
    let value: String
    
    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(label + ":")
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

struct ContactRowView: View {
    let contact: BuildingContact
    let icon: String
    var onCall: (() -> Void)?
    var onMessage: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contact.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let role = contact.role {
                    Text(role)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if let phone = contact.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                if let email = contact.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                if let onCall = onCall, contact.phone != nil {
                    Button(action: onCall) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)
                            .frame(width: 32, height: 32)
                            .background(Color.green.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                
                if let onMessage = onMessage, contact.email != nil {
                    Button(action: onMessage) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct SpacePhotoThumbnail: View {
    let space: SpacePhoto
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if let image = space.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 80)
                        .overlay(
                            Image(systemName: space.icon)
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
                
                Text(space.name)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
            }
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.white.opacity(0.1))
                )
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
    }
}

// Renamed to avoid conflict with EmergencyContactsSheet
struct BuildingEmergencyRow: View {
    let title: String
    let number: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text(number)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// NEW: Worker Assignment Sheet
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

// MARK: - View Model

@MainActor
class BuildingDetailVM: ObservableObject {
    let buildingId: String
    let buildingName: String
    let buildingAddress: String
    
    // User context
    @Published var userRole: CoreTypes.UserRole = CoreTypes.UserRole.worker
    
    // Overview data
    @Published var buildingImage: UIImage?
    @Published var completionPercentage: Int = 0
    @Published var workersOnSite: Int = 0
    @Published var workersPresent: [String] = []
    @Published var todaysTasks: (total: Int, completed: Int)?
    @Published var nextCriticalTask: String?
    @Published var todaysSpecialNote: String?
    @Published var spacePhotos: [SpacePhoto] = []
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
    
    // Routines data
    @Published var routineFilter: RoutineFilterType = .all
    @Published var dailyRoutines: [DailyRoutine] = []
    @Published var isLoadingRoutines: Bool = false
    
    // History data
    @Published var maintenanceHistory: [MaintenanceRecord] = []
    
    // Inventory data
    @Published var inventory: [CoreTypes.InventoryCategory: [CoreTypes.InventoryItem]] = [:]
    
    // Team data
    @Published var assignedWorkers: [AssignedWorker] = []
    
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
        // Load all data for the building
        await loadOverviewData()
        await loadRoutines()
        await loadHistory()
        await loadInventory()
        await loadTeamData()
    }
    
    private func loadUserRole() {
        // Get from auth manager
        if let roleString = NewAuthManager.shared.currentUser?.role,
           let role = CoreTypes.UserRole(rawValue: roleString) {
            userRole = role
        } else {
            userRole = .worker // Default to worker role
        }
    }
    
    private func loadOverviewData() async {
        // Phase 1: Mock data based on real buildings
        // For Rubin Museum
        if buildingId == "14" {
            completionPercentage = 87
            workersOnSite = 2
            workersPresent = ["Kevin D.", "Edwin L."]
            todaysTasks = (total: 38, completed: 33)
            nextCriticalTask = "DSNY Trash set-out @ 8 PM"
            complianceStatus = .compliant
            
            buildingSize = 70000
            floors = 7
            units = 1
            yearBuilt = 1998
            todaysSpecialNote = "Gallery event tonight - extra cleaning required"
        } else {
            // Default data
            completionPercentage = Int.random(in: 70...100)
            workersOnSite = Int.random(in: 0...3)
            workersPresent = ["Kevin D."]
            todaysTasks = (total: 12, completed: 8)
            nextCriticalTask = "Trash pickup @ 6 PM"
            complianceStatus = .compliant
            
            buildingSize = 45000
            floors = 6
            units = 12
            yearBuilt = 1920
        }
        
        // Load space photos
        spacePhotos = [
            SpacePhoto(id: "1", name: "Utility Room", icon: "wrench.fill", thumbnail: nil),
            SpacePhoto(id: "2", name: "Basement", icon: "arrow.down.to.line", thumbnail: nil),
            SpacePhoto(id: "3", name: "Roof Access", icon: "arrow.up.to.line", thumbnail: nil)
        ]
    }
    
    private func loadRoutines() async {
        isLoadingRoutines = true
        
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Real routines based on building
        if buildingId == "14" { // Rubin Museum
            dailyRoutines = [
                DailyRoutine(
                    id: "1",
                    title: "Gallery floors dust mop & spot clean",
                    scheduledTime: "6:00 AM",
                    assignedWorker: "Kevin D.",
                    requiredInventory: ["Dust mop", "Microfiber cloths"]
                ),
                DailyRoutine(
                    id: "2",
                    title: "Public restroom deep clean",
                    scheduledTime: "7:00 AM",
                    assignedWorker: nil,
                    requiredInventory: ["Disinfectant", "Paper towels", "Toilet cleaner"]
                ),
                DailyRoutine(
                    id: "3",
                    title: "Loading dock sweep & mop",
                    scheduledTime: "9:00 AM",
                    isCompleted: true,
                    assignedWorker: "Kevin D.",
                    requiredInventory: ["Broom", "Mop", "Degreaser"]
                ),
                DailyRoutine(
                    id: "4",
                    title: "Exhibition space patrol & touch-up",
                    scheduledTime: "2:00 PM",
                    requiredInventory: ["Glass cleaner", "Microfiber cloths"]
                ),
                DailyRoutine(
                    id: "5",
                    title: "DSNY compliant trash staging",
                    scheduledTime: "8:00 PM",
                    assignedWorker: "Edwin L.",
                    requiredInventory: ["Trash bags", "Recycling bins"]
                )
            ]
        } else {
            // Default routines
            dailyRoutines = [
                DailyRoutine(id: "1", title: "Lobby cleaning & mopping", scheduledTime: "6:00 AM"),
                DailyRoutine(id: "2", title: "Elevator wipe down", scheduledTime: "7:00 AM"),
                DailyRoutine(id: "3", title: "Common area patrol", scheduledTime: "2:00 PM"),
                DailyRoutine(id: "4", title: "Trash collection", scheduledTime: "5:00 PM")
            ]
        }
        
        isLoadingRoutines = false
    }
    
    private func loadHistory() async {
        // Phase 1: Basic maintenance records
        maintenanceHistory = [
            MaintenanceRecord(
                id: "1",
                title: "Elevator B Service",
                date: Date().addingTimeInterval(-86400),
                description: "Annual inspection completed",
                cost: nil
            ),
            MaintenanceRecord(
                id: "2",
                title: "HVAC Filter Replacement",
                date: Date().addingTimeInterval(-604800),
                description: "Replaced all filters on floors 1-3",
                cost: 450
            )
        ]
    }
    
    private func loadInventory() async {
        // Real inventory based on building needs
        inventory = [
            .cleaning: [
                CoreTypes.InventoryItem(
                    id: "1",
                    name: "Floor Cleaner",
                    category: .cleaning,
                    currentStock: 4,
                    minimumStock: 2,
                    maxStock: 10,
                    unit: "gallons",
                    cost: 25.99
                ),
                CoreTypes.InventoryItem(
                    id: "2",
                    name: "Glass Cleaner",
                    category: .cleaning,
                    currentStock: 8,
                    minimumStock: 4,
                    maxStock: 12,
                    unit: "bottles",
                    cost: 4.99
                )
            ],
            .equipment: [
                CoreTypes.InventoryItem(
                    id: "3",
                    name: "Mop Heads",
                    category: .equipment,
                    currentStock: 3,
                    minimumStock: 4,
                    maxStock: 10,
                    unit: "units",
                    cost: 12.99
                )
            ]
        ]
    }
    
    private func loadTeamData() async {
        // Real worker assignments
        if buildingId == "14" { // Rubin Museum
            assignedWorkers = [
                AssignedWorker(
                    id: "4",
                    name: "Kevin Dutan",
                    schedule: "M-F 6 AM - 2 PM",
                    isOnSite: true
                ),
                AssignedWorker(
                    id: "2",
                    name: "Edwin Lema",
                    schedule: "M-F 2 PM - 10 PM",
                    isOnSite: Calendar.current.component(.hour, from: Date()) >= 14
                )
            ]
        } else {
            assignedWorkers = [
                AssignedWorker(
                    id: "4",
                    name: "Kevin Dutan",
                    schedule: "M-F 6 AM - 2 PM",
                    isOnSite: true
                )
            ]
        }
    }
    
    // Action methods
    func toggleRoutineCompletion(_ routine: DailyRoutine) {
        // Update routine completion status
        if let index = dailyRoutines.firstIndex(where: { $0.id == routine.id }) {
            dailyRoutines[index].isCompleted.toggle()
            
            // Update completion percentage
            let completed = dailyRoutines.filter { $0.isCompleted }.count
            let total = dailyRoutines.count
            completionPercentage = total > 0 ? Int((Double(completed) / Double(total)) * 100) : 0
            
            // Broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: CoreTypes.DashboardUpdate.Source.worker,
                type: CoreTypes.DashboardUpdate.UpdateType.taskCompleted,
                buildingId: buildingId,
                workerId: NewAuthManager.shared.workerId ?? "",
                data: [
                    "routineId": routine.id,
                    "routineTitle": routine.title,
                    "isCompleted": String(dailyRoutines[index].isCompleted)
                ]
            )
            DashboardSyncService.shared.broadcastWorkerUpdate(update)
        }
    }
    
    // NEW: Assign worker to routine
    func assignWorkerToRoutine(_ routine: DailyRoutine, workerId: String) {
        if let index = dailyRoutines.firstIndex(where: { $0.id == routine.id }) {
            // Find worker name
            let workerName = assignedWorkers.first(where: { $0.id == workerId })?.name ?? "Unknown"
            dailyRoutines[index].assignedWorker = workerName
            
            // Broadcast update
            let update = CoreTypes.DashboardUpdate(
                source: CoreTypes.DashboardUpdate.Source.admin,
                type: CoreTypes.DashboardUpdate.UpdateType.taskUpdated,
                buildingId: buildingId,
                workerId: workerId,
                data: [
                    "routineId": routine.id,
                    "routineTitle": routine.title,
                    "assignedWorker": workerName,
                    "action": "workerAssigned"
                ]
            )
            DashboardSyncService.shared.broadcastAdminUpdate(update)
        }
    }
    
    func reportIssue() {
        // Phase 2: Open issue reporting
    }
    
    func requestSupplies() {
        // Phase 3: Open supply request
    }
    
    func addNote() {
        // Phase 2: Add note to building
    }
    
    func logVendorVisit() {
        // Phase 2: Log vendor visit
    }
    
    func savePhoto(_ photo: UIImage) async {
        // Phase 3: Save photo to building
        // Use FrancoPhotoStorageService to save
        let metadata = FrancoBuildingPhotoMetadata(
            buildingId: buildingId,
            category: .utilities,
            notes: nil,
            location: nil,
            taskId: nil,
            workerId: NewAuthManager.shared.workerId,
            timestamp: Date()
        )
        
        do {
            _ = try await FrancoPhotoStorageService.shared.savePhoto(photo, metadata: metadata)
            print("✅ Photo saved to building gallery")
        } catch {
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    func viewSpaceDetails(_ space: SpacePhoto) {
        // Phase 3: View space details
    }
    
    func exportBuildingReport() {
        // Phase 2: Export building report
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    func editBuildingInfo() {
        // Phase 4: Edit building information (admin only)
    }
}

// MARK: - Placeholder Views for Missing Components

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
