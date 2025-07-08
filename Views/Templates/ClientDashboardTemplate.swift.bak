//
//  ClientDashboardTemplate.swift
//  FrancoSphere
//
//  ✅ V6.0: Clean client dashboard template without conflicting placeholders
//

import SwiftUI

struct ClientDashboardTemplate: View {
    @StateObject private var viewModel = ClientDashboardViewModel()
    
    var body: some View {
        TabView {
            PortfolioOverviewView(intelligence: viewModel.portfolioIntelligence)
                .tabItem {
                    Label("Overview", systemImage: "chart.pie.fill")
                }
            
            BuildingIntelligenceListView(intelligence: viewModel.portfolioIntelligence)
                .tabItem {
                    Label("Buildings", systemImage: "building.2.fill")
                }
            
            ComplianceOverviewView(intelligence: viewModel.portfolioIntelligence)
                .tabItem {
                    Label("Compliance", systemImage: "shield.lefthalf.filled")
                }
            
            IntelligenceInsightsView(intelligence: viewModel.portfolioIntelligence)
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                }
        }
        .task {
            await viewModel.loadPortfolioIntelligence()
        }
    }
}

struct BuildingIntelligenceListView: View {
    let intelligence: PortfolioIntelligence?
    
    var body: some View {
        VStack {
            if let intelligence = intelligence {
                Text("Building Intelligence List")
                    .font(.largeTitle)
                Text("\(intelligence.totalBuildings) buildings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Loading building intelligence...")
                    .font(.headline)
                ProgressView()
            }
        }
    }
}

struct ClientDashboardTemplate_Previews: PreviewProvider {
    static var previews: some View {
        ClientDashboardTemplate()
            .preferredColorScheme(.dark)
    }
}
