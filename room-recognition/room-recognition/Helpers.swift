//
//  Helpers.swift
//  room-recognition
//
//  Created by Enrique Calderon on 10/11/25.
//

import Foundation
import SceneKit
import ARKit

/// Helper to get xyz from a float4 column (used for transforms)
extension simd_float4 {
    // --- THIS IS THE FIX ---
    var xyz: simd_float3 { // It now correctly returns simd_float3
        return simd_float3(x, y, z)
    }
    // --- END OF FIX ---
}

/// Helper for SCNVector3 to calculate distance
extension SCNVector3 {
    /// Calculates the squared distance between two SCNVector3 points.
    /// This is faster than distance(to:) as it avoids the square root.
    func distanceSquared(to vector: SCNVector3) -> Float {
        let dx = self.x - vector.x
        let dy = self.y - vector.y
        let dz = self.z - vector.z
        return dx*dx + dy*dy + dz*dz
    }
    
    /// Calculates the actual distance between two SCNVector3 points.
    func distance(to vector: SCNVector3) -> Float {
        return sqrt(distanceSquared(to: vector))
    }
}

/// Add this extension to SCNGeometry to easily create a line
extension SCNGeometry {
    static func line(from vector1: SCNVector3, to vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        return SCNGeometry(sources: [source], elements: [element])
    }
}
