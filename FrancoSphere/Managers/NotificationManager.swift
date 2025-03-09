import Foundation
import Combine
import UserNotifications

// MARK: - Notification Models

/// FrancoSphere notification model
struct FSNotification: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let message: String
    let date: Date
    let isRead: Bool
    let type: NotificationType
    let relatedBuildingId: String?
    let relatedTaskId: String?
    let relatedWorkerId: String?
    let requiresAction: Bool
    let actionTaken: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, title, message, date, isRead, type, relatedBuildingId, relatedTaskId, relatedWorkerId, requiresAction, actionTaken
    }
    
    init(id: String = UUID().uuidString,
         title: String,
         message: String,
         date: Date = Date(),
         isRead: Bool = false,
         type: NotificationType,
         relatedBuildingId: String? = nil,
         relatedTaskId: String? = nil,
         relatedWorkerId: String? = nil,
         requiresAction: Bool = false,
         actionTaken: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.date = date
        self.isRead = isRead
        self.type = type
        self.relatedBuildingId = relatedBuildingId
        self.relatedTaskId = relatedTaskId
        self.relatedWorkerId = relatedWorkerId
        self.requiresAction = requiresAction
        self.actionTaken = actionTaken
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case task = "Task"
    case maintenance = "Maintenance"
    case weather = "Weather"
    case inventory = "Inventory"
    case security = "Security"
    case system = "System"
    
    var icon: String {
        switch self {
        case .task: return "checklist"
        case .maintenance: return "wrench.and.screwdriver"
        case .weather: return "cloud.sun.rain"
        case .inventory: return "cube.box"
        case .security: return "lock.shield"
        case .system: return "gear"
        }
    }
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var notifications: [FSNotification] = []
    @Published var unreadCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        requestNotificationPermission()
        setupObservers()
        loadNotifications()
    }
    
    // MARK: - Notification Permission
    
    /// Request permission to send notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
            
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Notification Management
    
    /// Add a new notification
    func addNotification(
        title: String,
        message: String,
        type: NotificationType,
        buildingId: String? = nil,
        taskId: String? = nil,
        workerId: String? = nil,
        requiresAction: Bool = false,
        shouldSendLocalNotification: Bool = true
    ) {
        let notification = FSNotification(
            title: title,
            message: message,
            type: type,
            relatedBuildingId: buildingId,
            relatedTaskId: taskId,
            relatedWorkerId: workerId,
            requiresAction: requiresAction
        )
        
        notifications.insert(notification, at: 0)
        saveNotifications()
        updateUnreadCount()
        
        if shouldSendLocalNotification {
            sendLocalNotification(title: title, message: message, type: type)
        }
    }
    
    /// Mark a notification as read
    func markAsRead(id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            let notification = notifications[index]
            let updatedNotification = FSNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                date: notification.date,
                isRead: true,
                type: notification.type,
                relatedBuildingId: notification.relatedBuildingId,
                relatedTaskId: notification.relatedTaskId,
                relatedWorkerId: notification.relatedWorkerId,
                requiresAction: notification.requiresAction,
                actionTaken: notification.actionTaken
            )
            
            notifications[index] = updatedNotification
            saveNotifications()
            updateUnreadCount()
        }
    }
    
    /// Mark a notification as action taken
    func markActionTaken(id: String) {
        if let index = notifications.firstIndex(where: { $0.id == id }) {
            let notification = notifications[index]
            let updatedNotification = FSNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                date: notification.date,
                isRead: true,
                type: notification.type,
                relatedBuildingId: notification.relatedBuildingId,
                relatedTaskId: notification.relatedTaskId,
                relatedWorkerId: notification.relatedWorkerId,
                requiresAction: notification.requiresAction,
                actionTaken: true
            )
            
            notifications[index] = updatedNotification
            saveNotifications()
            updateUnreadCount()
        }
    }
    
    /// Delete a notification
    func deleteNotification(id: String) {
        notifications.removeAll { $0.id == id }
        saveNotifications()
        updateUnreadCount()
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
        saveNotifications()
        updateUnreadCount()
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        notifications = notifications.map { notification in
            FSNotification(
                id: notification.id,
                title: notification.title,
                message: notification.message,
                date: notification.date,
                isRead: true,
                type: notification.type,
                relatedBuildingId: notification.relatedBuildingId,
                relatedTaskId: notification.relatedTaskId,
                relatedWorkerId: notification.relatedWorkerId,
                requiresAction: notification.requiresAction,
                actionTaken: notification.actionTaken
            )
        }
        
        saveNotifications()
        updateUnreadCount()
    }
    
    /// Get notifications requiring action
    var actionableNotifications: [FSNotification] {
        return notifications.filter { $0.requiresAction && !$0.actionTaken }
    }
    
    /// Get unread notifications
    var unreadNotifications: [FSNotification] {
        return notifications.filter { !$0.isRead }
    }
    
    /// Get notifications by type
    func getNotifications(ofType type: NotificationType) -> [FSNotification] {
        return notifications.filter { $0.type == type }
    }
    
    /// Get notifications for a building
    func getNotifications(forBuilding buildingId: String) -> [FSNotification] {
        return notifications.filter { $0.relatedBuildingId == buildingId }
    }
    
    /// Get notifications for a task
    func getNotifications(forTask taskId: String) -> [FSNotification] {
        return notifications.filter { $0.relatedTaskId == taskId }
    }
    
    /// Get notifications for a worker
    func getNotifications(forWorker workerId: String) -> [FSNotification] {
        return notifications.filter { $0.relatedWorkerId == workerId }
    }
    
    // MARK: - Local Notifications
    
    /// Send a local notification
    private func sendLocalNotification(title: String, message: String, type: NotificationType) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        
        content.categoryIdentifier = type.rawValue
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending local notification: \(error)")
            }
        }
    }
    
    // MARK: - Persistence
    
    /// Save notifications to UserDefaults
    private func saveNotifications() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notifications)
            UserDefaults.standard.set(data, forKey: "storedNotifications")
        } catch {
            print("Error saving notifications: \(error)")
        }
    }
    
    /// Load notifications from UserDefaults
    private func loadNotifications() {
        if let data = UserDefaults.standard.data(forKey: "storedNotifications") {
            do {
                let decoder = JSONDecoder()
                notifications = try decoder.decode([FSNotification].self, from: data)
                updateUnreadCount()
            } catch {
                print("Error loading notifications: \(error)")
            }
        }
    }
    
    /// Update the unread notification count
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
        UNUserNotificationCenter.current().setBadgeCount(unreadCount)
    }
    
    // MARK: - Observers
    
    /// Set up notification observers
    private func setupObservers() {
        NotificationCenter.default.publisher(for: Notification.Name("TaskCompleted"))
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let taskId = userInfo["taskId"] as? String,
                      let taskName = userInfo["taskName"] as? String,
                      let buildingId = userInfo["buildingId"] as? String else {
                    return
                }
                
                self.addNotification(
                    title: "Task Completed",
                    message: "Task '\(taskName)' has been marked as completed.",
                    type: .task,
                    buildingId: buildingId,
                    taskId: taskId
                )
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("RestockRequestCreated"))
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let buildingId = userInfo["buildingId"] as? String,
                      let itemName = userInfo["itemName"] as? String else {
                    return
                }
                
                self.addNotification(
                    title: "Inventory Restock Needed",
                    message: "Item '\(itemName)' needs to be restocked.",
                    type: .inventory,
                    buildingId: buildingId,
                    requiresAction: true
                )
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("WeatherAlert"))
            .sink { [weak self] notification in
                guard let self = self,
                      let userInfo = notification.userInfo,
                      let buildingId = userInfo["buildingId"] as? String,
                      let alert = userInfo["alert"] as? String else {
                    return
                }
                
                self.addNotification(
                    title: "Weather Alert",
                    message: alert,
                    type: .weather,
                    buildingId: buildingId
                )
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Weather Notifications
    
    /// Generate weather-related notifications for a building
    func generateWeatherNotifications(for building: NamedCoordinate) {
        if let weatherAlert = WeatherService.shared.createWeatherNotification(for: building) {
            addNotification(
                title: "Weather Alert",
                message: weatherAlert,
                type: .weather,
                buildingId: building.id
            )
            
            NotificationCenter.default.post(
                name: Notification.Name("WeatherAlert"),
                object: nil,
                userInfo: [
                    "buildingId": building.id,
                    "alert": weatherAlert
                ]
            )
        }
        
        let wasteAdjustment = WeatherService.shared.shouldAdjustWasteCollection(for: building)
        if wasteAdjustment.shouldAdjust, let adjustedDate = wasteAdjustment.date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            let dateString = dateFormatter.string(from: adjustedDate)
            
            addNotification(
                title: "Waste Collection Schedule Change",
                message: "Due to weather conditions, waste collection for \(building.name) should be rescheduled to \(dateString).",
                type: .weather,
                buildingId: building.id,
                requiresAction: true
            )
        }
    }
}
