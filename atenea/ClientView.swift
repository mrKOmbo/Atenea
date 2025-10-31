//
//  ClientView.swift
//  atenea
//
//  Created by Enrique Calderon on 25/10/25.
//

import SwiftUI

struct ClientView: View {
    // 1. Create the manager, specifying the .client role
    @StateObject private var niManager = NearbyInteractionManager(role: .client)
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Client")
                .font(.largeTitle)
            
            Button(action: {
                // 3. When SOS is tapped, call the NEW function
                niManager.startSOS()
            }) {
                Text("SOS")
            }
            
            Text(niManager.connectionStatus)
                .font(.headline)
        }
        .onAppear {
            niManager.start()
        }
        .onDisappear {
            niManager.stop()
        }
    }
}
