import Foundation
import SwiftUI
import UserNotifications

// Define ModalState enum
enum ModalState: String {
    case none
    case eventAlarm
    case settings
    case addInstance
    case editInstance
    // Removed: singleAlarm and editSingleAlarm
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
    
    // New property to track active alarms
    @Published var activeAlarm: Alarm?
    
    // Timer for checking active alarms periodically
    private var alarmCheckTimer: Timer?
    // Flag to control alarm checking
    private var alarmChecksEnabled: Bool = true
    
    // NEW: Cooldown system to prevent rapid reactivation
    private var lastDismissalTime: Date? = nil
    private let dismissalCooldownPeriod: TimeInterval = 60 // 1 minute cooldown
    
    let availableRingtones: [String] = [
        "default.mp3",
        "ringtone1.mp3",
        "ringtone2.mp3",
        "ringtone3.mp3",
        "ringtone4.mp3",
        "ringtone5.mp3"
    ]
    
    init() {
        self.settings = AlarmSettings(
            ringtone: availableRingtones.first ?? "default.mp3",
            isCustomRingtone: false,
            customRingtoneURL: nil,
            snooze: false
        )
        loadAlarms()
        
        // Set up a timer to periodically check for active alarms
        self.alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            if self?.alarmChecksEnabled == true {
                self?.checkForActiveAlarms()
            }
        }
        
