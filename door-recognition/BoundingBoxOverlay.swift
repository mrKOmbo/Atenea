//
//  BoundingBoxOverlay.swift
//  door-recognition
//
//  Created by Enrique Calderon on 04/11/25.
//

import SwiftUI
import Vision

/// A view that overlays bounding boxes on the camera feed.
struct BoundingBoxOverlay: View {
    // The array of normalized bounding boxes.
    var boundingBoxes: [CGRect]
    
    var body: some View {
        // GeometryReader gives us the size of the parent view (the ZStack).
        GeometryReader { geometry in
            // Loop over all the detected bounding boxes.
            ForEach(boundingBoxes, id: \.self) { box in
                // Convert the normalized Vision coordinates to screen coordinates.
                let transformedRect = self.transformBoundingBox(box, in: geometry.size)
                
                // Draw the rectangle.
                Rectangle()
                    .path(in: transformedRect)
                    .stroke(Color.red, lineWidth: 2)
            }
        }
    }
    
    /// Converts a normalized bounding box from Vision's coordinate system
    /// (origin at bottom-left) to SwiftUI's coordinate system
    /// (origin at top-left).
    private func transformBoundingBox(_ normalizedRect: CGRect, in frameSize: CGSize) -> CGRect {
        
        // 1. Vision's origin is bottom-left, SwiftUI's is top-left.
        // We flip the Y-coordinate.
        let y = (1 - normalizedRect.origin.y - normalizedRect.height) * frameSize.height
        let x = normalizedRect.origin.x * frameSize.width
        let width = normalizedRect.width * frameSize.width
        let height = normalizedRect.height * frameSize.height
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}

// Add a public conformance to Hashable for CGRect to be used in ForEach
extension CGRect: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin.x)
        hasher.combine(origin.y)
        hasher.combine(size.width)
        hasher.combine(size.height)
    }
}
