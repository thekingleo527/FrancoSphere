
//
//  ImagePickerComponents.swift
//  FrancoSphere v6.0
//
//  📸 PHOTO MANAGEMENT: Unified image handling
//  🖼️ GALLERY: Building photo organization
//  📍 GEOTAGGING: Location-aware photos
//

import SwiftUI
import PhotosUI
import CoreLocation

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: ((UIImage) -> Void)?
    var sourceType: UIImagePickerController.SourceType = .camera
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        picker.allowsEditing = false
        
        // Add location metadata if available
        if sourceType == .camera {
            picker.showsCameraControls = true
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImagePicked?(image)
            }
            
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Photo Picker (Multiple Selection)

struct PhotoPicker: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                PhotosPicker(
                    selection: $selectedItems,
                    maxSelectionCount: 10,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    VStack(spacing: 20) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Select Photos")
                            .font(.headline)
                        
                        Text("Choose up to 10 photos")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onChange(of: selectedItems) { items in
                    Task {
                        selectedImages = []
                        for item in items {
                            if let data = try? await item.loadTransferable(type: Data.self),
                               let image = UIImage(data: data) {
                                selectedImages.append(image)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Photos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .disabled(selectedImages.isEmpty)
                }
            }
        }
    }
}

// MARK: - Building Photo Gallery

struct BuildingPhotoGallery: View {
    let building: CoreTypes.Building
    @StateObject private var viewModel = PhotoGalleryViewModel()
    @State private var selectedCategory = PhotoCategory.all
    @State private var showingFullScreen = false
    @State private var selectedPhoto: BuildingPhoto?
    @State private var showingAddPhoto = false
    
    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PhotoCategory.allCases, id: \.self) { category in
                        CategoryPill(
                            category: category,
                            isSelected: selectedCategory == category,
                            count: viewModel.photoCount(for: category)
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemBackground))
            
            // Photo grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(viewModel.filteredPhotos(for: selectedCategory)) { photo in
                        PhotoGridItem(photo: photo) {
                            selectedPhoto = photo
                            showingFullScreen = true
                        }
                    }
                }
                .padding(2)
            }
            
            // Add photo button
            VStack {
                Button(action: { showingAddPhoto = true }) {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPhotos(for: building.id)
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let photo = selectedPhoto {
                PhotoDetailView(photo: photo)
            }
        }
        .sheet(isPresented: $showingAddPhoto) {
            PhotoCaptureView(building: building) { image in
                await viewModel.savePhoto(image, for: building)
            }
        }
    }
}

// MARK: - Photo Category

enum PhotoCategory: String, CaseIterable {
    case all = "All"
    case exterior = "Exterior"
    case interior = "Interior"
    case utilities = "Utilities"
    case issues = "Issues"
    case before = "Before"
    case after = "After"
    case equipment = "Equipment"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.3x3"
        case .exterior: return "building.2"
        case .interior: return "door.left.hand.open"
        case .utilities: return "wrench"
        case .issues: return "exclamationmark.triangle"
        case .before: return "arrow.left.square"
        case .after: return "arrow.right.square"
        case .equipment: return "hammer"
        }
    }
}

struct CategoryPill: View {
    let category: PhotoCategory
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.caption)
                
                Text(category.rawValue)
                    .font(.subheadline)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.blue.opacity(0.3))
                        )
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
            )
        }
    }
}

// MARK: - Photo Grid Item

struct PhotoGridItem: View {
    let photo: BuildingPhoto
    let onTap: () -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 120)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                }
                
                // Overlay badges
                VStack {
                    HStack {
                        if photo.hasIssue {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        if photo.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.green)
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                }
                .padding(4)
            }
        }
        .task {
            thumbnail = await photo.loadThumbnail()
        }
    }
}

// MARK: - Photo Detail View

