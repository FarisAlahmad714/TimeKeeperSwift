//
//  AlarmViewModel.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import Foundation
import SwiftUI
import UserNotifications

class AlarmViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var showChoiceModal = false
    @Published var showSingleAlarmModal = false
    @Published var showEventAlarmModal = false
    @Published var showEditSingleAlarmModal = false
    @Published var showEditInstanceModal = false
    @Published var showAddInstanceModal = false
    @Published var showSettingsModal = false
    
    @Published var selectedEvent: Alarm?
    @Published var selectedInstance: AlarmInstance?
    @Published var alarmName = ""
    @Published var alarmDescription = ""
    @Published var alarmTime = Date()
    @Published var alarmDate = Date()
    @Published var eventInstances: [AlarmInstance] = []
    
    @Published var settings = AlarmSettings(repeatInterval: .none, ringtone: "Default", snooze: false)
    @Published var selectedAlarm: Alarm?
    
    init() {
        loadAlarms()
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
    
    // Other methods to be added as we build out the functionality
    // For now this gives us the basic structure
}