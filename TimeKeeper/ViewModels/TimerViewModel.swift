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
    
    init() {
        loadHistory()
    }
    
    func startTimer() {
        guard !isRunning, totalSeconds > 0 else { return }
        
        isRunning = true
        remainingTime = TimeInterval(totalSeconds)
        endDate = Date().addingTimeInterval(remainingTime)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateRemainingTime()
        }
        
        scheduleNotification()
        showAnimation = true
    }
    
    func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        showAnimation = false
        cancelNotification()
    }
    
    func resetTimer() {
        stopTimer()
        remainingTime = 0
        hours = 0
        minutes = 0
        seconds = 0
        label = ""
        showAnimation = false
    }
    
    func completeTimer() {
        addToHistory()
        resetTimer()
    }
    
    private var totalSeconds: Int {
        (hours * 3600) + (minutes * 60) + seconds
    }
    
    private func updateRemainingTime() {
        guard let endDate = endDate else { return }
        remainingTime = max(0, endDate.timeIntervalSinceNow)
        
        if remainingTime <= 0 {
            completeTimer()
        }
        
        let totalSeconds = Int(remainingTime)
        hours = totalSeconds / 3600
        minutes = (totalSeconds % 3600) / 60
        seconds = totalSeconds % 60
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = label.isEmpty ? "Timer Finished" : label
        content.body = "Your timer has completed!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: remainingTime, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling timer notification: \(error)")
            }
        }
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func addToHistory() {
        let historyItem = TimerHistoryItem(
            title: formattedTime(TimeInterval(totalSeconds)),
            label: label
        )
        timerHistory.append(historyItem)
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "timerHistory"),
           let decoded = try? JSONDecoder().decode([TimerHistoryItem].self, from: data) {
            timerHistory = decoded
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(timerHistory) {
            UserDefaults.standard.set(encoded, forKey: "timerHistory")
        }
    }
    
    func formattedTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    deinit {
        timer?.invalidate()
    }
}

struct TimerHistoryItem: Identifiable, Codable {
    var id: UUID = UUID()
    var title: String
    var label: String
}
