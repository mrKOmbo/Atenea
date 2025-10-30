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

    @State private var message = ""

    var body: some View {
        @Bindable var multipeerManager = multipeerManager
        
        NavigationStack {
            VStack {
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
                    
                    Section("Send Data") {
                        TextField("Message", text: $message)
                        Button("Send") {
                            multipeerManager.send(message.data!)
                        }
                    }
                    
                    Section("Received Messages") {
                        List(multipeerManager.managedPeers.values.flatMap { $0.1 }, id: \.self) { message in
                            Text(message as! String)
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
