//
//  TimeKeeperApp.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//
import SwiftUI
import UserNotifications

@main
struct TimeKeeperApp: App {
    @StateObject private var alarmViewModel = AlarmViewModel()
    @StateObject private var worldClockViewModel = WorldClockViewModel()
    @StateObject private var stopwatchViewModel = StopwatchViewModel()
    @StateObject private var timerViewModel = TimerViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmViewModel)
                .environmentObject(worldClockViewModel)
                .environmentObject(stopwatchViewModel)
                .environmentObject(timerViewModel)
                .onAppear {
                    // Request notification permissions
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                        if granted {
                            print("Notification permission granted")
                        } else if let error = error {
                            print("Error requesting notification permissions: \(error.localizedDescription)")
                        }
                    }
                }
        }
    }
}
