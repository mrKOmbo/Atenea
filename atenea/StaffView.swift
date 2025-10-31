//
//  StaffView.swift
//  atenea
//
//  Created by Enrique Calderon on 25/10/25.
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
            // UI to show navigation path
            if niManager.pathCount > 0 {
                Text("Finding Client (\(niManager.pathCount) hops)")
                    .font(.largeTitle)
                Text("Navigating to: \(niManager.currentTargetID)")
                    .font(.headline)
                    .padding(.bottom, 5)
            } else {
                Text("Staff")
                    .font(.largeTitle)
                Text(niManager.connectionStatus)
                    .font(.headline)
                    .padding(.bottom, 5)
            }
            
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

// The ARViewContainer struc
// Its job is simple: take a 'nearbyObject' and point an arrow.
struct ARViewContainer: UIViewRepresentable {
    
    var nearbyObject: NINearbyObject?
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        arView.session.run(config)
        
        let cameraAnchor = AnchorEntity(.camera)
        cameraAnchor.name = "cameraAnchor"
        arView.scene.addAnchor(cameraAnchor)
        
        let arrowEntity = ModelEntity(
            mesh: .generateBox(size: [0.1, 0.1, 0.5]),
            materials: [SimpleMaterial(color: .cyan, isMetallic: false)]
        )
        arrowEntity.name = "arrow"
        arrowEntity.position = [0, 0, -1.0]
        arrowEntity.isEnabled = false // Start hidden
        
        cameraAnchor.addChild(arrowEntity)
        
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        guard let cameraAnchor = arView.scene.anchors.first(where: { $0.name == "cameraAnchor" }),
              let arrowEntity = cameraAnchor.findEntity(named: "arrow") else {
            print("AR error: Could not find anchor or arrow entity.")
            return
        }
        
        if let object = nearbyObject {
            arrowEntity.isEnabled = true
            
            guard let niDirection = object.direction,
                  let niDistance = object.distance,
                  let cameraTransform = arView.session.currentFrame?.camera.transform
            else {
                return
            }

            let localPosition = SIMD3<Float>(
                niDirection.x * niDistance,
                niDirection.y * niDistance,
                niDirection.z * niDistance
            )
            
            var directionTransform = matrix_identity_float4x4
            directionTransform.columns.3 = SIMD4<Float>(localPosition, 1.0)
            
            let worldTransform = cameraTransform * directionTransform
            
            let targetPosition = SIMD3<Float>(worldTransform.columns.3.x,
                                               worldTransform.columns.3.y,
                                               worldTransform.columns.3.z)

            let localTargetPosition = cameraAnchor.convert(position: targetPosition, from: nil)
            
            arrowEntity.look(at: localTargetPosition,
                             from: arrowEntity.position,
                             relativeTo: cameraAnchor)
            
        } else {
            arrowEntity.isEnabled = false
        }
    }
    
    func dismantleUIView(_ uiView: ARView, context: Context) {
        uiView.session.pause()
    }
}
