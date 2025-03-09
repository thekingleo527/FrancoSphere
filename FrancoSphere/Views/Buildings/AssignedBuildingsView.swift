import SwiftUI

/// A simple model representing an assigned building.
struct AssignedBuilding: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let buildingID: String
}

/// A view showing the list of assigned buildings.
struct AssignedBuildingsView: View {
    let assignedBuildings: [AssignedBuilding]
    
    var body: some View {
        NavigationView {
            List(assignedBuildings) { building in
                VStack(alignment: .leading) {
                    Text(building.name)
                        .font(.headline)
                    Text("Building ID: \(building.buildingID)")
                        .font(.subheadline)
                }
            }
            .navigationTitle("Assigned Buildings")
        }
    }
}

struct AssignedBuildingsView_Previews: PreviewProvider {
    static var previews: some View {
        AssignedBuildingsView(assignedBuildings: [
            AssignedBuilding(id: "1", name: "Test Building", buildingID: "1")
        ])
    }
}
