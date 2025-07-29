import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let trend: String?
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.secondary)
                Spacer()
                if let trend = trend {
                    Text(trend)
                        .font(.caption)
                        .foregroundColor(trend.contains("↑") ? .green : .red)
                }
            }
            
            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