struct PhotoDetailView: View {
    let photo: BuildingPhoto
    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var showingActions = false
    @State private var isZoomed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = fullImage {
                    PhotoZoomView(image: image, isZoomed: $isZoomed)
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
                
                // Overlay info
                if !isZoomed {
                    VStack {
                        // Top bar
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Button(action: { showingActions = true }) {
                                Image(systemName: "ellipsis")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .frame(width: 44, height: 44)
                                    .background(Color.black.opacity(0.5))
                                    .clipShape(Circle())
                            }
                        }
                        .padding()
                        
                        Spacer()
                        
                        // Photo info
                        PhotoInfoOverlay(photo: photo)
                    }
                }
            }
            .navigationBarHidden(true)
            .statusBar(hidden: true)
        }
        .task {
            fullImage = await photo.loadFullImage()
        }
        .confirmationDialog("Photo Actions", isPresented: $showingActions) {
            Button("Share") { sharePhoto() }
            Button("Download") { downloadPhoto() }
            Button("Mark as Issue") { markAsIssue() }
            Button("Delete", role: .destructive) { deletePhoto() }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func sharePhoto() {
        guard let image = fullImage else { return }
        
        let av = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(av, animated: true)
        }
    }
    
    private func downloadPhoto() {
        guard let image = fullImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }
    
    private func markAsIssue() {
        // Mark photo as containing an issue
    }
    
    private func deletePhoto() {
        // Delete photo after confirmation
    }
}

struct PhotoZoomView: View {
    let image: UIImage
    @Binding var isZoomed: Bool
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = lastScale * value
                        isZoomed = scale > 1.1
                    }
                    .onEnded { _ in
                        lastScale = scale
                        
                        // Snap back if too small
                        withAnimation(.spring()) {
                            if scale < 1 {
                                scale = 1
                                lastScale = 1
                                offset = .zero
                                lastOffset = .zero
                                isZoomed = false
                            }
                        }
                    }
            )
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1 {
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onTapGesture(count: 2) {
                withAnimation(.spring()) {
                    if scale > 1 {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                        isZoomed = false
                    } else {
                        scale = 2
                        lastScale = 2
                        isZoomed = true
                    }
                }
            }
    }
}

