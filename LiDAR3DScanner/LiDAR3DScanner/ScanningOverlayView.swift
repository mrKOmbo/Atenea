import SwiftUI

struct ScanningOverlayView: View {
    @ObservedObject var viewModel: ARViewModel
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LiDAR Scanner 360°").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                    if viewModel.isScanning {
                        Text("● Escaneando...").font(.system(size: 14)).foregroundColor(.red)
                    } else if viewModel.scanCompleted {
                        Text("✓ Completado").font(.system(size: 14)).foregroundColor(.green)
                    }
                }
                .padding().background(Color.black.opacity(0.6)).cornerRadius(12)
                Spacer()
            }
            .padding()
            Spacer()
        }
    }
}
