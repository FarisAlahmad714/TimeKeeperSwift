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

struct AlarmActiveView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var backgroundEntryTime: Date?
    @State private var pulseAnimation = false
    @State private var shakeAnimation = false
    
    let alarm: Alarm
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Alarm header with time
                Text(formattedTime)
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Alarm name and description
                Text(alarm.name)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(alarm.description)
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Animation elements
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.red.opacity(0.7), Color.red.opacity(0)]),
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .opacity(0.8)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                        .onAppear {
                            pulseAnimation = true
                        }
                    
                    Image(systemName: "alarm.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .rotationEffect(Angle(degrees: shakeAnimation ? 10 : -10))
                        .animation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: shakeAnimation)
                        .onAppear {
                            shakeAnimation = true
                        }
                }
                .padding(.vertical, 30)
                
                // Action buttons
                HStack(spacing: 30) {
                    Button(action: snoozeAlarm) {
                        VStack {
                            Image(systemName: "bed.double.fill")
                                .font(.system(size: 30))
                            Text("Snooze")
                                .font(.headline)
                        }
                        .frame(width: 120, height: 80)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                    
                    Button(action: dismissAlarm) {
                        VStack {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 30))
                            Text("Dismiss")
                                .font(.headline)
                        }
                        .frame(width: 120, height: 80)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                    }
                }
                .padding(.top, 20)
            }
            .padding(30)
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                backgroundEntryTime = Date()
            } else if newPhase == .active, let entryTime = backgroundEntryTime {
                let timeInBackground = Date().timeIntervalSince(entryTime)
                if timeInBackground > 5 {
                    // Restart audio playback if app was in background for more than 5 seconds
                    AudioPlayerService.shared.playAlarmSound(for: alarm)
                }
            }
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        // For event alarms, get the time from the appropriate instance
        if let instances = alarm.instances, !instances.isEmpty {
            return formatter.string(from: instances[0].time)
        }
        
        // Fallback to first time in case there's an issue
        if !alarm.times.isEmpty {
            return formatter.string(from: alarm.times[0])
        }
        
        let now = Date()
        return formatter.string(from: now)
    }
    
    private func snoozeAlarm() {
        // Post notification to be handled by AppDelegate
        NotificationCenter.default.post(
            name: NSNotification.Name("SnoozeAlarmRequest"),
            object: nil,
            userInfo: ["alarm": alarm]
        )
        
        // Play haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Clear active alarm
        viewModel.activeAlarm = nil
    }
    
    private func dismissAlarm() {
        // Post notification to be handled by AppDelegate
        NotificationCenter.default.post(
            name: NSNotification.Name("DismissAlarmRequest"),
            object: nil,
            userInfo: ["alarm": alarm]
        )
        
        // Play haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // Clear active alarm
        viewModel.activeAlarm = nil
    }
}
