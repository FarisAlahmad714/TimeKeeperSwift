//
//  ContentView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//
import SwiftUI

// MARK: - ContentView
struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var alarmViewModel: AlarmViewModel
    
    var body: some View {
        ZStack {
            // Main app content
            TabView(selection: $selectedTab) {
                AlarmSetterView()
                    .tabItem {
                        Image("alarm_icon")
                            .renderingMode(.original)
                        Text("Alarms")
                    }
                    .tag(0)
                
                WorldClockView()
                    .tabItem {
                        Image("worldclock_icon")
                            .renderingMode(.original)
                        Text("World Clock")
                    }
                    .tag(1)
                
                CombinedTimeView()
                    .tabItem {
                        Image("stopwatch_icon")
                            .renderingMode(.original)
                        Text("TimeKeeper")
                    }
                    .tag(2)
            }
            .accentColor(.red)
            .disabled(alarmViewModel.activeAlarm != nil) // Disable interaction when alarm is active
            
            // Alarm overlay when active - ONLY shown at root level
            if alarmViewModel.activeAlarm != nil {
                AlarmActiveOverlay()
                    .transition(.opacity)
                    .zIndex(100) // Ensure it's on top
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AlarmNotificationReceived"))) { notification in
            if let alarmID = notification.userInfo?["alarmID"] as? String,
               let alarm = alarmViewModel.alarms.first(where: { $0.id == alarmID }) {
                withAnimation {
                    alarmViewModel.activeAlarm = alarm
                }
            }
        }
    }
}

// Overlay wrapper for AlarmActiveView
struct AlarmActiveOverlay: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    
    var body: some View {
        if let alarm = viewModel.activeAlarm {
            AlarmActiveView(alarm: alarm)
        } else {
            EmptyView()
        }
    }
}
