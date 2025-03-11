// WorldClockViewModel.swift
// TimeKeeper
// Created by Faris Alahmad on 3/2/25.
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
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }
            
            print("Raw API Response: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
            
            do {
                let decoder = JSONDecoder()
                let unsplashResponse = try decoder.decode(UnsplashResponse.self, from: data)
                if let firstPhoto = unsplashResponse.results.first,
                   let smallURLString = firstPhoto.urls.small,
                   let url = URL(string: smallURLString) {
                    completion(url)
                } else {
                    print("No suitable image found for \(city)")
                    completion(nil)
                }
            } catch {
                print("Decoding error: \(error)")
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
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "UnsplashAPIKey") as? String {
        print("API Key found: \(apiKey)")
        return apiKey
    } else {
        print("Error: UnsplashAPIKey not found in Info.plist")
        return nil
    }
}

// MARK: - Unsplash API Response Models
struct UnsplashResponse: Codable {
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Codable {
    let id: String
    let urls: UnsplashURLs
}

struct UnsplashURLs: Codable {
    let small: String?
    let regular: String?
}
