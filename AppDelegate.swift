import UIKit
import UserNotifications
import AVFoundation
import FirebaseCore
import RealmSwift

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
        if let alarm = notification.userInfo?["alarm"] as? Alarm {
            print("Received snooze notification for alarm: \(alarm.id)")
            handleSnoozeAction(for: alarm)
        } else {
            print("⚠️ Received snooze notification but couldn't extract alarm")
        }
    }
    
    // Handle dismiss notification from UI
    @objc func handleDismissNotification(_ notification: Notification) {
        if let alarm = notification.userInfo?["alarm"] as? Alarm {
            print("Received dismiss notification for alarm: \(alarm.id)")
            
            // Cancel all notifications for this alarm
            cancelRemainingNotifications(for: alarm.id)
            
            // Ensure the alarm is marked as inactive
            Self.sharedAlarmViewModel.markAlarmAsInactive(alarm.id)
            
            // Post notification to disable alarm checks temporarily (prevents reactivation)
            NotificationCenter.default.post(
                name: NSNotification.Name("TemporarilyDisableAlarmChecks"),
                object: nil
            )
            
            print("Alarm completely dismissed: \(alarm.id)")
        } else {
            print("⚠️ Received dismiss notification but couldn't extract alarm")
        }
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
                
                // Notify view model about active alarm
                DispatchQueue.main.async {
                    // Post notification to trigger active alarm view
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AlarmNotificationReceived"),
                        object: nil,
                        userInfo: ["alarmID": alarmID]
                    )
                    
                    // Set active alarm directly too
                    if Self.sharedAlarmViewModel.activeAlarm == nil {
                        Self.sharedAlarmViewModel.activeAlarm = alarm
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
        
        // Extract alarm ID
        if let alarmID = userInfo["alarmID"] as? String {
            // Find the alarm
            if let alarm = Self.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmID }) {
                // Set active alarm here too - this helps when notification is tapped
                if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                    DispatchQueue.main.async {
                        Self.sharedAlarmViewModel.activeAlarm = alarm
                        
                        // Restart sound playback
                        AudioPlayerService.shared.playAlarmSound(for: alarm)
                    }
                }
                
                switch response.actionIdentifier {
                case "SNOOZE_ACTION":
                    // Stop the current sound and schedule snooze
                    AudioPlayerService.shared.stopAlarmSound()
                    handleSnoozeAction(for: alarm)
                    Self.sharedAlarmViewModel.markAlarmAsInactive(alarm.id)
                    print("Alarm snoozed: \(alarm.name)")
                    
                case "DISMISS_ACTION":
                    // Stop the sound but keep alarm active
                    AudioPlayerService.shared.stopAlarmSound()
                    
                    // Create a persistent notification reminding user to open app
                    let content = UNMutableNotificationContent()
                    content.title = "Alarm Still Active"
                    content.body = "Open app to fully dismiss \(alarm.name)"
                    content.categoryIdentifier = "ALARM_CATEGORY"
                    content.userInfo = ["alarmID": alarm.id]
                    
                    let request = UNNotificationRequest(
                        identifier: "\(alarm.id)_reminder",
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
    public func handleSnoozeAction(for alarm: Alarm) {
        // Snooze for 5 minutes
        let snoozeDate = Date().addingTimeInterval(5 * 60)
        
        // Create a new snooze notification with higher priority
        let content = UNMutableNotificationContent()
        content.title = "Snoozed: \(alarm.name)"
        content.body = alarm.description
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.userInfo = ["alarmID": alarm.id, "isSnooze": true]
        
        if #available(iOS 15.0, *) {
            content.interruptionLevel = .timeSensitive
        }
        
        // Schedule for exactly 5 minutes later
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: snoozeDate)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(alarm.id)_snooze_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        // Clear existing notifications first
        cancelRemainingNotifications(for: alarm.id)
        
        // Add the snooze notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling snooze notification: \(error)")
            } else {
                print("Snooze notification scheduled for \(snoozeDate)")
            }
        }
        
        // Schedule additional follow-up notifications (for persistence) - just like the regular alarm
        scheduleSnoozeFollowUps(for: alarm, baseTime: snoozeDate)
    }

    // New method to schedule persistent follow-up notifications for snooze
    private func scheduleSnoozeFollowUps(for alarm: Alarm, baseTime: Date) {
        // Schedule 3 follow-up notifications at 1-minute intervals
        for i in 1...3 {
            let followUpContent = UNMutableNotificationContent()
            followUpContent.title = "⏰ \(alarm.name) - Snoozed Alarm Still Active"
            followUpContent.body = alarm.description
            followUpContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
            followUpContent.categoryIdentifier = "ALARM_CATEGORY"
            
            // Add same user info for identification
            followUpContent.userInfo = [
                "alarmID": alarm.id,
                "isSnooze": true,
                "isFollowUp": true
            ]
            
            if #available(iOS 15.0, *) {
                followUpContent.interruptionLevel = .timeSensitive
            }
            
            let followUpTime = Calendar.current.date(byAdding: .minute, value: i, to: baseTime)!
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: followUpTime)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let identifier = "\(alarm.id)_snooze_followup_\(i)"
            
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
        backupContent.body = alarm.description
        backupContent.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: alarm.ringtone))
        backupContent.categoryIdentifier = "ALARM_CATEGORY"
        backupContent.userInfo = ["alarmID": alarm.id, "isSnooze": true, "isBackup": true]
        
        if #available(iOS 15.0, *) {
            backupContent.interruptionLevel = .timeSensitive
        }
        
        let backupTrigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 5 * 60 + 15, // 5 min + 15 seconds
            repeats: false
        )
        
        let backupRequest = UNNotificationRequest(
            identifier: "\(alarm.id)_snooze_ultimate_backup",
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
    
    // Cancel all notifications for a specific alarm
    public func cancelRemainingNotifications(for alarmID: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiersToRemove = requests
                .filter { $0.identifier.contains(alarmID) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
            print("Cancelled \(identifiersToRemove.count) notifications for alarm \(alarmID)")
        }
        
        // Also clear delivered notifications
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let identifiersToRemove = notifications
                .filter { $0.request.identifier.contains(alarmID) }
                .map { $0.request.identifier }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiersToRemove)
            print("Removed \(identifiersToRemove.count) delivered notifications for alarm \(alarmID)")
        }
    }
}
