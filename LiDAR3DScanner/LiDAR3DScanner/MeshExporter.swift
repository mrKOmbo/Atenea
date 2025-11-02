import Foundation
import UIKit

class MeshExporter {
    enum ExportFormat {
        case usdz, obj
    }
    
    func exportMesh(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])], format: ExportFormat) -> String {
        let fileName = "scan_\(Date().timeIntervalSince1970)"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        switch format {
        case .obj:
            let objURL = documentsURL.appendingPathComponent("\(fileName).obj")
            let objContent = generateOBJ(geometries: geometries)
            do {
                try objContent.write(to: objURL, atomically: true, encoding: .utf8)
                return "✅ Exportado: \(objURL.path)"
            } catch {
                return "❌ Error: \(error.localizedDescription)"
            }
        case .usdz:
            return "✅ USDZ exportación disponible en versión completa"
        }
    }
    
    private func generateOBJ(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])]) -> String {
        var obj = "# LiDAR 3D Scanner Export\n"
        var vertexOffset: UInt32 = 0
        
        for geometry in geometries {
            for vertex in geometry.vertices {
                obj += "v \(vertex.x) \(vertex.y) \(vertex.z)\n"
            }
            for normal in geometry.normals {
                obj += "vn \(normal.x) \(normal.y) \(normal.z)\n"
            }
            for i in stride(from: 0, to: geometry.faces.count, by: 3) {
                let f1 = geometry.faces[i] + vertexOffset + 1
                let f2 = geometry.faces[i+1] + vertexOffset + 1
                let f3 = geometry.faces[i+2] + vertexOffset + 1
                obj += "f \(f1) \(f2) \(f3)\n"
            }
            vertexOffset += UInt32(geometry.vertices.count)
        }
        return obj
    }
}
