//
//  RoomPlanView.swift
//  RoomPlanSwiftUI
//
//  Created by tiyas aria on 10/12/23.
//

import SwiftUI

struct ShareableFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct RoomPlanView: View {
    var roomController = RoomController.instance
    @State private var doneScanning: Bool = false
    @State private var shareableFile: ShareableFile?
    
    var body: some View {
        ZStack {
            RoomCaptureViewRepresentable()
                .onAppear(perform: {
                    roomController.startSession()
                })
            
            VStack {
                Spacer()
                    if !doneScanning {
                    Button(action: {
                        roomController.stopSession()
                        self.doneScanning = true
                    }, label: {
                        Text("Done Scanning")
                            .padding(10)
                    })
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(30)
                } else {
                    Button(action: {
                        if let url = roomController.exportToUSDZ() {
                            self.shareableFile = ShareableFile(url: url)
                        }
                    }, label: {
                        Text("Export as .USDZ")
                            .padding(10)
                    })
                    .buttonStyle(.borderedProminent)
                    .cornerRadius(30)
                }
            }
            .padding(.bottom, 10)
        }
        .sheet(item: $shareableFile) { file in
            ShareSheet(activityItems: [file.url])
        }
        // --------------------------
    }
}

#Preview {
    RoomPlanView()
}
