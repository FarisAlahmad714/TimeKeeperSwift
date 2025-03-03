//
//  WorldClock.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//

import Foundation
import CoreGraphics

struct WorldClock: Identifiable, Codable {
    var id: UUID = UUID()
    var timezone: String
    var position: CGPoint
    
    init(timezone: String, position: CGPoint = CGPoint(x: 100, y: 100)) {
        self.timezone = timezone
        self.position = position
    }
    
    // Custom coding keys to handle CGPoint (which is not Codable by default)
    enum CodingKeys: String, CodingKey {
        case id
        case timezone
        case positionX
        case positionY
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timezone = try container.decode(String.self, forKey: .timezone)
        let positionX = try container.decode(CGFloat.self, forKey: .positionX)
        let positionY = try container.decode(CGFloat.self, forKey: .positionY)
        position = CGPoint(x: positionX, y: positionY)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
    }
}
