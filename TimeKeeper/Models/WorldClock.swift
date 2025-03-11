// WorldClock.swift
// TimeKeeper
// Created by Faris Alahmad on 3/2/25.

import Foundation
import SwiftUI

struct WorldClock: Identifiable, Codable {
    let id: UUID
    var timezone: String
    var position: CGPoint
    var imageURL: URL?

    init(id: UUID = UUID(), timezone: String, position: CGPoint, imageURL: URL? = nil) {
        self.id = id
        self.timezone = timezone
        self.position = position
        self.imageURL = imageURL
    }

    enum CodingKeys: String, CodingKey {
        case id
        case timezone
        case position
        case imageURL
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timezone = try container.decode(String.self, forKey: .timezone)
        position = try container.decode(CGPoint.self, forKey: .position)
        imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timezone, forKey: .timezone)
        try container.encode(position, forKey: .position)
        try container.encodeIfPresent(imageURL, forKey: .imageURL)
    }
}

// Extend CGPoint to conform to Codable
extension CGPoint: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }

    enum CodingKeys: String, CodingKey {
        case x
        case y
    }
}
