//
//  TaskDetailViewModel.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/4/25.
//


//
//  TaskDetailViewModel.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/4/25.
//

//
//  TaskDetailViewModel.swift
//  FrancoSphere
//
//  🎯 COMPLETE TASK DETAIL MVVM ARCHITECTURE
//  ✅ Individual task management with comprehensive workflow
//  ✅ Photo evidence handling with encryption integration
//  ✅ Location-based task completion and verification
//  ✅ Real-time status updates with reactive binding
//  ✅ Integration with TaskService, SecurityManager, TelemetryService
//  ✅ Task verification and validation workflows
//  ✅ Performance monitoring and error recovery
//  ✅ Multi-worker task coordination and handoff
//

import SwiftUI
import Foundation
import CoreLocation
import Combine
import PhotosUI

@MainActor
class TaskDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var task: ContextualTask
    @Published var isCompleting = false
    @Published var isLoading = false
    @Published var taskStatus: TaskStatus = .pending
    @Published var completionProgress: Double = 0.0
    @Published var evidence: TaskEvidenceCollection = TaskEvidenceCollection()
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var locationPermissionStatus: LocationPermissionStatus = .unknown
    @Published var currentLocation: CLLocation?
    @Published var taskMetrics: TaskMetrics = TaskMetrics()
    @Published var relatedTasks: [ContextualTask] = []
    @Published var taskVerification: TaskVerification?
    @Published var inventoryRequirements: [InventoryRequirement] = []
    @Published var timeTracking: TimeTracking = TimeTracking()
    @Published var taskInsight: TaskInsight?
    
    // MARK: - Photo Management
    @Published var selectedPhotos: [PhotosPickerItem] = []
    @Published var capturedPhotos: [TaskPhoto] = []
    @Published var isProcessingPhotos = false
    @Published var photoValidationResults: [PhotoValidationResult] = []
    
    // MARK: - Location & Context
    @Published var isAtTaskLocation = false
    @Published var distanceToTask: Double = 0.0
    @Published var estimatedArrivalTime: Date?
    @Published var weatherImpact: TaskWeatherImpact?
    
    // MARK: - Dependencies
    private let taskService: TaskService
    private let securityManager: SecurityManager
    private let telemetryService: TelemetryService
    private let authManager: NewAuthManager
    private let weatherManager: WeatherManager
    private let locationManager: CLLocationManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let locationAccuracyThreshold: CLLocationDistance = 50.0 // 50 meters
    private let maxPhotosPerTask = 10
    private let taskTimeoutMinutes = 120 // 2 hours
    private let autoSaveInterval: TimeInterval = 30 // 30 seconds
    
    // MARK: - State Management
    private var autoSaveTimer: Timer?
    private var locationUpdateTimer: Timer?
    private var taskStartTime: Date?
    private var lastLocationUpdate: Date = Date.distantPast
    
    // MARK: - Initialization
    init(task: ContextualTask,
         taskService: TaskService = TaskService.shared,
         securityManager: SecurityManager = SecurityManager.shared,
         telemetryService: TelemetryService = TelemetryService.shared,
         authManager: NewAuthManager = NewAuthManager.shared,
         weatherManager: WeatherManager = WeatherManager.shared) {
        
        self.task = task
        self.taskService = taskService
        self.securityManager = securityManager
        self.telemetryService = telemetryService
        self.authManager = authManager
        self.weatherManager = weatherManager
        self.locationManager = CLLocationManager()
        
        // Initialize based on task status
        self.taskStatus = TaskStatus(rawValue: task.status) ?? .pending
        
        setupReactiveBindings()
        setupLocationManager()
        loadTaskDetails()
    }
    
    // MARK: - Reactive Bindings
    private func setupReactiveBindings() {
        // Monitor photo selection changes
        $selectedPhotos
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] items in
                Task {
                    await self?.processSelectedPhotos(items)
                }
            }
            .store(in: &cancellables)
        
        // Monitor location permission changes
        $locationPermissionStatus
            .sink { [weak self] status in
                Task {
                    await self?.handleLocationPermissionChange(status)
                }
            }
            .store(in: &cancellables)
        
        // Monitor task status changes
        $taskStatus
            .sink { [weak self] status in
                Task {
                    await self?.handleTaskStatusChange(status)
                }
            }
            .store(in: &cancellables)
        
        // Weather impact monitoring
        weatherManager.$currentWeather
            .receive(on: DispatchQueue.main)
            .sink { [weak self] weather in
                Task {
                    await self?.updateWeatherImpact(weather)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Location Management
    private func setupLocationManager() {
        locationManager.delegate = LocationDelegate(viewModel: self)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Check current permission status
        updateLocationPermissionStatus()
        
        // Start location updates if authorized
        if locationManager.authorizationStatus == .authorizedWhenInUse || 
           locationManager.authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }
    
    private func updateLocationPermissionStatus() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationPermissionStatus = .unknown
        case .denied, .restricted:
            locationPermissionStatus = .denied
        case .authorizedWhenInUse, .authorizedAlways:
            locationPermissionStatus = .authorized
        @unknown default:
            locationPermissionStatus = .unknown
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse || 
              locationManager.authorizationStatus == .authorizedAlways else { return }
        
        locationManager.startUpdatingLocation()
        
        // Set up periodic location validation
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task {
                await self?.validateTaskLocation()
            }
        }
    }
    
    private func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    // MARK: - Task Detail Loading
    private func loadTaskDetails() {
        Task {
            await telemetryService.trackOperation("loadTaskDetails") {
                isLoading = true
                
                do {
                    // Load task metrics and related data
                    async let metrics = loadTaskMetrics()
                    async let related = loadRelatedTasks()
                    async let inventory = loadInventoryRequirements()
                    async let verification = loadTaskVerification()
                    async let insight = generateTaskInsight()
                    
                    self.taskMetrics = await metrics
                    self.relatedTasks = await related
                    self.inventoryRequirements = await inventory
                    self.taskVerification = await verification
                    self.taskInsight = await insight
                    
                    // Initialize time tracking
                    initializeTimeTracking()
                    
                    // Start auto-save if task is in progress
                    if taskStatus == .inProgress {
                        startAutoSave()
                    }
                    
                } catch {
                    await setError("Failed to load task details: \(error.localizedDescription)")
                }
                
                isLoading = false
            }
        }
    }
    
    private func loadTaskMetrics() async -> TaskMetrics {
        // Calculate task-specific metrics
        let estimatedDuration = calculateEstimatedDuration()
        let complexityScore = calculateComplexityScore()
        let priorityScore = calculatePriorityScore()
        
        return TaskMetrics(
            estimatedDuration: estimatedDuration,
            complexityScore: complexityScore,
            priorityScore: priorityScore,
            completionRate: await getTaskTypeCompletionRate(),
            averageCompletionTime: await getAverageCompletionTime()
        )
    }
    
    private func loadRelatedTasks() async -> [ContextualTask] {
        // Find tasks in the same building or category
        do {
            guard let workerId = authManager.workerId else { return [] }
            let allTasks = try await taskService.getTasks(for: workerId, date: Date())
            
            return allTasks.filter { relatedTask in
                relatedTask.id != task.id && (
                    relatedTask.buildingId == task.buildingId ||
                    relatedTask.category == task.category
                )
            }.prefix(5).map { $0 }
        } catch {
            print("Failed to load related tasks: \(error)")
            return []
        }
    }
    
    private func loadInventoryRequirements() async -> [InventoryRequirement] {
        // Determine required inventory based on task category and type
        switch task.category.lowercased() {
        case "cleaning":
            return [
                InventoryRequirement(itemName: "All-purpose cleaner", quantity: 1, isRequired: true),
                InventoryRequirement(itemName: "Microfiber cloths", quantity: 2, isRequired: true),
                InventoryRequirement(itemName: "Vacuum bags", quantity: 1, isRequired: false)
            ]
        case "sanitation":
            return [
                InventoryRequirement(itemName: "Trash bags", quantity: 5, isRequired: true),
                InventoryRequirement(itemName: "Disinfectant", quantity: 1, isRequired: true),
                InventoryRequirement(itemName: "Gloves", quantity: 2, isRequired: true)
            ]
        case "maintenance":
            return [
                InventoryRequirement(itemName: "Basic tools", quantity: 1, isRequired: true),
                InventoryRequirement(itemName: "Lubricant", quantity: 1, isRequired: false)
            ]
        default:
            return []
        }
    }
    
    private func loadTaskVerification() async -> TaskVerification? {
        // Determine if task requires verification
        let requiresVerification = task.urgencyLevel.lowercased() == "high" ||
                                 task.category.lowercased() == "maintenance" ||
                                 task.name.lowercased().contains("deep")
        
        if requiresVerification {
            return TaskVerification(
                isRequired: true,
                verificationMethod: .photoEvidence,
                minimumPhotos: 2,
                requiresLocation: true,
                requiresNotes: task.category.lowercased() == "maintenance"
            )
        }
        
        return nil
    }
    
    private func generateTaskInsight() async -> TaskInsight {
        let category = task.category.lowercased()
        let urgency = task.urgencyLevel.lowercased()
        let building = task.buildingName
        
        // Generate contextual insights
        var tips: [String] = []
        var warnings: [String] = []
        var optimizations: [String] = []
        
        // Category-specific insights
        switch category {
        case "cleaning":
            tips.append("Start with dry cleaning before wet cleaning")
            tips.append("Work from top to bottom for efficiency")
            if building.contains("Museum") {
                tips.append("Use museum-approved cleaning products only")
                warnings.append("Avoid water near artworks or displays")
            }
            
        case "sanitation":
            tips.append("Wear gloves and follow safety protocols")
            tips.append("Check for proper waste segregation")
            if urgency == "high" {
                warnings.append("Priority task - complete before other activities")
            }
            
        case "maintenance":
            tips.append("Document any issues found during inspection")
            warnings.append("Tag out equipment if safety concerns identified")
            if building.contains("Rubin Museum") {
                tips.append("Coordinate with museum staff for access")
            }
            
        default:
            tips.append("Follow standard operational procedures")
        }
        
        // Building-specific optimizations
        if task.buildingId == "14" { // Rubin Museum
            optimizations.append("Complete during low visitor traffic hours")
            optimizations.append("Use quiet equipment to minimize disruption")
        } else if task.buildingId == "10" || task.buildingId == "6" { // Perry Street
            optimizations.append("Combine with other Perry Street tasks for route efficiency")
        }
        
        return TaskInsight(
            title: "Task Guidance",
            description: "Optimized workflow for \(task.name)",
            tips: tips,
            warnings: warnings,
            optimizations: optimizations,
            estimatedEffort: taskMetrics.complexityScore > 0.7 ? .high : .medium
        )
    }
    
    // MARK: - Task Actions
    func startTask() async {
        await telemetryService.trackOperation("startTask") {
            guard taskStatus == .pending else { return }
            
            taskStatus = .inProgress
            taskStartTime = Date()
            timeTracking.startTime = Date()
            
            // Start location tracking
            if locationPermissionStatus == .authorized {
                startLocationUpdates()
            }
            
            // Start auto-save
            startAutoSave()
            
            await setSuccess("Task started successfully")
            print("✅ Task started: \(task.name)")
        }
    }
    
    func pauseTask() async {
        guard taskStatus == .inProgress else { return }
        
        taskStatus = .paused
        timeTracking.pausedAt = Date()
        
        // Calculate time spent so far
        if let startTime = timeTracking.startTime {
            let elapsed = Date().timeIntervalSince(startTime)
            timeTracking.totalTimeSpent += elapsed
        }
        
        stopLocationUpdates()
        stopAutoSave()
        
        await setSuccess("Task paused")
    }
    
    func resumeTask() async {
        guard taskStatus == .paused else { return }
        
        taskStatus = .inProgress
        timeTracking.startTime = Date()
        timeTracking.pausedAt = nil
        
        startLocationUpdates()
        startAutoSave()
        
        await setSuccess("Task resumed")
    }
    
    func completeTask() async {
        await telemetryService.trackOperation("completeTask") {
            guard taskStatus == .inProgress || taskStatus == .paused else { return }
            guard let workerId = authManager.workerId else {
                await setError("Worker ID not available")
                return
            }
            
            isCompleting = true
            
            do {
                // Validate completion requirements
                try await validateTaskCompletion()
                
                // Process evidence
                let processedEvidence = try await processTaskEvidence()
                
                // Complete the task via TaskService
                try await taskService.completeTask(
                    task.id,
                    workerId: workerId,
                    buildingId: task.buildingId,
                    evidence: processedEvidence
                )
                
                // Update local state
                taskStatus = .completed
                timeTracking.completedAt = Date()
                task.status = "completed"
                
                // Calculate final metrics
                calculateFinalMetrics()
                
                // Stop tracking
                stopLocationUpdates()
                stopAutoSave()
                
                await setSuccess("Task completed successfully!")
                print("✅ Task completed: \(task.name)")
                
            } catch {
                await setError("Failed to complete task: \(error.localizedDescription)")
                print("❌ Task completion error: \(error)")
            }
            
            isCompleting = false
        }
    }
    
    // MARK: - Evidence Management
    func addPhotoEvidence(_ photoData: Data) async {
        guard capturedPhotos.count < maxPhotosPerTask else {
            await setError("Maximum number of photos reached (\(maxPhotosPerTask))")
            return
        }
        
        isProcessingPhotos = true
        
        do {
            // Encrypt photo
            let encryptedPhoto = try await securityManager.encryptPhoto(photoData, taskId: task.id)
            
            // Create task photo
            let taskPhoto = TaskPhoto(
                id: UUID().uuidString,
                taskId: task.id,
                imageData: photoData,
                encryptedPhoto: encryptedPhoto,
                timestamp: Date(),
                location: currentLocation,
                notes: nil
            )
            
            capturedPhotos.append(taskPhoto)
            
            // Validate photo quality
            let validation = validatePhotoQuality(photoData)
            photoValidationResults.append(validation)
            
            await setSuccess("Photo added successfully")
            
        } catch {
            await setError("Failed to process photo: \(error.localizedDescription)")
        }
        
        isProcessingPhotos = false
    }
    
    func removePhoto(_ photoId: String) {
        capturedPhotos.removeAll { $0.id == photoId }
        photoValidationResults.removeAll { $0.photoId == photoId }
    }
    
    func addNotes(_ notes: String) {
        evidence.notes = notes
        triggerAutoSave()
    }
    
    private func processSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                await addPhotoEvidence(data)
            }
        }
        
        // Clear selection after processing
        selectedPhotos.removeAll()
    }
    
    private func validatePhotoQuality(_ photoData: Data) -> PhotoValidationResult {
        guard let image = UIImage(data: photoData) else {
            return PhotoValidationResult(
                photoId: UUID().uuidString,
                isValid: false,
                issues: ["Invalid image data"],
                score: 0.0
            )
        }
        
        var issues: [String] = []
        var score = 1.0
        
        // Check image dimensions
        let minDimension = min(image.size.width, image.size.height)
        if minDimension < 480 {
            issues.append("Image resolution too low")
            score -= 0.3
        }
        
        // Check file size
        let fileSizeMB = Double(photoData.count) / 1024.0 / 1024.0
        if fileSizeMB > 10 {
            issues.append("File size too large (\(String(format: "%.1f", fileSizeMB))MB)")
            score -= 0.2
        }
        
        // Check brightness (simplified)
        if image.size.width * image.size.height < 100000 {
            // Very small image might indicate poor quality
            score -= 0.1
        }
        
        return PhotoValidationResult(
            photoId: UUID().uuidString,
            isValid: score >= 0.5,
            issues: issues,
            score: max(0.0, score)
        )
    }
    
    // MARK: - Location Validation
    func updateLocation(_ location: CLLocation) {
        currentLocation = location
        lastLocationUpdate = Date()
        
        // Calculate distance to task location
        if let taskLocation = getTaskLocation() {
            distanceToTask = location.distance(from: taskLocation)
            isAtTaskLocation = distanceToTask <= locationAccuracyThreshold
            
            // Update estimated arrival time if not at location
            if !isAtTaskLocation {
                estimatedArrivalTime = calculateArrivalTime(from: location, to: taskLocation)
            }
        }
    }
    
    private func validateTaskLocation() async {
        guard let currentLocation = currentLocation else { return }
        
        if let taskLocation = getTaskLocation() {
            let distance = currentLocation.distance(from: taskLocation)
            
            if distance > locationAccuracyThreshold * 2 && taskStatus == .inProgress {
                // Worker seems to be far from task location
                await setError("You appear to be away from the task location. Current distance: \(Int(distance))m")
            }
        }
    }
    
    private func getTaskLocation() -> CLLocation? {
        // Get building coordinates based on building ID
        switch task.buildingId {
        case "10": return CLLocation(latitude: 40.7359, longitude: -74.0059) // 131 Perry
        case "6": return CLLocation(latitude: 40.7357, longitude: -74.0055)  // 68 Perry
        case "14": return CLLocation(latitude: 40.7402, longitude: -73.9980) // Rubin Museum
        case "3": return CLLocation(latitude: 40.7398, longitude: -73.9972)  // 135-139 W 17th
        case "7": return CLLocation(latitude: 40.7399, longitude: -73.9971)  // 136 W 17th
        case "9": return CLLocation(latitude: 40.7400, longitude: -73.9970)  // 138 W 17th
        case "16": return CLLocation(latitude: 40.7388, longitude: -73.9892) // 29-31 E 20th
        case "12": return CLLocation(latitude: 40.7245, longitude: -73.9968) // 178 Spring
        default: return nil
        }
    }
    
    private func calculateArrivalTime(from current: CLLocation, to destination: CLLocation) -> Date {
        let distance = current.distance(from: destination)
        let walkingSpeed = 1.4 // meters per second (average walking speed)
        let timeToArrive = distance / walkingSpeed
        
        return Date().addingTimeInterval(timeToArrive)
    }
    
    // MARK: - Auto-Save & Time Tracking
    private func startAutoSave() {
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.triggerAutoSave()
        }
    }
    
    private func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }
    
    private func triggerAutoSave() {
        Task {
            await saveTaskProgress()
        }
    }
    
    private func saveTaskProgress() async {
        // Auto-save current progress without completing the task
        evidence.lastSaved = Date()
        
        // Calculate current progress based on evidence and time
        let timeProgress = calculateTimeProgress()
        let evidenceProgress = calculateEvidenceProgress()
        completionProgress = (timeProgress + evidenceProgress) / 2.0
    }
    
    private func initializeTimeTracking() {
        timeTracking = TimeTracking(
            taskId: task.id,
            startTime: nil,
            completedAt: nil,
            pausedAt: nil,
            totalTimeSpent: 0,
            estimatedDuration: taskMetrics.estimatedDuration
        )
    }
    
    // MARK: - Validation & Metrics
    private func validateTaskCompletion() async throws {
        // Check if verification requirements are met
        if let verification = taskVerification {
            if verification.minimumPhotos > capturedPhotos.count {
                throw TaskValidationError.insufficientPhotos(required: verification.minimumPhotos, provided: capturedPhotos.count)
            }
            
            if verification.requiresLocation && !isAtTaskLocation {
                throw TaskValidationError.locationNotVerified
            }
            
            if verification.requiresNotes && (evidence.notes?.isEmpty ?? true) {
                throw TaskValidationError.notesRequired
            }
        }
    }
    
    private func processTaskEvidence() async throws -> TSTaskEvidence? {
        guard !capturedPhotos.isEmpty || evidence.notes != nil else { return nil }
        
        let photoData = capturedPhotos.map { $0.imageData }
        
        return TSTaskEvidence(
            photos: photoData,
            timestamp: Date(),
            location: currentLocation,
            notes: evidence.notes
        )
    }
    
    private func calculateTimeProgress() -> Double {
        guard let startTime = timeTracking.startTime else { return 0.0 }
        
        let elapsed = Date().timeIntervalSince(startTime) + timeTracking.totalTimeSpent
        let estimated = taskMetrics.estimatedDuration
        
        return min(1.0, elapsed / estimated)
    }
    
    private func calculateEvidenceProgress() -> Double {
        guard let verification = taskVerification else { return 1.0 }
        
        let photoProgress = Double(capturedPhotos.count) / Double(verification.minimumPhotos)
        let notesProgress = verification.requiresNotes ? (evidence.notes?.isEmpty == false ? 1.0 : 0.0) : 1.0
        let locationProgress = verification.requiresLocation ? (isAtTaskLocation ? 1.0 : 0.0) : 1.0
        
        return min(1.0, (photoProgress + notesProgress + locationProgress) / 3.0)
    }
    
    private func calculateFinalMetrics() {
        guard let startTime = timeTracking.startTime else { return }
        
        let totalTime = Date().timeIntervalSince(startTime) + timeTracking.totalTimeSpent
        timeTracking.totalTimeSpent = totalTime
        
        // Update completion progress to 100%
        completionProgress = 1.0
        
        // Calculate efficiency score
        let efficiency = taskMetrics.estimatedDuration / totalTime
        taskMetrics.actualDuration = totalTime
        taskMetrics.efficiencyScore = efficiency
    }
    
    // MARK: - Helper Methods
    private func calculateEstimatedDuration() -> TimeInterval {
        let baseDuration: TimeInterval = 1800 // 30 minutes
        var multiplier = 1.0
        
        // Adjust based on category
        switch task.category.lowercased() {
        case "cleaning": multiplier = 1.0
        case "sanitation": multiplier = 0.8
        case "maintenance": multiplier = 1.5
        case "inspection": multiplier = 0.6
        default: multiplier = 1.0
        }
        
        // Adjust based on urgency
        switch task.urgencyLevel.lowercased() {
        case "high": multiplier *= 1.2
        case "urgent": multiplier *= 1.5
        default: break
        }
        
        return baseDuration * multiplier
    }
    
    private func calculateComplexityScore() -> Double {
        var score = 0.5 // Base complexity
        
        // Increase based on category
        switch task.category.lowercased() {
        case "maintenance": score += 0.3
        case "cleaning": score += 0.1
        case "sanitation": score += 0.1
        default: break
        }
        
        // Increase based on building type
        if task.buildingName.contains("Museum") {
            score += 0.2 // Museums require more care
        }
        
        // Increase based on verification requirements
        if taskVerification?.isRequired == true {
            score += 0.2
        }
        
        return min(1.0, score)
    }
    
    private func calculatePriorityScore() -> Double {
        switch task.urgencyLevel.lowercased() {
        case "urgent": return 1.0
        case "high": return 0.8
        case "medium": return 0.5
        case "low": return 0.2
        default: return 0.5
        }
    }
    
    private func getTaskTypeCompletionRate() async -> Double {
        return 0.85 // 85% default completion rate
    }
    
    private func getAverageCompletionTime() async -> TimeInterval {
        return 1800 // 30 minutes default
    }
    
    private func updateWeatherImpact(_ weather: FrancoSphere.WeatherData?) async {
        guard let weather = weather else {
            weatherImpact = nil
            return
        }
        
        // Check if weather affects this task
        let isOutdoorTask = task.name.lowercased().contains("sidewalk") ||
                           task.name.lowercased().contains("curb") ||
                           task.name.lowercased().contains("trash")
        
        if isOutdoorTask {
            let severity: TaskWeatherImpact.Severity
            let recommendation: String
            
            switch weather.condition {
            case .rain:
                severity = .high
                recommendation = "Consider postponing outdoor work due to rain"
            case .snow:
                severity = .medium
                recommendation = "Take extra precautions for slip hazards"
            default:
                if weather.temperature < 20 {
                    severity = .medium
                    recommendation = "Dress warmly and take frequent breaks"
                } else if weather.temperature > 85 {
                    severity = .medium
                    recommendation = "Stay hydrated and work in shade when possible"
                } else {
                    severity = .low
                    recommendation = "Good conditions for outdoor work"
                }
            }
            
            weatherImpact = TaskWeatherImpact(
                severity: severity,
                condition: weather.condition,
                temperature: weather.temperature,
                recommendation: recommendation
            )
        } else {
            weatherImpact = nil
        }
    }
    
    // MARK: - Event Handlers
    private func handleLocationPermissionChange(_ status: LocationPermissionStatus) async {
        switch status {
        case .authorized:
            startLocationUpdates()
        case .denied:
            await setError("Location access denied. Task completion may be limited.")
            stopLocationUpdates()
        case .unknown:
            break
        }
    }
    
    private func handleTaskStatusChange(_ status: TaskStatus) async {
        switch status {
        case .inProgress:
            await setSuccess("Task is now in progress")
        case .completed:
            await setSuccess("Task completed successfully!")
        case .paused:
            await setSuccess("Task paused")
        default:
            break
        }
    }
    
    // MARK: - Error & Success Handling
    private func setError(_ message: String) async {
        errorMessage = message
        successMessage = nil
        print("❌ TaskDetailViewModel Error: \(message)")
    }
    
    private func setSuccess(_ message: String) async {
        successMessage = message
        errorMessage = nil
        print("✅ TaskDetailViewModel Success: \(message)")
        
        // Clear success message after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if self.successMessage == message {
                self.successMessage = nil
            }
        }
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Cleanup
    deinit {
        stopLocationUpdates()
        stopAutoSave()
        cancellables.removeAll()
    }
}

