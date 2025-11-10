//
//  RoomplanController .swift
//  RoomPlanSwiftUI
//
//  Created by tiyas aria on 10/12/23.
//

import RoomPlan
import SwiftUI
import Foundation
import Combine
import ARKit

struct RoomResult: Identifiable {
    let id = UUID()
    let room: CapturedRoom
    var worldMap: ARWorldMap? = nil
}


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
        captureView.captureSession.arSession.getCurrentWorldMap { worldMap, error in
            if let error = error {
                print("Error getting ARWorldMap: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.roomResult = RoomResult(room: processedResult, worldMap: nil)
                    self.isProcessing = false
                }
                return
            }
            
            // 2. Update on the main thread with both pieces of data
            DispatchQueue.main.async {
                self.roomResult = RoomResult(room: processedResult, worldMap: worldMap)
                self.isProcessing = false
                print("Room processing complete. Final result and world map are set.")
            }
        }
    }
    
    func startSession() {
        // Reset properties for a new scan
        DispatchQueue.main.async {
            self.roomResult = nil
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
