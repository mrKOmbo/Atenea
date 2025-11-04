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
    
    // Throttling para captura de frames - REDUCIDO para iPhone 13 Pro
    private var lastFrameTime: TimeInterval = 0
    private let frameInterval: TimeInterval = 7.0 // 3 segundos entre capturas (antes: 1.0)
    private var rotationTimer: Timer?
    private var processedMeshIDs = Set<UUID>()
    
    override init() {
        super.init()
        isLiDARAvailable = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
    }
    
    deinit {
        // Limpiar recursos al destruir
        rotationTimer?.invalidate()
        rotationTimer = nil
        miniViewUpdateTimer?.invalidate()
        miniViewUpdateTimer = nil
        arView?.session.pause()
        miniARView?.session.pause()
        miniARView = nil
    }
    
    func startScanning() {
        guard isLiDARAvailable else {
            print("❌ LiDAR no disponible en este dispositivo")
            return
        }
        
        guard let arView = arView else {
            print("❌ ARView no inicializado")
            return
        }
        
        print("🚀 Iniciando escaneo LiDAR...")
        
        isScanning = true
        scanCompleted = false
        meshAnchors.removeAll()
        capturedMeshGeometries.removeAll()
        processedMeshIDs.removeAll()
        pointCount = 0
        lastFrameTime = 0
        
        let config = ARWorldTrackingConfiguration()
        
        // Verificar soporte antes de configurar
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
            print("✅ Scene reconstruction activado")
        } else {
            print("⚠️ Scene reconstruction no soportado")
        }
        
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]
        
        // Solo agregar sceneDepth si está disponible
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics = .sceneDepth
            print("✅ Scene depth activado")
        }
        
        // NO reemplazar delegate - ya está asignado en ARViewContainer
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        
        print("✅ Sesión AR iniciada correctamente")
        setupMiniView()
        startMiniViewUpdates()
    }
    
    func stopScanning() {
        isScanning = false
        scanCompleted = true
        
        // Detener actualizaciones automáticas
        miniViewUpdateTimer?.invalidate()
        miniViewUpdateTimer = nil
        
        captureFinalMesh()
        updateMiniViewWithFinalMesh()
    }
    
    func resetScan() {
        isScanning = false
        scanCompleted = false
        meshAnchors.removeAll()
        capturedMeshGeometries.removeAll()
        processedMeshIDs.removeAll()
        pointCount = 0
        lastFrameTime = 0
        
        // Limpiar mini vista
        rotationTimer?.invalidate()
        rotationTimer = nil
        miniViewUpdateTimer?.invalidate()
        miniViewUpdateTimer = nil
        miniARView?.scene.anchors.removeAll()
        miniARView = nil
        
        // Reiniciar sesión principal
        guard let arView = arView else { return }
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    private func setupMiniView() {
        // Limpiar vista anterior si existe
        miniARView?.scene.anchors.removeAll()
        miniARView = nil
        
        // Crear nueva mini vista optimizada
        miniARView = ARView(frame: .zero)
        miniARView?.environment.background = .color(.black)
        
        // Configurar iluminación para mejor visualización
        if let miniView = miniARView {
            let anchor = AnchorEntity(world: .zero)
            miniView.scene.addAnchor(anchor)
        }
    }
    
    private func startMiniViewUpdates() {
        // Actualizar mini-vista cada 2 segundos mientras escanea
        miniViewUpdateTimer?.invalidate()
        miniViewUpdateTimer = Timer.scheduledTimer(withTimeInterval: miniViewUpdateInterval, repeats: true) { [weak self] _ in
            guard let self = self, self.isScanning else { return }
            self.updateMiniViewInRealTime()
        }
    }
    
    private func updateMiniViewInRealTime() {
        guard let arView = arView, let miniView = miniARView else { return }
        
        // Limpiar vista anterior
        miniView.scene.anchors.removeAll()
        
        // Crear anchor principal
        let mainAnchor = AnchorEntity(world: .zero)
        
        // Capturar meshes actuales del frame
        var meshCount = 0
        for anchor in arView.session.currentFrame?.anchors ?? [] {
            if let meshAnchor = anchor as? ARMeshAnchor {
                if let entity = createMeshEntityFromAnchor(meshAnchor, index: meshCount) {
                    mainAnchor.addChild(entity)
                    meshCount += 1
                }
            }
        }
        
        miniView.scene.addAnchor(mainAnchor)
        
        if meshCount > 0 {
            print("🔄 Mini-vista actualizada: \(meshCount) meshes")
            animateMiniView()
        }
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
        // Invalidar timer anterior si existe
        rotationTimer?.invalidate()
        
        guard let anchor = miniARView?.scene.anchors.first else { return }
        
        // Usar weak self para evitar retain cycle
        rotationTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] timer in
            guard let self = self, self.miniARView != nil else {
                timer.invalidate()
                return
            }
            let rotation = simd_quatf(angle: .pi / 90, axis: [0, 1, 0])
            anchor.transform.rotation *= rotation
        }
    }
    
    func exportMesh(format: MeshExporter.ExportFormat) -> String {
        guard !capturedMeshGeometries.isEmpty else { return "Error: No hay datos" }
        return MeshExporter().exportMesh(geometries: capturedMeshGeometries, format: format)
    }
}

extension ARViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isScanning else { return }
        
        let currentTime = frame.timestamp
        
        // THROTTLING: Solo procesar 1 frame por segundo
        guard currentTime - lastFrameTime >= frameInterval else { return }
        lastFrameTime = currentTime
        
        // Actualizar contador de puntos de forma optimizada
        var total = 0
        var newMeshCount = 0
        
        for anchor in frame.anchors {
            if let meshAnchor = anchor as? ARMeshAnchor {
                total += meshAnchor.geometry.vertices.count
                
                // Solo procesar mesh anchors nuevos
                if !processedMeshIDs.contains(meshAnchor.identifier) {
                    processedMeshIDs.insert(meshAnchor.identifier)
                    newMeshCount += 1
                }
            }
        }
        
        // Actualizar UI en main thread
        DispatchQueue.main.async { [weak self] in
            self?.pointCount = total
        }
        
        // Log cada 5 segundos
        if Int(currentTime) % 5 == 0 {
            print("📊 Meshes únicos: \(processedMeshIDs.count), Puntos totales: \(total)")
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ ARSession error: \(error.localizedDescription)")
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("⚠️ ARSession interrumpida")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("✅ ARSession reanudada")
    }
}
