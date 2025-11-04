import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configuración básica
        arView.environment.background = .cameraFeed()
        
        // Guardar referencia
        viewModel.arView = arView
        
        // Configuración inicial ligera (sin mesh reconstruction todavía)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        
        // Asignar delegate directamente al viewModel
        arView.session.delegate = viewModel
        arView.session.run(config)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // No hacer nada en updates para reducir overhead
    }
    
    
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        // Limpiar recursos al destruir la vista
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }
}
