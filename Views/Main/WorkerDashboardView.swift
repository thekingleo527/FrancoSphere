//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0 - ALL COMPILATION ERRORS FIXED
//
//  ✅ FIXED: BuildingDetailView parameter (building: NamedCoordinate)
//  ✅ FIXED: Use existing WorkerConstants.getWorkerName(id:)
//  ✅ FIXED: Removed redeclared WorkerConstants struct
//  ✅ FIXED: Proper TaskProgress property usage
//  ✅ ADDED: Portfolio access UI with building selection modes
//

import SwiftUI

struct WorkerDashboardView: View {
    @State private var showNovaAssistant = false  // Nova integration
    @StateObject private var viewModel = WorkerDashboardViewModel()
    @StateObject private var contextAdapter = WorkerContextEngineAdapter.shared
    @State private var showBuildingSelection = false
    @State private var buildingSelectionMode: BuildingSelectionMode = .clockIn
    @State private var selectedBuilding: NamedCoordinate?
    @State private var selectedBuildingIsAssigned = false
    @State private var showBuildingDetail = false
    
    enum BuildingSelectionMode {
        case clockIn        // Show all buildings for coverage
        case myBuildings    // Show only assigned buildings
        case coverage       // Show all buildings for coverage access
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Dynamic header
                        HeaderV3B(
                            workerName: contextAdapter.currentWorker?.name ?? "Worker",
                            nextTaskName: contextAdapter.getNextScheduledTask()?.title,
                            showClockPill: viewModel.isClockedIn,
                            isNovaProcessing: false,
                            onProfileTap: { handleProfileTap() },
                            onNovaPress: { /* Nova not shown for workers */ },
                            onNovaLongPress: { /* Nova not shown for workers */ }
                        )
                        
                        // Clock-in section
                        clockInSection
                        
                        // My assigned buildings
                        myBuildingsSection
                        
                        // Today's tasks
                        todaysTasksSection
                        
