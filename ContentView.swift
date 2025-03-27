//
//  ContentView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
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
                    Image("stopwatch_icon") // You can decide which icon to use
                        .renderingMode(.original)
                    Text("TimeKeeper")
                }
                .tag(2)
        }
        .accentColor(.red)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AlarmViewModel())
            .environmentObject(WorldClockViewModel())
            .environmentObject(StopwatchViewModel())
            .environmentObject(TimerViewModel())
    }
}
