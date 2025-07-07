//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  ✅ V6.0 MINIMAL FIX: Uses existing components
//

import SwiftUI

struct DashboardTaskDetailView: View {
    let task: ContextualTask
    
    @StateObject private var viewModel: TaskDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingCompletionSheet = false
    @State private var completionNotes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    
    init(task: ContextualTask) {
        self.task = task
        self._viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                taskInfoSection
                buildingSection
                statusSection
                actionButtonsSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(sourceType: imageSourceType, selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingCompletionSheet) {
            completionSheet
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.category.rawValue.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(categoryColor)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(task.urgencyLevel.capitalized)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(urgencyColor)
                    .cornerRadius(12)
            }
            
            Text(task.name)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Scheduled", systemImage: "clock")
                .font(.headline)
            
            HStack {
                Text("\(task.startTime) - \(task.endTime)")
                    .font(.subheadline)
                Spacer()
                Text(task.recurrence.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var buildingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Building", systemImage: "building.2")
                .font(.headline)
            
            Text(task.buildingName)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var statusSection: some View {
        HStack {
            Label(task.status.capitalized, systemImage: statusIcon)
                .font(.headline)
                .foregroundColor(statusColor)
            
            Spacer()
            
            if task.status == "completed" {
                Text("✓")
                    .font(.title2)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if task.status != "completed" {
                Button(action: { showingCompletionSheet = true }) {
                    Label("Mark as Complete", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        imageSourceType = .camera
                        showingImagePicker = true
                    }) {
                        Label("Camera", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        imageSourceType = .photoLibrary
                        showingImagePicker = true
                    }) {
                        Label("Library", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private var completionSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Complete Task")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                TextField("Add notes (optional)", text: $viewModel.completionNotes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                }
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        showingCompletionSheet = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Complete") {
                        if let image = selectedImage {
                            viewModel.capturedPhotos = [image]
                        }
                        Task {
                            await viewModel.completeTask()
                            showingCompletionSheet = false
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isSubmitting)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var categoryColor: Color {
        switch task.category.lowercased() {
        case "cleaning": return .blue
        case "maintenance": return .orange
        case "repair": return .red
        case "sanitation": return .green
        case "inspection": return .purple
        default: return .gray
        }
    }
    
    private var urgencyColor: Color {
        switch task.urgencyLevel.lowercased() {
        case "low": return .green
        case "medium": return .orange
        case "high", "critical": return .red
        default: return .gray
        }
    }
    
    private var statusIcon: String {
        switch task.status {
        case "completed": return "checkmark.circle.fill"
        case "in_progress": return "clock.fill"
        default: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch task.status {
        case "completed": return .green
        case "in_progress": return .blue
        default: return .gray
        }
    }
}
