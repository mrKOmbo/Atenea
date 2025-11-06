//
//  room_recognitionApp.swift
//  room-recognition
//
//  Created by Enrique Calderon on 06/11/25.
//

import SwiftUI
import RoomPlan

@main
struct room_recognitionApp: App {
    var body: some Scene {
        WindowGroup {
            checkDeciveView()
        }
    }
}


@ViewBuilder
func checkDeciveView() -> some View {
    if RoomCaptureSession.isSupported{
        ContentView()
    } else {
        UnsupportedDeviceView()
    }
}
