import Foundation
import UserNotifications
import RealmSwift
import AVFoundation

class AlarmViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var alarms: [Alarm] = []
    @Published var activeAlarm: Alarm?
    @Published var activeInstance: AlarmInstance?
    @Published var isCheckingDisabled = false
    @Published var alarmDate: Date = Date()
    @Published var alarmTime: Date = Date()
    @Published var alarmName: String = ""
    @Published var alarmDescription: String = ""
    @Published var instanceRepeatInterval: RepeatInterval = .none
    @Published var eventInstances: [AlarmInstance] = []
    @Published var selectedAlarm: Alarm?
    @Published var selectedEvent: Alarm?
    @Published var selectedInstance: AlarmInstance?
    
    // Modal handling
    enum ModalType {
        case none
        case eventAlarm
        case settings
        case addInstance
        case editInstance
    }
    @Published var activeModal: ModalType = .none
    
    // Settings
    struct AlarmSettings {
        var ringtone: String = "ringtone1.mp3"
        var snooze: Bool = true
    }
    @Published var settings = AlarmSettings()
    let availableRingtones: [String] = ["ringtone1.mp3", "ringtone2.mp3", "ringtone3.mp3", "ringtone4.mp3", "ringtone5.mp3"]
    
    // MARK: - Private properties
    private var checkTimer: Timer?
    private let realm = try! Realm()
    
    // MARK: - Initialization
    init() {
        loadAlarms()
        setupObservers()
        startCheckTimer()
    }
    
    deinit {
        checkTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe notifications to temporarily disable alarm checks
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTemporaryDisable),
            name: NSNotification.Name("TemporarilyDisableAlarmChecks"),
            object: nil
        )
        
        // Observe notifications to resume alarm checks
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleResumeChecks),
            name: NSNotification.Name("ResumeAlarmChecks"),
            object: nil
        )
        
        // Observe alarm notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAlarmNotification),
            name: NSNotification.Name("AlarmNotificationReceived"),
            object: nil
        )
    }
    
    @objc private func handleTemporaryDisable() {
        isCheckingDisabled = true
        print("Alarm checks temporarily disabled")
    }
    
    @objc private func handleResumeChecks() {
        isCheckingDisabled = false
        print("Alarm checks resumed")
    }
    
    @objc private func handleAlarmNotification(_ notification: Notification) {
        if let alarmID = notification.userInfo?["alarmID"] as? String {
            // Find the alarm
            if let alarm = alarms.first(where: { $0.id == alarmID }) {
                DispatchQueue.main.async {
                    self.activeAlarm = alarm
                    
                    // Also set activeInstance if instanceID is provided
                    if let instanceID = notification.userInfo?["instanceID"] as? String,
                       let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
                        self.activeInstance = instance
                        print("Active instance set: \(instance.id)")
                    } else {
                        print("No instance ID found in notification")
                    }
                }
            }
        }
    }
    
    private func startCheckTimer() {
        // Create a timer that periodically checks for active alarms
        checkTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkForActiveAlarms()
        }
    }
    
    // MARK: - Data Management
    // Load alarms from Realm database
    func loadAlarms() {
        let realmAlarms = realm.objects(RealmAlarm.self)
        alarms = realmAlarms.map { $0.toAlarm() }
        print("Loaded \(alarms.count) alarms from database")
    }
    
    // Save alarms to Realm database
    func saveAlarms() {
        do {
            let realm = try Realm()
            
            try realm.write {
                // Instead of deleting all existing alarms, update them
                for alarm in self.alarms {
                    if let existingAlarm = realm.object(ofType: RealmAlarm.self, forPrimaryKey: alarm.id) {
                        // Update existing alarm
                        existingAlarm.name = alarm.name
                        existingAlarm.desc = alarm.description
                        existingAlarm.status = alarm.status
                        existingAlarm.ringtone = alarm.ringtone
                        existingAlarm.isCustomRingtone = alarm.isCustomRingtone
                        existingAlarm.customRingtoneURLString = alarm.customRingtoneURL?.absoluteString
                        existingAlarm.snooze = alarm.snooze
                        
                        // Clear existing times and dates
                        existingAlarm.times.removeAll()
                        existingAlarm.dates.removeAll()
                        
                        // Add new times and dates
                        existingAlarm.times.append(objectsIn: alarm.times)
                        existingAlarm.dates.append(objectsIn: alarm.dates)
                        
                        // Handle instances
                        updateInstances(for: existingAlarm, with: alarm.instances, in: realm)
                    } else {
                        // Create new alarm with realm reference
                        let realmAlarm = RealmAlarm(alarm: alarm, realm: realm)
                        realm.add(realmAlarm)
                    }
                }
                
                // Delete alarms that no longer exist in the model
                let realmAlarms = realm.objects(RealmAlarm.self)
                let modelAlarmIds = Set(self.alarms.map { $0.id })
                
                for realmAlarm in realmAlarms {
                    if !modelAlarmIds.contains(realmAlarm.id) {
                        realm.delete(realmAlarm)
                    }
                }
            }
            
            print("Saved \(alarms.count) alarms to database")
        } catch {
            print("Error saving alarms: \(error)")
        }
    }
    
    // Helper method to update instances
    private func updateInstances(for realmAlarm: RealmAlarm, with instances: [AlarmInstance]?, in realm: Realm) {
        // Get current instance IDs
        let existingIds = Set(realmAlarm.instances.map { $0.id })
        let newIds = Set(instances?.map { $0.id } ?? [])
        
        // Remove instances that no longer exist
        for instance in realmAlarm.instances.freeze() {  // Use freeze() to avoid runtime errors
            if !newIds.contains(instance.id) {
                if let idx = realmAlarm.instances.index(matching: { $0.id == instance.id }) {
                    realmAlarm.instances.remove(at: idx)
                    
                    // Also delete the instance from Realm if no other alarms reference it
                    if let instanceToDelete = realm.object(ofType: RealmAlarmInstance.self, forPrimaryKey: instance.id) {
                        realm.delete(instanceToDelete)
                    }
                }
            }
        }
        
        // Add or update instances
        if let instances = instances {
            for instance in instances {
                if let existingInstance = realm.object(ofType: RealmAlarmInstance.self, forPrimaryKey: instance.id) {
                    // Update existing instance
                    existingInstance.date = instance.date
                    existingInstance.time = instance.time
                    existingInstance.desc = instance.description
                    existingInstance.repeatInterval = instance.repeatInterval.rawValue
                    
                    // Add to alarm if not already present
                    if !realmAlarm.instances.contains(where: { $0.id == instance.id }) {
                        realmAlarm.instances.append(existingInstance)
                    }
                } else {
                    // Create new instance
                    let realmInstance = RealmAlarmInstance(instance: instance)
                    realmAlarm.instances.append(realmInstance)
                }
            }
        }
    }
    
    // Add a new alarm
    func addAlarm() {
        let newId = UUID().uuidString
        
        // Create a new alarm with event instances
        let newAlarm = Alarm(
            id: newId,
            name: alarmName,
            description: alarmDescription,
            times: eventInstances.map { $0.time },
            dates: eventInstances.map { $0.date },
            instances: eventInstances,
            status: true,
            ringtone: settings.ringtone,
            isCustomRingtone: false,
            customRingtoneURL: nil,
            snooze: settings.snooze
        )
        
        alarms.append(newAlarm)
        saveAlarms()
        scheduleAlarmNotifications(for: newAlarm)
        resetFields()
        
        // Debug print after creating a new alarm
        debugPrintAlarmInstances()
    }
    
    // Delete an alarm
    func deleteAlarm(at indexSet: IndexSet) {
        for index in indexSet {
            let alarm = alarms[index]
            cancelAlarmNotifications(for: alarm.id)
        }
        
        alarms.remove(atOffsets: indexSet)
        saveAlarms()
    }
    
    // Update an existing alarm
    func updateAlarm(_ alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            // Cancel existing notifications
            cancelAlarmNotifications(for: alarm.id)
            
            // Update the alarm
            alarms[index] = alarm
            saveAlarms()
            
            // Schedule new notifications
            scheduleAlarmNotifications(for: alarm)
            
            // Debug print after updating
            debugPrintAlarmInstances()
        }
    }
    
    // Mark an alarm as inactive (when dismissed)
    func markAlarmAsInactive(_ alarmID: String) {
        if let index = alarms.firstIndex(where: { $0.id == alarmID }) {
            var updatedAlarm = alarms[index]
            updatedAlarm.status = false  // Set to inactive
            alarms[index] = updatedAlarm
            
            // Also clear active alarm if it matches
            if activeAlarm?.id == alarmID {
                activeAlarm = nil
                activeInstance = nil
            }
            
            saveAlarms()
        }
    }
    
    // Mark a specific instance as inactive
    func markInstanceAsInactive(alarmID: String, instanceID: String) {
        if let alarmIndex = alarms.firstIndex(where: { $0.id == alarmID }),
           let instances = alarms[alarmIndex].instances,
           let instanceIndex = instances.firstIndex(where: { $0.id == instanceID }) {
            
            // Create a mutable copy of the instances array
            var updatedInstances = instances
            
            // Just update the instance with current values (we'll mark through active states)
            var updatedInstance = updatedInstances[instanceIndex]
            updatedInstances[instanceIndex] = updatedInstance
            
            // Update the alarm with the modified instances
            var updatedAlarm = alarms[alarmIndex]
            updatedAlarm.instances = updatedInstances
            alarms[alarmIndex] = updatedAlarm
            
            // Clear active instance if it matches the one being marked inactive
            if activeAlarm?.id == alarmID && activeInstance?.id == instanceID {
                activeInstance = nil
                
                // Check if other instances are still active before clearing active alarm
                if !instances.contains(where: { $0.id != instanceID }) {
                    activeAlarm = nil
                }
            }
            
            // Cancel any notifications for this specific instance
            cancelInstanceNotifications(alarmID: alarmID, instanceID: instanceID)
            
            // Save changes to database
            saveAlarms()
            
            print("Marked instance \(instanceID) as inactive for alarm \(alarmID)")
        }
    }
    
    // Toggle alarm active status
    func toggleAlarmStatus(for alarm: Alarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            var updatedAlarm = alarms[index]
            updatedAlarm.status.toggle()
            
            if updatedAlarm.status {
                // If turning on, schedule notifications
                scheduleAlarmNotifications(for: updatedAlarm)
            } else {
                // If turning off, cancel notifications
                cancelAlarmNotifications(for: updatedAlarm.id)
            }
            
            alarms[index] = updatedAlarm
            saveAlarms()
        }
    }
    
    // MARK: - Notification Management
    // Cancel notifications for a specific alarm
    private func cancelAlarmNotifications(for alarmID: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmID) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled \(identifiersToRemove.count) notifications for alarm \(alarmID)")
        }
    }
    
    // Specific method to cancel instance notifications
    private func cancelInstanceNotifications(alarmID: String, instanceID: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { request in
                    return request.identifier.contains(alarmID) &&
                    request.identifier.contains(instanceID)
                }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled \(identifiersToRemove.count) notifications for instance \(instanceID)")
        }
    }
    
    // Schedule notifications for an alarm
    func scheduleAlarmNotifications(for alarm: Alarm) {
        guard alarm.status else {
            print("Alarm \(alarm.id) is disabled, not scheduling notifications")
            return
        }
        
        if let instances = alarm.instances, !instances.isEmpty {
            // This is an event alarm with specific instances
            scheduleEventAlarmNotifications(for: alarm, instances: instances)
        } else {
            // This is a regular, repeating alarm
            scheduleRegularAlarmNotifications(for: alarm)
        }
    }
    
    // Schedule notifications for an event alarm with specific instances
    private func scheduleEventAlarmNotifications(for alarm: Alarm, instances: [AlarmInstance]) {
        print("⚠️ Scheduling notifications for \(instances.count) instances in alarm: \(alarm.id)")
        let calendar = Calendar.current
        
        for (index, instance) in instances.enumerated() {
            // Skip if the instance time is in the past
            let instanceDateTime = combineDateTime(date: instance.date, time: instance.time)
            if instanceDateTime < Date() {
                print("⚠️ Instance \(instance.id) is in the past, skipping notification")
                continue
            }
            
            let content = UNMutableNotificationContent()
            content.title = alarm.name
            content.body = instance.description.isEmpty ? alarm.description : instance.description
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
            content.categoryIdentifier = "ALARM_CATEGORY"
            
            // Enhanced userInfo with more data to assist debugging
            content.userInfo = [
                "alarmID": alarm.id,
                "instanceID": instance.id,
                "instanceIndex": index,
                "isInstance": true,
                "scheduledTime": instanceDateTime.timeIntervalSince1970
            ]
            
            if #available(iOS 15.0, *) {
                content.interruptionLevel = .timeSensitive
            }
            
            // Create a calendar-based trigger for the specific date/time
            let dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: instanceDateTime
            )
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: dateComponents,
                repeats: false
            )
            
            // IMPORTANT: More unique identifier structure that separates instances clearly
            let identifier = "alarm_\(alarm.id)_instance_\(instance.id)_time_\(Int(instanceDateTime.timeIntervalSince1970))"
            
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            
            // Debug log before scheduling
            print("⚠️ Scheduling instance \(index) (ID: \(instance.id)) at \(instanceDateTime)")
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error scheduling notification for instance \(instance.id): \(error)")
                } else {
                    print("✅ Successfully scheduled notification for instance \(instance.id) at \(instanceDateTime)")
                }
            }
            
            // Also schedule follow-up notifications for persistence
            scheduleInstanceFollowUps(for: alarm, instance: instance, baseTime: instanceDateTime, index: index)
        }
        
        // Debug log - check what notifications are pending
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let alarmRequests = requests.filter { $0.content.userInfo["alarmID"] as? String == alarm.id }
            print("⚠️ Total pending notifications for alarm \(alarm.id): \(alarmRequests.count)")
            
            // Log the details of each pending notification
            for (index, request) in alarmRequests.enumerated() {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    print("⚠️ Notification \(index): ID=\(request.identifier), Fire date=\(calendar.date(from: trigger.dateComponents) ?? Date())")
                }
            }
        }
    }
    
    // Schedule follow-up notifications for an instance
    private func scheduleInstanceFollowUps(for alarm: Alarm, instance: AlarmInstance, baseTime: Date, index: Int) {
        // Schedule 3 follow-up notifications at 1-minute intervals
        for i in 1...3 {
            let followUpContent = UNMutableNotificationContent()
            followUpContent.title = "⏰ \(alarm.name) - Still Active"
            followUpContent.body = instance.description.isEmpty ? alarm.description : instance.description
            followUpContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
            followUpContent.categoryIdentifier = "ALARM_CATEGORY"
            
            // Include instance ID in userInfo with the same format
            followUpContent.userInfo = [
                "alarmID": alarm.id,
                "instanceID": instance.id,
                "instanceIndex": index,
                "isFollowUp": true
            ]
            
            if #available(iOS 15.0, *) {
                followUpContent.interruptionLevel = .timeSensitive
            }
            
            let followUpTime = Calendar.current.date(byAdding: .minute, value: i, to: baseTime)!
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: followUpTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let identifier = "alarm_\(alarm.id)_instance_\(instance.id)_followup_\(i)"
            
            let request = UNNotificationRequest(identifier: identifier, content: followUpContent, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling instance follow-up notification: \(error)")
                } else {
                    print("Scheduled instance follow-up notification #\(i) for \(followUpTime)")
                }
            }
        }
        
        // Backup notification
        let backupContent = UNMutableNotificationContent()
        backupContent.title = "⚠️ Backup: \(alarm.name)"
        backupContent.body = instance.description.isEmpty ? alarm.description : instance.description
        backupContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        backupContent.categoryIdentifier = "ALARM_CATEGORY"
        backupContent.userInfo = [
            "alarmID": alarm.id,
            "instanceID": instance.id,
            "instanceIndex": index,
            "isBackup": true
        ]
        
        if #available(iOS 15.0, *) {
            backupContent.interruptionLevel = .timeSensitive
        }
        
        let backupTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 60 * 3 + 15, // 3 min + 15 seconds
            repeats: false
        )
        
        let backupRequest = UNNotificationRequest(
            identifier: "alarm_\(alarm.id)_instance_\(instance.id)_backup",
            content: backupContent,
            trigger: backupTrigger
        )
        
        UNUserNotificationCenter.current().add(backupRequest) { error in
            if let error = error {
                print("Error scheduling ultimate backup notification: \(error)")
            } else {
                print("Ultimate backup notification scheduled")
            }
        }
    }
    
    // Schedule regular alarm notifications
    private func scheduleRegularAlarmNotifications(for alarm: Alarm) {
        for time in alarm.times {
            // Implementation depends on your regular alarm structure
            // This is a placeholder for where your regular alarm scheduling would go
            print("Scheduling regular alarm for \(time)")
        }
    }
    
    // Helper to combine date and time components
    private func combineDateTime(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
    
    // MARK: - Event Instances
    // Add instance to event instances array
    func addEventInstance() {
        let newInstance = AlarmInstance(
            id: UUID().uuidString,
            date: alarmDate,
            time: alarmTime,
            description: alarmDescription,
            repeatInterval: instanceRepeatInterval
        )
        
        eventInstances.append(newInstance)
        print("Added instance: \(newInstance.id) at \(alarmTime) on \(alarmDate)")
    }
    
    // Delete instance from a specific event
    func deleteInstance(eventId: String, instanceId: String) {
        // First cancel notifications for this instance
        cancelInstanceNotifications(alarmID: eventId, instanceID: instanceId)
        
        // Remove from the alarm
        if let alarmIndex = alarms.firstIndex(where: { $0.id == eventId }),
           var instances = alarms[alarmIndex].instances {
            instances.removeAll { $0.id == instanceId }
            
            var updatedAlarm = alarms[alarmIndex]
            updatedAlarm.instances = instances
            
            // Update the times and dates arrays if needed
            updatedAlarm.times = instances.map { $0.time }
            updatedAlarm.dates = instances.map { $0.date }
            
            alarms[alarmIndex] = updatedAlarm
            saveAlarms()
        }
    }
    
    // MARK: - UI Actions
    func handleEditSingleAlarm(alarm: Alarm) {
        selectedAlarm = alarm
        selectedEvent = alarm
        
        // Set fields for editing
        alarmName = alarm.name
        alarmDescription = alarm.description
        
        if let instances = alarm.instances, !instances.isEmpty {
            eventInstances = instances
        } else if !alarm.times.isEmpty {
            alarmTime = alarm.times[0]
            alarmDate = alarm.dates[0]
            
            // Create an instance based on the single alarm
            let instance = AlarmInstance(
                id: UUID().uuidString,
                date: alarmDate,
                time: alarmTime,
                description: alarm.description,
                repeatInterval: .none
            )
            eventInstances = [instance]
        }
        
        // Set settings
        settings.ringtone = alarm.ringtone
        settings.snooze = alarm.snooze
        
        // Open the event alarm modal
        activeModal = .eventAlarm
    }
    
    func handleOpenSettings(alarm: Alarm) {
        selectedAlarm = alarm
        
        // Set settings
        settings.ringtone = alarm.ringtone
        settings.snooze = alarm.snooze
        
        // Open settings modal
        activeModal = .settings
    }
    
    func handleAddInstance(event: Alarm) {
        selectedEvent = event
        
        // Default to today and the next hour
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        alarmDate = Date()
        alarmTime = nextHour
        alarmDescription = ""
        instanceRepeatInterval = .none
        
        // Set current event instances
        eventInstances = event.instances ?? []
        
        // Open add instance modal
        activeModal = .addInstance
    }
    
    func handleEditInstance(event: Alarm, instance: AlarmInstance) {
        selectedEvent = event
        selectedInstance = instance
        
        // Set fields for editing
        alarmDate = instance.date
        alarmTime = instance.time
        alarmDescription = instance.description
        instanceRepeatInterval = instance.repeatInterval
        
        // Open edit instance modal
        activeModal = .editInstance
    }
    
    // Update alarm settings
    func updateAlarmSettings() {
        if let alarm = selectedAlarm,
           let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            var updatedAlarm = alarms[index]
            
            // Update settings
            updatedAlarm.ringtone = settings.ringtone
            updatedAlarm.snooze = settings.snooze
            
            // Cancel existing notifications if needed
            cancelAlarmNotifications(for: alarm.id)
            
            // Update the alarm
            alarms[index] = updatedAlarm
            saveAlarms()
            
            // Reschedule notifications if the alarm is active
            if updatedAlarm.status {
                scheduleAlarmNotifications(for: updatedAlarm)
            }
        }
    }
    
    // Reset form fields
    func resetFields() {
        alarmName = ""
        alarmDescription = ""
        alarmDate = Date()
        alarmTime = Date()
        instanceRepeatInterval = .none
        selectedAlarm = nil
        selectedEvent = nil
        selectedInstance = nil
    }
    
    // MARK: - Alarm Active Checking
    /// Check for active alarms
    func checkForActiveAlarms() {
        // Skip checking if temporarily disabled
        if isCheckingDisabled {
            print("Alarm checks are disabled, skipping check")
            return
        }
        
        print("Checking for active alarms...")
        
        // If an alarm is already active, don't check again
        if activeAlarm != nil {
            print("An alarm is already active, skipping check")
            return
        }
        
        UNUserNotificationCenter.current().getDeliveredNotifications { [weak self] notifications in
            guard let self = self else { return }
            
            print("Found \(notifications.count) total delivered notifications")
            
            // Debug each notification
            for (index, notification) in notifications.enumerated() {
                let userInfo = notification.request.content.userInfo
                if let alarmID = userInfo["alarmID"] as? String {
                    print("Notification \(index): alarmID=\(alarmID), instanceID=\(userInfo["instanceID"] as? String ?? "none")")
                }
            }
            
            for notification in notifications {
                let userInfo = notification.request.content.userInfo
                if let alarmID = userInfo["alarmID"] as? String,
                   let alarm = self.alarms.first(where: { $0.id == alarmID }) {
                    
                    // Enhanced logging
                    print("Found active alarm: \(alarm.name) (ID: \(alarm.id))")
                    
                    DispatchQueue.main.async {
                        self.activeAlarm = alarm
                        
                        // Also set activeInstance if instanceID is provided
                        if let instanceID = userInfo["instanceID"] as? String,
                           let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
                            self.activeInstance = instance
                            print("Active instance set: \(instance.id)")
                        } else {
                            print("No instance ID found in notification")
                        }
                        
                        // Post notification to show alarm active view
                        NotificationCenter.default.post(
                            name: NSNotification.Name("AlarmNotificationReceived"),
                            object: nil,
                            userInfo: userInfo
                        )
                        
                        // Start playing alarm sound
                        AudioPlayerService.shared.playAlarmSound(for: alarm)
                    }
                    
                    print("Activated alarm: \(alarm.name)")
                    return
                }
            }
            
            print("No active alarms found")
        }
    }
    
    // MARK: - Debugging
    // Debug function - call when setting up alarms
    func debugPrintAlarmInstances() {
        print("\n======== ALARM INSTANCES DEBUG ========")
        for (alarmIndex, alarm) in alarms.enumerated() {
            print("ALARM #\(alarmIndex): \(alarm.name) (ID: \(alarm.id))")
            print("  Status: \(alarm.status ? "ACTIVE" : "INACTIVE")")
            
            if let instances = alarm.instances, !instances.isEmpty {
                print("  INSTANCES: \(instances.count)")
                for (instanceIndex, instance) in instances.enumerated() {
                    let dateTime = combineDateTime(date: instance.date, time: instance.time)
                    let isPast = dateTime < Date()
                    print("  - Instance #\(instanceIndex): \(instance.id)")
                    print("    Time: \(dateTime) [\(isPast ? "PAST" : "FUTURE")]")
                    print("    Description: \(instance.description)")
                    print("    Repeat: \(instance.repeatInterval.rawValue)")
                }
            } else {
                print("  NO INSTANCES")
            }
            print("  ---")
        }
        
        // Check pending notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("\n======== PENDING NOTIFICATIONS ========")
            print("TOTAL PENDING: \(requests.count)")
            
            // Group by alarm
            let alarmGroups = Dictionary(grouping: requests) { req in
                return req.content.userInfo["alarmID"] as? String ?? "unknown"
            }
            
            for (alarmID, requests) in alarmGroups {
                print("ALARM ID: \(alarmID)")
                print("  NOTIFICATIONS: \(requests.count)")
                
                // Sort by fire date
                let calendar = Calendar.current
                let sortedRequests = requests.compactMap { req -> (request: UNNotificationRequest, date: Date)? in
                    guard let trigger = req.trigger as? UNCalendarNotificationTrigger else { return nil }
                    return (req, calendar.date(from: trigger.dateComponents) ?? Date())
                }.sorted { $0.date < $1.date }
                
                for (index, item) in sortedRequests.enumerated() {
                    let req = item.request
                    let fireDate = item.date
                    let instanceID = req.content.userInfo["instanceID"] as? String ?? "none"
                    let isFollowUp = req.content.userInfo["isFollowUp"] as? Bool ?? false
                    let isBackup = req.content.userInfo["isBackup"] as? Bool ?? false
                    
                    print("  #\(index): Fire at \(fireDate)")
                    print("    Instance: \(instanceID)")
                    print("    Type: \(isFollowUp ? "Follow-up" : isBackup ? "Backup" : "Primary")")
                }
                print("  ---")
            }
            print("=====================================\n")
        }
    }
}
