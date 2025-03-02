//
//  WorldClockView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/2/25.
//


import SwiftUI

struct WorldClockView: View {
    @EnvironmentObject var viewModel: WorldClockViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("World Clock View")
                    .font(.title)
                
                Button("Add Clock") {
                    viewModel.showAddClockModal = true
                }
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .navigationTitle("World Clock")
        }
    }
}