//
//  DroneScene.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/29/25.
//
// DroneScene.swift

import SpriteKit

class DroneScene: SKScene, SKPhysicsContactDelegate {
    // Physics categories for collision detection
    private let droneCategoryBitMask: UInt32 = 0x1 << 0
    private let bannerCategoryBitMask: UInt32 = 0x1 << 1
    private let worldBoundaryBitMask: UInt32 = 0x1 << 2
    
    // Properties to store drone configuration
    private var droneNode: SKNode?
    private var droneBody: SKSpriteNode?
    private var propellerNodes: [SKSpriteNode] = []
    private var bannerNode: SKNode?
    private var bannerPhysicsBody: SKPhysicsBody?
    private var bannerTextNode: SKLabelNode?
    private var adLabelNode: SKNode?
    
    // Animation control
    private var lastUpdateTime: TimeInterval = 0
    private var hoverPhase: CGFloat = 0
    
    // Configuration
    var droneObject: DroneAdObject?
    var isMovingRight: Bool = true
    
    override func didMove(to view: SKView) {
        // Setup basic scene properties
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        // Setup physics world with low gravity
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.5)
        physicsWorld.contactDelegate = self
        
        // Add boundary to keep banner in frame
        let boundary = SKPhysicsBody(edgeLoopFrom: frame.insetBy(dx: -100, dy: -100))
        boundary.categoryBitMask = worldBoundaryBitMask
        boundary.collisionBitMask = bannerCategoryBitMask
        boundary.friction = 0.2
        self.physicsBody = boundary
        
