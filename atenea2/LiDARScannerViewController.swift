import UIKit
import ARKit
import SceneKit
import Metal
import MetalKit

class LiDARScannerViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - Properties
    private var arView: ARSCNView!
    private var previewView: SCNView!
    private var previewScene: SCNScene!
    private var pointCloudNode: SCNNode!
    
    private var vertexData: [SIMD3<Float>] = []
    private var colorData: [SIMD3<Float>] = []
    
    private let maxPoints = 500000
    private var isScanning = true
    
    // ADDED: A serial queue for heavy processing to avoid blocking the ARSession
    private let processingQueue = DispatchQueue(label: "com.example.lidar.processingQueue")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupPreviewView()
        setupScene()
        setupSession()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arView.session.pause()
    }
    
    // MARK: - Setup Methods
    private func setupARView() {
        arView = ARSCNView(frame: view.bounds)
        arView.delegate = self
        arView.session.delegate = self
        arView.automaticallyUpdatesLighting = true
        view.addSubview(arView)
    }
    
    private func setupPreviewView() {
        // Vista previa 3D en la esquina inferior derecha
        let previewSize: CGFloat = 200
        let margin: CGFloat = 20
        
        let previewFrame = CGRect(
            x: view.bounds.width - previewSize - margin,
            y: view.bounds.height - previewSize - margin - 100,
            width: previewSize,
            height: previewSize
        )
        
        previewView = SCNView(frame: previewFrame)
        previewView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        previewView.layer.cornerRadius = 12
        previewView.layer.borderWidth = 2
        previewView.layer.borderColor = UIColor.systemBlue.cgColor
        previewView.allowsCameraControl = true
        previewView.autoenablesDefaultLighting = true
        previewView.antialiasingMode = .multisampling4X
        
        view.addSubview(previewView)
    }
    
    private func setupScene() {
        previewScene = SCNScene()
        previewView.scene = previewScene
        
        // Configurar cámara para la vista previa
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 1, z: 3)
        cameraNode.look(at: SCNVector3(0, 0, 0))
        previewScene.rootNode.addChildNode(cameraNode)
        
        // Crear nodo para la nube de puntos
        pointCloudNode = SCNNode()
        previewScene.rootNode.addChildNode(pointCloudNode)
        
        // Añadir luz
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 5, z: 5)
        previewScene.rootNode.addChildNode(lightNode)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.color = UIColor.white.withAlphaComponent(0.3)
        previewScene.rootNode.addChildNode(ambientLight)
    }
    
    private func setupSession() {
        guard ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) else {
            showAlert(message: "Este dispositivo no soporta escaneo LiDAR")
            return
        }
    }
    
    private func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            configuration.frameSemantics.insert(.sceneDepth)
        }
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - ARSCNViewDelegate (ADDED)
    
    // ADDED: This delegate method handles adding the mesh to the *main* ARView
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor else { return }
        
        // Create geometry from the mesh anchor
        let geometry = createGeometry(from: meshAnchor)
        
        // Create a new node, assign the geometry, and add it to the node ARKit created
        let meshNode = SCNNode(geometry: geometry)
        meshNode.opacity = 0.8 // Make it slightly transparent
        
        // Add the new mesh node as a child of the node ARKit provided
        node.addChildNode(meshNode)
    }
    
    // ADDED: This delegate method handles updating the mesh in the *main* ARView
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let meshAnchor = anchor as? ARMeshAnchor,
              let meshNode = node.childNodes.first // Get the node we added in didAdd
        else { return }
        
        // Update the existing geometry with the new mesh data
        meshNode.geometry = createGeometry(from: meshAnchor)
    }

    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isScanning else { return }
        
        // CHANGED: Dispatch the heavy work to the background queue
        processingQueue.async { [weak self] in
            // Obtener datos de profundidad del LiDAR
            guard let depthMap = frame.sceneDepth?.depthMap else { return }
                    
            // This function now runs on the 'processingQueue'
            self?.processDepthMap(depthMap, frame: frame)
        }
    }
    
    // REMOVED: session(_:didAdd:) and session(_:didUpdate:)
    // We removed these because the ARSCNViewDelegate methods (renderer:didAdd: and renderer:didUpdate:)
    // are now handling the mesh visualization in the main view.
    // The preview view will now *only* show the point cloud.
    
    // MARK: - Processing Methods
    private func processDepthMap(_ depthMap: CVPixelBuffer, frame: ARFrame) {
        CVPixelBufferLockBaseAddress(depthMap, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(depthMap, .readOnly) }
        
        let width = CVPixelBufferGetWidth(depthMap)
        let height = CVPixelBufferGetHeight(depthMap)
        
        guard let baseAddress = CVPixelBufferGetBaseAddress(depthMap) else { return }
        let floatBuffer = baseAddress.assumingMemoryBound(to: Float32.self)
        
        let camera = frame.camera
        let viewMatrix = camera.viewMatrix(for: .portrait)
        let intrinsics = camera.intrinsics
        
        var newVertices: [SIMD3<Float>] = []
        var newColors: [SIMD3<Float>] = []
        
        // Muestrear puntos (cada 4 píxeles para rendimiento)
        let step = 4
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let index = y * width + x
                let depth = floatBuffer[index]
                
                // Filtrar puntos inválidos
                guard depth > 0 && depth < 5.0 else { continue }
                
                // Convertir coordenadas de píxel a 3D
                let point = unprojectPoint(
                    x: Float(x),
                    y: Float(y),
                    depth: depth,
                    intrinsics: intrinsics,
                    viewMatrix: viewMatrix
                )
                
                newVertices.append(point)
                
                // Color basado en profundidad
                let normalizedDepth = min(depth / 5.0, 1.0)
                let color = SIMD3<Float>(
                    Float(1.0 - normalizedDepth),
                    Float(normalizedDepth * 0.5),
                    Float(normalizedDepth)
                )
                newColors.append(color)
            }
        }
        
        // Actualizar datos globales
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.vertexData.append(contentsOf: newVertices)
            self.colorData.append(contentsOf: newColors)
            
            // Limitar número de puntos
            if self.vertexData.count > self.maxPoints {
                let excess = self.vertexData.count - self.maxPoints
                self.vertexData.removeFirst(excess)
                self.colorData.removeFirst(excess)
            }
            
            // CHANGED: Update the point cloud visualization
            // This is now called every frame after processing new points.
            self.updatePointCloud()
        }
    }
    
    private func unprojectPoint(x: Float, y: Float, depth: Float, intrinsics: simd_float3x3, viewMatrix: simd_float4x4) -> SIMD3<Float> {
        let fx = intrinsics[0][0]
        let fy = intrinsics[1][1]
        let cx = intrinsics[2][0]
        let cy = intrinsics[2][1]
        
        // Convertir de coordenadas de imagen a coordenadas de cámara
        let xCamera = (x - cx) / fx * depth
        let yCamera = (y - cy) / fy * depth
        let zCamera = depth
        
        let pointCamera = SIMD4<Float>(xCamera, yCamera, zCamera, 1.0)
        
        // Transformar al espacio mundial
        let worldPoint = viewMatrix.inverse * pointCamera
        
        return SIMD3<Float>(worldPoint.x, worldPoint.y, worldPoint.z)
    }
    
    // REPLACED: This function now sorts faces by classification
    private func createGeometry(from meshAnchor: ARMeshAnchor) -> SCNGeometry {
        let meshGeometry = meshAnchor.geometry
            
        // 1. Get Vertices and Normals (same as before)
        let vertices = meshGeometry.vertices
        let vertexSource = SCNGeometrySource(
            buffer: vertices.buffer,
            vertexFormat: vertices.format,
            semantic: .vertex,
            vertexCount: vertices.count,
            dataOffset: vertices.offset,
            dataStride: vertices.stride
        )
            
        let normals = meshGeometry.normals
        let normalSource = SCNGeometrySource(
            buffer: normals.buffer,
            vertexFormat: normals.format,
            semantic: .normal,
            vertexCount: normals.count,
            dataOffset: normals.offset,
            dataStride: normals.stride
        )
            
        // 2. Get Faces and Classifications
        let faces = meshGeometry.faces
        guard let classificationData = meshGeometry.classification else {
            // Fallback for devices without classification
            return SCNGeometry(sources: [vertexSource, normalSource], elements: [
                SCNGeometryElement(
                    data: Data(bytesNoCopy: faces.buffer.contents(), count: faces.buffer.length, deallocator: .none),
                    primitiveType: .triangles,
                    primitiveCount: faces.count,
                    bytesPerIndex: faces.bytesPerIndex
                )
            ])
        }
            
        let faceBuffer = faces.buffer.contents()
        let classBuffer = classificationData.buffer.contents().assumingMemoryBound(to: UInt8.self)
        
        // 3. Sort face indices into "buckets" based on their classification
        // We use a dictionary where the key is the classification,
        // and the value is an array of (UInt32) indices
        var buckets: [ARMeshClassification: [UInt32]] = [:]
        
        let indicesPerFace = 3 // .triangles
        
        for i in 0..<faces.count {
            // Get the classification for this face
            let classification = ARMeshClassification(rawValue: Int(classBuffer[i])) ?? .none
            
            // Get the 3 indices that make up this triangle
            let indices: (UInt32, UInt32, UInt32)
            let offset = i * indicesPerFace * faces.bytesPerIndex
            
            if faces.bytesPerIndex == 4 { // 32-bit indices
                let faceIndices = faceBuffer.advanced(by: offset).assumingMemoryBound(to: UInt32.self)
                indices = (faceIndices[0], faceIndices[1], faceIndices[2])
            } else { // 16-bit indices
                let faceIndices = faceBuffer.advanced(by: offset).assumingMemoryBound(to: UInt16.self)
                indices = (UInt32(faceIndices[0]), UInt32(faceIndices[1]), UInt32(faceIndices[2]))
            }
            
            // Add the indices to the correct bucket
            if buckets[classification] == nil {
                buckets[classification] = []
            }
            buckets[classification]?.append(contentsOf: [indices.0, indices.1, indices.2])
        }
        // 4. Create Geometry Elements and Materials for each bucket
        var elements: [SCNGeometryElement] = []
        var materials: [SCNMaterial] = []
        
        for (classification, indices) in buckets {
            // Create the geometry element
            let data = Data(bytes: indices, count: indices.count * MemoryLayout<UInt32>.stride)
            let element = SCNGeometryElement(
                data: data,
                primitiveType: .triangles,
                primitiveCount: indices.count / 3, // 3 indices per triangle
                bytesPerIndex: MemoryLayout<UInt32>.stride // We converted all to UInt32
            )
            elements.append(element)
            
            // Create the material
            materials.append(material(for: classification))
        }
        
        // 5. Create the final geometry
        let geometry = SCNGeometry(sources: [vertexSource, normalSource], elements: elements)
        geometry.materials = materials
        
        return geometry
    }

    // ADDED: A helper function to create materials for each classification
    private func material(for classification: ARMeshClassification) -> SCNMaterial {
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.fillMode = .fill // Use fill so we can see the colors
            
        switch classification {
        case .door:
            // This is our exit!
            material.diffuse.contents = UIColor.green.withAlphaComponent(0.7)
        case .wall:
            material.diffuse.contents = UIColor.gray.withAlphaComponent(0.6)
        case .floor:
            material.diffuse.contents = UIColor.brown.withAlphaComponent(0.7)
        case .window:
            material.diffuse.contents = UIColor.systemBlue.withAlphaComponent(0.7)
        case .ceiling:
            material.diffuse.contents = UIColor.lightGray.withAlphaComponent(0.6)
        case .seat:
            material.diffuse.contents = UIColor.yellow.withAlphaComponent(0.7)
        case .table:
            material.diffuse.contents = UIColor.orange.withAlphaComponent(0.7)
        default:
            // .none and all others
            material.diffuse.contents = UIColor.purple.withAlphaComponent(0.4)
        }
            
        return material
    }
    
    private func updatePointCloud() {
        guard !vertexData.isEmpty else { return }
        
        // Crear geometría de nube de puntos
        let vertexSource = SCNGeometrySource(vertices: vertexData.map { SCNVector3($0.x, $0.y, $0.z) })
        
        let colorSource = SCNGeometrySource(data: Data(bytes: colorData, count: colorData.count * MemoryLayout<SIMD3<Float>>.stride),
                                             semantic: .color,
                                             vectorCount: colorData.count,
                                             usesFloatComponents: true,
                                             componentsPerVector: 3,
                                             bytesPerComponent: MemoryLayout<Float>.size,
                                             dataOffset: 0,
                                             dataStride: MemoryLayout<SIMD3<Float>>.stride)
        
        var indices: [Int32] = []
        for i in 0..<vertexData.count {
            indices.append(Int32(i))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .point)
        element.pointSize = 3.0
        element.minimumPointScreenSpaceRadius = 2.0
        element.maximumPointScreenSpaceRadius = 5.0
        
        let geometry = SCNGeometry(sources: [vertexSource, colorSource], elements: [element])
        
        // Actualizar nodo
        pointCloudNode.geometry = geometry
    }
    
    // MARK: - Helper Methods
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
