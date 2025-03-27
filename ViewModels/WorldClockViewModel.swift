// WorldClockViewModel.swift

import Foundation
import SwiftUI
import Kingfisher

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
        if clocks.contains(where: { $0.timezone == timezone }) {
            print("Timezone \(timezone) already exists, skipping addition")
            return
        }
        
        let city = cityName(from: timezone)
        let newClock = WorldClock(timezone: timezone, position: CGPoint(x: 100, y: 100))
        clocks.append(newClock)
        saveClocks()
        
        fetchImageURL(for: city) { [weak self] imageURL in
            DispatchQueue.main.async {
                if let index = self?.clocks.firstIndex(where: { $0.id == newClock.id }) {
                    self?.clocks[index].imageURL = imageURL
                    self?.saveClocks()
                }
            }
        }
        
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

    func updateClockTimezone(id: UUID, newTimezone: String) {
        if let index = clocks.firstIndex(where: { $0.id == id }) {
            clocks[index].timezone = newTimezone
            saveClocks()
            let city = cityName(from: newTimezone)
            fetchImageURL(for: city) { [weak self] imageURL in
                DispatchQueue.main.async {
                    if let index = self?.clocks.firstIndex(where: { $0.id == id }) {
                        self?.clocks[index].imageURL = imageURL
                        self?.saveClocks()
                    }
                }
            }
        }
    }

    func timeForTimezone(_ timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm:ss a"  // 12-hour format with AM/PM
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.locale = Locale(identifier: "en_US")  // Ensures AM/PM display
        return formatter.string(from: currentTime)
    }

    func dateForTimezone(_ timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeZone = TimeZone(identifier: timezone)
        formatter.locale = Locale(identifier: "en_US")  // Consistent locale
        return formatter.string(from: currentTime)
    }

    func fetchImageURL(for city: String, completion: @escaping (URL?) -> Void) {
        guard let apiKey = getAPIKey() else {
            print("Error: Unable to fetch API key")
            completion(nil)
            return
        }

        let query = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.unsplash.com/search/photos?query=\(query)&client_id=\(apiKey)"
        guard let url = URL(string: urlString) else {
            print("Error: Invalid URL for city \(city)")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching image URL for \(city): \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let results = json?["results"] as? [[String: Any]],
                   let firstResult = results.first,
                   let urls = firstResult["urls"] as? [String: String],
                   let smallURL = urls["small"] {
                    completion(URL(string: smallURL))
                } else {
                    completion(nil)
                }
            } catch {
                print("Error parsing Unsplash response for \(city): \(error)")
                completion(nil)
            }
        }.resume()
    }

    func cityName(from timezone: String) -> String {
        let components = timezone.split(separator: "/")
        return components.last?.replacingOccurrences(of: "_", with: " ") ?? timezone
    }
}

func getAPIKey() -> String? {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "UnsplashAPIKey") as? String else {
        print("Error: UnsplashAPIKey not found in Info.plist")
        return nil
    }
    return apiKey
}
