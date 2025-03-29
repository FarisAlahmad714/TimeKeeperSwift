//
//  DroneAdObject.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/29/25.
//


//
//  DroneAdObject.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/29/25.
//

import Foundation
import SpriteKit

struct DroneAdObject: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var droneType: DroneType
    var adContent: AdContent?
    var position: CGPoint
    var rotation: Double
    var scale: CGFloat
    var visible: Bool
    var speed: CGFloat
    var bannerText: String?
    var bannerWidth: CGFloat
    
    // Unique drone properties
    var propellerSpeed: CGFloat
    var hoverAmplitude: CGFloat
    var bannerPhysicsEnabled: Bool
    
    init(name: String, droneType: DroneType = .quadcopter, adContent: AdContent? = nil,
         position: CGPoint = CGPoint(x: 100, y: 100), rotation: Double = 0, scale: CGFloat = 1.0,
         visible: Bool = true, speed: CGFloat = 1.0, bannerText: String? = nil,
         bannerWidth: CGFloat = 120, propellerSpeed: CGFloat = 15.0,
         hoverAmplitude: CGFloat = 3.0, bannerPhysicsEnabled: Bool = true) {
        self.name = name
        self.droneType = droneType
        self.adContent = adContent
        self.position = position
        self.rotation = rotation
        self.scale = scale
        self.visible = visible
        self.speed = speed
        self.bannerText = bannerText
        self.bannerWidth = bannerWidth
        self.propellerSpeed = propellerSpeed
        self.hoverAmplitude = hoverAmplitude
        self.bannerPhysicsEnabled = bannerPhysicsEnabled
    }
    
    // Custom coding keys to handle CGPoint
    enum CodingKeys: String, CodingKey {
        case id, name, droneType, adContent, positionX, positionY, rotation, scale, visible, speed
        case bannerText, bannerWidth, propellerSpeed, hoverAmplitude, bannerPhysicsEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        droneType = try container.decode(DroneType.self, forKey: .droneType)
        adContent = try container.decodeIfPresent(AdContent.self, forKey: .adContent)
        let positionX = try container.decode(CGFloat.self, forKey: .positionX)
        let positionY = try container.decode(CGFloat.self, forKey: .positionY)
        position = CGPoint(x: positionX, y: positionY)
        rotation = try container.decode(Double.self, forKey: .rotation)
        scale = try container.decode(CGFloat.self, forKey: .scale)
        visible = try container.decode(Bool.self, forKey: .visible)
        speed = try container.decode(CGFloat.self, forKey: .speed)
        bannerText = try container.decodeIfPresent(String.self, forKey: .bannerText)
        bannerWidth = try container.decode(CGFloat.self, forKey: .bannerWidth)
        propellerSpeed = try container.decode(CGFloat.self, forKey: .propellerSpeed)
        hoverAmplitude = try container.decode(CGFloat.self, forKey: .hoverAmplitude)
        bannerPhysicsEnabled = try container.decode(Bool.self, forKey: .bannerPhysicsEnabled)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(droneType, forKey: .droneType)
        try container.encodeIfPresent(adContent, forKey: .adContent)
        try container.encode(position.x, forKey: .positionX)
        try container.encode(position.y, forKey: .positionY)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(scale, forKey: .scale)
        try container.encode(visible, forKey: .visible)
        try container.encode(speed, forKey: .speed)
        try container.encodeIfPresent(bannerText, forKey: .bannerText)
        try container.encode(bannerWidth, forKey: .bannerWidth)
        try container.encode(propellerSpeed, forKey: .propellerSpeed)
        try container.encode(hoverAmplitude, forKey: .hoverAmplitude)
        try container.encode(bannerPhysicsEnabled, forKey: .bannerPhysicsEnabled)
    }
}

// Drone types
enum DroneType: String, Codable {
    case quadcopter
    case hexacopter
    case deliveryDrone
    case racingDrone
}

// Predefined drone templates
extension DroneAdObject {
    static let templates: [DroneAdObject] = [
        DroneAdObject(
            name: "Quad Explorer",
            droneType: .quadcopter,
            position: CGPoint(x: 100, y: 150),
            speed: 1.0,
            bannerText: "YOUR AD HERE!",
            bannerWidth: 150,
            propellerSpeed: 15.0,
            hoverAmplitude: 3.0
        ),
        DroneAdObject(
            name: "Delivery Drone",
            droneType: .deliveryDrone,
            position: CGPoint(x: 100, y: 180),
            speed: 0.8,
            bannerText: "Try our new features!",
            bannerWidth: 200,
            propellerSpeed: 12.0,
            hoverAmplitude: 4.0
        ),
        DroneAdObject(
            name: "Racing Drone",
            droneType: .racingDrone,
            position: CGPoint(x: 100, y: 120),
            speed: 2.0,
            bannerText: "Ultra fast performance",
            bannerWidth: 120,
            propellerSpeed: 25.0,
            hoverAmplitude: 2.0
        ),
        DroneAdObject(
            name: "Hexa Observer",
            droneType: .hexacopter,
            position: CGPoint(x: 100, y: 200),
            speed: 0.5,
            bannerText: "Wide view surveillance",
            bannerWidth: 180,
            propellerSpeed: 10.0,
            hoverAmplitude: 5.0
        )
    ]
}
