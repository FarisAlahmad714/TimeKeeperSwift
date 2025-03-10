//
//  ContentView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AlarmSetterView() // Replace AlarmsView with AlarmSetterView
                .tabItem {
                    Label("Alarms", systemImage: "alarm")
                }
            
            WorldClockView()
                .tabItem {
                    Label("World Clock", systemImage: "globe")
                }
            
            StopwatchView()
                .tabItem {
                    Label("Stopwatch", systemImage: "stopwatch")
                }
            
            TimerView()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }
        }
        .accentColor(.red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AlarmViewModel())
            .environmentObject(WorldClockViewModel())
    }
}
