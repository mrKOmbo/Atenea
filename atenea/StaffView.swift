//
//  StaffView.swift
//  atenea
//
//  Created by Enrique Calderon on 30/10/25.
//

import SwiftUI
import RealityKit
import ARKit
import NearbyInteraction

struct StaffView: View {
    // 1. Create the manager, specifying the .staff role
    @StateObject private var niManager = NearbyInteractionManager(role: .staff)
    
    var body: some View {
        VStack {
            Text("Staff")
                .font(.largeTitle)
            
            Text(niManager.connectionStatus)
                .font(.headline)
            
            // 3. Pass the ARViewContainer the latest nearbyObject
            ARViewContainer(nearbyObject: niManager.nearbyObject)
                .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            // 2. Start the manager when the view appears
            niManager.start()
        }
        .onDisappear {
            niManager.stop()
        }
    }
}

// This struct bridges SwiftUI to ARKit/RealityKit
struct ARViewContainer: UIViewRepresentable {
    
    var nearbyObject: NINearbyObject?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Start a basic AR world-tracking session
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        
        // Create an anchor for the camera
        // We will attach our arrow to this
        let cameraAnchor = AnchorEntity(.camera)
        arView.scene.addAnchor(cameraAnchor)
        
        // Create the arrow model (a simple box for this demo)
        // In a real app, you'd load a .usdz arrow model
        let arrowEntity = ModelEntity(
            mesh: .generateBox(size: [0.1, 0.1, 0.5]), // W, H, L
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        // Give it a name so we can find it later
        arrowEntity.name = "arrow"
        arrowEntity.position = [0, 0, -1.0] // Place 1m in front
        
        cameraAnchor.addChild(arrowEntity)
        
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        // This function is called every time 'nearbyObject' changes
        
        // Find our arrow in the scene
        guard let cameraAnchor = arView.scene.anchors.first(where: { $0.name == "cameraAnchor" }),
              let arrowEntity = cameraAnchor.findEntity(named: "arrow") else {
            return
        }
        
        if let object = nearbyObject {
            // We have a valid object!
            
            guard let niDirection = object.direction else {
                arrowEntity.isEnabled = false
                return 
            }
            
            // Make arrow visible
            arrowEntity.isEnabled = true
            
            // The NI direction is relative to the *device*.
            // We must transform it into ARKit's *world space*.
            guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return }
            
            // Create a 4x4 matrix from the NI direction
            var directionTransform = matrix_identity_float4x4
            directionTransform.columns.3.x = niDirection.x
            directionTransform.columns.3.y = niDirection.y
            directionTransform.columns.3.z = niDirection.z
            
            // Combine the camera and direction transforms
            let worldTransform = cameraTransform * directionTransform
            
            // Make the arrow entity look at the target's position
            // We position the arrow 1m in front of the camera
            // and tell it to "look at" the world-space position of the client.
            let targetPosition = SIMD3<Float>(worldTransform.columns.3.x,
                                               worldTransform.columns.3.y,
                                               worldTransform.columns.3.z)
            
            arrowEntity.look(at: targetPosition, from: [0, 0, -1.0], relativeTo: cameraAnchor)
            
        } else {
            // No object, hide the arrow
            arrowEntity.isEnabled = false
        }
    }
}
