import SwiftUI

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

// MARK: - WaveShape (Moved up in the file to be defined before use)
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
        let startComponents = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        let endComponents = UIColor(endColor).cgColor.components ?? [0, 0, 0, 1]
        let r = (1 - t) * Double(startComponents[0]) + t * Double(endComponents[0])
        let g = (1 - t) * Double(startComponents[1]) + t * Double(endComponents[1])
        let b = (1 - t) * Double(startComponents[2]) + t * Double(endComponents[2])
        let a = (1 - t) * Double(startComponents[3]) + t * Double(endComponents[3])
        return Color(red: r, green: g, blue: b, opacity: a)
    }
}

struct AlarmSetterView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @StateObject private var spaceshipViewModel = SpaceshipViewModel()
    @State private var selectedTime: Date = Date()
    @State private var isDragging = false
    @State private var showAlarmsView = false
    @State private var sunMoonOffset: CGFloat = 0.0
    @State private var isDayTime = true
    @State private var treeOffset: CGFloat = UIScreen.main.bounds.width
    @State private var humanOffset: CGFloat = UIScreen.main.bounds.width
    @State private var carOffset: CGFloat = -100
    
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
    
    private func getBackgroundGradient(for progress: Double) -> LinearGradient {
        let keyTimes: [Double] = [0.0, 0.2083, 0.2917, 0.5, 0.7083, 0.9167, 1.0]
        let keyGradients: [[Color]] = [
            [Color.black, Color.indigo, Color.blue],
            [Color.blue, Color.purple, Color.pink],
            [Color.pink, Color.orange, Color.yellow],
            [Color.yellow, Color.white, Color.blue],
            [Color.blue, Color.orange, Color.red],
            [Color.red, Color.purple, Color.indigo],
            [Color.black, Color.indigo, Color.blue]
        ]
        
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
        
        return LinearGradient(gradient: Gradient(colors: interpolatedColors), startPoint: .leading, endPoint: .trailing)
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
        
        updateSpaceshipForTime()
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
        ship.speed = 1.0 // Enforce a consistent base speed
        
        if sliderProgress >= 0.2083 && sliderProgress < 0.2917 {
            ship.speed = 1.5 // Slightly faster
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
        
        print("Ship speed set to: \(ship.speed)") // Debug print for speed
        
        if !spaceshipViewModel.isFlying {
            spaceshipViewModel.startFlying()
        }
        
        spaceshipViewModel.activeSpaceship = ship
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    getBackgroundGradient(for: sliderProgress)
                        .ignoresSafeArea()
                        .overlay(
                            RadialGradient(
                                gradient: Gradient(colors: [isDayTime ? Color.white.opacity(0.3) : Color.white.opacity(0.1), Color.clear]),
                                center: .init(x: sunMoonOffset + 0.5, y: 0.1),
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                    
                    if !isDayTime {
                        Canvas { context, size in
                            for _ in 0..<50 {
                                let x = CGFloat.random(in: 0...size.width)
                                let y = CGFloat.random(in: 0...size.height)
                                let starSize = CGFloat.random(in: 1...3)
                                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: starSize, height: starSize)), with: .color(.white.opacity(0.7)))
                            }
                        }
                    }
                    
                    ZStack {
                        if (sliderProgress >= 0.9167 && sliderProgress <= 1.0) || (sliderProgress >= 0.0 && sliderProgress < 0.2083) {
                            BedroomEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.95 || sliderProgress < 0.15 ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 1.0), value: sliderProgress)
                        }
                        if sliderProgress >= 0.2083 && sliderProgress < 0.2917 {
                            BeachEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.25 && sliderProgress < 0.27 ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 1.0), value: sliderProgress)
                        }
                        if sliderProgress >= 0.2917 && sliderProgress < 0.7083 {
                            CityEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.35 && sliderProgress < 0.65 ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 1.0), value: sliderProgress)
                        }
                        if sliderProgress >= 0.7083 && sliderProgress < 0.9167 {
                            NeighborhoodEnvironment()
                                .frame(width: geometry.size.width - 40, height: 150)
                                .clipShape(SnowglobeShape())
                                .overlay(SnowglobeShape().stroke(Color.white, lineWidth: 2))
                                .position(x: geometry.size.width / 2, y: geometry.size.height - 180)
                                .opacity(sliderProgress > 0.75 && sliderProgress < 0.85 ? 1.0 : 0.5)
                                .animation(.easeInOut(duration: 1.0), value: sliderProgress)
                        }
                    }
                    
                    if sliderProgress >= 0.25 && sliderProgress < 0.9 {
                        ZStack {
                            TreeView().offset(x: -geometry.size.width / 4, y: geometry.size.height - 80).opacity(sliderProgress > 0.3 ? 1.0 : sliderProgress - 0.25)
                            TreeView().offset(x: geometry.size.width / 4, y: geometry.size.height - 60).opacity(sliderProgress > 0.3 ? 1.0 : sliderProgress - 0.25)
                        }.animation(.easeInOut(duration: 1.0), value: sliderProgress)
                    }
                    
                    if sliderProgress >= 0.3 && sliderProgress < 0.7 {
                        HumanView()
                            .offset(x: humanOffset)
                            .opacity(sliderProgress > 0.35 ? 1.0 : (sliderProgress - 0.3) * 10)
                            .onAppear {
                                withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                                    humanOffset = -100
                                }
                            }
                            .onChange(of: sliderProgress) { _, newValue in
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    humanOffset = newValue > 0.7 ? UIScreen.main.bounds.width : humanOffset
                                }
                            }
                    }
                    
                    // FIXED SPACESHIP AND LABEL IMPLEMENTATION
                    Group {
                        // Spaceship View with thrusters
                        if let activeShip = spaceshipViewModel.activeSpaceship, activeShip.visible {
                            let shipPosition = activeShip.position
                            
                            // Draw thrusters first based on direction
                            if spaceshipViewModel.isMovingRight {
                                // When moving right, thrusters go on left
                                ThrusterView()
                                    .position(x: shipPosition.x - 40, y: shipPosition.y)
                            } else {
                                // When moving left, thrusters go on right but flipped
                                ThrusterView()
                                    .scaleEffect(x: -1, y: 1)
                                    .position(x: shipPosition.x + 40, y: shipPosition.y)
                            }
                            
                            // Spaceship image - flipped based on direction
                            if let _ = UIImage(named: activeShip.imageAsset) {
                                Image(activeShip.imageAsset)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80 * activeShip.scale, height: 80 * activeShip.scale)
                                    .scaleEffect(x: spaceshipViewModel.isMovingRight ? 1 : -1, y: 1)
                                    .position(x: shipPosition.x, y: shipPosition.y)
                                    .onTapGesture {
                                        spaceshipViewModel.logInteraction()
                                    }
                            } else {
                                // Fallback to system image
                                Image(systemName: "airplane")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80 * activeShip.scale, height: 80 * activeShip.scale)
                                    .scaleEffect(x: spaceshipViewModel.isMovingRight ? 1 : -1, y: 1)
                                    .position(x: shipPosition.x, y: shipPosition.y)
                                    .onTapGesture {
                                        spaceshipViewModel.logInteraction()
                                    }
                            }
                        }
                        
                        // Label - COMPLETELY SEPARATE from spaceship WITH HYPERLINK
                        if let activeShip = spaceshipViewModel.activeSpaceship, activeShip.visible {
                            let shipPosition = activeShip.position
                            
                            Text("TimeKeeper...")
                                .foregroundColor(.white)
                                .font(.caption).bold()
                                .padding(5)
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(5)
                                .overlay(
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                        .offset(x: spaceshipViewModel.isMovingRight ? -5 : 5, y: 0),
                                    alignment: spaceshipViewModel.isMovingRight ? .leading : .trailing
                                )
                                .position(x: shipPosition.x, y: shipPosition.y - 30)
                                .onTapGesture {
                                    // Handle label tap - same action as spaceship tap
                                    spaceshipViewModel.logInteraction()
                                    
                                    // If this ship has an ad, also trigger the ad handler
                                    if activeShip.adContent != nil {
                                        spaceshipViewModel.handleAdTap()
                                    }
                                }
                                // Add visual indication that label is tappable
                                .shadow(color: .blue, radius: 2)
                        }
                    }
                    
                    ZStack {
                        if isDayTime {
                            ZStack {
                                Circle().fill(RadialGradient(gradient: Gradient(colors: [Color.white, Color.yellow, Color.orange]), center: .center, startRadius: 0, endRadius: 25)).frame(width: 50, height: 50)
                                Circle().fill(Color.white.opacity(0.2)).frame(width: 80, height: 80)
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.orange.opacity(0.5), radius: 20, x: 0, y: 0)
                        } else {
                            ZStack {
                                Circle().fill(RadialGradient(gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]), center: .center, startRadius: 0, endRadius: 25)).frame(width: 50, height: 50)
                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 10, height: 10).offset(x: 10, y: -10)
                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 8, height: 8).offset(x: -12, y: 5)
                                Circle().fill(Color.gray.opacity(0.3)).frame(width: 6, height: 6).offset(x: 5, y: 10)
                            }
                            .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
                        }
                    }
                    .position(x: geometry.size.width * (sunMoonOffset + 0.5), y: calculateSunMoonYPosition(geometry: geometry))
                    .animation(.easeInOut(duration: 0.3), value: sunMoonOffset)
                    
                    HStack(spacing: 10) {
                        VStack(spacing: 5) {
                            Button(action: { adjustTime(by: 60) }) { Image(systemName: "plus.circle").resizable().frame(width: 20, height: 20).foregroundColor(.white) }
                            Button(action: { adjustTime(by: -60) }) { Image(systemName: "minus.circle").resizable().frame(width: 20, height: 20).foregroundColor(.white) }
                        }
                        Text(timeFormatter.string(from: selectedTime)).font(.system(size: 50, weight: .bold)).foregroundColor(.white).shadow(radius: 5)
                        VStack(spacing: 5) {
                            Button(action: { adjustTime(by: 1) }) { Image(systemName: "plus.circle").resizable().frame(width: 20, height: 20).foregroundColor(.white) }
                            Button(action: { adjustTime(by: -1) }) { Image(systemName: "minus.circle").resizable().frame(width: 20, height: 20).foregroundColor(.white) }
                        }
                    }
                    .position(x: geometry.size.width / 2, y: 200)
                    
                    VStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.2)).frame(height: 20).frame(width: geometry.size.width - 40)
                            Circle().fill(Color.white).frame(width: 30, height: 30).offset(x: calculateSliderOffset(geometry: geometry))
                                .gesture(
                                    DragGesture()
                                        .onChanged { value in
                                            isDragging = true
                                            let trackWidth = geometry.size.width - 40
                                            let dragX = value.location.x - (geometry.size.width / 2) + (trackWidth / 2)
                                            let boundedX = max(-trackWidth / 2, min(dragX, trackWidth / 2))
                                            let progress = (boundedX + trackWidth / 2) / trackWidth
                                            let newMinutes = Int(progress * Double(totalMinutesInDay))
                                            selectedTime = calendar.date(byAdding: .minute, value: newMinutes, to: startOfDay)!
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                sunMoonOffset = progress - 0.5
                                                isDayTime = calendar.component(.hour, from: selectedTime) >= 6 && calendar.component(.hour, from: selectedTime) < 18
                                            }
                                            updateSpaceshipForTime()
                                        }
                                        .onEnded { _ in isDragging = false }
                                )
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 20)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 150)
                    .zIndex(1)
                    
                    HStack(spacing: 40) {
                        Button(action: {
                            viewModel.alarmTime = selectedTime
                            showAlarmsView = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                viewModel.activeModal = .choice
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
                        
                        Button(action: { showAlarmsView = true }) {
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
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height - 80)
                    .zIndex(2)
                }
                .navigationBarHidden(true)
                .sheet(isPresented: $showAlarmsView) { AlarmsView() }
                .onAppear {
                    if spaceshipViewModel.availableSpaceships.isEmpty {
                        spaceshipViewModel.initializeDefaultSpaceships()
                    }
                    
                    if spaceshipViewModel.activeSpaceship == nil, let firstShip = spaceshipViewModel.availableSpaceships.first {
                        var updatedShip = firstShip
                        updatedShip.position = CGPoint(x: -50, y: 150) // Fixed Y position at 150
                        updatedShip.visible = true
                        updatedShip.scale = 1.5
                        updatedShip.rotation = 0 // Ensure consistent rotation
                        spaceshipViewModel.selectSpaceship(updatedShip)
                        spaceshipViewModel.startFlying()
                    }
                    viewModel.alarmTime = selectedTime
                }
            }
        }
    }
    
    // Thruster view definition
    struct ThrusterView: View {
        @State private var flameAnimation: Double = 0
        
        var body: some View {
            ZStack {
                // Main flame
                ZStack {
                    // Inner flame - bright center
                    Triangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.white, .yellow, .orange]),
                            startPoint: .trailing,
                            endPoint: .leading
                        ))
                        .frame(width: 35 + CGFloat(sin(flameAnimation) * 5), height: 16)
                        .blur(radius: 1)
                    
                    // Outer flame
                    Triangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.orange, .red, .red.opacity(0.5)]),
                            startPoint: .trailing,
                            endPoint: .leading
                        ))
                        .frame(width: 45 + CGFloat(sin(flameAnimation) * 8), height: 22)
                        .blur(radius: 2)
                    
                    // Flame particles
                    ForEach(0..<6) { i in
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [.orange, .red, .clear]),
                                startPoint: .trailing,
                                endPoint: .leading
                            ))
                            .frame(width: CGFloat.random(in: 4...7), height: CGFloat.random(in: 4...7))
                            .offset(x: -10 - CGFloat(i) * 5 - CGFloat(sin(flameAnimation) * 3),
                                    y: CGFloat.random(in: -10...10))
                            .opacity(0.7)
                            .blur(radius: 1)
                    }
                }
            }
            .onAppear {
                // Continuous flame animation
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    flameAnimation = .pi * 2
                }
            }
        }
    }
    
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
    
    // PROPERLY UPDATED BEDROOM ENVIRONMENT WITH CORRECT CAT
    struct BedroomEnvironment: View {
        @State private var zOffset: CGFloat = 0
        @State private var zOpacity: Double = 1.0
        @State private var tvAnimation: Double = 0.0
        @State private var starTwinkle: Double = 0.0
        @State private var catSleeping: Bool = true
        @State private var catPosition: Bool = false // false = left, true = right
        @State private var catBreathing: CGFloat = 0
        @State private var catXOffset: CGFloat = -60 // Start above sleeping human's head

        var body: some View {
            ZStack {
                // Background - match the deep purple from Image 1
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.4, green: 0.2, blue: 0.5), Color(red: 0.3, green: 0.15, blue: 0.4)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 300, height: 150)

                // Window with night sky
                ZStack {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 66, height: 56)
                        .offset(y: -40)
                    
                    // Night sky inside window - matches Image 1 exactly
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.05, blue: 0.3), Color.black]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 60, height: 50)
                        .offset(y: -40)
                    
                    // Window frame
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 60, height: 2)
                        .offset(y: -40)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 50)
                        .offset(y: -40)
                    
                    // Moon and stars
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 10, height: 10)
                        .offset(x: 20, y: -50)
                    ForEach(0..<8) { i in
                        Circle()
                            .fill(Color.white.opacity(0.6 + starTwinkle * 0.4))
                            .frame(width: CGFloat.random(in: 1...2), height: CGFloat.random(in: 1...2))
                            .offset(x: CGFloat.random(in: -25...25), y: CGFloat.random(in: -55 ... -35))
                    }
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                            starTwinkle = 1.0
                        }
                    }
                }

                // Bed frame - brown color matching Image 1
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                    .frame(width: 140, height: 40)
                    .offset(y: 50)
                    
                // Blue blanket
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.blue)
                    .frame(width: 130, height: 25)
                    .offset(y: 45)
                    
                // White pillow
                Capsule()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 30, height: 15)
                    .offset(x: -45, y: 40)

                // TV Stand and Gaming Setup
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.35, blue: 0.2))
                        .frame(width: 100, height: 40)
                        .offset(x: -60, y: 30)
                    
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 50, height: 30)
                        .offset(x: -60, y: 10)
                    Rectangle()
                        .fill(Color.blue.opacity(0.5 + tvAnimation * 0.3))
                        .frame(width: 44, height: 24)
                        .offset(x: -60, y: 10)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                tvAnimation = 1.0
                            }
                        }
                    
                    // Gaming console
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 20, height: 5)
                        .offset(x: -90, y: 25)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 2, height: 2)
                        .offset(x: -85, y: 25)
                }

                // Bookshelf - right side
                ZStack {
                    Rectangle()
                        .fill(Color(red: 0.6, green: 0.4, blue: 0.2))
                        .frame(width: 35, height: 70)
                        .offset(x: 100, y: -10)
                    
                    // Shelves
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.3, blue: 0.1))
                        .frame(width: 35, height: 2)
                        .offset(x: 100, y: -32)
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.3, blue: 0.1))
                        .frame(width: 35, height: 2)
                        .offset(x: 100, y: -10)
                    Rectangle()
                        .fill(Color(red: 0.5, green: 0.3, blue: 0.1))
                        .frame(width: 35, height: 2)
                        .offset(x: 100, y: 12)
                    
                    // Books - matching Image 1 exactly (yellow, blue, red)
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 8, height: 15)
                        .offset(x: 90, y: 0)
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 15)
                        .offset(x: 100, y: 0)
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 8, height: 15)
                        .offset(x: 110, y: 0)
                }

                // Sleeping Person
                ZStack {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 60, height: 20)
                        .offset(x: -60, y: 20)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                        .frame(width: 20, height: 20)
                        .offset(x: -90, y: 5)
                    Text("Z")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: -80, y: -10 + zOffset)
                        .opacity(zOpacity)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                                zOffset = -20
                                zOpacity = 0
                            }
                        }
                    Text("Z")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: -70, y: -15 + zOffset)
                        .opacity(zOpacity)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 1.0).delay(0.3).repeatForever(autoreverses: false)) {
                                zOffset = -20
                                zOpacity = 0
                            }
                        }
                }

                // Cat with PROPERLY ORIENTED EARS, WHISKERS AND REFINED FACE
                ZStack {
                    // Cat body
                    Capsule()
                        .fill(Color.gray)
                        .frame(width: 25, height: 15 + catBreathing)
                        .offset(y: 0)
                    
                    // Cat head
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 15, height: 15)
                        .offset(y: -10)
                    
                    // Cat ears - PROPERLY ORIENTED (pointing up)
                    Triangle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 8)
                        .offset(x: -5, y: -18)
                    
                    Triangle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 8)
                        .offset(x: 5, y: -18)
                    
                    // Inner ears - pink
                    Triangle()
                        .fill(Color.pink.opacity(0.8))
                        .frame(width: 4, height: 5)
                        .offset(x: -5, y: -17)
                    
                    Triangle()
                        .fill(Color.pink.opacity(0.8))
                        .frame(width: 4, height: 5)
                        .offset(x: 5, y: -17)
                    
                    // Cat eyes
                    if catSleeping {
                        // Closed eyes when sleeping
                        Path { path in
                            path.move(to: CGPoint(x: -5, y: -10))
                            path.addLine(to: CGPoint(x: -2, y: -10))
                        }
                        .stroke(Color.black, lineWidth: 1)
                        
                        Path { path in
                            path.move(to: CGPoint(x: 2, y: -10))
                            path.addLine(to: CGPoint(x: 5, y: -10))
                        }
                        .stroke(Color.black, lineWidth: 1)
                    } else {
                        // Open eyes when awake
                        Ellipse()
                            .fill(Color.green)
                            .frame(width: 4, height: 5)
                            .offset(x: -4, y: -10)
                        
                        Ellipse()
                            .fill(Color.green)
                            .frame(width: 4, height: 5)
                            .offset(x: 4, y: -10)
                        
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: -4, y: -10)
                        
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: 4, y: -10)
                    }
                    
                    // Cat nose - improved shape
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: -7))
                        path.addLine(to: CGPoint(x: -1.5, y: -5))
                        path.addLine(to: CGPoint(x: 1.5, y: -5))
                        path.closeSubpath()
                    }
                    .fill(Color.pink)
                    
                    // Cat mouth - more detailed with different states
                    if catSleeping {
                        // Simple relaxed sleeping mouth
                        Path { path in
                            path.move(to: CGPoint(x: -1, y: -5))
                            path.addQuadCurve(to: CGPoint(x: 1, y: -5), control: CGPoint(x: 0, y: -4.5))
                        }
                        .stroke(Color.black.opacity(0.4), lineWidth: 0.5)
                    } else {
                        // Open mouth when awake
                        Path { path in
                            path.move(to: CGPoint(x: -1.5, y: -5))
                            path.addQuadCurve(to: CGPoint(x: 1.5, y: -5), control: CGPoint(x: 0, y: -3))
                            path.addQuadCurve(to: CGPoint(x: -1.5, y: -5), control: CGPoint(x: 0, y: -6))
                        }
                        .fill(Color.red.opacity(0.7))
                        
                        // Small tongue
                        Path { path in
                            path.move(to: CGPoint(x: -0.5, y: -4.5))
                            path.addQuadCurve(to: CGPoint(x: 0.5, y: -4.5), control: CGPoint(x: 0, y: -3.5))
                        }
                        .stroke(Color.red, lineWidth: 0.8)
                    }
                    
                    // WHISKERS - left side (thicker and more visible)
                    ForEach(0..<3) { i in
                        Path { path in
                            path.move(to: CGPoint(x: -5, y: -6 + CGFloat(i)))
                            path.addLine(to: CGPoint(x: -12, y: -7 + CGFloat(i) * 2))
                        }
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.2)
                    }
                    
                    // WHISKERS - right side (thicker and more visible)
                    ForEach(0..<3) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 5, y: -6 + CGFloat(i)))
                            path.addLine(to: CGPoint(x: 12, y: -7 + CGFloat(i) * 2))
                        }
                        .stroke(Color.white.opacity(0.9), lineWidth: 1.2)
                    }
                    
                    // Meow speech bubble - only shows when cat is awake
                    if !catSleeping {
                        ZStack {
                            // Speech bubble background
                            Path { path in
                                path.move(to: CGPoint(x: -5, y: -20))
                                path.addLine(to: CGPoint(x: -15, y: -25))
                                path.addLine(to: CGPoint(x: -5, y: -30))
                                path.addCurve(
                                    to: CGPoint(x: 15, y: -30),
                                    control1: CGPoint(x: 0, y: -35),
                                    control2: CGPoint(x: 10, y: -35)
                                )
                                path.addCurve(
                                    to: CGPoint(x: 15, y: -20),
                                    control1: CGPoint(x: 20, y: -28),
                                    control2: CGPoint(x: 20, y: -22)
                                )
                                path.addCurve(
                                    to: CGPoint(x: -5, y: -20),
                                    control1: CGPoint(x: 10, y: -15),
                                    control2: CGPoint(x: 0, y: -15)
                                )
                                path.closeSubpath()
                            }
                            .fill(Color.black.opacity(0.7))
                            .overlay(
                                Path { path in
                                    path.move(to: CGPoint(x: -5, y: -20))
                                    path.addLine(to: CGPoint(x: -15, y: -25))
                                    path.addLine(to: CGPoint(x: -5, y: -30))
                                    path.addCurve(
                                        to: CGPoint(x: 15, y: -30),
                                        control1: CGPoint(x: 0, y: -35),
                                        control2: CGPoint(x: 10, y: -35)
                                    )
                                    path.addCurve(
                                        to: CGPoint(x: 15, y: -20),
                                        control1: CGPoint(x: 20, y: -28),
                                        control2: CGPoint(x: 20, y: -22)
                                    )
                                    path.addCurve(
                                        to: CGPoint(x: -5, y: -20),
                                        control1: CGPoint(x: 10, y: -15),
                                        control2: CGPoint(x: 0, y: -15)
                                    )
                                    path.closeSubpath()
                                }
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                            )
                            
                            // Meow text
                            Text("Meow!")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(.white)
                                .offset(y: -25)
                        }
                        .offset(x: 5, y: -5)
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Cat tail
                    Path { path in
                        path.move(to: CGPoint(x: -12, y: 0))
                        path.addCurve(
                            to: CGPoint(x: -18, y: -5),
                            control1: CGPoint(x: -14, y: 0),
                            control2: CGPoint(x: -18, y: -2)
                        )
                    }
                    .stroke(Color.gray, lineWidth: 3)
                    .opacity(catSleeping ? 0.7 : 1.0)
                }
                .offset(x: catXOffset, y: 40)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        catBreathing = 2
                    }
                    Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 1.0)) {
                            catSleeping.toggle()
                        }
                        if !catSleeping {
                            withAnimation(.easeInOut(duration: 2.0)) {
                                catXOffset = catPosition ? -40 : -70
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    catPosition.toggle()
                                    catSleeping = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // PROPERLY UPDATED BEACH ENVIRONMENT WITH ALL CHARACTERS AND CENTERED TREES
    struct BeachEnvironment: View {
        @State private var waveOffset: CGFloat = 0.0
        @State private var humanOffset: CGFloat = -150
        @State private var palmSway: Double = 0.0
        @State private var surferPosition: CGFloat = 0.0
        @State private var surferBalance: Double = 0.0
        @State private var armAngle: Double = 0.0

        var body: some View {
            ZStack {
                // Sky
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 80)
                    .offset(y: -35)

                // Sand
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color(red: 0.95, green: 0.8, blue: 0.6)]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 70)
                    .offset(y: 40)

                // Water
                Rectangle()
                    .fill(Color.blue.opacity(0.5))
                    .frame(height: 30)
                    .offset(y: 60)

                // Waves
                WaveShape()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 350, height: 15)
                    .offset(x: waveOffset, y: 55)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            waveOffset = 50
                        }
                    }

                // PROPERLY POSITIONED PALM TREES - CENTERED AND LOWER IN THE SCENE
                
                // Center Main Palm Tree
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 40))
                        path.addCurve(
                            to: CGPoint(x: 0, y: -30),
                            control1: CGPoint(x: 5, y: 20),
                            control2: CGPoint(x: -5, y: 0)
                        )
                    }
                    .stroke(Color.brown, lineWidth: 6)
                    .rotationEffect(.degrees(palmSway/2), anchor: .bottom)
                    ForEach(0..<7) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: -30))
                            path.addCurve(
                                to: CGPoint(x: cos(Double(i) * .pi / 3.5) * 30, y: -30 + sin(Double(i) * .pi / 3.5) * 25),
                                control1: CGPoint(x: cos(Double(i) * .pi / 3.5) * 15, y: -35),
                                control2: CGPoint(x: cos(Double(i) * .pi / 3.5) * 25, y: -32 + sin(Double(i) * .pi / 3.5) * 8)
                            )
                        }
                        .stroke(Color.green, lineWidth: 2.5)
                        .rotationEffect(.degrees(palmSway/2), anchor: .bottom)
                    }
                }
                .offset(x: 0, y: 30)

                // Left Palm Tree
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: -50, y: 40))
                        path.addCurve(
                            to: CGPoint(x: -50, y: -40),
                            control1: CGPoint(x: -55, y: 20),
                            control2: CGPoint(x: -45, y: 0)
                        )
                    }
                    .stroke(Color.brown, lineWidth: 8)
                    .rotationEffect(.degrees(palmSway), anchor: .bottom)
                    ForEach(0..<7) { i in
                        Path { path in
                            path.move(to: CGPoint(x: -50, y: -40))
                            path.addCurve(
                                to: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30),
                                control1: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 20, y: -45),
                                control2: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10)
                            )
                        }
                        .stroke(Color.green, lineWidth: 3)
                        .rotationEffect(.degrees(palmSway), anchor: .bottom)
                    }
                }
                .offset(x: -70, y: 40)

                // Right Palm Tree
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: 40))
                        path.addCurve(
                            to: CGPoint(x: 50, y: -40),
                            control1: CGPoint(x: 45, y: 20),
                            control2: CGPoint(x: 55, y: 0)
                        )
                    }
                    .stroke(Color.brown, lineWidth: 8)
                    .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                    ForEach(0..<7) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 50, y: -40))
                            path.addCurve(
                                to: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30),
                                control1: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 20, y: -45),
                                control2: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10)
                            )
                        }
                        .stroke(Color.green, lineWidth: 3)
                        .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                    }
                }
                .offset(x: 70, y: 40)

                // Far Left Palm Tree
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: -50, y: 40))
                        path.addCurve(
                            to: CGPoint(x: -50, y: -40),
                            control1: CGPoint(x: -55, y: 20),
                            control2: CGPoint(x: -45, y: 0)
                        )
                    }
                    .stroke(Color.brown, lineWidth: 6)
                    .rotationEffect(.degrees(palmSway), anchor: .bottom)
                    ForEach(0..<7) { i in
                        Path { path in
                            path.move(to: CGPoint(x: -50, y: -40))
                            path.addCurve(
                                to: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30),
                                control1: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 20, y: -45),
                                control2: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10)
                            )
                        }
                        .stroke(Color.green, lineWidth: 3)
                        .rotationEffect(.degrees(palmSway), anchor: .bottom)
                    }
                }
                .offset(x: -120, y: 35)

                // Far Right Palm Tree
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: 40))
                        path.addCurve(
                            to: CGPoint(x: 50, y: -40),
                            control1: CGPoint(x: 45, y: 20),
                            control2: CGPoint(x: 55, y: 0)
                        )
                    }
                    .stroke(Color.brown, lineWidth: 6)
                    .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                    ForEach(0..<7) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 50, y: -40))
                            path.addCurve(
                                to: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30),
                                control1: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 20, y: -45),
                                control2: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10)
                            )
                        }
                        .stroke(Color.green, lineWidth: 3)
                        .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                    }
                }
                .offset(x: 120, y: 35)
                
                // Extra Right Palm Tree
                ZStack {
                    Path { path in
                        path.move(to: CGPoint(x: 50, y: 40))
                        path.addCurve(
                            to: CGPoint(x: 50, y: -35),
                            control1: CGPoint(x: 45, y: 20),
                            control2: CGPoint(x: 55, y: 0)
                        )
                    }
                    .stroke(Color.brown, lineWidth: 7)
                    .rotationEffect(.degrees(-palmSway*1.2), anchor: .bottom)
                    ForEach(0..<7) { i in
                        Path { path in
                            path.move(to: CGPoint(x: 50, y: -35))
                            path.addCurve(
                                to: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 35, y: -35 + sin(Double(i) * .pi / 3.5) * 28),
                                control1: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 18, y: -38),
                                control2: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 28, y: -37 + sin(Double(i) * .pi / 3.5) * 8)
                            )
                        }
                        .stroke(Color.green, lineWidth: 3)
                        .rotationEffect(.degrees(-palmSway*1.2), anchor: .bottom)
                    }
                }
                .offset(x: 150, y: 38)

                // CHARACTERS

                // Surfer
                ZStack {
                    Capsule()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan, Color.teal]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: 60, height: 15)
                        .rotationEffect(.degrees(surferBalance))
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1, height: 13)
                        .rotationEffect(.degrees(surferBalance))
                    ZStack {
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 4, height: 15)
                            .offset(x: -8, y: -5)
                            .rotationEffect(.degrees(20))
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 4, height: 15)
                            .offset(x: 0, y: -5)
                            .rotationEffect(.degrees(-10))
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 10, height: 20)
                            .offset(y: -15)
                            .rotationEffect(.degrees(surferBalance/2))
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 3, height: 15)
                            .offset(x: -8, y: -15)
                            .rotationEffect(.degrees(-40 + surferBalance))
                        Capsule()
                            .fill(Color.black)
                            .frame(width: 3, height: 15)
                            .offset(x: 8, y: -15)
                            .rotationEffect(.degrees(20 + surferBalance))
                        Circle()
                            .fill(Color(red: 0.9, green: 0.7, blue: 0.5))
                            .frame(width: 12, height: 12)
                            .offset(y: -28)
                            .rotationEffect(.degrees(surferBalance/3))
                    }
                    .offset(y: -8)
                    .rotationEffect(.degrees(surferBalance))
                }
                .offset(x: surferPosition, y: 52)
                .onAppear {
                    withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                        surferPosition = 100
                    }
                    withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        surferBalance = 10
                    }
                }

                // Walking Human
                HumanView()
                    .offset(x: humanOffset, y: 30)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                            humanOffset = 150
                        }
                    }

                // Weight Lifter
                ZStack {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 20, height: 40)
                        .offset(y: 10)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                        .frame(width: 20, height: 20)
                        .offset(y: -20)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 3, height: 3)
                        .offset(x: -5, y: -20)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 3, height: 3)
                        .offset(x: 5, y: -20)
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 12, height: 5)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: -8, y: 0)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: 0)
                    }
                    .offset(x: -15, y: -5)
                    .rotationEffect(.degrees(armAngle), anchor: .center)
                    ZStack {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 12, height: 5)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: -8, y: 0)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 8, y: 0)
                    }
                    .offset(x: 15, y: -5)
                    .rotationEffect(.degrees(-armAngle), anchor: .center)
                }
                .offset(x: 40, y: 20)
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        armAngle = 30
                    }
                }

                // GRANNY CHARACTER - RESTORED AS REQUESTED
                ZStack {
                    Capsule()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.8), Color(red: 0.7, green: 0.4, blue: 0.8)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 20, height: 35)
                        .offset(y: 20)
                    Path { path in
                        path.move(to: CGPoint(x: -10, y: 20))
                        path.addLine(to: CGPoint(x: 10, y: 20))
                        path.addLine(to: CGPoint(x: 15, y: 40))
                        path.addLine(to: CGPoint(x: -15, y: 40))
                        path.closeSubpath()
                    }
                    .fill(Color.purple.opacity(0.4))
                    Circle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.9, blue: 0.8), Color(red: 0.95, green: 0.85, blue: 0.75)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 18, height: 18)
                        .offset(y: -5)
                    Path { path in
                        path.move(to: CGPoint(x: -5, y: -7))
                        path.addQuadCurve(to: CGPoint(x: 5, y: -7), control: CGPoint(x: 0, y: -9))
                    }
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    Ellipse()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 38, height: 10)
                        .offset(y: -5)
                    Ellipse()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.9), Color.orange.opacity(0.5)]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: 22, height: 12)
                        .offset(y: -10)
                    Rectangle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 22, height: 2)
                        .offset(y: -6)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: -4, y: -5)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: 4, y: -5)
                    Path { path in
                        path.move(to: CGPoint(x: -7, y: -5))
                        path.addLine(to: CGPoint(x: -2, y: -5))
                        path.move(to: CGPoint(x: 2, y: -5))
                        path.addLine(to: CGPoint(x: 7, y: -5))
                        path.move(to: CGPoint(x: -2, y: -5))
                        path.addQuadCurve(to: CGPoint(x: 2, y: -5), control: CGPoint(x: 0, y: -6))
                    }
                    .stroke(Color.black.opacity(0.8), lineWidth: 0.5)
                    Path { path in
                        path.move(to: CGPoint(x: -4, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 4, y: -1), control: CGPoint(x: 0, y: 1))
                    }
                    .stroke(Color.red.opacity(0.7), lineWidth: 1)
                    Capsule()
                        .fill(Color.purple.opacity(0.8))
                        .frame(width: 12, height: 5)
                        .offset(x: -10, y: 10)
                        .rotationEffect(.degrees(-20))
                    Capsule()
                        .fill(Color.purple.opacity(0.8))
                        .frame(width: 12, height: 5)
                        .offset(x: 10, y: 10)
                        .rotationEffect(.degrees(20))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.pink.opacity(0.7))
                        .frame(width: 10, height: 8)
                        .offset(x: 15, y: 15)
                }
                .offset(x: -50, y: 0)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    palmSway = 3
                }
            }
        }
    }
    
    // CITY ENVIRONMENT WITH PEDESTRIANS
    struct CityEnvironment: View {
        @State private var carOffset1: CGFloat = -150
        @State private var carOffset2: CGFloat = 150
        @State private var trafficLightState: Int = 0
        @State private var windowsAnimation: Double = 0.0
        @State private var clockHandAngle: Double = 0.0
        @State private var pedestrianYOffset: CGFloat = -35
        @State private var humanOffset: CGFloat = -UIScreen.main.bounds.width // Start from left side

        var body: some View {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 80)
                    .offset(y: -35)

                // Buildings
                ZStack {
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.indigo.opacity(0.6)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 50, height: 100)
                            .offset(x: -100, y: -30)
                        VStack(spacing: 5) {
                            ForEach(0..<4) { row in
                                HStack(spacing: 5) {
                                    ForEach(0..<3) { col in
                                        Rectangle()
                                            .fill(Color.yellow.opacity(0.3 + windowsAnimation * 0.5))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                        }
                        .offset(x: -100, y: -30)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                                windowsAnimation = 1.0
                            }
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 40, height: 15)
                            Text("OFFICE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.blue)
                        }
                        .offset(x: -100, y: -70)
                    }
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.8), Color.gray.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 60, height: 120)
                            .offset(y: -40)
                        VStack(spacing: 10) {
                            ForEach(0..<4) { _ in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.4))
                                    .frame(width: 40, height: 10)
                            }
                        }
                        .offset(y: -30)
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 25, height: 25)
                            ForEach(0..<12) { i in
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(width: 1, height: 3)
                                    .offset(y: -10)
                                    .rotationEffect(.degrees(Double(i) * 30))
                            }
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 2, height: 8)
                                .offset(y: -4)
                                .rotationEffect(.degrees(clockHandAngle / 12))
                            Rectangle()
                                .fill(Color.black)
                                .frame(width: 1, height: 10)
                                .offset(y: -5)
                                .rotationEffect(.degrees(clockHandAngle))
                        }
                        .offset(y: -75)
                        .onAppear {
                            withAnimation(Animation.linear(duration: 60.0).repeatForever(autoreverses: false)) {
                                clockHandAngle = 360
                            }
                        }
                        Triangle()
                            .fill(Color.red.opacity(0.7))
                            .frame(width: 40, height: 20)
                            .offset(y: -110)
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 58, height: 15)
                            Text("TIMEKEEPER")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.black)
                        }
                        .offset(y: -95)
                    }
                    ZStack {
                        Rectangle()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.7), Color.teal.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                            .frame(width: 40, height: 80)
                            .offset(x: 100, y: -20)
                        ZStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.5))
                                .frame(width: 30, height: 30)
                                .offset(x: 100, y: -30)
                            Circle()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 6, height: 6)
                                .offset(x: 95, y: -35)
                            Rectangle()
                                .fill(Color.blue.opacity(0.8))
                                .frame(width: 6, height: 8)
                                .offset(x: 105, y: -32)
                            Rectangle()
                                .fill(Color.yellow.opacity(0.8))
                                .frame(width: 8, height: 5)
                                .offset(x: 100, y: -25)
                        }
                        ZStack {
                            Rectangle()
                                .fill(Color.brown.opacity(0.7))
                                .frame(width: 15, height: 25)
                                .offset(x: 100, y: 5)
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 3, height: 3)
                                .offset(x: 95, y: 5)
                        }
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.white.opacity(0.8))
                                .frame(width: 35, height: 12)
                            Text("SHOP")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .offset(x: 100, y: -50)
                    }
                }

                // Road
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 30)
                    .offset(y: 50)

                // Road Lines (Center Line)
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 300, height: 2)
                    .offset(y: 50)

                // Dashed Lane Lines (Above the Center Line)
                ForEach(0..<7) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 20, height: 2)
                        .offset(x: CGFloat(i * 50) - 150, y: 40)
                }

                // Pedestrians (Walking downwards)
                ZStack {
                    MiniHumanView(color: .red)
                        .frame(width: 10, height: 20)
                        .offset(x: -10, y: pedestrianYOffset)
                    MiniHumanView(color: .blue)
                        .frame(width: 10, height: 20)
                        .offset(x: 0, y: pedestrianYOffset)
                    MiniHumanView(color: .green)
                        .frame(width: 10, height: 20)
                        .offset(x: 10, y: pedestrianYOffset)
                }
                .offset(x: 0, y: 35)

                // Giant Blue Human in Front of Office (from left side)
                HumanView()
                    .frame(width: 40, height: 80)
                    .offset(x: humanOffset, y: 10)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 5.0).delay(1.0)) {
                            humanOffset = -100 // Move to in front of office
                        }
                    }

                // Traffic Lights
                ZStack {
                    // Left Traffic Light
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 10, height: 30)
                        .offset(x: -130, y: 20)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray)
                        .frame(width: 12, height: 30)
                        .offset(x: -130, y: 10)
                    Circle()
                        .fill(trafficLightState == 0 ? Color.red : Color.red.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: -130, y: 0)
                    Circle()
                        .fill(trafficLightState == 1 ? Color.yellow : Color.yellow.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: -130, y: 10)
                    Circle()
                        .fill(trafficLightState == 2 ? Color.green : Color.green.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: -130, y: 20)

                    // Right Traffic Light
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 10, height: 30)
                        .offset(x: 130, y: 20)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray)
                        .frame(width: 12, height: 30)
                        .offset(x: 130, y: 10)
                    Circle()
                        .fill(trafficLightState == 0 ? Color.red : Color.red.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: 130, y: 0)
                    Circle()
                        .fill(trafficLightState == 1 ? Color.yellow : Color.yellow.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: 130, y: 10)
                    Circle()
                        .fill(trafficLightState == 2 ? Color.green : Color.green.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .offset(x: 130, y: 20)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 0.5)) {
                        trafficLightState = 0
                    }
                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            trafficLightState = (trafficLightState + 1) % 3
                            if trafficLightState == 0 { // Red light
                                withAnimation(Animation.linear(duration: 3.0)) {
                                    pedestrianYOffset = 35
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                    pedestrianYOffset = -35
                                }
                            }
                        }
                    }
                }

                // Cars (First Lane, Moving Left to Right)
                CarView(color: .red)
                    .offset(x: trafficLightState == 2 ? carOffset1 : -100, y: 40)
                    .onChange(of: trafficLightState) { _, newValue in
                        if newValue == 2 {
                            withAnimation(Animation.linear(duration: 4.0)) {
                                carOffset1 = 200
                            }
                        } else {
                            withAnimation(Animation.easeOut(duration: 0.5)) {
                                carOffset1 = -100
                            }
                        }
                    }
                CarView(color: .green)
                    .offset(x: trafficLightState == 2 ? carOffset1 - 60 : -160, y: 40)
                    .onChange(of: trafficLightState) { _, newValue in
                        if newValue == 2 {
                            withAnimation(Animation.linear(duration: 4.0)) {
                                carOffset1 = 200
                            }
                        } else {
                            withAnimation(Animation.easeOut(duration: 0.5)) {
                                carOffset1 = -100
                            }
                        }
                    }
                CarView(color: .yellow)
                    .offset(x: trafficLightState == 2 ? carOffset1 - 120 : -220, y: 40)
                    .onChange(of: trafficLightState) { _, newValue in
                        if newValue == 2 {
                            withAnimation(Animation.linear(duration: 4.0)) {
                                carOffset1 = 200
                            }
                        } else {
                            withAnimation(Animation.easeOut(duration: 0.5)) {
                                carOffset1 = -100
                            }
                        }
                    }

                // Cars (Second Lane, Moving Right to Left)
                CarView(color: .blue)
                    .offset(x: trafficLightState == 2 ? carOffset2 : 70, y: 60)
                    .onChange(of: trafficLightState) { _, newValue in
                        if newValue == 2 {
                            withAnimation(Animation.linear(duration: 4.0)) {
                                carOffset2 = -200
                            }
                        } else {
                            withAnimation(Animation.easeOut(duration: 0.5)) {
                                carOffset2 = 70
                            }
                        }
                    }
                CarView(color: .purple)
                    .offset(x: trafficLightState == 2 ? carOffset2 + 60 : 130, y: 60)
                    .onChange(of: trafficLightState) { _, newValue in
                        if newValue == 2 {
                            withAnimation(Animation.linear(duration: 4.0)) {
                                carOffset2 = -200
                            }
                        } else {
                            withAnimation(Animation.easeOut(duration: 0.5)) {
                                carOffset2 = 70
                            }
                        }
                    }
                CarView(color: .orange)
                    .offset(x: trafficLightState == 2 ? carOffset2 + 120 : 190, y: 60)
                    .onChange(of: trafficLightState) { _, newValue in
                        if newValue == 2 {
                            withAnimation(Animation.linear(duration: 4.0)) {
                                carOffset2 = -200
                            }
                        } else {
                            withAnimation(Animation.easeOut(duration: 0.5)) {
                                carOffset2 = 70
                            }
                        }
                    }
            }
        }
    }

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
    
    
    // UPDATED NEIGHBORHOOD ENVIRONMENT WITH CORRECTED DOG
    struct NeighborhoodEnvironment: View {
        @State private var kidOffset: CGFloat = -150    // For biker
        @State private var kid2Offset: CGFloat = 150    // For skateboarder
        @State private var cloudOffset: CGFloat = -200
        @State private var dogTailAngle: Double = -10
        @State private var smallBirdOffset: CGFloat = -150
        @State private var smallBirdY: CGFloat = -70
        @State private var ballOffset: CGFloat = 15     // For ball between children
        @State private var throwingArmAngle: Double = 45
        @State private var catchingArmAngle: Double = -20
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 70)
                    .offset(y: -40)
                
                // Cloud
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 30, height: 20)
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 20, height: 20)
                        .offset(x: -15, y: 0)
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 25, height: 25)
                        .offset(x: 15, y: 0)
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 22, height: 22)
                        .offset(x: 0, y: -10)
                }
                .offset(x: cloudOffset, y: -60)
                .onAppear {
                    withAnimation(Animation.linear(duration: 30.0).repeatForever(autoreverses: false)) {
                        cloudOffset = 200
                    }
                }
                
                // Small Bird
                ZStack {
                    Capsule()
                        .fill(Color.yellow)
                        .frame(width: 10, height: 6)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 6, height: 6)
                        .offset(x: 5, y: -2)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: 6, y: -3)
                    Triangle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 3)
                        .offset(x: 9, y: -2)
                        .rotationEffect(.degrees(90))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: -2))
                        path.addLine(to: CGPoint(x: -2, y: -6))
                        path.addLine(to: CGPoint(x: 5, y: -4))
                        path.closeSubpath()
                    }
                    .fill(Color.yellow.opacity(0.8))
                    .rotationEffect(.degrees(sin(Double(smallBirdOffset) * 0.05) * 20))
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 2))
                        path.addLine(to: CGPoint(x: -2, y: 6))
                        path.addLine(to: CGPoint(x: 5, y: 4))
                        path.closeSubpath()
                    }
                    .fill(Color.yellow.opacity(0.8))
                    .rotationEffect(.degrees(sin(Double(smallBirdOffset) * 0.05) * -20))
                }
                .offset(x: smallBirdOffset, y: smallBirdY)
                .onAppear {
                    withAnimation(Animation.linear(duration: 15.0).repeatForever(autoreverses: false)) {
                        smallBirdOffset = 200
                    }
                    withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        smallBirdY = -65
                    }
                }
                
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.4)]), startPoint: .top, endPoint: .bottom))
                    .frame(height: 80)
                    .offset(y: 35)
                
                // Tree
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.brown, Color(red: 0.4, green: 0.2, blue: 0.1)]), startPoint: .leading, endPoint: .trailing))
                        .frame(width: 15, height: 60)
                        .offset(y: 10)
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 60, height: 60)
                        .offset(y: -25)
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 50, height: 50)
                        .offset(x: 15, y: -30)
                    Circle()
                        .fill(Color.green.opacity(0.7))
                        .frame(width: 45, height: 45)
                        .offset(x: -15, y: -35)
                }
                .offset(x: -120, y: 0)
                
                // House
                ZStack {
                    Rectangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.brown.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 120, height: 80)
                        .offset(y: -20)
                    Triangle()
                        .fill(LinearGradient(gradient: Gradient(colors: [Color.red, Color.red.opacity(0.7)]), startPoint: .top, endPoint: .bottom))
                        .frame(width: 140, height: 50)
                        .offset(y: -85)
                    Rectangle()
                        .fill(Color.brown.opacity(0.7))
                        .frame(width: 20, height: 40)
                        .offset(x: 10, y: 0)
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 5, height: 5)
                        .offset(x: 0, y: 0)
                    ZStack {
                        Rectangle()
                            .fill(Color.yellow.opacity(0.6))
                            .frame(width: 30, height: 30)
                            .offset(x: -30, y: -20)
                        ZStack {
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 15, height: 20)
                                .offset(x: -30, y: -15)
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 10, height: 10)
                                .offset(x: -30, y: -30)
                            Rectangle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 10, height: 5)
                                .offset(x: -30, y: -10)
                        }
                    }
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .offset(x: 40, y: -20)
                }
                
                // Dog with Human
                ZStack {
                    HumanView()
                        .offset(x: -100, y: 30)
                    ZStack {
                        Capsule()
                            .fill(Color.brown)
                            .frame(width: 25, height: 15)
                            .offset(x: -70, y: 45)
                        Circle()
                            .fill(Color.brown)
                            .frame(width: 12, height: 12)
                            .offset(x: -58, y: 40)
                        Capsule()
                            .fill(Color.brown.opacity(0.8))
                            .frame(width: 6, height: 10)
                            .rotationEffect(.degrees(-30))
                            .offset(x: -62, y: 33)
                        Capsule()
                            .fill(Color.brown.opacity(0.8))
                            .frame(width: 6, height: 10)
                            .rotationEffect(.degrees(-10))
                            .offset(x: -54, y: 33)
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 3.5, height: 3.5)
                                .offset(x: -60, y: 38)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 1, height: 1)
                                .offset(x: -59.5, y: 37.5)
                        }
                        ZStack {
                            Circle()
                                .fill(Color.black)
                                .frame(width: 3.5, height: 3.5)
                                .offset(x: -55, y: 38)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 1, height: 1)
                                .offset(x: -54.5, y: 37.5)
                        }
                        Circle()
                            .fill(Color.black)
                            .frame(width: 4, height: 4)
                            .offset(x: -57, y: 42)
                        Path { path in
                            path.move(to: CGPoint(x: -59, y: 43))
                            path.addLine(to: CGPoint(x: -55, y: 43))
                        }
                        .stroke(Color.black, lineWidth: 0.8)
                        ZStack {
                            Capsule()
                                .fill(Color.red.opacity(0.8))
                                .frame(width: 3, height: 5)
                                .offset(x: -57, y: 45)
                            Path { path in
                                path.move(to: CGPoint(x: -57, y: 47))
                                path.addLine(to: CGPoint(x: -57, y: 48))
                                path.addLine(to: CGPoint(x: -58, y: 48))
                                path.move(to: CGPoint(x: -57, y: 47))
                                path.addLine(to: CGPoint(x: -57, y: 48))
                                path.addLine(to: CGPoint(x: -56, y: 48))
                            }
                            .stroke(Color.red.opacity(0.8), lineWidth: 1.5)
                        }
                        Path { path in
                            path.move(to: CGPoint(x: -82, y: 45))
                            path.addCurve(
                                to: CGPoint(x: -90, y: 40 + CGFloat(dogTailAngle)),
                                control1: CGPoint(x: -85, y: 45),
                                control2: CGPoint(x: -88, y: 42 + CGFloat(dogTailAngle/2))
                            )
                        }
                        .stroke(Color.brown, lineWidth: 3)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                dogTailAngle = 10
                            }
                        }
                        Path { path in
                            path.move(to: CGPoint(x: -100, y: 30))
                            path.addLine(to: CGPoint(x: -70, y: 40))
                            path.addLine(to: CGPoint(x: -58, y: 40))
                        }
                        .stroke(Color.black, lineWidth: 1)
                    }
                }
                
                // Biker (Moving)
                ZStack {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 40, height: 10)
                        .offset(y: 35)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 5, height: 5)
                        .offset(x: -15, y: 40)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 5, height: 5)
                        .offset(x: 15, y: 40)
                    ZStack {
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 15, height: 30)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                            .frame(width: 15, height: 15)
                            .offset(y: -22)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: -3, y: -22)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: 3, y: -22)
                        Path { path in
                            path.move(to: CGPoint(x: -3, y: -18))
                            path.addQuadCurve(to: CGPoint(x: 3, y: -18), control: CGPoint(x: 0, y: -16))
                        }
                        .stroke(Color.black, lineWidth: 1)
                    }
                    .offset(y: 10)
                }
                .offset(x: kidOffset, y: 20)
                .onAppear {
                    withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        kidOffset = 150
                    }
                }
                
                // Skateboarder (Moving)
                ZStack {
                    ZStack {
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 20, height: 20)
                            .offset(x: 0, y: 40)
                        Circle()
                            .stroke(Color.black, lineWidth: 1)
                            .frame(width: 20, height: 20)
                            .offset(x: 20, y: 40)
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 40))
                            path.addLine(to: CGPoint(x: 10, y: 25))
                            path.addLine(to: CGPoint(x: 20, y: 40))
                        }
                        .stroke(Color.black, lineWidth: 1)
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 1, height: 15)
                            .offset(x: 10, y: 17)
                    }
                    ZStack {
                        Capsule()
                            .fill(Color.green)
                            .frame(width: 12, height: 25)
                            .offset(x: 10, y: 5)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                            .frame(width: 12, height: 12)
                            .offset(x: 10, y: -12)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: 8, y: -12)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: 12, y: -12)
                        Path { path in
                            path.move(to: CGPoint(x: 7, y: -9))
                            path.addQuadCurve(to: CGPoint(x: 13, y: -9), control: CGPoint(x: 10, y: -7))
                        }
                        .stroke(Color.black, lineWidth: 1)
                        Path { path in
                            path.move(to: CGPoint(x: 4, y: -15))
                            path.addQuadCurve(to: CGPoint(x: 16, y: -15), control: CGPoint(x: 10, y: -20))
                        }
                        .fill(Color.blue)
                    }
                }
                .offset(x: kid2Offset, y: 15)
                .onAppear {
                    withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                        kid2Offset = -150
                    }
                }
                
                // Restored Two Children Playing Ball (Static)
                ZStack {
                    // First Child (Throwing, Purple)
                    ZStack {
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: 13, height: 25)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                            .frame(width: 13, height: 13)
                            .offset(y: -19)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: -3, y: -19)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: 3, y: -19)
                        Capsule()
                            .fill(Color.purple)
                            .frame(width: 5, height: 15)
                            .offset(x: 10, y: -5)
                            .rotationEffect(.degrees(throwingArmAngle))
                    }
                    .offset(y: 20)
                    
                    // Ball
                    Circle()
                        .fill(Color.red.opacity(0.8))
                        .frame(width: 10, height: 10)
                        .offset(x: ballOffset, y: 15)
                    
                    // Second Child (Catching, Red)
                    ZStack {
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 13, height: 25)
                        Circle()
                            .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                            .frame(width: 13, height: 13)
                            .offset(y: -19)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: -3, y: -19)
                        Circle()
                            .fill(Color.black)
                            .frame(width: 2, height: 2)
                            .offset(x: 3, y: -19)
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 5, height: 15)
                            .offset(x: -10, y: -5)
                            .rotationEffect(.degrees(catchingArmAngle))
                        Capsule()
                            .fill(Color.red)
                            .frame(width: 5, height: 15)
                            .offset(x: 10, y: -5)
                            .rotationEffect(.degrees(-10))
                    }
                    .offset(x: 70, y: 20)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        ballOffset = 55
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(Animation.easeOut(duration: 0.3)) {
                                throwingArmAngle = 20
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                withAnimation(Animation.easeIn(duration: 0.3)) {
                                    throwingArmAngle = 45
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(Animation.easeOut(duration: 0.3)) {
                                catchingArmAngle = 10
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                withAnimation(Animation.easeIn(duration: 0.2)) {
                                    catchingArmAngle = -20
                                }
                            }
                        }
                    }
                }
            }
        }
    }
                        
    // STANDARD COMPONENTS USED ACROSS ENVIRONMENTS
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
}
