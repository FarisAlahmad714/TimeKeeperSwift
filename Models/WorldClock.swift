//
//  WorldClock.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import Foundation

struct WorldClock: Identifiable, Codable {
    var id = UUID()
    var timezone: String
}