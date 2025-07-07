//
//  IntelligencePreviewPanel.swift
//  FrancoSphere
//
//  Created by Shawn Magloire on 7/7/25.
//


//
//  IntelligencePreviewPanel.swift
//  FrancoSphere
//
//  ✅ V6.0: Phase 4.1 - Real-Time Admin Dashboard UI
//  ✅ A reusable component to display the BuildingIntelligenceDTO.
//

import SwiftUI

struct IntelligencePreviewPanel: View {
    let intelligence: BuildingIntelligenceDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    metricCard(
                        title: "Overall Score",
                        value: "\(intelligence.overallScore)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    metricCard(
                        title: "Routine Adherence",
                        value: "\(intelligence.operationalMetrics.routineAdherence, specifier: "%.0f")%",
                        icon: "checklist.checked",
                        color: .blue
                    )
                    
                    metricCard(
                        title: "Compliance",
                        value: intelligence.complianceData.complianceStatus.rawValue,
                        icon: "shield.lefthalf.filled",
                        color: intelligence.complianceData.complianceStatus == .compliant ? .green : .orange
                    )
                    
                    metricCard(
                        title: "Data Quality",
                        value: "\(intelligence.dataQuality.score * 100, specifier: "%.0f")%",
                        icon: "chart.bar.xaxis",
                        color: .purple
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var header: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text("Building Intelligence")
                    .font(.headline)
                Text("Last updated: \(intelligence.timestamp, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
        }
        .padding()
        .frame(minWidth: 140)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

struct IntelligencePreviewPanel_Previews: PreviewProvider {
    static var previews: some View {
        let stubbedIntelligence = StubFactory.makeBuildingIntelligence(for: "14", workerIds: ["1", "4"])
        
        IntelligencePreviewPanel(intelligence: stubbedIntelligence)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
