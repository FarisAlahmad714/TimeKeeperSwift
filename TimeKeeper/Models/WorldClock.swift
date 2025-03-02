import Foundation

struct WorldClock: Identifiable, Codable {
    var id = UUID()
    var timezone: String
}