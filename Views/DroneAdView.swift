//
//  DroneAdView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/29/25.
//


import SwiftUI
import FirebaseAnalytics

struct DroneAdView: View {
    @StateObject private var viewModel = DroneViewModel()
    @State private var isTransitioningOrientation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let activeDrone = viewModel.activeDrone, activeDrone.visible && !isTransitioningOrientation {
                    DroneSpriteView(
                        droneObject: activeDrone,
                        isMovingRight: viewModel.isMovingRight,
                        onTap: { scene in // Modified to pass DroneScene
                            if !isTransitioningOrientation {
                                viewModel.logInteraction()
                                if activeDrone.adContent != nil {
                                    viewModel.handleAdTap(scene: scene) // Pass scene to handleAdTap
                                }
                            }
                        }
                    )
                    .frame(width: geometry.size.width, height: 200)
                    .position(x: geometry.size.width / 2, y: 400)
                    .opacity(isTransitioningOrientation ? 0 : 1)
                }
            }
            .onAppear {
                if viewModel.availableDrones.isEmpty {
                    viewModel.initializeDefaultDrones()
                }
                
                if viewModel.activeDrone == nil, let firstDrone = viewModel.availableDrones.first {
                    var updatedDrone = firstDrone
                    updatedDrone.position = CGPoint(x: -50, y: 150)
                    updatedDrone.visible = true
                    updatedDrone.rotation = 0
                    viewModel.selectDrone(updatedDrone)
                    viewModel.startFlying()
                }
                
                // Add orientation change handling
                NotificationCenter.default.addObserver(
                    forName: UIDevice.orientationDidChangeNotification,
                    object: nil,
                    queue: .main
                ) { [self] _ in
                    let currentOrientation = UIDevice.current.orientation
                    
                    if currentOrientation.isPortrait || currentOrientation.isLandscape {
                        // Set flags to pause animations
                        isTransitioningOrientation = true
                        
                        // Force stop animations in the ViewModel
                        viewModel.stopFlying()
                        
                        // Wait for layout to stabilize
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                // Resume animations
                                isTransitioningOrientation = false
                            }
                            
                            // Resume animations if portrait
                            if currentOrientation.isPortrait {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    viewModel.startFlying()
                                }
                            }
                        }
                    }
                }
                
                Analytics.logEvent("drone_ad_view_appeared", parameters: [:])
            }
            .onDisappear {
                // Remove the observer when view disappears
                NotificationCenter.default.removeObserver(
                    self,
                    name: UIDevice.orientationDidChangeNotification,
                    object: nil
                )
                viewModel.stopFlying()
            }
        }
    }
}
