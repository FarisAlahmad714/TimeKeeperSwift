//
//  ContentView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            AlarmsView()
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
        .accentColor(.red) // Similar to the "tomato" color in the original app
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AlarmViewModel())
            .environmentObject(WorldClockViewModel())
    }
}
