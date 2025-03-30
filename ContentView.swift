//
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var alarmViewModel: AlarmViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    // Compute if we're in landscape mode
    private var isLandscape: Bool {
        return horizontalSizeClass == .regular
    }
    
    var body: some View {
        ZStack {
            // Main app content
            TabView(selection: $selectedTab) {
                AlarmSetterView()
                    .tabItem {
                        // Custom tab item with orientation-aware sizing
                        Label {
                            Text("Alarms")
                        } icon: {
                            Image("alarm_icon")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: tabIconSize, height: tabIconSize)
                        }
                    }
                    .tag(0)
                
                WorldClockView()
                    .tabItem {
                        Label {
                            Text("World Clock")
                        } icon: {
                            Image("worldclock_icon")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: tabIconSize, height: tabIconSize)
                        }
                    }
                    .tag(1)
                
                CombinedTimeView()
                    .tabItem {
                        Label {
                            Text("TimeKeeper")
                        } icon: {
                            Image("stopwatch_icon")
                                .renderingMode(.original)
                                .resizable()
                                .scaledToFit()
                                .frame(width: tabIconSize, height: tabIconSize)
                        }
                    }
                    .tag(2)
            }
            .accentColor(.red)
            .disabled(alarmViewModel.activeAlarm != nil)
            
            // Alarm overlay when active - ONLY shown at root level
            if alarmViewModel.activeAlarm != nil {
                AlarmActiveOverlay()
                    .transition(.opacity)
                    .zIndex(100)
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
    
    // Size for tab icons based on orientation
    private var tabIconSize: CGFloat {
        return isLandscape ? 36 : 28
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
