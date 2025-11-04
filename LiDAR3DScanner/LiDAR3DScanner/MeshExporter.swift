import Foundation
import UIKit

class MeshExporter {
    enum ExportFormat {
        case usdz, obj, ply
    }
    
    func exportMesh(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])], format: ExportFormat) -> String {
        // Crear carpeta organizada
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let lidarFolder = documentsURL.appendingPathComponent("LiDAR_Scans", isDirectory: true)
        
        // Crear carpeta si no existe
        do {
            try FileManager.default.createDirectory(at: lidarFolder, withIntermediateDirectories: true)
        } catch {
            return "❌ Error creando carpeta: \(error.localizedDescription)"
        }
        
        // Nombre con fecha legible
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "Scan_\(timestamp)"
        
        switch format {
        case .obj:
            return exportOBJ(geometries: geometries, fileName: fileName, folder: lidarFolder)
        case .ply:
            return exportPLY(geometries: geometries, fileName: fileName, folder: lidarFolder)
        case .usdz:
            return "⚠️ USDZ en desarrollo. Usa OBJ o PLY."
        }
    }
    
    private func exportOBJ(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])], fileName: String, folder: URL) -> String {
        let objURL = folder.appendingPathComponent("\(fileName).obj")
        let mtlURL = folder.appendingPathComponent("\(fileName).mtl")
        
        let objContent = generateOBJ(geometries: geometries, mtlFileName: "\(fileName).mtl")
        let mtlContent = generateMTL()
        
        do {
            try objContent.write(to: objURL, atomically: true, encoding: .utf8)
            try mtlContent.write(to: mtlURL, atomically: true, encoding: .utf8)
            
            return "✅ Exportado OBJ + MTL\n\n📁 Archivos > En Mi iPhone > LiDAR3DScanner\n📝 Documents > LiDAR_Scans\n\n• \(fileName).obj\n• \(fileName).mtl"
        } catch {
            return "❌ Error: \(error.localizedDescription)"
        }
    }
    
    private func exportPLY(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])], fileName: String, folder: URL) -> String {
        let plyURL = folder.appendingPathComponent("\(fileName).ply")
        let plyContent = generatePLY(geometries: geometries)
        
        do {
            try plyContent.write(to: plyURL, atomically: true, encoding: .utf8)
            return "✅ Exportado PLY\n\n📁 Archivos > En Mi iPhone > LiDAR3DScanner\n📝 Documents > LiDAR_Scans\n\n• \(fileName).ply"
        } catch {
            return "❌ Error: \(error.localizedDescription)"
        }
    }
    
    private func generateOBJ(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])], mtlFileName: String) -> String {
        var obj = "# LiDAR 3D Scanner Export\n"
        obj += "mtllib \(mtlFileName)\n"
        obj += "usemtl LiDAR_Material\n\n"
        
        var vertexOffset: UInt32 = 0
        
        for (index, geometry) in geometries.enumerated() {
            obj += "o Mesh_\(index)\n"
            
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
                obj += "f \(f1)//\(f1) \(f2)//\(f2) \(f3)//\(f3)\n"
            }
            vertexOffset += UInt32(geometry.vertices.count)
        }
        return obj
    }
    
    private func generateMTL() -> String {
        var mtl = "# LiDAR Material\n"
        mtl += "newmtl LiDAR_Material\n"
        mtl += "Ka 0.2 0.4 0.6\n"
        mtl += "Kd 0.3 0.6 0.8\n"
        mtl += "Ks 0.5 0.5 0.5\n"
        mtl += "Ns 100.0\n"
        mtl += "d 1.0\n"
        return mtl
    }
    
    private func generatePLY(geometries: [(vertices: [SIMD3<Float>], faces: [UInt32], normals: [SIMD3<Float>])]) -> String {
        let totalVertices = geometries.reduce(0) { $0 + $1.vertices.count }
        let totalFaces = geometries.reduce(0) { $0 + $1.faces.count / 3 }
        
        var ply = "ply\n"
        ply += "format ascii 1.0\n"
        ply += "comment LiDAR 3D Scanner Export\n"
        ply += "element vertex \(totalVertices)\n"
        ply += "property float x\n"
        ply += "property float y\n"
        ply += "property float z\n"
        ply += "property float nx\n"
        ply += "property float ny\n"
        ply += "property float nz\n"
        ply += "element face \(totalFaces)\n"
        ply += "property list uchar int vertex_indices\n"
        ply += "end_header\n"
        
        var vertexOffset: UInt32 = 0
        
        for geometry in geometries {
            for i in 0..<geometry.vertices.count {
                let v = geometry.vertices[i]
                let n = i < geometry.normals.count ? geometry.normals[i] : SIMD3<Float>(0, 1, 0)
                ply += "\(v.x) \(v.y) \(v.z) \(n.x) \(n.y) \(n.z)\n"
            }
        }
        
        for geometry in geometries {
            for i in stride(from: 0, to: geometry.faces.count, by: 3) {
                let f1 = geometry.faces[i] + vertexOffset
                let f2 = geometry.faces[i+1] + vertexOffset
                let f3 = geometry.faces[i+2] + vertexOffset
                ply += "3 \(f1) \(f2) \(f3)\n"
            }
            vertexOffset += UInt32(geometry.vertices.count)
        }
        
        return ply
    }
}
