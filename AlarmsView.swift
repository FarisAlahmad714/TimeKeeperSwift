import SwiftUI

// MARK: - AlarmsView (Top-level struct)
struct AlarmsView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    
    // Custom colors - defined as static properties to reduce recalculations
    static let darkBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
    static let accentColor = Color(red: 0.9, green: 0.2, blue: 0.3)
    static let accentColor2 = Color(red: 1.0, green: 0.4, blue: 0.1)
    
    var body: some View {
        NavigationView {
            ZStack {
                // Simple background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 0) {
                    headerView
                    addAlarmButton
                    alarmListView
                }
            }
            .navigationBarHidden(true)
            // Modal view handling
            .sheet(isPresented: Binding(
                get: { viewModel.activeModal != .none },
                set: { if !$0 { viewModel.activeModal = .none } }
            )) {
                modalContentView
            }
            // Overlay for active alarm
            .overlay(activeAlarmView)
            // Check for active alarms when the view appears
            .onAppear {
                viewModel.checkForActiveAlarms()
            }
            // Also check when the app becomes active
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                viewModel.checkForActiveAlarms()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.activeAlarm != nil)
        .preferredColorScheme(.dark)
    }
    
    // Header with title
    private var headerView: some View {
        HStack {
            Text("alarms".localized)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.leading)
            
            Spacer()
            
            // Removed non-functional settings button
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
    }
    
    // Enhanced add alarm button
    private var addAlarmButton: some View {
        Button(action: {
            // Go directly to event alarm creation
            viewModel.activeModal = .eventAlarm
            viewModel.eventInstances = [] // Start with empty instances for new alarm
            viewModel.resetFields() // Reset all fields
            
            // Haptic feedback
            let impactMed = UIImpactFeedbackGenerator(style: .medium)
            impactMed.impactOccurred()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                Text("Add Alarm")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 25)
            .foregroundColor(.white)
            .background(Color(red: 0.9, green: 0.2, blue: 0.3))
            .cornerRadius(30)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
    }
    
    // Alarm list view - fixed to use List for swipe-to-delete functionality
    private var alarmListView: some View {
        List {
            ForEach(viewModel.alarms) { alarm in
                if alarm.isEventAlarm {
                    EventAlarmRow(alarm: alarm)
                        .listRowBackground(Color.black)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.handleEditSingleAlarm(alarm: alarm)
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                            print("Editing event alarm: \(alarm.name)")
                        }
                } else {
                    SingleAlarmRow(alarm: alarm)
                        .listRowBackground(Color.black)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.handleEditSingleAlarm(alarm: alarm)
                            let impactLight = UIImpactFeedbackGenerator(style: .light)
                            impactLight.impactOccurred()
                            print("Editing single alarm: \(alarm.name)")
                        }
                }
            }
            .onDelete { indexSet in
                viewModel.deleteAlarm(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
    }
    
    // Active alarm overlay
    @ViewBuilder
    private var activeAlarmView: some View {
        if let activeAlarm = viewModel.activeAlarm {
            AlarmActiveView(alarm: activeAlarm)
                .edgesIgnoringSafeArea(.all)
        }
    }
    
    // Modal content
    @ViewBuilder
    private var modalContentView: some View {
        Group {
            switch viewModel.activeModal {
            case .eventAlarm:
                EventAlarmView()
            case .settings:
                AlarmSettingsView()
            case .addInstance:
                EventInstanceView(isEditing: false, isAdding: true)
            case .editInstance:
                EventInstanceView(isEditing: true, isAdding: false)
            case .none:
                EmptyView()
            }
        }
    }
    
    // MARK: - AlarmActiveView
    struct AlarmActiveView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        @Environment(\.scenePhase) private var scenePhase
        @State private var backgroundEntryTime: Date?
        @State private var pulseAnimation = false
        @State private var shakeAnimation = false
        
        let alarm: Alarm
        
        var body: some View {
            ZStack {
                // Simple background
                Color.black.opacity(0.9)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 25) {
                    // Alarm header with time
                    Text(formattedTime)
                        .font(.system(size: 70, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Alarm name and description
                    Text(instanceTitle)
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text(instanceDescription)
                        .font(.system(size: 20, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    // Animation elements - simplified
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.1 : 0.9)
                            .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                            .onAppear {
                                pulseAnimation = true
                            }
                        
                        Image(systemName: "alarm.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.white)
                            .rotationEffect(Angle(degrees: shakeAnimation ? 10 : -10))
                            .animation(Animation.easeInOut(duration: 0.2).repeatForever(autoreverses: true), value: shakeAnimation)
                            .onAppear {
                                shakeAnimation = true
                            }
                    }
                    .padding(.vertical, 40)
                    
                    // Action buttons
                    HStack(spacing: 30) {
                        alarmActionButton(title: "Snooze", icon: "bed.double.fill", color: .blue, action: snoozeAlarm)
                        alarmActionButton(title: "Dismiss", icon: "stop.fill", color: .red, action: dismissAlarm)
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
        
        // Helper function to create alarm action buttons
        private func alarmActionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                VStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 30))
                    Text(title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                }
                .frame(width: 120, height: 90)
                .background(color)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
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
        
        private func snoozeAlarm() {
            // Create userInfo dictionary with alarm ID and instanceID
            var userInfo: [String: Any] = ["alarmID": alarm.id]
            
            // Add instanceID if available
            if let instance = viewModel.activeInstance {
                userInfo["instanceID"] = instance.id
            }
            
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
            
            // Log action for debugging
            print("Snooze request sent for alarm: \(alarm.id)")
        }
        
        private func dismissAlarm() {
            // Create userInfo dictionary with alarm ID and instanceID
            var userInfo: [String: Any] = ["alarmID": alarm.id]
            
            // Add instanceID if available
            if let instance = viewModel.activeInstance {
                userInfo["instanceID"] = instance.id
            }
            
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
            
            // Log action for debugging
            print("Dismiss request sent for alarm: \(alarm.id)")
        }
    }
    
    // MARK: - Supporting Views
    struct SingleAlarmRow: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        let alarm: Alarm
        @State private var isOn: Bool = false
        
        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    // Time display
                    if let firstTime = alarm.times.first {
                        Text(formatTime(firstTime))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Toggle switch
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.3, green: 0.85, blue: 0.4)))
                        .onChange(of: isOn) { newValue in
                            // Only call the toggle function if the state is actually different
                            if newValue != alarm.status {
                                viewModel.toggleAlarmStatus(for: alarm)
                                
                                // Force a UI update after a short delay to ensure state is refreshed
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isOn = viewModel.alarms.first(where: { $0.id == alarm.id })?.status ?? false
                                }
                            }
                        }
                }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Alarm name
                        Text(alarm.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        // Description
                        Text(alarm.description)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // Date
                        if let firstDate = alarm.dates.first {
                            Text(formatDate(firstDate))
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.8))
                                .padding(.top, 2)
                        }
                        
                        // Repeat interval
                        if let instance = alarm.instances?.first, instance.repeatInterval != .none {
                            Text("Repeats \(instance.repeatInterval.rawValue)")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    // Settings button
                    Button(action: {
                        viewModel.handleOpenSettings(alarm: alarm)
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color.white.opacity(0.6))
                            .padding(10)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(20)
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .onAppear {
                isOn = alarm.status  // Initialize toggle state when view appears
            }
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
    
    struct EventAlarmRow: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        let alarm: Alarm
        @State private var isOn: Bool = false
        @State private var isExpanded: Bool = true
        
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(spacing: 0) {
                    Button(action: {
                        withAnimation(.spring()) {
                            isExpanded.toggle()
                        }
                    }) {
                        HStack {
                            // Icon and title
                            HStack(spacing: 15) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 22))
                                    .foregroundColor(Color(red: 0.9, green: 0.5, blue: 0.1))
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(alarm.name)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                    
    	
                                }
                            }
                            
                            Spacer()
                            
                            // Expand/collapse indicator
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.gray)
                                .padding(.trailing, 5)
                            
                            // Toggle switch
                            Toggle("", isOn: $isOn)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.3, green: 0.85, blue: 0.4)))
                                .onChange(of: isOn) { newValue in
                                    if newValue != alarm.status {
                                        viewModel.toggleAlarmStatus(for: alarm)
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            isOn = viewModel.alarms.first(where: { $0.id == alarm.id })?.status ?? false
                                        }
                                    }
                                }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Controls row
                    HStack {
                        Spacer()
                        
                        // Add instance button
                        Button(action: {
                            viewModel.handleAddInstance(event: alarm)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus")
                                Text("Add Time")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.3, green: 0.7, blue: 0.4).opacity(0.2))
                            .foregroundColor(Color(red: 0.3, green: 0.8, blue: 0.4))
                            .cornerRadius(15)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Settings button
                        Button(action: {
                            viewModel.handleOpenSettings(alarm: alarm)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "gearshape")
                                Text("Settings")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.gray)
                            .cornerRadius(15)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                
                // Instances section (collapsible)
                if isExpanded, let instances = alarm.instances, !instances.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        // Divider
                        Rectangle()
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 1)
                            .padding(.horizontal, 10)
                        
                        instancesList(instances: instances)
                    }
                }
            }
            .background(Color(red: 0.15, green: 0.15, blue: 0.22))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .onAppear {
                isOn = alarm.status  // Initialize toggle state when view appears
            }
        }
        
        // Extract instances list to simplify view hierarchy
        private func instancesList(instances: [AlarmInstance]) -> some View {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(groupInstancesByDate(instances), id: \.date) { group in
                    // Date header
                    Text(formatDate(group.date))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.85))
                        .padding(.top, 15)
                        .padding(.bottom, 5)
                    
                    // Instances for this date
                    ForEach(group.instances) { instance in
                        instanceRow(for: instance)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.handleEditInstance(event: alarm, instance: instance)
                                print("Editing instance: \(instance.id) of alarm: \(alarm.name)")
                            }
                            .padding(.vertical, 5)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 15)
        }
        
        private func instanceRow(for instance: AlarmInstance) -> some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    // Time
                    Text(formatTime(instance.time))
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Description
                    Text(instance.description)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    // Repeat interval
                    if instance.repeatInterval != .none {
                        Text("Repeats \(instance.repeatInterval.rawValue)")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    withAnimation {
                        viewModel.deleteInstance(eventId: alarm.id, instanceId: instance.id)
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.red.opacity(0.8))
                        .padding(10)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.05))
            .cornerRadius(15)
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "E, MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        struct InstanceGroup {
            var date: Date
            var instances: [AlarmInstance]
        }
        
        func groupInstancesByDate(_ instances: [AlarmInstance]) -> [InstanceGroup] {
            var groups: [String: InstanceGroup] = [:]
            
            for instance in instances {
                let dateKey = formatDate(instance.date)
                
                if groups[dateKey] == nil {
                    groups[dateKey] = InstanceGroup(date: instance.date, instances: [])
                }
                
                groups[dateKey]?.instances.append(instance)
            }
            
            return Array(groups.values).sorted { formatDate($0.date) < formatDate($1.date) }
        }
    }
    
    // MARK: - Create/Edit Views
    struct AlarmChoiceView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        
        var body: some View {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Header
                    Text("Create an Alarm")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    // Create alarm button
                    Button(action: {
                        print("Selected time from AlarmSetterView: \(viewModel.alarmTime)")
                        
                        // Haptic feedback
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.activeModal = .eventAlarm
                        }
                    }) {
                        VStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "alarm.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 35, height: 35)
                                    .foregroundColor(.white)
                            }
                            
                            Text("Create Alarm")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 25)
                        .padding(.horizontal, 30)
                        .background(Color(red: 0.15, green: 0.15, blue: 0.2))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Close button
                    Button(action: {
                        viewModel.activeModal = .none
                    }) {
                        Text("Close")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .frame(width: 200)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(30)
                    }
                    .padding(.bottom, 30)
                }
            }
            .onAppear {
                print("AlarmChoiceView appeared with alarmTime: \(viewModel.alarmTime)")
            }
        }
    }
    
    // This view redirects to EventAlarmView
    struct SingleAlarmView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        var isEditing: Bool
        @Environment(\.dismiss) var dismiss
        
        init(isEditing: Bool = false) {
            self.isEditing = isEditing
        }
        
        var body: some View {
            // Redirect to EventAlarmView
            EventAlarmView()
                .onAppear {
                    // Initialize event instances if editing
                    if isEditing, let alarm = viewModel.selectedAlarm {
                        if alarm.instances == nil || alarm.instances!.isEmpty {
                            // Create a new instance based on the single alarm data
                            let newInstance = AlarmInstance(
                                id: UUID().uuidString,
                                date: alarm.dates.first ?? Date(),
                                time: alarm.times.first ?? Date(),
                                description: alarm.description,
                                repeatInterval: viewModel.instanceRepeatInterval
                            )
                            viewModel.eventInstances = [newInstance]
                        } else {
                            viewModel.eventInstances = alarm.instances ?? []
                        }
                    }
                }
        }
    }
    
    struct EventAlarmView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                ZStack {
                    // Background
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // Header
                            Text("Create Alarm")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            // Form sections
                            eventDetailsSection
                            
                            instanceDetailsSection
                            
                            // Instances list
                            if !viewModel.eventInstances.isEmpty {
                                instancesListSection
                            }
                            
                            // Action buttons
                            buttonSection
                                .padding(.bottom, 30)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("EventAlarmView appeared with alarmTime: \(viewModel.alarmTime)")
            }
        }
        
        // Event details section
        private var eventDetailsSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Alarm Details")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    TextField("Alarm Name", text: $viewModel.alarmName)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Description input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    TextField("Alarm Description", text: $viewModel.alarmDescription)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
            }
            .padding()
            .background(Color(red: 0.12, green: 0.12, blue: 0.17))
            .cornerRadius(20)
        }
        
        // Instance details section
        private var instanceDetailsSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Add Time")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $viewModel.alarmDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Color(red: 1.0, green: 0.5, blue: 0.3))
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Time picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $viewModel.alarmTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Color(red: 1.0, green: 0.5, blue: 0.3))
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Description")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    TextField("Instance Description", text: $viewModel.alarmDescription)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Repeat interval
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repeat")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Picker("Repeat", selection: $viewModel.instanceRepeatInterval) {
                        ForEach(RepeatInterval.allCases, id: \.self) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(Color(red: 1.0, green: 0.5, blue: 0.3))
                    .padding()
                    .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .cornerRadius(15)
                }
                
                // Add instance button
                Button(action: {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    viewModel.addEventInstance()
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Time")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(15)
                }
                .disabled(viewModel.alarmDescription.isEmpty)
                .opacity(viewModel.alarmDescription.isEmpty ? 0.6 : 1.0)
            }
            .padding()
            .background(Color(red: 0.12, green: 0.12, blue: 0.17))
            .cornerRadius(20)
        }
        
        // Instances list section
        private var instancesListSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Scheduled Times")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                ForEach(viewModel.eventInstances, id: \.id) { instance in
                    instanceRow(for: instance)
                }
            }
            .padding()
            .background(Color(red: 0.12, green: 0.12, blue: 0.17))
            .cornerRadius(20)
        }
        
        // Instance row
        private func instanceRow(for instance: AlarmInstance) -> some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    // Date and time
                    HStack {
                        Text(formatTime(instance.time))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(formatDate(instance.date))
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    
                    // Description
                    Text(instance.description)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    // Repeat interval
                    if instance.repeatInterval != .none {
                        Text("Repeats \(instance.repeatInterval.rawValue)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    }
                }
                
                Spacer()
                
                // Delete button
                Button(action: {
                    withAnimation {
                        viewModel.eventInstances.removeAll { $0.id == instance.id }
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding()
            .background(Color(red: 0.15, green: 0.15, blue: 0.2))
            .cornerRadius(15)
        }
        
        // Button section
        private var buttonSection: some View {
            HStack(spacing: 20) {
                // Cancel button
                Button(action: {
                    viewModel.activeModal = .none
                    viewModel.resetFields()
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
                
                // Add alarm button
                Button(action: {
                    // Haptic feedback
                    let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
                    impactHeavy.impactOccurred()
                    
                    // Add alarm and dismiss
                    viewModel.addAlarm()
                    viewModel.activeModal = .none
                    dismiss()
                }) {
                    Text("Add Alarm")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.red)
                        .cornerRadius(20)
                }
                .disabled(viewModel.alarmName.isEmpty || viewModel.eventInstances.isEmpty)
                .opacity(viewModel.alarmName.isEmpty || viewModel.eventInstances.isEmpty ? 0.5 : 1.0)
            }
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
    }
    
    // Simplified AlarmSettingsView
    struct AlarmSettingsView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                ZStack {
                    // Background
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            // Header
                            Text("Alarm Settings")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            // Settings section
                            settingsSection
                            
                            // Action buttons
                            buttonSection
                                .padding(.bottom, 30)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        
        // Settings section
        private var settingsSection: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Sound & Notifications")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Ringtone picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ringtone")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Picker("Ringtone", selection: $viewModel.settings.ringtone) {
                        ForEach(viewModel.availableRingtones, id: \.self) { ringtone in
                            Text(ringtone.replacingOccurrences(of: ".mp3", with: "")).tag(ringtone)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(Color.red)
                    .padding()
                    .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .cornerRadius(15)
                }
                
                // Snooze toggle
                VStack(alignment: .leading, spacing: 8) {
                    Text("Snooze")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Toggle("Allow snooze", isOn: $viewModel.settings.snooze)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                        .toggleStyle(SwitchToggleStyle(tint: Color.red))
                }
            }
            .padding()
            .background(Color(red: 0.12, green: 0.12, blue: 0.17))
            .cornerRadius(20)
        }
        
        // Button section
        private var buttonSection: some View {
            HStack(spacing: 20) {
                // Cancel button
                Button(action: {
                    viewModel.activeModal = .none
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
                
                // Save button
                Button(action: {
                    // Haptic feedback
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    viewModel.updateAlarmSettings()
                    viewModel.activeModal = .none
                    dismiss()
                }) {
                    Text("Save Changes")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
            }
        }
    }
    
    // Simplified EventInstanceView
    struct EventInstanceView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        let isEditing: Bool
        let isAdding: Bool
        @Environment(\.dismiss) var dismiss
        
        init(isEditing: Bool = false, isAdding: Bool = false) {
            self.isEditing = isEditing
            self.isAdding = isAdding
        }
        
        var body: some View {
            NavigationView {
                ZStack {
                    // Background
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    ScrollView {
                        VStack(spacing: 25) {
                            // Header
                            Text(isEditing ? "Edit Time" : "Add Time")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            // Instance details
                            instanceDetailsSection
                            
                            // Action buttons
                            buttonSection
                                .padding(.bottom, 30)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        
        // Instance details section
        private var instanceDetailsSection: some View {
            VStack(alignment: .leading, spacing: 15) {
                Text("Time Details")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                // Date picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $viewModel.alarmDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Color.blue)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Time picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    DatePicker("", selection: $viewModel.alarmTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .accentColor(Color.blue)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    TextField("Time Description", text: $viewModel.alarmDescription)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                        .cornerRadius(15)
                }
                
                // Repeat interval
                VStack(alignment: .leading, spacing: 8) {
                    Text("Repeat")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.gray)
                    
                    Picker("Repeat", selection: $viewModel.instanceRepeatInterval) {
                        ForEach(RepeatInterval.allCases, id: \.self) { interval in
                            Text(interval.rawValue).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .accentColor(Color.blue)
                    .padding()
                    .background(Color(red: 0.2, green: 0.2, blue: 0.25))
                    .cornerRadius(15)
                }
            }
            .padding()
            .background(Color(red: 0.12, green: 0.12, blue: 0.17))
            .cornerRadius(20)
        }
        
        // Button section
        private var buttonSection: some View {
            HStack(spacing: 20) {
                // Cancel button
                Button(action: {
                    viewModel.activeModal = .none
                    dismiss()
                }) {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(20)
                }
                
                // Save button
                Button(action: {
                    // Haptic feedback
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    if isEditing, let event = viewModel.selectedEvent, let instance = viewModel.selectedInstance {
                        // Update existing instance
                        if let eventIndex = viewModel.alarms.firstIndex(where: { $0.id == event.id }),
                           let instanceIndex = event.instances?.firstIndex(where: { $0.id == instance.id }) {
                            var updatedAlarm = viewModel.alarms[eventIndex]
                            if updatedAlarm.instances != nil {
                                updatedAlarm.instances?[instanceIndex] = AlarmInstance(
                                    id: instance.id,
                                    date: viewModel.alarmDate,
                                    time: viewModel.alarmTime,
                                    description: viewModel.alarmDescription,
                                    repeatInterval: viewModel.instanceRepeatInterval
                                )
                                viewModel.updateAlarm(updatedAlarm)
                            }
                        }
                    } else {
                        // Adding new instance to existing event alarm
                        viewModel.addEventInstance()
                        
                        // Save the updated instances back to the actual alarm
                        if let event = viewModel.selectedEvent {
                            var updatedAlarm = event
                            updatedAlarm.instances = viewModel.eventInstances
                            updatedAlarm.times = viewModel.eventInstances.map { $0.time }
                            updatedAlarm.dates = viewModel.eventInstances.map { $0.date }
                            viewModel.updateAlarm(updatedAlarm)
                        }
                    }
                    
                    viewModel.activeModal = .none
                    dismiss()
                }) {
                    Text(isEditing ? "Update Time" : "Add Time")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(20)
                }
                .disabled(viewModel.alarmDescription.isEmpty)
                .opacity(viewModel.alarmDescription.isEmpty ? 0.5 : 1.0)
            }
        }
    }
}
