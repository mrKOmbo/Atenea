//
//  RoomPlanView.swift
//  RoomPlanSwiftUI
//
//  Created by tiyas aria on 10/12/23.
//

import SwiftUI

struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct RoomPlanView: View {
    @ObservedObject var roomController = RoomController.instance
    
    // --- FIX #5 (Part 5) ---
    // We no longer need the @State private var showResultView
    // ------------------------
    
    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable()
                .onAppear(perform: {
                    roomController.startSession()
                })
            
            VStack {
                Spacer()
                
                if roomController.isProcessing {
                    ProgressView("Finishing Scan...")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                
                } else {
                    Button(action: {
                        roomController.stopSession()
                    }, label: {
                        Text("Done Scanning")
                            .padding(10)
                    })
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(30)
                }
            }
            .padding(.bottom, 30)
        }
        
        // --- FIX #5 (Part 6) ---
        // Remove the .onChange modifier.
        // Replace .sheet(isPresented:...) with .sheet(item:...)
        // This automatically watches our 'roomResult' publisher.
        .sheet(item: $roomController.roomResult) { result in
            // 'result' is the non-nil RoomResult
            // We pass its 'room' property to our ResultView
            ResultView(room: result.room)
        }
        // ------------------------
        
        .onDisappear {
            // This is good practice, ensures a fresh scan next time
            roomController.roomResult = nil
        }
    }
}

#Preview {
    RoomPlanView()
}
