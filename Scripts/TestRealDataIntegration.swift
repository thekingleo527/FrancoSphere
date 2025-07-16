//
//  TestRealDataIntegration.swift
//  FrancoSphere v6.0
//
//  Integration test for real data implementation
//

import Foundation

enum IntegrationTest {
    
    static func runFullIntegrationTest() async -> Bool {
        print("🧪 Running full integration test...")
        
        var allPassed = true
        
        // Test 1: Real portfolio intelligence
        if await testPortfolioIntelligence() {
            print("✅ Portfolio intelligence test passed")
        } else {
            print("❌ Portfolio intelligence test failed")
            allPassed = false
        }
        
        // Test 2: Real building metrics
        if await testBuildingMetrics() {
            print("✅ Building metrics test passed")
        } else {
            print("❌ Building metrics test failed")
            allPassed = false
        }
        
        // Test 3: Real worker performance
        if await testWorkerPerformance() {
            print("✅ Worker performance test passed")
        } else {
            print("❌ Worker performance test failed")
            allPassed = false
        }
        
        // Test 4: Real weather integration
        if await testWeatherIntegration() {
            print("✅ Weather integration test passed")
        } else {
            print("❌ Weather integration test failed")
            allPassed = false
        }
        
        return allPassed
    }
    
    private static func testPortfolioIntelligence() async -> Bool {
        do {
            let intelligence = await RealDataFactory.createRealPortfolioIntelligence()
            return intelligence.totalBuildings > 0
        } catch {
            print("Portfolio intelligence error: \(error)")
            return false
        }
    }
    
    private static func testBuildingMetrics() async -> Bool {
        let metrics = await RealDataFactory.createRealBuildingMetrics()
        return !metrics.isEmpty
    }
    
    private static func testWorkerPerformance() async -> Bool {
        let performance = await RealDataFactory.createRealWorkerPerformance(for: "2") // Edwin
        return performance.efficiency >= 0
    }
    
    private static func testWeatherIntegration() async -> Bool {
        let adapter = WeatherDataAdapter.shared
        let building = NamedCoordinate(id: "14", name: "Rubin Museum", latitude: 40.7402, longitude: -73.9980)
        
        await adapter.fetchWeatherForBuildingAsync(building)
        
        return adapter.currentWeather != nil
    }
}
