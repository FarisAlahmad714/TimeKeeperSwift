import SwiftUI

// MARK: - AlarmsView (Top-level struct)
struct AlarmsView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Main content
                VStack(spacing: 0) {
                    // Header
                    Text("Alarms")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    // Add Alarm Button
                    HStack(spacing: 10) {
                        Button(action: {
                            // Go directly to event alarm creation instead of choice
                            viewModel.activeModal = .eventAlarm
                            viewModel.eventInstances = [] // Start with empty instances for new alarm
                            viewModel.resetFields() // Reset all fields
                        }) {
                            Text("+ Add Alarm")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(10)
                                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // Alarm List
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
    }
    
    // Extract the list view to fix type-checking issues
    private var alarmListView: some View {
        List {
            ForEach(viewModel.alarms) { alarm in
                if alarm.isEventAlarm {
                    EventAlarmRow(alarm: alarm)
                        .listRowBackground(Color.black)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    // Add tap gesture to edit event alarm
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.handleEditSingleAlarm(alarm: alarm)
                            print("Editing event alarm: \(alarm.name)")
                        }
                } else {
                    SingleAlarmRow(alarm: alarm)
                        .listRowBackground(Color.black)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                    // Add tap gesture to edit single alarm
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.handleEditSingleAlarm(alarm: alarm)
                            print("Editing single alarm: \(alarm.name)")
                        }
                }
            }
            .onDelete { indexSet in
                viewModel.deleteAlarm(at: indexSet)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // Extract modal content to fix type-checking issues
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
    
    // MARK: - AlarmActiveView - FIXED IMPLEMENTATION
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
            HStack {
                Image(systemName: "clock")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .padding(.trailing)
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(alarm.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(alarm.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    timeAndDateSection
                    
                    repeatIntervalText
                }
                
                Spacer()
                
                controlButtons
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .padding(.horizontal)
            .onAppear {
                isOn = alarm.status  // Initialize toggle state when view appears
            }
        }
        
        private var timeAndDateSection: some View {
            Group {
                if let firstTime = alarm.times.first, let firstDate = alarm.dates.first {
                    Text(formatTime(firstTime))
                        .font(.title3)
                        .foregroundColor(.white)
                    Text(formatDate(firstDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        
        private var repeatIntervalText: some View {
            Group {
                if let instance = alarm.instances?.first, instance.repeatInterval != .none {
                    Text("Repeat \(instance.repeatInterval.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        
        private var controlButtons: some View {
            VStack {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .onChange(of: isOn) { _, newValue in  // Updated syntax for iOS 17+
                        // IMPORTANT: Make sure we're seeing the actual change
                        print("Toggle changed to \(newValue) for alarm: \(alarm.name)")
                        
                        // Only call the toggle function if the state is actually different
                        if newValue != alarm.status {
                            viewModel.toggleAlarmStatus(for: alarm)
                            
                            // Force a UI update after a short delay to ensure state is refreshed
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isOn = viewModel.alarms.first(where: { $0.id == alarm.id })?.status ?? false
                            }
                        }
                    }
                
                Button(action: {
                    viewModel.handleOpenSettings(alarm: alarm)
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateFormat = "h:mma"
            return formatter.string(from: date).uppercased()
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }
    }
    
    struct EventAlarmRow: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        let alarm: Alarm
        @State private var isOn: Bool = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                headerSection
                
                instancesSection
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            .padding(.horizontal)
            .onAppear {
                isOn = alarm.status  // Initialize toggle state when view appears
            }
        }
        
        private var headerSection: some View {
            HStack {
                Image(systemName: "calendar")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.gray)
                    .padding(.trailing)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(alarm.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            viewModel.handleAddInstance(event: alarm)
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(.green)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Text(alarm.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack {
                    Toggle("", isOn: $isOn)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                        .onChange(of: isOn) { _, newValue in  // Updated syntax for iOS 17+
                            // Log the change
                            print("Toggle changed to \(newValue) for event alarm: \(alarm.name)")
                            
                            // Only call if state is different
                            if newValue != alarm.status {
                                viewModel.toggleAlarmStatus(for: alarm)
                                
                                // Force UI update
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    isOn = viewModel.alarms.first(where: { $0.id == alarm.id })?.status ?? false
                                }
                            }
                        }
                    
                    Button(action: {
                        viewModel.handleOpenSettings(alarm: alarm)
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        
        private var instancesSection: some View {
            Group {
                if let instances = alarm.instances {
                    ForEach(groupInstancesByDate(instances), id: \.date) { group in
                        Text(formatDate(group.date))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                            .padding(.top, 4)
                        
                        instancesList(for: group)
                    }
                }
            }
        }
        
        @ViewBuilder
        private func instancesList(for group: InstanceGroup) -> some View {
            ForEach(group.instances) { instance in
                instanceRow(for: instance)
                // Add tap gesture to edit instance
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.handleEditInstance(event: alarm, instance: instance)
                        print("Editing instance: \(instance.id) of alarm: \(alarm.name)")
                    }
            }
        }
        
        private func instanceRow(for instance: AlarmInstance) -> some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(formatTime(instance.time))
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Text(instance.description)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    if instance.repeatInterval != .none {
                        Text("Repeat \(instance.repeatInterval.rawValue)")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.deleteInstance(eventId: alarm.id, instanceId: instance.id)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateFormat = "h:mma"
            return formatter.string(from: date).uppercased()
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
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
    
    struct AlarmChoiceView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        
        var body: some View {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 20) {
                    Text("Create an Alarm")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    // Removed singleAlarmButton and kept only eventAlarmButton
                    eventAlarmButton
                    
                    closeButton
                }
            }
            .onAppear {
                print("AlarmChoiceView appeared with alarmTime: \(viewModel.alarmTime)")
            }
        }
        
        private var eventAlarmButton: some View {
            Button(action: {
                print("Selected time from AlarmSetterView: \(viewModel.alarmTime)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.activeModal = .eventAlarm
                }
            }) {
                VStack {
                    Image(systemName: "calendar")
                        .resizable()
                        .frame(width: 50, height: 50)
                        .foregroundColor(.white)
                    Text("Create Alarm")  // Changed from "Create Event Alarm"
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            }
            .padding(.horizontal)
        }
        
        private var closeButton: some View {
            Button(action: {
                viewModel.activeModal = .none
            }) {
                Text("Close")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
    
    // This view can be completely removed, but to ensure compatibility with existing code,
    // we'll modify it to redirect to EventAlarmView
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
                    Color.black.edgesIgnoringSafeArea(.all)
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Create Alarm") // Removed "Event" from title
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            eventDetailsSection
                            
                            instanceDetailsSection
                            
                            instancesListSection
                            
                            buttonSection
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("EventAlarmView appeared with alarmTime: \(viewModel.alarmTime)")
            }
        }
        
        private func instanceRow(for instance: AlarmInstance) -> some View {
            HStack {
                VStack(alignment: .leading) {
                    Text(formatDate(instance.date))
                        .foregroundColor(.white)
                    Text(formatTime(instance.time) + " - " + instance.description)
                        .foregroundColor(.gray)
                    Text("Repeat \(instance.repeatInterval.rawValue)")
                        .foregroundColor(.blue)
                        .font(.subheadline)
                }
                Spacer()
                
                // Add delete button
                Button(action: {
                    // Remove the instance from eventInstances array
                    viewModel.eventInstances.removeAll { $0.id == instance.id }
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        
        private var eventDetailsSection: some View {
            VStack(spacing: 15) {
                TextField("Alarm Name", text: $viewModel.alarmName)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                
                TextField("Alarm Description", text: $viewModel.alarmDescription)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        
        private var instanceDetailsSection: some View {
            VStack(spacing: 15) {
                dateTimeSection
                
                TextField("Instance Description", text: $viewModel.alarmDescription)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                
                repeatIntervalPicker
                
                addInstanceButton
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        
        private var dateTimeSection: some View {
            HStack(spacing: 10) {
                DatePicker("Date", selection: $viewModel.alarmDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                DatePicker("Time", selection: $viewModel.alarmTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        
        private var repeatIntervalPicker: some View {
            Picker("Repeat", selection: $viewModel.instanceRepeatInterval) {
                ForEach(RepeatInterval.allCases, id: \.self) { interval in
                    Text(interval.rawValue).tag(interval)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        
        private var addInstanceButton: some View {
            Button(action: {
                viewModel.addEventInstance()
            }) {
                Text("Add Instance")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .scaleEffect(viewModel.alarmDescription.isEmpty ? 0.95 : 1.0)
            .animation(.spring(), value: viewModel.alarmDescription.isEmpty)
        }
        
        private var instancesListSection: some View {
            Group {
                if !viewModel.eventInstances.isEmpty {
                    VStack(spacing: 10) {
                        Text("Instances")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        ForEach(viewModel.eventInstances, id: \.id) { instance in
                            instanceRow(for: instance)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        
        private var buttonSection: some View {
            HStack(spacing: 20) {
                cancelButton
                
                addEventAlarmButton
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        
        private var cancelButton: some View {
            Button(action: {
                viewModel.activeModal = .none
                viewModel.resetFields()
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        
        private var addEventAlarmButton: some View {
            Button(action: {
                viewModel.addAlarm()
                viewModel.activeModal = .none
                dismiss()
            }) {
                Text("Add Alarm") // Changed from "Add Event Alarm"
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .scaleEffect(viewModel.alarmName.isEmpty || viewModel.eventInstances.isEmpty ? 0.95 : 1.0)
            .animation(.spring(), value: viewModel.alarmName.isEmpty || viewModel.eventInstances.isEmpty)
        }
        
        func formatDate(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        
        func formatTime(_ date: Date) -> String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateFormat = "h:mma"
            return formatter.string(from: date).uppercased()
        }
    }
    
    // No changes to AlarmSettingsView
    struct AlarmSettingsView: View {
        @EnvironmentObject var viewModel: AlarmViewModel
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            NavigationView {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    ScrollView {
                        VStack(spacing: 20) {
                            Text("Alarm Settings")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            settingsSection
                            
                            buttonSection
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        
        private var settingsSection: some View {
            VStack(spacing: 15) {
                ringtonePicker
                
                snoozeToggle
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        
        private var ringtonePicker: some View {
            Picker("Ringtone", selection: $viewModel.settings.ringtone) {
                ForEach(viewModel.availableRingtones, id: \.self) { ringtone in
                    Text(ringtone.replacingOccurrences(of: ".mp3", with: "")).tag(ringtone)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        
        private var snoozeToggle: some View {
            Toggle("Snooze", isOn: $viewModel.settings.snooze)
                .foregroundColor(.white)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
        }
        
        private var buttonSection: some View {
            HStack(spacing: 20) {
                cancelButton
                
                updateSettingsButton
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        
        private var cancelButton: some View {
            Button(action: {
                viewModel.activeModal = .none
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        
        private var updateSettingsButton: some View {
            Button(action: {
                viewModel.updateAlarmSettings()
                viewModel.activeModal = .none
                dismiss()
            }) {
                Text("Update Settings")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
    }
    
    // No changes to EventInstanceView
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
                    Color.black.edgesIgnoringSafeArea(.all)
                    ScrollView {
                        VStack(spacing: 20) {
                            Text(isEditing ? "Edit Instance" : "Add Instance")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            instanceDetailsSection
                            
                            buttonSection
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        
        private var instanceDetailsSection: some View {
            VStack(spacing: 15) {
                dateTimeSection
                
                TextField("Description", text: $viewModel.alarmDescription)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                
                repeatIntervalPicker
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
            .padding(.horizontal)
        }
        
        private var dateTimeSection: some View {
            HStack(spacing: 10) {
                DatePicker("Date", selection: $viewModel.alarmDate, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                DatePicker("Time", selection: $viewModel.alarmTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        
        private var repeatIntervalPicker: some View {
            Picker("Repeat", selection: $viewModel.instanceRepeatInterval) {
                ForEach(RepeatInterval.allCases, id: \.self) { interval in
                    Text(interval.rawValue).tag(interval)
                }
            }
            .pickerStyle(.menu)
            .foregroundColor(.white)
            .padding()
            .background(Color.gray.opacity(0.2))
            .cornerRadius(10)
        }
        
        private var buttonSection: some View {
            HStack(spacing: 20) {
                cancelButton
                
                addOrUpdateButton
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        
        private var cancelButton: some View {
            Button(action: {
                viewModel.activeModal = .none
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
            }
        }
        
        private var addOrUpdateButton: some View {
            Button(action: {
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
                Text(isEditing ? "Update Instance" : "Add Instance")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.blue, Color.cyan]), startPoint: .leading, endPoint: .trailing)
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
            .scaleEffect(viewModel.alarmDescription.isEmpty ? 0.95 : 1.0)
            .animation(.spring(), value: viewModel.alarmDescription.isEmpty)
        }
    }
}