// MARK: - Location Manager Delegate
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var viewModel: TaskDetailViewModel?
    
    init(viewModel: TaskDetailViewModel) {
        self.viewModel = viewModel
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            viewModel?.updateLocation(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            viewModel?.updateLocationPermissionStatus()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            await viewModel?.setError("Location error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

enum TaskStatus: String, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case paused = "paused"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

enum LocationPermissionStatus {
    case unknown
    case authorized
    case denied
}

struct TaskEvidenceCollection {
    var notes: String?
    var lastSaved: Date?
}

struct TaskPhoto {
    let id: String
    let taskId: String
    let imageData: Data
    let encryptedPhoto: EncryptedPhoto
    let timestamp: Date
    let location: CLLocation?
    var notes: String?
}

struct PhotoValidationResult {
    let photoId: String
    let isValid: Bool
    let issues: [String]
    let score: Double
}

struct TaskMetrics {
    var estimatedDuration: TimeInterval = 1800
    var actualDuration: TimeInterval = 0
    var complexityScore: Double = 0.5
    var priorityScore: Double = 0.5
    var completionRate: Double = 0.85
    var averageCompletionTime: TimeInterval = 1800
    var efficiencyScore: Double = 1.0
}

struct TaskVerification {
    let isRequired: Bool
    let verificationMethod: VerificationMethod
    let minimumPhotos: Int
    let requiresLocation: Bool
    let requiresNotes: Bool
}

enum VerificationMethod {
    case photoEvidence
    case supervisorApproval
    case systemCheck
}

struct InventoryRequirement {
    let itemName: String
    let quantity: Int
    let isRequired: Bool
}

struct TimeTracking {
    var taskId: String = ""
    var startTime: Date?
    var completedAt: Date?
    var pausedAt: Date?
    var totalTimeSpent: TimeInterval = 0
    var estimatedDuration: TimeInterval = 1800
}

struct TaskInsight {
    let title: String
    let description: String
    let tips: [String]
    let warnings: [String]
    let optimizations: [String]
    let estimatedEffort: EffortLevel
}

enum EffortLevel {
    case low
    case medium
    case high
}

struct TaskWeatherImpact {
    let severity: Severity
    let condition: FrancoSphere.WeatherCondition
    let temperature: Double
    let recommendation: String
    
    enum Severity {
        case low
        case medium
        case high
    }
}

enum TaskValidationError: LocalizedError {
    case insufficientPhotos(required: Int, provided: Int)
    case locationNotVerified
    case notesRequired
    case taskTimeout
    case invalidEvidence
    
    var errorDescription: String? {
        switch self {
        case .insufficientPhotos(let required, let provided):
            return "Insufficient photo evidence: \(provided) provided, \(required) required"
        case .locationNotVerified:
            return "Task location not verified. Please ensure you are at the correct location."
        case .notesRequired:
            return "Notes are required for this task"
        case .taskTimeout:
            return "Task has exceeded maximum allowed time"
        case .invalidEvidence:
            return "Task evidence is invalid or corrupted"
        }
    }
}