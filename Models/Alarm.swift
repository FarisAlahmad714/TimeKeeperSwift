//
//  Alarm.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import Foundation

struct Alarm: Identifiable, Codable {
    var id: String
    var name: String
    var description: String
    var times: [Date]
    var dates: [Date]
    var instances: [AlarmInstance]?
    var status: Bool
    var ringtone: String
    var snooze: Bool
    
    var isEventAlarm: Bool {
        return instances != nil && !instances!.isEmpty
    }
}
