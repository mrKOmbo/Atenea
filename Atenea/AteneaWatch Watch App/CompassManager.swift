//
//  CompassManager.swift
//  AteneaWatch Watch App
//
//  Created by Claude Code
//

import CoreLocation
import CoreMotion
import Combine

@MainActor
class CompassManager: NSObject, ObservableObject {
    @Published var heading: Double = 0.0
    @Published var isCalibrating: Bool = false

    private let locationManager = CLLocationManager()
    private let motionManager = CMMotionManager()

    override init() {
        super.init()
        setupLocationManager()
        setupMotionManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }

    private func setupMotionManager() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
        }
    }

    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()

        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] motion, error in
                guard let self = self, let motion = motion else { return }

                // Obtener el heading del dispositivo basado en la actitud
                let yaw = motion.attitude.yaw * 180 / .pi
                self.heading = yaw < 0 ? 360 + yaw : yaw
            }
        }
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        motionManager.stopDeviceMotionUpdates()
    }

    nonisolated deinit {
        locationManager.stopUpdatingHeading()
        motionManager.stopDeviceMotionUpdates()
    }
}

extension CompassManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        Task { @MainActor in
            if newHeading.headingAccuracy >= 0 {
                self.heading = newHeading.magneticHeading
            }
        }
    }

    nonisolated func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        Task { @MainActor in
            self.isCalibrating = true
        }
        return true
    }
}
