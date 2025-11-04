//
//  ContentView.swift
//  door-recognition
//
//  Created by Enrique Calderon on 04/11/25.
//

import SwiftUI

struct ContentView: View {
    
    // Create and observe the ViewModel.
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            // Layer 1: The camera view.
            CameraView(session: viewModel.session)
                .ignoresSafeArea()
            
            // Layer 2: The bounding box overlay.
            BoundingBoxOverlay(boundingBoxes: viewModel.boundingBoxes)
                .ignoresSafeArea()
            
            // You could add a simple text overlay for debugging:
            VStack {
                Spacer()
                Text("Detected Doors: \(viewModel.boundingBoxes.count)")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(10)
                    .padding()
            }
        }
        .onAppear {
            // Start the camera session when the view appears.
            viewModel.startSession()
        }
        .onDisappear {
            // Stop the camera session when the view disappears.
            viewModel.stopSession()
        }
    }
}
