//
//  NearbyInteractionManager.swift
//  atenea
//
//  Created by Enrique Calderon on 23/10/25.
//

import Foundation
import NearbyInteraction
import MultipeerConnectivity
import ARKit

// App roles
enum AppRole: String, Codable {
    case client
    case staff
    case forwarder
}

// Structure of the SOS mesasge
struct SOSMessage: Codable {
    let messageID: UUID
    let tokenPathData: [Data] // A list of *archived* NIDiscoveryTokens
}

// Helper functions to handle token archiving
func archiveToken(_ token: NIDiscoveryToken) -> Data? {
    do {
        return try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
    } catch {
        print("Error archiving token: \(error)")
        return nil
    }
}
func unarchiveToken(from data: Data) -> NIDiscoveryToken? {
    do {
        return try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data)
    } catch {
        print("Error unarchiving token: \(error)")
        return nil
    }
}

// This is the main NearbyInteractionManager class
class NearbyInteractionManager: NSObject, ObservableObject {
    
    // --- Published Properties for UI ---
    @Published var nearbyObject: NINearbyObject?
    @Published var connectionStatus: String = "Idle" // Idle by default
    @Published var currentTargetID: String = ""
    @Published var pathCount: Int = 0
    
    // --- Nearby Interaction ---
    private var niSession: NISession?
    private var tokenPath: [NIDiscoveryToken] = []
    private var currentTargetIndex: Int = -1
    
    // --- Multipeer Connectivity ---
    private let serviceType = "atenea-app" // It should be the same as declared over the info file under NSBonjourServices
    private var myPeerID: MCPeerID
    private var mpcSession: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    // --- App State ---
    private var myRole: AppRole
    private var myToken: NIDiscoveryToken?
    
    // Mesh network state
    private var processedMessageIDs: Set<UUID> = []
    private var currentSOSMessage: SOSMessage?

    init(role: AppRole) {
        self.myRole = role
        self.myPeerID = MCPeerID(displayName: UIDevice.current.name)
        super.init()
    }
    
    // MARK: - Public Control
    func start() {
        // 1. Start NI Session and get our token
        niSession = NISession()
        niSession?.delegate = self
        myToken = niSession?.discoveryToken
        
        // 2. Configure MPC
        startMPCSession()
        
        // 3. Start acting based on role
        if myRole == .client {
            // Client does nothing until SOS is tapped
            DispatchQueue.main.async { self.connectionStatus = "Ready to Call" }
        } else {
            // Staff and Forwarders are always browsing
            startBrowsing()
        }
    }
    
    func stop() {
        niSession?.invalidate()
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        mpcSession?.disconnect()
    }
    
    // Client calls this
    func startSOS() {
        print("Starting SOS")
        
        guard myRole == .client, let tokenData = archiveToken(myToken!) else {
            print("Error: Not client or token is invalid")
            return
        }
        
        // 1. Create the first SOS message
        let messageID = UUID()
        self.currentSOSMessage = SOSMessage(messageID: messageID, tokenPathData: [tokenData])
        self.processedMessageIDs.insert(messageID) // Add original SOS message to the list
        
        print("List of processed IDS: \(self.processedMessageIDs)")
        
        // 2. Stop browsing (if we were) and start advertising
        browser?.stopBrowsingForPeers()
        startAdvertising()
    }
    
    // MARK: - Internal MPC Methods
    
    private func startMPCSession() {
        mpcSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        mpcSession?.delegate = self
    }
    
    private func startAdvertising() {
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        print("Starting Advertising")
        DispatchQueue.main.async { self.connectionStatus = "Advertising SOS..." }
    }
    
    private func startBrowsing() {
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        print("Starting Browsing for peers")
        DispatchQueue.main.async { self.connectionStatus = "Scanning for SOS..." }
    }
    
    // Send our current SOSMessage to a peer
    private func sendSOSMessage(to peer: MCPeerID) {
        guard let mpcSession = mpcSession, let message = currentSOSMessage else { return }
        do {
            let data = try JSONEncoder().encode(message)
            try mpcSession.send(data, toPeers: [peer], with: .reliable)
            print("Successfully sent SOS message to \(peer.displayName)")
        } catch {
            print("Error sending SOS message: \(error.localizedDescription)")
        }
    }
    
    // MARK: - UWB Navigation Logic
    private func startUWBNavigation() {
        guard !tokenPath.isEmpty else {
            print("Navigation complete or no path.")
            DispatchQueue.main.async {
                self.connectionStatus = "Found Client!"
                self.nearbyObject = nil
            }
            return
        }
        
        // 1. Get the *last* token in the list (the nearest peer)
        self.currentTargetIndex = tokenPath.count - 1
        let targetToken = tokenPath[currentTargetIndex]
        
        // 2. Run the NI session
        niSession?.invalidate() // Stop any previous session
        niSession = NISession()
        niSession?.delegate = self
        
        let config = NINearbyPeerConfiguration(peerToken: targetToken)
        niSession?.run(config)
        
        DispatchQueue.main.async {
            self.pathCount = self.tokenPath.count
            self.currentTargetID = "Peer \(self.currentTargetIndex + 1)"
            self.connectionStatus = "Navigating to \(self.currentTargetID)..."
        }
    }
    
