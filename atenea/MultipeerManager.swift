//
//  MultipeerManager.swift
//  atenea
//
//  Created by Enrique Calderon on 24/10/25.
//

import SwiftUI
import MultipeerConnectivity
import NearbyInteraction

@Observable
class MultipeerManager: NSObject {
    var nearbyObjects: [NINearbyObject] = []
    var session: NISession?
    var peerDiscoveryToken: NIDiscoveryToken?

    enum _Error: Error {
        case invitationFailed(String)
        case startBrowsingFailed(String)
        case startAdvertisingFailed(String)
        case sendMessageFailed(String)

        var message: String {
            switch self {
            case .invitationFailed(let text):
               text
            case .startBrowsingFailed(let text):
                text
            case .startAdvertisingFailed(let text):
                text
            case .sendMessageFailed(let text):
                text
            }
        }
    }


    
    
    var error: _Error? = nil {
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
                self.error = nil
            })
        }
    }
    
    
    var isAdvertising: Bool = false {
        didSet {
            isAdvertising ? startAdvertising() : stopAdvertising()
        }
    }
    
    var isBrowsing: Bool = false {
        didSet {
            isBrowsing ? startBrowsing() : stopBrowsing()
        }
    }
    
    
    // peers that are not connected and are available to invite
    var peersAvailableToInvite: [MCPeerID : [String : String]?] {
        discoveredPeers.filter({ discoveredPeer in
            !managedPeers.contains(where: { managedPeer in
                return discoveredPeer.key == managedPeer.key && managedPeer.value.0 == .connected
            })
        })
    }
    private var discoveredPeers: [MCPeerID : [String : String]?] = [:]
    
    // invitations from other devices
    var invitationsReceived: [MCPeerID : (Data?, (Bool, MCSession?) -> Void)] = [:]
    
    // peers managed by the MCSession



    private let serviceType = "p2p" // same as that in info.plist

    private static let peerIdKey = "peerIdKey"
    private var peerIDData: Data? = UserDefaults.standard.data(forKey: MultipeerManager.peerIdKey) {
        didSet {
            UserDefaults.standard.set(peerIDData, forKey: MultipeerManager.peerIdKey)
        }
    }

    
    private var mcSession: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    override init() {
        super.init()
        
        let peerID: MCPeerID
        if let peerIDData, let _peerID = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: peerIDData) {
            peerID = _peerID
        } else {
            peerID = MCPeerID(displayName: UIDevice.current.name)
            peerIDData = try? NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true)
        }

        
        // session
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        self.mcSession = session
        
        // advertiser
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: [
            "nickname": "atenea"
        ], serviceType: serviceType)
        advertiser?.delegate = self
        
        // browser
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        
        // Nearby Interaction session
        session = NISession()
        session?.delegate = self
        
        // Get the discovery token
        guard let token = session?.discoveryToken else {
            return
        }
        self.peerDiscoveryToken = token
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
    
    func handleInvitation(_ peerID: MCPeerID, accept: Bool) {
        guard let info = invitationsReceived[peerID] else {
            return
        }
        info.1(accept, mcSession)
        
        if accept {
            guard let discoveryToken = peerDiscoveryToken else {
                return
            }
            let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
            session?.run(config)
        }
        
        DispatchQueue.main.async {
            self.managedPeers[peerID] = (nil as MCSessionState?, [])
            self.invitationsReceived.removeValue(forKey: peerID)
        }
    }
    
    // Browse
    private func startBrowsing() {
        browser?.startBrowsingForPeers()
    }
    
    private func stopBrowsing() {
        browser?.stopBrowsingForPeers()
    }
    
    func invite(_ peerID: MCPeerID, timeout: TimeInterval /*sec*/) {
        guard let mcSession, let peerDiscoveryToken else {
            setError(.invitationFailed("Session not available."))
            return
        }
        
        let context: Data
        do {
            context = try NSKeyedArchiver.archivedData(withRootObject: peerDiscoveryToken, requiringSecureCoding: true)
        } catch(let error) {
            setError(.invitationFailed("Failed to archive discovery token with error: \(error.localizedDescription)"))
            return
        }
        
        browser?.invitePeer(peerID, to: mcSession, withContext: context, timeout: timeout)
        DispatchQueue.main.async {
            self.managedPeers[peerID] = (nil as MCSessionState?, [])
        }
    }
    
    
    private func setError(_ error: _Error) {
        print("error: \(error)")
        DispatchQueue.main.async {
            self.error = error
        }
    }

}

extension MultipeerManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        self.nearbyObjects = nearbyObjects
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        // Handle the removal of nearby objects
    }
    
    func sessionWasSuspended(_ session: NISession) {
        // Handle session suspension
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        // Handle session resumption
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        // Handle session invalidation
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
        
        guard let context, let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: context) else {
            invitationHandler(false, nil)
            return
        }
        
        let peer = NINearbyPeerConfiguration(peerToken: token)
        session?.run(NINearbyPeerConfiguration(peerToken: token))
        
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
        
        if state == .connected {
            guard let discoveryToken = peerDiscoveryToken else {
                return
            }
            let config = NINearbyPeerConfiguration(peerToken: discoveryToken)
            self.session?.run(config)
        }
        
        DispatchQueue.main.async {
            self.managedPeers[peerID]?.0 = state
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
