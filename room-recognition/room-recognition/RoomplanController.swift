//
//  RoomplanController .swift
//  RoomPlanSwiftUI
//
//  Created by tiyas aria on 10/12/23.
//

import RoomPlan
import SwiftUI
import Foundation
import Combine

struct RoomResult: Identifiable {
    let id = UUID()
    let room: CapturedRoom
}
// ------------------------


// Add NSObject and ObservableObject
class RoomController: NSObject, RoomCaptureViewDelegate, ObservableObject {
    func encode(with coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not Needed")
    }
    
    static var instance = RoomController()
    var captureView: RoomCaptureView
    var sessionConfig: RoomCaptureSession.Configuration = RoomCaptureSession.Configuration()
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    
    @Published var roomResult: RoomResult?

    override init() {
    // --------------
        captureView = RoomCaptureView(frame: .zero)
        super.init()
        captureView.delegate = self
    }
    
    func captureView(shouldPresent roomDataForProcessing: CapturedRoomData, error: (Error)?) -> Bool {
        return true
    }
    
    
    func captureView(didPresent processedResult: CapturedRoom, error: (Error)?) {
        // Update on the main thread
        DispatchQueue.main.async {
            self.roomResult = RoomResult(room: processedResult)
            // ------------------------
            self.isProcessing = false
            print("Room processing complete. Final result is set.")
        }
    }
    
    func startSession() {
        // Reset properties for a new scan
        DispatchQueue.main.async {
            self.roomResult = nil
            // ------------------------
            self.isProcessing = false
        }
        captureView.captureSession.run(configuration: sessionConfig)
    }
    
    func stopSession() {
        DispatchQueue.main.async {
            self.isProcessing = true
        }
        captureView.captureSession.stop()
    }
}


struct RoomCaptureViewRepresentable : UIViewRepresentable {
    
    func makeUIView(context: Context) -> RoomCaptureView{
        RoomController.instance.captureView
    }
    
    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        
    }
}
