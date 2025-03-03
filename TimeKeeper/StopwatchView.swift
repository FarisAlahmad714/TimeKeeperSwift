//
//  StopwatchView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import SwiftUI

struct StopwatchView: View {
    @EnvironmentObject var viewModel: StopwatchViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    // Header
                    Text("Stopwatch")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Analog Clock
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.5), lineWidth: 4)
                            .frame(width: 200, height: 200)
                        
                        // Hour markers
                        ForEach(0..<60) { second in
                            let angle = Double(second) * 6 - 90 // 6 degrees per second
                            let radian = angle * .pi / 180
                            
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 2, height: second % 5 == 0 ? 10 : 5)
                                .offset(y: -90) // Position at the edge of the circle
                                .rotationEffect(.degrees(angle))
                        }
                        
                        // Second hand
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2, height: 90)
                            .offset(y: -45)
                            .rotationEffect(.degrees(viewModel.secondsAngle))
                        
                        // Minute hand
                        Rectangle()
                            .fill(Color.green)
                            .frame(width: 2, height: 70)
                            .offset(y: -35)
                            .rotationEffect(.degrees(viewModel.minutesAngle))
                        
                        // Hour hand
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: 2, height: 50)
                            .offset(y: -25)
                            .rotationEffect(.degrees(viewModel.hoursAngle))
                        
                        // Center dot
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                    }
                    .padding()
                    
                    // Time Display
                    Text(viewModel.formattedTime)
                        .font(.system(size: 40, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    // Control Buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            viewModel.startOrPause()
                        }) {
                            Text(viewModel.isRunning ? "Pause" : "Start")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: viewModel.isRunning ? [Color.yellow, Color.orange] : [Color.green, Color.cyan]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(50)
                                .shadow(color: (viewModel.isRunning ? Color.yellow : Color.green).opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        
                        Button(action: {
                            if viewModel.isRunning {
                                viewModel.addLap()
                            } else {
                                viewModel.reset()
                            }
                        }) {
                            Text(viewModel.isRunning ? "Lap" : "Reset")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.red, Color.orange]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(50)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .disabled(!viewModel.isRunning && viewModel.formattedTime == "00:00:00.00")
                        .opacity(!viewModel.isRunning && viewModel.formattedTime == "00:00:00.00" ? 0.5 : 1.0)
                    }
                    .padding(.horizontal)
                    
                    // Lap List
                    if viewModel.laps.isEmpty {
                        Text("No laps recorded")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.laps) { lap in
                                    HStack {
                                        Text("Lap \(lap.id)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(lap.time)
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StopwatchView_Previews: PreviewProvider {
    static var previews: some View {
        StopwatchView()
            .environmentObject(StopwatchViewModel())
            .preferredColorScheme(.dark)
    }
}
