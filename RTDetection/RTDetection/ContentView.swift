import SwiftUI
import AVFoundation
import Vision
import CoreML

// MARK: - ViewModel

final class RTDetector: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var statusText: String = "Buscando..."
    @Published var isTrue: Bool = false
    @Published var debugInfo: String = ""

    private let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "rt.camera.queue")
    private let visionQueue = DispatchQueue(label: "rt.vision.queue")
    private let speaker = AVSpeechSynthesizer()
    
    // Core ML Model para detección de puertas
    private lazy var doorDetectionModel: VNCoreMLModel? = {
        do {
            let config = MLModelConfiguration()
            let model = try DoorsDetectionV4(configuration: config)
            return try VNCoreMLModel(for: model.model)
        } catch {
            print("Error cargando modelo DoorsDetectionV4: \(error)")
            return nil
        }
    }()

    // throttling / debounce
    private var lastProcessTime: CFAbsoluteTime = 0
    private let minProcessInterval: CFTimeInterval = 0.2 // Procesamiento más espaciado
    private var trueStreak = 0
    private var falseStreak = 0
    private let confirmFrames = 2 // Menos frames para confirmar

    // OCR - más palabras clave
    private let keywordsExit = ["SALIDA", "EXIT", "EMERGENCIA", "EMERGENCY"]
    private let keywordsEntrance = ["ENTRADA", "ENTRANCE", "ACCESO", "ACCESS", "DOOR", "PUERTA"]

    // Variaciones comunes de OCR para palabras clave
    private func getTextVariations(_ keyword: String) -> [String] {
        switch keyword {
        case "SALIDA":
            return ["SALlDA", "5ALIDA", "SAUDA", "SALlD4", "SALIBA", "SALJDA"]
        case "EXIT":
            return ["EX1T", "EXlT", "EX17", "EXI7", "EX!T"]
        case "ENTRADA":
            return ["ENTR4DA", "ENTRADA", "ENTRADd", "ENTR4D4", "ENTPADA"]
        case "ENTRANCE":
            return ["ENTR4NCE", "ENTRANC3", "ENTRAHCE", "ENTR4NC3"]
        case "EMERGENCIA":
            return ["EMERG3NCIA", "EMERGENC1A", "EMERGENC!A"]
        default:
            return []
        }
    }
    
    // Public
    func makeSession() -> AVCaptureSession { session }

    // Setup camera
    func start() {
        queue.async {
            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input)
            else { return }

            self.session.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            output.setSampleBufferDelegate(self, queue: self.queue)
            guard self.session.canAddOutput(output) else { return }
            self.session.addOutput(output)

            // Orientación
            if let conn = output.connection(with: .video), conn.isVideoOrientationSupported {
                conn.videoOrientation = .portrait
            }

            self.session.commitConfiguration()
            self.session.startRunning()
        }
    }

    func stop() {
        queue.async { self.session.stopRunning() }
    }

    // MARK: - Delegate

    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        let now = CFAbsoluteTimeGetCurrent()
        if now - lastProcessTime < minProcessInterval { return }
        lastProcessTime = now

        guard let pixel = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        visionQueue.async {
            self.processFrame(pixel)
        }
    }

    // MARK: - Vision pipeline

    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        var foundSign: (bb: CGRect, kind: String, conf: Float)?
        var allTextDetections = 0
        var detectedTexts: [String] = [] // Para debugging
        
        let ocr = VNRecognizeTextRequest { req, _ in
            guard let obs = req.results as? [VNRecognizedTextObservation] else { return }
            allTextDetections = obs.count
            var best: (CGRect, String, Float)? = nil
            
            for o in obs {
                // Procesar los top 3 candidatos para mejor precisión
                let candidates = o.topCandidates(3)
                for candidate in candidates {
                    let s = candidate.string.uppercased()
                    // Guardar primeros textos para debug
                    if detectedTexts.count < 5 && candidate.confidence > 0.3 {
                        detectedTexts.append(s)
                    }
                    
                    // Búsqueda flexible - coincidencias parciales y similares
                    let isExit = self.keywordsExit.contains { keyword in
                        // Coincidencia exacta
                        if s.contains(keyword) { return true }
                        // Coincidencia con errores de OCR comunes
                        let variations = self.getTextVariations(keyword)
                        return variations.contains { s.contains($0) }
                    }
                    
                    let isEntrance = self.keywordsEntrance.contains { keyword in
                        if s.contains(keyword) { return true }
                        let variations = self.getTextVariations(keyword)
                        return variations.contains { s.contains($0) }
                    }
                    
                    if isExit || isEntrance {
                        let k = isExit ? "SALIDA" : "ENTRADA"
                        let conf = candidate.confidence * 0.9 // Penalizar ligeramente candidatos secundarios
                        if let b = best {
                            if conf > b.2 { best = (o.boundingBox, k, conf) }
                        } else {
                            best = (o.boundingBox, k, conf)
                        }
                    }
                }
            }
            if let b = best { foundSign = b }
        }
        ocr.recognitionLevel = .accurate // Cambiar a accurate para mejor calidad
        ocr.usesLanguageCorrection = true
        ocr.recognitionLanguages = ["es-MX","es","en","zh-Hans","zh-Hant"] // Agregar chino
        ocr.minimumTextHeight = 0.005 // Reducir para texto muy pequeño

        // Core ML Model - Detección de puertas personalizada
        var doorRects: [CGRect] = []
        
        guard let mlModel = doorDetectionModel else {
            // Fallback: usar detección genérica de rectángulos si el modelo falla
            let rectReq = VNDetectRectanglesRequest { req, _ in
                guard let rects = req.results as? [VNRectangleObservation] else { return }
                doorRects = rects.map { $0.boundingBox }.filter { bb in
                    let ar = bb.height / max(bb.width, 1e-6)
                    let area = bb.width * bb.height
                    return ar > 0.8 && area > 0.015
                }
            }
            rectReq.minimumSize = 0.05
            rectReq.minimumConfidence = 0.3
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
            try? handler.perform([ocr, rectReq])
            
            let decision = fuse(sign: foundSign, doors: doorRects)
            let textsPreview = detectedTexts.prefix(3).joined(separator: ", ")
            let debugMsg = "📝 Textos: \(allTextDetections) | 🚪 Puertas: \(doorRects.count) | ✅ Señal: \(foundSign != nil ? "SÍ" : "NO")\n🔍 Leyendo: \(textsPreview)"
            
            DispatchQueue.main.async {
                self.debugInfo = debugMsg
                self.updateState(decision: decision)
            }
            return
        }
        
        // Usar modelo Core ML personalizado
        let doorReq = VNCoreMLRequest(model: mlModel) { req, _ in
            // Procesar resultados del modelo
            if let results = req.results as? [VNRecognizedObjectObservation] {
                // Modelo tipo Object Detection (YOLO, etc.)
                doorRects = results
                    .filter { $0.confidence > 0.4 } // Confianza mínima
                    .map { $0.boundingBox }
            } else if let results = req.results as? [VNClassificationObservation] {
                // Modelo tipo Clasificación - usar toda la imagen si detecta puerta
                if let topResult = results.first, topResult.confidence > 0.5 {
                    // Si clasifica como puerta, usar toda la imagen
                    doorRects = [CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)]
                }
            }
        }
        doorReq.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([ocr, doorReq])
        } catch {
            print("Error en Vision requests: \(error)")
            return
        }

        // Fusión AND
        let decision = fuse(sign: foundSign, doors: doorRects)
        
        // DEBUG INFO DETALLADO
        let textsPreview = detectedTexts.prefix(3).joined(separator: ", ")
        let debugMsg = "📝 Textos: \(allTextDetections) | 🚪 Puertas: \(doorRects.count) (ML) | ✅ Señal: \(foundSign != nil ? "SÍ" : "NO")\n"

        DispatchQueue.main.async {
            self.debugInfo = debugMsg
            self.updateState(decision: decision)
        }
    }

    // Relación espacial: texto arriba Y texto EN la puerta
    private func fuse(sign: (bb: CGRect, kind: String, conf: Float)?,
                      doors: [CGRect]) -> (isTrue: Bool, message: String)
    {
        guard let s = sign else { return (false, "Sin señal") }
        
        // CASO 1: Si hay puertas detectadas, buscar relación espacial
        if !doors.isEmpty {
            // Buscar si texto está arriba de una puerta
            let hasDoorBelow = doors.contains { door in
                isText(s.bb, above: door, minHorizOverlap: 0.15, maxVerticalGap: 0.35)
            }
            
            // Buscar si texto está DENTRO de la puerta (overlap)
            let isTextInsideDoor = doors.contains { door in
                let overlapX = max(0, min(s.bb.maxX, door.maxX) - max(s.bb.minX, door.minX))
                let overlapY = max(0, min(s.bb.maxY, door.maxY) - max(s.bb.minY, door.minY))
                let textArea = s.bb.width * s.bb.height
                let overlapArea = overlapX * overlapY
                // Si más del 30% del texto está dentro del rectángulo de puerta
                return (overlapArea / max(textArea, 1e-6)) > 0.3
            }
            
            if hasDoorBelow || isTextInsideDoor {
                return (true, "\(s.kind) detectada")
            } else {
                return (false, "Señal \(s.kind) sin relación espacial")
            }
        } else {
            // CASO 2: Si NO hay puertas pero SÍ hay señal
            // Asumir que el texto está EN la puerta (la puerta no se detectó como rectángulo)
            // Esto es común cuando la puerta tiene diseños, ventanas, o colores que confunden al detector
            return (true, "\(s.kind) detectada (texto en puerta)")
        }
    }

    private func isText(_ text: CGRect, above door: CGRect,
                        minHorizOverlap: CGFloat,
                        maxVerticalGap: CGFloat) -> Bool
    {
        // Vision coord: origen abajo-izq, [0,1]
        let textBottom = text.minY
        let doorTop = door.maxY
        let verticalGap = doorTop - textBottom
        
        // PERMITIR QUE EL TEXTO ESTÉ ARRIBA O LIGERAMENTE SOLAPADO
        guard verticalGap >= -0.1, verticalGap <= maxVerticalGap else { return false }

        // Calcular overlap horizontal
        let overlap = max(0, min(text.maxX, door.maxX) - max(text.minX, door.minX))
        let base = max(text.width, door.width)
        let ratio = overlap / max(base, 1e-6)
        
        // También permitir proximidad horizontal si están cerca
        let textCenterX = text.midX
        let doorCenterX = door.midX
        let horizontalDistance = abs(textCenterX - doorCenterX)
        
        return ratio >= minHorizOverlap || horizontalDistance < 0.2
    }

    // Debounce + TTS
    private func updateState(decision: (isTrue: Bool, message: String)) {
        if decision.isTrue {
            trueStreak += 1; falseStreak = 0
            if trueStreak == confirmFrames {
                isTrue = true
                statusText = "TRUE — \(decision.message)"
                speak(decision.message)
            }
        } else {
            falseStreak += 1; trueStreak = 0
            if falseStreak == confirmFrames {
                isTrue = false
                statusText = "FALSE — \(decision.message)"
            }
        }
    }

    private func speak(_ text: String) {
        guard !speaker.isSpeaking else { return }
        let utt = AVSpeechUtterance(string: text)
        utt.voice = AVSpeechSynthesisVoice(language: "es-MX")
        utt.rate = AVSpeechUtteranceDefaultSpeechRate
        speaker.speak(utt)
    }
}

// MARK: - Camera Preview

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let v = PreviewView()
        v.videoPreviewLayer.session = session
        v.videoPreviewLayer.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

// MARK: - SwiftUI UI

struct ContentView: View {
    @StateObject private var vm = RTDetector()

    var body: some View {
        ZStack(alignment: .bottom) {
            CameraPreview(session: vm.makeSession())
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Text(vm.statusText)
                    .font(.headline)
                    .padding(10)
                    .background(vm.isTrue ? Color.green.opacity(0.8) : Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // DEBUG INFO
                Text(vm.debugInfo)
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                Text("AND: (Texto señal) ∧ (Puerta debajo)")
                    .font(.caption2)
                    .padding(.bottom, 12)
            }
            .padding()
        }
        .onAppear { vm.start() }
        .onDisappear { vm.stop() }
    }
}
