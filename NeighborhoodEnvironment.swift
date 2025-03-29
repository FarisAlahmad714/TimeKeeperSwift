//
//  NeighborhoodEnvironment.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/28/25.
//

import SwiftUI

   // MARK: - NeighborhoodEnvironment
struct NeighborhoodEnvironment: View {
    @State private var kidOffset: CGFloat = -150    // For biker
    @State private var kid3Offset: CGFloat = -200   // For second biker
    @State private var smallBirdOffset: CGFloat = -250 // Updated for left-to-right
    @State private var smallBirdY: CGFloat = -70
    @State private var bird2Offset: CGFloat = -200   // Updated for left-to-right
    @State private var bird2Y: CGFloat = -60
    @State private var bird3Offset: CGFloat = -150   // Updated for left-to-right
    @State private var bird3Y: CGFloat = -80
    @State private var cloudOffset: CGFloat = -200
    @State private var dogTailAngle: Double = -10
    @State private var ballOffset: CGFloat = 15     // For ball between children
    @State private var throwingArmAngle: Double = 45
    @State private var catchingArmAngle: Double = -20
    @State private var grillSmokeOffset: CGFloat = 0.0 // For cookout smoke animation
    @State private var cookoutAnimation: Double = 0.0 // For cookout activity animation
    
    // New state variables for bird animation control
    @State private var bird1AnimationActive = true
    @State private var bird2AnimationActive = true
    @State private var bird3AnimationActive = true

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
            
            // Small Bird 1
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
            
