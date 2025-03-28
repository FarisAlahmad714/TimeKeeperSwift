//
//  AudioPlayerService.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/27/25.
//

import Foundation
import AVFoundation
import UIKit

class AudioPlayerService: NSObject {
    // Singleton instance
    static let shared = AudioPlayerService()
    
    private var audioPlayer: AVAudioPlayer?
    private var currentAlarmId: String?
    private var backupTimer: Timer?
    private var soundPlaybackTimer: Timer?
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    
    private override init() {
        super.init()
        setupAudioSession()
        
        // Add observer for app becoming active to restart playback if needed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Add observer for audio interruptions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupAudioSession() {
        do {
            // Configure audio session with stronger settings
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured for background playback")
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    @objc private func handleAudioInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            print("Audio interruption began")
        } else if type == .ended {
            print("Audio interruption ended")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // Try to resume audio after interruption
                    restartCurrentAlarmSound()
                }
            }
        }
    }
    
    @objc private func handleAppDidBecomeActive() {
        // Make sure audio is still playing when app becomes active
        restartCurrentAlarmSound()
    }
    
    private func restartCurrentAlarmSound() {
        if let alarmId = currentAlarmId,
           let alarm = AppDelegate.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmId }) {
            print("Manually restarting alarm sound for \(alarm.name)")
            
            // Start sound playback without stopping first
            if audioPlayer?.isPlaying == false {
                playSingleSound(for: alarm)
            }
        }
    }
    
    // New method to play the sound once
    private func playSingleSound(for alarm: Alarm) {
        // Get the sound file
        let soundFileName: String
        var soundURL: URL?
        
        if alarm.isCustomRingtone, let customURL = alarm.customRingtoneURL {
            soundURL = customURL
        } else {
            soundFileName = alarm.ringtone
            soundURL = Bundle.main.url(forResource: soundFileName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3")
        }
        
        guard let url = soundURL else {
            print("Sound file not found")
            return
        }
        
        do {
            // Ensure audio session is active
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            
            // Initialize player
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 0.8
            audioPlayer?.prepareToPlay()
            let success = audioPlayer?.play() ?? false
            
            print("Started single sound playback: \(success)")
        } catch {
            print("Failed to play single sound: \(error)")
        }
    }
    
    func playAlarmSound(for alarm: Alarm) {
        // Stop any current playback
        stopAlarmSound()
        
        // Start background task
        startBackgroundTask()
        
        // Track current alarm
        currentAlarmId = alarm.id
        
        print("Starting alarm sound for: \(alarm.name)")
        
        // Play the sound once immediately
        playSingleSound(for: alarm)
        
        // Start a timer to repeatedly play the sound
        soundPlaybackTimer?.invalidate()
        soundPlaybackTimer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if let alarmId = self.currentAlarmId,
               let currentAlarm = AppDelegate.sharedAlarmViewModel.alarms.first(where: { $0.id == alarmId }) {
                print("Timer triggered - playing sound again for \(currentAlarm.name)")
                self.playSingleSound(for: currentAlarm)
            }
        }
        RunLoop.main.add(soundPlaybackTimer!, forMode: .common)
        
        // Create a backup timer that checks if audio is still playing
        createBackupPlaybackTimer()
    }
    
    private func createBackupPlaybackTimer() {
        // Create a timer that checks every 5 seconds if audio is still playing
        backupTimer?.invalidate()
        backupTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            if self.audioPlayer?.isPlaying == false {
                print("Backup timer detected audio stopped - restarting")
                self.restartCurrentAlarmSound()
            }
        }
        RunLoop.main.add(backupTimer!, forMode: .common)
    }
    
    private func startBackgroundTask() {
        // End any existing background task
        endBackgroundTask()
        
        // Start a new background task
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask { [weak self] in
            print("Background task about to expire - trying to extend")
            self?.endBackgroundTask()
            self?.startBackgroundTask() // Try to restart background task
        }
        
        print("Background task started with ID: \(backgroundTaskIdentifier.rawValue)")
    }
    
    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
            print("Background task ended")
        }
    }
    
    func stopAlarmSound() {
        soundPlaybackTimer?.invalidate()
        soundPlaybackTimer = nil
        
        backupTimer?.invalidate()
        backupTimer = nil
        
        if audioPlayer?.isPlaying == true {
            audioPlayer?.stop()
            audioPlayer = nil
            currentAlarmId = nil
            print("Stopped alarm sound")
        }
        
        // End background task when sound stops
        endBackgroundTask()
    }
    
    func isPlaying(alarmId: String) -> Bool {
        return currentAlarmId == alarmId && audioPlayer?.isPlaying == true
    }
}

// AVAudioPlayerDelegate implementation
extension AudioPlayerService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Audio player finished playing")
        
        // We're using our timer-based approach instead of relying on this callback
        // The delegate methods are still useful for debugging and monitoring
    }
    
    func audioPlayerBeginInterruption(_ player: AVAudioPlayer) {
        print("Audio player interrupted")
    }
    
    func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        print("Audio player interruption ended")
        
        if flags == AVAudioSession.InterruptionOptions.shouldResume.rawValue {
            player.play()
        }
    }
}
