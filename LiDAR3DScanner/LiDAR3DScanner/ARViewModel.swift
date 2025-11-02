import Foundation
import ARKit
import RealityKit
import UIKit

class ARViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scanCompleted = false
    @Published var pointCount = 0
    @Published var isLiDARAvailable = false
    @Published var miniARView: ARView?
    
    var arView: ARView?
    private var meshAnchors: [ARMeshAnchor] = []
    private var capturedMeshGeometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])] = []
    
    override init() {
        super.init()
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    func startScanning() {
        guard isLiDARAvailable, let arView = arView else { return }
        isScanning = true
        scanCompleted = false
        meshAnchors.removeAll()
        capturedMeshGeometries.removeAll()
        pointCount = 0
        
        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]
        config.frameSemantics = .sceneDepth
        
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        arView.session.delegate = self
        setupMiniView()
    }
    
    func stopScanning() {
        isScanning = false
        scanCompleted = true
        captureFinalMesh()
        updateMiniViewWithFinalMesh()
    }
    
    func resetScan() {
        isScanning = false
        scanCompleted = false
        meshAnchors.removeAll()
        capturedMeshGeometries.removeAll()
        pointCount = 0
        arView?.session.pause()
        miniARView?.scene.anchors.removeAll()
    }
    
    private func setupMiniView() {
        miniARView = ARView(frame: .zero)
        miniARView?.environment.background = .color(.black)
    }
    
    private func captureFinalMesh() {
        guard let arView = arView else { return }
        for anchor in arView.session.currentFrame?.anchors ?? [] {
            if let meshAnchor = anchor as? ARMeshAnchor {
                meshAnchors.append(meshAnchor)
                extractMeshGeometry(from: meshAnchor)
            }
        }
    }
    
    private func extractMeshGeometry(from meshAnchor: ARMeshAnchor) {
        let geometry = meshAnchor.geometry
        
        // Extraer vértices
        let verticesSource = geometry.vertices
        let verticesBuffer = verticesSource.buffer.contents()
        let vertexCount = verticesSource.count
        let vertexStride = verticesSource.stride
        
        var vertexArray: [SIMD3<Float>] = []
        for i in 0..<vertexCount {
            let vertexPointer = verticesBuffer.advanced(by: i * vertexStride)
            let vertex = vertexPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
            vertexArray.append(vertex)
        }
        
        // Extraer caras (índices)
        let facesSource = geometry.faces
        let facesBuffer = facesSource.buffer.contents()
        let faceCount = facesSource.count
        let indexCountPerFace = facesSource.indexCountPerPrimitive
        
        var faceArray: [UInt32] = []
        for i in 0..<faceCount {
            let facePointer = facesBuffer.advanced(by: i * indexCountPerFace * MemoryLayout<UInt32>.stride)
            for j in 0..<indexCountPerFace {
                let index = facePointer.advanced(by: j * MemoryLayout<UInt32>.stride)
                    .assumingMemoryBound(to: UInt32.self).pointee
                faceArray.append(index)
            }
        }
        
        // Extraer normales
        let normalsSource = geometry.normals
        let normalsBuffer = normalsSource.buffer.contents()
        let normalCount = normalsSource.count
        let normalStride = normalsSource.stride
        
        var normalArray: [SIMD3<Float>] = []
        for i in 0..<normalCount {
            let normalPointer = normalsBuffer.advanced(by: i * normalStride)
            let normal = normalPointer.assumingMemoryBound(to: SIMD3<Float>.self).pointee
            normalArray.append(normal)
        }
        
        capturedMeshGeometries.append((vertices: vertexArray, faces: faceArray, normals: normalArray))
        pointCount = vertexArray.count
    }
    
    private func updateMiniViewWithFinalMesh() {
        guard let miniView = miniARView else { return }
        miniView.scene.anchors.removeAll()
        
        let meshAnchor = AnchorEntity(world: .zero)
        for (index, meshData) in capturedMeshGeometries.enumerated() {
            if let entity = createMeshEntity(from: meshData, index: index) {
                meshAnchor.addChild(entity)
            }
        }
        miniView.scene.addAnchor(meshAnchor)
        animateMiniView()
    }
    
    private func createMeshEntity(from meshData: (vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>]), index: Int) -> ModelEntity? {
        guard !meshData.vertices.isEmpty, !meshData.faces.isEmpty else { return nil }
        var descriptor = MeshDescriptor(name: "scan_\(index)")
        descriptor.positions = MeshBuffer(meshData.vertices)
        descriptor.primitives = .triangles(meshData.faces)
        descriptor.normals = MeshBuffer(meshData.normals)
        
        guard let mesh = try? MeshResource.generate(from: [descriptor]) else { return nil }
        var material = SimpleMaterial()
        material.color = .init(tint: .blue.withAlphaComponent(0.8), texture: nil)
        return ModelEntity(mesh: mesh, materials: [material])
    }
    
    private func animateMiniView() {
        guard let anchor = miniARView?.scene.anchors.first else { return }
        var transform = anchor.transform
        let rotation = simd_quatf(angle: .pi / 180, axis: [0, 1, 0])
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            guard self.miniARView != nil else { timer.invalidate(); return }
            transform.rotation *= rotation
            anchor.transform = transform
        }
    }
    
    func exportMesh(format: MeshExporter.ExportFormat) -> String {
        guard !capturedMeshGeometries.isEmpty else { return "Error: No hay datos" }
        return MeshExporter().exportMesh(geometries: capturedMeshGeometries, format: format)
    }
}

extension ARViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if isScanning {
            var total = 0
            for anchor in frame.anchors {
                if let meshAnchor = anchor as? ARMeshAnchor {
                    total += meshAnchor.geometry.vertices.count
                }
            }
            DispatchQueue.main.async { self.pointCount = total }
        }
    }
}