        setupDrone()
    }
    
    private func setupDrone() {
        guard let droneObject = droneObject else { return }
        
        // Create main drone container
        let drone = SKNode()
        drone.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Create drone body based on type
        let bodyTexture: SKTexture
        let bodySize: CGSize
        let propellerPositions: [CGPoint]
        
        switch droneObject.droneType {
        case .quadcopter:
            if let image = UIImage(named: "drone_quad_body") {
                bodyTexture = SKTexture(image: image)
            } else {
                // Fallback if image is missing
                bodyTexture = createTextureForDroneType(.quadcopter)
            }
            bodySize = CGSize(width: 40, height: 20)
            propellerPositions = [
                CGPoint(x: -20, y: -20),
                CGPoint(x: 20, y: -20),
                CGPoint(x: 20, y: 20),
                CGPoint(x: -20, y: 20)
            ]
        case .hexacopter:
            if let image = UIImage(named: "drone_hexa_body") {
                bodyTexture = SKTexture(image: image)
            } else {
                bodyTexture = createTextureForDroneType(.hexacopter)
            }
            bodySize = CGSize(width: 50, height: 25)
            propellerPositions = [
                CGPoint(x: -25, y: -20),
                CGPoint(x: 0, y: -25),
                CGPoint(x: 25, y: -20),
                CGPoint(x: 25, y: 20),
                CGPoint(x: 0, y: 25),
                CGPoint(x: -25, y: 20)
            ]
        case .deliveryDrone:
            if let image = UIImage(named: "drone_delivery_body") {
                bodyTexture = SKTexture(image: image)
            } else {
                bodyTexture = createTextureForDroneType(.deliveryDrone)
            }
            bodySize = CGSize(width: 45, height: 30)
            propellerPositions = [
                CGPoint(x: -25, y: -20),
                CGPoint(x: 25, y: -20),
                CGPoint(x: 25, y: 20),
                CGPoint(x: -25, y: 20)
            ]
        case .racingDrone:
            if let image = UIImage(named: "drone_racing_body") {
                bodyTexture = SKTexture(image: image)
            } else {
                bodyTexture = createTextureForDroneType(.racingDrone)
            }
            bodySize = CGSize(width: 35, height: 15)
            propellerPositions = [
                CGPoint(x: -18, y: -15),
                CGPoint(x: 18, y: -15),
                CGPoint(x: 18, y: 15),
                CGPoint(x: -18, y: 15)
            ]
        }
        
        // Create and add the body sprite
        let bodySprite = SKSpriteNode(texture: bodyTexture)
        bodySprite.size = bodySize
        bodySprite.name = "droneBody"
        
        // Add physics to drone body
        let bodyPhysics = SKPhysicsBody(rectangleOf: bodySize)
        bodyPhysics.isDynamic = false  // Drone doesn't respond to physics
        bodyPhysics.categoryBitMask = droneCategoryBitMask
        bodyPhysics.contactTestBitMask = bannerCategoryBitMask
        bodyPhysics.collisionBitMask = 0  // Doesn't collide with anything
        bodySprite.physicsBody = bodyPhysics
        
        drone.addChild(bodySprite)
        self.droneBody = bodySprite
        
        // Add camera/sensor
        let camera = SKShapeNode(circleOfRadius: 5)
        camera.fillColor = .black
        camera.position = CGPoint(x: 0, y: 5)
        drone.addChild(camera)
        
        // Add status light
        let statusLight = SKShapeNode(circleOfRadius: 3)
        statusLight.fillColor = .green
        statusLight.position = CGPoint(x: 0, y: -8)
        
        // Add blinking animation to status light
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        statusLight.run(SKAction.repeatForever(blink))
        drone.addChild(statusLight)
        
        // Add propellers
        setupPropellers(for: drone, positions: propellerPositions)
        
        // Add the ad label (styled like spaceship)
        if let adContent = droneObject.adContent, adContent.isActive {
            let adText = droneObject.bannerText ?? adContent.advertiserName
            setupAdLabel(for: drone, text: adText)
        }
        
        // Add the completed drone to the scene
        addChild(drone)
        self.droneNode = drone
        
        // Set initial position
        drone.position = CGPoint(x: droneObject.position.x, y: droneObject.position.y)
        drone.xScale = isMovingRight ? 1 : -1
        
        // Start animations
        animatePropellers()
    }
    
    private func createTextureForDroneType(_ type: DroneType) -> SKTexture {
        // Create a placeholder texture programmatically if image asset is missing
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
        // Set up drone body based on type
        context.setFillColor(UIColor.darkGray.cgColor)
        
        switch type {
        case .quadcopter:
            context.addRect(CGRect(x: 35, y: 40, width: 30, height: 20))
        case .hexacopter:
            context.move(to: CGPoint(x: 50, y: 30))
            context.addLine(to: CGPoint(x: 70, y: 40))
            context.addLine(to: CGPoint(x: 70, y: 60))
            context.addLine(to: CGPoint(x: 50, y: 70))
            context.addLine(to: CGPoint(x: 30, y: 60))
            context.addLine(to: CGPoint(x: 30, y: 40))
            context.closePath()
        case .deliveryDrone:
            context.addRect(CGRect(x: 30, y: 35, width: 40, height: 30))
            context.addRect(CGRect(x: 40, y: 65, width: 20, height: 10))
        case .racingDrone:
            // Racing drone has more aerodynamic shape
            context.move(to: CGPoint(x: 30, y: 45))
            context.addLine(to: CGPoint(x: 50, y: 35))
            context.addLine(to: CGPoint(x: 70, y: 45))
            context.addLine(to: CGPoint(x: 70, y: 55))
            context.addLine(to: CGPoint(x: 50, y: 65))
            context.addLine(to: CGPoint(x: 30, y: 55))
            context.closePath()
        }
        
        context.fillPath()
        
        // Draw camera
        context.setFillColor(UIColor.black.cgColor)
        context.addEllipse(in: CGRect(x: 45, y: 45, width: 10, height: 10))
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image)
    }
    
    private func setupPropellers(for droneNode: SKNode, positions: [CGPoint]) {
        // Clear existing propellers
        propellerNodes.forEach { $0.removeFromParent() }
        propellerNodes.removeAll()
        
        // Create propellers
        for (index, position) in positions.enumerated() {
            // Create propeller sprite
            let propeller = SKSpriteNode(color: .black, size: CGSize(width: 20, height: 3))
            propeller.position = position
            propeller.name = "propeller_\(index)"
            
            // Add a second blade for propeller cross
            let secondBlade = SKSpriteNode(color: .black, size: CGSize(width: 3, height: 20))
            secondBlade.position = .zero
            propeller.addChild(secondBlade)
            
            // Add a center hub
            let hub = SKShapeNode(circleOfRadius: 3)
            hub.fillColor = .gray
            hub.strokeColor = .darkGray
            propeller.addChild(hub)
            
            droneNode.addChild(propeller)
            propellerNodes.append(propeller)
        }
    }
    
    private func setupAdLabel(for droneNode: SKNode, text: String) {
        // Create a label that's not a child of the drone but follows it independently
        let adLabelContainer = SKNode()
        adLabelContainer.name = "adLabel"
        adLabelContainer.position = droneNode.position // Start at drone's position
        adLabelContainer.position.y -= 30 // Position below drone
        
        // Rest of the label setup remains the same...
        let textWidth: CGFloat = CGFloat(text.count) * 10.0
        let boxWidth: CGFloat = max(140.0, textWidth + 40.0)
        
        // Background
        let backgroundRect = CGRect(x: -boxWidth/2, y: -15, width: boxWidth, height: 30)
        let labelBackground = SKShapeNode(rect: backgroundRect, cornerRadius: 5)
        labelBackground.name = "background"
        labelBackground.fillColor = UIColor.black.withAlphaComponent(0.7)
        labelBackground.strokeColor = UIColor.white.withAlphaComponent(0.5)
        labelBackground.lineWidth = 1
        adLabelContainer.addChild(labelBackground)
        
        // Text
        let textNode = SKLabelNode(text: text)
        textNode.name = "text"
        textNode.fontName = "Helvetica-Bold"
        textNode.fontSize = 14
        textNode.fontColor = .white
        textNode.position = CGPoint(x: 0, y: 0)
        textNode.horizontalAlignmentMode = .center
        textNode.verticalAlignmentMode = .center
        adLabelContainer.addChild(textNode)
        
        // Star
        let starNode = SKSpriteNode(color: .yellow, size: CGSize(width: 10, height: 10))
        starNode.name = "star"
        let leftOffset: CGFloat = -(boxWidth/2.0 - 10.0)
        let rightOffset: CGFloat = (boxWidth/2.0 - 10.0)
        let starOffset: CGFloat = isMovingRight ? leftOffset : rightOffset
        starNode.position = CGPoint(x: starOffset, y: 0)
        adLabelContainer.addChild(starNode)
        
        // Animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        adLabelContainer.run(SKAction.repeatForever(pulse))
        
        // Add to scene, not to the drone
        self.addChild(adLabelContainer)
        self.adLabelNode = adLabelContainer
    }
    
    private func updateAdLabel() {
        guard let adLabelNode = adLabelNode, let droneNode = droneNode else { return }
        
        // Get the text node and star
        let textNode = adLabelNode.childNode(withName: "text") as? SKLabelNode
        let backgroundNode = adLabelNode.childNode(withName: "background") as? SKShapeNode
        let starNode = adLabelNode.childNode(withName: "star") as? SKSpriteNode
        
        // Update star position based on direction
        if let star = starNode, let bg = backgroundNode {
            let boxWidth = bg.frame.width
            let leftOffset: CGFloat = -(boxWidth/2.0 - 10.0)
            let rightOffset: CGFloat = (boxWidth/2.0 - 10.0)
            let starOffset: CGFloat = isMovingRight ? leftOffset : rightOffset
            star.position.x = starOffset
        }
        
        // CRITICAL FIX: Ensure the text and entire label stays correctly oriented when drone changes direction
        if let text = textNode {
            // Reset rotation to ensure text is upright
            text.zRotation = 0
            
            // Keep text readable (not mirrored) when drone changes direction
            adLabelNode.xScale = 1.0  // Always keep the label at normal scale
        }
    }
    
    
    private func animatePropellers() {
        guard let droneObject = droneObject else { return }
        
        // Create a rotation action for propellers
        let rotationDuration = 1.0 / Double(droneObject.propellerSpeed)
        
        // Apply to all propellers
        for propeller in propellerNodes {
            if propeller.action(forKey: "rotate") == nil {
                let rotateAction = SKAction.rotate(byAngle: .pi * 2, duration: rotationDuration)
                let repeatAction = SKAction.repeatForever(rotateAction)
                propeller.run(repeatAction, withKey: "rotate")
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard let droneObject = droneObject, let droneNode = droneNode else { return }
        
        // Calculate delta time for smooth animation
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        // Update hover effect
        hoverPhase += CGFloat(dt) * 2.0
        let hoverOffset = sin(hoverPhase) * droneObject.hoverAmplitude
        
        // Apply subtle hover movement to drone
        droneNode.position.y = droneObject.position.y + hoverOffset
        
        // Move drone horizontally based on direction and speed
        if isMovingRight {
            droneNode.position.x += droneObject.speed
        } else {
            droneNode.position.x -= droneObject.speed
        }
        
        // Check if drone has reached screen edge to change direction
        let screenWidth = self.frame.width
        if droneNode.position.x > screenWidth + 50 {
            isMovingRight = false
            droneNode.xScale = -1
            
            // Force adLabelNode to stay upright when drone flips direction
            if let adLabelNode = adLabelNode {
                // Detach label from parent if it's a child of droneNode
                if adLabelNode.parent == droneNode {
                    let worldPosition = droneNode.convert(adLabelNode.position, to: self)
                    adLabelNode.removeFromParent()
                    adLabelNode.position = worldPosition
                    self.addChild(adLabelNode)
                }
            }
        } else if droneNode.position.x < -50 {
            isMovingRight = true
            droneNode.xScale = 1
            
            // Force adLabelNode to stay upright when drone flips direction
            if let adLabelNode = adLabelNode {
                // Detach label from parent if it's a child of droneNode
                if adLabelNode.parent == droneNode {
                    let worldPosition = droneNode.convert(adLabelNode.position, to: self)
                    adLabelNode.removeFromParent()
                    adLabelNode.position = worldPosition
                    self.addChild(adLabelNode)
                }
            }
        }
        
        // Update the ad label position to follow the drone
        if let adLabelNode = adLabelNode {
            if adLabelNode.parent != droneNode {
                // If label is not a child of drone, update its position to follow the drone
                adLabelNode.position = CGPoint(x: droneNode.position.x, y: droneNode.position.y - 30)
            }
        }
        
        // Make sure propellers keep spinning
        animatePropellers()
        
        // Update ad label
        updateAdLabel()
    }
}
// Extension to support vector operations on CGVector
extension CGVector {
    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
}
