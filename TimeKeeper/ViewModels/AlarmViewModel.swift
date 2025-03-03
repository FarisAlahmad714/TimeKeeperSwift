// AlarmViewModel.swift

import Foundation
import SwiftUI
import UserNotifications
import AVFoundation

class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var showChoiceModal = false
    @Published var showSingleAlarmModal = false
    @Published var showEventAlarmModal = false
    @Published var showEditSingleAlarmModal = false
    @Published var showEditInstanceModal = false
    @Published var showAddInstanceModal = false
    @Published var showSettingsModal = false
    @Published var showDocumentPicker: Bool = false
    
    @Published var selectedEvent: Alarm?
    @Published var selectedInstance: AlarmInstance?
    @Published var alarmName = ""
    @Published var alarmDescription = ""
    @Published var alarmTime = Date()
    @Published var alarmDate = Date()
    @Published var eventInstances: [AlarmInstance] = []
    @Published var instanceRepeatInterval: RepeatInterval = .none
    
    @Published var settings: AlarmSettings
    @Published var selectedAlarm: Alarm?
    
    let availableRingtones: [String] = [
        "default.mp3",
        "ringtone1.mp3",
        "ringtone2.mp3",
        "ringtone3.mp3"
    ]
    
    init() {
        self.settings = AlarmSettings(
            ringtone: availableRingtones.first ?? "default.mp3",
            isCustomRingtone: false,
            customRingtoneURL: nil,
            snooze: false
        )
        loadAlarms()
    }
    
    func presentDocumentPicker() {
        }
    
    func handleSelectedAudioFile(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)
        
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: url, to: destinationURL)
            settings.ringtone = url.lastPathComponent
            settings.isCustomRingtone = true
            settings.customRingtoneURL = destinationURL
            print("Successfully copied audio file to: \(destinationURL)")
        } catch {
            print("Error copying audio file: \(error)")
        }
        
        showDocumentPicker = false
    }
    
    func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: "alarms") {
            if let decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
                self.alarms = decoded
                print("Alarms loaded: \(decoded.count)")
                return
            }
        }
        self.alarms = []
    }
    
    func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: "alarms")
            print("Alarms saved: \(alarms.count)")
        }
    }
    
    func addAlarm() {
        let newId = UUID().uuidString
        
        if showSingleAlarmModal {
            let singleInstance = AlarmInstance(
                id: UUID().uuidString,
                date: alarmDate,
                time: alarmTime,
                description: alarmDescription,
                repeatInterval: instanceRepeatInterval
            )
            
            let newAlarm = Alarm(
                id: newId,
                name: alarmName,
                description: alarmDescription,
                times: [alarmTime],
                dates: [alarmDate],
                instances: [singleInstance],
                status: true,
                ringtone: settings.ringtone,
                isCustomRingtone: settings.isCustomRingtone,
                customRingtoneURL: settings.customRingtoneURL,
                snooze: settings.snooze
            )
            
            alarms.append(newAlarm)
        } else {
            let newAlarm = Alarm(
                id: newId,
                name: alarmName,
                description: alarmDescription,
                times: eventInstances.map { instance in instance.time },
                dates: eventInstances.map { instance in instance.date },
                instances: eventInstances,
                status: true,
                ringtone: settings.ringtone,
                isCustomRingtone: settings.isCustomRingtone,
                customRingtoneURL: settings.customRingtoneURL,
                snooze: settings.snooze
            )
            
            alarms.append(newAlarm)
        }
        
        saveAlarms()
        scheduleNotifications(for: alarms.last!)
        resetFields()
    }
    
    func resetFields() {
        alarmName = ""
        alarmDescription = ""
        alarmTime = Date()
        alarmDate = Date()
        eventInstances = []
        instanceRepeatInterval = .none
        showSingleAlarmModal = false
        showEventAlarmModal = false
        showChoiceModal = false
    }
    
    func scheduleNotifications(for alarm: Alarm) {
        guard alarm.status else {
            print("Skipping scheduling notifications for disabled alarm: \(alarm.name)")
            return
        }
        
        print("Scheduling notifications for alarm: \(alarm.name) with ID: \(alarm.id)")
        
        let calendar = Calendar.current
        let now = Date()
        
        if let instances = alarm.instances {
            for (_, instance) in instances.enumerated() {
                let content = UNMutableNotificationContent()
                content.title = alarm.name
                content.body = instance.description
                
                let soundName = alarm.ringtone
                if !alarm.isCustomRingtone, Bundle.main.path(forResource: soundName.replacingOccurrences(of: ".mp3", with: ""), ofType: "mp3") != nil {
                    content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))
                    print("Setting notification sound for instance \(instance.id) to: \(soundName)")
                } else {
                    content.sound = .default
                    print("Using default sound for notification (custom sounds must be bundled)")
                }
                
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: instance.date)
                let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: instance.time)
                
                var combinedComponents = DateComponents()
                combinedComponents.year = dateComponents.year
                combinedComponents.month = dateComponents.month
                combinedComponents.day = dateComponents.day
                combinedComponents.hour = timeComponents.hour
                combinedComponents.minute = timeComponents.minute
                combinedComponents.second = timeComponents.second ?? 0
                
                guard let startDate = calendar.date(from: combinedComponents) else {
                    print("Failed to create start date from components for instance \(instance.id): \(combinedComponents)")
                    continue
                }
                
                content.userInfo = ["alarmID": alarm.id, "instanceID": instance.id]
                
                if startDate > now {
                    let initialTrigger = UNCalendarNotificationTrigger(dateMatching: combinedComponents, repeats: false)
                    let initialRequest = UNNotificationRequest(
                        identifier: "\(alarm.id)_instance_\(instance.id)_initial",
                        content: content,
                        trigger: initialTrigger
                    )
                    
                    UNUserNotificationCenter.current().add(initialRequest) { error in
                        if let error = error {
                            print("Error scheduling initial notification for instance \(instance.id): \(error)")
                        } else {
                            print("Initial notification scheduled successfully for instance \(instance.id) at \(self.formatDateTime(from: combinedComponents))")
                        }
                    }
                } else {
                    print("Initial notification for instance \(instance.id) is in the past: \(self.formatDateTime(from: combinedComponents))")
                }
                
                if instance.repeatInterval != .none {
                    let maxRepeats = 10
                    var currentDate = startDate
                    
                    if startDate <= now {
                        switch instance.repeatInterval {
                        case .minutely:
                            let minutesSinceStart = calendar.dateComponents([.minute], from: startDate, to: now).minute ?? 0
                            let nextMinuteOffset = minutesSinceStart + 1
                            currentDate = calendar.date(byAdding: .minute, value: nextMinuteOffset, to: startDate)!
                        case .hourly:
                            let hoursSinceStart = calendar.dateComponents([.hour], from: startDate, to: now).hour ?? 0
                            let nextHourOffset = hoursSinceStart + 1
                            currentDate = calendar.date(byAdding: .hour, value: nextHourOffset, to: startDate)!
                        case .daily:
                            let daysSinceStart = calendar.dateComponents([.day], from: startDate, to: now).day ?? 0
                            let nextDayOffset = daysSinceStart + 1
                            currentDate = calendar.date(byAdding: .day, value: nextDayOffset, to: startDate)!
                        case .weekly:
                            let weeksSinceStart = calendar.dateComponents([.weekOfYear], from: startDate, to: now).weekOfYear ?? 0
                            let nextWeekOffset = weeksSinceStart + 1
                            currentDate = calendar.date(byAdding: .weekOfYear, value: nextWeekOffset, to: startDate)!
                        case .none:
                            continue
                        }
                    }
                    
                    var repeatCounter = 0
                    while repeatCounter < maxRepeats && currentDate > now {
                        let repeatComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: currentDate)
                        let repeatTrigger = UNCalendarNotificationTrigger(dateMatching: repeatComponents, repeats: false)
                        let repeatRequest = UNNotificationRequest(
                            identifier: "\(alarm.id)_instance_\(instance.id)_repeat_\(repeatCounter + 1)",
                            content: content,
                            trigger: repeatTrigger
                        )
                        
                        UNUserNotificationCenter.current().add(repeatRequest) { error in
                            if let error = error {
                                print("Error scheduling repeat notification \(repeatCounter + 1) for instance \(instance.id): \(error)")
                            } else {
                                print("Repeat notification \(repeatCounter + 1) scheduled successfully for instance \(instance.id) at \(self.formatDateTime(from: repeatComponents))")
                            }
                        }
                        
                        switch instance.repeatInterval {
                        case .minutely:
                            currentDate = calendar.date(byAdding: .minute, value: 1, to: currentDate)!
                        case .hourly:
                            currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate)!
                        case .daily:
                            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                        case .weekly:
                            currentDate = calendar.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
                        case .none:
                            break
                        }
                        repeatCounter += 1
                    }
                    
                    print("Scheduled \(repeatCounter) repeat notifications for instance \(instance.id)")
                }
            }
        }
    }
    
    func formatDateTime(from components: DateComponents) -> String {
        let calendar = Calendar.current
        if let date = calendar.date(from: components) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return formatter.string(from: date)
        }
        return "Unknown Date"
    }
    
    func cancelNotifications(for alarm: Alarm) {
        if let instances = alarm.instances {
            for instance in instances {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
                    "\(alarm.id)_instance_\(instance.id)_initial"
                ])
                
                for i in 1...10 {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
                        "\(alarm.id)_instance_\(instance.id)_repeat_\(i)"
                    ])
                }
                
                for i in 1...60 {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
                        "\(alarm.id)_instance_\(instance.id)_repeat_\(i)",
                        "\(alarm.id)_instance_\(instance.id)_repeating"
                    ])
                }
            }
        }
        
        for i in 0..<alarm.dates.count {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
                "\(alarm.id)_\(i)",
                "\(alarm.id)_\(i)_initial",
                "\(alarm.id)_\(i)_repeating"
            ])
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cleared all pending notifications")
    }
    
    func deleteAlarm(at indexSet: IndexSet) {
        let alarmsToDelete = indexSet.map { alarms[$0] }
        
        for alarm in alarmsToDelete {
            print("Deleting alarm: \(alarm.name) with ID: \(alarm.id)")
            cancelNotifications(for: alarm)
            
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let remainingRequests = requests.filter { $0.identifier.contains(alarm.id) }
                if !remainingRequests.isEmpty {
                    print("Warning: \(remainingRequests.count) notifications still pending for alarm \(alarm.id) after cancellation:")
                    for request in remainingRequests {
                        print("- \(request.identifier)")
                    }
                } else {
                    print("All notifications for alarm \(alarm.id) successfully canceled.")
                }
            }
        }
        
        alarms.remove(atOffsets: indexSet)
        saveAlarms()
        clearAllNotifications()
    }
    
    func toggleAlarmStatus(for alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index].status.toggle()
            
            if alarms[index].status {
                scheduleNotifications(for: alarms[index])
            } else {
                cancelNotifications(for: alarms[index])
            }
            
            saveAlarms()
        }
    }
    
    func handleOpenSettings(alarm: Alarm) {
        selectedAlarm = alarm
        settings = AlarmSettings(
            ringtone: alarm.ringtone,
            isCustomRingtone: alarm.isCustomRingtone,
            customRingtoneURL: alarm.customRingtoneURL,
            snooze: alarm.snooze
        )
        showSettingsModal = true
    }
    
    func closeSettings() {
        selectedAlarm = nil
        showSettingsModal = false
    }
    
    func updateAlarmSettings() {
        guard let selectedAlarm = selectedAlarm else { return }
        
        if let index = alarms.firstIndex(where: { $0.id == selectedAlarm.id }) {
            alarms[index] = Alarm(
                id: alarms[index].id,
                name: alarms[index].name,
                description: alarms[index].description,
                times: alarms[index].times,
                dates: alarms[index].dates,
                instances: alarms[index].instances,
                status: alarms[index].status,
                ringtone: settings.ringtone,
                isCustomRingtone: settings.isCustomRingtone,
                customRingtoneURL: settings.customRingtoneURL,
                snooze: settings.snooze
            )
            
            cancelNotifications(for: alarms[index])
            scheduleNotifications(for: alarms[index])
            
            saveAlarms()
            closeSettings()
        }
    }
    
    func addEventInstance() {
        let newInstance = AlarmInstance(
            id: UUID().uuidString,
            date: alarmDate,
            time: alarmTime,
            description: alarmDescription,
            repeatInterval: instanceRepeatInterval
        )
        eventInstances.append(newInstance)
        alarmDescription = ""
        instanceRepeatInterval = .none
    }
    
    func handleEditSingleAlarm(alarm: Alarm) {
        selectedAlarm = alarm
        alarmName = alarm.name
        alarmDescription = alarm.description
        alarmTime = alarm.times.first ?? Date()
        alarmDate = alarm.dates.first ?? Date()
        if let instance = alarm.instances?.first {
            instanceRepeatInterval = instance.repeatInterval
        }
        settings = AlarmSettings(
            ringtone: alarm.ringtone,
            isCustomRingtone: alarm.isCustomRingtone,
            customRingtoneURL: alarm.customRingtoneURL,
            snooze: alarm.snooze
        )
        showEditSingleAlarmModal = true
    }
    
    func handleEditInstance(event: Alarm, instance: AlarmInstance) {
        selectedEvent = event
        selectedInstance = instance
        alarmDate = instance.date
        alarmTime = instance.time
        alarmDescription = instance.description
        instanceRepeatInterval = instance.repeatInterval
        showEditInstanceModal = true
    }
    
    func handleAddInstance(event: Alarm) {
        selectedEvent = event
        alarmDate = Date()
        alarmTime = Date()
        alarmDescription = ""
        instanceRepeatInterval = .none
        showAddInstanceModal = true
    }
    
    func deleteInstance(eventId: String, instanceId: String) {
        if let eventIndex = alarms.firstIndex(where: { $0.id == eventId }), var instances = alarms[eventIndex].instances {
            instances.removeAll { $0.id == instanceId }
            alarms[eventIndex].instances = instances
            alarms[eventIndex].times = instances.map { $0.time }
            alarms[eventIndex].dates = instances.map { $0.date }
            saveAlarms()
            if let selectedEvent = selectedEvent, selectedEvent.id == eventId {
                eventInstances = instances
            }
            cancelNotifications(for: alarms[eventIndex])
            scheduleNotifications(for: alarms[eventIndex])
        }
    }
}
