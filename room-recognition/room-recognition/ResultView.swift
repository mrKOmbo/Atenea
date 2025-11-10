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
    let roomResult: RoomResult
    @State private var scene: SCNScene?
    @State private var shareableFile: ShareableFile?
    @State private var showARView = false
    @Environment(\.dismiss) var dismiss

    var room: CapturedRoom {
        roomResult.room
    }

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
                
                VStack {
                    HStack(spacing: 10) {
                        Button(action: {
                            self.showARView = true
                        }, label: {
                            Label("View in AR", systemImage: "arkit")
                                .font(.headline)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .cornerRadius(30)
                        .disabled(roomResult.worldMap == nil)
                        
                        Button(action: {
                            if let url = exportToUSDZ() {
                                self.shareableFile = ShareableFile(url: url)
                            }
                        }, label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                        })
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .cornerRadius(30)
                    }
                    
                    if roomResult.worldMap == nil {
                        Text("Automatic AR alignment is unavailable for this scan.")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.top, 5)
                    }
                }
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
            .fullScreenCover(isPresented: $showARView) {
                if let worldMap = roomResult.worldMap {
                    ARModelView(room: roomResult.room, worldMap: worldMap)
                } else {
                    Text("Error: World Map not found.")
                }
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
            try room.export(to: tempURL)
            let newScene = try SCNScene(url: tempURL, options: nil)
            highlightDoors(in: newScene, from: room)
            self.scene = newScene
            
        } catch {
            print("Error setting up scene: \(error.localizedDescription)")
            self.scene = SCNScene()
        }
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
