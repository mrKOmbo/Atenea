//
//  ResultView.swift
//  room-recognition
//
//  Created by Enrique Calderon on 09/11/25.
//

import SwiftUI
import SceneKit
import RoomPlan
import UIKit

struct ResultView: View {
    let room: CapturedRoom
    @State private var scene: SCNScene?
    @State private var shareableFile: ShareableFile?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack {
                if let scene = scene {
                    SceneView(
                        scene: scene,
                        options: [.allowsCameraControl, .autoenablesDefaultLighting]
                    )
                } else {
                    ProgressView("Loading 3D Model...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                
                Button(action: {
                    if let url = exportToUSDZ() {
                        self.shareableFile = ShareableFile(url: url)
                    }
                }, label: {
                    Text("Export as .USDZ")
                        .font(.headline)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(.borderedProminent)
                .cornerRadius(30)
                .padding()
            }
            .onAppear(perform: setupScene)
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $shareableFile) { file in
                ShareSheet(activityItems: [file.url])
            }
        }
    }

    /// Sets up the SCNScene from the CapturedRoom and highlights doors.
    func setupScene() {
        let tempDir = FileManager.default.temporaryDirectory
        let tempURL = tempDir.appendingPathComponent("tempRoom.usdz")
        
        // Clean up old file if it exists
        try? FileManager.default.removeItem(at: tempURL)

        do {
            // 1. Export the room to the temp file URL
            try room.export(to: tempURL)
            
            // 2. Load the SCNScene from that file URL
            let newScene = try SCNScene(url: tempURL, options: nil)
            
            // 3. Call our function to highlight doors
            highlightDoors(in: newScene, from: room)
            
            // 4. Set the scene
            self.scene = newScene
            
        } catch {
            print("Error setting up scene: \(error.localizedDescription)")
            self.scene = SCNScene() // Set an empty scene on error
        }
        // --------------
    }
    
    /// Finds all doors in the room and adds a green box to them.
    func highlightDoors(in scene: SCNScene, from room: CapturedRoom) {
            let greenMaterial = SCNMaterial()
            greenMaterial.diffuse.contents = UIColor.green.withAlphaComponent(0.7)
            greenMaterial.specular.contents = UIColor.white
            
            let doors = room.doors
            
            print("Found \(doors.count) doors to highlight.")
            
            for door in doors {
                let dimensions = door.dimensions
                let box = SCNBox(width: CGFloat(dimensions.x),
                                 height: CGFloat(dimensions.y),
                                 length: CGFloat(dimensions.z),
                                 chamferRadius: 0)
                box.materials = [greenMaterial]
                
                let node = SCNNode(geometry: box)
                node.simdTransform = door.transform
                scene.rootNode.addChildNode(node)
            }
        }
    
    /// Exports the original (un-highlighted) room data to a USDZ file.
    func exportToUSDZ() -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "RoomScan_\(Date().timeIntervalSince1970).usdz"
        let fileURL = tempDir.appendingPathComponent(fileName)
                
        do {
            try room.export(to: fileURL)
            print("Successfully exported to \(fileURL)")
            return fileURL
        } catch {
            print("Error exporting CapturedRoom to USDZ: \(error.localizedDescription)")
            return nil
        }
    }
}
