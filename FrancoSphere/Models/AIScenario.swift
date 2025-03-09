import Foundation
import SwiftUI

enum AIScenario: Equatable {
    case routineIncomplete
    case missingPhoto
    case clockOutReminder
    case pendingTasks
    case weatherAlert
    
    var title: String {
        switch self {
        case .routineIncomplete:
            return "Incomplete Tasks"
        case .missingPhoto:
            return "Photo Required"
        case .clockOutReminder:
            return "Clock Out Reminder"
        case .pendingTasks:
            return "Pending Tasks"
        case .weatherAlert:
            return "Weather Alert"
        }
    }
    
    var message: String {
        switch self {
        case .routineIncomplete:
            return "You have incomplete routine tasks that need attention."
        case .missingPhoto:
            return "Task requires photo verification before completion."
        case .clockOutReminder:
            return "Don't forget to clock out before leaving the building."
        case .pendingTasks:
            return "You have tasks scheduled for today that need completion."
        case .weatherAlert:
            return "Weather conditions may impact today's maintenance tasks."
        }
    }
    
    var systemIcon: String {
        switch self {
        case .routineIncomplete: return "checklist"
        case .missingPhoto: return "camera"
        case .clockOutReminder: return "clock"
        case .pendingTasks: return "exclamationmark.bubble"
        case .weatherAlert: return "cloud.rain"
        }
    }
    
    var actionText: String {
        switch self {
        case .routineIncomplete: return "View Tasks"
        case .missingPhoto: return "Take Photo"
        case .clockOutReminder: return "Clock Out"
        case .pendingTasks: return "View Tasks"
        case .weatherAlert: return "Check Weather"
        }
    }
    
    var color: Color {
        switch self {
        case .routineIncomplete: return .blue
        case .missingPhoto: return .orange
        case .clockOutReminder: return .red
        case .pendingTasks: return .green
        case .weatherAlert: return .purple
        }
    }
}
