//
//  BedroomEnvironment.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/28/25.
//

import SwiftUI


// MARK: - BedroomEnvironment
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
            // Background - deep purple gradient
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color(red: 0.4, green: 0.2, blue: 0.5), Color(red: 0.3, green: 0.15, blue: 0.4)]), startPoint: .top, endPoint: .bottom))
                .frame(width: 300, height: 150)

            // Window with night sky
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white)
                    .frame(width: 66, height: 56)
                    .offset(y: -40)
                
                // Night sky inside window
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

            // Bed frame - brown color
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
                
                // Books - yellow, blue, red
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

            // Cat with properly oriented ears, whiskers, and refined face
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
                
                // Cat ears - pointing up
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
                
                // Simple, super visible mouth
                if catSleeping {
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 4, height: 1)
                        .offset(x: 0, y: -4)
                } else {
                    Ellipse()
                        .fill(Color.red)
                        .frame(width: 4, height: 3)
                        .offset(x: 0, y: -4)
                }
                
                // Simple, visible whiskers
                // Left whiskers
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 1)
                    .offset(x: -6, y: -6)
                    .rotationEffect(.degrees(-10))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 1)
                    .offset(x: -6, y: -8)
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 1)
                    .offset(x: -6, y: -4)
                    .rotationEffect(.degrees(10))
                
                // Right whiskers
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 1)
                    .offset(x: 6, y: -6)
                    .rotationEffect(.degrees(10))
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 1)
                    .offset(x: 6, y: -8)
                
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 8, height: 1)
                    .offset(x: 6, y: -4)
                    .rotationEffect(.degrees(-10))
                
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
