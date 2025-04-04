import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var alarmViewModel: AlarmViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var refreshTrigger = UUID()

    // Add state for tracking current language
    @State private var currentLanguage: String = LanguageManager.shared.currentLanguage
    
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
                            Text("alarms".localized)
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
                            Text("world_clock".localized)
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
                            Text("timekeeper".localized)
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
        // Add language change notification handler
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LanguageChanged"))) { _ in
            // Update current language
            currentLanguage = LanguageManager.shared.currentLanguage
            // Force view refresh
            refreshTrigger = UUID()

        }
        // Add support for right-to-left languages
        .environment(\.layoutDirection, currentLanguage == "ar" ? .rightToLeft : .leftToRight)
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
                
                // Alarm name and description - FIXED
                Text(instanceTitle)
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(instanceDescription)
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
                            Text("snooze".localized)
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
                            Text("dismiss".localized)
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
    
    // ADDED: New computed properties for consistent display
    private var instanceTitle: String {
        // Always show the alarm name as the title
        return alarm.name
    }
    
    private var instanceDescription: String {
        // If we have an active instance, use its description
        if let instance = viewModel.activeInstance {
            return instance.description
        }
        return alarm.description
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        
        // For event alarms with active instance, get the time from that instance
        if let activeInstance = viewModel.activeInstance {
            return formatter.string(from: activeInstance.time)
        }
        
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
        // Create userInfo dictionary with both alarm object and ID
        var userInfo: [String: Any] = ["alarm": alarm, "alarmID": alarm.id]
        
        // Add instanceID if available
        if let instance = viewModel.activeInstance {
            userInfo["instanceID"] = instance.id
        }
        
        // Stop audio immediately - THIS IS CRITICAL
        AudioPlayerService.shared.stopAlarmSound()
        
        // Post notification to be handled by AppDelegate
        NotificationCenter.default.post(
            name: NSNotification.Name("SnoozeAlarmRequest"),
            object: nil,
            userInfo: userInfo
        )
        
        // Play haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Clear active alarm and instance
        viewModel.activeAlarm = nil
        viewModel.activeInstance = nil
        
        print("Snooze request sent with alarm ID: \(alarm.id)")
    }
    
    private func dismissAlarm() {
        // Create userInfo dictionary with both alarm object and ID
        var userInfo: [String: Any] = ["alarm": alarm, "alarmID": alarm.id]
        
        // Add instanceID if available
        if let instance = viewModel.activeInstance {
            userInfo["instanceID"] = instance.id
        }
        
        // Stop audio immediately - THIS IS CRITICAL
        AudioPlayerService.shared.stopAlarmSound()
        
        // Post notification to be handled by AppDelegate
        NotificationCenter.default.post(
            name: NSNotification.Name("DismissAlarmRequest"),
            object: nil,
            userInfo: userInfo
        )
        
        // Play haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        
        // Clear active alarm and instance
        viewModel.activeAlarm = nil
        viewModel.activeInstance = nil
        
        print("Dismiss request sent with alarm ID: \(alarm.id)")
    }
}