    private func advanceToNextTarget() {
        guard currentTargetIndex >= 0 else { return }
        
        // 1. Remove the target we just found
        tokenPath.remove(at: currentTargetIndex)
        
        // 2. Start navigation to the *new* last item in the list
        startUWBNavigation()
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionManager: NISessionDelegate {
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let peerObject = nearbyObjects.first else { return }
        
        DispatchQueue.main.async {
            self.nearbyObject = peerObject
        }
        
        // Check if we've reached the target
        // It is set at 0.5 meters for simplicity
        if let distance = peerObject.distance, distance < 0.5 {
            if myRole == .staff {
                print("Reached target \(currentTargetID). Advancing to next...")
                // We found the peer, advance to the next one
                advanceToNextTarget()
            }
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        DispatchQueue.main.async {
            self.nearbyObject = nil // Don't change status, just wait for signal to return
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        DispatchQueue.main.async { self.connectionStatus = "Session Suspended" }
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        // Re-run the session with the *same* target
        if myRole == .staff, currentTargetIndex < tokenPath.count {
            let targetToken = tokenPath[currentTargetIndex]
            let config = NINearbyPeerConfiguration(peerToken: targetToken)
            session.run(config)
            DispatchQueue.main.async {
                self.connectionStatus = "Navigating to \(self.currentTargetID)..."
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate (Client or Forwarder)
extension NearbyInteractionManager: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        // Auto-accept invitations
        print("Received invitation from \(peerID.displayName)")
        invitationHandler(true, self.mpcSession)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate (Staff or Forwarder)
extension NearbyInteractionManager: MCNearbyServiceBrowserDelegate {
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        // Found a peer advertising an SOS, invite them
        print("Found SOS advertiser: \(peerID.displayName). Inviting.")
        browser.invitePeer(peerID, to: mpcSession!, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost SOS advertiser: \(peerID.displayName)")
    }
}

// MARK: - MCSessionDelegate (All Roles)
extension NearbyInteractionManager: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("Connected to \(peerID.displayName)")
            // The advertiser (Client/Forwarder) sends the message to the browser (Staff/Forwarder)
            if advertiser != nil {
                sendSOSMessage(to: peerID)
            }
            
        case .connecting:
            print("Connecting to \(peerID.displayName)...")
            
        case .notConnected:
            print("Disconnected from \(peerID.displayName)")
            
            // If we were a Client/Forwarder who just passed the potato,
            // we can stop advertising.
            if advertiser != nil {
                advertiser?.stopAdvertisingPeer()
                advertiser = nil
                
                // If we are a client, we're done.
                // If we are a forwarder, go back to browsing.
                if myRole == .forwarder {
                    startBrowsing()
                } else if myRole == .client {
                    DispatchQueue.main.async { self.connectionStatus = "SOS Sent!" }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // This is called on the Browser (Staff or Forwarder)
        do {
            let message = try JSONDecoder().decode(SOSMessage.self, from: data)
            
            // --- Loop Prevention ---
            if processedMessageIDs.contains(message.messageID) {
                print("Received duplicate SOS message. Dropping.")
                return
            }
            processedMessageIDs.insert(message.messageID)
            
            print("Received new SOS message with \(message.tokenPathData.count) hops.")
            print("This being \(message.tokenPathData)")
            
            if myRole == .staff {
                // --- I AM STAFF ---
                print("I am staff, will start searching")
                
                // 1. This is the end of the line. Store the path.
                self.tokenPath = message.tokenPathData.compactMap { unarchiveToken(from: $0) }
                
                // 2. Stop browsing and disconnect
                browser?.stopBrowsingForPeers()
                session.disconnect()
                
                // 3. Start UWB Navigation
                DispatchQueue.main.async {
                    self.startUWBNavigation()
                }
                
            } else if myRole == .forwarder {
                print("I am forwarder, will start forwarding")
                
                // --- I AM A FORWARDER ---
                guard let myTokenData = archiveToken(myToken!) else { return }
                
                // 1. Add my token to the path
                var newPath = message.tokenPathData
                newPath.append(myTokenData)
                self.currentSOSMessage = SOSMessage(messageID: message.messageID, tokenPathData: newPath)
                
                // 2. Disconnect from the previous advertiser
                session.disconnect()
                
                // 3. Stop browsing and start advertising (pass the hot potato)
                browser?.stopBrowsingForPeers()
                startAdvertising()
            }
            
        } catch {
            print("Error decoding SOS message: \(error)")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
