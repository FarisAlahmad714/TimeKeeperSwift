import SwiftUI

struct SpaceshipView: View {
    let spaceship: Spaceship
    let onTap: () -> Void
    @EnvironmentObject var viewModel: SpaceshipViewModel
    
    @State private var animationPhase: Double = 0
    @State private var isShowingAd: Bool = false
    @State private var showAdTimer: Timer?
    @State private var adDisplayTime: TimeInterval = 0
    
    var body: some View {
        ZStack {
            // The spaceship image with fallback to SF Symbols
            Group {
                if UIImage(named: spaceship.imageAsset) != nil {
                    Image(spaceship.imageAsset)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    // Fallback to SF Symbol
                    Image(systemName: getSystemImageName(for: spaceship.name))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .frame(width: 80 * spaceship.scale, height: 80 * spaceship.scale)
            .rotationEffect(Angle(radians: spaceship.rotation))
            .scaleEffect(1.0 + 0.05 * sin(animationPhase))
            .shadow(color: specialEffectColor, radius: specialEffectRadius, x: 0, y: 0)
            
            // Add thruster effect behind the spaceship
            // Always show thruster effect for all ships
            TrailEffect()
                .scaleEffect(spaceship.scale * 0.8)
                .offset(x: -40, y: 0) // Position behind the ship
            
            // Banner/Ad if one is attached to this ship
            if let adContent = spaceship.adContent, adContent.isActive, isShowingAd {
                AdBannerView(adContent: adContent)
                    .frame(width: 150, height: 40)
                    .offset(y: -60)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .position(spaceship.position)
        .onAppear {
            // Start subtle animation
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                animationPhase = .pi * 2
            }
            
            // Show ad if available and setup ad rotation timer
            if let adContent = spaceship.adContent {
                withAnimation {
                    isShowingAd = true
                }
                
                // Setup ad rotation timer based on displayDuration
                adDisplayTime = adContent.displayDuration
                showAdTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    if adDisplayTime > 0 {
                        adDisplayTime -= 1
                    } else {
                        // Toggle ad visibility based on timing
                        withAnimation {
                            isShowingAd.toggle()
                        }
                        
                        // Reset timer
                        adDisplayTime = adContent.displayDuration
                    }
                }
            }
            
            // Print debug info
            print("SpaceshipView appeared: \(spaceship.name) at \(spaceship.position), visible: \(spaceship.visible)")
        }
        .onDisappear {
            // Clean up timer
            showAdTimer?.invalidate()
            showAdTimer = nil
        }
        .onTapGesture {
            onTap()
            print("Spaceship tapped: \(spaceship.name)")
            
            // Visual feedback on tap
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animationPhase += .pi
            }
            
            // If this ship has an ad and is tapped, trigger the ad handler
            if spaceship.adContent != nil {
                viewModel.handleAdTap()
            }
        }
    }
    
    // System image fallback based on ship name
    private func getSystemImageName(for shipName: String) -> String {
        switch shipName.lowercased() {
        case "explorer": return "airplane"
        case "cruiser": return "ferry"
        case "fighter": return "bolt.horizontal.fill"
        case "hauler": return "shippingbox"
        case "corvette": return "bolt"
        case "shuttle": return "tram"
        case "destroyer": return "target"
        case "transport": return "bus"
        case "flagship": return "shield"
        default: return "airplane.circle"
        }
    }
    
    // Special effect styling based on the ship's special effect
    private var specialEffectColor: Color {
        guard let effect = spaceship.specialEffect, spaceship.premium else {
            return Color.clear
        }
        
        switch effect {
        case .trail:
            return Color.blue.opacity(0.7)
        case .glow:
            return Color.yellow.opacity(0.6)
        case .warpField:
            return Color.purple.opacity(0.6)
        case .teleport:
            return Color.green.opacity(0.7)
        case .explosion:
            return Color.red.opacity(0.8)
        }
    }
    
    private var specialEffectRadius: CGFloat {
        guard spaceship.specialEffect != nil, spaceship.premium else {
            return 0
        }
        return 10 + 2 * sin(animationPhase)
    }
}

// Enhanced trail effect that looks like spaceship thrusters
struct TrailEffect: View {
    @State private var flameAnimation: Double = 0
    @State private var sparkleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Main flame
            ZStack {
                // Inner flame - bright center
                Triangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.white, .yellow, .orange]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 35 + CGFloat(sin(flameAnimation) * 5), height: 16)
                    .offset(x: -40)
                    .blur(radius: 1)
                
                // Outer flame
                Triangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [.orange, .red, .red.opacity(0.5)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 45 + CGFloat(sin(flameAnimation) * 8), height: 22)
                    .offset(x: 45)
                    .blur(radius: 2)
                
                // Flame particles
                ForEach(0..<6) { i in
                    Circle()
                        .fill(LinearGradient(
                                gradient: Gradient(colors: [.orange, .red, .clear]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat.random(in: 4...7), height: CGFloat.random(in: 4...7))
                        .offset(x: 55 + CGFloat(i) * 5 + sparkleOffset,
                                y: CGFloat.random(in: -10...10))
                        .opacity(0.7)
                        .blur(radius: 1)
                }
            }
            .offset(x: 40) // Position behind the ship
            
            // Smoke trail
            ZStack {
                ForEach(0..<4) { i in
                    Circle()
                        .fill(Color.gray.opacity(0.3 - Double(i) * 0.05))
                        .frame(width: 12 + CGFloat(i) * 2, height: 12 + CGFloat(i) * 2)
                        .offset(x: 55 + CGFloat(i) * 8, y: CGFloat.random(in: -5...5))
                        .blur(radius: CGFloat(1 + i))
                }
            }
            .offset(x: 40) // Position behind the ship
        }
        .onAppear {
            // Continuous flame animation
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                flameAnimation = .pi * 2
            }
            
            // Sparkle particle animation
            withAnimation(Animation.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
                sparkleOffset = 3
            }
        }
    }
}

// Triangle shape for the flame
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY - rect.height/2))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + rect.height/2))
        path.closeSubpath()
        return path
    }
}

// Ad banner for spaceships
struct AdBannerView: View {
    let adContent: AdContent
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                )
            
            HStack(spacing: 6) {
                if let bannerImage = adContent.bannerImage, UIImage(named: bannerImage) != nil {
                    Image(bannerImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                } else {
                    // Fallback to system image
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .frame(width: 30, height: 30)
                }
                
                Text(adContent.advertiserName)
                    .font(.caption)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Image(systemName: "arrow.up.forward.app")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 6)
        }
    }
}

// Special effect components (for premium ships)
struct GlowEffect: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
            .blur(radius: 15)
            .opacity(0.5)
    }
}

struct WarpFieldEffect: View {
    @State private var phase: Double = 0
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.purple.opacity(0.5 - Double(i) * 0.15), lineWidth: 2)
                    .frame(width: 70 + CGFloat(i) * 20, height: 70 + CGFloat(i) * 20)
                    .scaleEffect(1.0 + 0.1 * sin(phase + Double(i)))
            }
        }
        .onAppear {
            withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
}

struct TeleportEffect: View {
    @State private var opacity: Double = 0.8
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.6 * opacity))
                .frame(width: 60, height: 60)
                .scaleEffect(scale)
                .blur(radius: 5)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                opacity = 0.2
                scale = 1.2
            }
        }
    }
}
