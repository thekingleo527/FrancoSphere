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
            (a, r, g, b) = (
                255,
                (int >> 8) * 17,
                (int >> 4 & 0xF) * 17,
                (int & 0xF) * 17
            )
        case 6:
            (a, r, g, b) = (
                255,
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        case 8:
            (a, r, g, b) = (
                int >> 24,
                int >> 16 & 0xFF,
                int >> 8 & 0xFF,
                int & 0xFF
            )
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

// Helper function
private func convertStringToInt64(_ string: String) -> Int64 {
    return Int64(string) ?? 0
}

// MARK: - Weather Animation Overlay
struct WeatherAnimationView: View {
    let condition: String
    let size: CGFloat
    @State private var isAnimating = false

    var body: some View {
        Group {
            switch condition.lowercased() {
            case let c where c.contains("rain"):
                rainView
            case let c where c.contains("snow"):
                snowView
            case let c where c.contains("cloud"):
                cloudView
            default:
                sunnyView
            }
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever()
            ) {
                isAnimating = true
            }
        }
    }

    private var rainView: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Image(systemName: "cloud.rain.fill")
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(.blue.opacity(0.7))
                    .offset(
                        x: CGFloat(i * 20) - 80,
                        y: isAnimating ? 20 : -20
                    )
                    .animation(
                        Animation.easeInOut(duration: 2)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: isAnimating
                    )
            }
        }
    }

    private var snowView: some View {
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                Image(systemName: "snowflake")
                    .resizable()
                    .frame(width: size * 0.8, height: size * 0.8)
                    .foregroundColor(.white.opacity(0.8))
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .offset(
                        x: CGFloat(i * 20) - 80,
                        y: isAnimating ? 20 : -20
                    )
                    .animation(
                        Animation.easeInOut(duration: 3)
                            .repeatForever()
                            .delay(Double(i) * 0.3),
                        value: isAnimating
                    )
            }
        }
    }

    private var cloudView: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { i in
                Image(systemName: "cloud.fill")
                    .resizable()
                    .frame(width: size * 1.2, height: size)
                    .foregroundColor(.white.opacity(0.6))
                    .offset(
                        x: CGFloat(i * 30) - 45,
                        y: isAnimating ? CGFloat(i * 5) : 0
                    )
                    .animation(
                        Animation.easeInOut(duration: 4)
                            .repeatForever()
                            .delay(Double(i) * 0.5),
                        value: isAnimating
                    )
            }
        }
    }

    private var sunnyView: some View {
        Image(systemName: "sun.max.fill")
            .resizable()
            .frame(width: size * 1.5, height: size * 1.5)
            .foregroundColor(.yellow)
            .opacity(isAnimating ? 0.9 : 0.7)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
    }
}

// MARK: - Weather Detail
struct WeatherDetailView: View {
    let temperature: Int
    let condition: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Current Weather")
                .font(.title).fontWeight(.bold)
            HStack(spacing: 20) {
                Image(systemName: iconName())
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("\(temperature)°F")
                        .font(.system(size: 48)).fontWeight(.bold)
                    Text(condition).font(.title2)
                }
            }
            .padding()
            .background(FrancoSphereColors.cardBackground)
            .cornerRadius(15)
            Spacer()
        }
        .padding()
        .background(FrancoSphereColors.primaryBackground)
        .navigationTitle("Weather Details")
    }

    private func iconName() -> String {
        let c = condition.lowercased()
        if c.contains("rain")    { return "cloud.rain.fill" }
        if c.contains("snow")    { return "snow" }
        if c.contains("cloud")   { return "cloud.fill" }
        if c.contains("thunder") { return "cloud.bolt.fill" }
        if c.contains("fog")     { return "cloud.fog.fill" }
        return "sun.max.fill"
    }
}