            // Small Bird 2 - Different color
            ZStack {
                Capsule()
                    .fill(Color.white)
                    .frame(width: 10, height: 6)
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .offset(x: 5, y: -2)
                Circle()
                    .fill(Color.black)
                    .frame(width: 2, height: 2)
                    .offset(x: 6, y: -3)
                Triangle()
                    .fill(Color.red)
                    .frame(width: 4, height: 3)
                    .offset(x: 9, y: -2)
                    .rotationEffect(.degrees(90))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: -2))
                    path.addLine(to: CGPoint(x: -2, y: -6))
                    path.addLine(to: CGPoint(x: 5, y: -4))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.8))
                .rotationEffect(.degrees(sin(Double(bird2Offset) * 0.05) * 20))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 2))
                    path.addLine(to: CGPoint(x: -2, y: 6))
                    path.addLine(to: CGPoint(x: 5, y: 4))
                    path.closeSubpath()
                }
                .fill(Color.white.opacity(0.8))
                .rotationEffect(.degrees(sin(Double(bird2Offset) * 0.05) * -20))
            }
            .offset(x: bird2Offset, y: bird2Y)
            
            // Small Bird 3 - Blue color
            ZStack {
                Capsule()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 10, height: 6)
                Circle()
                    .fill(Color.blue.opacity(0.7))
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
                .fill(Color.blue.opacity(0.6))
                .rotationEffect(.degrees(sin(Double(bird3Offset) * 0.05) * 20))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 2))
                    path.addLine(to: CGPoint(x: -2, y: 6))
                    path.addLine(to: CGPoint(x: 5, y: 4))
                    path.closeSubpath()
                }
                .fill(Color.blue.opacity(0.6))
                .rotationEffect(.degrees(sin(Double(bird3Offset) * 0.05) * -20))
            }
            .offset(x: bird3Offset, y: bird3Y)
            
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
            
            // Second Biker (Moving opposite direction)
            ZStack {
                Rectangle()
                    .fill(Color.purple)
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
                        .fill(Color.green)
                        .frame(width: 15, height: 30)
                    Circle()
                        .fill(Color(red: 0.7, green: 0.5, blue: 0.4)) // Dark skin tone
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
            .offset(x: kid3Offset, y: 30)
            .onAppear {
                withAnimation(Animation.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                    kid3Offset = 200
                }
            }
            
            // Two Children Playing Ball - Updated First Child to Dark Skin
            ZStack {
                // First Child (Throwing, Purple, Dark Skinned)
                ZStack {
                    Capsule()
                        .fill(Color.purple)
                        .frame(width: 13, height: 25)
                    Circle()
                        .fill(Color(red: 0.7, green: 0.5, blue: 0.4)) // Dark skin tone
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

            // Family Cookout Area - Moved Further Back
            ZStack {
                // Grill
                Rectangle()
                    .fill(Color.black)
                    .frame(width: 30, height: 20)
                    .offset(x: 100, y: -10)
                Rectangle()
                    .fill(Color.gray)
                    .frame(width: 25, height: 15)
                    .offset(x: 100, y: -15)
                Circle()
                    .fill(Color.red)
                    .frame(width: 5, height: 5)
                    .offset(x: 95, y: -20)
                Circle()
                    .fill(Color.red)
                    .frame(width: 5, height: 5)
                    .offset(x: 105, y: -20)

                // Smoke Animation
                ForEach(0..<3) { i in
                    Circle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 5 + CGFloat(i) * 2, height: 5 + CGFloat(i) * 2)
                        .offset(x: 100 + grillSmokeOffset, y: -30 - CGFloat(i) * 5)
                }
                .onAppear {
                    withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                        grillSmokeOffset = 10
                    }
                }

                // Family Members
                // Adult Male (Grilling)
                ZStack {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 15, height: 30)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.8, blue: 0.6))
                        .frame(width: 15, height: 15)
                        .offset(y: -22)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: -4, y: -22)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: 4, y: -22)
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 5, height: 15)
                        .offset(x: -10, y: -5)
                        .rotationEffect(.degrees(-30 + cookoutAnimation * 10))
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 5, height: 15)
                        .offset(x: 10, y: -5)
                        .rotationEffect(.degrees(30 - cookoutAnimation * 10))
                }
                .offset(x: 100, y: -25)

                // Adult Female (Holding Plate)
                ZStack {
                    Capsule()
                        .fill(Color.purple)
                        .frame(width: 15, height: 30)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.75)) // Lighter skin tone for female
                        .frame(width: 15, height: 15)
                        .offset(y: -22)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: -4, y: -22)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                        .offset(x: 4, y: -22)
                    Path { path in
                        path.move(to: CGPoint(x: -4, y: -18))
                        path.addQuadCurve(to: CGPoint(x: 4, y: -18), control: CGPoint(x: 0, y: -15))
                    }
                    .stroke(Color.black, lineWidth: 1) // Smile for female
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(width: 10, height: 5)
                        .offset(x: 0, y: -10) // Plate
                    Capsule()
                        .fill(Color.purple)
                        .frame(width: 5, height: 15)
                        .offset(x: -10, y: -5)
                        .rotationEffect(.degrees(-20))
                    Capsule()
                        .fill(Color.purple)
                        .frame(width: 5, height: 15)
                        .offset(x: 10, y: -5)
                        .rotationEffect(.degrees(20))
                }
                .offset(x: 120, y: -25)

                // Child Female (Playing Nearby)
                ZStack {
                    Capsule()
                        .fill(Color.pink)
                        .frame(width: 10, height: 20)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.85, blue: 0.75))
                        .frame(width: 10, height: 10)
                        .offset(y: -15)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: -3, y: -15)
                    Circle()
                        .fill(Color.black)
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: 3, y: -15)
                    Capsule()
                        .fill(Color.pink)
                        .frame(width: 3, height: 10)
                        .offset(x: -5, y: 5)
                        .rotationEffect(.degrees(20 + cookoutAnimation * 10))
                    Capsule()
                        .fill(Color.pink)
                        .frame(width: 3, height: 10)
                        .offset(x: 5, y: 5)
                        .rotationEffect(.degrees(-20 - cookoutAnimation * 10))
                }
                .offset(x: 110, y: -10)

                // Table with Food
                Rectangle()
                    .fill(Color.brown)
                    .frame(width: 40, height: 10)
                    .offset(x: 115, y: -15)
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 105, y: -20)
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                    .offset(x: 115, y: -20)
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .offset(x: 125, y: -20)
            }
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    cookoutAnimation = 1.0
                }
            }
        }
        .onAppear {
            // Start bird animations with the new approach
            startBirdAnimation(birdNumber: 1)
            
            // Stagger other birds slightly for natural look
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                startBirdAnimation(birdNumber: 2)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                startBirdAnimation(birdNumber: 3)
            }
            
            // Bird height animations remain the same
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                smallBirdY = -65
            }
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bird2Y = -55
            }
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                bird3Y = -75
            }
            
            // Other animations
            withAnimation(Animation.linear(duration: 30.0).repeatForever(autoreverses: false)) {
                cloudOffset = 200
            }
            
            withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                dogTailAngle = 10
            }
            
            withAnimation(Animation.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                kidOffset = 150
            }
            
            withAnimation(Animation.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                kid3Offset = 200
            }
        }
        .onDisappear {
            // Clean up animations when view disappears
            bird1AnimationActive = false
            bird2AnimationActive = false
            bird3AnimationActive = false
        }
    }
    
    // Helper function for bird animation control
    private func startBirdAnimation(birdNumber: Int) {
        // Reset bird to starting position without animation
        switch birdNumber {
        case 1:
            self.smallBirdOffset = -250
            self.bird1AnimationActive = true
            withAnimation(.linear(duration: 15.0)) {
                self.smallBirdOffset = 250
            }
            // When flight completes, reset and start again
            DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
                if self.bird1AnimationActive {
                    startBirdAnimation(birdNumber: 1)
                }
            }
        case 2:
            self.bird2Offset = -200
            self.bird2AnimationActive = true
            withAnimation(.linear(duration: 18.0)) {
                self.bird2Offset = 250
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 18.0) {
                if self.bird2AnimationActive {
                    startBirdAnimation(birdNumber: 2)
                }
            }
        case 3:
            self.bird3Offset = -150
            self.bird3AnimationActive = true
            withAnimation(.linear(duration: 20.0)) {
                self.bird3Offset = 250
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 20.0) {
                if self.bird3AnimationActive {
                    startBirdAnimation(birdNumber: 3)
                }
            }
        default:
            break
        }
    }
}
