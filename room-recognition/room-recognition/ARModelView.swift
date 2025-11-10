//
//  ARModelView.swift
//  room-recognition
//
//  Created by Enrique Calderon on 09/11/25.
//

import SwiftUI
import ARKit
import SceneKit
import RoomPlan

/// 1. The SwiftUI View wrapper
struct ARModelView: View {
    let room: CapturedRoom
    let worldMap: ARWorldMap
    
    @Environment(\.dismiss) var dismiss
    @State private var localizationStatus: String = "Move phone to relocalize..."
    @State private var statusColor: Color = .orange

    var body: some View {
        ZStack(alignment: .top) {
            ARSceneViewRepresentable(
                room: room,
                worldMap: worldMap,
                localizationStatus: $localizationStatus,
                statusColor: $statusColor
            )
            .ignoresSafeArea()
            
            VStack {
                Text(localizationStatus)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(12)
                    .background(statusColor.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .padding(12)
                .background(.black.opacity(0.5))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
    }
}

/// 2. The UIViewRepresentable for ARSCNView
struct ARSceneViewRepresentable: UIViewRepresentable {
    
    let room: CapturedRoom
    let worldMap: ARWorldMap
    @Binding var localizationStatus: String
    @Binding var statusColor: Color
    
    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.initialWorldMap = worldMap
        arView.session.run(configuration)
        
        context.coordinator.arView = arView
        context.coordinator.setupRoomModel(from: room)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARSCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARSceneViewRepresentable
        var arView: ARSCNView?
        
        // Model and Navigation properties
        var roomNode = SCNNode()
        var doorNodes: [SCNNode] = []
        var pathNode: SCNNode?
        
        var isRelocalized = false

        init(parent: ARSceneViewRepresentable) {
            self.parent = parent
        }
                
        /// Exports CapturedRoom to USDZ, loads it, and adds door markers
        func setupRoomModel(from room: CapturedRoom) {
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("tempARModel.usdz")
            
            try? FileManager.default.removeItem(at: tempURL)
            
            do {
                try room.export(to: tempURL)
                let scene = try SCNScene(url: tempURL, options: nil)
                
                let fullRoomNode = SCNNode()
                for child in scene.rootNode.childNodes {
                    fullRoomNode.addChildNode(child)
                }
                
                self.roomNode.addChildNode(fullRoomNode)
                self.setupDoorMarkers(from: room)
                print("AR Model prepared. Waiting for relocalization...")
                
            } catch {
                print("Error setting up AR scene: \(error.localizedDescription)")
            }
        }
        
        /// Creates visible markers for all doors in the room
        func setupDoorMarkers(from room: CapturedRoom) {
            let doorMaterial = SCNMaterial()
            doorMaterial.diffuse.contents = UIColor.systemGreen.withAlphaComponent(0.8)
            doorMaterial.emission.contents = UIColor.systemGreen
            
            for door in room.doors {
                let sphere = SCNSphere(radius: 0.15)
                sphere.materials = [doorMaterial]
                
                let node = SCNNode(geometry: sphere)
                node.simdPosition = door.transform.columns.3.xyz
                
                self.doorNodes.append(node)
                self.roomNode.addChildNode(node)
            }
        }
                
        /// This delegate function is called on every single frame
        func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
            
            guard let arView = self.arView,
                  let frame = arView.session.currentFrame,
                  let camera = arView.session.currentFrame?.camera else {
                return
            }

            if !isRelocalized {
                DispatchQueue.main.async {
                    switch frame.worldMappingStatus {
                    case .mapped:
                        self.isRelocalized = true
                        self.addModelToScene()
                        self.parent.localizationStatus = "Relocalized! Guiding to nearest door."
                        self.parent.statusColor = .green
                    case .extending, .limited:
                        self.parent.localizationStatus = "Trying to match map..."
                        self.parent.statusColor = .orange
                    case .notAvailable:
                        self.parent.localizationStatus = "Localization not available."
                        self.parent.statusColor = .red
                    @unknown default:
                        self.parent.localizationStatus = "Unknown status..."
                        self.parent.statusColor = .red
                    }
                }
                return
            }
                        
            let cameraWorldPos = SCNVector3(camera.transform.columns.3.xyz)
            
            let cameraLocalPos = roomNode.convertPosition(cameraWorldPos, from: nil)
            
            guard let closestDoor = findClosestDoor(to: cameraLocalPos) else {
                return
            }
            
            drawPath(from: cameraLocalPos, to: closestDoor.position, in: arView.scene)
        }
        
        /// Called once relocalization is successful
        func addModelToScene() {
            guard let arView = self.arView else { return }
            
            arView.scene.rootNode.addChildNode(self.roomNode)
            print("Model added to scene at (0,0,0).")
        }
        
        /// Finds the nearest SCNNode in the doorNodes array
        func findClosestDoor(to localPos: SCNVector3) -> SCNNode? {
            return doorNodes.min(by: {
                $0.position.distanceSquared(to: localPos) < $1.position.distanceSquared(to: localPos)
            })
        }
        
        // Looks strange, show it in a different way.
        
        /// Creates and updates a 3D line node
        func drawPath(from userPos: SCNVector3, to doorPos: SCNVector3, in scene: SCNScene) {
            // Remove the old path
            pathNode?.removeFromParentNode()
            
            let path = SCNGeometry.line(
                from: SCNVector3(userPos.x, 0, userPos.z),
                to: SCNVector3(doorPos.x, 0, doorPos.z)
            )
            
            let pathMaterial = SCNMaterial()
            pathMaterial.diffuse.contents = UIColor.systemRed
            pathMaterial.emission.contents = UIColor.systemRed
            path.materials = [pathMaterial]
            
            let newNode = SCNNode(geometry: path)
            self.pathNode = newNode
            
            self.roomNode.addChildNode(newNode)
        }
    }
}
