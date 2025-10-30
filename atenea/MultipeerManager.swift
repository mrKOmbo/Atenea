//
//  MultipeerManager.swift
//  atenea
//
//  Created by Enrique Calderon on 24/10/25.
//

import Observation
import SwiftUI
import MultipeerConnectivity

@Observable
@Observable
class MultipeerManager: NSObject {
    var peerID: MCPeerID
    private var advertiser: MCNearbyServiceAdvertiser?
    var managedPeers: [MCPeerID : (MCSessionState?, [any Codable])] = [:]
    
    override init() {
        let peerID: MCPeerID
        if let peerIDData, let _peerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: peerIDData) {
            peerID = _peerID
        } else {
            peerID = MCPeerID(displayName: UIDevice.current.name)
            peerIDData = try? NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true)
        }
        self.peerID = peerID
        
        super.init()
        
        // session
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession?.delegate = self
        
        // advertiser
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        
        // browser
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
    }
    
    // session
    func disconnectSession() {
        mcSession?.disconnect()
    }
    
    

    
    
    // Advertisement
    private func startAdvertising() {
        advertiser?.startAdvertisingPeer()
    }
    
    private func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()
    }
    
    func invite(_ peerID: MCPeerID, timeout: TimeInterval /*sec*/) {
        guard let mcSession else {
            setError(.invitationFailed("Session not available."))
            return
        }
        
        browser?.invitePeer(peerID, to: mcSession, withContext: nil, timeout: timeout)
        DispatchQueue.main.async {
            self.managedPeers[peerID] = (nil as MCSessionState?, [])
        }
    }
    
    func handleInvitation(_ peerID: MCPeerID, accept: Bool) {
        guard let info = invitationsReceived[peerID] else {
            return
        }
        info.1(accept, mcSession)
        
        DispatchQueue.main.async {
            self.managedPeers[peerID] = (nil as MCSessionState?, [])
            self.invitationsReceived.removeValue(forKey: peerID)
        }
    }
    
    func send(_ data: Data) {
        do {
            try mcSession?.send(data, toPeers: mcSession?.connectedPeers ?? [], with: .reliable)
        } catch(let error) {
            setError(.sendMessageFailed("Failed to send data with error: \(error.localizedDescription)"))
        }
    }
    
    // Browse
    private func startBrowsing() {
        browser?.startBrowsingForPeers()
    }
    
    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
    }
    
    
    private func setError(_ error: _Error) {
        print("error: \(error)")
        DispatchQueue.main.async {
            self.error = error
        }
    }

}

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("found peer: \(peerID.displayName) with info \(String(describing: info))")
        DispatchQueue.main.async {
            self.discoveredPeers[peerID] = info
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("lost peer: \(peerID.displayName)")
        DispatchQueue.main.async {
            self.discoveredPeers.removeValue(forKey: peerID)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: any Error) {
        self.setError(.startBrowsingFailed("Failed to start browsing for peers with error: \(error.localizedDescription)"))
    }
}

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("invitation received from \(peerID.displayName), with context: \(String(describing: context?.string))")
        
        DispatchQueue.main.async {
            self.invitationsReceived[peerID] = (context, invitationHandler)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: any Error) {
        self.setError(.startAdvertisingFailed("Failed to start advertising with error: \(error.localizedDescription)"))
    }
}



extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        print("peer state changed for \(peerID.displayName): \(state.displayString)")
        
        DispatchQueue.main.async {
            self.managedPeers[peerID]?.0 = state
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("did receive data \(data.count) bytes")
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.managedPeers[peerID]?.1.append(message)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("receive stream.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("start receiving resource with progress: \(progress)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: (any Error)?) {
        print("finish receiving resource. url: \(String(describing: localURL)), error: \(String(describing: error))")
    }

}

extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
    
    var image: Image? {
        if let uiImage = UIImage(data: self) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
}


extension String {
    var data: Data? {
        self.data(using: .utf8)
    }
}


extension MCSessionState {
    var displayString: String {
        switch self {
        case .notConnected:
            return "Not Connected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        @unknown default:
            return "Unknown"
        }
    }
}
