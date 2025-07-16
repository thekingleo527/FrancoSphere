//
//  WorkerDashboardView.swift
//  FrancoSphere v6.0 - PORTFOLIO ACCESS UI
//
//  ✅ ADDED: Portfolio access UI with building selection modes
//  ✅ ADDED: Enhanced building selection sheet
//  ✅ FIXED: Clock-in shows all buildings, "My Sites" shows assigned
//

import SwiftUI

struct WorkerDashboardView: View {
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
                            showClockPill: false, // Will be updated based on clock-in status
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
                    }
                    .padding()
                }
            }
        }
        .task {
            await loadWorkerSpecificData()
            await runDatabaseSanityCheck()
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
                }
            )
        }
        .sheet(isPresented: $showBuildingDetail) {
            if let building = selectedBuilding {
                BuildingDetailView(
                    buildingId: building.id,
                    isAssigned: selectedBuildingIsAssigned
                )
            }
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
                    Image(systemName: "clock.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start Your Shift")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Choose any building in the portfolio")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
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
                        MyBuildingCard(
                            building: building,
                            isPrimary: building.id == contextAdapter.getPrimaryBuilding()?.id,
                            onTap: {
                                selectedBuilding = building
                                selectedBuildingIsAssigned = true
                                showBuildingDetail = true
                            }
                        )
                    }
                    
                    if contextAdapter.assignedBuildings.count > 3 {
                        Button("View All My Buildings") {
                            buildingSelectionMode = .myBuildings
                            showBuildingSelection = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
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
                        TaskCard(task: task)
                    }
                    
                    if contextAdapter.todaysTasks.count > 3 {
                        Button("View All Tasks") {
                            // Navigate to full task list
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Progress")
                .font(.headline)
                .foregroundColor(.white)
            
            if let progress = contextAdapter.taskProgress {
                ProgressCard(progress: progress)
            } else {
                Text("No progress data")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func handleClockInTap() {
        buildingSelectionMode = .clockIn
        showBuildingSelection = true
    }
    
    private func handleProfileTap() {
        // Show profile or settings
    }
    
    private func handleBuildingSelection(_ building: NamedCoordinate) {
        switch buildingSelectionMode {
        case .clockIn:
            Task {
                await viewModel.clockIn(at: building)
                showBuildingSelection = false
            }
        case .myBuildings, .coverage:
            selectedBuilding = building
            selectedBuildingIsAssigned = contextAdapter.isBuildingAssigned(building.id)
            showBuildingDetail = true
            showBuildingSelection = false
        }
    }
    
    private func loadWorkerSpecificData() async {
        await viewModel.loadInitialData()
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
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
                
                if mode == .clockIn && !showingCoverageBuildings {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Coverage") {
                            showingCoverageBuildings = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
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
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var buildingList: some View {
        List(buildingsToShow, id: \.id) { building in
            BuildingSelectionRow(
                building: building,
                isAssigned: assignedBuildings.contains { $0.id == building.id },
                onTap: { onSelect(building) }
            )
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
    }
    
    private var buildingsToShow: [NamedCoordinate] {
        switch mode {
        case .clockIn:
            return showingCoverageBuildings ? portfolioBuildings : assignedBuildings
        case .myBuildings:
            return assignedBuildings
        case .coverage:
            return portfolioBuildings
        }
    }
    
    private var navigationTitle: String {
        switch mode {
        case .clockIn: return "Clock In"
        case .myBuildings: return "My Buildings"
        case .coverage: return "Coverage"
        }
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
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MyBuildingCard: View {
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
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TaskCard: View {
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
                }
            }
            
            Spacer()
            
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct ProgressCard: View {
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
            }
            
            ProgressView(value: progress.completionRate)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            HStack {
                Text("\(Int(progress.completionRate * 100))% Complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Debug Sanity Check (added to file)
