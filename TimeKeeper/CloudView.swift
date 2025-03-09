//
//  CloudView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI
struct CloudView: View {
    @State private var offset: CGFloat = -100
    let speed: Double
    let yPosition: CGFloat

    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .frame(width: 100, height: 50)
            .foregroundColor(.white.opacity(0.7))
            .offset(x: offset, y: yPosition)
            .onAppear {
                withAnimation(Animation.linear(duration: speed).repeatForever(autoreverses: false)) {
                    offset = UIScreen.main.bounds.width + 100
                }
            }
    }
}

