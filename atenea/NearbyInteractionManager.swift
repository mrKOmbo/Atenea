//
//  NearbyInteractionManager.swift
//  atenea
//
//  Created by Enrique Calderon on 30/10/25.
//

import Foundation
import NearbyInteraction
import MultipeerConnectivity
import ARKit

// Define a custom error for token unarchiving
enum TokenError: Error {
    case unarchiveFailed
}

// Define the data we send over Multipeer Connectivity
// We must send our NI token and role
struct MPCSessionData: Codable {
    let token: NIDiscoveryToken
    let role: AppRole
    
    init(token: NIDiscoveryToken, role: AppRole) {
        self.token = token
        self.role = role
    }
    
    // 1. Define the keys we'll use in the encoded data
    enum CodingKeys: String, CodingKey {
        case token
        case role
    }
    
    // 2. Manual Decoder (init from Decoder)
    // This teaches the struct how to build itself from encoded data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode 'role' normally, as it's already Codable
        self.role = try container.decode(AppRole.self, forKey: .role)
        
        // Decode the 'token' as raw Data
        let tokenData = try container.decode(Data.self, forKey: .token)
        
        // Unarchive the Data back into an NIDiscoveryToken
        guard let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: tokenData) else {
            throw TokenError.unarchiveFailed
        }
        self.token = token
    }
    
    // 3. Manual Encoder (encode(to:))
    // This teaches the struct how to encode itself
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode 'role' normally
        try container.encode(role, forKey: .role)
        
        // Archive the NIDiscoveryToken into Data
        let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
        
        // Encode the resulting Data
        try container.encode(tokenData, forKey: .token)
    }
}

enum AppRole: String, Codable {
    case client
    case staff
}

// This object will manage all NI and MPC logic
class NearbyInteractionManager: NSObject, ObservableObject {
    
    // Published properties to update the UI
    @Published var nearbyObject: NINearbyObject?
    @Published var connectionStatus: String = "Not Connected"
    
    // Nearby Interaction
    private var niSession: NISession?
    
    // Multipeer Connectivity (for token exchange)
    private let serviceType = "atenea-app" // Must match Info.plist
    private var myPeerID: MCPeerID
    private var mpcSession: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    private var myRole: AppRole
    private var connectedPeer: MCPeerID?

    init(role: AppRole) {
        self.myRole = role
        // Use the device name for the PeerID
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }
    
    func start() {
        // 1. Initialize and start the NI session
        niSession = NISession()
        niSession?.delegate = self
        
        // 2. Start Multipeer Connectivity
        startMPCSession()
    }
    
    func stop() {
        niSession?.invalidate()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        mpcSession?.disconnect()
    }
    
    private func startMPCSession() {
        mpcSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        mpcSession?.delegate = self
        
        if myRole == .staff {
            // Staff advertises itself
            advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
            advertiser?.delegate = self
            advertiser?.startAdvertisingPeer()
            DispatchQueue.main.async {
                self.connectionStatus = "Advertising as Staff..."
            }
        } else {
            // Client browses for Staff (but only when SOS is tapped)
            // We'll call `startBrowsing` from the view
        }
    }
    
    // Client calls this when "SOS" is pressed
    func startBrowsing() {
        guard myRole == .client else { return }
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        DispatchQueue.main.async {
            self.connectionStatus = "Browsing for Staff..."
        }
    }
    
    // Send our NI token to the connected peer
    private func sendTokenToPeer(_ peer: MCPeerID) {
        guard let mpcSession = mpcSession,
              let token = niSession?.discoveryToken else {
            print("Error: Missing session or token")
            return
        }
        
        let data = MPCSessionData(token: token, role: self.myRole)
        
        do {
            let encodedData = try JSONEncoder().encode(data)
            try mpcSession.send(encodedData, toPeers: [peer], with: .reliable)
            print("Successfully sent NI token to \(peer.displayName)")
        } catch {
            print("Error sending token: \(error.localizedDescription)")
        }
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionManager: NISessionDelegate {
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        // The session will update with the peer's location.
        guard let peerObject = nearbyObjects.first else { return }
        
        DispatchQueue.main.async {
            self.nearbyObject = peerObject
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        DispatchQueue.main.async {
            self.nearbyObject = nil
            self.connectionStatus = "Peer Lost."
            
            // If we're staff, restart advertising to be found again
            if self.myRole == .staff {
                self.advertiser?.startAdvertisingPeer()
                self.connectionStatus = "Advertising as Staff..."
            }
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        DispatchQueue.main.async {
            self.connectionStatus = "Session Suspended"
        }
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        // Restart the interaction
        if let peer = self.connectedPeer, let mpcSession = mpcSession {
            if !mpcSession.connectedPeers.contains(peer) {
                 // We lost MPC connection, try to find them again
                 if self.myRole == .staff {
                     self.advertiser?.startAdvertisingPeer()
                 } else {
                     self.browser?.startBrowsingForPeers()
                 }
            } else {
                // We are still connected via MPC, just re-share token
                sendTokenToPeer(peer)
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Staff)
extension NearbyInteractionManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        // Staff auto-accepts invitations from Clients
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, self.mpcSession)
        DispatchQueue.main.async {
            self.connectionStatus = "Connecting to Client..."
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Client)
extension NearbyInteractionManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Client auto-invites the first Staff member it finds
        guard let mpcSession = mpcSession else { return }
        
        print("Found Staff: \(peerID.displayName). Inviting.")
        browser.invitePeer(peerID, to: mpcSession, withContext: nil, timeout: 10)
        DispatchQueue.main.async {
            self.connectionStatus = "Found Staff, inviting..."
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost Staff: \(peerID.displayName)")
    }
}

// MARK: - MCSessionDelegate (Both Roles)
extension NearbyInteractionManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            DispatchQueue.main.async {
                self.connectionStatus = "Connected to \(peerID.displayName)"
            }
            // As soon as we connect, send our NI token
            self.connectedPeer = peerID
            sendTokenToPeer(peerID)
            
            // Stop advertising/browsing once connected to one peer
            self.advertiser?.stopAdvertisingPeer()
            self.browser?.stopBrowsingForPeers()
            
        case .connecting:
            DispatchQueue.main.async {
                self.connectionStatus = "Connecting..."
            }
        case .notConnected:
            DispatchQueue.main.async {
                self.connectionStatus = "Disconnected"
                self.nearbyObject = nil
            }
            // Restart advertising/browsing if disconnected
            if self.myRole == .staff {
                self.advertiser?.startAdvertisingPeer()
            } else {
                // Client has to manually press SOS again
            }
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
            // This is where we receive the peer's NI token
            do {
                let receivedData = try JSONDecoder().decode(MPCSessionData.self, from: data)
                
                let peerToken = receivedData.token
                
                print("Received token from \(peerID.displayName)")
                
                // We have the token, start the NI session
                let config = NINearbyPeerConfiguration(peerToken: peerToken)
                self.niSession?.run(config)
                
            } catch {
                print("Error decoding token: \(error.localizedDescription)")
            }
        }
    
    // These methods are required but not used in this simple example
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
