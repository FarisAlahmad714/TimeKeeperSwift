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
    @Published var isMovingRight = true // Track movement direction
    
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.availableSpaceships.isEmpty {
                self.initializeDefaultSpaceships()
            }
            if self.activeSpaceship == nil, !self.availableSpaceships.isEmpty {
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
    
    public func initializeDefaultSpaceships() {
        availableSpaceships = Spaceship.templates.filter { !$0.premium }
        
        if var demoShip = availableSpaceships.first {
            demoShip.adContent = AdContent(
                advertiserName: "YOUR AD HERE!",
                bannerImage: "premium_banner",
                targetURL: URL(string: "https://timekeeper.app/premium"),
                displayDuration: 15.0,
                priority: 10,
                startDate: Date(),
                endDate: Date().addingTimeInterval(60*60*24*365)
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

        }
    }
    
    // MARK: - Spaceship Management
    
    func selectSpaceship(_ spaceship: Spaceship) {
        if let currentShip = activeSpaceship {
            let viewEndTime = Date()
            let startTime = spaceshipViewTime[currentShip.id] ?? viewEndTime.timeIntervalSince(sessionStartTime)
            let duration = viewEndTime.timeIntervalSince1970 - startTime
            spaceshipViewTime[currentShip.id] = duration
        }
        
        activeSpaceship = spaceship
        spaceshipViewTime[spaceship.id] = Date().timeIntervalSince1970
        
        if let adContent = spaceship.adContent, adContent.isActive {
            let adId = adContent.id.uuidString
            adImpressions[adId] = (adImpressions[adId] ?? 0) + 1
            
            if let index = availableSpaceships.firstIndex(where: { $0.id == spaceship.id }),
               var ad = availableSpaceships[index].adContent {
                ad.impressionCount += 1
                availableSpaceships[index].adContent = ad
                saveSpaceships()
            }
            
            logAdImpression(adId: adId, advertiser: adContent.advertiserName)
        }
    }
    
    func purchasePremiumShip(_ ship: Spaceship) {
        guard ship.premium && !isPremiumUser else { return }
        
        let alertVC = UIAlertController(
            title: "Purchase \(ship.name)",
            message: "Would you like to purchase this premium ship for $0.99?",
            preferredStyle: .alert
        )
        
        alertVC.addAction(UIAlertAction(title: "Purchase", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            self.availableSpaceships.append(ship)
            self.saveSpaceships()
            self.selectSpaceship(ship)
            
            let confirmVC = UIAlertController(
                title: "Purchase Successful",
                message: "You now own the \(ship.name)!",
                preferredStyle: .alert
            )
            confirmVC.addAction(UIAlertAction(title: "OK", style: .default))
            
            DispatchQueue.main.async {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = windowScene.windows.first?.rootViewController {
                    rootViewController.present(confirmVC, animated: true)
                }
            }
        })
        
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alertVC, animated: true)
            }
        }
    }
    
    func checkPremiumStatus() {
        isPremiumUser = UserDefaults.standard.bool(forKey: "isPremiumUser")
    }
    
    // MARK: - Flight Controls
    
    func startFlying() {
        guard !isFlying else { return }
        isFlying = true
        
        // Reset position if it's out of bounds
        if var ship = activeSpaceship {
            let screenWidth = UIScreen.main.bounds.width
            if ship.position.x < -100 || ship.position.x > screenWidth + 100 ||
               ship.position.y < 100 || ship.position.y > 300 {
                ship.position = CGPoint(x: -50, y: 150)
                isMovingRight = true
                activeSpaceship = ship
            }
        }
        
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
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
        
        let screenSize = UIScreen.main.bounds.size
        let rightEdge: CGFloat = screenSize.width + 50.0
        let leftEdge: CGFloat = -50.0
        
        // Fixed Y position to ensure the spaceship stays at the intended height
        let fixedY: CGFloat = 150.0  // This is the desired fixed height
        
        // Apply horizontal movement based on direction
        if isMovingRight {
            ship.position.x += ship.speed * 2.0 // Increased speed for more noticeable movement
            if ship.position.x > rightEdge {
                isMovingRight = false
                print("Reached right edge, changing direction")
            }
        } else {
            ship.position.x -= ship.speed * 2.0 // Increased speed for more noticeable movement
            if ship.position.x < leftEdge {
                isMovingRight = true
                print("Reached left edge, changing direction")
            }
        }
        
        // Set a completely fixed Y position instead of allowing drift
        ship.position.y = fixedY
        
        // Important: Don't rotate the ship - we'll handle direction via scale effect in the view
        // ship.rotation = isMovingRight ? 0 : 180  <-- Removing this line
        ship.rotation = 0 // Keep consistent rotation
        
        activeSpaceship = ship
        
        // Save periodically
        if Int(Date().timeIntervalSince1970) % 10 == 0 {
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
            if !isFlying {
                startFlying()
            }
        }
    }
    
    // MARK: - Ad Handling
    
    func handleAdTap() {
        guard let ship = activeSpaceship, let adContent = ship.adContent, adContent.isActive else {
            return
        }
        
        let adId = adContent.id.uuidString
        adClicks[adId] = (adClicks[adId] ?? 0) + 1
        
        if let index = availableSpaceships.firstIndex(where: { $0.id == ship.id }),
           var ad = availableSpaceships[index].adContent {
            ad.clickCount += 1
            availableSpaceships[index].adContent = ad
            saveSpaceships()
        }
        
        logAdClick(adId: adId, advertiser: adContent.advertiserName)
        
        if let url = adContent.targetURL {
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

// Helper extension
extension UIDeviceOrientation {
    var isPortrait: Bool {
        return self == .portrait || self == .portraitUpsideDown
    }
    
    var isLandscape: Bool {
        return self == .landscapeLeft || self == .landscapeRight
    }
}
