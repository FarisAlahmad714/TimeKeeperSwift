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
            VStack {
                Text("Stopwatch View")
                    .font(.title)
                
                Button(viewModel.isRunning ? "Stop" : "Start") {
                    if viewModel.isRunning {
                        viewModel.stopStopwatch()
                    } else {
                        viewModel.startStopwatch()
                    }
                }
                .padding()
                .background(viewModel.isRunning ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("Stopwatch")
        }
    }
}