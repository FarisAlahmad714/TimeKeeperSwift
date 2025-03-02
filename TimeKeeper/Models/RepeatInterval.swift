import Foundation

enum RepeatInterval: String, Codable, CaseIterable {
    case none = "None"
    case daily = "Daily"
    case weekly = "Weekly"
    case hourly = "Hourly"
    case minutely = "Minutely"
}