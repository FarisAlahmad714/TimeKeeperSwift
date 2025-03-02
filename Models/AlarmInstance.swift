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
}