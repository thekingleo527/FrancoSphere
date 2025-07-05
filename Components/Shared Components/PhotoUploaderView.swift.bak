import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

import UIKit
// FrancoSphere Types Import
// (This comment helps identify our import)


// Rename to avoid conflicts with other implementations
public struct FSPhotoUploaderView: View {
    // Use @Binding for proper state management
    @Binding var selectedImage: UIImage?
    var onPhotoSelected: (UIImage) -> Void
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @State private var isShowingImagePicker = false
    
    public init(selectedImage: Binding<UIImage?>,
                onPhotoSelected: @escaping (UIImage) -> Void,
                sourceType: UIImagePickerController.SourceType = .photoLibrary) {
        self._selectedImage = selectedImage
        self.onPhotoSelected = onPhotoSelected
        self.sourceType = sourceType
    }
    
    public var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 200)
                    .cornerRadius(10)
            } else {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .frame(height: 200)
                    
                    VStack {
                        Image(systemName: "camera.fill")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("Tap to upload photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Button(action: {
                isShowingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text(selectedImage == nil ? "Upload Photo" : "Change Photo")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            FSImagePicker(selectedImage: $selectedImage, sourceType: sourceType, onImagePicked: onPhotoSelected)
        }
    }
}

// Rename to avoid conflicts with other implementations
struct FSImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var sourceType: UIImagePickerController.SourceType
    var onImagePicked: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: FSImagePicker
        
        init(_ parent: FSImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
                parent.onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// Preview with proper @State for binding
struct FSPhotoUploaderView_Previews: PreviewProvider {
    static var previews: some View {
        // Use @State to create a Binding for the preview
        let previewView = StatePreviewWrapper()
        return previewView
    }
    
    // Helper struct for preview
    struct StatePreviewWrapper: View {
        @State private var previewImage: UIImage? = nil
        
        var body: some View {
            FSPhotoUploaderView(
                selectedImage: $previewImage,
                onPhotoSelected: { _ in }
            )
        }
    }
}
