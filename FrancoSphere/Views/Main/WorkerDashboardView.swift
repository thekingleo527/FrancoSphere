import SwiftUI
import MapKit
import CoreLocation

// MARK: - Color Theme
struct FrancoSphereColors {
    static let primaryBackground = Color(hex: "#121219")
    static let cardBackground = Color(hex: "#1E1E2C")
    static let accentBlue = Color(hex: "#4F74C9")
    static let deepNavy = Color(hex: "#1B2D4F")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#BBBBBB")
}

// Extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// Helper function to convert between String and Int64
private func convertStringToInt64(_ string: String) -> Int64 {
    return Int64(string) ?? 0
}

// MARK: - Main View
struct WorkerDashboardView: View {
    // State objects
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var locationManager = LocationManager()
    
    // Repositories and managers
    private let buildingRepository = BuildingRepository.shared
    private let taskManager = TaskManager.shared
    private let weatherDataAdapter = WeatherDataAdapter.shared
    private let aiAssistantManager = AIAssistantManager.shared
    
    // State variables
    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var currentBuildingName: String = "None"
    @State private var assignedBuildings: [NamedCoordinate] = []
    @State private var todaysTasks: [MaintenanceTask] = []
    @State private var weatherAlerts: [WeatherAlert] = []
    @State private var showProfileView = false
    @State private var showBuildingList = false
    @State private var showTaskDetail: MaintenanceTask? = nil
    @State private var isBuildingListExpanded = false
    @State private var showWeatherDetail = false
    @State private var currentTemperature: Int = 72
    @State private var currentCondition: String = "Clear"
    
