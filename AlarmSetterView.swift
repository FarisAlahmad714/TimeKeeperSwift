import SwiftUI
import FirebaseAnalytics
import GameKit

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Seeded Random Generator for consistent star positions
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var rng: GKRandomSource
    
    init(seed: Int) {
        self.rng = GKMersenneTwisterRandomSource(seed: UInt64(seed))
    }
    
    mutating func next() -> UInt64 {
        // GKRandom produces values in [0, 1], we need values in [0, UInt64.max]
        let lower = UInt64(rng.nextInt(upperBound: Int.max))
            let upper = UInt64(rng.nextInt(upperBound: Int.max))
            return (upper << 32) | lower    }
}

// MARK: - WaveShape
struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        for x in stride(from: rect.minX, to: rect.maxX, by: 10) {
            let y = sin(x * 0.1) * 5 + rect.midY
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Color Extension
extension Color {
    func lerp(to endColor: Color, t: Double) -> Color {
        // Apply cubic ease-in-out function to t
        let easedT: Double
        if t < 0.5 {
            easedT = 4 * t * t * t
        } else {
            easedT = 1 - pow(-2 * t + 2, 3) / 2
        }
        
        let startComponents = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let endComponents = UIColor(endColor).cgColor.components ?? [0, 0, 0, 1]
        let r = (1 - easedT) * Double(startComponents[0]) + easedT * Double(endComponents[0])
        let g = (1 - easedT) * Double(startComponents[1]) + easedT * Double(endComponents[1])
        let b = (1 - easedT) * Double(startComponents[2]) + easedT * Double(endComponents[2])
        let a = (1 - easedT) * Double(startComponents[3]) + easedT * Double(endComponents[3])
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

struct AlarmSetterView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @StateObject private var spaceshipViewModel = SpaceshipViewModel()
    @StateObject private var droneViewModel = DroneViewModel()
    @State private var selectedTime: Date = Date()
    @State private var isDragging = false
    @State private var showAlarmsView = false
    @State private var sunMoonOffset: CGFloat = 0.0
    @State private var isDayTime = true
    @State private var treeOffset: CGFloat = UIScreen.main.bounds.width
    @State private var humanOffset: CGFloat = UIScreen.main.bounds.width
    @State private var carOffset: CGFloat = -100
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var previousOrientation: UIDeviceOrientation = .unknown
    @State private var isTransitioningOrientation = false
    @State private var animationsEnabled = true
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private let calendar = Calendar.current
    private let startOfDay: Date = Calendar.current.startOfDay(for: Date())

    private var totalMinutesInDay: Int {
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return calendar.dateComponents([.minute], from: startOfDay, to: endOfDay).minute!
    }

    private var sliderProgress: Double {
        let minutesSinceMidnight = calendar.dateComponents([.minute], from: startOfDay, to: selectedTime).minute ?? 0
        return Double(minutesSinceMidnight) / Double(totalMinutesInDay)
    }
    
    // Helper functions for sun, moon, and star effects
    private func getSunIntensity(progress: Double) -> Double {
        // Sun is brightest at noon (0.5), dimmer at sunrise/sunset
        if progress < 0.25 || progress > 0.75 {
            return 0.5
        } else {
            // Peak at noon with a bell curve
            return 1.0 - (abs(progress - 0.5) * 2.0)
        }
    }
    
    private func getMoonIntensity(progress: Double) -> Double {
        // Moon is brightest at midnight (0.0/1.0)
        if progress < 0.1 {
            return 1.0 - (progress * 10.0)
        } else if progress > 0.9 {
            return (progress - 0.9) * 10.0
        } else {
            return 0.0
        }
    }
    
    private func getStarOpacity(_ progress: Double) -> Double {
        // Stars brightest at midnight (0.0 or 1.0)
        if progress < 0.2 {
            return 1.0 - (progress / 0.2)
        } else if progress > 0.8 {
            return (progress - 0.8) / 0.2
        } else {
            return 0.0
        }
    }

    private func getBackgroundGradient(for progress: Double) -> LinearGradient {
        // Keep your existing keyTimes
        let keyTimes: [Double] = [0.0, 0.2083, 0.2917, 0.5, 0.7083, 0.9167, 1.0]
        
        // Enhanced realistic sky colors
        let keyGradients: [[Color]] = [
            // Midnight (0.0) - Deep blue to indigo
            [Color(red: 0.05, green: 0.05, blue: 0.15),
             Color(red: 0.1, green: 0.05, blue: 0.2),
             Color(red: 0.15, green: 0.1, blue: 0.25)],
            
            // Dawn (0.2083) - Pinks and purples
            [Color(red: 0.3, green: 0.1, blue: 0.3),
             Color(red: 0.7, green: 0.3, blue: 0.5),
             Color(red: 0.9, green: 0.5, blue: 0.6)],
            
            // Morning (0.2917) - Rich orange to light blue
            [Color(red: 0.9, green: 0.6, blue: 0.3),
             Color(red: 0.7, green: 0.7, blue: 0.9),
             Color(red: 0.6, green: 0.8, blue: 1.0)],
            
            // Noon (0.5) - Sky blue gradient
            [Color(red: 0.4, green: 0.7, blue: 0.9),
             Color(red: 0.5, green: 0.8, blue: 1.0),
             Color(red: 0.6, green: 0.85, blue: 1.0)],
            
            // Sunset beginning (0.7083) - Blue to orange
            [Color(red: 0.6, green: 0.8, blue: 0.9),
             Color(red: 0.9, green: 0.7, blue: 0.5),
             Color(red: 1.0, green: 0.6, blue: 0.4)],
            
            // Dusk (0.9167) - Orange to deep purple
            [Color(red: 0.7, green: 0.4, blue: 0.3),
             Color(red: 0.4, green: 0.2, blue: 0.4),
             Color(red: 0.2, green: 0.1, blue: 0.3)],
            
            // Back to Midnight (1.0) - Deep blue to indigo (same as 0.0)
            [Color(red: 0.05, green: 0.05, blue: 0.15),
             Color(red: 0.1, green: 0.05, blue: 0.2),
             Color(red: 0.15, green: 0.1, blue: 0.25)]
        ]
        
        // Rest of your existing function remains the same
        var startIndex = 0
        for i in 0..<keyTimes.count - 1 {
            if progress >= keyTimes[i] && progress <= keyTimes[i + 1] {
                startIndex = i
                break
            }
        }
        
        let startGradient = keyGradients[startIndex]
        let endGradient = keyGradients[startIndex + 1]
        let t = (progress - keyTimes[startIndex]) / (keyTimes[startIndex + 1] - keyTimes[startIndex])
        
        let interpolatedColors = startGradient.enumerated().map { index, startColor in
            let endColor = endGradient[index]
            return startColor.lerp(to: endColor, t: t)
        }
        
        // Modify gradient direction based on time of day
        let startPoint: UnitPoint
        let endPoint: UnitPoint
        
        if progress < 0.25 || progress > 0.75 {
            // Night/dawn/dusk - more horizontal gradient
            startPoint = .bottomLeading
            endPoint = .topTrailing
        } else {
            // Day - more vertical gradient
            startPoint = .bottom
            endPoint = .top
        }
        
        return LinearGradient(gradient: Gradient(colors: interpolatedColors),
                              startPoint: startPoint,
                              endPoint: endPoint)
    }

    private func adjustTime(by minutes: Int) {
        let minutesSinceMidnight = calendar.dateComponents([.minute], from: startOfDay, to: selectedTime).minute ?? 0
        var newMinutes = minutesSinceMidnight + minutes
        if newMinutes >= totalMinutesInDay { newMinutes = newMinutes % totalMinutesInDay } else if newMinutes < 0 { newMinutes = totalMinutesInDay + newMinutes }
        selectedTime = calendar.date(byAdding: .minute, value: newMinutes, to: startOfDay)!
        let progress = Double(newMinutes) / Double(totalMinutesInDay)
        withAnimation(.easeInOut(duration: 0.3)) {
            sunMoonOffset = progress - 0.5
            isDayTime = calendar.component(.hour, from: selectedTime) >= 6 && calendar.component(.hour, from: selectedTime) < 18
        }
        
        updateAdObjectsForTime()
    }
    
    private func updateAdObjectsForTime() {
        updateSpaceshipForTime()
        updateDroneForTime()
    }

    private func calculateSliderOffset(geometry: GeometryProxy) -> CGFloat {
        let trackWidth = geometry.size.width - 40
        return (sliderProgress * trackWidth) - (trackWidth / 2)
    }

    private func calculateSunMoonYPosition(geometry: GeometryProxy) -> CGFloat {
        let normalizedProgress = (sunMoonOffset + 0.5)
        let heightRange: CGFloat = 100
        let baseY: CGFloat = 150
        let a: CGFloat = 4 * heightRange
        let yOffset = -a * pow(normalizedProgress - 0.5, 2) + heightRange
        return baseY - yOffset
    }

    private func updateSpaceshipForTime() {
        guard var ship = spaceshipViewModel.activeSpaceship else { return }
        
        ship.visible = true
        ship.scale = 1.5
        ship.speed = 1.0
        
        if sliderProgress >= 0.2083 && sliderProgress < 0.2917 {
            ship.speed = 1.5
            if ship.premium { ship.specialEffect = .glow }
        } else if sliderProgress >= 0.2917 && sliderProgress < 0.7083 {
            ship.speed = 1.0
            if ship.premium { ship.specialEffect = .trail }
        } else if sliderProgress >= 0.7083 && sliderProgress < 0.7917 {
            ship.speed = 1.3
            if ship.premium { ship.specialEffect = .warpField }
        } else {
            ship.speed = 0.7
            if ship.premium { ship.specialEffect = .teleport }
        }
        
        print("Ship speed set to: \(ship.speed)")
        
        if !spaceshipViewModel.isFlying && !isTransitioningOrientation {
            spaceshipViewModel.startFlying()
        }
        
        spaceshipViewModel.activeSpaceship = ship
    }
    
    // Function to update drones based on time
    private func updateDroneForTime() {
        guard var drone = droneViewModel.activeDrone else { return }
        
        drone.visible = true
        
        // Adjust drone properties based on time
        if sliderProgress >= 0.2083 && sliderProgress < 0.2917 {
            // Dawn - Faster drones
            drone.speed = 1.2
            drone.hoverAmplitude = 4.0
        } else if sliderProgress >= 0.2917 && sliderProgress < 0.7083 {
            // Day - Normal speed
            drone.speed = 0.8
            drone.hoverAmplitude = 2.0
        } else if sliderProgress >= 0.7083 && sliderProgress < 0.7917 {
            // Dusk - Medium speed
            drone.speed = 1.0
            drone.hoverAmplitude = 3.0
        } else {
            // Night - Slow drones
            drone.speed = 0.5
            drone.hoverAmplitude = 5.0
        }
        
        if !droneViewModel.isFlying && !isTransitioningOrientation {
            droneViewModel.startFlying()
        }
        
        droneViewModel.activeDrone = drone
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    getBackgroundGradient(for: sliderProgress)
                        .ignoresSafeArea()
                        .overlay(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    isDayTime ?
                                        Color.white.opacity(0.3 * getSunIntensity(progress: sliderProgress)) :
                                        Color.white.opacity(0.1 * getMoonIntensity(progress: sliderProgress)),
                                    Color.clear
                                ]),
                                center: .init(x: sunMoonOffset + 0.5, y: 0.1),
                                startRadius: 0,
                                endRadius: isDayTime ? 200 : 100
                            )
                        )
                    
                    if !isDayTime && animationsEnabled {
                        TimelineView(.animation(minimumInterval: 0.5, paused: false)) { _ in
                            Canvas { context, size in
                                // Use a deterministic seed for consistent star positions
                                let seed = 12345
                                var randomGen = SeededRandomNumberGenerator(seed: seed)

                                // Create a star field with various sizes and brightnesses
                                for i in 0..<100 {
                                    // Fixed positions based on index
                                    let x = CGFloat(Double.random(in: 0...1, using: &randomGen) * size.width)
                                    let y = CGFloat(Double.random(in: 0...1, using: &randomGen) * size.height)
                                    
                                    // Vary star sizes - brighter stars are larger
                                    let brightness = Double.random(in: 0.3...1.0, using: &randomGen)
                                    let baseStarSize = Double.random(in: 1.0...2.5, using: &randomGen) * brightness
                                    
                                    // Apply a subtle twinkle effect
                                    let time = Date().timeIntervalSince1970
                                    let twinkleSpeed = Double.random(in: 0.5...2.0, using: &randomGen)
                                    let twinkleFactor = sin(time * twinkleSpeed + Double(i)) * 0.3 + 0.7
                                    
                                    // Adjust brightness by time of day
                                    let timeBasedOpacity = getStarOpacity(sliderProgress)
                                    let finalOpacity = brightness * timeBasedOpacity * twinkleFactor
                                    
                                    // Draw star
                                    let starSize = baseStarSize * (isDragging ? 1.0 : twinkleFactor)
                                    context.opacity = finalOpacity
                                    
                                    // Create tiny glow effect for brighter stars
                                    if brightness > 0.7 {
                                        // Soft glow for bright stars
                                        context.fill(
                                            Path(ellipseIn: CGRect(x: x-starSize/2, y: y-starSize/2, width: starSize*2.5, height: starSize*2.5)),
                                            with: .color(.white.opacity(0.05 * finalOpacity))
                                        )
                                    }
                                    
                                    // Main star point
                                    context.fill(
                                        Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)),
                                        with: .color(.white)
                                    )
                                }
                            }
                            .opacity(isTransitioningOrientation ? 0 : 1)
                        }
                    }
                    
                    // Show drone at higher altitude
                    DroneAdView()
                        .frame(height: 200)
                        .position(x: geometry.size.width / 2, y: 100) // Higher position in the sky
                        .opacity(isTransitioningOrientation ? 0 : 1)
                    
                    ZStack {
                        if (sliderProgress >= 0.9167 && sliderProgress <= 1.0) || (sliderProgress >= 0.0 && sliderProgress < 0.2083) {
                            BedroomEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.95 || sliderProgress < 0.15 ? 1.0 : 0.5)
                                .animation(animationsEnabled ? .easeInOut(duration: 1.0) : .none, value: sliderProgress)
                        }
                        if sliderProgress >= 0.2083 && sliderProgress < 0.2917 {
                            BeachEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.25 && sliderProgress < 0.27 ? 1.0 : 0.5)
                                .animation(animationsEnabled ? .easeInOut(duration: 1.0) : .none, value: sliderProgress)
                        }
                        if sliderProgress >= 0.2917 && sliderProgress < 0.7083 {
                            CityEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.35 && sliderProgress < 0.65 ? 1.0 : 0.5)
                                .animation(animationsEnabled ? .easeInOut(duration: 1.0) : .none, value: sliderProgress)
                        }
                        if sliderProgress >= 0.7083 && sliderProgress < 0.9167 {
                            NeighborhoodEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.75 && sliderProgress < 0.85 ? 1.0 : 0.5)
                                .animation(animationsEnabled ? .easeInOut(duration: 1.0) : .none, value: sliderProgress)
                        }
                    }
                    .opacity(isTransitioningOrientation ? 0 : 1)
                    
                    if sliderProgress >= 0.25 && sliderProgress < 0.9 {
                        ZStack {
                            TreeView().offset(x: -geometry.size.width / 4, y: geometry.size.height - 80).opacity(sliderProgress > 0.3 ? 1.0 : sliderProgress - 0.25)
                            TreeView().offset(x: geometry.size.width / 4, y: geometry.size.height - 60).opacity(sliderProgress > 0.3 ? 1.0 : sliderProgress - 0.25)
                        }
                        .animation(animationsEnabled ? .easeInOut(duration: 1.0) : .none, value: sliderProgress)
                        .opacity(isTransitioningOrientation ? 0 : 1)
                    }
                    
                    // Spaceship at original position
                    Group {
                        if let activeShip = spaceshipViewModel.activeSpaceship, activeShip.visible && !isTransitioningOrientation {
                            let shipPosition = activeShip.position
                            
                            if spaceshipViewModel.isMovingRight {
                                ThrusterView()
                                    .position(x: shipPosition.x - 40, y: shipPosition.y)
                                    .opacity(isTransitioningOrientation ? 0 : 1)
                            } else {
                                ThrusterView()
                                    .scaleEffect(x: -1, y: 1)
                                    .position(x: shipPosition.x + 40, y: shipPosition.y)
                                    .opacity(isTransitioningOrientation ? 0 : 1)
                            }
                            
                            if let _ = UIImage(named: activeShip.imageAsset) {
                                Image(activeShip.imageAsset)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80 * activeShip.scale, height: 80 * activeShip.scale)
                                    .scaleEffect(x: spaceshipViewModel.isMovingRight ? 1 : -1, y: 1)
                                    .position(x: shipPosition.x, y: shipPosition.y)
                                    .opacity(isTransitioningOrientation ? 0 : 1)
                                    .onTapGesture {
                                        if !isTransitioningOrientation {
                                            spaceshipViewModel.logInteraction()
                                            if activeShip.adContent != nil {
                                                Analytics.logEvent("spaceship_ad_click", parameters: [
                                                    "ship_name": activeShip.name,
                                                    "advertiser": activeShip.adContent?.advertiserName ?? "unknown",
                                                    "timestamp": Date().timeIntervalSince1970
                                                ])
                                            }
                                        }
                                    }
                            } else {
                                Image(systemName: "airplane")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80 * activeShip.scale, height: 80 * activeShip.scale)
                                    .scaleEffect(x: spaceshipViewModel.isMovingRight ? 1 : -1, y: 1)
                                    .position(x: shipPosition.x, y: shipPosition.y)
                                    .opacity(isTransitioningOrientation ? 0 : 1)
                                    .onTapGesture {
                                        if !isTransitioningOrientation {
                                            spaceshipViewModel.logInteraction()
                                            if activeShip.adContent != nil {
                                                Analytics.logEvent("spaceship_ad_click", parameters: [
                                                    "ship_name": activeShip.name,
                                                    "advertiser": activeShip.adContent?.advertiserName ?? "unknown",
                                                    "timestamp": Date().timeIntervalSince1970
                                                ])
                                            }
                                        }
                                    }
                            }
                        }
                        
                        if let activeShip = spaceshipViewModel.activeSpaceship, activeShip.visible && !isTransitioningOrientation {
                            let shipPosition = activeShip.position
                            
                            Text("YOUR AD HERE!...")
                                .foregroundColor(.white)
                                .font(.caption).bold()
                                .padding(10)
                                .frame(width: 150, height: 30)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(5)
                                .overlay(
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .offset(x: spaceshipViewModel.isMovingRight ? -5 : 5, y: 0),
                                    alignment: spaceshipViewModel.isMovingRight ? .leading : .trailing
                                )
                                .position(x: shipPosition.x, y: shipPosition.y - 30)
                                .opacity(isTransitioningOrientation ? 0 : 1)
                                .onAppear {
                                    if activeShip.adContent != nil {
                                        Analytics.logEvent("spaceship_ad_impression", parameters: [
                                            "ship_name": activeShip.name,
                                            "advertiser": activeShip.adContent?.advertiserName ?? "unknown",
                                            "timestamp": Date().timeIntervalSince1970
                                        ])
                                    }
                                }
                                .onTapGesture {
                                    if !isTransitioningOrientation {
                                        spaceshipViewModel.logInteraction()
                                        if activeShip.adContent != nil {
                                            spaceshipViewModel.handleAdTap()
                                            Analytics.logEvent("spaceship_ad_click", parameters: [
                                                "ship_name": activeShip.name,
                                                "advertiser": activeShip.adContent?.advertiserName ?? "unknown",
                                                "timestamp": Date().timeIntervalSince1970
                                            ])
                                        }
                                    }
                                }
                                .shadow(color: .blue, radius: 2)
                        }
                    }
                    
                    ZStack {
                        if sunMoonOffset > 0.2 {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), center: .center, startRadius: 0, endRadius: 25))
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                                    .offset(x: 10, y: -10)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .offset(x: -12, y: 5)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .offset(x: 5, y: 10)
                                Image("rightmoon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
                        } else if sunMoonOffset < -0.2 {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), center: .center, startRadius: 0, endRadius: 25))
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                                    .offset(x: 10, y: -10)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .offset(x: -12, y: 5)
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 6, height: 6)
                                    .offset(x: 5, y: 10)
                                Image("leftmoon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(RadialGradient(gradient: Gradient(colors: [Color.white, Color.yellow, Color.orange]), center: .center, startRadius: 0, endRadius: 25))
                                    .frame(width: 50, height: 50)
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                Image("sun")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.orange.opacity(0.5), radius: 20, x: 0, y: 0)
                        }
                    }
                    .position(x: geometry.size.width * (sunMoonOffset + 0.5), y: calculateSunMoonYPosition(geometry: geometry))
                    .animation(.easeInOut(duration: 0.3), value: sunMoonOffset)
                    .opacity(isTransitioningOrientation ? 0 : 1)
                    
                    HStack(spacing: 10) {
                        VStack(spacing: 5) {
                            Button(action: { adjustTime(by: 60) }) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                            }
                            .disabled(isTransitioningOrientation)
                            
                            Button(action: { adjustTime(by: -60) }) {
                                Image(systemName: "minus.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                            }
                            .disabled(isTransitioningOrientation)
                        }
                        Text(timeFormatter.string(from: selectedTime))
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(radius: 5)
                        VStack(spacing: 5) {
                            Button(action: { adjustTime(by: 1) }) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                            }
                            .disabled(isTransitioningOrientation)
                            
                            Button(action: { adjustTime(by: -1) }) {
                                Image(systemName: "minus.circle")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(.white)
                            }
                            .disabled(isTransitioningOrientation)
                        }
                    }
                    .position(x: geometry.size.width / 2, y: 200)
                    .opacity(isTransitioningOrientation ? 0.5 : 1)
                    
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 20)
                                .frame(width: geometry.size.width - 40)
                            ZStack {
                                Circle()
                                    .fill(
                                        AngularGradient(
                                            gradient: Gradient(colors: [
                                                Color(red: 0.2, green: 0.1, blue: 0.4).opacity(0.9),
                                                Color(red: 0.1, green: 0.2, blue: 0.5).opacity(0.7),
                                                Color(red: 0.9, green: 0.8, blue: 1.0).opacity(0.3),
                                                Color(red: 0.5, green: 0.1, blue: 0.6).opacity(0.8),
                                                Color(red: 0.8, green: 0.4, blue: 0.2).opacity(0.5),
                                                Color(red: 0.0, green: 0.0, blue: 0.2).opacity(0.9),
                                                Color(red: 0.2, green: 0.1, blue: 0.4).opacity(0.9)
                                            ]),
                                            center: .center,
                                            angle: .degrees(isDragging ? 360 : 0)
                                        )
                                    )
                                    .frame(width: 30, height: 30)
                                    .blur(radius: 2)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [Color.white.opacity(0.6), Color.blue.opacity(0.3), Color.clear]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 2
                                            )
                                    )
                                    .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 0)
                                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 0)
                                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isDragging)
                                ForEach(0..<3) { _ in
                                    Circle()
                                        .fill(Color.white.opacity(Double.random(in: 0.5...0.8)))
                                        .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                                        .offset(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: -10...10))
                                }
                            }
                            .offset(x: calculateSliderOffset(geometry: geometry))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        if !isTransitioningOrientation {
                                            isDragging = true
                                            let trackWidth = geometry.size.width - 40
                                            let dragX = value.location.x - (geometry.size.width / 2) + (trackWidth / 2)
                                            let boundedX = max(-trackWidth / 2, min(dragX, trackWidth / 2))
                                            let progress = (boundedX + trackWidth / 2) / trackWidth
                                            selectedTime = calendar.date(byAdding: .minute, value: Int(progress * Double(totalMinutesInDay)), to: startOfDay)!
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                sunMoonOffset = progress - 0.5
                                                isDayTime = calendar.component(.hour, from: selectedTime) >= 6 && calendar.component(.hour, from: selectedTime) < 18
                                            }
                                            updateAdObjectsForTime()
                                            Analytics.logEvent("slider_dragged", parameters: [
                                                "progress": progress,
                                                "selected_time": timeFormatter.string(from: selectedTime)
                                            ])
                                        }
                                    }
                                    .onEnded { _ in
                                        isDragging = false
                                    }
                            )
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 20)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 150)
                    .zIndex(1)
                    .opacity(isTransitioningOrientation ? 0.5 : 1)
                    .disabled(isTransitioningOrientation)
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            if !isTransitioningOrientation {
                                // Just set the time and open the form
                                viewModel.alarmTime = selectedTime
                                viewModel.alarmDate = selectedTime
                                viewModel.eventInstances = [] // Empty array - no instances created yet
                                
                                showAlarmsView = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    // Go directly to event alarm creation
                                    viewModel.activeModal = .eventAlarm
                                }
                                Analytics.logEvent("set_alarm_tapped", parameters: [
                                    "selected_time": timeFormatter.string(from: selectedTime)
                                ])
                            }
                        }) {
                            VStack {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                Text("Set Alarm")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isTransitioningOrientation)
                        
                        Button(action: {
                            if !isTransitioningOrientation {
                                showAlarmsView = true
                                Analytics.logEvent("alarms_button_tapped", parameters: [:])
                            }
                        }) {
                            VStack {
                                Image(systemName: "alarm.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                                Text("Alarms")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            }
                        }
                        .disabled(isTransitioningOrientation)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 80)
                    .zIndex(2)
                    .opacity(isTransitioningOrientation ? 0.5 : 1)
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showAlarmsView) { AlarmsView() }
                .onAppear {
                    // Initialize spaceships
                    if spaceshipViewModel.availableSpaceships.isEmpty {
                        spaceshipViewModel.initializeDefaultSpaceships()
                    }
                    
                    if spaceshipViewModel.activeSpaceship == nil, let firstShip = spaceshipViewModel.availableSpaceships.first {
                        var updatedShip = firstShip
                        updatedShip.position = CGPoint(x: -50, y: 150)
                        updatedShip.visible = true
                        updatedShip.scale = 1.5
                        updatedShip.rotation = 0
                        spaceshipViewModel.selectSpaceship(updatedShip)
                        spaceshipViewModel.startFlying()
                    }
                    
                    // Initialize drones
                    if droneViewModel.availableDrones.isEmpty {
                        droneViewModel.initializeDefaultDrones()
                    }
                    
                    if droneViewModel.activeDrone == nil, let firstDrone = droneViewModel.availableDrones.first {
                        var updatedDrone = firstDrone
                        updatedDrone.position = CGPoint(x: -50, y: 100) // Higher position for drones
                        updatedDrone.visible = true
                        droneViewModel.selectDrone(updatedDrone)
                        droneViewModel.startFlying()
                    }
                    
                    viewModel.alarmTime = selectedTime
                    
                    // Add orientation change handling
                    NotificationCenter.default.addObserver(
                        forName: UIDevice.orientationDidChangeNotification,
                        object: nil,
                        queue: .main
                    ) { [self] _ in
                        let currentOrientation = UIDevice.current.orientation
                        
                        if currentOrientation != previousOrientation &&
                           (currentOrientation.isPortrait || currentOrientation.isLandscape) {
                            
                            // Set flags to pause animations
                            isTransitioningOrientation = true
                            animationsEnabled = false
                            
                            // Force stop animations in both ViewModels
                            spaceshipViewModel.stopFlying()
                            droneViewModel.stopFlying()
                            
                            // Reset positions without animation
                            withAnimation(.none) {
                                sunMoonOffset = sliderProgress - 0.5
                                treeOffset = UIScreen.main.bounds.width
                                humanOffset = UIScreen.main.bounds.width
                                carOffset = -100
                                
                                // Reset spaceship
                                if var ship = spaceshipViewModel.activeSpaceship {
                                    ship.position = CGPoint(x: -50, y: 150)
                                    spaceshipViewModel.activeSpaceship = ship
                                }
                                
                                // Reset drone
                                if var drone = droneViewModel.activeDrone {
                                    drone.position = CGPoint(x: -50, y: 100)
                                    droneViewModel.activeDrone = drone
                                }
                            }
                            
                            // Wait for layout to stabilize - use a longer delay for more reliability
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // Resume animations
                                    isTransitioningOrientation = false
                                    animationsEnabled = true
                                }
                                
                                // Resume animations if portrait
                                if currentOrientation.isPortrait {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        updateAdObjectsForTime()
                                        spaceshipViewModel.startFlying()
                                        droneViewModel.startFlying()
                                    }
                                }
                            }
                            
                            previousOrientation = currentOrientation
                        }
                    }
                    
                    Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                        AnalyticsParameterScreenName: "Alarm Setter",
                        AnalyticsParameterScreenClass: "AlarmSetterView"
                    ])
                }
                .onDisappear {
                    // Remove the observer when view disappears
                    NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
                    spaceshipViewModel.stopFlying()
                    droneViewModel.stopFlying()
                }
            }
        }
    }
}

