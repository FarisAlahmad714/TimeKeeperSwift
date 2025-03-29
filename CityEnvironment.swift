//
//  CityEnvironment.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/28/25.
//
import SwiftUI
 

struct CityEnvironment: View {
    @State private var carOffset1: CGFloat = -150
    @State private var carOffset2: CGFloat = 150
    @State private var trafficLightState: Int = 0
    @State private var windowsAnimation: Double = 0.0
    @State private var clockHandAngle: Double = 0.0
    @State private var pedestrianYOffset: CGFloat = -35
    @State private var humanOffset: CGFloat = -UIScreen.main.bounds.width

    var body: some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.blue.opacity(0.2)]), startPoint: .top, endPoint: .bottom))
                .frame(height: 80)
                .offset(y: -35)
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
                    .offset(x: 100, y: -50)// Continuation of CityEnvironment
                    Color.indigo.opacity(0.6)                            .frame(width: 50, height: 100)
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
                Rectangle()
                    .fill(Color.gray)
                    .frame(height: 30)
                    .offset(y: 50)
                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: 300, height: 2)
                    .offset(y: 50)
                ForEach(0..<7) { i in
                    Rectangle()
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 20, height: 2)
                        .offset(x: CGFloat(i * 50) - 150, y: 40)
                }
                ZStack {
                    MiniHumanView(color: .red)
                        .frame(width: 10, height: 20)
                        .offset(x: -10, y: pedestrianYOffset)
                    ZStack {
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 5, height: 10)
                        Circle()
                            .fill(Color(red: 0.7, green: 0.5, blue: 0.4)) // Dark skin tone
                            .frame(width: 5, height: 5)
                            .offset(y: -7)
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 2, height: 5)
                            .offset(x: -3, y: -2)
                            .rotationEffect(.degrees(-15), anchor: .top)
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 2, height: 5)
                            .offset(x: 3, y: -2)
                            .rotationEffect(.degrees(15), anchor: .top)
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 2, height: 5)
                            .offset(x: -1.5, y: 5)
                            .rotationEffect(.degrees(15), anchor: .top)
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 2, height: 5)
                            .offset(x: 1.5, y: 5)
                            .rotationEffect(.degrees(-15), anchor: .top)
                    }
                    .frame(width: 10, height: 20)
                    .offset(x: 0, y: pedestrianYOffset)
                    MiniHumanView(color: .green)
                        .frame(width: 10, height: 20)
                        .offset(x: 10, y: pedestrianYOffset)
                }
                .offset(x: 0, y: 35)
                HumanView()
                    .frame(width: 40, height: 80)
                    .offset(x: humanOffset, y: 10)
                    .onAppear {
                        withAnimation(Animation.linear(duration: 5.0).delay(1.0)) {
                            humanOffset = -100
                        }
                    }
                ZStack {
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
