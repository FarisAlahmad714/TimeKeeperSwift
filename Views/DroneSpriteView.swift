//
//  DroneSpriteView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/29/25.
//


import SwiftUI
import SpriteKit

struct DroneSpriteView: UIViewRepresentable {
    var droneObject: DroneAdObject
    var isMovingRight: Bool
    var onTap: () -> Void
    
    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        
        // Create and configure the scene
        let scene = DroneScene(size: CGSize(width: UIScreen.main.bounds.width, height: 200))
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.droneObject = droneObject
        scene.isMovingRight = isMovingRight
        
        // Add tap gesture recognizer
        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        view.addGestureRecognizer(tapRecognizer)
        
        // Present the scene
        view.presentScene(scene)
        
        return view
    }
    
    func updateUIView(_ uiView: SKView, context: Context) {
        if let scene = uiView.scene as? DroneScene {
            scene.droneObject = droneObject
            scene.isMovingRight = isMovingRight
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: DroneSpriteView
        
        init(_ parent: DroneSpriteView) {
            self.parent = parent
        }
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            parent.onTap()
        }
    }
}