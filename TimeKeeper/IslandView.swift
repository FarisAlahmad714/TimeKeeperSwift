//
//  IslandView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI
struct IslandView: View {
    var body: some View {
        Rectangle()
            .fill(Color.green)
            .frame(height: 50)
            .frame(maxWidth: .infinity, alignment: .bottom)
    }
}
