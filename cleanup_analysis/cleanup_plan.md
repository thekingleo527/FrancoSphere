# FrancoSphere Cleanup Plan

## Identified Issues

### 1. Duplicate Files from GRDB Migration
- Multiple copies of service files
- Duplicate model definitions
- Redundant view files

### 2. Incorrect File Organization
- Files in root that should be in subdirectories
- Nested FrancoSphere folders
- Backup folders in repository

### 3. Proper Structure Should Be:
```
FrancoSphere/
├── App/
│   └── FrancoSphereApp.swift
├── Models/
│   ├── Core/
│   │   ├── CoreTypes.swift (SINGLE source of truth)
│   │   └── UnifiedDataService.swift
│   ├── DTOs/
│   ├── AI/
│   └── [Model files]
├── Views/
│   ├── Main/
│   ├── Buildings/
│   ├── Auth/
│   └── Templates/
├── ViewModels/
├── Services/
│   ├── Core Services (BuildingService, TaskService, etc)
│   ├── AI/
│   ├── Migration/
│   └── Configuration/
├── Components/
│   ├── Glass/
│   ├── Design/
│   └── Shared/
├── Managers/
│   └── [Manager files]
├── Resources/
│   └── Assets.xcassets/
└── FrancoSphere.xcodeproj
```

## Files to Keep (Latest GRDB versions)

### Core Services (Services/)
- BuildingService.swift
- TaskService.swift
- WorkerService.swift
- IntelligenceService.swift
- DashboardSyncService.swift

### Database (Managers/)
- GRDBManager.swift (PRIMARY)
- DatabaseManager.swift (Auth only)
- OperationalDataManager.swift

### Models (Models/Core/)
- CoreTypes.swift (COMPLETE version with all types)
- UnifiedDataService.swift

### Remove These Duplicates:
- Any SQLiteManager files (replaced by GRDB)
- RealWorldDataSeeder.swift (old approach)
- Duplicate type definitions outside CoreTypes
- All backup folders
- Any files in incorrect locations
