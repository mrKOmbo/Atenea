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
        .sheet(item: $roomController.roomResult) { result in
            ResultView(room: result.room)
        }
        .onDisappear {
            roomController.roomResult = nil
        }
    }
}

#Preview {
    RoomPlanView()
}
