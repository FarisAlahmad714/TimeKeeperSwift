// TimeKeeperApp.swift

//
//  TimeKeeperApp.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
import SwiftUI
import UserNotifications

@main
struct TimeKeeperApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var alarmViewModel = AlarmViewModel()
    @StateObject var stopwatchViewModel = StopwatchViewModel()
    @StateObject var timerViewModel = TimerViewModel()
    @StateObject var worldClockViewModel = WorldClockViewModel()
    
    init() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
        
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(alarmViewModel)
                .environmentObject(stopwatchViewModel)
                .environmentObject(timerViewModel)
                .environmentObject(worldClockViewModel)
                .accentColor(.red)
        }
    }
}
