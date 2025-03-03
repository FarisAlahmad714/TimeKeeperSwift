//
//  TimerView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import SwiftUI

struct TimerView: View {
    @EnvironmentObject var viewModel: TimerViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        Text("Timer")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        // Countdown Display
                        ZStack {
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: 4)
                                .frame(width: 200, height: 200)
                            
                            Text(viewModel.formattedTime(viewModel.remainingTime))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                        }
                        .padding()
                        .opacity(viewModel.showAnimation ? 1.0 : 0.0)
                        .scaleEffect(viewModel.showAnimation ? 1.0 : 0.8)
                        .animation(.spring(), value: viewModel.showAnimation)
                        
                        // Timer Input
                        if !viewModel.isRunning {
                            VStack(spacing: 15) {
                                TextField("Label", text: $viewModel.label)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    )
                                
                                HStack(spacing: 10) {
                                    Picker("Hours", selection: $viewModel.hours) {
                                        ForEach(0..<24) { Text("\($0)").tag($0) }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    
                                    Picker("Minutes", selection: $viewModel.minutes) {
                                        ForEach(0..<60) { Text("\($0)").tag($0) }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    
                                    Picker("Seconds", selection: $viewModel.seconds) {
                                        ForEach(0..<60) { Text("\($0)").tag($0) }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 100)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Controls
                        HStack(spacing: 20) {
                            Button(action: {
                                if viewModel.isRunning {
                                    viewModel.stopTimer()
                                } else {
                                    viewModel.startTimer()
                                }
                            }) {
                                Text(viewModel.isRunning ? "Stop" : "Start")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: viewModel.isRunning ? [Color.red, Color.orange] : [Color.green, Color.cyan]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(50)
                                    .shadow(color: (viewModel.isRunning ? Color.red : Color.green).opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            
                            Button(action: {
                                viewModel.resetTimer()
                            }) {
                                Text("Reset")
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
                            .disabled(viewModel.isRunning || (viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0))
                            .opacity(viewModel.isRunning || (viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0) ? 0.5 : 1.0)
                        }
                        .padding(.horizontal)
                        
                        // History
                        if !viewModel.timerHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("History")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(.top)
                                
                                ForEach(viewModel.timerHistory) { item in
                                    HStack {
                                        Text(item.title)
                                            .font(.subheadline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(item.label)
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
                        }
                        
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct TimerView_Previews: PreviewProvider {
    static var previews: some View {
        TimerView()
            .environmentObject(TimerViewModel())
            .preferredColorScheme(.dark)
    }
}
