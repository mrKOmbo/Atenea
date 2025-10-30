//
//  ContentView.swift
//  atenea
//
//  Created by Enrique Calderon on 22/10/25.
//

import SwiftUI
import MultipeerConnectivity

struct ArrowView: View {
    var direction: SIMD3<Float>?
    var distance: Float?

    var body: some View {
        VStack {
            if let direction = direction, let distance = distance {
                Text("Distance: \(distance)m")
                Image(systemName: "arrow.up")
                    .font(.system(size: 100))
                    .rotationEffect(.init(radians: Double(atan2(direction.x, -direction.y))))
            } else {
                Text("Searching for device...")
            }
        }
    }
}

struct ContentView: View {
    // Get the manager from the environment
    @Environment(MultipeerManager.self) private var multipeerManager

    var body: some View {
        // --- THIS IS THE FIX ---
        // Create a bindable instance of the manager to get '$' bindings
        @Bindable var multipeerManager = multipeerManager
        
        NavigationStack {
            VStack {
                if let nearbyObject = multipeerManager.nearbyObjects.first {
                    ArrowView(direction: nearbyObject.direction, distance: nearbyObject.distance)
                } else {
                    List {
                        Section("Controls") {
                            Toggle("Start Advertising", isOn: $multipeerManager.isAdvertising)
                            Toggle("Start Browsing", isOn: $multipeerManager.isBrowsing)
                        }
                        
                        Section("Available Peers") {
                            if multipeerManager.peersAvailableToInvite.isEmpty {
                                Text("No peers found.")
                            } else {
                                ForEach(Array(multipeerManager.peersAvailableToInvite.keys), id: \.self) { peer in
                                    HStack {
                                        Text(peer.displayName)
                                        Spacer()
                                        Button("Invite") {
                                            multipeerManager.invite(peer, timeout: 30)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                        
                        Section("Invitations") {
                            if multipeerManager.invitationsReceived.isEmpty {
                                Text("No pending invitations.")
                            } else {
                                ForEach(Array(multipeerManager.invitationsReceived.keys), id: \.self) { peer in
                                    HStack {
                                        Text("Invite from \(peer.displayName)")
                                        Spacer()
                                        Button("Accept") {
                                            multipeerManager.handleInvitation(peer, accept: true)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.green)
                                        
                                        Button("Decline") {
                                            multipeerManager.handleInvitation(peer, accept: false)
                                        }
                                        .buttonStyle(.bordered)
                                        .tint(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Atenea")
            .ignoresSafeArea(edges: .bottom)
        }
    }
}


#Preview {
    ContentView()
        // Add a mock manager for the preview to work
        .environment(MultipeerManager())
}
