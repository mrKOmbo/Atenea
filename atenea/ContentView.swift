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
                Text("Atenea APP")
                    .font(.largeTitle)
                
                NavigationLink(destination: ClientView()) {
                    Text("I am a Client")
                        .font(.title)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                NavigationLink(destination: StaffView()) {
                    Text("I am Staff")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Select Role")
        }
    }
}
