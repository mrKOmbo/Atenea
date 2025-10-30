//
//  ContentView.swift
//  atenea
//
//  Created by Enrique Calderon on 22/10/25.
//

import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    // Get the manager from the environment
    @Environment(MultipeerManager.self) private var multipeerManager

    var body: some View {
        // --- THIS IS THE FIX ---
        // Create a bindable instance of the manager to get '$' bindings
        @Bindable var multipeerManager = multipeerManager
        
        NavigationStack {
            VStack {
                // --- Control Panel ---
                List {
                    Section("Controls") {
                        // Now use the bindable instance for the Toggles
                        Toggle("Start Advertising", isOn: $multipeerManager.isAdvertising)
                        Toggle("Start Browsing", isOn: $multipeerManager.isBrowsing)
                    }
                    
                    // --- Discovered Peers ---
                    Section("Available Peers") {
                        if multipeerManager.peersAvailableToInvite.isEmpty {
                            Text("No peers found.")
                        } else {
                            // Loop over the peers dictionary
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
                    
                    // --- Incoming Invitations ---
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
                    
                    // --- Connected Peers ---
                    Section("Connections") {
                        if multipeerManager.managedPeers.isEmpty {
                            Text("Not connected to any peers.")
                        } else {
                            ForEach(Array(multipeerManager.managedPeers.keys), id: \.self) { peer in
                                if let state = multipeerManager.managedPeers[peer]?.0 {
                                    Text("\(peer.displayName): \(state.displayString)")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Multipeer Demo")
            .ignoresSafeArea(edges: .bottom)
        }
    }
}


#Preview {
    ContentView()
        // Add a mock manager for the preview to work
        .environment(MultipeerManager())
}
