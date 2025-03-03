//
//  StopwatchViewModel.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import Foundation
import SwiftUI

class StopwatchViewModel: ObservableObject {
    @Published var seconds: Double = 0.0
    @Published var isRunning: Bool = false
    @Published var laps: [Lap] = []
    
    private var timer: Timer?
    
    init() {
        reset()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    var formattedTime: String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        let milliseconds = Int((seconds - Double(totalSeconds)) * 100)
        return String(format: "%02d:%02d:%02d.%02d", hours, minutes, remainingSeconds, milliseconds)
    }
    
    // Computed properties for clock hand angles
    var secondsAngle: Double {
        let totalSeconds = seconds
        let secondsInMinute = totalSeconds.truncatingRemainder(dividingBy: 60)
        return secondsInMinute * 6 // 360 degrees / 60 seconds = 6 degrees per second
    }
    
    var minutesAngle: Double {
        let totalSeconds = seconds
        let minutes = (totalSeconds / 60).truncatingRemainder(dividingBy: 60)
        return minutes * 6 // 360 degrees / 60 minutes = 6 degrees per minute
    }
    
    var hoursAngle: Double {
        let totalSeconds = seconds
        let hours = (totalSeconds / 3600).truncatingRemainder(dividingBy: 12)
        return hours * 30 // 360 degrees / 12 hours = 30 degrees per hour
    }
    
    func startOrPause() {
        if isRunning {
            timer?.invalidate()
        } else {
            timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { [weak self] _ in
                self?.seconds += 0.01
            }
        }
        isRunning.toggle()
    }
    
    func reset() {
        timer?.invalidate()
        isRunning = false
        seconds = 0.0
        laps.removeAll()
    }
    
    func addLap() {
        let lap = Lap(id: laps.count + 1, time: formattedTime)
        laps.append(lap)
    }
}

struct Lap: Identifiable {
    let id: Int
    let time: String
}
