import SwiftUI
import FirebaseAnalytics

struct CombinedTimeView: View {
    @EnvironmentObject var stopwatchViewModel: StopwatchViewModel
    @EnvironmentObject var timerViewModel: TimerViewModel
    @State private var selectedMode: TimeMode = .timer

    enum TimeMode {
        case timer
        case stopwatch
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Dark theme background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Modernized title
                    Text(selectedMode == .stopwatch ? "Stopwatch" : "Timer")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Redesigned picker
                    Picker("Mode", selection: $selectedMode) {
                        Text("Timer").tag(TimeMode.timer)
                        Text("Stopwatch").tag(TimeMode.stopwatch)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.15, green: 0.15, blue: 0.2), Color(red: 0.1, green: 0.1, blue: 0.15)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .cornerRadius(10)
                    )
                    .foregroundColor(.white)
                    .onChange(of: selectedMode) { oldValue, newValue in
                        Analytics.logEvent("CombinedTime_mode_switched", parameters: [
                            "new_mode": newValue == .timer ? "timer" : "stopwatch",
                            "old_mode": oldValue == .timer ? "timer" : "stopwatch"
                        ])
                    }
                    
                    // Content based on mode
                    if selectedMode == .timer {
                        TimerContent()
                    } else {
                        StopwatchContent()
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                    AnalyticsParameterScreenName: "Combined Time",
                    AnalyticsParameterScreenClass: "CombinedTimeView"
                ])
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct StopwatchContent: View {
    @EnvironmentObject var viewModel: StopwatchViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Original stopwatch circle (unchanged)
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.3)]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 100
                )
                .overlay(
                    Canvas { context, size in
                        for _ in 0...50 {
                            let x = CGFloat.random(in: 0...size.width)
                            let y = CGFloat.random(in: 0...size.height)
                            let star = CGRect(x: x, y: y, width: 2, height: 2)
                            context.fill(Path(ellipseIn: star), with: .color(.white))
                        }
                    }
                )
                .clipShape(Circle())
                .frame(width: 200, height: 200)
                
                Circle()
                    .stroke(Color.gray.opacity(0.5), lineWidth: 4)
                    .frame(width: 200, height: 200)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(Double(Date().timeIntervalSince1970) * 0.1))
                    )
                
                ForEach(0..<60) { second in
                    let angle = Double(second) * 6 - 90
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 2, height: second % 5 == 0 ? 10 : 5)
                        .offset(y: -90)
                        .rotationEffect(.degrees(angle))
                }
                
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.cyan, Color.white.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 2, height: 90)
                    .offset(y: -45)
                    .rotationEffect(.degrees(viewModel.secondsAngle))
                
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.cyan, Color.white.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 2, height: 70)
                    .offset(y: -35)
                    .rotationEffect(.degrees(viewModel.minutesAngle))
                
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.cyan, Color.white.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(width: 2, height: 50)
                    .offset(y: -25)
                    .rotationEffect(.degrees(viewModel.hoursAngle))
                
                Circle()
                    .fill(Color.purple)
                    .frame(width: 10, height: 10)
            }
            .padding()
            
            // Redesigned time display
            Text(viewModel.formattedTime)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            
            // Redesigned buttons
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.startOrPause()
                    Analytics.logEvent("CombinedTime_stopwatch_start_pause_tapped", parameters: [
                        "action": viewModel.isRunning ? "pause" : "start",
                        "current_time": viewModel.formattedTime
                    ])
                }) {
                    Text(viewModel.isRunning ? "Pause" : "Start")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.3), radius: 5, x: 0, y: 3)
                }
                
                Button(action: {
                    if viewModel.isRunning {
                        let lapCountBefore = viewModel.laps.count
                        viewModel.addLap()
                        let lapCountAfter = viewModel.laps.count
                        if lapCountAfter > lapCountBefore {
                            if let lastLap = viewModel.laps.last {
                                Analytics.logEvent("CombinedTime_stopwatch_lap_added", parameters: [
                                    "lap_id": lastLap.id,
                                    "lap_time": lastLap.time,
                                    "total_laps": viewModel.laps.count
                                ])
                            }
                        }
                    } else {
                        viewModel.reset()
                        Analytics.logEvent("CombinedTime_stopwatch_reset_tapped", parameters: [
                            "total_laps": viewModel.laps.count
                        ])
                    }
                }) {
                    Text(viewModel.isRunning ? "Lap" : "Reset")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .disabled(!viewModel.isRunning && viewModel.formattedTime == "00:00:00.00")
                .opacity(!viewModel.isRunning && viewModel.formattedTime == "00:00:00.00" ? 0.5 : 1.0)
            }
            .padding(.horizontal)
            
            // Redesigned lap list
            if viewModel.laps.isEmpty {
                Text("No laps recorded")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.laps) { lap in
                            HStack {
                                Text("Lap \(lap.id)")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                Spacer()
                                Text(lap.time)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                            .cornerRadius(15)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
            }
        }
    }
}

