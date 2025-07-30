# FrancoSphere v6.0 🏢

**Franco Management Enterprises, LLC**  
*Enterprise Building Management Platform*

📧 Contact: shawn@fme-llc.com  
🌐 Website: [francomanagement.org](https://francomanagement.org)

> **Note**: This repository contains the architectural documentation and planning for FrancoSphere v6.0.  
> Development is scheduled to begin in February 2025.
> 
> **Current Status**: 🏗️ Architecture & Design Phase

A comprehensive building management platform for property operations, maintenance tracking, and workforce coordination in New York City.

## 📑 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#️-architecture)
- [Project Structure](#-project-structure)
- [Nova AI System](#-nova-ai-system-flow)
- [Technology Stack](#️-technology-stack)
- [Features by Role](#-features-by-role)
- [Data Flow](#-data-flow)
- [Getting Started](#-getting-started-development-guide)
- [Deployment](#-deployment)
- [Development Status](#-development-status)
- [Development Roadmap](#️-development-roadmap)
- [Supported Buildings](#-supported-buildings)
- [Security](#-security)
- [Planned Features](#-planned-features-v60)
- [Version History](#-version-history)
- [Contributing](#-contributing)
- [Support](#-support)
- [Team](#-team)
- [License](#-license)

## 🌟 Overview

FrancoSphere is a modern iOS application designed to streamline property management operations across multiple buildings for Franco Management Enterprises, LLC. It features real-time synchronization, AI-powered insights, and role-based dashboards for workers, administrators, and clients.

## 🎯 Key Features

### Three Specialized Dashboards
- **Worker Dashboard** - Task management, clock-in/out, route optimization
- **Admin Dashboard** - Building oversight, worker management, metrics tracking  
- **Client Dashboard** - Portfolio overview, compliance monitoring, intelligence insights

### Dashboard Flow
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ Worker Dashboard│     │ Admin Dashboard │     │Client Dashboard │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ • My Tasks      │     │ • All Buildings │     │ • Portfolio     │
│ • Clock In/Out  │     │ • All Workers   │     │ • Compliance    │
│ • Route Map     │     │ • Assignments   │     │ • Analytics     │
│ • Weather Alert │     │ • Real-time Map │     │ • AI Insights   │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                         │
         └───────────────────────┴─────────────────────────┘
                                 │
                        ┌────────▼────────┐
                        │ DashboardSync   │
                        │    Service      │
                        └─────────────────┘
```

### Core Capabilities
- ✅ Real-time task tracking and photo evidence collection
- ✅ Worker clock-in/out with location verification
- ✅ Building maintenance scheduling and compliance
- ✅ Weather-responsive task prioritization
- ✅ AI-powered operational insights (Nova AI)
- ✅ Offline-first architecture with sync capabilities
- ✅ QuickBooks payroll integration
- ✅ DSNY (NYC Sanitation) schedule integration

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Layer (SwiftUI)                       │
├─────────────────┬──────────────────┬────────────────────────┤
│ Worker Dashboard │ Admin Dashboard  │  Client Dashboard      │
└────────┬────────┴────────┬─────────┴──────────┬────────────┘
         │                 │                     │
         ▼                 ▼                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    ViewModels (@MainActor)                    │
└─────────────────────────┬────────────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────┐
│                    Services (Business Logic)                  │
├─────────────┬────────────┬──────────────┬───────────────────┤
│    Core     │Intelligence│ Integration  │   Operations      │
└─────────────┴────────────┴──────────────┴───────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────┐
│                 Managers (System Utilities)                   │
├────────────────┬──────────────┬──────────────────────────────┤
│   Database     │    System     │        Operations           │
└────────────────┴──────────────┴──────────────────────────────┘
                          │
┌─────────────────────────▼────────────────────────────────────┐
│                    GRDB (SQLite Database)                     │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
FrancoSphere/
├── Models/               # Data structures and types
│   ├── Core/            # CoreTypes.swift - central type definitions
│   ├── DTOs/            # Data transfer objects
│   ├── Extensions/      # Swift extensions
│   └── Enums/           # Enumeration types
│
├── ViewModels/          # MVVM view models
│   ├── Dashboard/       # Dashboard-specific view models
│   ├── Building/        # Building management view models
│   └── Task/            # Task-related view models
│
├── Views/               # SwiftUI views
│   ├── Auth/            # Authentication views
│   ├── Buildings/       # Building management views
│   └── Main/            # Main app views and dashboards
│
├── Services/            # Business logic layer
│   ├── Core/            # Core services (Task, Building, Worker)
│   ├── Intelligence/    # AI and metrics services
│   ├── Integration/     # External integrations (Weather, QuickBooks)
│   └── Operations/      # Operational services
│
├── Managers/            # System-level utilities
│   ├── Database/        # Database management
│   ├── System/          # System services (Auth, Location, Notifications)
│   └── Operations/      # Operational managers
│
├── Nova/                # AI System
│   ├── Core/            # Nova intelligence engine
│   └── UI/              # Nova UI components
│
├── Components/          # Reusable UI components
│   ├── Glass/           # Glassmorphism design system
│   ├── Design/          # Design components
│   ├── Cards/           # Card components
│   └── Common/          # Shared components
│
├── Utilities/           # Helper functions and extensions
├── Sync/                # Data synchronization
└── Resources/           # Assets and configuration
```

## 🤖 Nova AI System Flow

```
                     ┌─────────────────────┐
                     │   Building Data     │
                     │   Worker Metrics    │
                     │   Task History      │
                     └──────────┬──────────┘
                                │
                     ┌──────────▼──────────┐
                     │  Nova Intelligence  │
                     │      Engine         │
                     └──────────┬──────────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
   ┌────────▼────────┐ ┌───────▼────────┐ ┌───────▼────────┐
   │ Task Priority   │ │ Route Optimize │ │ Compliance     │
   │ Recommendations │ │ Suggestions    │ │ Predictions    │
   └─────────────────┘ └────────────────┘ └────────────────┘
            │                   │                   │
            └───────────────────┴───────────────────┘
                                │
                     ┌──────────▼──────────┐
                     │  Dashboard Updates  │
                     │  & Notifications    │
                     └─────────────────────┘
```

## 🛠️ Technology Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 5.9
- **UI Framework**: SwiftUI
- **Database**: GRDB (SQLite)
- **Architecture**: MVVM + Services
- **Concurrency**: Swift Concurrency (async/await)
- **AI Integration**: Nova AI System
- **Design System**: Custom Glassmorphism (2040 Standard)

## 📱 Features by Role

### Workers
- View assigned tasks and buildings
- Clock in/out with GPS verification
- Submit task completion with photo evidence
- View optimized routes between buildings
- Receive weather-based task prioritization

### Administrators
- Monitor all buildings and workers in real-time
- Assign and reassign tasks dynamically
- View performance metrics and analytics
- Manage compliance and maintenance schedules
- Export payroll data to QuickBooks

### Clients
- Portfolio-wide performance overview
- Compliance status monitoring
- AI-powered insights and predictions
- Historical metrics and trends
- Emergency contact management

## 🔄 Data Flow

```
Worker Actions                    System Processing                 Real-time Updates
─────────────                    ─────────────────                ─────────────────
                                        
Clock In ──────────┐                                             ┌──▶ Admin Dashboard
                   │            ┌─────────────────┐              │    (Worker Status)
Take Photo ────────┼───────────▶│                 │──────────────┤
                   │            │  TaskService &  │              │
Complete Task ─────┘            │  DashboardSync  │              ├──▶ Client Dashboard
                                │                 │              │    (Metrics Update)
                                └─────────────────┘              │
                                         │                       └──▶ Worker Dashboard
                                         ▼                            (Next Task)
                                   ┌──────────┐
                                   │   GRDB   │
                                   │ Database │
                                   └──────────┘
```

## 🚀 Getting Started (Development Guide)

> **Note**: These instructions are for the development team starting in February 2025.

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target
- Swift Package Manager
- macOS Sonoma 14.0+ (for development)

### System Requirements
- **Minimum iOS Version**: 17.0
- **Supported Devices**: iPhone 12 and newer
- **Storage**: 100MB available space
- **Network**: Required for sync (offline mode available)

### Installation

1. Clone the repository (when available)
```bash
git clone [repository-url]
cd FrancoSphere
```

2. Open in Xcode
```bash
open FrancoSphere.xcodeproj
```

3. Install dependencies
- GRDB will be automatically fetched via Swift Package Manager

4. Configure environment
- Add your API keys to `Config/Secrets.swift` (create from template)
- Configure weather API endpoints
- Set up QuickBooks OAuth credentials

5. Build and run
- Select your target device/simulator
- Press ⌘R to build and run

## 🚀 Deployment

### Development Timeline
- **Development Start**: February 2025
- **Alpha Testing**: Q2 2025
- **Beta Release**: Q3 2025
- **Production Launch**: Q4 2025

### TestFlight
- Internal testing for Franco Management Enterprises team
- Beta testing for select building managers

### App Store
- Enterprise deployment planned for Q4 2025
- Private distribution to Franco Management Enterprises employees

## 🏢 Supported Buildings

The system currently manages properties in Manhattan including:
- Rubin Museum (142-148 West 17th Street)
- 104 Franklin Street
- 36 Walker Street
- 131 Perry Street
- And 15+ additional properties

## 🔐 Security

- Role-based access control (RBAC)
- Secure credential storage in Keychain
- GPS verification for clock-in events
- Photo evidence tamper protection
- Encrypted database with SQLCipher

## 🤝 Contributing

This is a private repository for Franco Management Enterprises, LLC. For access or contributions, please contact the development team.

### Development Guidelines
- Follow Swift API Design Guidelines
- Maintain 80%+ code coverage for new features
- All UI changes must support Dynamic Type
- Commits must follow conventional commit format
- PR reviews required before merging to main

## 📄 License

Proprietary Software - Franco Management Enterprises, LLC © 2025. All rights reserved.

This software and associated documentation files (the "Software") are the exclusive property of Franco Management Enterprises, LLC. Unauthorized copying, modification, distribution, or use of this Software, via any medium, is strictly prohibited without the express written permission of Franco Management Enterprises, LLC.

---

## 🆕 Planned Features (v6.0)

### Architecture Improvements
- ✨ Consolidated Nova AI system (60% file reduction)
- ✨ Reorganized project structure for clarity
- ✨ ViewModels at root level (proper MVVM)
- ✨ Clear service boundaries
- ✨ Elimination of redundant managers and services

### Performance Enhancements
- ✨ Optimized database queries
- ✨ Improved real-time sync efficiency
- ✨ Target: 40% reduction in app launch time
- ✨ Enhanced offline capabilities

### New Features
- ✨ Advanced weather integration
- ✨ AI-powered task recommendations
- ✨ Enhanced photo evidence system
- ✨ Improved worker route optimization

## 📈 Version History

- **v6.0** (Planned - Feb 2025) - Major architecture overhaul, Nova AI integration
- **v5.0** (Planned) - Three-dashboard system implementation
- **v4.0** (Planned) - GRDB migration, offline-first architecture
- **v3.0** (Planned) - Worker clock-in/out, photo evidence
- **v2.0** (Planned) - Multi-building support
- **v1.0** (Planned) - Initial release

## 🚧 Development Status

**Current Phase**: Architecture & Planning  
**Development Start**: February 2025  
**Status**: Pre-development documentation and system design

## 🗺️ Development Roadmap

### Phase 1: Foundation (Feb-Mar 2025)
- [ ] Core data models implementation
- [ ] GRDB database setup
- [ ] Basic authentication system
- [ ] Worker dashboard MVP

### Phase 2: Core Features (Apr-May 2025)
- [ ] Task management system
- [ ] Photo evidence capture
- [ ] Clock in/out functionality
- [ ] Admin dashboard

### Phase 3: Intelligence (Jun-Jul 2025)
- [ ] Nova AI integration
- [ ] Real-time sync implementation
- [ ] Weather service integration
- [ ] Client dashboard

### Phase 4: Polish & Deploy (Aug-Sep 2025)
- [ ] Performance optimization
- [ ] Comprehensive testing
- [ ] Beta testing program
- [ ] App Store submission

## 📞 Support

For technical support or questions:
- Internal Slack: #francosphere-dev
- Email: shawn@fme-llc.com
- Lead Developer: Shawn Magloire

## 👥 Team

**Franco Management Enterprises, LLC**
- Shawn Magloire - Lead Developer & Technical Architecture
- Franco Management Team - Product Strategy & Operations

---

Built with ❤️ in New York City 🗽 by Franco Management Enterprises, LLC  
[francomanagement.org](https://francomanagement.org)