    // Map region variable
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        ZStack {
            FrancoSphereColors.primaryBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header area
                headerContent
                // Content area
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        buildingsMapSection
                        todaysTasksSection
                        weatherSection
                        assignedBuildingsSection
                        Color.clear.frame(height: 80) // Extra space for assistant
                    }
                }
                .background(FrancoSphereColors.primaryBackground)
                .refreshable {
                    await refreshData()
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // AI Assistant Overlay (positioned as the last element in ZStack for proper layering)
            AIAvatarOverlayView()
                .edgesIgnoringSafeArea(.all)
                .zIndex(100) // Ensure it's always on top
        }
        .onAppear(perform: loadData)
        .sheet(isPresented: $showBuildingList) {
            FrancoBuildingSelectionView(buildings: assignedBuildings, onSelect: handleClockIn)
                .preferredColorScheme(.dark)
                .interactiveDismissDisabled()
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                DashboardTaskDetailView(task: task)
                    .preferredColorScheme(.dark)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showTaskDetail = nil
                            }
                        }
                    }
            }
        }
        .sheet(isPresented: $showProfileView) {
            NavigationView {
                FrancoWorkerProfileView(
                    workerName: authManager.currentWorkerName,
                    workerId: authManager.workerId
                )
                .preferredColorScheme(.dark)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showProfileView = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showWeatherDetail) {
            NavigationView {
                WeatherDetailView(temperature: currentTemperature, condition: currentCondition)
                    .preferredColorScheme(.dark)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showWeatherDetail = false
                            }
                        }
                    }
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        // Notification handlers for AI Assistant actions
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowWeatherDetails"))) { _ in
            showWeatherDetail = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NavigateToTasks"))) { _ in
            if let firstTask = todaysTasks.first {
                showTaskDetail = firstTask
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("TriggerClockOut"))) { _ in
            performClockOut()
        }
    }
    
    // MARK: - Helper Functions
    private func logoutUser() {
        authManager.logout()
    }
    
    private func clockOut() {
        // Check for incomplete tasks before clocking out
        if hasIncompleteTasksForToday() {
            AIAssistantManager.trigger(for: .routineIncomplete)
            return
        }
        
        performClockOut()
    }
    
    private func performClockOut() {
        SQLiteManager.shared.logClockOut(
            workerId: authManager.workerId,
            timestamp: Date()
        )
        clockedInStatus = (false, nil)
        currentBuildingName = "None"
    }
    
    private func hasIncompleteTasksForToday() -> Bool {
        return todaysTasks.contains { !$0.isComplete }
    }
    
    private func hasIncompleteCleaningTasks() -> Bool {
        return todaysTasks.contains { !$0.isComplete && $0.category == .cleaning }
    }
    
    private func hasPendingTasks() -> Bool {
        return !todaysTasks.isEmpty && todaysTasks.contains { !$0.isComplete }
    }
    
    private func hasWeatherAlerts() -> Bool {
        return !weatherAlerts.isEmpty
    }
    
    // MARK: - Header Content
    private var headerContent: some View {
        VStack(spacing: 0) {
            // Blue header area
            VStack(spacing: 0) {
                // FRANCOSPHERE header
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                        Image(systemName: "globe")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(FrancoSphereColors.accentBlue)
                    }
                    Text("FRANCOSPHERE")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, UIApplication.shared.connectedScenes
                    .compactMap { ($0 as? UIWindowScene)?.windows.first?.safeAreaInsets.top }
                    .first ?? 0)
                .padding(.bottom, 12)
                
                // Welcome section
                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 20))
                        .foregroundColor(FrancoSphereColors.accentBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome, \(authManager.currentWorkerName)")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(clockedInStatus.isClockedIn ? Color.green : Color.orange)
                                .frame(width: 10, height: 10)
                            Text(clockedInStatus.isClockedIn ? "Clocked In" : "Not Clocked In")
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                    Menu {
                        Button(action: { showProfileView = true }) {
                            Label("View Profile", systemImage: "person")
                        }
                        Button(action: { logoutUser() }) {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.black)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
                
                // Clock In/Out button
                if clockedInStatus.isClockedIn {
                    Button(action: { clockOut() }) {
                        HStack {
                            Spacer()
                            Image(systemName: "clock")
                                .font(.system(size: 16))
                                .padding(.trailing, 8)
                            Text("CLOCK OUT")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                } else {
                    Button(action: { showBuildingList = true }) {
                        HStack {
                            Spacer()
                            Image(systemName: "building.2")
                                .font(.system(size: 16))
                                .padding(.trailing, 8)
                            Text("CLOCK IN")
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(FrancoSphereColors.deepNavy)
            .edgesIgnoringSafeArea(.top)
        }
        .background(FrancoSphereColors.primaryBackground)
    }
    
    // MARK: - Map Section
    private var buildingsMapSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("My Buildings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(FrancoSphereColors.textPrimary)
                Spacer()
                Button(action: {
                    centerMapOnCurrentLocation()
                }) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                        .foregroundColor(FrancoSphereColors.accentBlue)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 12)
            
            ZStack(alignment: .bottomTrailing) {
                Map(position: $cameraPosition) {
                    ForEach(assignedBuildings) { building in
                        Annotation(building.id, coordinate: building.coordinate) {
                            NavigationLink(destination: BuildingDetailView(building: building)) {
                                ZStack {
                                    Circle()
                                        .fill(isClockedInBuilding(building) ? Color.green : FrancoSphereColors.accentBlue)
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                        .shadow(radius: 2)
                                    if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 32, height: 32)
                                            .clipShape(Circle())
                                    } else {
                                        Text(building.name.prefix(2))
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
                .frame(height: 200)
                .cornerRadius(12)
                
                VStack(spacing: 8) {
                    Button(action: { zoomIn() }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }
                    Button(action: { zoomOut() }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.gray.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Tasks Section
    private var todaysTasksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(FrancoSphereColors.accentBlue)
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(FrancoSphereColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            if todaysTasks.isEmpty {
                Text("No tasks scheduled for today")
                    .font(.subheadline)
                    .foregroundColor(FrancoSphereColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(FrancoSphereColors.cardBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 6) {
                    ForEach(todaysTasks, id: \.id) { task in
                        taskListItem(task)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func taskListItem(_ task: MaintenanceTask) -> some View {
        Button(action: {
            showTaskDetail = task
        }) {
            HStack(spacing: 12) {
                Image(systemName: task.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(FrancoSphereColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(task.statusColor)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(buildingRepository.getBuildingName(forId: task.buildingID))
                            .font(.caption)
                            .foregroundColor(FrancoSphereColors.textSecondary)
                        if let startTime = task.startTime {
                            Text(formatTime(startTime))
                                .font(.caption)
                                .foregroundColor(FrancoSphereColors.textSecondary)
                        }
                    }
                }
                Spacer()
                Text(task.statusText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.statusColor.opacity(0.2))
                    .foregroundColor(task.statusColor)
                    .cornerRadius(12)
            }
            .padding(10)
            .background(FrancoSphereColors.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Weather Section
    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("Weather Conditions")
                    .font(.headline)
                    .foregroundColor(FrancoSphereColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal)
            
            Button(action: {
                showWeatherDetail = true
            }) {
                HStack {
                    Image(systemName: getWeatherIcon())
                        .font(.title2)
                        .foregroundColor(.yellow)
                    Text("\(currentTemperature)°F")
                        .font(.title3)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    Text(currentCondition)
                        .foregroundColor(FrancoSphereColors.textSecondary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(FrancoSphereColors.accentBlue)
                }
                .padding(.vertical, 10)
                .padding(.horizontal)
                .background(FrancoSphereColors.cardBackground)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // Helper for weather icons
    private func getWeatherIcon() -> String {
        switch currentCondition.lowercased() {
        case _ where currentCondition.lowercased().contains("rain"):
            return "cloud.rain.fill"
        case _ where currentCondition.lowercased().contains("cloud"):
            return "cloud.fill"
        case _ where currentCondition.lowercased().contains("snow"):
            return "snow"
        case _ where currentCondition.lowercased().contains("thunder"):
            return "cloud.bolt.fill"
        case _ where currentCondition.lowercased().contains("fog"):
            return "cloud.fog.fill"
        default:
            return "sun.max.fill"
        }
    }
    
    // MARK: - Buildings Section
    private var assignedBuildingsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📍 Assigned Buildings")
                .font(.headline)
                .padding(.horizontal)
            if assignedBuildings.isEmpty {
                Text("You don't have any assigned buildings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(FrancoSphereColors.cardBackground)
                    .cornerRadius(8)
                    .padding(.horizontal)
            } else {
                ForEach(assignedBuildings) { building in
                    buildingListItem(building)
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func buildingListItem(_ building: NamedCoordinate) -> some View {
        NavigationLink(destination: BuildingDetailView(building: building)) {
            HStack(spacing: 12) {
                if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.gray)
                        .frame(width: 50, height: 50)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(building.name)
                        .font(.headline)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    if let address = building.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isClockedInBuilding(building) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                }
            }
            .padding(12)
            .background(FrancoSphereColors.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Map Zoom Functions
    private func getCurrentRegion() -> MKCoordinateRegion? {
        return cameraPosition.region
    }
    
    private func zoomIn() {
        if let region = getCurrentRegion() {
            let newLatDelta = max(region.span.latitudeDelta * 0.5, 0.001)
            let newLongDelta = max(region.span.longitudeDelta * 0.5, 0.001)
            let newRegion = MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLongDelta)
            )
            withAnimation {
                cameraPosition = .region(newRegion)
            }
        }
    }
    
    private func zoomOut() {
        if let region = getCurrentRegion() {
            let newLatDelta = min(region.span.latitudeDelta * 2.0, 180.0)
            let newLongDelta = min(region.span.longitudeDelta * 2.0, 180.0)
            let newRegion = MKCoordinateRegion(
                center: region.center,
                span: MKCoordinateSpan(latitudeDelta: newLatDelta, longitudeDelta: newLongDelta)
            )
            withAnimation {
                cameraPosition = .region(newRegion)
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadData() {
        checkClockInStatus()
        loadAssignedBuildings()
        loadTodaysTasks()
        loadWeatherAlerts()
        centerMapOnCurrentLocation()
        
        // Check for AI assistant triggers
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Check for incomplete cleaning tasks
            if hasIncompleteCleaningTasks() {
                AIAssistantManager.trigger(for: .routineIncomplete)
            }
            
            // Check for pending tasks
            else if hasPendingTasks() {
                AIAssistantManager.trigger(for: .pendingTasks)
            }
            
            // Check for weather alerts
            else if hasWeatherAlerts() {
                AIAssistantManager.trigger(for: .weatherAlert)
            }
        }
    }
    
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        checkClockInStatus()
        loadAssignedBuildings()
        loadTodaysTasks()
        loadWeatherAlerts()
    }
    
    private func loadWeatherAlerts() {
        weatherAlerts = []
        for building in assignedBuildings {
            if let notification = weatherDataAdapter.createWeatherNotification(for: building) {
                weatherAlerts.append(
                    WeatherAlert(
                        id: UUID().uuidString,
                        buildingId: building.id,
                        buildingName: building.name,
                        title: "Weather Alert",
                        message: notification,
                        icon: "cloud.rain.fill",
                        color: .blue,
                        timestamp: Date()
                    )
                )
            }
        }
    }
    
    private func checkClockInStatus() {
        // SQLiteManager.isWorkerClockedIn expects Int64
        clockedInStatus = SQLiteManager.shared.isWorkerClockedIn(workerId: authManager.workerId)
        
        if clockedInStatus.isClockedIn, let buildingId = clockedInStatus.buildingId {
            // Convert the Int64 buildingId to String for comparison with NamedCoordinate.id
            let buildingIdString = String(buildingId)
            if let building = assignedBuildings.first(where: { $0.id == buildingIdString }) {
                currentBuildingName = building.name
            } else {
                currentBuildingName = "Building #\(buildingId)"
            }
        } else {
            currentBuildingName = "None"
        }
    }
    
    private func loadAssignedBuildings() {
        assignedBuildings = buildingRepository.buildings
    }
    
    private func loadTodaysTasks() {
        // Convert to String for new TaskManager
        let workerIdString = String(authManager.workerId)
        todaysTasks = taskManager.fetchTasks(forWorker: workerIdString, date: Date())
        todaysTasks.sort { (task1, task2) -> Bool in
            if task1.urgency != task2.urgency {
                return task1.urgency.rawValue > task2.urgency.rawValue
            }
            return task1.dueDate < task2.dueDate
        }
    }
    
    private func getCurrentBuilding() -> NamedCoordinate? {
        if clockedInStatus.isClockedIn, let buildingId = clockedInStatus.buildingId {
            // Convert Int64 to String for comparing with NamedCoordinate.id
            let buildingIdString = String(buildingId)
            return assignedBuildings.first { $0.id == buildingIdString }
        }
        return nil
    }
    
    private func centerMapOnCurrentLocation() {
        if let loc = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
            cameraPosition = .region(region)
        } else if let firstBld = assignedBuildings.first {
            let region = MKCoordinateRegion(
                center: firstBld.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
            cameraPosition = .region(region)
        }
    }
    
    private func handleClockIn(_ building: NamedCoordinate) {
        guard canClockIn(building) else {
            print("Cannot clock in - not at building location")
            return
        }
        
        // Convert String ID to Int64 for SQLiteManager
        let buildingIdInt64 = convertStringToInt64(building.id)
        
        SQLiteManager.shared.logClockIn(
            workerId: authManager.workerId,
            buildingId: buildingIdInt64,
            timestamp: Date()
        )
        
        clockedInStatus = (true, buildingIdInt64)
        currentBuildingName = building.name
        loadTodaysTasks()
        showBuildingList = false
    }
    
    private func canClockIn(_ building: NamedCoordinate) -> Bool {
        if authManager.userRole == "admin" { return true }
        return locationManager.isWithinRange(of: building.coordinate, radius: 50)
    }
    
    private func isClockedInBuilding(_ building: NamedCoordinate) -> Bool {
        if let bId = clockedInStatus.buildingId {
            // Convert buildingId to String for comparison
            return String(bId) == building.id
        }
        return false
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Building Selection View
struct FrancoBuildingSelectionView: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void
    
    @State private var searchText = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredBuildings) { building in
                    Button(action: {
                        onSelect(building)
                    }) {
                        HStack(spacing: 15) {
                            if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(building.name)
                                    .font(.headline)
                                if let address = building.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Select Building")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .searchable(text: $searchText, prompt: "Search buildings")
        }
    }
    
    private var filteredBuildings: [NamedCoordinate] {
        if searchText.isEmpty {
            return buildings
        } else {
            return buildings.filter { building in
                building.name.localizedCaseInsensitiveContains(searchText) ||
                (building.address ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Worker Profile View
struct FrancoWorkerProfileView: View {
    let workerName: String
    let workerId: Int64
    let userRole: String = AuthManager.shared.userRole
    
    @State private var assignedBuildings: [NamedCoordinate] = []
    @State private var completedTasks = 0
    @State private var pendingTasks = 0
    @State private var totalHoursWorked: Double = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(FrancoSphereColors.deepNavy)
                            .frame(width: 100, height: 100)
                            .shadow(radius: 3)
                        Text(workerName.prefix(2).uppercased())
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(FrancoSphereColors.accentBlue)
                    }
                    VStack(spacing: 4) {
                        Text(workerName)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(FrancoSphereColors.textPrimary)
                        Text(userRole.capitalized)
                            .font(.subheadline)
                            .foregroundColor(FrancoSphereColors.accentBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .background(FrancoSphereColors.accentBlue.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                HStack(spacing: 15) {
                    statCard(count: completedTasks,
                             label: "Completed",
                             icon: "checkmark.circle.fill",
                             color: .green)
                    statCard(count: pendingTasks,
                             label: "Pending",
                             icon: "clock.fill",
                             color: .orange)
                    statCard(count: Int(totalHoursWorked),
                             label: "Hours",
                             icon: "clock.arrow.circlepath",
                             color: FrancoSphereColors.accentBlue)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("Assigned Buildings")
                        .font(.headline)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    ForEach(assignedBuildings) { building in
                        HStack {
                            if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(FrancoSphereColors.cardBackground)
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(8)
                                    Image(systemName: "building.2.fill")
                                        .foregroundColor(FrancoSphereColors.textSecondary)
                                }
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(building.name)
                                    .font(.headline)
                                    .foregroundColor(FrancoSphereColors.textPrimary)
                                if let address = building.address {
                                    Text(address)
                                        .font(.caption)
                                        .foregroundColor(FrancoSphereColors.textSecondary)
                                        .lineLimit(1)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(FrancoSphereColors.cardBackground)
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(FrancoSphereColors.cardBackground.opacity(0.5))
                .cornerRadius(12)
            }
            .padding()
        }
        .background(FrancoSphereColors.primaryBackground)
        .navigationTitle("Worker Profile")
        .onAppear {
            loadProfileData()
        }
    }
    
    private func statCard(count: Int,
                          label: String,
                          icon: String,
                          color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(FrancoSphereColors.textPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(FrancoSphereColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(FrancoSphereColors.cardBackground)
        .cornerRadius(12)
    }
    
    private func loadProfileData() {
        assignedBuildings = BuildingRepository.shared.buildings
        
        // Convert Int64 to String for TaskManager
        let workerIdString = String(workerId)
        let allTasks = TaskManager.shared.getUpcomingTasks(forWorker: workerIdString)
        completedTasks = allTasks.filter { $0.isComplete }.count
        pendingTasks = allTasks.filter { !$0.isComplete }.count
        totalHoursWorked = Double(Int.random(in: 50...400))
    }
}

// MARK: - Weather Detail View
struct WeatherDetailView: View {
    let temperature: Int
    let condition: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 10) {
                    HStack {
                        Spacer()
                        VStack(spacing: 5) {
                            Image(systemName: getWeatherIcon(condition))
                                .font(.system(size: 80))
                                .foregroundColor(.yellow)
                            Text("\(temperature)°F")
                                .font(.system(size: 60, weight: .medium))
                                .foregroundColor(FrancoSphereColors.textPrimary)
                            Text(condition)
                                .font(.title2)
                                .foregroundColor(FrancoSphereColors.textSecondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(FrancoSphereColors.cardBackground)
                    .cornerRadius(16)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("Details")
                        .font(.headline)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    weatherDetailRow(icon: "thermometer", title: "Feels Like", value: "\(temperature - 1)°F")
                    weatherDetailRow(icon: "humidity.fill", title: "Humidity", value: "45%")
                    weatherDetailRow(icon: "wind", title: "Wind", value: "8 mph NW")
                    weatherDetailRow(icon: "umbrella.fill", title: "Precipitation", value: "0%")
                    weatherDetailRow(icon: "eye.fill", title: "Visibility", value: "10 miles")
                }
                .padding()
                .background(FrancoSphereColors.cardBackground)
                .cornerRadius(16)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hourly Forecast")
                        .font(.headline)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            hourlyForecastItem(time: "Now", temp: temperature, icon: getWeatherIcon(condition))
                            hourlyForecastItem(time: "10 AM", temp: temperature + 1, icon: "sun.max.fill")
                            hourlyForecastItem(time: "11 AM", temp: temperature + 2, icon: "sun.max.fill")
                            hourlyForecastItem(time: "12 PM", temp: temperature + 3, icon: "sun.max.fill")
                            hourlyForecastItem(time: "1 PM", temp: temperature + 3, icon: "sun.max.fill")
                            hourlyForecastItem(time: "2 PM", temp: temperature + 2, icon: "cloud.sun.fill")
                            hourlyForecastItem(time: "3 PM", temp: temperature + 1, icon: "cloud.sun.fill")
                            hourlyForecastItem(time: "4 PM", temp: temperature, icon: "cloud.sun.fill")
                        }
                        .padding(.vertical, 10)
                    }
                }
                .padding()
                .background(FrancoSphereColors.cardBackground)
                .cornerRadius(16)
            }
            .padding()
        }
        .background(FrancoSphereColors.primaryBackground.edgesIgnoringSafeArea(.all))
        .navigationTitle("Weather Details")
    }
    
    private func weatherDetailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(FrancoSphereColors.accentBlue)
            Text(title)
                .foregroundColor(FrancoSphereColors.textPrimary)
            Spacer()
            Text(value)
                .foregroundColor(FrancoSphereColors.textSecondary)
        }
        .padding(.vertical, 5)
    }
    
    private func hourlyForecastItem(time: String, temp: Int, icon: String) -> some View {
        VStack(spacing: 8) {
            Text(time)
                .font(.caption)
                .foregroundColor(FrancoSphereColors.textSecondary)
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.yellow)
            Text("\(temp)°")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(FrancoSphereColors.textPrimary)
        }
        .frame(width: 60)
    }
    
    private func getWeatherIcon(_ condition: String) -> String {
        switch condition.lowercased() {
        case _ where condition.lowercased().contains("rain"):
            return "cloud.rain.fill"
        case _ where condition.lowercased().contains("cloud"):
            return "cloud.fill"
        case _ where condition.lowercased().contains("snow"):
            return "snow"
        case _ where condition.lowercased().contains("thunder"):
            return "cloud.bolt.fill"
        case _ where condition.lowercased().contains("fog"):
            return "cloud.fog.fill"
        default:
            return "sun.max.fill"
        }
    }
}

// MARK: - Preview Provider
struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
    }
}
