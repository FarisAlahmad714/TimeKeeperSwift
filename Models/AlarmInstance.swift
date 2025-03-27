//
//  AlarmInstance.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//
import Foundation

struct AlarmInstance: Identifiable, Codable {
    var id: String
    var date: Date
    var time: Date
    var description: String
    var repeatInterval: RepeatInterval
    
    // Standard initializer
    init(id: String, date: Date, time: Date, description: String, repeatInterval: RepeatInterval) {
        self.id = id
        self.date = date
        self.time = time
        self.description = description
        self.repeatInterval = repeatInterval
    }
    
    // Coding keys for Codable
    enum CodingKeys: String, CodingKey {
        case id, date, time, description, repeatInterval
    }
}
