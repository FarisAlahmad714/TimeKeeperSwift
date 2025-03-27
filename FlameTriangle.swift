//
//  FlameTriangle.swift
//  TimeKeeper
//
//  Created by Faris Alahmad on 3/10/25.
//
import SwiftUI

// Triangle shape used for visual effects in the app
struct FlameTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

// Inverted Triangle shape
struct InvertedFlameTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        
        return path
    }
}

// Custom shape for the dynamic island
struct IslandShape: Shape {
    var cornerRadius: CGFloat
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let notchCenterX = rect.midX
        let notchLeft = notchCenterX - (notchWidth / 2)
        let notchRight = notchCenterX + (notchWidth / 2)
        
        var path = Path()
        
        // Start at top left corner
        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))
        
        // Top edge to the notch
        path.addLine(to: CGPoint(x: notchLeft, y: rect.minY))
        
        // Bottom of the notch
        path.addLine(to: CGPoint(x: notchLeft, y: rect.minY + notchHeight))
        path.addLine(to: CGPoint(x: notchRight, y: rect.minY + notchHeight))
        
        // Continue the top edge
        path.addLine(to: CGPoint(x: notchRight, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY))
        
        // Top right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 270),
            endAngle: Angle(degrees: 0),
            clockwise: false
        )
        
        // Right edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        
        // Bottom right corner
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 0),
            endAngle: Angle(degrees: 90),
            clockwise: false
        )
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        
        // Bottom left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 90),
            endAngle: Angle(degrees: 180),
            clockwise: false
        )
        
        // Left edge
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
        
        // Top left corner
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
            radius: cornerRadius,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false
        )
        
        path.closeSubpath()
        return path
    }
}
