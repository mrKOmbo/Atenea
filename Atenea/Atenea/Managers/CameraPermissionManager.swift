//
//  CameraPermissionManager.swift
//  Atenea
//
//  Created by Emilio Cruz Vargas on 07/10/25.
//

import AVFoundation
import SwiftUI
internal import Combine

class CameraPermissionManager: ObservableObject {
    @Published var permissionGranted = false

    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.permissionGranted = granted
            }
        }
    }

    func checkPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
}
