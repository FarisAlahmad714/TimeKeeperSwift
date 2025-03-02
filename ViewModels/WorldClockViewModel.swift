//
//  WorldClockViewModel.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import Foundation
import SwiftUI

class WorldClockViewModel: ObservableObject {
    @Published var clocks: [WorldClock] = []
    @Published var showAddClockModal = false
    @Published var selectedTimezone: String?
    @Published var currentTime = Date()
    
    private var timer: Timer?
    
    init() {
        loadClocks()
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }
    
    func loadClocks() {
        // We'll implement this when we create the WorldClock model
        self.clocks = []
    }
}