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
        if let data = UserDefaults.standard.data(forKey: "worldClocks"),
           let decoded = try? JSONDecoder().decode([WorldClock].self, from: data) {
            clocks = decoded
        } else {
            clocks = []
        }
    }
    
    func saveClocks() {
        if let encoded = try? JSONEncoder().encode(clocks) {
            UserDefaults.standard.set(encoded, forKey: "worldClocks")
        }
    }
    
    func addClock(timezone: String) {
        // Prevent duplicates
        if clocks.contains(where: { $0.timezone == timezone }) {
            print("Timezone \(timezone) already exists, skipping addition")
            return
        }
        
        let newClock = WorldClock(timezone: timezone, position: CGPoint(x: 100, y: 100))
        clocks.append(newClock)
        saveClocks()
        showAddClockModal = false
    }
    
    func deleteClock(at offsets: IndexSet) {
        clocks.remove(atOffsets: offsets)
        saveClocks()
    }
    
    func updateClockPosition(_ clock: WorldClock, position: CGPoint) {
        if let index = clocks.firstIndex(where: { $0.id == clock.id }) {
            clocks[index].position = position
            saveClocks()
        }
    }
    
    func timeForTimezone(_ timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: timezone)
        return formatter.string(from: currentTime)
    }
    
    func dateForTimezone(_ timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(identifier: timezone)
        return formatter.string(from: currentTime)
    }
}