struct TimerContent: View {
    @EnvironmentObject var viewModel: TimerViewModel
    @State private var sandProgress: CGFloat = 1.0
    @State private var isFlipped: Bool = false
    @State private var rotationDegrees: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Original hourglass (unchanged)
            VStack {
                ZStack {
                    HourglassView(sandProgress: sandProgress, isFlipped: isFlipped)
                        .frame(width: 140, height: 210)
                        .rotationEffect(.degrees(rotationDegrees))
                    
                    Text(viewModel.formattedTime(viewModel.isRunning ? viewModel.remainingTime : TimeInterval(viewModel.hours * 3600 + viewModel.minutes * 60 + viewModel.seconds)))
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        .padding(5)
                }
                .frame(height: 250)
                .background(Color.black.opacity(0.8))
                .cornerRadius(15)
                .padding(.horizontal, 20)
            }
            .onAppear { resetHourglass() }
            .onChange(of: viewModel.isRunning) { oldValue, newValue in
                if newValue {
                    startHourglassAnimation()
                } else if oldValue && viewModel.remainingTime <= 0 {
                    resetHourglass()
                }
            }
            .onChange(of: viewModel.remainingTime) { oldValue, newValue in
                if viewModel.isRunning && viewModel.initialDuration > 0 {
                    withAnimation(.linear(duration: 0.3)) {
                        sandProgress = max(0, newValue / viewModel.initialDuration)
                    }
                    if newValue <= 0 && oldValue > 0 {
                        resetHourglass()
                    }
                }
            }
            
