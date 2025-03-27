//
//  IslandView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

//
//import SwiftUI
//
//struct IslandView: View {
//    @EnvironmentObject var alarmViewModel: AlarmViewModel
//    @EnvironmentObject var stopwatchViewModel: StopwatchViewModel
//    @EnvironmentObject var timerViewModel: TimerViewModel
//    @EnvironmentObject var worldClockViewModel: WorldClockViewModel
//    @EnvironmentObject var spaceshipViewModel: SpaceshipViewModel
//    
//    @State private var isExpanded = false
//    @State private var currentTabIndex = 0
//    @State private var showControls = false
//    @State private var dragOffset: CGSize = .zero
//    @State private var animationPhase: Double = 0
//    
//    // Get the current active tab index from the TabView
//    func updateCurrentTab(_ index: Int) {
//        currentTabIndex = index
//        // Trigger a small visual feedback when switching tabs
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
//            dragOffset = CGSize(width: 5, height: 0)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                withAnimation(.spring()) {
//                    dragOffset = .zero
//                }
//            }
//        }
//    }
//    
//    var body: some View {
//        VStack {
//            // Dynamic Island
//            ZStack {
//                // Base capsule shape
//                Capsule()
//                    .fill(
//                        LinearGradient(
//                            gradient: Gradient(colors: [Color.black.opacity(0.8), Color.black]),
//                            startPoint: .top,
//                            endPoint: .bottom
//                        )
//                    )
//                    .frame(width: isExpanded ? 350 : 120, height: isExpanded ? 180 : 36)
//                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
//                    .overlay(
//                        Capsule()
//                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
//                    )
//                    .scaleEffect(showControls ? 1.02 : 1.0)
//                    .offset(dragOffset)
//                
//                // Clock display in island when not expanded
//                if !isExpanded {
//                    CollapsedIslandContent(currentTab: currentTabIndex)
//                } else {
//                    ExpandedIslandContent(
//                        currentTab: currentTabIndex,
//                        alarmVM: alarmViewModel,
//                        stopwatchVM: stopwatchViewModel,
//                        timerVM: timerViewModel,
//                        worldClockVM: worldClockViewModel,
//                        showControls: $showControls
//                    )
//                }
//                
//                // Visual cue for draggability
//                if isExpanded {
//                    RoundedRectangle(cornerRadius: 2)
//                        .fill(Color.gray.opacity(0.5))
//                        .frame(width: 36, height: 4)
//                        .offset(y: -74)
//                }
//                
//                // Glowing effects around the edges when active
//                if showControls {
//                    Capsule()
//                        .stroke(
//                            LinearGradient(
//                                gradient: Gradient(colors: [Color.red.opacity(0.4), Color.orange.opacity(0.3)]),
//                                startPoint: .leading,
//                                endPoint: .trailing
//                            ),
//                            lineWidth: 2
//                        )
//                        .frame(width: isExpanded ? 352 : 122, height: isExpanded ? 182 : 38)
//                        .blur(radius: 2)
//                }
//            }
//            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
//            .animation(.easeInOut, value: showControls)
//            .onTapGesture {
//                isExpanded.toggle()
//                
//                // When expanding, show controls after a brief delay
//                if isExpanded {
//                    withAnimation(.easeIn.delay(0.2)) {
//                        showControls = true
//                    }
//                } else {
//                    withAnimation {
//                        showControls = false
//                    }
//                }
//                
//                // Trigger haptic feedback
//                let generator = UIImpactFeedbackGenerator(style: .medium)
//                generator.impactOccurred()
//            }
//            .gesture(
//                DragGesture()
//                    .onChanged { value in
//                        // Only allow vertical drag when expanded
//                        if isExpanded {
//                            dragOffset = CGSize(width: 0, height: value.translation.height * 0.2)
//                            
//                            // If dragged down enough, collapse
//                            if value.translation.height > 70 {
//                                isExpanded = false
//                                showControls = false
//                                dragOffset = .zero
//                            }
//                        }
//                    }
//                    .onEnded { _ in
//                        withAnimation(.spring()) {
//                            dragOffset = .zero
//                        }
//                    }
//            )
//            .onAppear {
//                // Start subtle animation
//                withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
//                    animationPhase = 1.0
//                }
//            }
//        }
//    }
//}
//
//struct CollapsedIslandContent: View {
//    let currentTab: Int
//    @State private var currentTime = Date()
//    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
//    
//    var body: some View {
//        HStack(spacing: 12) {
//            // Show content based on current tab
//            switch currentTab {
//            case 0: // Alarms tab
//                Image(systemName: "alarm.fill")
//                    .foregroundColor(.red)
//                timeText
//            case 1: // World Clock tab
//                Image(systemName: "globe")
//                    .foregroundColor(.blue)
//                timeText
//            case 2: // Stopwatch tab
//                Image(systemName: "stopwatch.fill")
//                    .foregroundColor(.green)
//                timeText
//            case 3: // Timer tab
//                Image(systemName: "timer")
//                    .foregroundColor(.orange)
//                timeText
//            default:
//                timeText
//            }
//        }
//        .onReceive(timer) { _ in
//            currentTime = Date()
//        }
//    }
//    
//    var timeText: some View {
//        Text(timeString)
//            .font(.system(size: 12, weight: .semibold, design: .rounded))
//            .foregroundColor(.white)
//    }
//    
//    var timeString: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss"
//        return formatter.string(from: currentTime)
//    }
//}
//
//struct ExpandedIslandContent: View {
//    let currentTab: Int
//    let alarmVM: AlarmViewModel
//    let stopwatchVM: StopwatchViewModel
//    let timerVM: TimerViewModel
//    let worldClockVM: WorldClockViewModel
//    @Binding var showControls: Bool
//    
//    var body: some View {
//        VStack(spacing: 8) {
//            // Header based on current tab
//            Text(headerTitle)
//                .font(.system(size: 16, weight: .bold, design: .rounded))
//                .foregroundColor(.white)
//            
//            // Tab-specific content
//            switch currentTab {
//            case 0: // Alarms tab
//                AlarmIslandContent(alarmVM: alarmVM)
//            case 1: // World Clock tab
//                WorldClockIslandContent(worldClockVM: worldClockVM)
//            case 2: // Stopwatch tab
//                StopwatchIslandContent(stopwatchVM: stopwatchVM)
//            case 3: // Timer tab
//                TimerIslandContent(timerVM: timerVM)
//            default:
//                Text("TimeKeeper")
//                    .foregroundColor(.white.opacity(0.8))
//            }
//            
//            // Quick action buttons
//            HStack(spacing: 20) {
//                quickActionButton(for: currentTab)
//            }
//            .padding(.top, 4)
//        }
//        .padding(.horizontal)
//        .padding(.vertical, 12)
//    }
//    
//    var headerTitle: String {
//        switch currentTab {
//        case 0: return "Alarms"
//        case 1: return "World Clock"
//        case 2: return "Stopwatch"
//        case 3: return "Timer"
//        default: return "TimeKeeper"
//        }
//    }
//    
//    @ViewBuilder
//    func quickActionButton(for tab: Int) -> some View {
//        switch tab {
//        case 0: // Alarms tab
//            Button(action: {
//                alarmVM.activeModal = .choice
//            }) {
//                HStack {
//                    Image(systemName: "plus.circle.fill")
//                    Text("Add Alarm")
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 6)
//                .background(
//                    Capsule()
//                        .fill(Color.red.opacity(0.2))
//                )
//                .foregroundColor(.red)
//            }
//            .buttonStyle(PlainButtonStyle())
//            
//        case 1: // World Clock tab
//            Button(action: {
//                worldClockVM.showAddClockModal = true
//            }) {
//                HStack {
//                    Image(systemName: "plus.circle.fill")
//                    Text("Add Clock")
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 6)
//                .background(
//                    Capsule()
//                        .fill(Color.blue.opacity(0.2))
//                )
//                .foregroundColor(.blue)
//            }
//            .buttonStyle(PlainButtonStyle())
//            
//        case 2: // Stopwatch tab
//            Button(action: {
//                stopwatchVM.isRunning ? stopwatchVM.startOrPause() : stopwatchVM.startOrPause()
//            }) {
//                HStack {
//                    Image(systemName: stopwatchVM.isRunning ? "pause.circle.fill" : "play.circle.fill")
//                    Text(stopwatchVM.isRunning ? "Pause" : "Start")
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 6)
//                .background(
//                    Capsule()
//                        .fill(Color.green.opacity(0.2))
//                )
//                .foregroundColor(.green)
//            }
//            .buttonStyle(PlainButtonStyle())
//            
//        case 3: // Timer tab
//            Button(action: {
//                timerVM.isRunning ? timerVM.stopTimer() : timerVM.startTimer()
//            }) {
//                HStack {
//                    Image(systemName: timerVM.isRunning ? "stop.circle.fill" : "play.circle.fill")
//                    Text(timerVM.isRunning ? "Stop" : "Start")
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 6)
//                .background(
//                    Capsule()
//                        .fill(Color.orange.opacity(0.2))
//                )
//                .foregroundColor(.orange)
//            }
//            .buttonStyle(PlainButtonStyle())
//            .disabled(!timerVM.isRunning && timerVM.hours == 0 && timerVM.minutes == 0 && timerVM.seconds == 0)
//            .opacity(!timerVM.isRunning && timerVM.hours == 0 && timerVM.minutes == 0 && timerVM.seconds == 0 ? 0.5 : 1.0)
//            
//        default:
//            EmptyView()
//        }
//    }
//}
//
//// Tab-specific content views
//struct AlarmIslandContent: View {
//    let alarmVM: AlarmViewModel
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            if let nextAlarm = getNextAlarm() {
//                Text("Next Alarm")
//                    .font(.system(size: 12, weight: .medium))
//                    .foregroundColor(.gray)
//                
//                HStack {
//                    Image(systemName: "alarm.fill")
//                        .foregroundColor(.red)
//                    
//                    Text(formatAlarmTime(nextAlarm))
//                        .foregroundColor(.white)
//                        .font(.system(size: 14, weight: .semibold))
//                    
//                    if let instance = nextAlarm.instances?.first {
//                        Text(getRepeatText(instance.repeatInterval))
//                            .font(.system(size: 10))
//                            .foregroundColor(.gray)
//                    }
//                }
//            } else {
//                Text("No upcoming alarms")
//                    .font(.system(size: 14))
//                    .foregroundColor(.gray)
//            }
//            
//            Text("\(alarmVM.alarms.filter { $0.status }.count) active alarms")
//                .font(.system(size: 12))
//                .foregroundColor(.gray)
//        }
//    }
//    
//    private func getNextAlarm() -> Alarm? {
//        let now = Date()
//        let calendar = Calendar.current
//        
//        // Filter active alarms and find the next one to trigger
//        let activeAlarms = alarmVM.alarms.filter { $0.status }
//        
//        // Find the next alarm to trigger
//        var nextAlarm: (alarm: Alarm, date: Date)? = nil
//        
//        for alarm in activeAlarms {
//            if let instances = alarm.instances {
//                for instance in instances {
//                    // Combine date and time into a single Date
//                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: instance.date)
//                    let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: instance.time)
//                    
//                    var combinedComponents = DateComponents()
//                    combinedComponents.year = dateComponents.year
//                    combinedComponents.month = dateComponents.month
//                    combinedComponents.day = dateComponents.day
//                    combinedComponents.hour = timeComponents.hour
//                    combinedComponents.minute = timeComponents.minute
//                    combinedComponents.second = timeComponents.second ?? 0
//                    
//                    if let alarmDate = calendar.date(from: combinedComponents) {
//                        if alarmDate > now {
//                            if nextAlarm == nil || alarmDate < nextAlarm!.date {
//                                nextAlarm = (alarm, alarmDate)
//                            }
//                        } else if instance.repeatInterval != .none {
//                            // For repeating alarms, find the next occurrence
//                            var nextOccurrence: Date?
//                            
//                            switch instance.repeatInterval {
//                            case .daily:
//                                nextOccurrence = calendar.date(byAdding: .day, value: 1, to: alarmDate)
//                            case .weekly:
//                                nextOccurrence = calendar.date(byAdding: .weekOfYear, value: 1, to: alarmDate)
//                            case .hourly:
//                                nextOccurrence = calendar.date(byAdding: .hour, value: 1, to: alarmDate)
//                            case .minutely:
//                                nextOccurrence = calendar.date(byAdding: .minute, value: 1, to: alarmDate)
//                            case .none:
//                                break
//                            }
//                            
//                            if let nextOccurrence = nextOccurrence, nextAlarm == nil || nextOccurrence < nextAlarm!.date {
//                                nextAlarm = (alarm, nextOccurrence)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        return nextAlarm?.alarm
//    }
//    
//    private func formatAlarmTime(_ alarm: Alarm) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "h:mm a"
//        
//        if let time = alarm.times.first {
//            return formatter.string(from: time)
//        }
//        
//        return "--:--"
//    }
//    
//    private func getRepeatText(_ repeatInterval: RepeatInterval) -> String {
//        switch repeatInterval {
//        case .daily: return "Daily"
//        case .weekly: return "Weekly"
//        case .hourly: return "Hourly"
//        case .minutely: return "Every minute"
//        case .none: return "Once"
//        }
//    }
//}
//
//struct WorldClockIslandContent: View {
//    let worldClockVM: WorldClockViewModel
//    
//    var body: some View {
//        if worldClockVM.clocks.isEmpty {
//            Text("No world clocks added")
//                .font(.system(size: 14))
//                .foregroundColor(.gray)
//        } else {
//            VStack(alignment: .leading, spacing: 6) {
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(worldClockVM.clocks.prefix(3)) { clock in
//                            VStack(alignment: .leading, spacing: 2) {
//                                Text(cityName(from: clock.timezone))
//                                    .font(.system(size: 12, weight: .medium))
//                                    .foregroundColor(.white)
//                                    .lineLimit(1)
//                                
//                                Text(worldClockVM.timeForTimezone(clock.timezone))
//                                    .font(.system(size: 10, weight: .regular, design: .monospaced))
//                                    .foregroundColor(.gray)
//                            }
//                            .padding(.vertical, 4)
//                            .padding(.horizontal, 8)
//                            .background(
//                                RoundedRectangle(cornerRadius: 6)
//                                    .fill(Color.blue.opacity(0.1))
//                            )
//                        }
//                    }
//                }
//                
//                Text("\(worldClockVM.clocks.count) clocks • Tap to view all")
//                    .font(.system(size: 10))
//                    .foregroundColor(.gray)
//            }
//        }
//    }
//    
//    private func cityName(from timezone: String) -> String {
//        let components = timezone.split(separator: "/")
//        return components.last?.replacingOccurrences(of: "_", with: " ") ?? timezone
//    }
//}
//
//struct StopwatchIslandContent: View {
//    let stopwatchVM: StopwatchViewModel
//    
//    var body: some View {
//        VStack(spacing: 4) {
//            Text(stopwatchVM.formattedTime)
//                .font(.system(size: 18, weight: .bold, design: .monospaced))
//                .foregroundColor(.white)
//            
//            HStack(spacing: 16) {
//                // Lap count
//                Text("\(stopwatchVM.laps.count) laps")
//                    .font(.system(size: 12))
//                    .foregroundColor(.gray)
//                
//                // Status indicator
//                HStack(spacing: 4) {
//                    Circle()
//                        .fill(stopwatchVM.isRunning ? Color.green : Color.red)
//                        .frame(width: 6, height: 6)
//                    
//                    Text(stopwatchVM.isRunning ? "Running" : "Stopped")
//                        .font(.system(size: 12))
//                        .foregroundColor(stopwatchVM.isRunning ? .green : .red)
//                }
//            }
//        }
//    }
//}
//
//struct TimerIslandContent: View {
//    let timerVM: TimerViewModel
//    
//    var body: some View {
//        VStack(spacing: 4) {
//            if timerVM.isRunning {
//                // Running timer display
//                Text(timerVM.formattedTime(timerVM.remainingTime))
//                    .font(.system(size: 18, weight: .bold, design: .monospaced))
//                    .foregroundColor(.white)
//                
//                // Progress bar
//                ProgressView(value: timerVM.remainingTime, total: timerVM.initialDuration)
//                    .progressViewStyle(LinearProgressViewStyle(tint: Color.orange))
//                    .frame(height: 4)
//                
//                if !timerVM.label.isEmpty {
//                    Text(timerVM.label)
//                        .font(.system(size: 12))
//                        .foregroundColor(.gray)
//                }
//            } else {
//                // Setup timer display
//                Text(timerVM.formattedTime(TimeInterval(timerVM.hours * 3600 + timerVM.minutes * 60 + timerVM.seconds)))
//                    .font(.system(size: 18, weight: .bold, design: .monospaced))
//                    .foregroundColor(.white)
//                
//                Text(timerVM.hours == 0 && timerVM.minutes == 0 && timerVM.seconds == 0 ? "Set a timer" : "Timer ready")
//                    .font(.system(size: 12))
//                    .foregroundColor(.gray)
//            }
//        }
//    }
//}
//
//struct IslandView_Previews: PreviewProvider {
//    static var previews: some View {
//        ZStack {
//            Color.gray.opacity(0.2).edgesIgnoringSafeArea(.all)
//            
//            VStack {
//                IslandView()
//                    .padding(.top, 20)
//                
//                Spacer()
//            }
//        }
//        .environmentObject(AlarmViewModel())
//        .environmentObject(StopwatchViewModel())
//        .environmentObject(TimerViewModel())
//        .environmentObject(WorldClockViewModel())
//        .environmentObject(SpaceshipViewModel())
//    }
//}
