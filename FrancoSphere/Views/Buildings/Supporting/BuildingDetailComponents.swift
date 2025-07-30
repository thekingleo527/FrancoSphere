//
//  BuildingDetailComponents.swift
//  FrancoSphere v6.0
//
//  Supporting components for BuildingDetailView
//  Focuses on unique components not defined elsewhere
//

import SwiftUI
import MapKit
import MessageUI

// MARK: - Message Composer

struct MessageComposerView: View {
    let recipients: [String]
    let subject: String
    let prefilledBody: String
    
    @State private var messageBody = ""
    @State private var isUrgent = false
    @State private var attachPhoto = false
    @State private var selectedPhotos: [UIImage] = []
    @State private var showingPhotoPicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Recipients
                VStack(alignment: .leading, spacing: 8) {
                    Text("To:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(recipients, id: \.self) { recipient in
                                RecipientChip(email: recipient)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                
                // Message options
                HStack {
                    Toggle(isOn: $isUrgent) {
                        Label("Urgent", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .red))
                    
                    Spacer()
                    
                    Button(action: { showingPhotoPicker = true }) {
                        Label(
                            selectedPhotos.isEmpty ? "Add Photo" : "\(selectedPhotos.count) Photos",
                            systemImage: "camera.fill"
                        )
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                
                // Message body
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $messageBody)
                        .font(.body)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Photo preview
                if !selectedPhotos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(selectedPhotos.indices, id: \.self) { index in
                                PhotoThumbnail(
                                    image: selectedPhotos[index],
                                    onRemove: {
                                        selectedPhotos.remove(at: index)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(height: 100)
                }
                
                Spacer()
            }
            .navigationTitle(subject)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") { sendMessage() }
                        .fontWeight(.semibold)
                        .disabled(messageBody.isEmpty)
                }
            }
        }
        .onAppear {
            messageBody = prefilledBody
        }
        .sheet(isPresented: $showingPhotoPicker) {
            PhotoPicker(selectedImages: $selectedPhotos)
        }
    }
    
    private func sendMessage() {
        // Send message logic
        print("Sending message to: \(recipients.joined(separator: ", "))")
        print("Subject: \(subject)")
        print("Urgent: \(isUrgent)")
        print("Photos: \(selectedPhotos.count)")
        print("Body: \(messageBody)")
        
        // TODO: Implement actual sending via email client or API
        
        dismiss()
    }
}

struct RecipientChip: View {
    let email: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.circle.fill")
                .font(.caption)
            
            Text(displayName)
                .font(.caption)
                .lineLimit(1)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue)
        .cornerRadius(16)
    }
    
    private var displayName: String {
        if email.contains("@") {
            return email.components(separatedBy: "@").first?.capitalized ?? email
        }
        return email
    }
}

struct PhotoThumbnail: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .offset(x: 8, y: -8)
        }
    }
}

// MARK: - Maintenance Components

struct MaintenanceHistoryCard: View {
    let records: [MaintenanceRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Maintenance", systemImage: "wrench.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            if records.isEmpty {
                Text("No recent maintenance")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(records.prefix(5)) { record in
                        MaintenanceRecordRow(record: record)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct MaintenanceRecordRow: View {
    let record: MaintenanceRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(record.type)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            if let vendor = record.vendor {
                Text(vendor)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(record.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(2)
            
            HStack {
                MaintenanceStatusBadge(status: record.status)
                
                Spacer()
                
                if let cost = record.cost {
                    Text("$\(cost.formatted())")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct MaintenanceStatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "completed", "passed":
            return .green
        case "pending", "scheduled":
            return .orange
        case "failed", "urgent":
            return .red
        default:
            return .blue
        }
    }
}

// MARK: - Team Components

struct AssignedWorkersCard: View {
    let workers: [WorkerAssignment]
    let onCall: (WorkerAssignment) -> Void
    let onMessage: (WorkerAssignment) -> Void
    let onViewTasks: (WorkerAssignment) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Assigned Workers", systemImage: "person.2.fill")
                .font(.headline)
                .foregroundColor(.white)
            
            if workers.isEmpty {
                Text("No workers currently assigned")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.vertical)
            } else {
                VStack(spacing: 12) {
                    ForEach(workers) { assignment in
                        WorkerAssignmentRow(
                            assignment: assignment,
                            onCall: { onCall(assignment) },
                            onMessage: { onMessage(assignment) },
                            onViewTasks: { onViewTasks(assignment) }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

struct WorkerAssignmentRow: View {
    let assignment: WorkerAssignment
    let onCall: () -> Void
    let onMessage: () -> Void
    let onViewTasks: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Worker avatar
                ZStack {
                    Circle()
                        .fill(assignment.isOnSite ? Color.green : Color.gray)
                        .frame(width: 40, height: 40)
                    
                    Text(assignment.worker.name.initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(assignment.worker.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        if !assignment.specialties.isEmpty {
                            Text("• \(assignment.specialties.first!)")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    HStack(spacing: 8) {
                        if assignment.isOnSite {
                            Label("On-site", systemImage: "location.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Text(assignment.schedule)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    ActionButton(icon: "phone.fill", color: .green, action: onCall)
                    ActionButton(icon: "message.fill", color: .blue, action: onMessage)
                    ActionButton(icon: "checklist", color: .purple, action: onViewTasks)
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.2))
                .clipShape(Circle())
        }
    }
}

// MARK: - Supporting Models

struct MaintenanceRecord: Identifiable {
    let id: String
    let date: Date
    let type: String
    let vendor: String?
    let description: String
    let cost: Decimal?
    let status: String
}

struct WorkerAssignment: Identifiable {
    let id: String
    let worker: WorkerProfile
    let schedule: String
    let specialties: [String]
    var isOnSite: Bool
}

// MARK: - Photo Picker (Simple implementation)

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Extensions

extension String {
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: self) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        
        // Fallback
        let words = self.split(separator: " ")
        let initials = words.compactMap { $0.first }.prefix(2)
        return String(initials).uppercased()
    }
}

// MARK: - Worker Profile (Temporary until we align with your models)

struct WorkerProfile {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let role: String
}
