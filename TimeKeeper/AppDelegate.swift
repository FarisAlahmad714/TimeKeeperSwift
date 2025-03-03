//
//  AppDelegate.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/3/25.
//


// AppDelegate.swift

import UIKit
import UserNotifications
import AVFoundation

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    var audioPlayer: AVAudioPlayer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        guard let alarmID = userInfo["alarmID"] as? String,
              let instanceID = userInfo["instanceID"] as? String else {
            completionHandler([.banner, .sound])
            return
        }
        
        guard let data = UserDefaults.standard.data(forKey: "alarms"),
              let alarms = try? JSONDecoder().decode([Alarm].self, from: data),
              let alarm = alarms.first(where: { $0.id == alarmID }) else {
            completionHandler([.banner, .sound])
            return
        }
        
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
    }
}