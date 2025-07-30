//
//  BuildingDetailView.swift
//  FrancoSphere v6.0
//
//  🏢 COMPREHENSIVE: Tab-based building management
//  📱 ADAPTIVE: Role-based content visibility
//  🔄 REAL-TIME: Live updates via DashboardSync
//  📸 PHOTO-READY: Integrated photo management
//

import SwiftUI
import MapKit
import MessageUI

struct BuildingDetailView: View {
    // MARK: - Properties
    let building: CoreTypes.Building
    @StateObject private var viewModel: BuildingDetailViewModel
    @EnvironmentObject private var authManager: NewAuthManager
    @EnvironmentObject private var dashboardSync: DashboardSyncService
    
    // MARK: - State
    @State private var selectedTab = BuildingTab.overview
    @State private var showingPhotoCapture = false
    @State private var showingMessageComposer = false
    @State private var showingCallMenu = false
    @State private var selectedContact: ContactInfo?
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    init(building: CoreTypes.Building) {
        self.building = building
        self._viewModel = StateObject(wrappedValue: BuildingDetailViewModel(building: building))
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
            PhotoCaptureView(building: building) { photo in
                await viewModel.savePhoto(photo)
            }
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposerView(
                recipients: getMessageRecipients(),
                subject: "Re: \(building.name)",
                prefilledBody: getBuildingContext()
            )
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
            
            Text(building.name)
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
                    Image(systemName: buildingIcon)
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
                    Text(building.type.rawValue.capitalized)
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
                        
                        if let status = building.complianceStatus {
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
                ForEach(BuildingTab.allCases, id: \.self) { tab in
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
    
    private func tabButton(_ tab: BuildingTab) -> some View {
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
                InfoRow("Address", value: building.address)
                InfoRow("Type", value: building.type.rawValue.capitalized)
                InfoRow("Size", value: "\(building.size.formatted()) sq ft")
                InfoRow("Floors", value: "\(building.floors)")
                InfoRow("Units", value: "\(building.units)")
                InfoRow("Built", value: "\(building.yearBuilt)")
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
                if let primaryContact = building.primaryContact {
                    ContactRow(
                        contact: primaryContact,
                        icon: "building.2",
                        onCall: { selectedContact = primaryContact; showingCallMenu = true },
                        onMessage: { selectedContact = primaryContact; showingMessageComposer = true }
                    )
                }
                
                // Franco contacts
                ContactRow(
                    contact: ContactInfo(
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
                
                ContactRow(
                    contact: ContactInfo(
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
                
                ContactRow(
                    contact: ContactInfo(
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
            
            // Daily routines
            if viewModel.routineFilter == .all || viewModel.routineFilter == .daily {
                dailyRoutinesCard
            }
            
            // Weekly routines
            if viewModel.routineFilter == .all || viewModel.routineFilter == .weekly {
                weeklyRoutinesCard
            }
            
            // Monthly routines
            if viewModel.routineFilter == .all || viewModel.routineFilter == .monthly {
                monthlyRoutinesCard
            }
            
            // Add routine button (admin only)
            if viewModel.userRole == .admin {
                addRoutineButton
            }
        }
    }
    
    private var routineFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(RoutineFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        title: filter.rawValue,
                        isSelected: viewModel.routineFilter == filter,
                        action: { viewModel.routineFilter = filter }
                    )
                }
            }
        }
    }
    
    private var dailyRoutinesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Daily Routines", systemImage: "calendar.circle.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                if let routines = viewModel.dailyRoutines[timeOfDay], !routines.isEmpty {
                    TimeOfDaySection(
                        timeOfDay: timeOfDay,
                        routines: routines,
                        onToggle: { routine in
                            viewModel.toggleRoutineCompletion(routine)
                        }
                    )
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
                // Simplified maintenance focus
                maintenanceHistoryCard
                vendorVisitsCard
            } else {
                // Full history with analytics
                historyFilterPills
                historyAnalyticsCard
                detailedHistoryList
            }
        }
    }
    
    // MARK: - Inventory Tab
    private var inventoryContent: some View {
        VStack(spacing: 20) {
            // Inventory categories
            ForEach(InventoryCategory.allCases, id: \.self) { category in
                if let items = viewModel.inventory[category], !items.isEmpty {
                    InventoryCategoryCard(
                        category: category,
                        items: items,
                        onUpdateQuantity: { item, quantity in
                            viewModel.updateInventoryQuantity(item, quantity: quantity)
                        },
                        onReorder: { item in
                            viewModel.reorderItem(item)
                        }
                    )
                }
            }
            
            // Add item button
            if viewModel.userRole == .admin || viewModel.userRole == .worker {
                addInventoryItemButton
            }
        }
    }
    
    // MARK: - Team Tab
    private var teamContent: some View {
        VStack(spacing: 20) {
            // Assigned workers
            assignedWorkersCard
            
            // Coverage calendar
            coverageCalendarCard
            
            // Emergency contacts
            emergencyContactsCard
        }
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
    
    private func shouldShowTab(_ tab: BuildingTab) -> Bool {
        switch tab {
        case .inventory:
            return viewModel.userRole != .client
        case .history:
            return true
        default:
            return true
        }
    }
    
    private var buildingIcon: String {
        switch building.type {
        case .commercial:
            return "building.2.fill"
        case .residential:
            return "house.fill"
        case .mixed:
            return "building.fill"
        case .industrial:
            return "hammer.fill"
        case .special:
            if building.name.lowercased().contains("museum") {
                return "building.columns.fill"
            } else if building.name.lowercased().contains("park") {
                return "leaf.fill"
            }
            return "star.fill"
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
        case .unknown: return "questionmark.circle.fill"
        }
    }
    
    private func complianceColor(_ status: CoreTypes.ComplianceStatus) -> Color {
        switch status {
        case .compliant: return .green
        case .nonCompliant: return .red
        case .pending: return .orange
        case .unknown: return .gray
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
        Building: \(building.name)
        Address: \(building.address)
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
            
            if let emergencyContact = building.emergencyContact,
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
        selectedContact = ContactInfo(
            name: email.components(separatedBy: "@").first?.capitalized ?? "Contact",
            role: nil,
            email: email,
            phone: nil,
            isEmergencyContact: false
        )
        showingMessageComposer = true
    }
    
    private func openInMaps() {
        let address = building.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        guard let url = URL(string: "maps://?address=\(address)") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Supporting Types

enum BuildingTab: String, CaseIterable {
    case overview = "Overview"
    case routines = "Routines"
    case history = "History"
    case inventory = "Inventory"
    case team = "Team"
    
    var title: String { rawValue }
}

enum RoutineFilter: String, CaseIterable {
    case all = "All"
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
}

enum TimeOfDay: String, CaseIterable {
    case morning = "Morning (6 AM - 12 PM)"
    case afternoon = "Afternoon (12 PM - 5 PM)"
    case evening = "Evening (5 PM - 10 PM)"
    
    var icon: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }
}

enum InventoryCategory: String, CaseIterable {
    case cleaning = "Cleaning Supplies"
    case equipment = "Equipment & Tools"
    case building = "Building Supplies"
    
    var icon: String {
        switch self {
        case .cleaning: return "sparkles"
        case .equipment: return "wrench.fill"
        case .building: return "house.fill"
        }
    }
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

struct ContactRow: View {
    let contact: ContactInfo
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

// MARK: - View Model

@MainActor
class BuildingDetailViewModel: ObservableObject {
    let building: CoreTypes.Building
    
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
    @Published var spacePhotos: [SpacePhoto] = []
    @Published var isFavorite: Bool = false
    
    // Routines data
    @Published var routineFilter: RoutineFilter = .all
    @Published var dailyRoutines: [TimeOfDay: [BuildingRoutine]] = [:]
    @Published var weeklyRoutines: [BuildingRoutine] = []
    @Published var monthlyRoutines: [BuildingRoutine] = []
    
    // History data
    @Published var maintenanceHistory: [MaintenanceRecord] = []
    @Published var vendorVisits: [VendorVisit] = []
    
    // Inventory data
    @Published var inventory: [InventoryCategory: [InventoryItem]] = [:]
    
    // Team data
    @Published var assignedWorkers: [WorkerAssignment] = []
    @Published var coverageSchedule: [String: [String]] = [:] // Day: [Worker IDs]
    
    init(building: CoreTypes.Building) {
        self.building = building
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
        userRole = NewAuthManager.shared.currentUser?.role ?? .worker
    }
    
    private func loadOverviewData() async {
        // Simulate loading
        completionPercentage = Int.random(in: 70...100)
        workersOnSite = Int.random(in: 0...3)
        workersPresent = ["Kevin D.", "Maria S."]
        todaysTasks = (total: 12, completed: 8)
        nextCriticalTask = "Trash pickup @ 6 PM"
        
        // Load space photos
        spacePhotos = [
            SpacePhoto(id: "1", name: "Utility Room", icon: "wrench.fill", thumbnail: nil),
            SpacePhoto(id: "2", name: "Basement", icon: "arrow.down.to.line", thumbnail: nil),
            SpacePhoto(id: "3", name: "Roof Access", icon: "arrow.up.to.line", thumbnail: nil)
        ]
    }
    
    private func loadRoutines() async {
        // Load from database
        dailyRoutines = [
            .morning: [
                BuildingRoutine(id: "1", title: "Lobby cleaning & mopping", timeOfDay: .morning, frequency: .daily),
                BuildingRoutine(id: "2", title: "Elevator wipe down", timeOfDay: .morning, frequency: .daily)
            ],
            .afternoon: [
                BuildingRoutine(id: "3", title: "Common area patrol", timeOfDay: .afternoon, frequency: .daily)
            ]
        ]
    }
    
    private func loadHistory() async {
        // Load maintenance and vendor history
    }
    
    private func loadInventory() async {
        // Load inventory items
        inventory = [
            .cleaning: [
                InventoryItem(id: "1", name: "Floor Cleaner", category: .cleaning, quantity: 4, unit: "gallons", minQuantity: 2)
            ]
        ]
    }
    
    private func loadTeamData() async {
        // Load assigned workers and schedule
    }
    
    // Action methods
    func toggleRoutineCompletion(_ routine: BuildingRoutine) {
        // Update routine completion status
    }
    
    func updateInventoryQuantity(_ item: InventoryItem, quantity: Int) {
        // Update inventory
    }
    
    func reorderItem(_ item: InventoryItem) {
        // Create reorder request
    }
    
    func reportIssue() {
        // Open issue reporting
    }
    
    func requestSupplies() {
        // Open supply request
    }
    
    func addNote() {
        // Add note to building
    }
    
    func logVendorVisit() {
        // Log vendor visit
    }
    
    func savePhoto(_ photo: UIImage) async {
        // Save photo to building
    }
    
    func viewSpaceDetails(_ space: SpacePhoto) {
        // View space details
    }
    
    func exportBuildingReport() {
        // Export building report
    }
    
    func toggleFavorite() {
        isFavorite.toggle()
    }
    
    func editBuildingInfo() {
        // Edit building information (admin only)
    }
}

// MARK: - Data Models

struct SpacePhoto: Identifiable {
    let id: String
    let name: String
    let icon: String
    let thumbnail: UIImage?
}

struct BuildingRoutine: Identifiable {
    let id: String
    let title: String
    let timeOfDay: TimeOfDay
    let frequency: RoutineFilter
    var isCompleted: Bool = false
}

struct MaintenanceRecord: Identifiable {
    let id: String
    let date: Date
    let type: String
    let vendor: String?
    let description: String
    let cost: Decimal?
    let status: String
}

struct VendorVisit: Identifiable {
    let id: String
    let date: Date
    let vendor: String
    let purpose: String
    let signedBy: String
}

struct InventoryItem: Identifiable {
    let id: String
    let name: String
    let category: InventoryCategory
    var quantity: Int
    let unit: String
    let minQuantity: Int
}

struct WorkerAssignment: Identifiable {
    let id: String
    let worker: CoreTypes.WorkerProfile
    let schedule: String
    let specialties: [String]
    var isOnSite: Bool
}

// MARK: - Supporting Components

struct TimeOfDaySection: View {
    let timeOfDay: TimeOfDay
    let routines: [BuildingRoutine]
    let onToggle: (BuildingRoutine) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: timeOfDay.icon)
                    .font(.subheadline)
                Text(timeOfDay.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(.white.opacity(0.8))
            
            VStack(alignment: .leading, spacing: 6) {
                ForEach(routines) { routine in
                    HStack {
                        Button(action: { onToggle(routine) }) {
                            Image(systemName: routine.isCompleted ? "checkmark.square.fill" : "square")
                                .foregroundColor(routine.isCompleted ? .green : .white.opacity(0.5))
                        }
                        
                        Text(routine.title)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .strikethrough(routine.isCompleted)
                        
                        Spacer()
                    }
                }
            }
            .padding(.leading, 8)
        }
    }
}

// MARK: - Extensions

extension CoreTypes {
    struct ContactInfo {
        let name: String
        let role: String?
        let email: String?
        let phone: String?
        let isEmergencyContact: Bool
    }
}
