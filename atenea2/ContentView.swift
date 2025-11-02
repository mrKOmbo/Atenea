import SwiftUI

struct ContentView: View {
    var body: some View {
        LiDARScannerView()
            .ignoresSafeArea()
    }
}

// Wrapper para usar el ViewController de UIKit en SwiftUI
struct LiDARScannerView: UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context) -> LiDARScannerViewController {
        return LiDARScannerViewController()
    }
    
    func updateUIViewController(_ uiViewController: LiDARScannerViewController, context: Context) {
        // No necesitamos actualizar nada aquí
    }
}