            // Redesigned scrollable content
            ScrollView {
                VStack(spacing: 20) {
                    // Timer history
                    if !viewModel.timerHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("History")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 10)
                            
                            ForEach(viewModel.timerHistory) { item in
                                HStack {
                                    Text(item.label)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(item.title)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundColor(.gray)
                                    Button(action: {
                                        if let index = viewModel.timerHistory.firstIndex(where: { $0.id == item.id }) {
                                            viewModel.timerHistory.remove(at: index)
                                            viewModel.saveHistory()
                                            Analytics.logEvent("CombinedTime_timer_history_deleted", parameters: [
                                                "history_id": item.id,
                                                "label": item.label,
                                                "duration": item.title
                                            ])
                                        }
                                    }) {
                                        Image(systemName: "trash.fill")
                                            .foregroundColor(Color(red: 0.9, green: 0.2, blue: 0.3))
                                            .padding(10)
                                            .background(Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.1))
                                            .clipShape(Circle())
                                    }
                                }
                                .padding()
                                .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Input controls
                    if !viewModel.isRunning {
                        VStack(spacing: 15) {
                            TextField("Label", text: $viewModel.label)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                .cornerRadius(15)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 15)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            
                            HStack(spacing: 10) {
                                Picker("Hours", selection: $viewModel.hours) {
                                    ForEach(0..<24) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                                .clipped()
                                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                .cornerRadius(15)
                                
                                Picker("Minutes", selection: $viewModel.minutes) {
                                    ForEach(0..<60) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                                .clipped()
                                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                .cornerRadius(15)
                                
                                Picker("Seconds", selection: $viewModel.seconds) {
                                    ForEach(0..<60) { Text("\($0)").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100)
                                .clipped()
                                .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            
            // Redesigned buttons
            HStack(spacing: 20) {
                Button(action: {
                    if viewModel.isRunning {
                        viewModel.stopTimer()
                        Analytics.logEvent("CombinedTime_timer_stop_tapped", parameters: [
                            "label": viewModel.label,
                            "remaining_time": viewModel.remainingTime
                        ])
                    } else {
                        viewModel.startTimer()
                        let totalDuration = TimeInterval(viewModel.hours * 3600 + viewModel.minutes * 60 + viewModel.seconds)
                        Analytics.logEvent("CombinedTime_timer_start_tapped", parameters: [
                            "label": viewModel.label,
                            "duration": totalDuration
                        ])
                    }
                }) {
                    Text(viewModel.isRunning ? "Stop" : "Start")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .disabled(!viewModel.isRunning && viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0)
                .opacity(!viewModel.isRunning && viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0 ? 0.5 : 1.0)
                
                Button(action: {
                    viewModel.resetTimer()
                    resetHourglass()
                    Analytics.logEvent("CombinedTime_timer_reset_tapped", parameters: [
                        "label": viewModel.label
                    ])
                }) {
                    Text("Reset")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.9, green: 0.2, blue: 0.3), Color(red: 1.0, green: 0.4, blue: 0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .disabled(viewModel.isRunning || (viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0))
                .opacity(viewModel.isRunning || (viewModel.hours == 0 && viewModel.minutes == 0 && viewModel.seconds == 0) ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    private func startHourglassAnimation() {
        withAnimation(.spring()) {
            rotationDegrees = 180
            isFlipped = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            sandProgress = 1.0
            withAnimation(.linear(duration: 0.3)) {
                sandProgress = viewModel.remainingTime / viewModel.initialDuration
            }
        }
    }
    
    private func resetHourglass() {
        withAnimation(.spring()) {
            rotationDegrees = 0
            isFlipped = false
            sandProgress = 1.0
        }
    }
}

// Original HourglassView (unchanged)
struct HourglassView: View {
    let sandProgress: CGFloat
    let isFlipped: Bool
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let middle = height / 2
            
            drawHourglassBackground(context: context, size: size)
            
            if !isFlipped {
                drawBottomChamberSand(context: context, size: size, fillRatio: 1.0, isFilling: true)
            } else {
                if sandProgress > 0 {
                    drawBottomChamberSand(context: context, size: size, fillRatio: sandProgress, isFilling: false)
                }
                drawTopChamberSand(context: context, size: size, fillRatio: 1.0 - sandProgress, isFilling: true)
                if sandProgress > 0 && sandProgress < 1.0 {
                    drawFallingSand(context: context, size: size)
                }
            }
            
            drawHourglassFrame(context: context, size: size)
        }
    }
    
    private func drawHourglassBackground(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        
        let hourglassPath = createHourglassPath(size: size)
        let blueGradient = Gradient(colors: [
            Color(red: 0.05, green: 0.1, blue: 0.5),
            Color(red: 0.1, green: 0.2, blue: 0.6)
        ])
        
        context.fill(hourglassPath, with: .linearGradient(
            blueGradient,
            startPoint: CGPoint(x: width / 2, y: 0),
            endPoint: CGPoint(x: width / 2, y: height)
        ))
        
        for _ in 0..<40 {
            let x = CGFloat.random(in: 0..<width)
            let y = CGFloat.random(in: 0..<height)
            if hourglassPath.contains(CGPoint(x: x, y: y)) {
                let starSize = CGFloat.random(in: 1...2.5)
                let opacity = CGFloat.random(in: 0.5...1.0)
                context.fill(
                    Path(ellipseIn: CGRect(x: x - starSize/2, y: y - starSize/2, width: starSize, height: starSize)),
                    with: .color(Color.white.opacity(opacity))
                )
            }
        }
    }
    
    private func drawHourglassFrame(context: GraphicsContext, size: CGSize) {
        let hourglassPath = createHourglassPath(size: size)
        let frameGradient = Gradient(colors: [
            Color.white.opacity(0.9),
            Color.gray.opacity(0.6)
        ])
        
        context.stroke(hourglassPath, with: .linearGradient(
            frameGradient,
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: size.width, y: size.height)
        ), lineWidth: 10)
        context.stroke(hourglassPath, with: .color(Color.black.opacity(0.2)), lineWidth: 2)
    }
    
    private func drawTopChamberSand(context: GraphicsContext, size: CGSize, fillRatio: CGFloat, isFilling: Bool) {
        let width = size.width
        let height = size.height
        let middle = height / 2
        if fillRatio <= 0 { return }
        
        let topBottomWidth = width * 0.7
        let neckWidth = width * 0.03
        let maxSandHeight = middle
        let sandHeight = maxSandHeight * fillRatio
        let sandTopY = sandHeight
        
        var sandPath = Path()
        if isFilling {
            sandPath.move(to: CGPoint(x: (width - topBottomWidth) / 2, y: 0))
            sandPath.addLine(to: CGPoint(x: (width + topBottomWidth) / 2, y: 0))
            let rightSideX = (width + topBottomWidth) / 2 - (sandHeight / maxSandHeight) * ((width + topBottomWidth) / 2 - (width / 2 + neckWidth / 2))
            sandPath.addCurve(
                to: CGPoint(x: rightSideX, y: sandTopY),
                control1: CGPoint(x: (width + topBottomWidth) / 2, y: sandHeight * 0.4),
                control2: CGPoint(x: width / 2 + neckWidth * 2, y: sandHeight * 0.8)
            )
            let peakHeight = min(10.0, sandHeight * 0.3)
            sandPath.addQuadCurve(
                to: CGPoint(x: width / 2 - (rightSideX - width / 2), y: sandTopY),
                control: CGPoint(x: width / 2, y: sandTopY - peakHeight)
            )
            let leftSideX = (width - topBottomWidth) / 2 + (sandHeight / maxSandHeight) * ((width / 2 - neckWidth / 2) - (width - topBottomWidth) / 2)
            sandPath.addCurve(
                to: CGPoint(x: (width - topBottomWidth) / 2, y: 0),
                control1: CGPoint(x: width / 2 - neckWidth * 2, y: sandHeight * 0.8),
                control2: CGPoint(x: (width - topBottomWidth) / 2, y: sandHeight * 0.4)
            )
        }
        
        let sandGradient = Gradient(colors: [
            Color(red: 0.98, green: 0.9, blue: 0.4),
            Color(red: 0.95, green: 0.85, blue: 0.5)
        ])
        context.fill(sandPath, with: .linearGradient(
            sandGradient,
            startPoint: CGPoint(x: width / 2, y: 0),
            endPoint: CGPoint(x: width / 2, y: middle)
        ))
        addSandTexture(context: context, in: sandPath, size: size, count: Int(30 * fillRatio))
    }
    
    private func drawBottomChamberSand(context: GraphicsContext, size: CGSize, fillRatio: CGFloat, isFilling: Bool) {
        let width = size.width
        let height = size.height
        let middle = height / 2
        if fillRatio <= 0 { return }
        
        let bottomWidth = width * 0.65
        let neckWidth = width * 0.03
        
        if fillRatio >= 0.99 && isFilling {
            var fullPath = Path()
            fullPath.move(to: CGPoint(x: width / 2 - neckWidth / 2, y: middle))
            fullPath.addLine(to: CGPoint(x: width / 2 + neckWidth / 2, y: middle))
            fullPath.addCurve(
                to: CGPoint(x: (width + bottomWidth) / 2, y: height),
                control1: CGPoint(x: width / 2 + neckWidth * 2, y: middle * 1.2),
                control2: CGPoint(x: (width + bottomWidth) / 2 - bottomWidth * 0.1, y: height * 0.8)
            )
            fullPath.addLine(to: CGPoint(x: (width - bottomWidth) / 2, y: height))
            fullPath.addCurve(
                to: CGPoint(x: width / 2 - neckWidth / 2, y: middle),
                control1: CGPoint(x: (width - bottomWidth) / 2 + bottomWidth * 0.1, y: height * 0.8),
                control2: CGPoint(x: width / 2 - neckWidth * 2, y: middle * 1.2)
            )
            fullPath.closeSubpath()
            
            let sandGradient = Gradient(colors: [
                Color(red: 0.98, green: 0.9, blue: 0.4),
                Color(red: 0.95, green: 0.85, blue: 0.5)
            ])
            context.fill(fullPath, with: .linearGradient(
                sandGradient,
                startPoint: CGPoint(x: width / 2, y: middle),
                endPoint: CGPoint(x: width / 2, y: height)
            ))
            addSandTexture(context: context, in: fullPath, size: size, count: 40)
            return
        }
        
        let maxSandHeight = height - middle
        let sandHeight = maxSandHeight * fillRatio
        let sandBottomY = middle + sandHeight
        
        var sandPath = Path()
        sandPath.move(to: CGPoint(x: width / 2 - neckWidth / 2, y: middle))
        sandPath.addLine(to: CGPoint(x: width / 2 + neckWidth / 2, y: middle))
        let rightWidthAtBottom = neckWidth + (bottomWidth - neckWidth) * (sandHeight / maxSandHeight)
        let rightSideXAtBottom = width / 2 + rightWidthAtBottom / 2
        
        sandPath.addCurve(
            to: CGPoint(x: rightSideXAtBottom, y: sandBottomY),
            control1: CGPoint(x: width / 2 + neckWidth * 1.5, y: middle + sandHeight * 0.3),
            control2: CGPoint(x: rightSideXAtBottom - rightWidthAtBottom * 0.2, y: sandBottomY - sandHeight * 0.1)
        )
        
        if isFilling {
            let peakHeight = min(10.0, sandHeight * 0.3)
            sandPath.addQuadCurve(
                to: CGPoint(x: width / 2 - rightWidthAtBottom / 2, y: sandBottomY),
                control: CGPoint(x: width / 2, y: sandBottomY - peakHeight)
            )
        } else {
            let funnelDepth = min(15.0, 10 + fillRatio * 20)
            sandPath.addQuadCurve(
                to: CGPoint(x: width / 2 - rightWidthAtBottom / 2, y: sandBottomY),
                control: CGPoint(x: width / 2, y: sandBottomY + funnelDepth)
            )
        }
        
        sandPath.addCurve(
            to: CGPoint(x: width / 2 - neckWidth / 2, y: middle),
            control1: CGPoint(x: width / 2 - rightWidthAtBottom / 2 + rightWidthAtBottom * 0.2, y: sandBottomY - sandHeight * 0.1),
            control2: CGPoint(x: width / 2 - neckWidth * 1.5, y: middle + sandHeight * 0.3)
        )
        sandPath.closeSubpath()
        
        let sandGradient = Gradient(colors: [
            Color(red: 0.98, green: 0.9, blue: 0.5),
            Color(red: 0.95, green: 0.85, blue: 0.4)
        ])
        context.fill(sandPath, with: .linearGradient(
            sandGradient,
            startPoint: CGPoint(x: width / 2, y: middle),
            endPoint: CGPoint(x: width / 2, y: sandBottomY)
        ))
        addSandTexture(context: context, in: sandPath, size: size, count: Int(30 * fillRatio))
    }
    
    private func drawFallingSand(context: GraphicsContext, size: CGSize) {
        let width = size.width
        let height = size.height
        let middle = height / 2
        let streamWidth = width * 0.015
        context.fill(
            Path(ellipseIn: CGRect(
                x: width / 2 - streamWidth / 2,
                y: middle - streamWidth / 2,
                width: streamWidth,
                height: streamWidth
            )),
            with: .color(Color(red: 0.95, green: 0.85, blue: 0.5))
        )
        
        let sandColor = Color(red: 0.95, green: 0.85, blue: 0.5)
        for i in 0...8 {
            let yOffset = CGFloat(i) * 1.0
            let xVariation = CGFloat.random(in: -0.5...0.5)
            context.fill(
                Path(ellipseIn: CGRect(
                    x: width / 2 - 0.5 + xVariation,
                    y: middle + yOffset,
                    width: 1.0,
                    height: 1.0
                )),
                with: .color(sandColor)
            )
        }
        
        for i in 0..<4 {
            let angle = Double(i) * .pi / 2
            let distance = CGFloat(1.5) + CGFloat(i % 2)
            let xOffset = cos(angle) * distance
            let yOffset = CGFloat(3.0) + sin(angle) * distance + CGFloat(i)
            let size = CGFloat(0.6) + CGFloat(i % 2) * 0.3
            let opacity = CGFloat(0.8) + CGFloat(i % 2) * 0.1
            context.fill(
                Path(ellipseIn: CGRect(
                    x: width / 2 + xOffset - size / 2,
                    y: middle + yOffset - size / 2,
                    width: size,
                    height: size
                )),
                with: .color(sandColor.opacity(opacity))
            )
        }
    }
    
    private func addSandTexture(context: GraphicsContext, in path: Path, size: CGSize, count: Int) {
        for _ in 0..<count {
            let x = CGFloat.random(in: path.boundingRect.minX..<path.boundingRect.maxX)
            let y = CGFloat.random(in: path.boundingRect.minY..<path.boundingRect.maxY)
            if path.contains(CGPoint(x: x, y: y)) {
                let particleSize = CGFloat.random(in: 0.5...1.5)
                let opacity = CGFloat.random(in: 0.05...0.15)
                let isDark = Bool.random()
                let particleColor = isDark ?
                    Color(red: 0.6, green: 0.5, blue: 0.3).opacity(opacity) :
                    Color(red: 1.0, green: 0.95, blue: 0.85).opacity(opacity)
                context.fill(
                    Path(ellipseIn: CGRect(
                        x: x - particleSize / 2,
                        y: y - particleSize / 2,
                        width: particleSize,
                        height: particleSize
                    )),
                    with: .color(particleColor)
                )
            }
        }
    }
    
    private func createHourglassPath(size: CGSize) -> Path {
        let width = size.width
        let height = size.height
        let middle = height / 2
        let lipWidth = width * 0.05
        let topBottomWidth = width * 0.7
        let middleWidth = width * 0.03
        
        var path = Path()
        path.move(to: CGPoint(x: (width - topBottomWidth) / 2 - lipWidth, y: 0))
        path.addLine(to: CGPoint(x: (width + topBottomWidth) / 2 + lipWidth, y: 0))
        path.addCurve(
            to: CGPoint(x: width * 0.5 + middleWidth / 2, y: middle),
            control1: CGPoint(x: (width + topBottomWidth) / 2 + lipWidth, y: middle * 0.3),
            control2: CGPoint(x: (width + middleWidth) / 2, y: middle * 0.7)
        )
        path.addCurve(
            to: CGPoint(x: (width + topBottomWidth) / 2 + lipWidth, y: height),
            control1: CGPoint(x: (width + middleWidth) / 2, y: middle * 1.3),
            control2: CGPoint(x: (width + topBottomWidth) / 2 + lipWidth, y: middle * 1.7)
        )
        path.addLine(to: CGPoint(x: (width - topBottomWidth) / 2 - lipWidth, y: height))
        path.addCurve(
            to: CGPoint(x: width * 0.5 - middleWidth / 2, y: middle),
            control1: CGPoint(x: (width - topBottomWidth) / 2 - lipWidth, y: middle * 1.7),
            control2: CGPoint(x: (width - middleWidth) / 2, y: middle * 1.3)
        )
        path.addCurve(
            to: CGPoint(x: (width - topBottomWidth) / 2 - lipWidth, y: 0),
            control1: CGPoint(x: (width - middleWidth) / 2, y: middle * 0.7),
            control2: CGPoint(x: (width - topBottomWidth) / 2 - lipWidth, y: middle * 0.3)
        )
        path.closeSubpath()
        return path
    }
}

struct CombinedTimeView_Previews: PreviewProvider {
    static var previews: some View {
        CombinedTimeView()
            .environmentObject(StopwatchViewModel())
            .environmentObject(TimerViewModel())
            .preferredColorScheme(.dark)
    }
}
