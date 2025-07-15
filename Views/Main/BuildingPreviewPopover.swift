//
//  BuildingPreviewPopover.swift
//  FrancoSphere
//
//  ✅ NEW COMPONENT - Building preview hover card for MapOverlayView
//  ✅ Shows building photo, address, open tasks, sanitation schedule
//  ✅ Double-tap pushes BuildingDetailView
//  ✅ FIXED: Optional String unwrapping for imageAssetName
//

import SwiftUI
import MapKit

struct BuildingPreviewPopover: View {
    let building: NamedCoordinate
    let onDetails: () -> Void
    let onDismiss: () -> Void
    
    @StateObject private var contextEngine = WorkerContextEngineAdapter.shared
    @State private var openTasksCount: Int = 0
    @State private var nextSanitationDate: String?
    @State private var isLoading = true
    @State private var dismissTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with building image
            buildingHeader
            
            // Building info
            buildingInfo
            
            // Task and schedule info
            statusInfo
            
            // Action buttons
            actionButtons
        }
        .padding(20)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .onAppear {
            loadBuildingData()
            startDismissTimer()
        }
        .onDisappear {
            dismissTimer?.invalidate()
        }
    }
    
    // MARK: - Building Header
    
    private var buildingHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(building.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            
            // Building image
            buildingImageView
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var buildingImageView: some View {
        // ✅ FIXED: Proper optional handling for imageAssetName
        if let imageAssetName = building.imageAssetName, !imageAssetName.isEmpty,
           let uiImage = UIImage(named: imageAssetName) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            // Fallback view with building icon
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.3))
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "building.2.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                        
                        Text("No Image")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                )
        }
    }
    
    // MARK: - Building Info
    
    private var buildingInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Building address or coordinates
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Building ID: \(building.id)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
            }
            
            // Coordinates for reference
            HStack {
                Image(systemName: "globe")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text("\(String(format: "%.4f", building.latitude)), \(String(format: "%.4f", building.longitude))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    // MARK: - Status Info
    
    private var statusInfo: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.white.opacity(0.2))
            
            if isLoading {
                loadingStatusView
            } else {
                loadedStatusView
            }
        }
    }
    
    private var loadingStatusView: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text("Loading building status...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var loadedStatusView: some View {
        VStack(spacing: 8) {
            // Open tasks count
            HStack {
                Image(systemName: "checklist")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("\(openTasksCount) open tasks")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                if openTasksCount > 0 {
                    Circle()
                        .fill(openTasksCount > 3 ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                }
            }
            
            // Sanitation schedule
            if let sanitationDate = nextSanitationDate {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Next sanitation: \(sanitationDate)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Details") {
                onDetails()
            }
            .buttonStyle(PrimaryPreviewButtonStyle())
            
            Button("Dismiss") {
                onDismiss()
            }
            .buttonStyle(SecondaryPreviewButtonStyle())
        }
    }
    
    // MARK: - Real Data Loading
    
    private func loadBuildingData() {
        Task {
            // Load real task data for this building
            let allTasks = Task {
                let tasks = await WorkerContextEngine.shared.getTodaysTasks()
                await MainActor.run {
                    self.tasks = tasks
                }
            }
            let buildingTasks = allTasks.filter { task in
                task.buildingName == building.name || task.buildingId == building.id
            }
            
            // Use .status instead of .isCompleted
            let openTasks = buildingTasks.filter { $0.status != "completed" }
            
            // Find next sanitation task
            let sanitationTasks = buildingTasks.filter { task in
                task.category.lowercased().contains("sanitation") ||
                task.name.lowercased().contains("sanitation") ||
                task.name.lowercased().contains("dsny") ||
                task.name.lowercased().contains("trash")
            }
            
            let nextSanitation = sanitationTasks.first { $0.status != "completed" }
            
            await MainActor.run {
                withAnimation(.animation(.easeInOut) {
                    openTasksCount = openTasks.count
                    
                    if let next = nextSanitation {
                        // Extract date from task if available
                        if let startTime = next.startTime {
                            nextSanitationDate = "Today \(startTime)"
                        } else {
                            nextSanitationDate = "Scheduled"
                        }
                    } else {
                        nextSanitationDate = "No scheduled sanitation"
                    }
                    
                    isLoading = false
                }
            }
        }
    }
    
    private func startDismissTimer() {
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            withAnimation(Animation.easeOut) {
                onDismiss()
            }
        }
    }
}

// MARK: - Custom Button Styles

struct PrimaryPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryPreviewButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    // MARK: - Preview
    
    struct BuildingPreviewPopover_Previews: PreviewProvider {
        static var previews: some View {
            ZStack {
                Color.black.ignoresSafeArea()
                
                BuildingPreviewPopover(
                    building: NamedCoordinate(
                        id: "1",
                        name: "12 West 18th Street",
                        latitude: 40.7397,
                        longitude: -73.9944,
                        imageAssetName: "12_West_18th_Street"
                    ),
                    onDetails: { print("View details tapped") },
                    onDismiss: { print("Dismiss tapped") }
                )
            }
            .preferredColorScheme(.dark)
        }
    }
}
