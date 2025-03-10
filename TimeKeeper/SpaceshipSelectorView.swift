//
//  SpaceshipSelectorView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//


import SwiftUI

// Selector UI to choose a spaceship
struct SpaceshipSelectorView: View {
    @EnvironmentObject var viewModel: SpaceshipViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Select Your Spaceship")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 20) {
                            ForEach(viewModel.availableSpaceships) { ship in
                                SpaceshipGridItem(ship: ship)
                                    .onTapGesture {
                                        viewModel.selectSpaceship(ship)
                                        dismiss()
                                    }
                            }
                            
                            // Premium ships that are not owned yet
                            ForEach(Spaceship.templates.filter { $0.premium && !viewModel.availableSpaceships.contains(where: { $0.name == $0.name }) }) { ship in
                                SpaceshipGridItem(ship: ship, locked: true)
                                    .onTapGesture {
                                        viewModel.purchasePremiumShip(ship)
                                    }
                            }
                        }
                        .padding()
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct SpaceshipGridItem: View {
    let ship: Spaceship
    var locked: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(locked ? Color.gray.opacity(0.3) : Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                // Use either the ship image asset or fall back to system image
                Group {
                    if UIImage(named: ship.imageAsset) != nil {
                        Image(ship.imageAsset)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        // Fallback to SF Symbol
                        Image(systemName: getSystemImageName(for: ship.name))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .frame(width: 60, height: 60)
                .opacity(locked ? 0.6 : 1.0)
                
                if locked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                        .offset(y: 30)
                }
            }
            
            Text(ship.name)
                .font(.caption)
                .foregroundColor(.white)
            
            if locked {
                Text("Premium")
                    .font(.caption2)
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ship.premium ? Color.yellow.opacity(0.6) : Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // Helper function to get system image name based on ship type
    private func getSystemImageName(for shipName: String) -> String {
        switch shipName.lowercased() {
        case "explorer": return "airplane"
        case "cruiser": return "ferry"
        case "fighter": return "bolt.horizontal.fill"
        case "hauler": return "shippingbox"
        case "corvette": return "bolt"
        case "shuttle": return "tram"
        case "destroyer": return "target"
        case "transport": return "bus"
        case "flagship": return "shield"
        default: return "airplane.circle"
        }
    }
}