//
//  Spaceship.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI

// Base model for all spaceship types
struct Spaceship: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var imageAsset: String
    var premium: Bool
    var adContent: AdContent?
    var position: CGPoint
    var rotation: Double
    var scale: CGFloat
    var visible: Bool
    var speed: CGFloat
    var specialEffect: SpecialEffect?
    
    init(name: String, imageAsset: String, premium: Bool = false, adContent: AdContent? = nil, 
         position: CGPoint = CGPoint(x: 100, y: 100), rotation: Double = 0, scale: CGFloat = 1.0,
         visible: Bool = true, speed: CGFloat = 1.0, specialEffect: SpecialEffect? = nil) {
        self.name = name
        self.imageAsset = imageAsset
        self.premium = premium
        self.adContent = adContent
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.visible = visible
        self.speed = speed
        self.specialEffect = specialEffect
    }
    
    // Custom coding keys to handle CGPoint (which is not Codable by default)
    enum CodingKeys: String, CodingKey {
        case id, name, imageAsset, premium, adContent, positionX, positionY, rotation, scale, visible, speed, specialEffect
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageAsset = try container.decode(String.self, forKey: .imageAsset)
        premium = try container.decode(Bool.self, forKey: .premium)
        adContent = try container.decodeIfPresent(AdContent.self, forKey: .adContent)
        let positionX = try container.decode(CGFloat.self, forKey: .positionX)
        let positionY = try container.decode(CGFloat.self, forKey: .positionY)
        position = CGPoint(x: positionX, y: positionY)
        rotation = try container.decode(Double.self, forKey: .rotation)
        scale = try container.decode(CGFloat.self, forKey: .scale)
        visible = try container.decode(Bool.self, forKey: .visible)
        speed = try container.decode(CGFloat.self, forKey: .speed)
        specialEffect = try container.decodeIfPresent(SpecialEffect.self, forKey: .specialEffect)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(imageAsset, forKey: .imageAsset)
        try container.encode(premium, forKey: .premium)
        try container.encodeIfPresent(adContent, forKey: .adContent)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(scale, forKey: .scale)
        try container.encode(visible, forKey: .visible)
        try container.encode(speed, forKey: .speed)
        try container.encodeIfPresent(specialEffect, forKey: .specialEffect)
    }
}

// Monetization content model
struct AdContent: Codable {
    var id: UUID = UUID()
    var advertiserName: String
    var bannerImage: String?
    var targetURL: URL?
    var displayDuration: TimeInterval
    var priority: Int
    var impressionCount: Int = 0
    var clickCount: Int = 0
    var startDate: Date
    var endDate: Date
    
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }
}

// Special effects for premium ships
enum SpecialEffect: String, Codable {
    case trail
    case glow
    case warpField
    case teleport
    case explosion
}

// Predefined spaceship templates
extension Spaceship {
    static let templates: [Spaceship] = [
        Spaceship(name: "Explorer", imageAsset: "spaceship_explorer", premium: false),
        Spaceship(name: "Cruiser", imageAsset: "spaceship_cruiser", premium: false),
        Spaceship(name: "Fighter", imageAsset: "spaceship_fighter", premium: true, specialEffect: .trail),
        Spaceship(name: "Hauler", imageAsset: "spaceship_hauler", premium: false),
        Spaceship(name: "Corvette", imageAsset: "spaceship_corvette", premium: true, specialEffect: .glow),
        Spaceship(name: "Shuttle", imageAsset: "spaceship_shuttle", premium: false),
        Spaceship(name: "Destroyer", imageAsset: "spaceship_destroyer", premium: true, specialEffect: .warpField),
        Spaceship(name: "Transport", imageAsset: "spaceship_transport", premium: false),
        Spaceship(name: "Flagship", imageAsset: "spaceship_flagship", premium: true, specialEffect: .teleport)
    ]
}
