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
        
        // Set up notification handling
        UNUserNotificationCenter.current().delegate = self
        
        // Load alarms from database on startup
        Self.sharedAlarmViewModel.loadAlarms()
        return true
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        guard let alarmID = userInfo["alarmID"] as? String,
              let instanceID = userInfo["instanceID"] as? String else {
            completionHandler([.banner, .sound])
            return
        }
        
        // Fetch alarm from AlarmViewModel
        if let alarm = Self.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmID }) {
            if alarm.isCustomRingtone, let soundURL = alarm.customRingtoneURL {
                do {
                    audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                    audioPlayer?.play()
                    completionHandler([.banner])
                } catch {
                    print("Error playing custom sound: \(error)")
                    completionHandler([.banner, .sound])
                }
            } else {
                completionHandler([.banner, .sound])
            }
        } else {
            print("Alarm with ID \(alarmID) not found")
            completionHandler([.banner, .sound])
        }
    }
}
