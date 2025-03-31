// Alarm.swift
// TimeKeeper
// Created by Faris Alahmad on 3/2/25

import Foundation

struct Alarm: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var description: String
    var times: [Date]
    var dates: [Date]
    var instances: [AlarmInstance]?
    var status: Bool
    var ringtone: String
    var isCustomRingtone: Bool
    var customRingtoneURL: URL?
    var snooze: Bool
    
    // Conform to Equatable
    static func == (lhs: Alarm, rhs: Alarm) -> Bool {
        return lhs.id == rhs.id // Compare based on unique ID
    }
    
    // Add this custom initializer
    init(id: String, name: String, description: String, times: [Date], dates: [Date], instances: [AlarmInstance]?, status: Bool, ringtone: String, isCustomRingtone: Bool, customRingtoneURL: URL?, snooze: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.times = times
        self.dates = dates
        self.instances = instances
        self.status = status
        self.ringtone = ringtone
        self.isCustomRingtone = isCustomRingtone
        self.customRingtoneURL = customRingtoneURL
        self.snooze = snooze
    }
    
    var isEventAlarm: Bool {
        return true  // Changed to check for non-empty
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, times, dates, instances, status, ringtone, isCustomRingtone, customRingtoneURL, snooze
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(description, forKey: .description)
        try container.encode(times, forKey: .times)
        try container.encode(dates, forKey: .dates)
        try container.encode(instances, forKey: .instances)
        try container.encode(status, forKey: .status)
        try container.encode(ringtone, forKey: .ringtone)
        try container.encode(isCustomRingtone, forKey: .isCustomRingtone)
        try container.encode(customRingtoneURL, forKey: .customRingtoneURL)
        try container.encode(snooze, forKey: .snooze)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        times = try container.decode([Date].self, forKey: .times)
        dates = try container.decode([Date].self, forKey: .dates)
        instances = try container.decodeIfPresent([AlarmInstance].self, forKey: .instances)
        status = try container.decode(Bool.self, forKey: .status)
        ringtone = try container.decode(String.self, forKey: .ringtone)
        isCustomRingtone = try container.decode(Bool.self, forKey: .isCustomRingtone)
        customRingtoneURL = try container.decodeIfPresent(URL.self, forKey: .customRingtoneURL)
        snooze = try container.decode(Bool.self, forKey: .snooze)
    }
}
