//
//  CameraViewModel.swift
//  door-recognition
//
//  Created by Enrique Calderon on 04/11/25.
//

import AVFoundation
import Vision
import SwiftUI

// This class will manage the camera session and all the Vision processing.
// It conforms to NSObject and AVCaptureVideoDataOutputSampleBufferDelegate
// to process video frames.
class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // The main capture session.
    let session = AVCaptureSession()
    
    // The Vision model request.
    private var visionRequests = [VNRequest]()
    
    // The dispatch queue for Vision processing to avoid blocking the main thread.
    private let visionQueue = DispatchQueue(label: "com.example.visionQueue")
    
    // A timestamp to track the last processed frame for throttling.
    private var lastFrameTimestamp = TimeInterval(0)
    
    // Published property to hold the bounding boxes for the UI.
    // CGRects are normalized (0.0 to 1.0).
    @Published var boundingBoxes = [CGRect]()

    override init() {
        super.init()
        setupSession()
        setupVision()
    }

    /// Configures the AVCaptureSession with camera input and video data output.
    func setupSession() {
        // Use a high-quality preset.
        session.sessionPreset = .hd1920x1080
        
        // Find the back camera.
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                   for: .video,
                                                   position: .back) else {
            print("Could not find back camera.")
            return
        }
        
        // Create an input from the device.
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error creating camera input: \(error)")
            return
        }
        
        // Create a video data output.
        let videoOutput = AVCaptureVideoDataOutput()
        // Set this class as the delegate to receive frames.
        videoOutput.setSampleBufferDelegate(self, queue: visionQueue)
        // Discard late frames to process the most current one.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            // Set the video orientation to portrait.
            videoOutput.connection(with: .video)?.videoOrientation = .portrait
        } else {
            print("Could not add video output.")
        }
    }

    /// Loads the Core ML model and sets up the Vision request.
    func setupVision() {
        // Load the compiled model.
        // Make sure to replace "DoorDetectionV3" with the exact class
        // name Xcode generated from your .mlmodel file.
        guard let modelURL = Bundle.main.url(forResource: "DoorDetectionV3", withExtension: "mlmodelc") else {
            print("Model file not found.")
            return
        }
        
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            
            // Create a Core ML request.
            let objectRecognitionRequest = VNCoreMLRequest(model: visionModel) { [weak self] (request, error) in
                self?.handleVisionResults(request, error: error)
            }
            // We are looking for objects, not classifications.
            objectRecognitionRequest.imageCropAndScaleOption = .scaleFill
            
            self.visionRequests = [objectRecognitionRequest]
        } catch {
            print("Failed to load Vision model: \(error)")
        }
    }

    /// Handles the results from the Vision request.
    private func handleVisionResults(_ request: VNRequest, error: Error?) {
        if let error = error {
            print("Vision request error: \(error.localizedDescription)")
            return
        }
        
        // Cast the results to object observations.
        guard let results = request.results as? [VNRecognizedObjectObservation] else {
            return
        }
        
        // Map the observations to their bounding boxes.
        let boxes = results.map { $0.boundingBox }
        
        // Publish the bounding boxes on the main thread for the UI to update.
        DispatchQueue.main.async {
            self.boundingBoxes = boxes
        }
    }

    // This is the delegate method that receives every video frame.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        // --- THROTTLING LOGIC ---
        // Get the current frame's timestamp.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        // Check if at least 1 second has passed since the last processing.
        guard timestamp - lastFrameTimestamp >= 1.0 else {
            return // Skip this frame
        }
        
        // Update the last processed timestamp.
        lastFrameTimestamp = timestamp
        // --- END THROTTLING ---

        
        // Get the pixel buffer from the sample buffer.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        // Create an image request handler for the current frame.
        var requestOptions: [VNImageOption: Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        
        // Create a handler to perform the Vision request.
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: .up,
                                                        options: requestOptions)
        
        do {
            // Perform the Vision request on the frame.
            try imageRequestHandler.perform(self.visionRequests)
        } catch {
            print("Failed to perform Vision request: \(error)")
        }
    }

    /// Starts the capture session on a background thread.
    func startSession() {
        visionQueue.async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    /// Stops the capture session.
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
}

