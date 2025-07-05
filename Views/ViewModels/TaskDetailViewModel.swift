//
//  TaskDetailViewModel.swift
//  FrancoSphere
//

import SwiftUI
import Combine
import CoreLocation

@MainActor
class TaskDetailViewModel: ObservableObject {
    @Published var task: ContextualTask
    @Published var isCompleting = false
    @Published var completionNotes = ""
    @Published var capturedPhotos: [UIImage] = []
    @Published var showCamera = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var evidence: TaskEvidence?
    @Published var weather: WeatherData?
    @Published var isSubmitting = false
    
    private let taskService = TaskService.shared
    private let contextEngine = WorkerContextEngine.shared
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(task: ContextualTask) {
        self.task = task
        setupBindings()
        loadWeatherData()
    }
    
    func completeTask() async {
        guard !isSubmitting else { return }
        
        isSubmitting = true
        
        do {
            let photoData = capturedPhotos.compactMap { $0.jpegData(compressionQuality: 0.8) }
            let currentLocation = getCurrentLocation()
            
            let taskEvidence = TaskEvidence(
                photos: photoData,
                timestamp: Date(),
                location: currentLocation,
                notes: completionNotes.isEmpty ? nil : completionNotes
            )
            
            let workerId = NewAuthManager.shared.workerId
        guard !workerId.isEmpty else {
                throw TaskError.noWorkerID
            }
            
            try await taskService.completeTask(
                task.id,
                workerId: workerId,
                buildingId: task.buildingId,
                evidence: taskEvidence
            )
            
            // Update local task status
            task.status = "completed"
            task.completedAt = Date()
            
        } catch {
            errorMessage = "Failed to complete task: \(error.localizedDescription)"
            showError = true
        }
        
        isSubmitting = false
    }
    
    func addPhoto(_ image: UIImage) {
        capturedPhotos.append(image)
    }
    
    func removePhoto(at index: Int) {
        guard index < capturedPhotos.count else { return }
        capturedPhotos.remove(at: index)
    }
    
    private func setupBindings() {
        // Use context engine for weather data instead of direct WeatherManager
        contextEngine.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadWeatherData()
            }
            .store(in: &cancellables)
    }
    
    private func loadWeatherData() {
        // Get weather data from context engine
        if let weatherData = contextEngine.getCurrentWeather() {
            self.weather = weatherData
        }
    }
    
    private func getCurrentLocation() -> CLLocation? {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            return nil
        }
        
        return locationManager.location
    }
    
    private func getWeatherImpact() -> String {
        guard let weather = weather else { return "Weather data unavailable" }
        
        switch weather.condition {
        case .clear, .sunny:
            return "Perfect conditions for outdoor work"
        case .cloudy:
            return "Good conditions, overcast sky"
        case .rain, .rainy:
            return "Wet conditions - take extra precautions"
        case .snow, .snowy:
            return "Snowy conditions - be careful on walkways"
        case .fog, .foggy:
            return "Low visibility - exercise caution"
        case .storm, .stormy, .windy:
            return "Severe weather - consider postponing outdoor tasks"
        default:
            break
        }
    }
}

enum TaskError: LocalizedError {
    case noWorkerID
    case invalidTask
    case submissionFailed
    
    var errorDescription: String? {
        switch self {
        case .noWorkerID:
            return "No worker ID available"
        case .invalidTask:
            return "Invalid task data"
        case .submissionFailed:
            return "Failed to submit task completion"
        default:
            break
        }
    }
}
