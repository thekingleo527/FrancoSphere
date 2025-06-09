//
//  HapticManager.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 6/8/25.
//


//
//  HapticManager.swift
//  FrancoSphere
//
//  Manages haptic feedback throughout the app
//

import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}