//
//  TaskPhotoUploader.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 3/30/25.
//


import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import UIKit
// FrancoSphere Types Import
// (This comment helps identify our import)


/// Dedicated photo uploader for task verification
struct TaskPhotoUploader: View {
    @Binding var image: UIImage?
    var onPhotoSelected: (UIImage) -> Void
    
    @State private var showImagePicker = false
    @State private var showSourceOptions = false
    @State private var imageSource: UIImagePickerController.SourceType = .camera
    
    var body: some View {
        VStack(spacing: 12) {
            // Display selected image or placeholder
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
                    .cornerRadius(8)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        VStack {
                            Image(systemName: "camera")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("Task Verification Photo")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                        }
                    )
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button(action: {
                    showSourceOptions = true
                }) {
                    HStack {
                        Image(systemName: image == nil ? "camera.fill" : "arrow.triangle.2.circlepath")
                        Text(image == nil ? "Add Photo" : "Change Photo")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                
                if image != nil {
                    Button(action: {
                        image = nil
                    }) {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Remove")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: imageSource, selectedImage: $image)
                .onDisappear {
                    if let selectedImage = image {
                        onPhotoSelected(selectedImage)
                    }
                }
        }
        .actionSheet(isPresented: $showSourceOptions) {
            ActionSheet(
                title: Text("Select Photo Source"),
                message: Text("Choose where to get your photo from"),
                buttons: [
                    .default(Text("Camera")) {
                        imageSource = .camera
                        showImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        imageSource = .photoLibrary
                        showImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
    }
}

/// Basic image picker that works with your existing code
struct ImagePickerView: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

/// Helper functions for task photo management
struct TaskPhotoManager {
    /// Saves a task verification photo to disk
    static func savePhoto(_ image: UIImage, forTask taskID: String) -> String? {
        let fileName = "task_\(taskID)_\(Int(Date().timeIntervalSince1970)).jpg"
        
        // Get the documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Convert UIImage to JPEG data
        if let data = image.jpegData(compressionQuality: 0.8) {
            // Write to disk
            do {
                try data.write(to: fileURL)
                return fileURL.path
            } catch {
                print("Error saving image: \(error)")
                return nil
            }
        }
        
        return nil
    }
    
    /// Loads a photo from a file path
    static func loadPhoto(from path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
}