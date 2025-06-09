import SwiftUI
import MapKit
import CoreLocation

// Renamed to avoid conflicts - this is the building selection view used for clock-in
struct ClockInBuildingSelectionView: View {
    // Import the NamedCoordinate type from FrancoSphereModels
    let buildings: [FrancoSphere.NamedCoordinate]
    let onSelect: (FrancoSphere.NamedCoordinate) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var viewMode: ViewMode = .list
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedBuilding: FrancoSphere.NamedCoordinate? = nil
    @State private var userLocation: CLLocationCoordinate2D? = nil
    @State private var sortMode: SortMode = .alphabetical
    @State private var currentTab: BuildingTab = .assigned
    @State private var assignedBuildings: [String] = []
    @State private var hasLocationAccess = false
    
    // Type alias for convenience
    private typealias NamedCoordinate = FrancoSphere.NamedCoordinate
    
    // Enums for view states
    enum ViewMode {
        case list
        case map
    }
    
    enum SortMode {
        case alphabetical
        case distance
        case recentlyVisited
    }
    
    enum BuildingTab {
        case assigned
        case nearby
        case all
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndViewToggle
                buildingTabSelector
                
                switch viewMode {
                case .list:
                    buildingListView
                case .map:
                    buildingMapView
                }
            }
            .navigationTitle("Select Building")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Menu {
                    Picker("Sort By", selection: $sortMode) {
                        Label("Alphabetical", systemImage: "textformat.abc")
                            .tag(SortMode.alphabetical)
                        Label("Distance", systemImage: "location")
                            .tag(SortMode.distance)
                        Label("Recently Visited", systemImage: "clock")
                            .tag(SortMode.recentlyVisited)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            )
            .alert(item: $selectedBuilding) { building in
                Alert(
                    title: Text("Clock in at \(building.name)?"),
                    message: Text("You will be clocked in at this building."),
                    primaryButton: .default(Text("Clock In")) {
                        onSelect(building)
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
            .onAppear {
                requestLocationAccess()
                loadAssignedBuildings()
                centerMapOnUserLocation()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var searchAndViewToggle: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search buildings", text: $searchText)
                    .autocapitalization(.none)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Picker("View Mode", selection: $viewMode) {
                Label("List", systemImage: "list.bullet").tag(ViewMode.list)
                Label("Map", systemImage: "map").tag(ViewMode.map)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
        .padding(.top, 10)
    }
    
    private var buildingTabSelector: some View {
        HStack(spacing: 0) {
            ForEach([BuildingTab.assigned, BuildingTab.nearby, BuildingTab.all], id: \.self) { tab in
                Button(action: { withAnimation { currentTab = tab } }) {
                    VStack(spacing: 8) {
                        Text(tabTitle(for: tab))
                            .font(.subheadline)
                            .fontWeight(currentTab == tab ? .semibold : .regular)
                            .foregroundColor(currentTab == tab ? .blue : .gray)
                        if currentTab == tab {
                            Rectangle().fill(Color.blue).frame(height: 2)
                        } else {
                            Rectangle().fill(Color.clear).frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 10)
    }
    
    private var buildingListView: some View {
        List(filteredBuildings) { building in
            Button {
                selectedBuilding = building
            } label: {
                HStack(spacing: 15) {
                    buildingImageView(building)
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.headline)
                        if let address = building.address {
                            Text(address)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        HStack(spacing: 15) {
                            if let distance = buildingDistance(to: building) {
                                Label(formatDistance(distance), systemImage: "location")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if isAssignedBuilding(building) {
                                Label("Assigned", systemImage: "checkmark.circle")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                            }
                            if isRecentlyVisited(building) {
                                Label("Recent", systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(PlainListStyle())
    }
    
    private var buildingMapView: some View {
        ZStack(alignment: .bottom) {
            Map(
                coordinateRegion: $region,
                showsUserLocation: hasLocationAccess,
                annotationItems: filteredBuildings
            ) { building in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude)) {
                    Button(action: {
                        selectedBuilding = building
                    }) {
                        BuildingMapMarker(
                            building: building,
                            isAssigned: isAssignedBuilding(building),
                            isSelected: selectedBuilding?.id == building.id
                        )
                    }
                }
            }
            .edgesIgnoringSafeArea(.bottom)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { centerMapOnUserLocation() }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 30)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(filteredBuildings) { building in
                        Button(action: { selectedBuilding = building }) {
                            buildingMapCard(building)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 20)
            }
            .background(Rectangle().fill(Color(.systemBackground)).shadow(radius: 5))
            .frame(height: 160)
        }
    }
    
    // MARK: - Helper Views
    
    private func buildingMapCard(_ building: NamedCoordinate) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                buildingImageView(building)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.name)
                        .font(.headline)
                        .lineLimit(1)
                    if let distance = buildingDistance(to: building) {
                        Text(formatDistance(distance))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(action: { zoomToBuilding(building) }) {
                    Image(systemName: "location.magnifyingglass")
                        .foregroundColor(.blue)
                }
            }
            
            if let address = building.address {
                Text(address)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Button(action: { selectedBuilding = building }) {
                Text("CLOCK IN")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .padding(15)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
        .frame(width: 220)
    }
    
    private struct BuildingMapMarker: View {
        let building: FrancoSphere.NamedCoordinate
        let isAssigned: Bool
        let isSelected: Bool
        
        var body: some View {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(markerColor)
                        .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 2)
                        
                    // Check if there's a valid image
                    if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: isSelected ? 44 : 34, height: isSelected ? 44 : 34)
                            .clipShape(Circle())
                    } else {
                        Text(building.name.prefix(2))
                            .font(.system(size: isSelected ? 18 : 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                Image(systemName: "arrowtriangle.down.fill")
                    .font(.system(size: 12))
                    .foregroundColor(markerColor)
                    .offset(y: -5)
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(), value: isSelected)
        }
        
        private var markerColor: Color {
            if isSelected { return .blue }
            else if isAssigned { return .purple }
            else { return .orange }
        }
    }
    
    private func buildingImageView(_ building: NamedCoordinate) -> some View {
        Group {
            if !building.imageAssetName.isEmpty, let uiImage = UIImage(named: building.imageAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Circle().fill(Color.orange)
                    Text(building.name.prefix(2))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var filteredBuildings: [NamedCoordinate] {
        // Step 1: Filter by search text
        var filtered = buildings
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Step 2: Filter by tab
        switch currentTab {
        case .assigned:
            filtered = filtered.filter { isAssignedBuilding($0) }
        case .nearby:
            filtered = filtered.filter { buildingDistance(to: $0) != nil }
            if let userLocation = userLocation {
                filtered = filtered.filter { building in
                    let buildingLocation = CLLocation(latitude: building.latitude, longitude: building.longitude)
                    let userCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    let distance = userCLLocation.distance(from: buildingLocation)
                    return distance <= 3000 // ~2 miles
                }
            }
        case .all:
            break
        }
        
        // Step 3: Sort based on selected sort mode
        switch sortMode {
        case .alphabetical:
            filtered.sort { $0.name < $1.name }
        case .distance:
            if let userLocation = userLocation {
                filtered.sort { b1, b2 in
                    let loc1 = CLLocation(latitude: b1.latitude, longitude: b1.longitude)
                    let loc2 = CLLocation(latitude: b2.latitude, longitude: b2.longitude)
                    let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
                    return loc1.distance(from: userLoc) < loc2.distance(from: userLoc)
                }
            }
        case .recentlyVisited:
            filtered.sort { isRecentlyVisited($0) && !isRecentlyVisited($1) }
        }
        
        return filtered
    }
    
    private func tabTitle(for tab: BuildingTab) -> String {
        switch tab {
        case .assigned: return "Assigned"
        case .nearby: return "Nearby"
        case .all: return "All"
        }
    }
    
    private func loadAssignedBuildings() {
        // Load assigned buildings from AuthManager's worker ID
        // For now, using placeholder data
        assignedBuildings = ["1", "3", "5", "7"]
    }
    
    private func isAssignedBuilding(_ building: NamedCoordinate) -> Bool {
        assignedBuildings.contains(building.id)
    }
    
    private func isRecentlyVisited(_ building: NamedCoordinate) -> Bool {
        ["1", "3", "5"].contains(building.id) // Placeholder logic
    }
    
    private func requestLocationAccess() {
        hasLocationAccess = true
        userLocation = CLLocationCoordinate2D(latitude: 40.7308, longitude: -73.9973) // Simulated location
    }
    
    private func centerMapOnUserLocation() {
        if let userLocation = userLocation {
            region = MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            )
        }
    }
    
    private func zoomToBuilding(_ building: NamedCoordinate) {
        withAnimation {
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: building.latitude, longitude: building.longitude),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    private func buildingDistance(to building: NamedCoordinate) -> CLLocationDistance? {
        guard let userLocation = userLocation else { return nil }
        let userLoc = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let buildingLoc = CLLocation(latitude: building.latitude, longitude: building.longitude)
        return userLoc.distance(from: buildingLoc)
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        let feet = distance * 3.28084
        if feet < 1000 {
            return "\(Int(feet)) ft"
        } else {
            let miles = distance / 1609.34
            return String(format: "%.1f mi", miles)
        }
    }
}

// MARK: - Preview
struct ClockInBuildingSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        ClockInBuildingSelectionView(
            buildings: FrancoSphere.NamedCoordinate.allBuildings,
            onSelect: { _ in }
        )
    }
}

// Type aliases for compatibility with existing code
typealias BuildingSelectionView = ClockInBuildingSelectionView
