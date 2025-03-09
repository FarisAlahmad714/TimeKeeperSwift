//
//  BirdView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI
struct BirdView: View {
    @State private var xPosition: CGFloat = -50
    @State private var yPosition: CGFloat = 50

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 5))
            path.addLine(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: -10, y: 5))
            path.closeSubpath()
        }
        .fill(Color.black)
        .frame(width: 20, height: 10)
        .offset(x: xPosition, y: yPosition)
        .onAppear {
            withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses: false)) {
                xPosition = UIScreen.main.bounds.width + 50
                yPosition += CGFloat.random(in: -20...20)
            }
        }
    }
}
