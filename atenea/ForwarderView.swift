//
//  ForwarderView.swift
//  atenea
//
//  Created by Enrique Calderon on 30/10/25.
//

import SwiftUI

struct ForwarderView: View {
    @StateObject private var niManager = NearbyInteractionManager(role: .forwarder)
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Forwarder Mode")
                .font(.largeTitle)
            
            ProgressView()
                .scaleEffect(2.0)
            
            Text(niManager.connectionStatus)
                .font(.title2)
                .padding()
        }
        .onAppear {
            niManager.start()
        }
        .onDisappear {
            niManager.stop()
        }
    }
}
