// SpaceshipViewModel.swift

import SwiftUI
import StoreKit
import Combine

class SpaceshipViewModel: ObservableObject {
    @Published var availableSpaceships: [Spaceship] = []
    @Published var activeSpaceship: Spaceship?
    @Published var showSpaceshipSelector = false
    @Published var isPremiumUser = false
    @Published var adImpressions: [String: Int] = [:]
    @Published var adClicks: [String: Int] = [:]
    @Published var isFlying = false
    @Published var orientation: UIDeviceOrientation = .portrait
    @Published var interactionCount = 0
    @Published var lastInteractionTime: Date? = nil
    
    private var orientationCancellable: AnyCancellable?
    private var flightTimer: Timer?
    private var animationTimer: Timer?
    
    // Analytics
    private var sessionStartTime: Date = Date()
    private var spaceshipViewTime: [UUID: TimeInterval] = [:]
    
    init() {
        loadSpaceships()
        checkPremiumStatus()
        setupOrientationObserver()
        
        // Auto-select a ship if we have them
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.availableSpaceships.isEmpty {
                self.initializeDefaultSpaceships()
            }
            if self.activeSpaceship == nil && !self.availableSpaceships.isEmpty {
                self.selectSpaceship(self.availableSpaceships[0])
            }
        }
    }
    
    deinit {
        flightTimer?.invalidate()
        animationTimer?.invalidate()
        orientationCancellable?.cancel()
    }
    
    // MARK: - Setup Methods
    
    private func setupOrientationObserver() {
        orientationCancellable = NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)
            .map { _ in UIDevice.current.orientation }
            .sink { [weak self] orientation in
                guard let self = self else { return }
                self.orientation = orientation
                self.handleOrientationChange()
            }
    }
    
    // Changed from private to public so it can be called from AlarmSetterView
    public func initializeDefaultSpaceships() {
        availableSpaceships = Spaceship.templates.filter { !$0.premium }
        
        // Add demo ad content to one ship
        if var demoShip = availableSpaceships.first {
            demoShip.adContent = AdContent(
                advertiserName: "TimeKeeper Premium",
                bannerImage: "premium_banner",
                targetURL: URL(string: "https://timekeeper.app/premium"),
                displayDuration: 15.0,
                priority: 10,
                startDate: Date(),
                endDate: Date().addingTimeInterval(60*60*24*365) // 1 year
            )
            if let index = availableSpaceships.firstIndex(where: { $0.id == demoShip.id }) {
                availableSpaceships[index] = demoShip
            }
        }
        
        saveSpaceships()
    }
    
    // MARK: - Data Persistence
    
    func loadSpaceships() {
        if let data = UserDefaults.standard.data(forKey: "spaceships"),
           let decoded = try? JSONDecoder().decode([Spaceship].self, from: data) {
            availableSpaceships = decoded
            print("Loaded \(decoded.count) spaceships")
        }
    }
    
    func saveSpaceships() {
        if let encoded = try? JSONEncoder().encode(availableSpaceships) {
            UserDefaults.standard.set(encoded, forKey: "spaceships")
            print("Saved \(availableSpaceships.count) spaceships")
        }
    }
    
    // MARK: - Spaceship Management
    
    func selectSpaceship(_ spaceship: Spaceship) {
        // Record analytics for previous ship
        if let currentShip = activeSpaceship {
            let viewEndTime = Date()
            let startTime = spaceshipViewTime[currentShip.id] ?? viewEndTime.timeIntervalSince(sessionStartTime)
            let duration = viewEndTime.timeIntervalSince1970 - startTime
            spaceshipViewTime[currentShip.id] = duration
        }
        
        activeSpaceship = spaceship
        spaceshipViewTime[spaceship.id] = Date().timeIntervalSince1970
        
        // Update ad impressions
        if let adContent = spaceship.adContent, adContent.isActive {
            let adId = adContent.id.uuidString
            adImpressions[adId] = (adImpressions[adId] ?? 0) + 1
            
            // Track impression in the model
            if let index = availableSpaceships.firstIndex(where: { $0.id == spaceship.id }),
               var ad = availableSpaceships[index].adContent {
                ad.impressionCount += 1
                availableSpaceships[index].adContent = ad
                saveSpaceships()
            }
            
            // Report to analytics
            logAdImpression(adId: adId, advertiser: adContent.advertiserName)
        }
    }
    
    func purchasePremiumShip(_ ship: Spaceship) {
        // This would be replaced with actual in-app purchase logic
        guard ship.premium && !isPremiumUser else { return }
        
        // Simulate IAP flow (in real app, this would be StoreKit logic)
        let alertVC = UIAlertController(
            title: "Purchase \(ship.name)",
            message: "Would you like to purchase this premium ship for $0.99?",
            preferredStyle: .alert
        )
        
        alertVC.addAction(UIAlertAction(title: "Purchase", style: .default) { [weak self] _ in
            // Simulate successful purchase
            guard let self = self else { return }
            
            // Add ship to available ships
            self.availableSpaceships.append(ship)
            self.saveSpaceships()
            self.selectSpaceship(ship)
            
            // Show confirmation
            let confirmVC = UIAlertController(
                title: "Purchase Successful",
                message: "You now own the \(ship.name)!",
                preferredStyle: .alert
            )
            confirmVC.addAction(UIAlertAction(title: "OK", style: .default))
            
            // Fix the deprecated windows API usage - use scene-based approach instead
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(confirmVC, animated: true)
                }
            }
        })
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Fix the deprecated windows API usage - use scene-based approach
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alertVC, animated: true)
            }
        }
    }
    
    func checkPremiumStatus() {
        // In a real app, this would check for an active subscription or premium purchase
        // For now, just simulate it
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    // MARK: - Flight Controls
    
    func startFlying() {
        guard !isFlying else { return }
        isFlying = true
        
        // Start animation timer for ship movement
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateSpaceshipPosition()
        }
    }
    
    func stopFlying() {
        isFlying = false
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateSpaceshipPosition() {
        guard isFlying, var ship = activeSpaceship, orientation.isPortrait else { return }
        
        // For smooth right to left horizontal movement like a hot air balloon
        let screenSize = UIScreen.main.bounds.size
        
        // Update position - move from right to left
        ship.position.x -= ship.speed * 2.0
        
        // If the ship goes off the left edge, wrap it around to the right
        if ship.position.x < -50 {
            ship.position.x = screenSize.width + 50
            // Slightly randomize the vertical position when coming back
            ship.position.y = CGFloat.random(in: 100...screenSize.height/2)
        }
        
        // Add slight vertical drift for more natural movement
        let verticalDrift = sin(Date().timeIntervalSince1970 * 0.5) * 0.5
        ship.position.y += CGFloat(verticalDrift)
        
        // Keep the ship within vertical bounds
        let minY: CGFloat = 80
        let maxY: CGFloat = screenSize.height / 2
        ship.position.y = min(max(ship.position.y, minY), maxY)
        
        // Keep the rotation facing left for realistic direction
        ship.rotation = .pi // Point left
        
        // Update active ship
        activeSpaceship = ship
        
        // Save every few seconds to avoid excessive writes
        if Int(Date().timeIntervalSince1970) % 5 == 0 {
            if let index = availableSpaceships.firstIndex(where: { $0.id == ship.id }) {
                availableSpaceships[index] = ship
                saveSpaceships()
            }
        }
    }
    
    private func handleOrientationChange() {
        if orientation.isLandscape {
            stopFlying()
            activeSpaceship?.visible = false
        } else if orientation.isPortrait {
            activeSpaceship?.visible = true
        }
    }
    
    // MARK: - Ad Handling
    
    func handleAdTap() {
        guard let ship = activeSpaceship, let adContent = ship.adContent, adContent.isActive else {
            return
        }
        
        let adId = adContent.id.uuidString
        adClicks[adId] = (adClicks[adId] ?? 0) + 1
        
        // Track click in the model
        if let index = availableSpaceships.firstIndex(where: { $0.id == ship.id }),
           var ad = availableSpaceships[index].adContent {
            ad.clickCount += 1
            availableSpaceships[index].adContent = ad
            saveSpaceships()
        }
        
        // Log analytics
        logAdClick(adId: adId, advertiser: adContent.advertiserName)
        
        // Open ad URL if available
        if let url = adContent.targetURL {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Analytics
    
    private func logAdImpression(adId: String, advertiser: String) {
        print("Ad impression logged: \(adId) - \(advertiser)")
        // In a real app, this would send data to your analytics service
    }
    
    private func logAdClick(adId: String, advertiser: String) {
        print("Ad click logged: \(adId) - \(advertiser)")
        // In a real app, this would send data to your analytics service
    }
    
    func logInteraction() {
        interactionCount += 1
        lastInteractionTime = Date()
        
        // After a certain number of interactions, show the ship if it's not already flying
        if interactionCount % 5 == 0 && !isFlying {
            startFlying()
        }
    }
}

// Helper extension
extension UIDeviceOrientation {
    var isPortrait: Bool {
        return self == .portrait || self == .portraitUpsideDown
    }
    
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
}
