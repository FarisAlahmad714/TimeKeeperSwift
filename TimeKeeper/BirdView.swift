//
//  BirdView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI
struct BirdView: View {
    @State private var position = CGPoint(x: -20, y: 100)
    
    var body: some View {
        Image(systemName: "bird.fill")
            .resizable()
            .frame(width: 20, height: 20)
            .foregroundColor(.black)
            .position(position)
            .onAppear {
                withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                    position = CGPoint(x: UIScreen.main.bounds.width + 20, y: 100 + CGFloat.random(in: -50...50))
                }
            }
    }
}
