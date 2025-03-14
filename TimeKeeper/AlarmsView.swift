//
//  AlarmsView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//
import SwiftUI

struct AlarmsView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    Text("Alarms")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    HStack(spacing: 10) {
                        Button(action: {
                            viewModel.activeModal = .choice
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
                    
                    List {
                        ForEach(viewModel.alarms) { alarm in
                            if alarm.isEventAlarm {
                                EventAlarmRow(alarm: alarm)
                                    .listRowBackground(Color.black)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            } else {
                                SingleAlarmRow(alarm: alarm)
                                    .listRowBackground(Color.black)
                                    .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 5, trailing: 0))
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.deleteAlarm(at: indexSet)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: Binding(
                get: { viewModel.activeModal != .none },
                set: { if !$0 { viewModel.activeModal = .none } }
            )) {
                Group {
                    switch viewModel.activeModal {
                    case .choice:
                        AlarmChoiceView()
                    case .singleAlarm:
                        SingleAlarmView()
                    case .eventAlarm:
                        EventAlarmView()
                    case .settings:
                        AlarmSettingsView()
                    case .editSingleAlarm:
                        SingleAlarmView(isEditing: true)
                    case .addInstance:
                        EventInstanceView(isAdding: true)
                    case .editInstance:
                        EventInstanceView(isEditing: true)
                    case .none:
                        EmptyView()
                    }
                }
                .id(viewModel.activeModal)
            }
        }
    }
}

struct SingleAlarmRow: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    let alarm: Alarm
    
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
                
                if let firstTime = alarm.times.first, let firstDate = alarm.dates.first {
                    Text(formatTime(firstTime))
                        .font(.title3)
                        .foregroundColor(.white)
                    Text(formatDate(firstDate))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                if let instance = alarm.instances?.first, instance.repeatInterval != .none {
                    Text("Repeat \(instance.repeatInterval.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack {
                Toggle("", isOn: Binding(
                    get: { alarm.status },
                    set: { _ in viewModel.toggleAlarmStatus(for: alarm) }
                ))
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                
                Button(action: {
                    viewModel.handleOpenSettings(alarm: alarm)
                }) {
                    Image(systemName: "gearshape")
                        .foregroundColor(.gray)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                    Toggle("", isOn: Binding(
                        get: { alarm.status },
                        set: { _ in viewModel.toggleAlarmStatus(for: alarm) }
                    ))
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    
                    Button(action: {
                        viewModel.handleOpenSettings(alarm: alarm)
                    }) {
                        Image(systemName: "gearshape")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            if let instances = alarm.instances {
                ForEach(groupInstancesByDate(instances), id: \.date) { group in
                    Text(formatDate(group.date))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                    
                    ForEach(group.instances) { instance in
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
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .padding(.horizontal)
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
                
                Button(action: {
                    print("Selected time from AlarmSetterView: \(viewModel.alarmTime)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.activeModal = .singleAlarm
                    }
                }) {
                    VStack {
                        Image(systemName: "alarm")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.white)
                        Text("Create Single Alarm")
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
                        Text("Create Event Alarm")
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
        .onAppear {
            print("AlarmChoiceView appeared with alarmTime: \(viewModel.alarmTime)")
        }
    }
}

struct SingleAlarmView: View {
    @EnvironmentObject var viewModel: AlarmViewModel
    let isEditing: Bool
    @Environment(\.dismiss) var dismiss
    
    init(isEditing: Bool = false) {
        self.isEditing = isEditing
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 20) {
                        Text(isEditing ? "Edit Single Alarm" : "Create Single Alarm")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
                        VStack(spacing: 15) {
                            TextField("Alarm Name", text: $viewModel.alarmName)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            
                            TextField("Description", text: $viewModel.alarmDescription)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            
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
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.activeModal = .none
                                if !isEditing { viewModel.resetFields() }
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
                            
                            Button(action: {
                                viewModel.addAlarm()
                                viewModel.activeModal = .none
                                dismiss()
                            }) {
                                Text(isEditing ? "Update Alarm" : "Add Alarm")
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
                            .scaleEffect(viewModel.alarmName.isEmpty ? 0.95 : 1.0)
                            .animation(.spring(), value: viewModel.alarmName.isEmpty)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                if !isEditing {
                    print("SingleAlarmView appeared with alarmTime: \(viewModel.alarmTime)")
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
                        Text("Create Event Alarm")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                        
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
                        
                        VStack(spacing: 15) {
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
                            
                            TextField("Instance Description", text: $viewModel.alarmDescription)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            
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
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        if !viewModel.eventInstances.isEmpty {
                            VStack(spacing: 10) {
                                Text("Instances")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(.top)
                                
                                ForEach(viewModel.eventInstances, id: \.id) { instance in
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
                                    }
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        HStack(spacing: 20) {
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
                            
                            Button(action: {
                                viewModel.addAlarm()
                                viewModel.activeModal = .none
                                dismiss()
                            }) {
                                Text("Add Event Alarm")
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
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("EventAlarmView appeared with alarmTime: \(viewModel.alarmTime)")
            }
        }
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
                        
                        VStack(spacing: 15) {
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
                            
                            TextField("Description", text: $viewModel.alarmDescription)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.5), lineWidth: 1))
                            
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
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            Button(action: {
                                viewModel.activeModal = isEditing ? .editInstance : .addInstance
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
                            
                            Button(action: {
                                if isAdding {
                                    viewModel.addEventInstance()
                                    viewModel.activeModal = .none
                                } else if isEditing, let event = viewModel.selectedEvent, let instance = viewModel.selectedInstance {
                                    if let eventIndex = viewModel.alarms.firstIndex(where: { $0.id == event.id }),
                                       let instanceIndex = event.instances?.firstIndex(where: { $0.id == instance.id }) {
                                        viewModel.alarms[eventIndex].instances?[instanceIndex] = AlarmInstance(
                                            id: instance.id,
                                            date: viewModel.alarmDate,
                                            time: viewModel.alarmTime,
                                            description: viewModel.alarmDescription,
                                            repeatInterval: viewModel.instanceRepeatInterval
                                        )
                                        viewModel.saveAlarms()
                                    }
                                    viewModel.activeModal = .none
                                }
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
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

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
                        
                        VStack(spacing: 15) {
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
                            
                            Toggle("Snooze", isOn: $viewModel.settings.snooze)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        HStack(spacing: 20) {
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
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
