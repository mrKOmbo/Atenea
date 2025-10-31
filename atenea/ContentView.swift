//
//  ContentView.swift
//  atenea
//
//  Created by Enrique Calderon on 22/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                Text("Atenea App")
                    .font(.largeTitle)
                
                NavigationLink(destination: ClientView()) {
                    Text("I am a Client")
                        .font(.title) // ...
                }
                
                NavigationLink(destination: StaffView()) {
                    Text("I am Staff")
                        .font(.title) // ...
                }
                
                // ADD THIS NEW ROLE
                NavigationLink(destination: ForwarderView()) {
                    Text("Act as Forwarder")
                        .font(.title)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Select Role")
        }
    }
}
