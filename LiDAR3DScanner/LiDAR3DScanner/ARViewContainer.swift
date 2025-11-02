import SwiftUI
import RealityKit
import ARKit

struct ARViewContainx   er: UIViewRepresentable {
    @ObservedObject var viewModel: ARViewModel
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Configuración optimizada de renderizado
        arView.environment.background = .cameraFeed()
        arView.renderOptions = [
            .disablePersonOcclusion,
            .disableDepthOfField,
            .disableMotionBlur,
            .disableHDR,
            .disableCameraGrain
        ]
        
        // Reducir calidad de renderizado para mejor performance
        arView.contentScaleFactor = 0.8
        
        // Guardar referencia
        viewModel.arView = arView
        
        // Configuración inicial ligera (sin mesh reconstruction todavía)
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        
        // NO activar sceneReconstruction aquí - se activa en startScanning()
        // Esto reduce la carga inicial
        
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // No hacer nada en updates para reducir overhead
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject {
        var viewModel: ARViewModel
        
        init(viewModel: ARViewModel) {
            self.viewModel = viewModel
        }
    }
    
    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        // Limpiar recursos al destruir la vista
        uiView.session.pause()
        uiView.scene.anchors.removeAll()
    }
}
