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

// --- FIX #5 (Part 1) ---
// We create this struct to hold our final room.
// Making it Identifiable lets us use it with .sheet(item:)
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
    
    // --- FIX #5 (Part 2) ---
    // We replace finalResult with our new Identifiable struct
    @Published var roomResult: RoomResult?
    // ------------------------

    // --- FIX #4 ---
    // Added 'override' because we are subclassing NSObject
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
            // --- FIX #5 (Part 3) ---
            // Set our new published property
            self.roomResult = RoomResult(room: processedResult)
            // ------------------------
            self.isProcessing = false
            print("Room processing complete. Final result is set.")
        }
    }
    
    func startSession() {
        // Reset properties for a new scan
        DispatchQueue.main.async {
            // --- FIX #5 (Part 4) ---
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
