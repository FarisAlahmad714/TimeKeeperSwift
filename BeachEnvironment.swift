//
//  BeachEnvironment.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/28/25.
//
import SwiftUI



// MARK: - BeachEnvironment
struct BeachEnvironment: View {
    @State private var waveOffset: CGFloat = 0.0
    @State private var humanOffset: CGFloat = -150
    @State private var palmSway: Double = 0.0
    @State private var surferPosition: CGFloat = 0.0
    @State private var surferBalance: Double = 0.0
    @State private var armAngle: Double = 0.0
    @State private var seagull1Position: CGFloat = -200
    @State private var seagull1Y: CGFloat = -80
    @State private var seagull2Position: CGFloat = 150
    @State private var seagull2Y: CGFloat = -60
    @State private var seagull3Position: CGFloat = -50
    @State private var seagull3Y: CGFloat = -70
    @State private var wingAngle: Double = 0.0

    var body: some View {
        ZStack {
            // Background layers
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
                .frame(height: 80)
                .offset(y: -35)
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.yellow.opacity(0.8), Color(red: 0.95, green: 0.8, blue: 0.6)]), startPoint: .top, endPoint: .bottom))
                .frame(height: 70)
                .offset(y: 40)
            Rectangle()
                .fill(Color.blue.opacity(0.5))
                .frame(height: 30)
                .offset(y: 60)
            
            // Z-Index ordering for trees, beach characters and wave
            ZStack {
                // Trees - at the back (z-index 1)
                ZStack {
                    // PALM TREES - CODE UNCHANGED
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 40))
                            path.addCurve(to: CGPoint(x: 0, y: -30), control1: CGPoint(x: 5, y: 20), control2: CGPoint(x: -5, y: 0))
                        }
                        .stroke(Color.brown, lineWidth: 6)
                        .rotationEffect(.degrees(palmSway/2), anchor: .bottom)
                        ForEach(0..<7) { i in
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: -30))
                                path.addCurve(to: CGPoint(x: cos(Double(i) * .pi / 3.5) * 30, y: -30 + sin(Double(i) * .pi / 3.5) * 25), control1: CGPoint(x: cos(Double(i) * .pi / 3.5) * 15, y: -35), control2: CGPoint(x: cos(Double(i) * .pi / 3.5) * 25, y: -32 + sin(Double(i) * .pi / 3.5) * 8))
                            }
                            .stroke(Color.green, lineWidth: 2.5)
                            .rotationEffect(.degrees(palmSway/2), anchor: .bottom)
                        }
                    }
                    .offset(x: 0, y: 30)
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: -50, y: 40))
                            path.addCurve(to: CGPoint(x: -50, y: -40), control1: CGPoint(x: -55, y: 20), control2: CGPoint(x: -45, y: 0))
                        }
                        .stroke(Color.brown, lineWidth: 8)
                        .rotationEffect(.degrees(palmSway), anchor: .bottom)
                        ForEach(0..<7) { i in
                            Path { path in
                                path.move(to: CGPoint(x: -50, y: -40))
                                path.addCurve(to: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30), control1: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 20, y: -45), control2: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10))
                            }
                            .stroke(Color.green, lineWidth: 3)
                            .rotationEffect(.degrees(palmSway), anchor: .bottom)
                        }
                    }
                    .offset(x: -70, y: 40)
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 50, y: 40))
                            path.addCurve(to: CGPoint(x: 50, y: -40), control1: CGPoint(x: 45, y: 20), control2: CGPoint(x: 55, y: 0))
                        }
                        .stroke(Color.brown, lineWidth: 8)
                        .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                        ForEach(0..<7) { i in
                            Path { path in
                                path.move(to: CGPoint(x: 50, y: -40))
                                path.addCurve(to: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30), control1: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 20, y: -45), control2: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10))
                            }
                            .stroke(Color.green, lineWidth: 3)
                            .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                        }
                    }
                    .offset(x: 70, y: 40)
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: -50, y: 40))
                            path.addCurve(to: CGPoint(x: -50, y: -40), control1: CGPoint(x: -55, y: 20), control2: CGPoint(x: -45, y: 0))
                        }
                        .stroke(Color.brown, lineWidth: 6)
                        .rotationEffect(.degrees(palmSway), anchor: .bottom)
                        ForEach(0..<7) { i in
                            Path { path in
                                path.move(to: CGPoint(x: -50, y: -40))
                                path.addCurve(to: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30), control1: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 20, y: -45), control2: CGPoint(x: -50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10))
                            }
                            .stroke(Color.green, lineWidth: 3)
                            .rotationEffect(.degrees(palmSway), anchor: .bottom)
                        }
                    }
                    .offset(x: -120, y: 35)
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 50, y: 40))
                            path.addCurve(to: CGPoint(x: 50, y: -40), control1: CGPoint(x: 45, y: 20), control2: CGPoint(x: 55, y: 0))
                        }
                        .stroke(Color.brown, lineWidth: 6)
                        .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                        ForEach(0..<7) { i in
                            Path { path in
                                path.move(to: CGPoint(x: 50, y: -40))
                                path.addCurve(to: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 40, y: -40 + sin(Double(i) * .pi / 3.5) * 30), control1: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 20, y: -45), control2: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 30, y: -42 + sin(Double(i) * .pi / 3.5) * 10))
                            }
                            .stroke(Color.green, lineWidth: 3)
                            .rotationEffect(.degrees(-palmSway), anchor: .bottom)
                        }
                    }
                    .offset(x: 120, y: 35)
                    ZStack {
                        Path { path in
                            path.move(to: CGPoint(x: 50, y: 40))
                            path.addCurve(to: CGPoint(x: 50, y: -35), control1: CGPoint(x: 45, y: 20), control2: CGPoint(x: 55, y: 0))
                        }
                        .stroke(Color.brown, lineWidth: 7)
                        .rotationEffect(.degrees(-palmSway*1.2), anchor: .bottom)
                        ForEach(0..<7) { i in
                            Path { path in
                                path.move(to: CGPoint(x: 50, y: -35))
                                path.addCurve(to: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 35, y: -35 + sin(Double(i) * .pi / 3.5) * 28), control1: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 18, y: -38), control2: CGPoint(x: 50 + cos(Double(i) * .pi / 3.5) * 28, y: -37 + sin(Double(i) * .pi / 3.5) * 8))
                            }
                            .stroke(Color.green, lineWidth: 3)
                            .rotationEffect(.degrees(-palmSway*1.2), anchor: .bottom)
                        }
                    }
                    .offset(x: 150, y: 38)
                }
                .zIndex(1)
                
                // Blue Person - middle layer (z-index 2)
                ZStack {
                    Capsule()
                        .fill(Color.blue)
                        .frame(width: 20, height: 40)
                        .offset(y: 10)
                    Circle()
                        .fill(Color(red: 0.85, green: 0.65, blue: 0.5)) // Medium dark skin tone
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
                .zIndex(2)
                
                // Grandma (Purple) - foreground (z-index 3)
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
                .zIndex(3)
                
                // Walking human
                HumanView()
                    .offset(x: humanOffset, y: 30)
                    .zIndex(2)
            }
            
            // Seagulls
            ZStack {
                // Seagull 1
                ZStack {
                    // Body and head
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 12, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 15, y: -4), control: CGPoint(x: 15, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 17, y: -7), control: CGPoint(x: 16, y: -5))
                        path.addQuadCurve(to: CGPoint(x: 16, y: -9), control: CGPoint(x: 17, y: -8))
                        path.addLine(to: CGPoint(x: -2, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -1, y: 0))
                    }
                    .fill(Color.white)
                    
                    // Beak
                    Path { path in
                        path.move(to: CGPoint(x: 17, y: -7))
                        path.addLine(to: CGPoint(x: 22, y: -8))
                        path.addLine(to: CGPoint(x: 17, y: -5.5))
                    }
                    .fill(Color.orange)
                    
                    // Eye
                    Circle()
                        .fill(Color.black)
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: 16, y: -7)
                    
                    // Wings
                    Path { path in
                        path.move(to: CGPoint(x: 2, y: 0))
                        path.addLine(to: CGPoint(x: -10, y: -3 + CGFloat(wingAngle)))
                        path.addLine(to: CGPoint(x: -15, y: 2))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    
                    Path { path in
                        path.move(to: CGPoint(x: 8, y: 0))
                        path.addLine(to: CGPoint(x: 20, y: 2 - CGFloat(wingAngle)))
                        path.addLine(to: CGPoint(x: 18, y: 5))
                        path.addLine(to: CGPoint(x: 6, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    
                    // Tail
                    Path { path in
                        path.move(to: CGPoint(x: -2, y: -1))
                        path.addLine(to: CGPoint(x: -8, y: -4))
                        path.addLine(to: CGPoint(x: -5, y: 0))
                        path.addLine(to: CGPoint(x: -2, y: -1))
                    }
                    .fill(Color.white.opacity(0.9))
                }
                .scaleEffect(1.2)
                .offset(x: seagull1Position, y: seagull1Y)
                
                // Seagull 2 - going the opposite direction
                ZStack {
                    // Body and head
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 12, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 15, y: -4), control: CGPoint(x: 15, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 17, y: -7), control: CGPoint(x: 16, y: -5))
                        path.addQuadCurve(to: CGPoint(x: 16, y: -9), control: CGPoint(x: 17, y: -8))
                        path.addLine(to: CGPoint(x: -2, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -1, y: 0))
                    }
                    .fill(Color.white)
                    
                    // Beak
                    Path { path in
                        path.move(to: CGPoint(x: 17, y: -7))
                        path.addLine(to: CGPoint(x: 22, y: -8))
                        path.addLine(to: CGPoint(x: 17, y: -5.5))
                    }
                    .fill(Color.orange)
                    
                    // Eye
                    Circle()
                        .fill(Color.black)
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: 16, y: -7)
                    
                    // Wings
                    Path { path in
                        path.move(to: CGPoint(x: 2, y: 0))
                        path.addLine(to: CGPoint(x: -10, y: -3 + CGFloat(wingAngle)))
                        path.addLine(to: CGPoint(x: -15, y: 2))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    
                    Path { path in
                        path.move(to: CGPoint(x: 8, y: 0))
                        path.addLine(to: CGPoint(x: 20, y: 2 - CGFloat(wingAngle)))
                        path.addLine(to: CGPoint(x: 18, y: 5))
                        path.addLine(to: CGPoint(x: 6, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    
                    // Tail
                    Path { path in
                        path.move(to: CGPoint(x: -2, y: -1))
                        path.addLine(to: CGPoint(x: -8, y: -4))
                        path.addLine(to: CGPoint(x: -5, y: 0))
                        path.addLine(to: CGPoint(x: -2, y: -1))
                    }
                    .fill(Color.white.opacity(0.9))
                }
                .scaleEffect(0.9)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .offset(x: seagull2Position, y: seagull2Y)
                
                // Seagull 3 - closer to the beach
                ZStack {
                    // Body and head
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 0))
                        path.addLine(to: CGPoint(x: 12, y: 0))
                        path.addQuadCurve(to: CGPoint(x: 15, y: -4), control: CGPoint(x: 15, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 17, y: -7), control: CGPoint(x: 16, y: -5))
                        path.addQuadCurve(to: CGPoint(x: 16, y: -9), control: CGPoint(x: 17, y: -8))
                        path.addLine(to: CGPoint(x: -2, y: -1))
                        path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -1, y: 0))
                    }
                    .fill(Color.white)
                    
                    // Beak
                    Path { path in
                        path.move(to: CGPoint(x: 17, y: -7))
                        path.addLine(to: CGPoint(x: 22, y: -8))
                        path.addLine(to: CGPoint(x: 17, y: -5.5))
                    }
                    .fill(Color.orange)
                    
                    // Eye
                    Circle()
                        .fill(Color.black)
                        .frame(width: 1.5, height: 1.5)
                        .offset(x: 16, y: -7)
                    
                    // Wings
                    Path { path in
                        path.move(to: CGPoint(x: 2, y: 0))
                        path.addLine(to: CGPoint(x: -10, y: -3 + CGFloat(wingAngle)))
                        path.addLine(to: CGPoint(x: -15, y: 2))
                        path.addLine(to: CGPoint(x: 0, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    
                    Path { path in
                        path.move(to: CGPoint(x: 8, y: 0))
                        path.addLine(to: CGPoint(x: 20, y: 2 - CGFloat(wingAngle)))
                        path.addLine(to: CGPoint(x: 18, y: 5))
                        path.addLine(to: CGPoint(x: 6, y: 0))
                    }
                    .fill(Color.white.opacity(0.9))
                    
                    // Tail
                    Path { path in
                        path.move(to: CGPoint(x: -2, y: -1))
                        path.addLine(to: CGPoint(x: -8, y: -4))
                        path.addLine(to: CGPoint(x: -5, y: 0))
                        path.addLine(to: CGPoint(x: -2, y: -1))
                    }
                    .fill(Color.white.opacity(0.9))
                }
                .scaleEffect(0.75)
                .offset(x: seagull3Position, y: seagull3Y)
            }
            
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
            
            // Wave
            WaveShape()
                .fill(Color.blue.opacity(0.7))
                .frame(width: 350, height: 15)
                .offset(x: waveOffset, y: 55)
        }
        .onAppear {
            // Palm trees
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                palmSway = 3
            }
            
            // Surfer
            withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                surferPosition = 100
            }
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                surferBalance = 10
            }
            
            // Wave
            withAnimation(Animation.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                waveOffset = 50
            }
            
            // Walking human
            withAnimation(Animation.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                humanOffset = 150
            }
            
            // Blue human arms
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                armAngle = 30
            }
            
            // Birds - all now consistently flying left to right
            withAnimation(Animation.linear(duration: 18.0).repeatForever(autoreverses: false)) {
                seagull1Position = 250  // From -200 to 250
            }
            withAnimation(Animation.linear(duration: 22.0).repeatForever(autoreverses: false)) {
                seagull2Position = 250  // From 150 to -250 (reversed direction)
            }
            withAnimation(Animation.linear(duration: 15.0).repeatForever(autoreverses: false)) {
                seagull3Position = 250  // From -50 to 200
            }
            
            // Bird heights
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                seagull1Y = -75
            }
            withAnimation(Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                seagull2Y = -55
            }
            withAnimation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                seagull3Y = -65
            }
            
            // Wing flapping
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                wingAngle = 3
            }
        }
    }
}
