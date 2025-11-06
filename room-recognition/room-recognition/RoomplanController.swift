//
//  RoomplanController .swift
//  RoomPlanSwiftUI
//
//  Created by tiyas aria on 10/12/23.
//

import RoomPlan
import SwiftUI
import Foundation // <-- Add this import

class RoomController :  RoomCaptureViewDelegate {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    static var instance = RoomController()
    var captureView  : RoomCaptureView
    var sessionConfig : RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    var finalResult : CapturedRoom?
    
    
    init() {
        captureView = RoomCaptureView(frame: .zero)
        captureView.delegate = self
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        return true
    }
    
    
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        finalResult = processedResult
    }
    
    func startSession() {
        captureView.captureSession.run(configuration: sessionConfig)
    }
    
    func stopSession() {
        captureView.captureSession.stop()
    }
    
    // MARK: - USDZ EXPORT FUNCTION
    func exportToUSDZ() -> URL? {
        guard let room = finalResult else {
            print("Error: No final room result available for export.")
            return nil
        }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "RoomScan_\(Date().timeIntervalSince1970).usdz"
        let fileURL = tempDir.appendingPathComponent(fileName)
                
        do {
            try room.export(to: fileURL)
            return fileURL
        } catch {
            print("Error exporting CapturedRoom to USDZ: \(error.localizedDescription)")
            return nil
        }
    }
}


struct RoomCaptureViewRepresentable : UIViewRepresentable {
    
    func makeUIView(context: Context) -> RoomCaptureView{
        RoomController.instance.captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        
    }
}
