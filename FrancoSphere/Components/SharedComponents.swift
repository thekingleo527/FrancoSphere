//
import SwiftUI
import Foundation
import MapKit

// MARK: - Building Marker for Map
struct BuildingMarkerView: View {
    let building: NamedCoordinate
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .shadow(radius: 2)
                    .frame(width: 40, height: 40)
                
                // FIX 1: Remove optional binding for non-optional String
                if let uiImage = UIImage(named: building.imageAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    Image(systemName: "building.fill")
                        .foregroundColor(Color(red: 0.34, green: 0.34, blue: 0.8))
                }
            }
            
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 12))
                .foregroundColor(.white)
                .offset(y: -5)
        }
    }
}

// MARK: - Building Card
struct BuildingCardView: View {
    let building: NamedCoordinate
    let status: BuildingStatus = .operational // In a real app, this would be fetched
    
    var body: some View {
        HStack {
            // Building image
            Group {
                // FIX 1: Remove optional binding for non-optional String
                if let uiImage = UIImage(named: building.imageAssetName) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "building.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.gray)
                        .padding(5)
                }
            }
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            
            VStack(alignment: .leading) {
                Text(building.name)
                    .font(.headline)
                
                HStack {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    
                    // FIX 2: Use rawValue instead of description
                    Text("Status: \(status.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(status.color)
                }
            }
        }
        .padding(.vertical, 5)
    }
}
