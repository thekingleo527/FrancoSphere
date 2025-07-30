//
//  ImagePicker.swift
//  FrancoSphere v6.0
//
//  📸 PHOTO MANAGEMENT: Unified image handling for Phase 3
//  🖼️ GALLERY: Building photo organization with evidence tracking
//  📍 GEOTAGGING: Location-aware photos for compliance
//  ✅ PHASE 3 READY: Integrated with PhotoEvidenceService
//
//  Note: Renamed components to avoid conflicts:
//  - BuildingPhoto → FrancoBuildingPhoto
//  - PhotoGridItem → FrancoPhotoGridItem
//  - BuildingPhotoGallery → FrancoBuildingPhotoGallery
//

import SwiftUI
import PhotosUI
import CoreLocation
import Combine

// MARK: - Basic Image Picker (Existing - Enhanced)

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

struct FrancoPhotoPicker: View {
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
                .onChange(of: selectedItems) { oldValue, newValue in
                    Task {
                        selectedImages = []
                        for item in newValue {
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

// MARK: - Building Photo Gallery (Renamed to avoid conflict)

struct FrancoBuildingPhotoGallery: View {
    let buildingId: String
    @StateObject private var viewModel = FrancoPhotoGalleryViewModel()
    @State private var selectedCategory = FrancoPhotoCategory.all
    @State private var showingFullScreen = false
    @State private var selectedPhoto: FrancoBuildingPhoto?
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
                    ForEach(FrancoPhotoCategory.allCases, id: \.self) { category in
                        FrancoCategoryPill(
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
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading photos...")
                    .padding()
                Spacer()
            } else if viewModel.photos.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No photos yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add photos to document this building")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(viewModel.filteredPhotos(for: selectedCategory)) { photo in
                            FrancoPhotoGridItem(photo: photo) {
                                selectedPhoto = photo
                                showingFullScreen = true
                            }
                        }
                    }
                    .padding(2)
                }
            }
            
            // Add photo button
            VStack {
                Button(action: { showingAddPhoto = true }) {
                    Label("Add Photo", systemImage: "camera.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(FrancoSphereDesign.DashboardColors.workerPrimary)
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .navigationTitle("Photos")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPhotos(for: buildingId)
        }
        .fullScreenCover(isPresented: $showingFullScreen) {
            if let photo = selectedPhoto {
                FrancoPhotoDetailView(photo: photo)
            }
        }
        .sheet(isPresented: $showingAddPhoto) {
            FrancoBuildingPhotoCaptureView(
                buildingId: buildingId
            ) { image, category, notes in
                await viewModel.savePhoto(image, buildingId: buildingId, category: category, notes: notes)
            }
        }
    }
}

// MARK: - Building Photo Capture View

struct FrancoBuildingPhotoCaptureView: View {
    let buildingId: String
    let onCapture: (UIImage, FrancoPhotoCategory, String) async -> Void
    
    @State private var capturedImage: UIImage?
    @State private var category = FrancoPhotoCategory.all
    @State private var notes = ""
    @State private var showingCamera = true
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    // Get building name from CanonicalIDs
    private var buildingName: String {
        switch buildingId {
        case "14": return "Rubin Museum"
        case "1": return "12 West 18th Street"
        case "2": return "36 Walker Street"
        case "3": return "41 Elizabeth Street"
        case "4": return "68 Perry Street"
        case "5": return "104 Franklin Street"
        case "6": return "112 West 17th Street"
        case "7": return "117 West 17th Street"
        case "8": return "123 1st Avenue"
        case "9": return "131 Perry Street"
        case "10": return "133 East 15th Street"
        case "11": return "135 West 17th Street"
        case "12": return "136 West 17th Street"
        case "13": return "138 West 17th Street"
        case "15": return "29-31 East 20th Street"
        case "16": return "Stuyvesant Cove Park"
        case "17": return "178 Spring Street"
        default: return "Building #\(buildingId)"
        }
    }
    
    var body: some View {
        NavigationView {
            if let image = capturedImage {
                // Review captured image
                VStack(spacing: 0) {
                    // Image preview
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .background(Color.black)
                    
                    // Metadata form
                    Form {
                        Section("Details") {
                            Picker("Category", selection: $category) {
                                ForEach(FrancoPhotoCategory.allCases, id: \.self) { cat in
                                    Label(cat.rawValue, systemImage: cat.icon)
                                        .tag(cat)
                                }
                            }
                            
                            TextField("Notes (optional)", text: $notes, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        Section {
                            Button("Save Photo") {
                                Task {
                                    await onCapture(image)
                                    dismiss()
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .font(.headline)
                            
                            Button("Retake", role: .destructive) {
                                capturedImage = nil
                                showingCamera = true
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .navigationTitle("Add Photo")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Cancel") { dismiss() }
                )
            } else if showingCamera {
                ImagePicker(
                    image: $capturedImage,
                    onImagePicked: { image in
                        capturedImage = image
                        showingCamera = false
                    },
                    sourceType: .camera
                )
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Photo Category (Renamed)

enum FrancoPhotoCategory: String, CaseIterable {
    case all = "All"
    case exterior = "Exterior"
    case interior = "Interior"
    case utilities = "Utilities"
    case issues = "Issues"
    case before = "Before"
    case after = "After"
    case equipment = "Equipment"
    case compliance = "Compliance"
    
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
        case .compliance: return "checkmark.shield"
        }
    }
}

// MARK: - Category Pill

struct FrancoCategoryPill: View {
    let category: FrancoPhotoCategory
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
                    .fill(isSelected ? FrancoSphereDesign.DashboardColors.workerPrimary : Color(.systemGray5))
            )
        }
    }
}

// MARK: - Photo Grid Item (Renamed)

struct FrancoPhotoGridItem: View {
    let photo: FrancoBuildingPhoto
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
            thumbnail = await loadThumbnail(for: photo)
        }
    }
    
    private func loadThumbnail(for photo: FrancoBuildingPhoto) async -> UIImage? {
        return await FrancoPhotoStorageService.shared.loadThumbnail(for: photo.id)
    }
}

// MARK: - Photo Detail View

struct FrancoPhotoDetailView: View {
    let photo: FrancoBuildingPhoto
    @Environment(\.dismiss) private var dismiss
    @State private var fullImage: UIImage?
    @State private var showingActions = false
    @State private var isZoomed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                if let image = fullImage {
                    FrancoPhotoZoomView(image: image, isZoomed: $isZoomed)
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
                        FrancoPhotoInfoOverlay(photo: photo)
                    }
                }
            }
            .navigationBarHidden(true)
            .statusBar(hidden: true)
        }
        .task {
            fullImage = await FrancoPhotoStorageService.shared.loadFullImage(for: photo.id)
        }
        .confirmationDialog("Photo Actions", isPresented: $showingActions) {
            Button("Share") { sharePhoto() }
            Button("Download") { downloadPhoto() }
            if !photo.hasIssue {
                Button("Mark as Issue") { markAsIssue() }
            }
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
        Task {
            await FrancoPhotoStorageService.shared.markPhotoAsIssue(photo.id)
        }
    }
    
    private func deletePhoto() {
        Task {
            await FrancoPhotoStorageService.shared.deletePhoto(photo.id)
            dismiss()
        }
    }
}

// MARK: - Photo Zoom View

struct FrancoPhotoZoomView: View {
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

// MARK: - Photo Info Overlay

struct FrancoPhotoInfoOverlay: View {
    let photo: FrancoBuildingPhoto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Metadata
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(photo.category.rawValue)
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
            
            // Compliance info
            if photo.taskId != nil {
                HStack {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.caption)
                    Text("Task Evidence")
                        .font(.caption)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .cornerRadius(12)
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

// MARK: - View Model (Renamed)

@MainActor
class FrancoPhotoGalleryViewModel: ObservableObject {
    @Published var photos: [FrancoBuildingPhoto] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationManager = LocationManager()
    
    init() {
        // Request location permission when view model is created
        locationManager.requestLocation()
    }
    
    func loadPhotos(for buildingId: String) async {
        isLoading = true
        
        do {
            // Load photos from database via service
            photos = try await FrancoPhotoStorageService.shared.loadPhotos(for: buildingId)
        } catch {
            self.error = error
            print("❌ Failed to load photos: \(error)")
        }
        
        isLoading = false
    }
    
    func savePhoto(_ image: UIImage, buildingId: String) async {
        do {
            let metadata = FrancoBuildingPhotoMetadata(
                buildingId: buildingId,
                category: .all,
                notes: nil,
                location: locationManager.location,  // Will be nil if not available
                taskId: nil,
                workerId: NewAuthManager.shared.workerId,
                timestamp: Date()
            )
            
            let photo = try await FrancoPhotoStorageService.shared.savePhoto(image, metadata: metadata)
            photos.append(photo)
        } catch {
            self.error = error
            print("❌ Failed to save photo: \(error)")
        }
    }
    
    func photoCount(for category: FrancoPhotoCategory) -> Int {
        if category == .all {
            return photos.count
        }
        return photos.filter { $0.category == category }.count
    }
    
    func filteredPhotos(for category: FrancoPhotoCategory) -> [FrancoBuildingPhoto] {
        if category == .all {
            return photos
        }
        return photos.filter { $0.category == category }
    }
}

// MARK: - Data Models (Renamed to avoid conflicts)

struct FrancoBuildingPhoto: Identifiable {
    let id: String
    let buildingId: String
    let category: FrancoPhotoCategory
    let timestamp: Date
    let uploadedBy: String?
    let notes: String?
    let localPath: String
    let remotePath: String?
    let thumbnailPath: String?
    let hasIssue: Bool
    let isVerified: Bool
    let hasLocation: Bool
    let location: CLLocation?
    let taskId: String?
    let fileSize: Int?
}

struct FrancoBuildingPhotoMetadata {
    let buildingId: String
    let category: FrancoPhotoCategory
    let notes: String?
    let location: CLLocation?
    let taskId: String?
    let workerId: String?
    let timestamp: Date
}

// MARK: - Photo Storage Service (Phase 3 Integration - Renamed)

actor FrancoPhotoStorageService {
    static let shared = FrancoPhotoStorageService()
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    private let grdbManager = GRDBManager.shared
    private let compressionQuality: CGFloat = 0.7
    private let thumbnailSize = CGSize(width: 200, height: 200)
    
    func loadPhotos(for buildingId: String) async throws -> [FrancoBuildingPhoto] {
        let rows = try await grdbManager.query("""
            SELECT * FROM photo_evidence 
            WHERE building_id = ? 
            ORDER BY created_at DESC
        """, [buildingId])
        
        return rows.compactMap { row in
            guard let id = row["id"] as? String,
                  let buildingId = row["building_id"] as? String,
                  let localPath = row["local_path"] as? String,
                  let createdAt = row["created_at"] as? String,
                  let date = ISO8601DateFormatter().date(from: createdAt) else {
                return nil
            }
            
            return FrancoBuildingPhoto(
                id: id,
                buildingId: buildingId,
                category: FrancoPhotoCategory(rawValue: row["category"] as? String ?? "") ?? .all,
                timestamp: date,
                uploadedBy: row["worker_id"] as? String,
                notes: row["notes"] as? String,
                localPath: localPath,
                remotePath: row["remote_url"] as? String,
                thumbnailPath: row["thumbnail_path"] as? String,
                hasIssue: (row["has_issue"] as? Int ?? 0) == 1,
                isVerified: (row["is_verified"] as? Int ?? 0) == 1,
                hasLocation: row["location_lat"] != nil,
                location: nil,
                taskId: row["task_id"] as? String,
                fileSize: row["file_size"] as? Int
            )
        }
    }
    
    func savePhoto(_ image: UIImage, metadata: FrancoBuildingPhotoMetadata) async throws -> FrancoBuildingPhoto {
        let photoId = UUID().uuidString
        let fileName = "\(photoId).jpg"
        
        // Create directory structure: /Evidence/YYYY/MM/DD/building_XX/
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        let datePath = dateFormatter.string(from: metadata.timestamp)
        
        let photoDirectory = documentsDirectory
            .appendingPathComponent("Evidence")
            .appendingPathComponent(datePath)
            .appendingPathComponent("building_\(metadata.buildingId)")
        
        try FileManager.default.createDirectory(at: photoDirectory, withIntermediateDirectories: true)
        
        // Save full image
        let filePath = photoDirectory.appendingPathComponent(fileName)
        guard let imageData = image.jpegData(compressionQuality: compressionQuality) else {
            throw FrancoPhotoError.compressionFailed
        }
        try imageData.write(to: filePath)
        
        // Create thumbnail
        let thumbnailPath = photoDirectory.appendingPathComponent("thumb_\(fileName)")
        if let thumbnail = image.preparingThumbnail(of: thumbnailSize),
           let thumbData = thumbnail.jpegData(compressionQuality: 0.5) {
            try thumbData.write(to: thumbnailPath)
        }
        
        // Save to database
        try await grdbManager.execute("""
            INSERT INTO photo_evidence (
                id, building_id, task_id, worker_id, 
                local_path, thumbnail_path, file_size,
                category, notes, has_issue, is_verified,
                location_lat, location_lon, created_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, [
            photoId,
            metadata.buildingId,
            metadata.taskId as Any,
            metadata.workerId as Any,
            filePath.path,
            thumbnailPath.path,
            imageData.count,
            metadata.category.rawValue,
            metadata.notes as Any,
            0, // has_issue
            0, // is_verified
            metadata.location?.coordinate.latitude as Any,
            metadata.location?.coordinate.longitude as Any,
            ISO8601DateFormatter().string(from: metadata.timestamp)
        ])
        
        return FrancoBuildingPhoto(
            id: photoId,
            buildingId: metadata.buildingId,
            category: metadata.category,
            timestamp: metadata.timestamp,
            uploadedBy: metadata.workerId,
            notes: metadata.notes,
            localPath: filePath.path,
            remotePath: nil,
            thumbnailPath: thumbnailPath.path,
            hasIssue: false,
            isVerified: false,
            hasLocation: metadata.location != nil,
            location: metadata.location,
            taskId: metadata.taskId,
            fileSize: imageData.count
        )
    }
    
    func loadThumbnail(for photoId: String) async -> UIImage? {
        let rows = try? await grdbManager.query(
            "SELECT thumbnail_path FROM photo_evidence WHERE id = ?",
            [photoId]
        )
        
        guard let path = rows?.first?["thumbnail_path"] as? String else { return nil }
        return UIImage(contentsOfFile: path)
    }
    
    func loadFullImage(for photoId: String) async -> UIImage? {
        let rows = try? await grdbManager.query(
            "SELECT local_path FROM photo_evidence WHERE id = ?",
            [photoId]
        )
        
        guard let path = rows?.first?["local_path"] as? String else { return nil }
        return UIImage(contentsOfFile: path)
    }
    
    func markPhotoAsIssue(_ photoId: String) async {
        try? await grdbManager.execute(
            "UPDATE photo_evidence SET has_issue = 1 WHERE id = ?",
            [photoId]
        )
    }
    
    func deletePhoto(_ photoId: String) async {
        // Get file paths
        let rows = try? await grdbManager.query(
            "SELECT local_path, thumbnail_path FROM photo_evidence WHERE id = ?",
            [photoId]
        )
        
        if let row = rows?.first {
            // Delete files
            if let path = row["local_path"] as? String {
                try? FileManager.default.removeItem(atPath: path)
            }
            if let thumbPath = row["thumbnail_path"] as? String {
                try? FileManager.default.removeItem(atPath: thumbPath)
            }
        }
        
        // Delete database record
        try? await grdbManager.execute(
            "DELETE FROM photo_evidence WHERE id = ?",
            [photoId]
        )
    }
}

// MARK: - Error Types

enum FrancoPhotoError: LocalizedError {
    case compressionFailed
    case saveFailed
    case loadFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .saveFailed:
            return "Failed to save photo"
        case .loadFailed:
            return "Failed to load photo"
        case .deleteFailed:
            return "Failed to delete photo"
        }
    }
}

// MARK: - Utility Room Support

struct FrancoUtilityRoomPhotoSection: View {
    let buildingId: String
    
    var body: some View {
        NavigationLink {
            FrancoBuildingPhotoGallery(buildingId: buildingId)
        } label: {
            HStack {
                Image(systemName: "photo.on.rectangle")
                    .font(.title2)
                    .foregroundColor(FrancoSphereDesign.DashboardColors.workerPrimary)
                
                VStack(alignment: .leading) {
                    Text("Building Photos")
                        .font(.headline)
                    Text("Document maintenance and issues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview Support

#Preview("Photo Gallery") {
    NavigationView {
        FrancoBuildingPhotoGallery(buildingId: "14")
    }
}

#Preview("Photo Capture") {
    FrancoBuildingPhotoCaptureView(buildingId: "14") { _ in }
}
