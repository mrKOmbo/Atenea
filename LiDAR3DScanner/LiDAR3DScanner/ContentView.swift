import SwiftUI
import RealityKit

struct ContentView: View {
    @StateObject private var viewModel = ARViewModel()
    @State private var showTutorial = true
    @State private var showExportOptions = false
    
    var body: some View {
        ZStack {
            ARViewContainer(viewModel: viewModel)
                .ignoresSafeArea()
            
            // Mini-vista 3D
            if viewModel.isScanning || viewModel.scanCompleted {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        MiniView3D(viewModel: viewModel)
                            .frame(width: 160, height: 160)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(16)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue, lineWidth: 2))
                            .padding([.trailing, .bottom], 20)
                    }
                }
            }
            
            ScanningOverlayView(viewModel: viewModel)
            
            VStack {
                Spacer()
                if viewModel.isScanning {
                    Text("Puntos: \(viewModel.pointCount)")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                }
                
                HStack(spacing: 30) {
                    if !viewModel.isScanning && !viewModel.scanCompleted {
                        Button(action: { viewModel.startScanning() }) {
                            VStack {
                                Image(systemName: "viewfinder.circle.fill").font(.system(size: 50))
                                Text("Iniciar Escaneo").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white).padding().background(Color.blue).cornerRadius(20)
                        }
                    } else if viewModel.isScanning {
                        Button(action: { viewModel.stopScanning() }) {
                            VStack {
                                Image(systemName: "stop.circle.fill").font(.system(size: 50))
                                Text("Detener").font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white).padding().background(Color.red).cornerRadius(20)
                        }
                    } else if viewModel.scanCompleted {
                        Button(action: { viewModel.resetScan() }) {
                            VStack {
                                Image(systemName: "arrow.counterclockwise.circle.fill").font(.system(size: 40))
                                Text("Nuevo").font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white).padding().background(Color.gray).cornerRadius(20)
                        }
                        Button(action: { showExportOptions = true }) {
                            VStack {
                                Image(systemName: "square.and.arrow.up.circle.fill").font(.system(size: 40))
                                Text("Exportar").font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white).padding().background(Color.green).cornerRadius(20)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            
            if showTutorial { TutorialView(showTutorial: $showTutorial) }
            if showExportOptions { ExportOptionsView(viewModel: viewModel, showExportOptions: $showExportOptions) }
            
            if !viewModel.isLiDARAvailable {
                VStack {
                    Spacer()
                    Text("⚠️ LiDAR no disponible en este dispositivo")
                        .foregroundColor(.white).padding().background(Color.red).cornerRadius(12).padding()
                    Spacer()
                }
            }
        }
        .statusBarHidden(true)
    }
}

struct MiniView3D: View {
    @ObservedObject var viewModel: ARViewModel
    var body: some View {
        ZStack {
            if let arView = viewModel.miniARView {
                ARViewRepresentable(arView: arView)
            } else {
                Color.black
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            VStack { HStack { Text("Vista 3D").font(.system(size: 10)).foregroundColor(.white).padding(4).background(Color.blue).cornerRadius(4); Spacer() }; Spacer() }.padding(4)
        }
    }
}

struct ARViewRepresentable: UIViewRepresentable {
    let arView: ARView
    func makeUIView(context: Context) -> ARView { arView }
    func updateUIView(_ uiView: ARView, context: Context) {}
}

struct TutorialView: View {
    @Binding var showTutorial: Bool
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            VStack(spacing: 30) {
                Text("🎯 Cómo Escanear").font(.system(size: 28, weight: .bold)).foregroundColor(.white)
                VStack(alignment: .leading, spacing: 15) {
                    Text("1️⃣ Mueve la cámara lentamente en 360°").foregroundColor(.white)
                    Text("2️⃣ Mantén distancia de 1-5 metros").foregroundColor(.white)
                    Text("3️⃣ Evita movimientos bruscos").foregroundColor(.white)
                    Text("4️⃣ Completa un giro completo").foregroundColor(.white)
                }
                Button(action: { showTutorial = false }) {
                    Text("Comenzar").font(.system(size: 20, weight: .bold)).foregroundColor(.white)
                        .padding(.horizontal, 60).padding(.vertical, 16).background(Color.blue).cornerRadius(30)
                }
            }
            .padding(40)
        }
    }
}

struct ExportOptionsView: View {
    @ObservedObject var viewModel: ARViewModel
    @Binding var showExportOptions: Bool
    @State private var exportStatus = ""
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8).ignoresSafeArea().onTapGesture { showExportOptions = false }
            VStack(spacing: 25) {
                Text("Exportar Modelo 3D").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Button(action: { exportStatus = viewModel.exportMesh(format: .usdz) }) {
                    Text("Exportar USDZ").foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(12)
                }
                Button(action: { exportStatus = viewModel.exportMesh(format: .obj) }) {
                    Text("Exportar OBJ").foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.blue).cornerRadius(12)
                }
                if !exportStatus.isEmpty { Text(exportStatus).foregroundColor(.green).padding() }
                Button(action: { showExportOptions = false }) { Text("Cerrar").foregroundColor(.white).padding() }
            }
            .padding(30).background(Color.gray.opacity(0.3)).cornerRadius(20).padding(40)
        }
    }
}
