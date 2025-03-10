//
//  SpaceshipView 2.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//


import SwiftUI

struct SpaceshipView: View {
    let spaceship: Spaceship
    let onTap: () -> Void
    @EnvironmentObject var viewModel: SpaceshipViewModel
    
    @State private var animationPhase: Double = 0
    @State private var isShowingAd: Bool = false
    
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
            .overlay(
                specialEffectOverlay
            )
            .overlay(
                // Debug overlay to ensure the spaceship is rendered correctly
                Text(spaceship.name)
                    .font(.caption)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.5))
                    .padding(3)
                    .offset(y: -50)
            )
            
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
            
            // Show ad if available
            if spaceship.adContent != nil {
                withAnimation {
                    isShowingAd = true
                }
            }
            
            // Print debug info
            print("SpaceshipView appeared: \(spaceship.name) at \(spaceship.position), visible: \(spaceship.visible)")
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
    
    @ViewBuilder
    private var specialEffectOverlay: some View {
        if let effect = spaceship.specialEffect, spaceship.premium {
            switch effect {
            case .trail:
                TrailEffect()
            case .glow:
                GlowEffect(color: .yellow)
            case .warpField:
                WarpFieldEffect()
            case .teleport:
                TeleportEffect()
            case .explosion:
                EmptyView() // Placeholder for explosion effect
            }
        } else {
            EmptyView()
        }
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

// Special effect components
struct TrailEffect: View {
    var body: some View {
        // Simple particle trail
        ZStack {
            ForEach(0..<5) { i in
                Circle()
                    .fill(Color.blue.opacity(0.7 - Double(i) * 0.15))
                    .frame(width: 15 - CGFloat(i) * 2, height: 15 - CGFloat(i) * 2)
                    .offset(x: -25 - CGFloat(i) * 5)
                    .blur(radius: CGFloat(i))
            }
        }
    }
}

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