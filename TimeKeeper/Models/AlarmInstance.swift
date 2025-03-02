import Foundation

struct AlarmInstance: Identifiable, Codable {
    var id: String
    var date: Date
    var time: Date
    var description: String
}