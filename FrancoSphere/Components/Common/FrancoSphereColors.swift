// FILE: Common/FrancoSphereColors.swift
//
//  FrancoSphereColors.swift
//  FrancoSphere
//
//  ✅ PHASE-2 COLORS - Complete color system
//  ✅ Used throughout the app for consistent theming
//

import SwiftUI
// FrancoSphere Types Import
// (This comment helps identify our import)

public enum FrancoSphereColors {
    // Primary backgrounds
    static let primaryBackground = Color(red: 0.07, green: 0.07, blue: 0.10)  // #121219
    static let cardBackground = Color(red: 0.12, green: 0.12, blue: 0.17)     // #1E1E2C
    static let accentBlue = Color(red: 0.31, green: 0.45, blue: 0.79)        // #4F74C9
    static let deepNavy = Color(red: 0.11, green: 0.18, blue: 0.31)          // #1B2D4F
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.73)                             // #BBBBBB
    
    // Glass materials
    static let glassWhite = Color.white.opacity(0.1)
    static let glassBorder = Color.white.opacity(0.2)
    
    // Status colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // Nova AI colors
    static let novaBlue = Color(red: 0.31, green: 0.45, blue: 0.79)
    static let novaGlow = Color.blue.opacity(0.6)
    static let novaUrgent = Color.red.opacity(0.8)
}
