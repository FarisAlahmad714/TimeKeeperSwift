//
//  TimerViewModel.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import Foundation
import SwiftUI
import UserNotifications

class TimerViewModel: ObservableObject {
    @Published var hours = 0
    @Published var minutes = 0
    @Published var seconds = 0
    @Published var remainingTime: TimeInterval = 0
    @Published var isRunning = false
    @Published var showAnimation = false
    @Published var label = ""
    @Published var timerHistory: [TimerHistoryItem] = []
    
    private var timer: Timer?
    private var endDate: Date?
    
    // Basic functionality - we'll expand as needed
    func startTimer() {
        // Implementation will be added as we build
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func resetTimer() {
        stopTimer()
        remainingTime = 0
        hours = 0
        minutes = 0
        seconds = 0
        label = ""
    }
}

struct TimerHistoryItem: Identifiable {
    var id: UUID = UUID()
    var title: String
    var label: String
}