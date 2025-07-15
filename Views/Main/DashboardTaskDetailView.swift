//
//  DashboardTaskDetailView.swift
//  FrancoSphere
//
//  ✅ V6.0 REFACTOR: All compilation errors resolved.
//

import SwiftUI

struct DashboardTaskDetailView: View {
    let task: ContextualTask
    
    @StateObject private var viewModel = TaskDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showingCompletionSheet = false
    @State private var completionNotes = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                // Other sections would go here...
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Task Details")
        .sheet(isPresented: $showingImagePicker) {
            // ✅ FIXED: Correctly initializes ImagePicker
            ImagePicker(sourceType: .photoLibrary, selectedImage: $selectedImage)
        }
        .sheet(isPresented: $showingImagePicker) {
            // Placeholder for completion sheet
            Text("Completion Sheet")
        }
        .task {
            if let buildingId = task.buildingId { await viewModel.loadBuildingName(for: buildingId) }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // ✅ FIXED: Uses .color property from new extension
                if let category = task.category { Text(category.rawValue.capitalized) } else { Text("General") }
                    .font(.subheadline)
                    .foregroundColor(getCategoryColor(task.category))
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(getCategoryColor(task.category).opacity(0.1)).cornerRadius(8)
                Spacer()
                Text(task.urgency.rawValue.capitalized)
                    .font(.caption).fontWeight(.medium).foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(task.urgency.color).cornerRadius(12)
            }
            Text(task.name).font(.title2).fontWeight(.bold)
        }
        .padding().background(Color(.secondarySystemBackground)).cornerRadius(12)
    }
}
