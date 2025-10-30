//
//  ClientView.swift
//  atenea
//
//  Created by Enrique Calderon on 30/10/25.
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
                // 3. When SOS is tapped, start browsing
                niManager.startBrowsing()
            }) {
                Text("SOS")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(40)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            Text(niManager.connectionStatus)
                .font(.headline)
            
            if let distance = niManager.nearbyObject?.distance {
                Text("Staff is \(String(format: "%.2f", distance))m away")
                    .font(.subheadline)
            }
        }
        .onAppear {
            // 2. Start the manager when the view appears
            niManager.start()
        }
        .onDisappear {
            niManager.stop()
        }
    }
}
