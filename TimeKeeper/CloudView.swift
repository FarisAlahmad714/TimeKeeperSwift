//
//  CloudView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI
struct CloudView: View {
    @State private var offset: CGFloat = -100
    
    var body: some View {
        Image(systemName: "cloud.fill")
            .resizable()
            .frame(width: 50, height: 30)
            .foregroundColor(.white.opacity(0.5))
            .offset(x: offset, y: 50)
            .onAppear {
                withAnimation(Animation.linear(duration: 10).repeatForever(autoreverses: false)) {
                    offset = UIScreen.main.bounds.width + 100
                }
            }
    }
}