struct PhotoInfoOverlay: View {
    let photo: BuildingPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Metadata
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(photo.space)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(photo.timestamp.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let worker = photo.uploadedBy {
                        Text("By \(worker)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    if photo.hasLocation {
                        Label("GPS", systemImage: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            // Notes
            if let notes = photo.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
            }
            
            // Tags
            if !photo.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(photo.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.8))
                                .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - View Model

@MainActor
class PhotoGalleryViewModel: ObservableObject {
    @Published var photos: [BuildingPhoto] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    func loadPhotos(for buildingId: String) async {
        isLoading = true
        
        do {
            // Load photos from database
            photos = try await PhotoStorageService.shared.loadPhotos(for: buildingId)
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    func savePhoto(_ image: UIImage, for building: CoreTypes.Building) async {
        // Save photo logic
    }
    
    func photoCount(for category: PhotoCategory) -> Int {
        if category == .all {
            return photos.count
        }
        return photos.filter { $0.category == category }.count
    }
    
    func filteredPhotos(for category: PhotoCategory) -> [BuildingPhoto] {
        if category == .all {
            return photos
        }
        return photos.filter { $0.category == category }
    }
}

// MARK: - Data Models

struct BuildingPhoto: Identifiable {
    let id: String
    let buildingId: String
    let space: String
    let category: PhotoCategory
    let timestamp: Date
    let uploadedBy: String?
    let notes: String?
    let tags: [String]
    let localPath: String
    let remotePath: String?
    let thumbnailPath: String?
    let hasIssue: Bool
    let isVerified: Bool
    let hasLocation: Bool
    let location: CLLocation?
    
    func loadThumbnail() async -> UIImage? {
        // Load thumbnail image
        return nil // Placeholder
    }
    
    func loadFullImage() async -> UIImage? {
        // Load full resolution image
        return nil // Placeholder
    }
}

// MARK: - Photo Storage Service

actor PhotoStorageService {
    static let shared = PhotoStorageService()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    func loadPhotos(for buildingId: String) async throws -> [BuildingPhoto] {
        // Load from database and file system
        return []
    }
    
    func savePhoto(_ image: UIImage, metadata: PhotoMetadata) async throws -> BuildingPhoto {
        // Save to file system and database
        let photoId = UUID().uuidString
        let fileName = "\(photoId).jpg"
        
        // Create directory structure
        let buildingDirectory = documentsDirectory
            .appendingPathComponent("Buildings")
            .appendingPathComponent(metadata.buildingId)
            .appendingPathComponent("Photos")
            .appendingPathComponent(metadata.spaceType)
        
        try FileManager.default.createDirectory(at: buildingDirectory, withIntermediateDirectories: true)
        
        // Save image
        let filePath = buildingDirectory.appendingPathComponent(fileName)
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            try data.write(to: filePath)
        }
        
        // Create database record
        let photo = BuildingPhoto(
            id: photoId,
            buildingId: metadata.buildingId,
            space: metadata.spaceType,
            category: .all,
            timestamp: metadata.timestamp,
            uploadedBy: nil,
            notes: metadata.notes,
            tags: [],
            localPath: filePath.path,
            remotePath: nil,
            thumbnailPath: nil,
            hasIssue: false,
            isVerified: false,
            hasLocation: metadata.location != nil,
            location: metadata.location
        )
        
        return photo
    }
}

// MARK: - Utility Room Photo Organizer

struct UtilityRoomPhotoOrganizer: View {
    let building: CoreTypes.Building
    @State private var utilityRooms: [UtilityRoom] = []
    @State private var selectedRoom: UtilityRoom?
    
    var body: some View {
        List {
            Section("Utility Spaces") {
                ForEach(utilityRooms) { room in
                    NavigationLink(destination: UtilityRoomDetail(room: room)) {
                        HStack {
                            Image(systemName: room.icon)
                                .font(.title3)
                                .foregroundColor(.blue)
                                .frame(width: 40)
                            
                            VStack(alignment: .leading) {
                                Text(room.name)
                                    .font(.headline)
                                
                                Text("\(room.photoCount) photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if room.hasRecentActivity {
                                Circle()
                                    .fill(Color.orange)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
            }
            
            Section {
                Button(action: addUtilityRoom) {
                    Label("Add Utility Room", systemImage: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Utility Rooms")
        .task {
            loadUtilityRooms()
        }
    }
    
    private func loadUtilityRooms() {
        // Load utility rooms for building
        utilityRooms = [
            UtilityRoom(id: "1", name: "Boiler Room", icon: "flame.fill", photoCount: 12, hasRecentActivity: true),
            UtilityRoom(id: "2", name: "Electrical Room", icon: "bolt.fill", photoCount: 8, hasRecentActivity: false),
            UtilityRoom(id: "3", name: "Water Meter Room", icon: "drop.fill", photoCount: 5, hasRecentActivity: false),
            UtilityRoom(id: "4", name: "Trash Room", icon: "trash.fill", photoCount: 23, hasRecentActivity: true),
            UtilityRoom(id: "5", name: "Storage Room", icon: "archivebox.fill", photoCount: 15, hasRecentActivity: false)
        ]
    }
    
    private func addUtilityRoom() {
        // Add new utility room
    }
}

struct UtilityRoom: Identifiable {
    let id: String
    let name: String
    let icon: String
    let photoCount: Int
    let hasRecentActivity: Bool
}

struct UtilityRoomDetail: View {
    let room: UtilityRoom
    
    var body: some View {
        BuildingPhotoGallery(building: CoreTypes.Building(
            id: "temp",
            name: room.name,
            address: "",
            type: .commercial,
            size: 0,
            floors: 0,
            units: 0,
            yearBuilt: 0,
            managementCompany: nil,
            primaryContact: nil,
            emergencyContact: nil,
            accessInstructions: nil,
            specialNotes: nil,
            amenities: [],
            complianceStatus: .unknown,
            lastInspectionDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}

// MARK: - Previews

#Preview("Photo Gallery") {
    NavigationView {
        BuildingPhotoGallery(building: PreviewData.sampleBuilding)
    }
}

#Preview("Utility Rooms") {
    NavigationView {
        UtilityRoomPhotoOrganizer(building: PreviewData.sampleBuilding)
    }
}