                        // Progress section
                        progressSection
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
                    .padding()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .task {
            await loadWorkerSpecificData()
            await runDatabaseSanityCheck()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showBuildingSelection) {
            BuildingSelectionSheet(
                mode: buildingSelectionMode,
                assignedBuildings: contextAdapter.assignedBuildings,
                portfolioBuildings: contextAdapter.portfolioBuildings,
                onSelect: { building in
                    handleBuildingSelection(building)
                },
                onCancel: {
                    showBuildingSelection = false
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
            )
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                // FIXED: Use correct parameter name and type
                BuildingDetailView(building: building)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    // MARK: - UI Sections
    
    private var clockInSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Clock In")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: handleClockInTap) {
                HStack {
                    Image(systemName: viewModel.isClockedIn ? "clock.badge.checkmark.fill" : "clock.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(viewModel.isClockedIn ? .green : .blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.isClockedIn ? "Clocked In" : "Start Your Shift")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(viewModel.isClockedIn ?
                             (viewModel.currentBuilding?.name ?? "Unknown Location") :
                             "Choose any building in the portfolio")
                            .font(.caption)
                            .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var myBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Assignments")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(contextAdapter.assignedBuildings.count) buildings")
                    .font(.caption)
                    .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
            if contextAdapter.assignedBuildings.isEmpty {
                Text("No buildings assigned")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(contextAdapter.assignedBuildings.prefix(3), id: \.id) { building in
                        WorkerBuildingCard(
                            building: building,
                            isPrimary: building.id == contextAdapter.getPrimaryBuilding()?.id,
                            onTap: {
                                selectedBuilding = building
                                selectedBuildingIsAssigned = true
                                showBuildingDetail = true
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                            }
                        )
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
                    
                    if contextAdapter.assignedBuildings.count > 3 {
                        Button("View All My Buildings") {
                            buildingSelectionMode = .myBuildings
                            showBuildingSelection = true
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var todaysTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Tasks")
                .font(.headline)
                .foregroundColor(.white)
            
            if contextAdapter.todaysTasks.isEmpty {
                Text("No tasks scheduled")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(contextAdapter.todaysTasks.prefix(3), id: \.id) { task in
                        WorkerTaskCard(task: task)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
                    
                    if contextAdapter.todaysTasks.count > 3 {
                        Button("View All Tasks") {
                            // Navigate to full task list
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            if let progress = viewModel.taskProgress {
                WorkerProgressCard(progress: progress)
            } else {
                Text("No progress data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockInTap() {
        if viewModel.isClockedIn {
            Task {
                await viewModel.clockOut()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        } else {
            buildingSelectionMode = .clockIn
            showBuildingSelection = true
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private func handleProfileTap() {
        // Show profile or settings
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private func handleBuildingSelection(_ building: NamedCoordinate) {
        switch buildingSelectionMode {
        case .clockIn:
            Task {
                await viewModel.clockIn(at: building)
                showBuildingSelection = false
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        case .myBuildings, .coverage:
            selectedBuilding = building
            selectedBuildingIsAssigned = contextAdapter.isBuildingAssigned(building.id)
            showBuildingDetail = true
            showBuildingSelection = false
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private func loadWorkerSpecificData() async {
        await viewModel.loadInitialData()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    // MARK: - Debug Sanity Check
    
    private func runDatabaseSanityCheck() async {
        #if DEBUG
        print("🔍 Running database sanity check...")
        
        do {
            // Check worker assignments
            let rows = try await GRDBManager.shared.query("""
                SELECT wa.worker_id, wa.building_id, b.name as building_name, w.name as worker_name
                FROM worker_building_assignments wa
                JOIN buildings b ON wa.building_id = b.id
                JOIN workers w ON wa.worker_id = w.id
                WHERE wa.is_active = 1
                ORDER BY wa.worker_id, wa.is_primary DESC
                LIMIT 20
            """)
            
            print("✅ Database sanity check: \(rows.count) active assignments")
            
            var workerCounts: [String: Int] = [:]
            for row in rows {
                let workerId = row["worker_id"] as? String ?? "nil"
                let buildingName = row["building_name"] as? String ?? "nil"
                let workerName = row["worker_name"] as? String ?? "nil"
                
                workerCounts[workerId, default: 0] += 1
                
                if workerId == "4" { // Kevin's assignments
                    print("   Kevin → \(buildingName)")
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
            print("📊 Worker assignment counts:")
            for (workerId, count) in workerCounts {
                // FIXED: Use existing WorkerConstants.getWorkerName(id:)
                let workerName = WorkerConstants.getWorkerName(id: workerId)
                print("   \(workerName): \(count) buildings")
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
            // Check if Kevin has Rubin Museum
            let kevinRubin = rows.first { row in
                let workerId = row["worker_id"] as? String
                let buildingName = row["building_name"] as? String
                return workerId == "4" && buildingName?.contains("Rubin") == true
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
            if kevinRubin != nil {
                print("✅ Kevin correctly assigned to Rubin Museum")
            } else {
                print("❌ Kevin NOT assigned to Rubin Museum!")
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
        } catch {
            print("❌ Database sanity check failed: \(error)")
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        #endif
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
}

// MARK: - Building Selection Sheet

struct BuildingSelectionSheet: View {
    let mode: WorkerDashboardView.BuildingSelectionMode
    let assignedBuildings: [NamedCoordinate]
    let portfolioBuildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    let onCancel: () -> Void
    
    @State private var showingCoverageBuildings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                modeHeader
                
                // Building list
                buildingList
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
                
                if mode == .clockIn && !showingCoverageBuildings {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Coverage") {
                            showingCoverageBuildings = true
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var modeHeader: some View {
        VStack(spacing: 8) {
            switch mode {
            case .clockIn:
                if !showingCoverageBuildings {
                    Text("My Assigned Buildings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Tap 'Coverage' to see all portfolio buildings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("All Portfolio Buildings")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Clock in anywhere for coverage support")
                        .font(.caption)
                        .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
                
            case .myBuildings:
                Text("My Assigned Buildings")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(assignedBuildings.count) buildings in your regular assignments")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
            case .coverage:
                Text("Portfolio Coverage")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("All buildings available for coverage support")
                    .font(.caption)
                    .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .padding()
        .background(.ultraThinMaterial)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var buildingList: some View {
        List(buildingsToShow, id: \.id) { building in
            BuildingSelectionRow(
                building: building,
                isAssigned: assignedBuildings.contains { $0.id == building.id },
                onTap: { onSelect(building) }
            )
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var buildingsToShow: [NamedCoordinate] {
        switch mode {
        case .clockIn:
            return showingCoverageBuildings ? portfolioBuildings : assignedBuildings
        case .myBuildings:
            return assignedBuildings
        case .coverage:
            return portfolioBuildings
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
    
    private var navigationTitle: String {
        switch mode {
        case .clockIn: return "Clock In"
        case .myBuildings: return "My Buildings"
        case .coverage: return "Coverage"
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
}

// MARK: - Supporting Views

struct BuildingSelectionRow: View {
    let building: NamedCoordinate
    let isAssigned: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(isAssigned ? .blue : .gray)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        if isAssigned {
                            Label("Assigned", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("Coverage", systemImage: "circle.dashed")
                                .font(.caption)
                                .foregroundColor(.orange)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                        }
                        
                        Spacer()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            .padding(.vertical, 8)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
}

struct WorkerBuildingCard: View {
    let building: NamedCoordinate
    let isPrimary: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "building.2.fill")
                    .font(.title2)
                    .foregroundColor(isPrimary ? .yellow : .blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if isPrimary {
                        Text("PRIMARY BUILDING")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    } else {
                        Text("Assigned Building")
                            .font(.caption)
                            .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
}

struct WorkerTaskCard: View {
    let task: ContextualTask
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(task.isCompleted ? Color.green : Color.orange)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Unknown Task")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let buildingName = task.buildingName {
                    Text(buildingName)
                        .font(.caption)
                        .foregroundColor(.secondary)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
                }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
            Spacer()
            
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
}

struct WorkerProgressCard: View {
    let progress: TaskProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Task Progress")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(progress.completedTasks)/\(progress.totalTasks)")
                    .font(.headline)
                    .foregroundColor(.white)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
            
            // FIXED: Use progressPercentage and normalize it
            ProgressView(value: progress.progressPercentage / 100.0)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            HStack {
                Text("\(Int(progress.progressPercentage))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
            }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
    }
        .sheet(isPresented: $showNovaAssistant) {
            NovaInteractionView()
        }
}
