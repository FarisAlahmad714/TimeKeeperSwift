import Foundation
import SwiftUI
import UserNotifications

// Define ModalState enum
enum ModalState: String {
    case none
    case choice
    case singleAlarm
    case eventAlarm
    case settings
    case editSingleAlarm
    case addInstance
    case editInstance
}

// Define AlarmSettings struct
struct AlarmSettings {
    var ringtone: String
    var isCustomRingtone: Bool
    var customRingtoneURL: URL?
    var snooze: Bool
}

class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var activeModal: ModalState = .none
    
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
    @Published var showDocumentPicker: Bool = false
    
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
        // Implementation for document picker
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
                
                // Schedule notifications for all loaded alarms
                for alarm in self.alarms {
                    if alarm.status {
                        self.scheduleNotifications(for: alarm)
                    }
                }
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
        
        if activeModal == .singleAlarm {
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
        } else if activeModal == .eventAlarm {
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
    }
    
    // Improved toggleAlarmStatus function to fix state inconsistency
    func toggleAlarmStatus(for alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            // Get the current status and toggle it
            let newStatus = !alarms[index].status
            
            // Update the status
            alarms[index].status = newStatus
            print("Toggling alarm '\(alarm.name)' to \(newStatus ? "ON" : "OFF")")
            
            // Handle notifications based on new status
            if newStatus {
                scheduleNotifications(for: alarms[index])
            } else {
                cancelNotifications(for: alarms[index])
            }
            
            // Save the updated state immediately
            saveAlarms()
            
            // Verify the save happened correctly
            DispatchQueue.main.async {
                self.verifyAlarmStatus(id: alarm.id, expectedStatus: newStatus)
            }
        }
    }
    
    // Add verification to ensure UI and saved state match
    private func verifyAlarmStatus(id: String, expectedStatus: Bool) {
        // Load from storage and verify
        if let data = UserDefaults.standard.data(forKey: "alarms"),
           let decoded = try? JSONDecoder().decode([Alarm].self, from: data),
           let savedAlarm = decoded.first(where: { $0.id == id }) {
            
            if savedAlarm.status != expectedStatus {
                print("⚠️ WARNING: Alarm state mismatch! UI: \(expectedStatus), Saved: \(savedAlarm.status)")
                
                // Force update the UI to match saved state
                if let index = alarms.firstIndex(where: { $0.id == id }) {
                    DispatchQueue.main.async {
                        self.alarms[index].status = savedAlarm.status
                        self.objectWillChange.send()
                    }
                }
            } else {
                print("✅ Alarm state verified: \(expectedStatus)")
            }
        }
    }
    
    // IMPROVED notification scheduling to handle multiple instances better
    func scheduleNotifications(for alarm: Alarm) {
        // First cancel ALL existing notifications for this alarm
        cancelNotifications(for: alarm)
        
        guard alarm.status else {
            print("Alarm disabled - not scheduling: \(alarm.name)")
            return
        }
        
        print("Scheduling notifications for alarm: \(alarm.name) with ID: \(alarm.id)")
        
        // Process each instance SEPARATELY
        if let instances = alarm.instances {
            for (index, instance) in instances.enumerated() {
                // Create a separate, standalone notification for each instance
                scheduleStandaloneInstance(instance: instance, index: index, alarm: alarm)
            }
        }
        
        // Check total notification count
        checkPendingNotifications()
    }

    private func scheduleStandaloneInstance(instance: AlarmInstance, index: Int, alarm: Alarm) {
        // Generate unique prefix for all notifications of this instance
        let instancePrefix = "INSTANCE_\(index+1)_\(alarm.id)_"
        
        // Create content with instance-specific title
        let content = UNMutableNotificationContent()
        content.title = "\(alarm.name): \(instance.description)"
        content.body = "Scheduled alarm for \(formatTime(instance.time))"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        
        // Add unique identifiers in userInfo
        content.userInfo = [
            "alarmId": alarm.id,
            "instanceId": instance.id,
            "instanceIndex": index,
            "instanceDescription": instance.description
        ]
        
        // Calculate notification time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: instance.date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: instance.time)
        
        // Get the exact start time
        var exactComponents = DateComponents()
        exactComponents.year = dateComponents.year
        exactComponents.month = dateComponents.month
        exactComponents.day = dateComponents.day
        exactComponents.hour = timeComponents.hour
        exactComponents.minute = timeComponents.minute
        exactComponents.second = 0
        
        // iOS has a limit of 64 scheduled notifications per app
        // For repeating alarms, we'll schedule a maximum of 5 future occurrences
        let maxNotificationsPerInstance = 5
        
        if let startDate = calendar.date(from: exactComponents) {
            let now = Date()
            // Skip scheduling if the date is in the past
            if startDate < now && instance.repeatInterval == .none {
                print("Skipping past notification for \(instance.id) at \(startDate)")
                return
            }
            
            // Schedule based on repeat type
            switch instance.repeatInterval {
            case .none:
                // Single occurrence notification
                let trigger = UNCalendarNotificationTrigger(dateMatching: exactComponents, repeats: false)
                let uniqueId = "\(instancePrefix)SINGLE"
                scheduleNotification(content: content, trigger: trigger, identifier: uniqueId)
                
            case .minutely, .hourly, .daily, .weekly:
                // Calculate the dates for the next few occurrences
                var occurrences: [Date] = []
                var nextDate = max(startDate, now) // Start from now or the start date, whichever is later
                
                for i in 0..<maxNotificationsPerInstance {
                    occurrences.append(nextDate)
                    
                    // Calculate next occurrence
                    switch instance.repeatInterval {
                    case .minutely:
                        nextDate = calendar.date(byAdding: .minute, value: 1, to: nextDate)!
                    case .hourly:
                        nextDate = calendar.date(byAdding: .hour, value: 1, to: nextDate)!
                    case .daily:
                        nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
                    case .weekly:
                        nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate)!
                    default:
                        break
                    }
                }
                
                // Schedule each occurrence
                for (i, date) in occurrences.enumerated() {
                    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                    let uniqueId = "\(instancePrefix)OCC_\(i)"
                    
                    scheduleNotification(content: content, trigger: trigger, identifier: uniqueId)
                }
            }
        }
    }

    private func scheduleNotification(content: UNMutableNotificationContent, trigger: UNNotificationTrigger, identifier: String) {
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(identifier) - \(error.localizedDescription)")
            } else {
                if let calendarTrigger = trigger as? UNCalendarNotificationTrigger,
                   let date = Calendar.current.date(from: calendarTrigger.dateComponents) {
                    print("✅ Scheduled notification: \(identifier) at \(date)")
                } else {
                    print("✅ Scheduled notification: \(identifier)")
                }
            }
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    // IMPROVED notification cancellation
    func cancelNotifications(for alarm: Alarm) {
        print("Cancelling notifications for alarm: \(alarm.id)")
        
        // Gather all possible notification identifiers related to this alarm
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmsRequests = requests.filter { $0.identifier.contains(alarm.id) }
            if !alarmsRequests.isEmpty {
                // Remove all notifications containing this alarm ID
                let identifiers = alarmsRequests.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                print("Cancelled \(identifiers.count) notifications for alarm \(alarm.id)")
            } else {
                print("No notifications found for alarm \(alarm.id)")
            }
        }
    }
    
    // Utility to check how many notifications are scheduled
    func checkPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📱 Total pending notifications: \(requests.count)")
            
            // Group by alarm
            let alarmGroups = Dictionary(grouping: requests) { request -> String in
                let components = request.identifier.components(separatedBy: "_")
                if components.count > 2 && components[0] == "INSTANCE" {
                    return components[2] // The alarm ID in our new format
                } else if let alarmId = request.identifier.components(separatedBy: "_").first {
                    return alarmId // Old format fallback
                }
                return "unknown"
            }
            
            for (alarmId, requests) in alarmGroups {
                print("  🔔 Alarm \(alarmId): \(requests.count) notifications")
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cleared all pending notifications")
    }
    
    // UPDATED to ensure alarms are fully deleted and notifications are cancelled
    func deleteAlarm(at indexSet: IndexSet) {
        let alarmsToDelete = indexSet.map { alarms[$0] }
        
        for alarm in alarmsToDelete {
            print("Deleting alarm: \(alarm.name) with ID: \(alarm.id)")
            
            // Cancel all notifications for this alarm
            cancelNotifications(for: alarm)
            
            // Double-check for any remaining notifications
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let relatedRequests = requests.filter { $0.identifier.contains(alarm.id) }
                if !relatedRequests.isEmpty {
                    let identifiers = relatedRequests.map { $0.identifier }
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                    print("Force removed \(identifiers.count) additional notifications for alarm \(alarm.id)")
                }
            }
        }
        
        // Remove alarms from the array
        alarms.remove(atOffsets: indexSet)
        saveAlarms()
    }
    
    func handleOpenSettings(alarm: Alarm) {
        selectedAlarm = alarm
        settings = AlarmSettings(
            ringtone: alarm.ringtone,
            isCustomRingtone: alarm.isCustomRingtone,
            customRingtoneURL: alarm.customRingtoneURL,
            snooze: alarm.snooze
        )
        activeModal = .settings
    }
    
    func closeSettings() {
        selectedAlarm = nil
        activeModal = .none
    }
    
    func updateAlarmSettings() {
        guard let selectedAlarm = selectedAlarm else { return }
        
        if let index = alarms.firstIndex(where: { $0.id == selectedAlarm.id }) {
            var updatedAlarm = alarms[index]
            updatedAlarm.ringtone = settings.ringtone
            updatedAlarm.isCustomRingtone = settings.isCustomRingtone
            updatedAlarm.customRingtoneURL = settings.customRingtoneURL
            updatedAlarm.snooze = settings.snooze
            
            alarms[index] = updatedAlarm
            
            cancelNotifications(for: alarms[index])
            scheduleNotifications(for: alarms[index])
            
            saveAlarms()
        }
    }
    
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            // Cancel existing notifications
            cancelNotifications(for: alarms[index])
            
            // Update the alarm
            alarms[index] = alarm
            
            // Schedule new notifications
            scheduleNotifications(for: alarms[index])
            
            // Save changes
            saveAlarms()
            print("Alarm updated: \(alarm.id)")
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
        activeModal = .editSingleAlarm
    }
    
    func handleEditInstance(event: Alarm, instance: AlarmInstance) {
        selectedEvent = event
        selectedInstance = instance
        alarmDate = instance.date
        alarmTime = instance.time
        alarmDescription = instance.description
        instanceRepeatInterval = instance.repeatInterval
        activeModal = .editInstance
    }
    
    func handleAddInstance(event: Alarm) {
        selectedEvent = event
        // Add this line to copy existing instances:
        eventInstances = event.instances ?? []
        alarmDate = Date()
        alarmTime = Date()
        alarmDescription = ""
        instanceRepeatInterval = .none
        activeModal = .addInstance
    }
    
    func deleteInstance(eventId: String, instanceId: String) {
        if let eventIndex = alarms.firstIndex(where: { $0.id == eventId }), var instances = alarms[eventIndex].instances {
            // Cancel notifications for this specific instance
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let instanceRequests = requests.filter {
                    $0.identifier.contains(eventId) && $0.identifier.contains(instanceId)
                }
                
                let identifiers = instanceRequests.map { $0.identifier }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                print("Removed \(identifiers.count) notifications for instance \(instanceId)")
            }
            
            // Remove instance from array
            instances.removeAll { $0.id == instanceId }
            alarms[eventIndex].instances = instances
            alarms[eventIndex].times = instances.map { $0.time }
            alarms[eventIndex].dates = instances.map { $0.date }
            
            saveAlarms()
            
            if let selectedEvent = selectedEvent, selectedEvent.id == eventId {
                eventInstances = instances
            }
            
            // Reschedule notifications for the remaining instances
            if !instances.isEmpty {
                scheduleNotifications(for: alarms[eventIndex])
            }
        }
    }
}