// Rest of existing view components remain the same// MARK: - ThrusterView
struct ThrusterView: View {
    @State private var flameAnimation: Double = 0
    
    var body: some View {
        ZStack {
            ZStack {
                Triangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.white, .yellow, .orange]), startPoint: .trailing, endPoint: .leading))
                    .frame(width: 35 + CGFloat(sin(flameAnimation) * 5), height: 16)
                    .blur(radius: 1)
                Triangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.orange, .red, .red.opacity(0.5)]), startPoint: .trailing, endPoint: .leading))
                    .frame(width: 45 + CGFloat(sin(flameAnimation) * 8), height: 22)
                    .blur(radius: 2)
                ForEach(0..<6) { i in
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [.orange, .red, .clear]), startPoint: .trailing, endPoint: .leading))
                        .frame(width: CGFloat.random(in: 4...7), height: CGFloat.random(in: 4...7))
                        .offset(x: -10 - CGFloat(i) * 5 - CGFloat(sin(flameAnimation) * 3), y: CGFloat.random(in: -10...10))
                        .opacity(0.7)
                        .blur(radius: 1)
                }
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                flameAnimation = .pi * 2
            }
        }
    }
}



// Add these helper functions
private func getSunIntensity(progress: Double) -> Double {
    // Sun is brightest at noon (0.5), dimmer at sunrise/sunset
    if progress < 0.25 || progress > 0.75 {
        return 0.5
    } else {
        // Peak at noon with a bell curve
        return 1.0 - (abs(progress - 0.5) * 2.0)
    }
}

