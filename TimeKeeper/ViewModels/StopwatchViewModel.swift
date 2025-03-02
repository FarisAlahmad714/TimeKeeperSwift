//
//  StopwatchViewModel.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import Foundation
import SwiftUI

class StopwatchViewModel: ObservableObject {
    @Published var elapsedTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var laps: [TimeInterval] = []
    
    private var startDate: Date?
    private var timer: Timer?
    
    func startStopwatch() {
        if isRunning {
            return
        }
        
        isRunning = true
        startDate = Date().addingTimeInterval(-elapsedTime)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startDate = self.startDate else { return }
            self.elapsedTime = Date().timeIntervalSince(startDate)
        }
    }
    
    func stopStopwatch() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetStopwatch() {
        stopStopwatch()
        elapsedTime = 0
        laps = []
    }
    
    func addLap() {
        laps.append(elapsedTime)
    }
    
    deinit {
        timer?.invalidate()
    }
}