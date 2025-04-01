//
//  DroneSpriteView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/29/25.
//

import SwiftUI
import FirebaseAnalytics
import Combine

class DroneViewModel: ObservableObject {
    @Published var availableDrones: [DroneAdObject] = []
    @Published var activeDrone: DroneAdObject?
    @Published var isFlying = false
    @Published var isMovingRight = true
    @Published var interactionCount = 0
    @Published var lastInteractionTime: Date? = nil
    
    private var flightTimer: Timer?
    private var orientationCancellable: AnyCancellable?
    private var droneViewTime: [UUID: TimeInterval] = [:]
    private var sessionStartTime: Date = Date()
    
    init() {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        loadDrones()
        setupOrientationObserver()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.availableDrones.isEmpty {
                self.initializeDefaultDrones()
            }
            if self.activeDrone == nil, !self.availableDrones.isEmpty {
                self.selectDrone(self.availableDrones[0])
            }
        }
    }
    
    deinit {
        flightTimer?.invalidate()
        orientationCancellable?.cancel()
    }
    
    // MARK: - Setup Methods
    
    private func setupOrientationObserver() {
        orientationCancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .map { _ in UIDevice.current.orientation }
            .sink { [weak self] orientation in
                guard let self = self else { return }
                self.handleOrientationChange(orientation)
            }
    }
    
    private func handleOrientationChange(_ orientation: UIDeviceOrientation) {
        if orientation.isLandscape {
            stopFlying()
            activeDrone?.visible = false
        } else if orientation.isPortrait {
            activeDrone?.visible = true
            if !isFlying {
                startFlying()
            }
        }
    }
    
    // In DroneViewModel.swift, modify initializeDefaultDrones():
    // In DroneViewModel.swift
    public func initializeDefaultDrones() {
        // Clear existing saved drones first
        UserDefaults.standard.removeObject(forKey: "drones")
        
        // Start fresh with templates
        availableDrones = DroneAdObject.templates
        
        // Update ALL drones with localized banner text
        for i in 0..<availableDrones.count {
            var drone = availableDrones[i]
            drone.bannerText = "ad_banner".localized // Use localized string
            availableDrones[i] = drone
        }
        
        // Update the first drone with ad content
        if var demoDrone = availableDrones.first {
            demoDrone.adContent = AdContent(
                advertiserName: "ad_banner".localized, // Match banner text
                bannerImage: nil,
                targetURL: URL(string: "https://timekeeper.app/premium"),
                displayDuration: 15.0,
                priority: 10,
                startDate: Date(),
                endDate: Date().addingTimeInterval(60*60*24*365)
            )
            if let index = availableDrones.firstIndex(where: { $0.id == demoDrone.id }) {
                availableDrones[index] = demoDrone
            }
        }
        
        saveDrones()
    }
    
    // MARK: - Data Persistence
    
    func loadDrones() {
        if let data = UserDefaults.standard.data(forKey: "drones"),
           let decoded = try? JSONDecoder().decode([DroneAdObject].self, from: data) {
            availableDrones = decoded
            print("Loaded \(decoded.count) drones")
        }
    }
    
    func saveDrones() {
        if let encoded = try? JSONEncoder().encode(availableDrones) {
            UserDefaults.standard.set(encoded, forKey: "drones")
           
        }
    }
    
    // MARK: - Drone Management
    
    func selectDrone(_ drone: DroneAdObject) {
        if let currentDrone = activeDrone {
            let viewEndTime = Date()
            let startTime = droneViewTime[currentDrone.id] ?? viewEndTime.timeIntervalSince(sessionStartTime)
            let duration = viewEndTime.timeIntervalSince1970 - startTime
            droneViewTime[currentDrone.id] = duration
        }
        
        activeDrone = drone
        droneViewTime[drone.id] = Date().timeIntervalSince1970
        
        if let adContent = drone.adContent, adContent.isActive {
            let adId = adContent.id.uuidString
            
            if let index = availableDrones.firstIndex(where: { $0.id == drone.id }),
               var ad = availableDrones[index].adContent {
                ad.impressionCount += 1
                availableDrones[index].adContent = ad
                saveDrones()
            }
            
            logAdImpression(adId: adId, advertiser: adContent.advertiserName)
            
            Analytics.logEvent("drone_ad_impression", parameters: [
                "drone_name": drone.name,
                "advertiser": adContent.advertiserName,
                "timestamp": Date().timeIntervalSince1970
            ])
        }
    }
    
    // MARK: - Flight Controls
    
    func startFlying() {
        guard !isFlying else { return }
        isFlying = true
        
        // Reset position if it's out of bounds
        if var drone = activeDrone {
            let screenWidth = UIScreen.main.bounds.width
            if drone.position.x < -100 || drone.position.x > screenWidth + 100 ||
               drone.position.y < 100 || drone.position.y > 300 {
                drone.position = CGPoint(x: -50, y: 150)
                isMovingRight = true
                activeDrone = drone
            }
        }
    }
    
    func stopFlying() {
        isFlying = false
    }
    
    // MARK: - Ad Handling
    
    // In DroneSpriteView.swift, inside DroneViewModel
    func handleAdTap(scene: DroneScene?) {
        guard let drone = activeDrone, let adContent = drone.adContent, adContent.isActive else {
            return
        }
        
        let adId = adContent.id.uuidString
        
        if let index = availableDrones.firstIndex(where: { $0.id == drone.id }),
           var ad = availableDrones[index].adContent {
            ad.clickCount += 1
            availableDrones[index].adContent = ad
            saveDrones()
        }
        
        logAdClick(adId: adId, advertiser: adContent.advertiserName)
        
        Analytics.logEvent("drone_ad_click", parameters: [
            "drone_name": drone.name,
            "advertiser": adContent.advertiserName,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        // Trigger confetti and wait for completion
        if let scene = scene, let url = adContent.targetURL {
            scene.triggerConfetti(at: drone.position) {
                // This runs after confetti animation completes
                UIApplication.shared.open(url)
            }
        } else if let url = adContent.targetURL {
            // Fallback if scene isn’t available
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Analytics
    
    private func logAdImpression(adId: String, advertiser: String) {
        print("Ad impression logged: \(adId) - \(advertiser)")
    }
    
    private func logAdClick(adId: String, advertiser: String) {
        print("Ad click logged: \(adId) - \(advertiser)")
    }
    
    func logInteraction() {
        interactionCount += 1
        lastInteractionTime = Date()
        
        if interactionCount % 5 == 0 && !isFlying {
            startFlying()
        }
    }
}
