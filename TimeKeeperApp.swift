// TimeKeeperApp.swift
//
//  TimeKeeperApp.swift
//  TimeKeeper
//
//  TimeKeeperApp.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.

import SwiftUI
import UserNotifications
import FirebaseCore
import RealmSwift // Changed from CloudKit to RealmSwift

@main
struct TimeKeeperApp: SwiftUI.App { // Explicitly use SwiftUI.App to resolve ambiguity
    // Reference the existing AppDelegate from AppDelegate.swift
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
        
        // Use the shared AlarmViewModel instance
        @StateObject var alarmViewModel = AppDelegate.sharedAlarmViewModel
        @StateObject var stopwatchViewModel = StopwatchViewModel()
        @StateObject var timerViewModel = TimerViewModel()
        @StateObject var worldClockViewModel = WorldClockViewModel()
        
        init() {
            // Set up notification permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                if granted {
                    print("Notification permission granted")
                } else if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            
            // Register for alarm notifications
            setupNotificationObservers()
        }
        
        // Moved notification setup to a separate method to avoid init ambiguity
        private func setupNotificationObservers() {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("AlarmNotificationReceived"),
                object: nil,
                queue: .main
            ) { [self] notification in
                if let alarmID = notification.userInfo?["alarmID"] as? String,
                   let alarm = alarmViewModel.alarms.first(where: { $0.id == alarmID }) {
                    alarmViewModel.activeAlarm = alarm
                } 
            }
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