        // Ensure the timer runs even when scrolling
        if let timer = self.alarmCheckTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // Listen for notification center notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationReceived),
            name: NSNotification.Name("AlarmNotificationReceived"),
            object: nil
        )
        
        // Add observers for temporarily disabling alarm checks
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(temporarilyDisableAlarmChecks),
            name: NSNotification.Name("TemporarilyDisableAlarmChecks"),
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resumeAlarmChecks),
            name: NSNotification.Name("ResumeAlarmChecks"),
            object: nil
        )
    }
    
    deinit {
        // Clean up timer and observers
        alarmCheckTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // UPDATED: Much more aggressive alarm disabling
    @objc private func temporarilyDisableAlarmChecks() {
        print("🛑 FORCEFULLY DISABLING ALL ALARM SYSTEMS")
        
        // Set global dismissal time for cooldown
        lastDismissalTime = Date()
        
        // Stop EVERYTHING
        alarmChecksEnabled = false
        
        // Kill the timer completely
        alarmCheckTimer?.invalidate()
        alarmCheckTimer = nil
        
        // Force clear active alarm
        DispatchQueue.main.async {
            // Stop any playing sounds
            AudioPlayerService.shared.stopAlarmSound()
            
            // Force nil the active alarm
            self.activeAlarm = nil
            
            // Do NOT clear pending notifications - this is what's breaking snooze
            // We'll keep the delivered notifications though
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            // Force UI refresh
            self.objectWillChange.send()
        }
        
        print("⚠️ ALARM SYSTEMS TEMPORARILY DISABLED - WILL RESUME FOR SNOOZE")
        
        // Automatically resume alarm checks after a short period
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("ResumeAlarmChecks"),
                object: nil
            )
        }
    }
    
    @objc private func resumeAlarmChecks() {
        // No changes needed here
        // Check for snooze-related notifications first
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let snoozeRequests = requests.filter {
                let isSnooze = ($0.content.userInfo["isSnooze"] as? Bool) ?? false
                return isSnooze
            }
            
            // IMPORTANT: If we have pending snooze notifications, ALWAYS resume checks
            if !snoozeRequests.isEmpty {
                print("⚠️ Pending snooze notifications found - forcing alarm checks to resume")
                self.lastDismissalTime = nil  // Clear cooldown timer completely
                self.alarmChecksEnabled = true
                
                // Recreate timer if needed
                if self.alarmCheckTimer == nil {
                    self.alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                        self?.checkForActiveAlarms()
                    }
                    if let timer = self.alarmCheckTimer {
                        RunLoop.main.add(timer, forMode: .common)
                    }
                    print("⚡ Alarm checks forcibly resumed for snooze notifications")
                }
                return
            }
            
            // Original cooldown check for non-snooze scenarios
            if let lastDismissal = self.lastDismissalTime,
               Date().timeIntervalSince(lastDismissal) < 10 { // 10 seconds instead of 60
                print("⏱️ Not resuming alarm checks - still in cooldown period")
                return
            }
            
            // Resume alarm checks normally
            self.alarmChecksEnabled = true
            
            if self.alarmCheckTimer == nil {
                self.alarmCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                    self?.checkForActiveAlarms()
                }
                if let timer = self.alarmCheckTimer {
                    RunLoop.main.add(timer, forMode: .common)
                }
                print("⚡ Alarm checks resumed")
            }
        }
    }
    
    @objc func handleNotificationReceived(_ notification: Notification) {
        // No changes needed here
        if let alarmID = notification.userInfo?["alarmID"] as? String,
           let alarm = alarms.first(where: { $0.id == alarmID }) {
            DispatchQueue.main.async {
                self.activeAlarm = alarm
                AudioPlayerService.shared.playAlarmSound(for: alarm)
            }
        }
    }
    
    func checkForActiveAlarms() {
        // No changes needed here
        // Force check for snooze notifications first
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let snoozeRequests = requests.filter {
                ($0.content.userInfo["isSnooze"] as? Bool) ?? false
            }
            
            if !snoozeRequests.isEmpty && !self.alarmChecksEnabled {
                print("⚠️ FOUND PENDING SNOOZE NOTIFICATIONS - FORCIBLY ENABLING ALARM CHECKS")
                self.alarmChecksEnabled = true
                
                // Remove any cooldown that might be active
                self.lastDismissalTime = nil
            }
        }
        
        // COOLDOWN CHECK: Don't reactivate alarms too soon after dismissal
        if let lastDismissal = lastDismissalTime,
           Date().timeIntervalSince(lastDismissal) < dismissalCooldownPeriod {
            print("🧊 Alarm reactivation prevented - in cooldown period")
            return // Skip all checks during cooldown period
        }
        
        if !alarmChecksEnabled {
            return // Skip if checks are disabled
        }
        
        // First check if any sound is currently playing
        for alarm in alarms {
            if AudioPlayerService.shared.isPlaying(alarmId: alarm.id) {
                DispatchQueue.main.async {
                    // If sound is playing but no active alarm is set, set it
                    if self.activeAlarm == nil {
                        print("Found active alarm \(alarm.name) based on audio playing")
                        self.activeAlarm = alarm
                    }
                }
                return
            }
        }
        
        // Then check notification center for any active notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let alarmNotifications = notifications.filter { notification in
                notification.request.content.categoryIdentifier == "ALARM_CATEGORY"
            }
            
            if let firstAlarmNotification = alarmNotifications.first,
               let alarmID = firstAlarmNotification.request.content.userInfo["alarmID"] as? String,
               let alarm = self.alarms.first(where: { $0.id == alarmID }) {
                
                // Found an active alarm notification
                DispatchQueue.main.async {
                    if !self.alarmChecksEnabled {
                        return // Double-check in case it was disabled during async operation
                    }
                    
                    print("Found active alarm \(alarm.name) from notification center")
                    if self.activeAlarm == nil || self.activeAlarm?.id != alarm.id {
                        self.activeAlarm = alarm
                        AudioPlayerService.shared.playAlarmSound(for: alarm)
                    }
                }
            }
        }
        
        // Finally, check for any pending snooze notifications that might be close to firing
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let snoozeNotifications = requests.filter { request in
                guard let isSnooze = request.content.userInfo["isSnooze"] as? Bool, isSnooze else {
                    return false
                }
                
                // Check if this notification is due to fire soon (within next 10 seconds)
                if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger,
                   let fireDate = trigger.nextTriggerDate(),
                   fireDate.timeIntervalSinceNow < 10 {
                    return true
                }
                
                return false
            }
            
            // If we have imminent snooze notifications, make sure system is ready
            if !snoozeNotifications.isEmpty {
                print("⏰ Found \(snoozeNotifications.count) snooze notifications about to fire")
                
                // Ensure alarm checks are enabled
                if !self.alarmChecksEnabled {
                    self.alarmChecksEnabled = true
                    print("⚠️ Forcibly enabling alarm checks for imminent snooze")
                }
            }
        }
    }
    
    // Function to mark an alarm as inactive
    func markAlarmAsInactive(_ alarmID: String) {
        // No changes needed here
        DispatchQueue.main.async {
            if self.activeAlarm?.id == alarmID {
                print("Marking alarm \(alarmID) as inactive")
                self.activeAlarm = nil
                
                // Force UI refresh
                self.objectWillChange.send()
            }
        }
    }
    
    func presentDocumentPicker() {
        // No changes needed here
        // Implementation for document picker
    }
    
    func handleSelectedAudioFile(url: URL) {
        // No changes needed here
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
    
    // UPDATED: Convert single alarms to event alarms when loading
    func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: "alarms") {
            if var decoded = try? JSONDecoder().decode([Alarm].self, from: data) {
                // Convert any single alarms to event alarms
                for i in 0..<decoded.count {
                    if decoded[i].instances == nil || decoded[i].instances!.isEmpty {
                        // This is a single alarm - convert it to event alarm
                        let newInstance = AlarmInstance(
                            id: UUID().uuidString,
                            date: decoded[i].dates.first ?? Date(),
                            time: decoded[i].times.first ?? Date(),
                            description: decoded[i].description,
                            repeatInterval: .none
                        )
                        decoded[i].instances = [newInstance]
                    }
                }
                
                self.alarms = decoded
                print("Alarms loaded: \(decoded.count)")
                
                // Schedule notifications for all loaded alarms
                for alarm in self.alarms {
                    if alarm.status {
                        self.scheduleNotifications(for: alarm)
                    }
                }
                
                // Save back the converted alarms
                saveAlarms()
                return
            }
        }
        self.alarms = []
    }
    
    func saveAlarms() {
        // No changes needed here
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: "alarms")
            print("Alarms saved: \(alarms.count)")
        }
    }
    
    // UPDATED: Removed single alarm path, only event alarms are created
    func addAlarm() {
        let newId = UUID().uuidString
        
        // Only create event alarms
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
        
        saveAlarms()
        scheduleNotifications(for: alarms.last!)
        resetFields()
    }
    
    func resetFields() {
        // No changes needed here
        alarmName = ""
        alarmDescription = ""
        alarmTime = Date()
        alarmDate = Date()
        eventInstances = []
        instanceRepeatInterval = .none
    }
    
    func toggleAlarmStatus(for alarm: Alarm) {
        // No changes needed here
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
                
                // Also clear active alarm if it's being turned off
                if activeAlarm?.id == alarm.id {
                    activeAlarm = nil
                }
            }
            
            // Save the updated state immediately
            saveAlarms()
            
            // Verify the save happened correctly
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.verifyAlarmStatus(id: alarm.id, expectedStatus: newStatus)
            }
        }
    }
    
    private func verifyAlarmStatus(id: String, expectedStatus: Bool) {
        // No changes needed here
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
    
    func scheduleNotifications(for alarm: Alarm) {
        // No changes needed here
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
        // No changes needed here
        // Generate unique prefix for all notifications of this instance
        let instancePrefix = "INSTANCE_\(index+1)_\(alarm.id)_"
        
        // Create content with instance-specific title
        let content = UNMutableNotificationContent()
        content.title = "\(alarm.name): \(instance.description)"
        content.body = "Alarm is ringing"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        
        // Setup for notification actions
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Set as time sensitive for higher priority
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // Add unique identifiers in userInfo
        content.userInfo = [
            "alarmID": alarm.id,
            "instanceID": instance.id,
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
                
                // Schedule follow-up notifications (to make it persistent)
                scheduleFollowUpNotifications(for: alarm, instance: instance, baseTime: startDate)
                
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
                    
                    // Schedule follow-up notifications for this occurrence
                    scheduleFollowUpNotifications(for: alarm, instance: instance, baseTime: date)
                }
            }
        }
    }
    
    private func scheduleFollowUpNotifications(for alarm: Alarm, instance: AlarmInstance, baseTime: Date) {
        // No changes needed here
        // Always schedule follow-ups for better persistence
        
        // Schedule 3 follow-up notifications at 1-minute intervals
        for i in 1...3 {
            let followUpContent = UNMutableNotificationContent()
            followUpContent.title = "⏰ \(alarm.name) - Still ringing"
            followUpContent.body = instance.description
            followUpContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
            followUpContent.categoryIdentifier = "ALARM_CATEGORY"
            
            // Add same user info for identification
            followUpContent.userInfo = [
                "alarmID": alarm.id,
                "instanceID": instance.id,
                "isFollowUp": true
            ]
            
            if #available(iOS 15.0, *) {
                followUpContent.interruptionLevel = .timeSensitive
            }
            
            let followUpTime = Calendar.current.date(byAdding: .minute, value: i, to: baseTime)!
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: followUpTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let identifier = "\(alarm.id)_\(instance.id)_followup_\(i)"
            
            scheduleNotification(content: followUpContent, trigger: trigger, identifier: identifier)
        }
    }

    private func scheduleNotification(content: UNMutableNotificationContent, trigger: UNNotificationTrigger, identifier: String) {
        // No changes needed here
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling notification: \(identifier) - \(error.localizedDescription)")
            } else {
                if let calendarTrigger = trigger as? UNCalendarNotificationTrigger,
                   let date = Calendar.current.date(from: calendarTrigger.dateComponents) {
                    print("✅ Scheduled notification: \(identifier) at \(self.formatDateTime(date))")
                } else {
                    print("✅ Scheduled notification: \(identifier)")
                }
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        // No changes needed here
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
    
    func cancelNotifications(for alarm: Alarm) {
        // No changes needed here
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
        
        // Also remove delivered notifications for this alarm
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let deliveredIds = notifications
                .filter { $0.request.identifier.contains(alarm.id) }
                .map { $0.request.identifier }
            
            if !deliveredIds.isEmpty {
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: deliveredIds)
                print("Removed \(deliveredIds.count) delivered notifications for alarm \(alarm.id)")
            }
        }
    }
    
    func checkPendingNotifications() {
        // No changes needed here
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("📱 Total pending notifications: \(requests.count)")
            
            // Group by alarm
            let alarmGroups = Dictionary(grouping: requests) { request -> String in
                if let alarmID = request.content.userInfo["alarmID"] as? String {
                    return alarmID
                }
                
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
        // No changes needed here
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("Cleared all notifications")
    }
    
    func deleteAlarm(at indexSet: IndexSet) {
        // No changes needed here
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
            
            // Clear active alarm if it's one of the alarms being deleted
            if activeAlarm?.id == alarm.id {
                activeAlarm = nil
            }
        }
        
        // Remove alarms from the array
        alarms.remove(atOffsets: indexSet)
        saveAlarms()
    }
    
    func handleOpenSettings(alarm: Alarm) {
        // No changes needed here
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
        // No changes needed here
        selectedAlarm = nil
        activeModal = .none
    }
    
    func updateAlarmSettings() {
        // No changes needed here
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
        // No changes needed here
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
        // No changes needed here
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
    
    // UPDATED: Modify to convert single alarms to event alarms
    func handleEditSingleAlarm(alarm: Alarm) {
        // Convert to event alarm editing flow
        selectedEvent = alarm
        alarmName = alarm.name
        alarmDescription = alarm.description
        
        // Convert existing instances or create a new instance if needed
        if let instances = alarm.instances, !instances.isEmpty {
            eventInstances = instances
        } else {
            // Create a new instance from the first time/date
            let newInstance = AlarmInstance(
                id: UUID().uuidString,
                date: alarm.dates.first ?? Date(),
                time: alarm.times.first ?? Date(),
                description: alarm.description,
                repeatInterval: .none
            )
            eventInstances = [newInstance]
        }
        
        settings = AlarmSettings(
            ringtone: alarm.ringtone,
            isCustomRingtone: alarm.isCustomRingtone,
            customRingtoneURL: alarm.customRingtoneURL,
            snooze: alarm.snooze
        )
        
        // Use eventAlarm modal instead of editSingleAlarm
        activeModal = .eventAlarm
    }
    
    func handleEditInstance(event: Alarm, instance: AlarmInstance) {
        // No changes needed here
        selectedEvent = event
        selectedInstance = instance
        alarmDate = instance.date
        alarmTime = instance.time
        alarmDescription = instance.description
        instanceRepeatInterval = instance.repeatInterval
        activeModal = .editInstance
    }
    
    func handleAddInstance(event: Alarm) {
        // No changes needed here
        selectedEvent = event
        // Copy existing instances to preserve them
        eventInstances = event.instances ?? []
        alarmDate = Date()
        alarmTime = Date()
        alarmDescription = ""
        instanceRepeatInterval = .none
        activeModal = .addInstance
    }
    
    func deleteInstance(eventId: String, instanceId: String) {
        // No changes needed here
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