// MARK: - Main Dashboard
struct WorkerDashboardView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var locationManager = LocationManager()

    private let buildingRepo = BuildingRepository.shared
    private let taskManager = TaskManager.shared
    private let weatherAdapter = WeatherDataAdapter.shared

    @State private var clockedInStatus: (isClockedIn: Bool, buildingId: Int64?) = (false, nil)
    @State private var currentBuildingName: String = "None"
    @State private var assignedBuildings: [NamedCoordinate] = []
    @State private var todaysTasks: [MaintenanceTask] = []
    @State private var weatherAlerts: [WeatherAlert] = []

    @State private var showProfileView = false
    @State private var showBuildingList = false
    @State private var showTaskDetail: MaintenanceTask? = nil
    @State private var showWeatherDetail = false

    @State private var currentTemperature: Int = 72
    @State private var currentCondition: String = "Clear"
    @State private var showAllBuildings = false

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        ZStack {
            FrancoSphereColors.primaryBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                headerContent
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        buildingsMapSection
                        todaysTasksSection
                        weatherSection
                        assignedBuildingsSection
                        Color.clear.frame(height: 80)
                    }
                }
                .background(FrancoSphereColors.primaryBackground)
                .refreshable { await refreshData() }
            }
            .ignoresSafeArea(edges: .top)

            aiAssistantOverlay
                .edgesIgnoringSafeArea(.all)
                .zIndex(100)
        }
        .onAppear(perform: loadData)
        .sheet(isPresented: $showBuildingList) {
            FrancoBuildingSelectionView(
                buildings: assignedBuildings,
                onSelect: handleClockIn
            )
            .preferredColorScheme(.dark)
            .interactiveDismissDisabled()
        }
        .sheet(item: $showTaskDetail) { task in
            NavigationView {
                DashboardTaskDetailView(task: task)
                    .preferredColorScheme(.dark)
                    .navigationBarItems(trailing: Button("Done") {
                        showTaskDetail = nil
                    })
            }
        }
        .sheet(isPresented: $showProfileView) {
            NavigationView {
                ProfileView()
                    .preferredColorScheme(.dark)
                    .navigationBarItems(trailing: Button("Done") {
                        showProfileView = false
                    })
            }
        }
        .sheet(isPresented: $showWeatherDetail) {
            NavigationView {
                WeatherDetailView(
                    temperature: currentTemperature,
                    condition: currentCondition
                )
                .preferredColorScheme(.dark)
                .navigationBarItems(trailing: Button("Done") {
                    showWeatherDetail = false
                })
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarHidden(true)
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("ShowWeatherDetails")
            )
        ) { _ in showWeatherDetail = true }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("NavigateToTasks")
            )
        ) {_ in
            if let first = todaysTasks.first {
                showTaskDetail = first
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(
                for: Notification.Name("TriggerClockOut")
            )
        ) { _ in performClockOut() }
    }

    // MARK: – Header
    private var headerContent: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
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
                        .font(.system(size: 20.9, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top,
                    UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?
                            .windows.first?.safeAreaInsets.top
                        }
                        .first ?? 0
                )
                .padding(.bottom, 12)

                HStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 19))
                        .foregroundColor(FrancoSphereColors.accentBlue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome, \(authManager.currentWorkerName)")
                            .font(.system(size: 20.9))
                            .foregroundColor(.white)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(
                                    clockedInStatus.isClockedIn
                                        ? Color.green
                                        : Color.orange
                                )
                                .frame(width: 10, height: 10)
                            Text(
                                clockedInStatus.isClockedIn
                                    ? "Clocked In"
                                    : "Not Clocked In"
                            )
                            .font(.system(size: 14.25))
                            .foregroundColor(.white)
                        }
                    }
                    Spacer()
                    Menu {
                        Button { showProfileView = true } label: {
                            Label("View Profile", systemImage: "person")
                        }
                        Button { logoutUser() } label: {
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

                // Clock In / Out Button
                if clockedInStatus.isClockedIn {
                    Button { clockOut() } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "clock")
                                .font(.system(size: 16))
                                .padding(.trailing, 8)
                            Text("CLOCK OUT")
                                .font(.system(size: 17.46, weight: .semibold))
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
                    Button { showBuildingList = true } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "building.2")
                                .font(.system(size: 16))
                                .padding(.trailing, 8)
                            Text("CLOCK IN")
                                .font(.system(size: 17.46, weight: .semibold))
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

    // MARK: – Map Section
    private var buildingsMapSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("My Buildings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(FrancoSphereColors.textPrimary)
                Spacer()
                Button { centerMapOnCurrentLocation() } label: {
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
                Map(coordinateRegion: $region, annotationItems: assignedBuildings) { b in
                    MapAnnotation(coordinate: b.coordinate) {
                        NavigationLink(destination: BuildingDetailView(building: b)) {
                            ZStack {
                                Circle()
                                    .fill(
                                        isClockedInBuilding(b)
                                            ? Color.green
                                            : FrancoSphereColors.accentBlue
                                    )
                                    .frame(width: 36, height: 36)
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 2)
                                if let ui = UIImage(named: b.imageAssetName), !b.imageAssetName.isEmpty {
                                    Image(uiImage: ui)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 32, height: 32)
                                        .clipShape(Circle())
                                } else {
                                    Text(b.name.prefix(2))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .mapStyle(.standard(elevation: .realistic,
                                    pointsOfInterest: .excludingAll))
                .frame(height: 200)
                .cornerRadius(12)
                .overlay(
                    WeatherAnimationView(condition: currentCondition, size: 30)
                        .padding(.trailing, 50)
                        .padding(.bottom, 50)
                )

                // Zoom In Only
                Button { zoomIn() } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.gray.opacity(0.7))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .padding(.horizontal)
        }
    }

    // MARK: – Today's Tasks
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
        Button { showTaskDetail = task } label: {
            HStack(spacing: 12) {
                Image(systemName: task.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(FrancoSphereColors.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(task.statusColor)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.name)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Text(buildingRepo.getBuildingName(forId: task.buildingID))
                            .font(.caption)
                            .foregroundColor(FrancoSphereColors.textSecondary)
                        if let s = task.startTime {
                            Text(formatTime(s))
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

    // MARK: – Weather Section
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

            Button { showWeatherDetail = true } label: {
                HStack {
                    Image(systemName: iconName())
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

    private func iconName() -> String {
        let c = currentCondition.lowercased()
        if c.contains("rain")    { return "cloud.rain.fill" }
        if c.contains("snow")    { return "snow" }
        if c.contains("cloud")   { return "cloud.fill" }
        if c.contains("thunder") { return "cloud.bolt.fill" }
        if c.contains("fog")     { return "cloud.fog.fill" }
        return "sun.max.fill"
    }

    // MARK: – Assigned Buildings
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
                ForEach(assignedBuildings.prefix(2)) { b in
                    buildingListItem(b)
                        .padding(.horizontal)
                }
                if assignedBuildings.count > 2 {
                    Button {
                        withAnimation { showAllBuildings.toggle() }
                    } label: {
                        HStack {
                            Text(
                                showAllBuildings
                                ? "Show Less"
                                : "\(assignedBuildings.count - 2) More Buildings"
                            )
                            .font(.subheadline)
                            .foregroundColor(FrancoSphereColors.accentBlue)
                            Image(systemName:
                                showAllBuildings ? "chevron.up" : "chevron.down"
                            )
                            .font(.caption)
                            .foregroundColor(FrancoSphereColors.accentBlue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(FrancoSphereColors.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    if showAllBuildings {
                        ForEach(assignedBuildings.dropFirst(2)) { b in
                            buildingListItem(b)
                                .padding(.horizontal)
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
    }

    private func buildingListItem(_ b: NamedCoordinate) -> some View {
        NavigationLink(destination: BuildingDetailView(building: b)) {
            HStack(spacing: 12) {
                if let img = UIImage(named: b.imageAssetName), !b.imageAssetName.isEmpty {
                    Image(uiImage: img)
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
                    Text(b.name)
                        .font(.headline)
                        .foregroundColor(FrancoSphereColors.textPrimary)
                    if let addr = b.address {
                        Text(addr)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if isClockedInBuilding(b) {
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

    // MARK: – AI Assistant Overlay
    private var aiAssistantOverlay: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                Spacer()
                if hasIncompleteCleaningTasks()
                    || hasPendingTasks()
                    || hasWeatherAlerts()
                {
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                if hasIncompleteCleaningTasks() {
                                    Text("Pending Tasks").font(.headline)
                                    Text("You have cleaning tasks that need to be completed.")
                                        .font(.subheadline)
                                        .foregroundColor(FrancoSphereColors.textSecondary)
                                } else if hasPendingTasks() {
                                    Text("Pending Tasks").font(.headline)
                                    Text("You have tasks scheduled for today that need completion.")
                                        .font(.subheadline)
                                        .foregroundColor(FrancoSphereColors.textSecondary)
                                } else {
                                    Text("Weather Alert").font(.headline)
                                    Text("Weather conditions may affect your tasks today.")
                                        .font(.subheadline)
                                        .foregroundColor(FrancoSphereColors.textSecondary)
                                }
                                Button {
                                    if let first = todaysTasks.first {
                                        showTaskDetail = first
                                    }
                                } label: {
                                    Text("View Tasks")
                                        .font(.subheadline).fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(FrancoSphereColors.accentBlue)
                                        .cornerRadius(8)
                                }
                            }
                            .padding(12)
                        }
                        .background(FrancoSphereColors.cardBackground)
                        .cornerRadius(12)
                    }
                    .padding(.trailing, 8)
                }
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Circle()
                            .fill(FrancoSphereColors.accentBlue)
                            .frame(width: 63, height: 63)
                        Circle()
                            .fill(FrancoSphereColors.deepNavy)
                            .frame(width: 59, height: 59)
                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(FrancoSphereColors.accentBlue)
                    }
                    Button {
                        // dismiss if needed
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 20, height: 20)
                            Image(systemName: "xmark")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                        }
                    }
                }
                .shadow(radius: 2)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: – Map Zoom
    private func zoomIn() {
        var newRegion = region
        newRegion.span.latitudeDelta = max(newRegion.span.latitudeDelta * 0.5, 0.001)
        newRegion.span.longitudeDelta = max(newRegion.span.longitudeDelta * 0.5, 0.001)
        withAnimation {
            region = newRegion
        }
    }

    // MARK: – Data & Helpers
    private func logoutUser() {
        authManager.logout()
    }
    private func clockOut() {
        if hasIncompleteCleaningTasks() {
            AIAssistantManager.trigger(for: .routineIncomplete)
        } else {
            performClockOut()
        }
    }
    private func performClockOut() {
        SQLiteManager.shared.logClockOut(
            workerId: authManager.workerId,
            timestamp: Date()
        )
        clockedInStatus = (false, nil)
        currentBuildingName = "None"
    }
    private func hasIncompleteCleaningTasks() -> Bool {
        todaysTasks.contains { !$0.isComplete && $0.category == .cleaning }
    }
    private func hasPendingTasks() -> Bool {
        !todaysTasks.isEmpty && todaysTasks.contains { !$0.isComplete }
    }
    private func hasWeatherAlerts() -> Bool {
        !weatherAlerts.isEmpty
    }
    private func formatTime(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }

    private func loadData() {
        checkClockInStatus()
        assignedBuildings = buildingRepo.buildings
        loadTodaysTasks()
        loadWeatherAlerts()
        centerMapOnCurrentLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if hasIncompleteCleaningTasks() {
                AIAssistantManager.trigger(for: .routineIncomplete)
            } else if hasPendingTasks() {
                AIAssistantManager.trigger(for: .pendingTasks)
            } else if hasWeatherAlerts() {
                AIAssistantManager.trigger(for: .weatherAlert)
            }
        }
    }
    private func refreshData() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadData()
    }
    private func loadTodaysTasks() {
        let wid = String(authManager.workerId)
        todaysTasks = taskManager.fetchTasks(forWorker: wid, date: Date())
        todaysTasks.sort {
            if $0.urgency != $1.urgency {
                return $0.urgency.rawValue > $1.urgency.rawValue
            }
            return $0.dueDate < $1.dueDate
        }
    }
    private func loadWeatherAlerts() {
        weatherAlerts = assignedBuildings.compactMap { b in
            weatherAdapter.createWeatherNotification(for: b).map {
                WeatherAlert(
                    id: UUID().uuidString,
                    buildingId: b.id,
                    buildingName: b.name,
                    title: "Weather Alert",
                    message: $0,
                    icon: "cloud.rain.fill",
                    color: .blue,
                    timestamp: Date()
                )
            }
        }
        if let data = weatherAdapter.currentWeather {
            currentTemperature = Int(data.temperature)
            currentCondition = data.condition.rawValue
        }
    }
    private func checkClockInStatus() {
        clockedInStatus = SQLiteManager.shared.isWorkerClockedIn(
            workerId: authManager.workerId
        )
        if
            clockedInStatus.isClockedIn,
            let bid = clockedInStatus.buildingId,
            let b = assignedBuildings.first(where: { $0.id == String(bid) })
        {
            currentBuildingName = b.name
        } else {
            currentBuildingName = "None"
        }
    }
    private func centerMapOnCurrentLocation() {
        if let loc = locationManager.location?.coordinate {
            region = MKCoordinateRegion(
                center: loc,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        }
    }
    private func handleClockIn(_ b: NamedCoordinate) {
        guard authManager.userRole == "admin"
            || locationManager.isWithinRange(of: b.coordinate, radius: 50)
        else { return }
        let bid = Int64(b.id) ?? 0
        SQLiteManager.shared.logClockIn(
            workerId: authManager.workerId,
            buildingId: bid,
            timestamp: Date()
        )
        clockedInStatus = (true, bid)
        currentBuildingName = b.name
        loadTodaysTasks()
        showBuildingList = false
    }
    private func isClockedInBuilding(_ b: NamedCoordinate) -> Bool {
        clockedInStatus.buildingId.map(String.init) == b.id
    }
}

// MARK: - Building Selection
struct FrancoBuildingSelectionView: View {
    let buildings: [NamedCoordinate]
    let onSelect: (NamedCoordinate) -> Void

    @State private var searchText = ""
    @Environment(\.presentationMode) var mode

    var body: some View {
        NavigationView {
            List(filtered) { b in
                Button { onSelect(b) } label: {
                    HStack(spacing: 15) {
                        if let ui = UIImage(named: b.imageAssetName), !b.imageAssetName.isEmpty {
                            Image(uiImage: ui)
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
                            Text(b.name).font(.headline)
                            if let addr = b.address {
                                Text(addr).font(.caption).foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundColor(.gray)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
            .searchable(text: $searchText, prompt: "Search buildings")
            .navigationTitle("Select Building")
            .navigationBarItems(trailing: Button("Cancel") { mode.wrappedValue.dismiss() })
        }
    }

    private var filtered: [NamedCoordinate] {
        guard !searchText.isEmpty else { return buildings }
        return buildings.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || ($0.address ?? "").localizedCaseInsensitiveContains(searchText)
        }
    }
}

struct WorkerDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        WorkerDashboardView()
    }
}
