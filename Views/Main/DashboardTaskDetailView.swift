//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
//  ✅ PRESERVED: Original UI design and all functional elements.
//  ✅ FIXED: Uses a new ViewModel for clean data management and state handling.
//

import SwiftUI

// MARK: - View Model
@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var buildingName: String = "Loading..."
    private let buildingService = BuildingService.shared

    func loadBuildingName(for buildingId: CoreTypes.BuildingID) async {
        // Use the new service to get the building name
        self.buildingName = await buildingService.name(forId: buildingId)
    }
}

// MARK: - Main View
struct DashboardTaskDetailView: View {
    let task: ContextualTask
    
    @StateObject private var viewModel = TaskDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - State Properties
    @State private var showingCompletionSheet = false
    @State private var completionNotes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                taskDetailsSection
                buildingInfoSection
                statusSection
                actionButtonsSection
                
                if let image = selectedImage {
                    completionPhotoSection(image)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") { presentationMode.wrappedValue.dismiss() }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCompletionSheet) {
            completionSheet
        }
        .task {
            await viewModel.loadBuildingName(for: task.buildingId)
        }
    }
    
    // MARK: - Subviews (Preserving Original Style)
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.category.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(task.category.color)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(task.category.color.opacity(0.1)).cornerRadius(8)
                
                Spacer()
                
                Text(task.urgency.rawValue.capitalized)
                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(task.urgency.color).cornerRadius(12)
            }
            Text(task.name).font(.title2).fontWeight(.bold)
            if !task.description.isEmpty {
                Text(task.description).foregroundColor(.secondary)
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12)
    }
    
    private var taskDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Task Information").font(.headline)
            VStack(spacing: 12) {
                detailRow(icon: "calendar", label: "Due Date", value: formatDate(task.dueDate))
                detailRow(icon: "hourglass", label: "Est. Duration", value: "\(task.estimatedDuration / 60) mins")
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12)
    }
    
    private var buildingInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location").font(.headline)
            VStack(spacing: 12) {
                detailRow(icon: "building.2", label: "Building", value: viewModel.buildingName)
                detailRow(icon: "map", label: "Building ID", value: task.buildingId)
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12)
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Status").font(.headline)
            HStack {
                Circle()
                    .fill(task.isCompleted ? .green : task.urgency.color)
                    .frame(width: 12, height: 12)
                Text(task.isCompleted ? "Completed" : "Pending")
                    .font(.subheadline).fontWeight(.medium)
            }
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if !task.isCompleted {
                Button(action: { showingCompletionSheet = true }) {
                    Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                        .fontWeight(.medium).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.green)
            }
            
            Button(action: { /* Navigate to building detail */ }) {
                Label("View Building Details", systemImage: "building.2")
                    .fontWeight(.medium).frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
    
    private func completionPhotoSection(_ image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Completion Photo").font(.headline)
                Spacer()
                Button("Remove", role: .destructive) { selectedImage = nil }
                    .font(.caption)
            }
            Image(uiImage: image).resizable().scaledToFit()
                .frame(maxHeight: 200).cornerRadius(12).clipped()
        }
        .padding().background(Color(.systemBackground)).cornerRadius(12)
    }
    
    private var completionSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Complete Task").font(.title2).fontWeight(.bold).padding(.horizontal)
                
                VStack(alignment: .leading) {
                    Text("Add completion notes (optional):").font(.subheadline).foregroundColor(.secondary)
                    TextEditor(text: $completionNotes)
                        .frame(height: 100).padding(8)
                        .background(Color(.systemGray6)).cornerRadius(8)
                }.padding(.horizontal)
                
                HStack {
                    Button(action: { showingImagePicker = true }) {
                        Label("Add Photo", systemImage: "camera.fill")
                    }.buttonStyle(.bordered)
                    if selectedImage != nil {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    }
                    Spacer()
                }.padding(.horizontal)
                
                Spacer()
                
                Button(action: markTaskComplete) {
                    Label("Confirm Completion", systemImage: "checkmark.circle.fill")
                        .fontWeight(.medium).frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent).tint(.green).padding()
            }
            .navigationBarItems(leading: Button("Cancel") { showingCompletionSheet = false })
        }
    }
    
    // MARK: - Helper Methods
    
    private func markTaskComplete() {
        print("✅ Task marked complete: \(task.name)")
        // In a real app, this would call a TaskService method:
        // Task {
        //     let evidence = ActionEvidence(photos: [selectedImage?.pngData()], comments: completionNotes)
        //     try? await TaskService.shared.completeTask(task.id, with: evidence)
        //     presentationMode.wrappedValue.dismiss()
        // }
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon).font(.subheadline).foregroundColor(.blue).frame(width: 20)
            Text(label).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(value).font(.subheadline).fontWeight(.medium).multilineTextAlignment(.trailing)
        }
    }
}
