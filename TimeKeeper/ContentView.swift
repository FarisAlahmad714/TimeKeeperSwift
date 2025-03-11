//
//  ContentView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var islandOffset: CGFloat = -60
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main TabView with proper alignment
            TabView(selection: $selectedTab) {
                AlarmSetterView() // This is what's used in your TimeKeeper folder
                    .tabItem {
                        Label("Alarms", systemImage: "alarm")
                    }
                    .tag(0)
                
                WorldClockView()
                    .tabItem {
                        Label("World Clock", systemImage: "globe")
                    }
                    .tag(1)
                
                StopwatchView()
                    .tabItem {
                        Label("Stopwatch", systemImage: "stopwatch")
                    }
                    .tag(2)
                
                TimerView()
                    .tabItem {
                        Label("Timer", systemImage: "timer")
                    }
                    .tag(3)
            }
            .accentColor(.red)
            
            // Dynamic Island at the top
            IslandView()
                .offset(y: islandOffset)
                .zIndex(100) // Ensure it stays on top
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Allow dragging the island down to reveal more or up to hide it
                            let newOffset = -60 + value.translation.height
                            islandOffset = min(10, max(-110, newOffset))
                        }
                        .onEnded { _ in
                            // Snap to one of two positions based on current offset
                            withAnimation(.spring()) {
                                islandOffset = islandOffset > -30 ? 10 : -60
                            }
                        }
                )
                .onChange(of: selectedTab) { oldValue, newValue in // Fixed deprecated API
                    // Animate the island slightly when changing tabs
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        islandOffset = -65
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring()) {
                            islandOffset = -60
                        }
                    }
                }
        }
        .onAppear {
            // Start with the island partially visible
            withAnimation(.spring().delay(0.5)) {
                islandOffset = -60
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AlarmViewModel())
            .environmentObject(WorldClockViewModel())
            .environmentObject(StopwatchViewModel())
            .environmentObject(TimerViewModel())
            .environmentObject(SpaceshipViewModel())
    }
}
