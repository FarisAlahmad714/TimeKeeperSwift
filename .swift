//
//  TimeKeeperApp 2.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/12/25.
//


//  TimeKeeperApp.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.

import SwiftUI
import UserNotifications
import FirebaseCore


@main
struct TimeKeeperApp: App {
    // Reference the existing AppDelegate from AppDelegate.swift
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // Use the shared AlarmViewModel instance
    @StateObject var alarmViewModel = AppDelegate.sharedAlarmViewModel
    @StateObject var stopwatchViewModel = StopwatchViewModel()
    @StateObject var timerViewModel = TimerViewModel()
    @StateObject var worldClockViewModel = WorldClockViewModel()
    
    init() {
        // Keep your notification permission request
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
