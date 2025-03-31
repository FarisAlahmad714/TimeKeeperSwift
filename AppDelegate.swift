import UIKit
import UserNotifications
import AVFoundation
import FirebaseCore
import RealmSwift
import AudioToolbox

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var audioPlayer: AVAudioPlayer?
    static let sharedAlarmViewModel = AlarmViewModel() // Shared instance for database access
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure Firebase for analytics
        FirebaseApp.configure()
        
        // Configure Realm database
        configureRealm()
        
        // Register notification categories for actions
        registerNotificationCategories()
        
        // Request notification permissions (including critical alert if available)
        requestNotificationPermissions()
        
        // Set up notification handling
        UNUserNotificationCenter.current().delegate = self
        
        // Configure audio session for background playback
        setupAudioSession()
        
        // Load alarms from database on startup
        Self.sharedAlarmViewModel.loadAlarms()
        
        // Check for active alarms at startup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Self.sharedAlarmViewModel.checkForActiveAlarms()
        }
        
        // Add snooze notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSnoozeNotification(_:)),
            name: NSNotification.Name("SnoozeAlarmRequest"),
            object: nil
        )
        
        // Add dismiss notification observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDismissNotification(_:)),
            name: NSNotification.Name("DismissAlarmRequest"),
            object: nil
        )
        
        return true
    }
    
    // Handle snooze notification from UI
    @objc func handleSnoozeNotification(_ notification: Notification) {
        // First try to get the alarm object directly
        if let alarm = notification.userInfo?["alarm"] as? Alarm {
            print("✅ Received snooze notification with full alarm object")
            handleSnoozeWithAlarm(alarm, notification: notification)
        }
        // Fall back to looking up by ID
        else if let alarmID = notification.userInfo?["alarmID"] as? String,
                let alarm = Self.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmID }) {
            print("⚠️ Received snooze notification with ID only: \(alarmID)")
            handleSnoozeWithAlarm(alarm, notification: notification)
        }
        else {
            print("❌ CRITICAL ERROR: Received snooze notification but couldn't extract alarm information")
            // Try to stop all audio anyway
            AudioPlayerService.shared.stopAlarmSound()
            // Force remove all notifications as emergency measure
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }
    
    private func handleSnoozeWithAlarm(_ alarm: Alarm, notification: Notification) {
        print("Received snooze notification for alarm: \(alarm.id)")
        AudioPlayerService.shared.stopAlarmSound() // Stop the ringtone
        
        // Extract instanceID if present
        let instanceID = notification.userInfo?["instanceID"] as? String
        
        // Handle the snooze
        handleSnoozeAction(for: alarm, instanceID: instanceID)
        
        // Temporarily disable alarm checks
        NotificationCenter.default.post(
            name: NSNotification.Name("TemporarilyDisableAlarmChecks"),
            object: nil
        )
        
        // Force resume alarm checks after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            NotificationCenter.default.post(
                name: NSNotification.Name("ResumeAlarmChecks"),
                object: nil
            )
        }
        
        print("Alarm snoozed: \(alarm.id)")
    }
    
    // Similarly update handleDismissNotification
    @objc func handleDismissNotification(_ notification: Notification) {
        // First try to get the alarm object directly
        if let alarm = notification.userInfo?["alarm"] as? Alarm {
            print("✅ Received dismiss notification with full alarm object")
            handleDismissWithAlarm(alarm, notification: notification)
        }
        // Fall back to looking up by ID
        else if let alarmID = notification.userInfo?["alarmID"] as? String,
                let alarm = Self.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmID }) {
            print("⚠️ Received dismiss notification with ID only: \(alarmID)")
            handleDismissWithAlarm(alarm, notification: notification)
        }
        else {
            print("❌ CRITICAL ERROR: Received dismiss notification but couldn't extract alarm information")
            // Try to stop all audio anyway
            AudioPlayerService.shared.stopAlarmSound()
            // Force cancel all notifications as a last resort
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    private func handleDismissWithAlarm(_ alarm: Alarm, notification: Notification) {
        print("Received dismiss notification for alarm: \(alarm.id)")
        AudioPlayerService.shared.stopAlarmSound() // Stop the ringtone
        
        // Extract instanceID if present
        let instanceID = notification.userInfo?["instanceID"] as? String
        
        // Cancel notifications
        if let instanceID = instanceID {
            cancelRemainingNotifications(for: alarm.id, instanceID: instanceID)
            Self.sharedAlarmViewModel.markInstanceAsInactive(alarmID: alarm.id, instanceID: instanceID)
        } else {
            cancelRemainingNotifications(for: alarm.id)
            Self.sharedAlarmViewModel.markAlarmAsInactive(alarm.id)
        }
        
        // Post notification to disable alarm checks
        NotificationCenter.default.post(
            name: NSNotification.Name("TemporarilyDisableAlarmChecks"),
            object: nil
        )
        
        print("Alarm dismissed: \(alarm.id)")
    }
    
    // Add this emergency reset method to AppDelegate
    @objc func emergencyResetAllAlarms() {
        print("⚠️⚠️⚠️ EMERGENCY RESET ACTIVATED ⚠️⚠️⚠️")
        
        // Stop all audio
        AudioPlayerService.shared.stopAlarmSound()
        
        // Clear active alarm state
        Self.sharedAlarmViewModel.activeAlarm = nil
        Self.sharedAlarmViewModel.activeInstance = nil
        
        // Remove all notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // Resume normal operation
        NotificationCenter.default.post(
            name: NSNotification.Name("ResumeAlarmChecks"),
            object: nil
        )
        
        print("All alarms have been reset")
    }
    
    // Setup audio session for alarm sounds to play in background
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured for background playback")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // Request notification permissions including critical alerts
    private func requestNotificationPermissions() {
        // Note: criticalAlert requires special entitlement from Apple
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        
        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    // Register notification categories with actions
    private func registerNotificationCategories() {
        // Create snooze action only
        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze (5 min)",
            options: .authenticationRequired
        )
        
        // Create the category with ONLY the snooze action (no dismiss action)
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM_CATEGORY",
            actions: [snoozeAction], // Only include snooze action here
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Register the category
        UNUserNotificationCenter.current().setNotificationCategories([alarmCategory])
        print("Notification categories registered successfully")
    }
    
    // Configure Realm database
    private func configureRealm() {
        print("Configuring Realm database...")
        
        let config = Realm.Configuration(
            // Set the schema version
            schemaVersion: 1,
            
            // Set the migration block for future schema changes
            migrationBlock: { _, oldSchemaVersion in
                // We haven't migrated anything yet, so oldSchemaVersion == 0
                if oldSchemaVersion < 1 {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                }
            }
        )
        
        // Tell Realm to use this configuration for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        // Print Realm file location for debugging
        if let realmURL = config.fileURL {
            print("Realm database location: \(realmURL)")
        }
        
        // Try to initialize Realm to catch any configuration errors early
        do {
            _ = try Realm()
            print("Realm successfully configured!")
        } catch {
            print("Error initializing Realm: \(error.localizedDescription)")
        }
    }
    
    // Handle notifications while app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // Check if this is an alarm notification
        if let alarmID = userInfo["alarmID"] as? String {
            // Show alert options for presentation
            var options: UNNotificationPresentationOptions = [.banner]
            if #available(iOS 14.0, *) {
                options = [.banner, .list]
            } else {
                options = [.alert]
            }
            
            // Find the alarm
            if let alarm = Self.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmID }) {
                // Start playing alarm sound using AudioPlayerService
                AudioPlayerService.shared.playAlarmSound(for: alarm)
                
                // FIXED: Extract instance ID with fallback to notification identifier
                var instanceID = userInfo["instanceID"] as? String
                print("DEBUG - Notification received with userInfo: \(userInfo)")
                print("DEBUG - Notification identifier: \(notification.request.identifier)")
                
                // If instanceID is nil or doesn't match any instance, try to extract from identifier
                if instanceID == nil || (alarm.instances != nil && !alarm.instances!.contains(where: { $0.id == instanceID })) {
                    // Parse from identifier format: "alarm_[alarmID]_instance_[instanceID]_time_..."
                    let components = notification.request.identifier.components(separatedBy: "_")
                    if components.count >= 4 && components.firstIndex(of: "instance") != nil {
                        let instanceIndex = components.firstIndex(of: "instance")! + 1
                        if instanceIndex < components.count {
                            instanceID = components[instanceIndex]
                            print("DEBUG - Extracted instanceID from notification identifier: \(instanceID!)")
                        }
                    }
                }
                
                // Prepare notification userInfo
                var notificationUserInfo: [String: Any] = ["alarmID": alarmID]
                if let instanceID = instanceID {
                    notificationUserInfo["instanceID"] = instanceID
                }
                
                // Notify view model about active alarm
                DispatchQueue.main.async {
                    // Post notification to trigger active alarm view
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AlarmNotificationReceived"),
                        object: nil,
                        userInfo: notificationUserInfo
                    )
                    
                    // Set active alarm directly too
                    if Self.sharedAlarmViewModel.activeAlarm == nil {
                        Self.sharedAlarmViewModel.activeAlarm = alarm
                        // If we have an instance ID, also set the active instance
                        if let instanceID = instanceID,
                           let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
                            Self.sharedAlarmViewModel.activeInstance = instance
                            print("DEBUG - Set active instance: \(instance.id) with description: \(instance.description)")
                        }
                    }
                }
                
                print("Alarm notification received for: \(alarm.name)")
            }
            
            completionHandler(options)
        } else {
            // Default behavior for non-alarm notifications
            completionHandler([.banner, .sound])
        }
    }
    
    // Handle notification actions (snooze, dismiss)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Extract alarm ID and instance ID if present
        if let alarmID = userInfo["alarmID"] as? String {
            // FIXED: Extract instance ID with fallback to notification identifier
            var instanceID = userInfo["instanceID"] as? String
            print("DEBUG - Notification response with userInfo: \(userInfo)")
            print("DEBUG - Notification identifier: \(response.notification.request.identifier)")
            
            // Find the alarm
            if let alarm = Self.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmID }) {
                // If instanceID is nil or doesn't match any instance, try to extract from identifier
                if instanceID == nil || (alarm.instances != nil && !alarm.instances!.contains(where: { $0.id == instanceID })) {
                    // Parse from identifier format: "alarm_[alarmID]_instance_[instanceID]_time_..."
                    let components = response.notification.request.identifier.components(separatedBy: "_")
                    if components.count >= 4 && components.firstIndex(of: "instance") != nil {
                        let instanceIndex = components.firstIndex(of: "instance")! + 1
                        if instanceIndex < components.count {
                            instanceID = components[instanceIndex]
                            print("DEBUG - Extracted instanceID from notification identifier: \(instanceID!)")
                        }
                    }
                }
                
                // Set active alarm here too - this helps when notification is tapped
                if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                    DispatchQueue.main.async {
                        Self.sharedAlarmViewModel.activeAlarm = alarm
                        
                        // If we have an instance ID, also set the active instance
                        if let instanceID = instanceID,
                           let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
                            Self.sharedAlarmViewModel.activeInstance = instance
                            print("DEBUG - Set active instance: \(instance.id) with description: \(instance.description)")
                        }
                        
                        // Restart sound playback
                        AudioPlayerService.shared.playAlarmSound(for: alarm)
                    }
                }
                
                switch response.actionIdentifier {
                case "SNOOZE_ACTION":
                    // Stop the current sound and schedule snooze
                    AudioPlayerService.shared.stopAlarmSound()
                    handleSnoozeAction(for: alarm, instanceID: instanceID)
                    Self.sharedAlarmViewModel.markAlarmAsInactive(alarm.id)
                    
                    // ADDED: Schedule alarm checks to resume after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("ResumeAlarmChecks"),
                            object: nil
                        )
                    }
                    
                    print("Alarm snoozed: \(alarm.name)")
                    
                case "DISMISS_ACTION":
                    // Stop the sound but keep alarm active
                    AudioPlayerService.shared.stopAlarmSound()
                    
                    // Create a persistent notification reminding user to open app
                    let content = UNMutableNotificationContent()
                    content.title = "Alarm Still Active"
                    content.body = "Open app to fully dismiss \(alarm.name)"
                    content.categoryIdentifier = "ALARM_CATEGORY"
                    
                    // Include instance ID in userInfo if present
                    var reminderUserInfo: [String: Any] = ["alarmID": alarm.id]
                    if let instanceID = instanceID {
                        reminderUserInfo["instanceID"] = instanceID
                    }
                    content.userInfo = reminderUserInfo
                    
                    // Create reminder notification identifier
                    let reminderID = instanceID != nil ?
                    "\(alarm.id)_instance_\(instanceID!)_reminder_\(Date().timeIntervalSince1970)" :
                    "\(alarm.id)_reminder_\(Date().timeIntervalSince1970)"
                    
                    let request = UNNotificationRequest(
                        identifier: reminderID,
                        content: content,
                        trigger: nil  // Deliver immediately
                    )
                    
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling reminder notification: \(error)")
                        } else {
                            print("Reminder notification scheduled")
                        }
                    }
                    
                    print("Alarm temporarily dismissed, waiting for app open: \(alarm.name)")
                    
                case UNNotificationDefaultActionIdentifier:
                    // User tapped the notification - don't stop anything
                    // This will open the app where they'll see the alarm interface
                    print("User opened notification for alarm: \(alarm.name)")
                    
                default:
                    print("Unknown action for notification: \(response.actionIdentifier)")
                }
            }
        }
        
        completionHandler()
    }
    
    // Handle snooze action - made public so it can be called from AlarmActiveView
    public func handleSnoozeAction(for alarm: Alarm, instanceID: String? = nil) {
        // Snooze for 5 minutes
        let snoozeDate = Date().addingTimeInterval(5 * 60)
        
        // Create a new snooze notification with higher priority
        let content = UNMutableNotificationContent()
        content.title = "Snoozed: \(alarm.name)"
        
        // FIXED: Use instance description if available
        if let instanceID = instanceID,
           let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
            content.body = instance.description.isEmpty ? alarm.description : instance.description
        } else {
            content.body = alarm.description
        }
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        content.categoryIdentifier = "ALARM_CATEGORY"
        
        // Include instanceID in userInfo if provided
        var userInfo: [String: Any] = ["alarmID": alarm.id, "isSnooze": true]
        if let instanceID = instanceID {
            userInfo["instanceID"] = instanceID
        }
        content.userInfo = userInfo
        
        // Schedule for exactly 5 minutes later
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: snoozeDate)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        // Create notification identifier that includes instanceID if present
        let notificationID = instanceID != nil ?
        "\(alarm.id)_instance_\(instanceID!)_snooze_\(Date().timeIntervalSince1970)" :
        "\(alarm.id)_snooze_\(Date().timeIntervalSince1970)"
        
        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: trigger
        )
        
        // Cancel only notifications relevant to this instance/current alarm
        if let instanceID = instanceID {
            cancelRemainingNotifications(for: alarm.id, instanceID: instanceID)
        } else {
            cancelRemainingNotifications(for: alarm.id, onlyCurrentAlarm: true)
        }
        
        // Add the snooze notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze notification: \(error)")
            } else {
                print("Snooze notification scheduled for \(snoozeDate)")
            }
        }
        
        // Schedule additional follow-up notifications (for persistence)
        scheduleSnoozeFollowUps(for: alarm, baseTime: snoozeDate, instanceID: instanceID)
    }
    
    // New method to schedule persistent follow-up notifications for snooze
    private func scheduleSnoozeFollowUps(for alarm: Alarm, baseTime: Date, instanceID: String? = nil) {
        // Schedule 3 follow-up notifications at 1-minute intervals
        for i in 1...3 {
            let followUpContent = UNMutableNotificationContent()
            followUpContent.title = "⏰ \(alarm.name) - Snoozed Alarm Still Active"
            
            // FIXED: Use instance description if available
            if let instanceID = instanceID,
               let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
                followUpContent.body = instance.description.isEmpty ? alarm.description : instance.description
            } else {
                followUpContent.body = alarm.description
            }
            
            followUpContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
            followUpContent.categoryIdentifier = "ALARM_CATEGORY"
            
            // Include instanceID in userInfo if provided
            var userInfo: [String: Any] = [
                "alarmID": alarm.id,
                "isSnooze": true,
                "isFollowUp": true
            ]
            if let instanceID = instanceID {
                userInfo["instanceID"] = instanceID
            }
            followUpContent.userInfo = userInfo
            
            if #available(iOS 15.0, *) {
                followUpContent.interruptionLevel = .timeSensitive
            }
            
            let followUpTime = Calendar.current.date(byAdding: .minute, value: i, to: baseTime)!
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: followUpTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            // Create identifier that includes instanceID if present
            let identifier = instanceID != nil ?
            "\(alarm.id)_instance_\(instanceID!)_snooze_followup_\(i)" :
            "\(alarm.id)_snooze_followup_\(i)"
            
            let request = UNNotificationRequest(identifier: identifier, content: followUpContent, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling snooze follow-up notification: \(error)")
                } else {
                    print("Scheduled snooze follow-up notification #\(i) for \(followUpTime)")
                }
            }
        }
        
        // Also add a backup notification in case all else fails
        let backupContent = UNMutableNotificationContent()
        backupContent.title = "⚠️ Snoozed Alarm Backup: \(alarm.name)"
        
        // FIXED: Use instance description if available
        if let instanceID = instanceID,
           let instance = alarm.instances?.first(where: { $0.id == instanceID }) {
            backupContent.body = instance.description.isEmpty ? alarm.description : instance.description
        } else {
            backupContent.body = alarm.description
        }
        
        backupContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        backupContent.categoryIdentifier = "ALARM_CATEGORY"
        
        // Include instanceID in userInfo if provided
        var backupUserInfo: [String: Any] = ["alarmID": alarm.id, "isSnooze": true, "isBackup": true]
        if let instanceID = instanceID {
            backupUserInfo["instanceID"] = instanceID
        }
        backupContent.userInfo = backupUserInfo
        
        if #available(iOS 15.0, *) {
            backupContent.interruptionLevel = .timeSensitive
        }
        
        let backupTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5 * 60 + 15, // 5 min + 15 seconds
            repeats: false
        )
        
        // Create identifier that includes instanceID if present
        let backupID = instanceID != nil ?
        "\(alarm.id)_instance_\(instanceID!)_snooze_ultimate_backup" :
        "\(alarm.id)_snooze_ultimate_backup"
        
        let backupRequest = UNNotificationRequest(
            identifier: backupID,
            content: backupContent,
            trigger: backupTrigger
        )
        
        UNUserNotificationCenter.current().add(backupRequest) { error in
            if let error = error {
                print("Error scheduling ultimate backup snooze: \(error)")
            } else {
                print("Ultimate backup snooze notification scheduled")
            }
        }
    }
    
    // Cancel notifications for a specific alarm
    public func cancelRemainingNotifications(for alarmID: String, onlyCurrentAlarm: Bool = false, instanceID: String? = nil) {
        print("CANCELLING NOTIFICATIONS FOR ALARM: \(alarmID), instance: \(instanceID ?? "all")")
        
        // First cancel pending notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { request in
                    let userInfo = request.content.userInfo
                    
                    // Check userInfo first for more reliable filtering
                    if let requestAlarmID = userInfo["alarmID"] as? String {
                        if requestAlarmID == alarmID {
                            if let specificInstanceID = instanceID {
                                return (userInfo["instanceID"] as? String) == specificInstanceID
                            } else if onlyCurrentAlarm {
                                return (userInfo["instanceID"] as? String) == nil
                            } else {
                                return true
                            }
                        }
                        return false
                    }
                    
                    // Fallback to checking the identifier if userInfo doesn't have alarmID
                    if let specificInstanceID = instanceID {
                        return request.identifier.contains(alarmID) && request.identifier.contains(specificInstanceID)
                    } else if onlyCurrentAlarm {
                        return request.identifier.contains(alarmID) && !request.identifier.contains("_instance_")
                    } else {
                        return request.identifier.contains(alarmID)
                    }
                }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled \(identifiersToRemove.count) pending notifications for alarm \(alarmID)")
        }
        
        // Then cancel delivered notifications with the same approach
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications
                .filter { notification in
                    let userInfo = notification.request.content.userInfo
                    
                    // Check userInfo first
                    if let requestAlarmID = userInfo["alarmID"] as? String {
                        if requestAlarmID == alarmID {
                            if let specificInstanceID = instanceID {
                                return (userInfo["instanceID"] as? String) == specificInstanceID
                            } else if onlyCurrentAlarm {
                                return (userInfo["instanceID"] as? String) == nil
                            } else {
                                return true
                            }
                        }
                        return false
                    }
                    
                    // Fallback to identifier
                    if let specificInstanceID = instanceID {
                        return notification.request.identifier.contains(alarmID) &&
                        notification.request.identifier.contains(specificInstanceID)
                    } else if onlyCurrentAlarm {
                        return notification.request.identifier.contains(alarmID) &&
                        !notification.request.identifier.contains("_instance_")
                    } else {
                        return notification.request.identifier.contains(alarmID)
                    }
                }
                .map { $0.request.identifier }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
            print("Removed \(identifiersToRemove.count) delivered notifications for alarm \(alarmID)")
        }
    }
}
