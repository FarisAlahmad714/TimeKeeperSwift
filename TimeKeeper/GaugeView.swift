//
//  GaugeView.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI
struct GaugeView: View {
    let selectedTime: Date
    let totalMinutesInDay: Int
    let calendar = Calendar.current
    let startOfDay = Calendar.current.startOfDay(for: Date())
    
    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height)
            let minutesSinceMidnight = calendar.dateComponents([.minute], from: startOfDay, to: selectedTime).minute!
            let progress = Double(minutesSinceMidnight) / Double(totalMinutesInDay)
            let angle = Angle(degrees: 90 * progress)
            
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
            }
            .stroke(Color.gray, lineWidth: 10)
            
            Path { path in
                path.addArc(center: center, radius: radius, startAngle: .degrees(180), endAngle: .degrees(180 + angle.degrees), clockwise: false)
            }
            .stroke(Color.blue, lineWidth: 10)
        }
        .frame(height: 100)
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 75)
    }
}
