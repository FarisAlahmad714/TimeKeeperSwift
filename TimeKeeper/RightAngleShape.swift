//
//  RightAngleShape.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/9/25.
//

import SwiftUI

struct RightAngleShape: Shape {
    var progress: Double // 0.0 to 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let angle = Angle(degrees: 90 * min(progress * 2, 1)) // Opens to 90° by noon
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + 100 * cos(angle.radians), y: center.y - 100 * sin(angle.radians)))
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + 100, y: center.y))
        return path
    }
}
