///
//  TimerViewModel.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import Foundation
import SwiftUI
import UserNotifications

class TimerViewModel: ObservableObject {
    @Published var hours: Int = 0
    @Published var minutes: Int = 0
    @Published var seconds: Int = 0
    @Published var label: String = ""
    @Published var isRunning: Bool = false
    @Published var remainingTime: TimeInterval = 0
    @Published var timerHistory: [TimerHistoryItem] = []
    @Published var showAnimation: Bool = false
    
    private var timer: Timer?
    var initialDuration: TimeInterval = 0
    
    init() {
        loadHistory()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func startTimer() {
        guard !isRunning else { return }
        
        initialDuration = TimeInterval(hours * 3600 + minutes * 60 + seconds)
        remainingTime = initialDuration
        
        if remainingTime <= 0 { return }
        
        isRunning = true
        showAnimation = true
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.remainingTime > 0 {
                self.remainingTime -= 1
            } else {
                self.stopTimer()
            }
        }
        
        scheduleTimerNotification()
    }
    
    func stopTimer() {
        timer?.invalidate()
        isRunning = false
        showAnimation = false
        
        if initialDuration > 0 {
            let historyItem = TimerHistoryItem(
                title: formattedTime(initialDuration),
                label: label.isEmpty ? "Timer" : label
            )
            timerHistory.append(historyItem)
            saveHistory()
        }
    }
    
    func resetTimer() {
        timer?.invalidate()
        isRunning = false
        remainingTime = 0
        hours = 0
        minutes = 0
        seconds = 0
        label = ""
        showAnimation = false
        initialDuration = 0
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["timerNotification"])
    }
    
    private func scheduleTimerNotification() {
        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "Timer Finished" : "\(label) Finished"
        content.body = "Your timer has completed!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingTime, repeats: false)
        let request = UNNotificationRequest(identifier: "timerNotification", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling timer notification: \(error)")
            }
        }
    }
    
    // Changed from private to public
    public func saveHistory() {
        if let encoded = try? JSONEncoder().encode(timerHistory) {
            UserDefaults.standard.set(encoded, forKey: "timerHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "timerHistory"),
           let decoded = try? JSONDecoder().decode([TimerHistoryItem].self, from: data) {
            timerHistory = decoded
        }
    }
}

struct TimerHistoryItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let label: String
    
    init(title: String, label: String) {
        self.id = UUID()
        self.title = title
        self.label = label
    }
}