private func getMoonIntensity(progress: Double) -> Double {
    // Moon is brightest at midnight (0.0/1.0)
    if progress < 0.1 {
        return 1.0 - (progress * 10.0)
    } else if progress > 0.9 {
        return (progress - 0.9) * 10.0
    } else {
        return 0.0
    }
}

// MARK: - SnowglobeShape
struct SnowglobeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.width / 2
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.maxY), radius: radius, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.closeSubpath()
        return path
    }
}





// MARK: - CityEnvironment


    // MARK: - MiniHumanView
    struct MiniHumanView: View {
        let color: Color
        @State private var stepAngle: Double = 0

        var body: some View {
            ZStack {
                Capsule()
                    .fill(color)
                    .frame(width: 5, height: 10)
                Circle()
                    .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                    .frame(width: 5, height: 5)
                    .offset(y: -7)
                Capsule()
                    .fill(color)
                    .frame(width: 2, height: 5)
                    .offset(x: -3, y: -2)
                    .rotationEffect(.degrees(-stepAngle), anchor: .top)
                Capsule()
                    .fill(color)
                    .frame(width: 2, height: 5)
                    .offset(x: 3, y: -2)
                    .rotationEffect(.degrees(stepAngle), anchor: .top)
                Capsule()
                    .fill(color)
                    .frame(width: 2, height: 5)
                    .offset(x: -1.5, y: 5)
                    .rotationEffect(.degrees(stepAngle), anchor: .top)
                Capsule()
                    .fill(color)
                    .frame(width: 2, height: 5)
                    .offset(x: 1.5, y: 5)
                    .rotationEffect(.degrees(-stepAngle), anchor: .top)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    stepAngle = 15
                }
            }
        }
    }

 
    // MARK: - Standard Components
    struct HumanView: View {
        @State private var legAngle: Double = 0.0
        @State private var armAngle: Double = 0.0
                            
        var body: some View {
            ZStack {
                Capsule().fill(Color.blue).frame(width: 20, height: 40)
                Circle().fill(Color(red: 1.0, green: 0.8, blue: 0.6)).frame(width: 20, height: 20).offset(y: -30)
                Circle().fill(Color.black).frame(width: 4, height: 4).offset(x: -5, y: -32)
                Circle().fill(Color.black).frame(width: 4, height: 4).offset(x: 5, y: -32)
                Path { path in
                    path.move(to: CGPoint(x: -3, y: -28))
                    path.addQuadCurve(to: CGPoint(x: 3, y: -28), control: CGPoint(x: 0, y: -25))
                }.stroke(Color.black, lineWidth: 1)
                Capsule().fill(Color.blue).frame(width: 5, height: 20).offset(x: -5, y: 20).rotationEffect(.degrees(legAngle), anchor: .top)
                Capsule().fill(Color.blue).frame(width: 5, height: 20).offset(x: 5, y: 20).rotationEffect(.degrees(-legAngle), anchor: .top)
                Capsule().fill(Color.blue).frame(width: 5, height: 15).offset(x: -10, y: -5).rotationEffect(.degrees(armAngle), anchor: .bottom)
                Capsule().fill(Color.blue).frame(width: 5, height: 15).offset(x: 10, y: -5).rotationEffect(.degrees(-armAngle), anchor: .bottom)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    legAngle = 20
                    armAngle = 15
                }
            }
        }
    }
                        
    struct CarView: View {
        let color: Color
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                    .frame(width: 30, height: 15)
                RoundedRectangle(cornerRadius: 3)
                    .fill(color.opacity(0.8))
                    .frame(width: 15, height: 10)
                    .offset(y: -7)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 13, height: 8)
                    .offset(y: -7)
                Circle()
                    .fill(Color.black)
                    .frame(width: 7, height: 7)
                    .offset(x: -10, y: 5)
                Circle()
                    .fill(Color.black)
                    .frame(width: 7, height: 7)
                    .offset(x: 10, y: 5)
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 3, height: 3)
                    .offset(x: 14, y: 0)
                Circle()
                    .fill(Color.red)
                    .frame(width: 3, height: 3)
                    .offset(x: -14, y: 0)
            }
        }
    }
                        
    struct TreeView: View {
        @State private var swayAngle: Double = 0.0
                        
        var body: some View {
            ZStack {
                // Tree trunk
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.brown, Color(red: 0.5, green: 0.3, blue: 0.1)]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: 15, height: 70)
                    .rotationEffect(.degrees(swayAngle), anchor: .bottom)
                            
                // Tree foliage - multiple layers for depth
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 60, height: 60)
                    .offset(y: -40)
                    .rotationEffect(.degrees(swayAngle), anchor: .bottom)
                            
                Circle()
                    .fill(Color.green.opacity(0.9))
                    .frame(width: 50, height: 50)
                    .offset(x: 15, y: -45)
                    .rotationEffect(.degrees(swayAngle), anchor: .bottom)
                            
                Circle()
                    .fill(Color.green.opacity(0.7))
                    .frame(width: 55, height: 55)
                    .offset(x: -15, y: -45)
                    .rotationEffect(.degrees(swayAngle), anchor: .bottom)
                            
                Circle()
                    .fill(Color.green.opacity(0.8))
                    .frame(width: 45, height: 45)
                    .offset(y: -60)
                    .rotationEffect(.degrees(swayAngle), anchor: .bottom)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    swayAngle = 5
                }
            }
        }
    }
                    
