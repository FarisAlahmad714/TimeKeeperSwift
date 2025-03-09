//
//  ModalState.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//


import Foundation

enum ModalState: Equatable {
    case none
    case choice
    case singleAlarm
    case eventAlarm
    case settings
    case editSingleAlarm
    case addInstance
    case editInstance
}