import SpriteKit

class DroneScene: SKScene, SKPhysicsContactDelegate {
    // Physics categories for collision detection
    private let droneCategoryBitMask: UInt32 = 0x1 << 0
    private let bannerCategoryBitMask: UInt32 = 0x1 << 1
    private let worldBoundaryBitMask: UInt32 = 0x1 << 2
    
    // Properties to store drone configuration
    public var droneNode: SKNode?
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
    
    // Confetti emitter
    private var confettiEmitter: SKEmitterNode?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        
        physicsWorld.gravity = CGVector(dx: 0, dy: -0.5)
        physicsWorld.contactDelegate = self
        
        let boundary = SKPhysicsBody(edgeLoopFrom: frame.insetBy(dx: -100, dy: -100))
        boundary.categoryBitMask = worldBoundaryBitMask
        boundary.collisionBitMask = bannerCategoryBitMask
        boundary.friction = 0.2
        self.physicsBody = boundary
        
        setupDrone()
        setupConfettiEmitter()
    }
    
    private func setupConfettiEmitter() {
        confettiEmitter = SKEmitterNode()
        
        if let emitter = confettiEmitter {
            // Load your white star image
            var particleTexture = SKTexture(imageNamed: "spark")
            
            // Fallback to programmatic texture if needed
            if particleTexture.size() == CGSize.zero {
                print("WARNING: 'spark' image not found in asset catalog. Using programmatic texture instead.")
                particleTexture = createConfettiTexture()
            }
            
            // Even more vibrant colors with clearer separation
            let colors = [
                UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),    // Bright Red
                UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0),    // Bright Green
                UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0),    // Bright Blue
                UIColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0),    // Bright Yellow
                UIColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0),    // Bright Magenta
                UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 1.0)     // Bright Cyan
            ]
            
            emitter.particleColorSequence = SKKeyframeSequence(
                keyframeValues: colors,
                times: [0, 0.2, 0.4, 0.6, 0.8, 1.0]
            )
            
            // Set emitter properties
            emitter.particleTexture = particleTexture
            emitter.particleBirthRate = 0
            emitter.numParticlesToEmit = 200             // Even more particles
            emitter.particleLifetime = 3.5               // Much longer lifetime (was 2.5)
            emitter.particleLifetimeRange = 1.5          // More variance in lifetime
            emitter.emissionAngle = .pi / 2
            emitter.emissionAngleRange = .pi * 2         // Full 360° emission
            emitter.particleSpeed = 200                  // Even faster (more space)
            emitter.particleSpeedRange = 150             // Much more variance in speed
            emitter.yAcceleration = -100                 // Slightly lighter gravity for longer hang time
            emitter.particleAlpha = 1.0
            emitter.particleAlphaRange = 0.0
            emitter.particleScale = 0.1                  // Even smaller stars
            emitter.particleScaleRange = 0.05            // Some size variance
            emitter.particleColorBlendFactor = 1.0       // Maximum color blend
            
            // Add some spin to make it more dynamic
            emitter.particleRotationRange = .pi * 2
            emitter.particleRotationSpeed = 3.0          // Faster rotation
            
            emitter.isHidden = true
            addChild(emitter)
        }
    }

    
    // Method to create a programmatic texture for confetti particles
    private func createConfettiTexture() -> SKTexture {
        let size = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return SKTexture(image: UIImage()) // Fallback to empty texture
        }
        
        // Draw a small star shape
        context.setFillColor(UIColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let path = UIBezierPath()
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius: CGFloat = 4.0
        let points = 5
        let angle = CGFloat.pi * 2 / CGFloat(points * 2)
        
        for i in 0..<(points * 2) {
            let r = (i % 2 == 0) ? radius : radius / 2
            let x = center.x + r * cos(CGFloat(i) * angle)
            let y = center.y + r * sin(CGFloat(i) * angle)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.close()
        context.addPath(path.cgPath)
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image)
    }
    
    // And modify the triggering function for longer display:
    func triggerConfetti(at position: CGPoint) {
        guard let emitter = confettiEmitter else { return }
        
        emitter.position = position
        emitter.isHidden = false
        emitter.particleBirthRate = 300 // More intense burst
        
        // Reset after a longer burst
        let wait = SKAction.wait(forDuration: 1.0) // Longer emission time (was 0.5)
        let stop = SKAction.run {
            emitter.particleBirthRate = 0
            // Don't hide immediately - let particles fade out naturally
            
            // Hide after all particles are gone
            let finalWait = SKAction.wait(forDuration: 4.0) // Wait for particles to clear
            let finalHide = SKAction.run {
                emitter.isHidden = true
                emitter.resetSimulation() // Reset for next use
            }
            emitter.run(SKAction.sequence([finalWait, finalHide]))
        }
        emitter.run(SKAction.sequence([wait, stop]))
    }
    
    private func setupDrone() {
        guard let droneObject = droneObject else { return }
        
        let drone = SKNode()
        drone.position = CGPoint(x: frame.midX, y: frame.midY)
        
        let bodyTexture: SKTexture
        let bodySize: CGSize
        let propellerPositions: [CGPoint]
        
        switch droneObject.droneType {
        case .quadcopter:
            if let image = UIImage(named: "drone_quad_body") {
                bodyTexture = SKTexture(image: image)
            } else {
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
        
        let bodySprite = SKSpriteNode(texture: bodyTexture)
        bodySprite.size = bodySize
        bodySprite.name = "droneBody"
        
        let bodyPhysics = SKPhysicsBody(rectangleOf: bodySize)
        bodyPhysics.isDynamic = false
        bodyPhysics.categoryBitMask = droneCategoryBitMask
        bodyPhysics.contactTestBitMask = bannerCategoryBitMask
        bodyPhysics.collisionBitMask = 0
        bodySprite.physicsBody = bodyPhysics
        
        drone.addChild(bodySprite)
        self.droneBody = bodySprite
        
        let camera = SKShapeNode(circleOfRadius: 5)
        camera.fillColor = .black
        camera.position = CGPoint(x: 0, y: 5)
        drone.addChild(camera)
        
        let statusLight = SKShapeNode(circleOfRadius: 3)
        statusLight.fillColor = .green
        statusLight.position = CGPoint(x: 0, y: -8)
        
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ])
        statusLight.run(SKAction.repeatForever(blink))
        drone.addChild(statusLight)
        
        setupPropellers(for: drone, positions: propellerPositions)
        
        if let adContent = droneObject.adContent, adContent.isActive {
            let adText = droneObject.bannerText ?? adContent.advertiserName
            setupAdLabel(for: drone, text: adText)
        }
        
        addChild(drone)
        self.droneNode = drone
        
        drone.position = CGPoint(x: droneObject.position.x, y: droneObject.position.y)
        drone.xScale = isMovingRight ? 1 : -1
        
        animatePropellers()
    }
    
    private func createTextureForDroneType(_ type: DroneType) -> SKTexture {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let context = UIGraphicsGetCurrentContext()!
        
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
            context.move(to: CGPoint(x: 30, y: 45))
            context.addLine(to: CGPoint(x: 50, y: 35))
            context.addLine(to: CGPoint(x: 70, y: 45))
            context.addLine(to: CGPoint(x: 70, y: 55))
            context.addLine(to: CGPoint(x: 50, y: 65))
            context.addLine(to: CGPoint(x: 30, y: 55))
            context.closePath()
        }
        
        context.fillPath()
        
        context.setFillColor(UIColor.black.cgColor)
        context.addEllipse(in: CGRect(x: 45, y: 45, width: 10, height: 10))
        context.fillPath()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return SKTexture(image: image)
    }
    
    private func setupPropellers(for droneNode: SKNode, positions: [CGPoint]) {
        propellerNodes.forEach { $0.removeFromParent() }
        propellerNodes.removeAll()
        
        for (index, position) in positions.enumerated() {
            let propeller = SKSpriteNode(color: .black, size: CGSize(width: 20, height: 3))
            propeller.position = position
            propeller.name = "propeller_\(index)"
            
            let secondBlade = SKSpriteNode(color: .black, size: CGSize(width: 3, height: 20))
            secondBlade.position = .zero
            propeller.addChild(secondBlade)
            
            let hub = SKShapeNode(circleOfRadius: 3)
            hub.fillColor = .gray
            hub.strokeColor = .darkGray
            propeller.addChild(hub)
            
            droneNode.addChild(propeller)
            propellerNodes.append(propeller)
        }
    }
    
    private func setupAdLabel(for droneNode: SKNode, text: String) {
        let adLabelContainer = SKNode()
        adLabelContainer.name = "adLabel"
        adLabelContainer.position = droneNode.position
        adLabelContainer.position.y -= 30
        
        let textWidth: CGFloat = CGFloat(text.count) * 10.0
        let boxWidth: CGFloat = max(140.0, textWidth + 40.0)
        
        let backgroundRect = CGRect(x: -boxWidth/2, y: -15, width: boxWidth, height: 30)
        let labelBackground = SKShapeNode(rect: backgroundRect, cornerRadius: 5)
        labelBackground.name = "background"
        labelBackground.fillColor = UIColor.black.withAlphaComponent(0.7)
        labelBackground.strokeColor = UIColor.white.withAlphaComponent(0.5)
        labelBackground.lineWidth = 1
        adLabelContainer.addChild(labelBackground)
        
        let textNode = SKLabelNode(text: text)
        textNode.name = "text"
        textNode.fontName = "Helvetica-Bold"
        textNode.fontSize = 14
        textNode.fontColor = .white
        textNode.position = CGPoint(x: 0, y: 0)
        textNode.horizontalAlignmentMode = .center
        textNode.verticalAlignmentMode = .center
        adLabelContainer.addChild(textNode)
        
        let starNode = SKSpriteNode(color: .yellow, size: CGSize(width: 10, height: 10))
        starNode.name = "star"
        let leftOffset: CGFloat = -(boxWidth/2.0 - 10.0)
        let rightOffset: CGFloat = (boxWidth/2.0 - 10.0)
        let starOffset: CGFloat = isMovingRight ? leftOffset : rightOffset
        starNode.position = CGPoint(x: starOffset, y: 0)
        adLabelContainer.addChild(starNode)
        
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.5),
            SKAction.scale(to: 1.0, duration: 0.5)
        ])
        adLabelContainer.run(SKAction.repeatForever(pulse))
        
        self.addChild(adLabelContainer)
        self.adLabelNode = adLabelContainer
    }
    
    private func updateAdLabel() {
        guard let adLabelNode = adLabelNode, let droneNode = droneNode else { return }
        
        let textNode = adLabelNode.childNode(withName: "text") as? SKLabelNode
        let backgroundNode = adLabelNode.childNode(withName: "background") as? SKShapeNode
        let starNode = adLabelNode.childNode(withName: "star") as? SKSpriteNode
        
        if let star = starNode, let bg = backgroundNode {
            let boxWidth = bg.frame.width
            let leftOffset: CGFloat = -(boxWidth/2.0 - 10.0)
            let rightOffset: CGFloat = (boxWidth/2.0 - 10.0)
            let starOffset: CGFloat = isMovingRight ? leftOffset : rightOffset
            star.position.x = starOffset
        }
        
        if let text = textNode {
            text.zRotation = 0
            adLabelNode.xScale = 1.0
        }
    }
    
    private func animatePropellers() {
        guard let droneObject = droneObject else { return }
        
        let rotationDuration = 1.0 / Double(droneObject.propellerSpeed)
        
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
        
        if lastUpdateTime == 0 {
            lastUpdateTime = currentTime
        }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime
        
        hoverPhase += CGFloat(dt) * 2.0
        let hoverOffset = sin(hoverPhase) * droneObject.hoverAmplitude
        
        droneNode.position.y = droneObject.position.y + hoverOffset
        
        if isMovingRight {
            droneNode.position.x += droneObject.speed
        } else {
            droneNode.position.x -= droneObject.speed
        }
        
        let screenWidth = self.frame.width
        if droneNode.position.x > screenWidth + 50 {
            isMovingRight = false
            droneNode.xScale = -1
            
            if let adLabelNode = adLabelNode {
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
            
            if let adLabelNode = adLabelNode {
                if adLabelNode.parent == droneNode {
                    let worldPosition = droneNode.convert(adLabelNode.position, to: self)
                    adLabelNode.removeFromParent()
                    adLabelNode.position = worldPosition
                    self.addChild(adLabelNode)
                }
            }
        }
        
        if let adLabelNode = adLabelNode {
            if adLabelNode.parent != droneNode {
                adLabelNode.position = CGPoint(x: droneNode.position.x, y: droneNode.position.y - 30)
            }
        }
        
        animatePropellers()
        updateAdLabel()
    }
}

// Extension to support vector operations on CGVector
extension CGVector {
    static func * (lhs: CGVector, rhs: CGFloat) -> CGVector {
        return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
    }
}

// UIImage extension for color detection
extension UIImage {
    func isPredominantlyBlackOrWhite() -> Bool {
        guard let cgImage = self.cgImage else { return false }
        
        // Convert to a bitmap context
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        ) else { return false }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let pixelData = context.data else { return false }
        
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)
        var blackOrWhitePixelCount = 0
        let totalPixels = width * height
        
        // Analyze each pixel
        for i in 0..<totalPixels {
            let offset = i * bytesPerPixel
            let red = Float(data[offset]) / 255.0
            let green = Float(data[offset + 1]) / 255.0
            let blue = Float(data[offset + 2]) / 255.0
            
            // Consider a pixel "black" if all components are low, "white" if all are high
            if (red < 0.2 && green < 0.2 && blue < 0.2) || (red > 0.8 && green > 0.8 && blue > 0.8) {
                blackOrWhitePixelCount += 1
            }
        }
        
        // Return true if more than 70% of pixels are black or white
        let percentage = Float(blackOrWhitePixelCount) / Float(totalPixels)
        return percentage > 0.5
    }
}
